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

            @buxd.execPlugin pn, { cmd: req.params.cmd }, (err, data) =>
              if err and err == 'not found'
                code = 404
              else
                code = 200

              @debug "#{reqInfo} [#{code}]"
              return reply(data).code(code)
            
      plug pn

    @server.start (err) =>
      if err then callback err

      @debug "Server started at: #{@server.info.uri}"
      super callback

module.exports = HTTPInterface
