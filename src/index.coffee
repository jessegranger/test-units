{ echo, warn, die, debounce, red, green } = require './common'
Async = require 'async'

# calling suite just registers tests
# all the suites register themselves, in serial
# then on a debounce, start running the actual tests,
# either in parallel or serial

suites = new Map()

defaultRunOptions = {
	exitOnFail: true
	failMark: red "FAIL"
	passMark: green "PASS"
	echo: echo
}

runAllSuites = (runOpts) ->
	runOpts = Object.assign {}, defaultRunOptions, runOpts
	runOpts.echo "Starting runAllSuites..."
	testStarted = testPassed = testFailed = testCount = 0
	# first add up how much total work there is
	for [desc, suiteOpts] from suites
		testCount += suiteOpts.tests.size

	# then run the real tests with async handling
	Async.forEachSeries suites.keys(),
		(suite_key, suite_next) ->
			suiteOpts = suites.get(suite_key)
			parallel = Math.max(1, suiteOpts.parallel ? 1)
			try suiteOpts.suiteSetup (err) ->
				if err? then runOpts.echo progress(), "suiteSetup returned error:", err
				else Async.forEachLimit suiteOpts.tests.keys(), parallel,
					(test_key, test_next) ->
						# echo progress(), "Starting test:", test_key
						progress = -> "[#{testStarted}/#{testPassed+testFailed}/#{testCount}] #{suite_key} - #{test_key}"
						testStarted += 1
						timer = null
						fail = (err, label) ->
							testFailed += 1
							runOpts.echo progress(), runOpts.failMark, (label ? ""), (err ? "")
							fail = pass = (->) # ignore any future passes
							test_next if runOpts.exitOnFail then err else null
							null
						pass = ->
							testPassed += 1
							runOpts.echo progress(), runOpts.passMark
							fail = pass = (->) # ignore future failures
							test_next()
							null
						# get the test options from the tests Map
						testOpts = suiteOpts.tests.get(test_key)
						# register a timeout right away
						test_context = {
							timeout: (ms) ->
								clearTimeout timer
								timer = setTimeout (-> fail "Timed out after #{ms} ms"), ms
						}
						# set the default timeout
						test_context.timeout testOpts.timeout ? 10000
						try suiteOpts.beforeEachTest.call test_context, (err) ->
							if err then return fail(err)
							try testOpts.func.call test_context, (err) ->
								clearTimeout timer
								try suiteOpts.afterEachTest.call test_context, ->
									if err and not testOpts.shouldFail then fail(err)
									else pass()
								catch err then fail(err, "try afterEachTest")
								null
							catch err then fail(err, "try testOpts.func")
						catch err then fail(err, "try beforeEachTest")
					(err) ->
						try suiteOpts.suiteTeardown (err2) ->
							suite_next(err ? err2)
						catch err3
							suite_next(err3)
			catch err
				runOpts.echo "suiteSetup failed, err:", err
		(err) ->
			if err then die err
			else runOpts.echo "All tests complete [#{testPassed} passing, #{testFailed} failed]"

testPtr = null
suitePtr = null
suiteTimer = null

emptyHandler = (cb) -> cb()

# The AsyncFunction constructor is not normally exposed
AsyncFunction = `(async function() {}).constructor`

# Inspect func and if it doesn't accept a callback argument, add a wrapper that does.
ensureCallback = (func) -> return switch true
	when func.constructor is AsyncFunction then (cb) ->
		p = func() # return the underlying promise created by the async function
		p.then(->cb()).catch(cb)
		null
	when func.length is 0 then (cb) ->
		try
			ret = func()
			if ret?.constructor == Promise
				ret.then(-> cb()).catch(cb)
			else cb()
		catch err then cb(err)
		null
	else func

defaultSuiteOpts =
	parallel: false
	defaultTimeout: 10000
	suiteSetup: emptyHandler
	suiteTeardown: emptyHandler
	beforeEachTest: emptyHandler
	afterEachTest: emptyHandler
	echo: echo

suite = (desc, suiteOpts, func) ->
	if 'function' is typeof suiteOpts
		func = suiteOpts
		suiteOpts = {}
	unless 'function' is typeof func
		throw new Error("suite() requires a callback as the last argument")
	func = ensureCallback func
	suiteOpts = Object.assign {}, defaultSuiteOpts, suiteOpts
	suiteOpts.tests = testPtr = new Map()
	if suites.has desc
		throw new Error("suite() should not be called twice with the same suite identifier")
	suites.set desc, suiteOpts
	suitePtr = { desc, suiteOpts }
	# now invoke the body of the suite
	# this will load up data structures full of test parts, but will not start anything yet
	func (err) -> # now all the tests will register themselves
		if err? then die "Failed to create suite: #{desc} err:", err
		testPtr = null
		# each time the suite registers a new test, we push a timer forward
		# once we haven't registered any new tests, run them all
		suiteTimer = debounce suiteTimer, 100, runAllSuites
	suiteOpts.echo "Registered suite:", desc, "with", suiteOpts.tests.size, "tests"
	suitePtr = null

defaultTestOpts =
	shouldFail: false
	timeout: 10000

test = (desc, testOpts, func) ->
	if 'function' is typeof testOpts
		func = testOpts
		testOpts = {}
	testOpts = Object.assign {}, defaultTestOpts, testOpts
	testOpts.func = ensureCallback func
	testPtr?.set desc, testOpts
	null

suiteSetup     = (func) ->
	unless suitePtr then throw new Error("suiteSetup called outside suite()")
	unless suitePtr.suiteOpts then throw new Error("suitePtr.suiteOpts should exist already")
	suitePtr.suiteOpts.suiteSetup = ensureCallback func
	null
suiteTeardown  = (func) -> suitePtr and suitePtr.suiteOpts.suiteTeardown = ensureCallback func; null
beforeEachTest = (func) -> suitePtr and suitePtr.suiteOpts.beforeEachTest = ensureCallback func; null
afterEachTest  = (func) -> suitePtr and suitePtr.suiteOpts.afterEachTest = ensureCallback func; null


Object.assign module.exports, {
	suite, test,
	suiteSetup, suiteTeardown, beforeEachTest, afterEachTest,
	describe: suite, it: test,
	assert: require('assert')
}
