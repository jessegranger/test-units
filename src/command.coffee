
{ echo, warn, die } = require "./common"

opts = require('optimist').argv
echo "OPTS:", opts

verbose = if opts.verbose or opts.v then echo else ->
cmd = opts._

switch cmd
	when "run" then warn "TODO: run all tests"
	else warn "Unknown command: #{cmd}"
