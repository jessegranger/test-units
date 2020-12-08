

echo = console.log.bind(console)
warn = console.warn.bind(console)
TTY = require('tty')
forceColor = "--color" in process.argv
supportColor = forceColor or (TTY.isatty(1) and /(?:color|alacritty)/.test process.env.TERM)
red   = if supportColor then (word) -> "\x1B[38;2;255;0;0m#{word}\x1B[m" else (word) -> word
green = if supportColor then (word) -> "\x1B[38;2;0;255;0m#{word}\x1B[m" else (word) -> word
print = (args...) -> process.stdout.write args.join(" ")
die = (msg...) ->
	console.error new Error("Die: "+msg.map(String).join(" "))
	process.exit 1
debounce = (timer, ms, func) ->
	clearTimeout timer
	return setTimeout func, ms

Object.assign module.exports, { echo, warn, die, print, debounce, red, green }
