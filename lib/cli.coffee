program = require 'commander'
BUXd = require './buxd'

makeOpts = (p) ->
  if p.debug
    process.env.DEBUG = 'libbux:*,buxd:*'
  opts =
    config: p.config
  return opts

commands =
  cmd_start: (p, opts) ->
    buxd = BUXd.create opts
    buxd.start()

  cmd_auth: (p, opts) ->
    BUXd.login opts

program
  .version BUXd.version
  .option '-c, --config <file>', 'Set config file'
  .option '    --debug', 'Debug'
  .action (cmd) ->

    target = commands["cmd_#{cmd}"]
    if !target
      console.log "Command not found: #{cmd}"
      return program.outputHelp()

    target program, makeOpts(program)

program
  .command 'start'
  .description 'Start BUXd'

program
  .command 'auth'
  .description 'Get access token'

program.parse process.argv

if not process.argv[2] then program.outputHelp()

