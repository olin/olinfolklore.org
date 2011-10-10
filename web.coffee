# OlinFolklore.org
# ================

express = require 'express'
fs = require 'fs'
path = require 'path'
mime = require 'mime'
form = require 'connect-form'
bcrypt = require 'bcrypt'
querystring = require 'querystring'
[serial, parallel] = require 'pour'
MongoStore = require 'connect-mongo'
mongoose = require 'mongoose'
{markdown} = require "markdown"
coffeekup = require 'coffeekup'
url = require 'url'

# local modules
{User, Comment, Story} = require './models'

# Configuration
# -------------

config =
	MONGO_USER: 'heroku_app1398322'
	MONGO_PASS: 'a160eaj59k4m50hv5t7plnta9r'
	MONGO_HOST: 'dbh55.mongolab.com'
	MONGO_PORT: '27557'
	MONGO_DB: 'heroku_app1398322'

	secret: "panda-bears-dont-kill-for-free"

############################################################################
# app setup
############################################################################

app = express.createServer(
	express.logger()
	express.bodyParser()
    form keepExtensions: true
)
app.use express.cookieParser()
app.use express.static(__dirname + '/public')
app.use express.errorHandler(dumpExceptions: true, showStack: true)

app.set 'view engine', 'jade'

#
# mongo
#

#app.configure 'production', ->
mongoose.connect "mongodb://" +
	"#{config.MONGO_USER}:#{config.MONGO_PASS}@" +
	"#{config.MONGO_HOST}:#{config.MONGO_PORT}/#{config.MONGO_DB}"
app.use express.session
	secret: "animorphs",
	store: new MongoStore
		host: config.MONGO_HOST
		port: config.MONGO_PORT
		db: config.MONGO_DB
		username: config.MONGO_USER
		password: config.MONGO_PASS

#app.configure 'development', ->
#	mongoose.connect 'mongodb://localhost/mache'
#	app.use express.session
#		secret: "animorphs",
#		store: new MongoStore(db: "mongo")

############################################################################
# routes
############################################################################

verifyEmail = (audience, assertion, cb) ->
	opts =
		host: 'diresworb.org'
		path: "/verify"
		method: "POST"
	vreq = require('https').request opts, (vres) ->
		body = ""
		vres.on("data", (chunk) ->
			body += chunk
		).on "end", ->
			try
				verifierResp = JSON.parse(body)
				valid = verifierResp and verifierResp.status == "okay"
				email = (if valid then verifierResp.email else null)
				if valid
					console.log "assertion verified successfully for email:", email
				else
					console.log "failed to verify assertion:", verifierResp.reason
				cb email
			catch e
				console.log "non-JSON response from verifier", e
				cb null
	vreq.setHeader "Content-Type", "application/x-www-form-urlencoded"
	data = querystring.stringify
		assertion: assertion
		audience: audience
	vreq.setHeader "Content-Length", data.length
	vreq.write data
	vreq.end()
	console.log "verifying assertion!"

app.get "/login", (req, res) ->
	res.render 'login', {req, layout: null}

app.post "/login", (req, res) ->
	audience = (if req.headers["host"] then req.headers["host"] else 'localhost')
	assertion = req.body.assertion

	verifyEmail audience, assertion, (email) ->
		if not email
			res.send {email: null, message: "Not able to verify email address."}
			return
		
		# Check for valid Olin emails.
		if email == 'id@timryan.org'
			email = "timothy.ryan@students.olin.edu"
		unless email.match /@(students|alumni).olin.edu/
			res.send {email: null, message: "Only valid @students.olin.edu or @alumni.olin.edu email addresses permitted."}
			return

		# Create user if she doesn't exist.
		User.findById req.session.user, (err, user) ->
			if not user
				user = new User()
				user._id = email
				user.name = email.replace /@.*$/, ''
				user.registered = new Date()
				user.save()

			req.session.user = user._id
			res.send {email: email, message: "You are now logged in as #{email}."}

app.post "/logout", (req, res) ->
	req.session.user = null
	res.redirect '/login'

# Middleware.

verifyUser = (req, res, next) ->
	path = url.parse(req.url, true)
	if path.pathname in ['/login', '/logout']
		next()
		return

	if req.session.user
		User.findById req.session.user, (err, user) ->
			if user
				req.user = user
				next()
			else
				res.redirect '/login'
	else
		res.redirect '/login'

#
# main page
#

app.get '/', verifyUser, (req, res) ->
	Story.find {}, (err, stories) ->
		res.render 'index', {req, stories}

app.get '/stories/', verifyUser, (req, res) ->
	res.render 'story-new', {req}

app.post '/stories/', verifyUser, (req, res) ->
	story = new Story()
	story.user = req.user._id
	story.time = new Date()
	story.occurred = req.body.date
	story.title = req.body.title
	story.tags = req.body.tags.split /,\s+/
	story.summary = req.body.summary
	story.content = req.body.content
	story.save()

	res.redirect "/stories/#{story.id}"

app.get '/stories/:id', verifyUser, (req, res) ->
	Story.findById req.params.id, (err, story) ->
		if not story
			res.send "No story by that ID found."
			return
		
		comments = []
		# populate stories
		for comment in story.comments
			comments.push 
				content: comment.content
				time: comment.time
				user: User.findOne {_id: comment.user}
		console.log comments

		User.findById story.user, (err, author) ->
			# Convert markdown into html.
			html = markdown.toHTML(story.content)

			res.render 'story', {req, story, author, comments, html}

app.post '/stories/:id', verifyUser, (req, res) ->
	Story.findById req.params.id, (err, story) ->
		if not story
			res.send "No story by that ID found."
			return
		
		switch req.body.action
			when 'favorite'
				story.favorites.push req.user._id
				console.log story
				story.save()
			when 'unfavorite'
				if (i = story.favorites.indexOf req.user._id) != -1
					story.favorites = story.favorites.splice i, 1
				story.save()
			when 'comment'
				story.comments.push
					user: req.user._id
					content: req.body.comment
					time: new Date()
				story.save()
		
		res.redirect '/stories/' + req.params.id

############################################################################
# launch
############################################################################

port = process.env.PORT || 3000
app.listen port
console.log "Listening on port #{port}..."