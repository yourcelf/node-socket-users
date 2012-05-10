mongoose = require 'mongoose'
path     = require 'path'

Schema = mongoose.Schema

UserSchema = new mongoose.Schema
  email:
    type: String
    required: true
    lowercase: true
    unique: true
    trim: true
  name:
    required: false
    type: String
    trim: true
  image:
    required: false
    type: String
 
UserSchema.path('name').validate (v) ->
  v.length > 2
, "Name must be longer than 2 characters"
UserSchema.path('name').validate (v) ->
  v.length < 30
, "Name must be shorter than 30 characters"

User = mongoose.model("User", UserSchema)

module.exports = { User }
