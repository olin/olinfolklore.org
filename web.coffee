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
coffeekup = require 'coffeekup'

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

app.register '.coffee', coffeekup.adapters.express
app.set 'view engine', 'coffee'

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
				console.log "non-JSON response from verifier"
				cb null
	vreq.setHeader "Content-Type", "application/x-www-form-urlencoded"
	data = querystring.stringify
		assertion: assertion
		audience: audience
	vreq.setHeader "Content-Length", data.length
	vreq.write data
	vreq.end()
	console.log "verifying assertion!"

# Middleware.

populateUser = (req, res, next) ->
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

app.get '/', populateUser, (req, res) ->
	Story.find {}, (err, stories) ->
		res.send """

<h1>Olinfolklore</h1>
<p>Logged in as #{req.user.name} (#{req.user._id}).</p>

<h2>Stories</h2>
<ul>
#{"<li><a href='/stories/#{story.id}'>#{story.title}</a><br>
<em>#{story.occurred}</em></li>" for story in stories}
</ul>
"""

app.get "/login", (req, res) ->
	res.send """
<h1>Log in</h1>
<p>In order to view Olinfolklore.org, you must first <button id="signin">Sign in</button>.</p>
<script src="https://diresworb.org/include.js" type="text/javascript"></script>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js"></script>
<script>
document.getElementById('signin').onclick = function () {
navigator.id.getVerifiedEmail(function(assertion) {
    if (assertion) {
       console.log(assertion);
       $.post('/login', {assertion: assertion}, function (data) {
       		console.log(data);
       });
    } else {
        // something went wrong!  the user isn't logged in.
    }
});
}
</script>
"""

app.post "/login", (req, res) ->
	audience = (if req.headers["host"] then req.headers["host"] else 'localhost')
	assertion = req.body.assertion

	verifyEmail audience, assertion, (email) ->
		if not email
			res.send {email: null, message: "Not able to verify email address."}
		# else if email isn't an olin email
		else
			res.session.user = "timothy.ryan@students.olin.edu"

			# Create user if she doesn't exist.
			User.findById res.session.user, (err, user) ->
				if not user
					user = new User()
					user._id = email
					user.name = email.replace /@.*$/, ''
					user.registered = new Date()
					user.save()

				res.send {email: email, message: "You are now logged in as #{email}."}

app.post "/logout", (req, res) ->
	req.session.user = null
	res.redirect '/login'

app.get '/stories/', populateUser, (req, res) ->
	res.send '''
<h1>Submit a new story</h1>
<form method="post">
<label>Title: <input type="text" name="title"></label><br>
<label>Date (YYYY-MM-DD): <input type="date" name="date"></label><br>
<label>Tags (comma-separated): <input type="text" name="tags"></label><br>
<!-- characters -->
<label>Summary (max 140 chars): <input type="text" maxlength="140" name="summary"></label><br>
<label>Story:<br>
<textarea rows="30" cols="100" name="content"></textarea></label><br>
<!-- photos -->
<button type="submit">Submit Story</button>
</form>
'''

app.post '/stories/', populateUser, (req, res) ->
	story = new Story()
	story.user = req.user._id
	story.time = new Date()
	story.occurred = req.body.date
	story.title = req.body.title
	story.tags = req.body.tags.split /,\s+/
	story.summary = req.body.summary
	story.content = req.body.content
	story.save()

	res.send """
<h1>Story submitted!</h1>
<p>You can view it <a href="/stories/#{story.id}">here</a>.</p>
"""

app.get '/stories/:id', populateUser, (req, res) ->
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
			res.send """
<h1>#{story.title}</h1>
<p class="summary"><em>#{story.summary}</em></p>
<dl>
<dt>Author:</dt><dd>#{author?.name}</dd>
<dt>Tags:</dt><dd>#{story.tags.join(', ')}</dd>
</dl>
<div style="white-space: pre">
#{story.content}
</div>
#{if req.user._id in story.favorites then '
<form method="post">You have favorited this story.
<input type="hidden" name="action" value="unfavorite">
<button type="Submit">Undo?</button>
</form>
' else '
<form method="post">
<input type="hidden" name="action" value="favorite">
<button type="Submit">Favorite this story</button>
</form>
'}
<h2>Comments</h2>
#{if story.comments then '<ul class="comments">' + ("<li><b>" + comment.user.name + "</b><br>#{comment.content}</li>" for comment in comments) + '</ul>' else '<p>There are no comments yet.</p>'}
<h3>Post a comment</h3>
<form method="post">
<input type="hidden" name="action" value="comment">
<textarea rows="7 cols="50" name="comment"></textarea>
<button type="Submit">Submit a comment</button>
</form>
"""

app.post '/stories/:id', populateUser, (req, res) ->
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