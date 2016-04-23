debug = require 'debug'

class Interface

  constructor: (@name, @config, @buxd) ->
    @debug = debug("buxd:interface:#{@name}")

  start: (callback) ->
    callback()

module.exports = Interface
