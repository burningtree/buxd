BUX = require 'libbux'
async = require 'async'
fs = require 'fs'
Path = require 'path'
yaml = require 'js-yaml'
defaultsDeep = require 'lodash.defaultsdeep'

BUXdVersion = '0.1.0';

class BUXd

  interfaces: {}
  plugins: {}
  counters: {}
    
  constructor: (@opts) ->
    @debug = require('debug')('buxd:main')
    @debug "opts: #{@opts}"

  start: (callback) ->
    @debug "Initializing BUXd .."

    @loadConfig =>
      @debug "Config loaded"

      if !@config.account?.access_token
        throw @exception "No access_token! Please run 'buxd auth'"

      @bux = new BUX.api(access_token: @config.account.access_token)

      @debug "Loading plugins .."
      @loadPlugins =>
        @debug "Plugins loaded"

        @debug "Starting interfaces .."
        @loadInterfaces =>
          @debug "Interfaces loaded"

          @uptime = new Date()

          console.log "BUXd #{@version()} started [libbux #{BUX.version}]"
          console.log "Loaded interfaces: #{Object.keys(@interfaces).join(', ')}"
          console.log "Loaded plugins: #{Object.keys(@plugins).join(', ')}"
          if callback then return callback()
          return true

  loadPlugins: (callback) ->

    async.each Object.keys(@config.plugins), (pn, next) =>
      pc = @config.plugins[pn]
      if pc == false then return next()

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

  loadConfig: (callback) ->
    defaultConfigFile = Path.resolve(__dirname, '..', 'buxd.default.yaml')
    defaultConfig = yaml.load fs.readFileSync(defaultConfigFile)

    configFile = @opts.config || './buxd.yaml'

    if !fs.existsSync(configFile)
      throw new @exception "Config file not found: #{configFile}"

    @debug "Loading config: #{configFile}"
    @config = defaultsDeep yaml.load(fs.readFileSync(configFile)), defaultConfig

    #@config.account = { access_token: JSON.parse(fs.readFileSync(process.env.HOME+'/.bux-config.json')).account.access_token }
    callback()

  execPlugin: (plugin, opts, callback) ->
    cmd = opts.cmd || 'get'
    if !@plugins[plugin][cmd] then return callback 'not found'

    @plugins[plugin][cmd] (value) =>
      @updateCounter "exec.#{plugin}.#{cmd}"
      callback null, value

  updateCounter: (type) ->
    if !@counters[type] then @counters[type] = 0
    @counters[type]++
    return true

  exception: (msg) ->
    console.log msg
    process.exit()

  version: () ->
    return BUXdVersion;

module.exports =

  login: (opts) ->
    prompt = require 'prompt'
    prompt.message = ''
    prompt.delimited = ''
    prompt.start()

    schema =
      properties:
        email: { description: 'Email' }
        password: { description: 'Password', hidden: true }

    prompt.get schema, (err, result) ->
      if err then throw err

      bux = new BUX.api()
      bux.login result, (err, res) ->
        if err then throw 'Login error'

        console.log "Login success!"
        console.log "access_token = #{res.access_token}"

        fn = opts.config || "./buxd.yaml"
        schema = { properties: { answer: { description: "Do you want write it to '#{fn}'? [y]" }}}
        prompt.get schema, (err, result) ->
          if err then throw err
          prompt.stop()

          if result.answer in [ '', 'y' ]
            output = {}
            if fs.existsSync(fn)
              output = yaml.load fs.readFileSync(fn)

            if !output.account then output.account = {}
            output.account.access_token = res.access_token
            fs.writeFileSync fn, yaml.dump(output)
            console.log "Done. Token writed to file: #{fn}"


  BUXd: BUXd
  version: BUXdVersion
  create: (config) -> return new BUXd(config)

