browserid   = require 'browserid-consumer'
models      = require './schema'
RoomManager = require('iorooms').RoomManager
uuid        = require 'node-uuid'

class UserRoomManager extends RoomManager
  constructor: (route, io, store, options) ->
    super(route, io, store, options)
    @on "join", (opts) =>
      {socket, room, first} = opts
      if first
        socket.emit "users", @getUsers(room, socket.session)
        socket.broadcast.to(room).emit "user_joined", @userRepr(socket.session)
    @on "leave", (opts) =>
      {socket, room, first} = opts
      if last
        socket.broadcast.to(room).emit "user_left", @userRepr(socket.session)

    @onChannel "user", (socket, data) =>
      socket.session.user.name = data.name
      @saveSession(socket.session)
      socket.broadcast.to(room).emit "user", @userRepr(socket.session)

  authorizeConnection: (session, callback) =>
    unless session.pub_id?
      session.pub_id = uuid.v4()
      @saveSession(session)
      callback()

  getUsers: (room, session) =>
    sessions = @getSessionsInRoom(room)
    self = sessions.filter (a) -> a.pub_id == session.pub_id
    others = _.reject sessions, (a) -> a.pub_id == session.pub_id
    return { self: @userRepr(self), others: (@userRepr(sess) for sess in others) }

  userRepr: (session) =>
    return {
      pub_id: session.pub_id
      name: session.user.name
    }

  broadcastUserChange: (session) =>
    if session.rooms?
      for room in session.rooms
        socket.broadcast.to(room).emit "user", @userRepr(session)

route = (app, io, sessionStore, host, prefix="") ->
  iorooms = new UserRoomManager("/iorooms", io, sessionStore)
  app.post prefix + "/verify", (req, res) ->
    browserid.verify req.body.assertion, host, (err, msg) ->
      res.header('Content-Type', 'application/json')
      if err?
        res.send JSON.stringify error: "Authorization failed."
      else
        email = msg.email
        models.User.findOne {email: msg.email}, (err, doc) ->
          # Success: {"status":"okay","email":"cfd@media.mit.edu","audience":"localhost:3000","expires":1336593791808,"issuer":"browserid.org"}
          if err?
            res.send JSON.stringify {error: "Error fetching user"}
          else
            if doc?
              req.session.user = doc
              res.send JSON.stringify doc
            else
              req.session.user = new models.User {
                email: msg.email
              }
              req.session.user.save (err) ->
                if err?
                  res.send JSON.stringify {error: "Error saving user"}
                else
                  res.send JSON.stringify req.session.user
              iorooms.broadcastUserChange(req.session)

  app.get prefix + "/logout", (req, res) ->
    req.session.destroy()
    res.redirect('/')

module.exports = { route }
