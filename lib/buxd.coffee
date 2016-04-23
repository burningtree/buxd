BUX = require 'libbux'
async = require 'async'

BUXServerVersion = '0.1.0';

class BUXServer

  config:
    interfaces: 
      http:
        port: 5440
        address: 'localhost'
    plugins:
      performance: {}
      test: {}
    account:
      access_token: JSON.parse(require('fs').readFileSync(process.env.HOME+'/.bux-config.json')).account.access_token

  interfaces: {}
  plugins: {}
  version: BUXServerVersion
    
  constructor: (config) ->
    # TODO assign config
    @debug = require('debug')('buxd:main')

  start: (callback) ->
    @debug "Initializing BUXd .."

    @bux = new BUX.api(access_token: @config.account.access_token)

    @debug "Loading plugins .."
    @loadPlugins =>
      @debug "Plugins loaded"

      @debug "Starting interfaces .."
      @loadInterfaces =>
        @debug "Interfaces loaded"

        console.log "BUXd #{@version} started"
        console.log "Loaded interfaces: #{Object.keys(@interfaces).join(', ')}"
        console.log "Loaded plugins: #{Object.keys(@plugins).join(', ')}"
        if callback then return callback()
        return true

  loadPlugins: (callback) ->

    async.each Object.keys(@config.plugins), (pn, next) =>
      pc = @config.plugins[pn]
      @debug "Loading plugin: #{pn}"
      target = require "../plugins/#{pn}"
        
      @plugins[pn] = target @, @bux
      @debug "Plugin loaded: #{pn}"
      next()

    , () ->
      callback()

  loadInterfaces: (callback) ->

    async.each Object.keys(@config.interfaces), (int, next) =>
      ic = @config.interfaces[int]
      @debug "Starting interface: #{int} .."
      target = require "./interface/#{int}"
      obj = new target int, ic, @
      obj.start (err) =>
        if err then throw err
        @interfaces[int] = obj
        @debug "Interface started: #{int}"
        next()

    , () ->
      callback()

  test: () ->

    config = JSON.parse require('fs').readFileSync(process.env.HOME + '/.bux-config.json')

    bux.profile (err, data) ->
      console.log data

module.exports =
  Server: BUXServer
  version: BUXServerVersion
  create: (config) ->
    return new BUXServer(config)

