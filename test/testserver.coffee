express         = require 'express'
socketio        = require 'socket.io'
connect         = require 'connect'
mongoose        = require 'mongoose'
browserid       = require 'browserid-consumer'

# Monkeypatch browserid
browserid.verify = (assertion, host, callback) ->
  if assertion == "valid-assertion"
    callback?(null,
      status: 'okay'
      email: "test@example.com"
      audience: host
      expires: 1577836800
    )
  else
    callback?(
      status: 'not okay'
      audience: host
    )

start = ->
  db = mongoose.connect("mongodb://localhost:27017/test")
  app = express.createServer()
  sessionStore = new connect.session.MemoryStore
  app.configure ->
    app.use express.cookieParser()
    app.use express.bodyParser()
    app.use express.session
      secret: "yadda yaddda secret"
      store: sessionStore
      key: "express.sid"
    app.use express.static __dirname + '/static'
    app.set "views", __dirname + '/views'

  app.get '/', (req, res) ->
    res.render 'test.jade', layout: false

  io = socketio.listen(app, "log level": 0)
  require('../lib/app').route(app, io, sessionStore, "localhost:3000", '/auth')

  app.listen(3000)

  return { db, app, io, sessionStore }

if require.main == module
  start()

module.exports = { start }
