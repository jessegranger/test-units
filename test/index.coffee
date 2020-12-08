
{ suite, test, suiteSetup, suiteTeardown,
	beforeEachTest, afterEachTest, assert } = require '../src/index'

suite "suite()", ->
	test "test (sync)", ->
	test "test (sync) should fail", { shouldFail: true }, -> throw new Error('should fail')
	test "test (callback)", (ok) -> ok()
	test "test (async) returns a Promise", -> new Promise((resolve) -> setTimeout(resolve, 300))
	test "test (async) rejects a Promise", { shouldFail: true }, -> new Promise((_, reject) -> setTimeout((-> reject(123)), 300))
	test "test (async) awaits a Promise", -> assert.equal 42, await new Promise (resolve) -> setTimeout (-> resolve 42), 300
	test "test (async) fails", { shouldFail: true }, -> assert.equal 43, await new Promise (resolve) -> setTimeout (-> resolve 42), 300

suite "suite (callback)", (endSuite) ->
	test "test (sync)", ->
	test "test (async)", (ok) -> ok()
	endSuite()

suite "suite (parallel)", { parallel: 8 }, (ready) ->
	testCount = 10
	for i in [0..testCount] by 1 then do (i) ->
		test "test (#{i}/#{testCount})", { shouldFail: (i is testCount - 3) }, (ok) ->
			if i is testCount - 3 then ok(new Error("should fail"))
			else setTimeout ok, Math.floor(Math.random()*1000)
	ready()

suite "suiteSetup()", (endSuite) ->

	setupStarted = setupFinished = false
	suiteSetup (done) ->
		setupStarted = true
		setTimeout (->
			setupFinished = true
			done()
		), 500

	test "should run before any test", ->
		assert.ok setupStarted, "suiteSetup should have started"
		assert.ok setupFinished, "suiteSetup should have finished before the test ran"

	endSuite()

do ->
	teardownCount = 0
	suite "suiteTeardown() should not", ->
		suiteTeardown -> teardownCount += 1
		test "run before", -> assert.equal teardownCount, 0

	suite "suiteTeardown() should", ->
		test "run after", -> assert.equal teardownCount, 1

suite "beforeEachTest()", (ready) ->
	beforeCounter = 0
	beforeEachTest -> beforeCounter += 1
	test "Test 1", -> assert.equal beforeCounter, 1
	test "Test 2", -> assert.equal beforeCounter, 2
	test "Test 3", -> assert.equal beforeCounter, 3

suite "afterEachTest()", (ready) ->
	afterCounter = 0
	afterEachTest -> afterCounter += 1
	test "Test 1", -> assert.equal afterCounter, 0
	test "Test 2", -> assert.equal afterCounter, 1
	test "Test 3", -> assert.equal afterCounter, 2
