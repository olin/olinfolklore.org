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
	MONGO_USER: ''
	MONGO_PASS: ''
	MONGO_HOST: ''
	MONGO_PORT: ''
	MONGO_DB: ''

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
###
app.use express.session
	secret: "animorphs",
	store: new MongoStore
		host: config.MONGO_HOST
		port: config.MONGO_PORT
		db: config.MONGO_DB
		username: config.MONGO_USER
		password: config.MONGO_PASS
###

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
	res.send 'whaddup'

############################################################################
# launch
############################################################################

port = process.env.PORT || 3000
app.listen port
console.log "Listening on port #{port}..."