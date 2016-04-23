Interface = require '../interface'
Hapi = require 'hapi'

class HTTPInterface extends Interface

  start: (callback) ->

    @server = new Hapi.Server()
    @server.connection port: @config.port, address: @config.address

    for pn of @buxd.plugins
      plug = (pn) =>

        method = 'GET'
        @server.route
          method: method
          path: "/#{pn}/{cmd?}"
          handler: (req, reply) =>

            reqInfo = "#{method}: #{req.url.path}"
            cmd = req.params.cmd || 'get'

            if !@buxd.plugins[pn][cmd]
              @debug "#{reqInfo} [404]"
              return reply 'command not found'

            @buxd.plugins[pn][cmd] (value) =>
              @debug "#{reqInfo} [200]"
              return reply value
            
      plug pn

    @server.start (err) =>
      if err then callback err

      @debug "Server started at: #{@server.info.uri}"
      super callback

module.exports = HTTPInterface
