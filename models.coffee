{Schema} = mongoose = require 'mongoose'

#
# Schemas
#

UserSchema = new Schema
	_id: String
	name: String
	password: String
	registered: Date

CommentSchema = new Schema
	user: String
	time: Date
	content: String

StorySchema = new Schema
	user: { type: String, ref: 'User' }
	title: String
	time: Date
	occurred: Date
	characters: [Schema.ObjectId]
	tags: [String]
	summary: String
	revisions: [String]
	content: String
	photo: Boolean
	caption: String
	favorites: [String]
	comments: [CommentSchema]

#
# Models
#

exports.User = User = mongoose.model('User', UserSchema)
exports.Comment = Comment = mongoose.model('Comment', CommentSchema)
exports.Story = Story = mongoose.model('Story', StorySchema)