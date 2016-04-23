module.exports = (app, bux) ->
  get: (reply) ->
    reply
      buxd: app.version()
      libbux: bux.version()
      uptime: (new Date() - app.uptime)/1000
      interfaces: Object.keys app.interfaces
      plugins: Object.keys app.plugins
      counters: app.counters
      time: new Date().toString()
