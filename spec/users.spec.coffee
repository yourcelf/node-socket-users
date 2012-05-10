Browser = require 'zombie'
expect  = require 'expect.js'
_       = require 'underscore'

waitFor = (callback) ->
  # Try to execute the callback periodically until it returns truthy.  Make
  # sure the callback is idempotent.
  interval = setInterval ->
    if callback()
      clearInterval(interval)
  , 10

describe "users", ->
  before ->
    @server = require('../test/testserver').start()
  after ->
    @server.app.close()

  it "connects to the socket", (done) ->
    @browser = new Browser()
    @browser.visit "http://localhost:3000/", ->
    waitFor =>
      socketIDs = (socketID for socketID, socket of @server.io.roomClients)
      if socketIDs.length == 1
        done()
        return true

  it "authenticates", (done) ->
    @browser.clickLink ".signin", =>
      waitFor =>
        user = @browser.evaluate("window.user")
        if user?
          for sid, sess of @server.sessionStore.sessions
            session = JSON.parse(sess)
            expect(_.isEqual user, session.user).to.be(true)
            done()
            return true

  it "logs out", (done) ->
    sess = (sess for sid,sess of @server.sessionStore.sessions)[0]
    sid = sess.sid
    @browser.clickLink ".logout", =>
      waitFor =>
        sess = (sess for sid,sess of @server.sessionStore.sessions)[0]
        # Ensure that the sid is changed.
        if sess.sid != sid
          # and the user is gone.
          expect(sess.user).to.be(undefined)
          done()
          return true
