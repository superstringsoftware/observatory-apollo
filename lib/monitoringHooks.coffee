#require = if Npm? then Npm.require else __meteor_bootstrap__.require
#Fiber = require 'fibers'

#console.log Meteor.default_server.stream_server

Meteor.userIP = (uid)->
  ret = {}
  uid = uid ? Meteor.userId()
  if uid?
    s = ss for k, ss of Meteor.default_server.sessions when ss.userId is uid
    if s
      ret.forwardedFor = s.socket?.headers?['x-forwarded-for']
      ret.remoteAddress = s.socket?.remoteAddress
  ret


# Ok, we can register handler for every new connecting socket, we can analyze all current meteor sessions
Meteor.default_server.stream_server.register (socket)->
  ###
  console.log "SOCKET Connect! ----------------------------->"
  socket.on 'data', (raw_msg)->
    console.log 'Got message in a socket: --------->', @id
    console.log raw_msg
  socket.on 'close', ->
    console.log "Closing socket #{@id}"

  console.dir socket
  console.log "METEOR SESSION: ----------------------------->"
  Meteor.userIP()
  console.dir socket.meteor_session
  #console.log s.meteor_session.userId, s.meteor_session.socket.headers for s in Meteor.default_server.stream_server.open_sockets when s.meteor_session?
  ###

Meteor.methods
  # TODO: add authorization!
  _observatoryGetOpenSessions: ->
    # console.log "======================================== called observatoryGetOpenSockets ======================================"
    ret = []
    #console.dir Meteor.default_server?.stream_server?.open_sockets
    for k, socket of Meteor.default_server?.stream_server?.open_sockets #Meteor.default_server.sessions #Meteor.default_server?.stream_server?.open_sockets
      # TODO: DO NOT delete the below as if Meteor internal API changes we'll need to look at it again!!!
      # console.dir os.collectionViews
      os = socket.meteor_session

      # analyzing named subscriptions
      ns = {}
      for k1, v1 of os._namedSubs
        ns[k1] =
          uid: v1.userId
          name: v1._name
          deactivated: v1._deactivated
          isReady: v1._ready
          params: v1._params
        for k,v of v1
          if typeof(v) is 'function'
            ns[k1][k] = v.toString()

      o =
        ddpVersion: os.version
        sessionId: os.id
        initialized: os.initialized
        lastConnect: new Date os.last_connect_time
        lastDetach: new Date os.last_detach_time
        blocked: os.blocked
        workerRunning: os.worker_running
        userId: os.userId
        sessionData: os.sessionData
        namedSubs: ns

        collectionViews: ({name: v.collectionName, id: k, docNumber: Object.keys(v.documents).length} for k,v of os.collectionViews)

        headers: os.socket?.headers
        protocol: os.socket?.protocol
        address: os.socket?.address
        remoteAddress: os.socket?.remoteAddress
        remotePort: os.socket?.remotePort

        isSending: os._isSending
        pendingReady: os._pendingReady

      ret.push o
      #console.dir o
      #console.dir os.socket._events
      #console.dir Meteor.default_server.sessions
    ret

  _observatoryGetCurrentServer: ->
    #console.log "======================================== called observatoryGetOpenSockets ======================================"
    #console.dir Meteor.default_server
    publishHandlers = ({name: k, func: v.toString()} for k,v of Meteor.default_server?.publish_handlers)
    methodHandlers = ({name: k, func: v.toString()} for k,v of Meteor.default_server?.method_handlers)
    {publishHandlers: publishHandlers, methodHandlers: methodHandlers}

  _observatoryGetArbitraryObj: (line)->
    Meteor.userIP()



