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

#
# main page
#

app.get '/', (req, res) ->
	Story.find {}, (err, stories) ->
		res.send """

<h1>Olinfolklore</h1>
<p>#{if req.session.user then "Logged in as #{req.session.user.name}. <a href='/logout'>Logout?</a>" else 'Not currently logged in. <a href="/login">Sign in?</a>'}</p>

<h2>Stories</h2>
<ul>
#{"<li><a href='/stories/#{story.id}'>#{story.title}</a><br>
<em>#{story.occurred}</em></li>" for story in stories}
</ul>
<button id="signin">Sign in</button>
<script src="https://diresworb.org/include.js" type="text/javascript"></script>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js"></script>
<script>
document.getElementById('signin').onclick = function () {
navigator.id.getVerifiedEmail(function(assertion) {
    if (assertion) {
       console.log(assertion);
       $.post('/identities', {assertion: assertion}, function (data) {
       		console.log(data);
       });
    } else {
        // something went wrong!  the user isn't logged in.
    }
});
}
</script>
"""

app.post "/identities", (req, res) ->
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
				req.session.email = email
				if valid
					console.log "assertion verified successfully for email:", email
				else
					console.log "failed to verify assertion:", verifierResp.reason
					res.json email
			catch e
				console.log "non-JSON response from verifier"
				res.json null
	vreq.setHeader "Content-Type", "application/x-www-form-urlencoded"
	audience = (if req.headers["host"] then req.headers["host"] else 'olinfolklore.org')
	data = querystring.stringify
		assertion: req.body.assertion
		audience: audience
	vreq.setHeader "Content-Length", data.length
	vreq.write data
	vreq.end()
	console.log "verifying assertion!"

app.get '/register', (req, res) ->
	res.send '''
<h1>New Users/Update Password</h1>
<form method="post">
<label>Email address (must be @students.olin.edu or @alumni.olin.edu): <input type="text" name="email"></label><br>
<label>Full Name: <input type="text" name="name"></label><br>
<label>Password: <input type="password" name="password"></label><br>
<button type="submit">Register/Update password</button>
<p style="color: red">JK YOU DONT NEED A VALID EMAIL ADDRESS YET</p>
</form>
'''

app.post '/register', (req, res) ->
	if not req.body.email or not req.body.password or not req.body.name
		res.send """<p>Invalid data. <a href="/register">Try again?</a></p>"""
		return

	user = new User()
	user._id = req.body.email
	user.name = req.body.name
	salt = bcrypt.gen_salt_sync 10
	user.password = bcrypt.encrypt_sync config.secret, salt
	user.password = req.body.password
	user.registered = new Date()
	user.save()

	req.session.user = user

	res.send """
<p>Welcome #{req.body.email}!</p>
<p><a href="/">Continue...</a></p>
"""

app.get '/login', (req, res) ->
	res.send """
<h1>Login</h1>
<form method="post">
<label>Email address (must be @students.olin.edu or @alumni.olin.edu): <input type="text" name="email"></label><br>
<label>Password: <input type="password" name="password"></label><br>
<button type="submit">Login</button>
</form>
"""

app.post '/login', (req, res) ->
	User.findById req.body.email, (err, user) -> 
		if not user or not bcrypt.compare_sync(config.secret, user.password)
			res.send """<p>Invalid data. <a href="/login">Try again?</a></p>"""
			return

		user.remove()
		res.send "LOL DEAD"
		
		#req.session.user = user
		#res.redirect '/'

app.get '/stories/', (req, res) ->
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

app.post '/stories/', (req, res) ->
	story = new Story()
	story.user = req.session.user._id
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

app.get '/stories/:id', (req, res) ->
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
#{if req.session.user?._id in story.favorites then '
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

app.post '/stories/:id', (req, res) ->
	Story.findById req.params.id, (err, story) ->
		if not story
			res.send "No story by that ID found."
			return
		
		switch req.body.action
			when 'favorite'
				story.favorites.push req.session.user._id
				console.log story
				story.save()
			when 'unfavorite'
				if (i = story.favorites.indexOf req.session.user._id) != -1
					story.favorites = story.favorites.splice i, 1
				story.save()
			when 'comment'
				story.comments.push
					user: req.session.user._id
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