{Schema} = mongoose = require 'mongoose'

#
# Schemas
#

UserSchema = new Schema
	_id: String
	password: String
	registered: Date

CommentSchema = new Schema
	user: Schema.ObjectId
	title: String
	time: Date
	content: String

StorySchema = new Schema
	user: Schema.ObjectId
	title: String
	time: Date
	comments: [CommentSchema]
	characters: [Schema.ObjectId]
	tags: [String]
	summary: String
	revisions: [String]
	content: String
	photo: Boolean
	caption: String
	likes: [Schema.ObjectId]

#
# Models
#

exports.User = User = mongoose.model('User', UserSchema)
exports.Comment = Comment = mongoose.model('Comment', CommentSchema)
exports.Story = Story = mongoose.model('Story', StorySchema)