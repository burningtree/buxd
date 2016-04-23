program = require 'commander'
BUXd = require './buxd'

program
  .version BUXd.version
  .option '--debug', 'Debug'
  .parse process.argv

if program.debug
  process.env.DEBUG = 'libbux:*,buxd:*'

buxd = BUXd.create()
buxd.start()

