
{ suite, test, suiteSetup, suiteTeardown,
	beforeEachTest, afterEachTest, assert } = require '../src/index'

suite "Basic system", ->
	test "Can pass", (ok) -> ok()
	test "The done callback is optional", ->

suite "Basic system with async creation", (endSuite) ->
	test "Can pass", ->
	endSuite()

suite "Parallel tests", { parallel: 8 }, (ready) ->
	testCount = 10
	for i in [0..testCount] by 1 then do (i) ->
		test "One of many (#{i}/#{testCount})", { shouldFail: (i is testCount - 3) }, (ok) ->
			if i is testCount - 3 then ok(new Error("should fail"))
			else setTimeout ok, Math.floor(Math.random()*1000)
	ready()

suite "Can use suiteSetup() asynchronously", (endSuite) ->

	setupStarted = setupFinished = false
	suiteSetup (done) ->
		setupStarted = true
		setTimeout (->
			setupFinished = true
			done()
		), 500

	test "Got past suiteSetup()", ->
		assert.ok setupStarted, "suiteSetup should have started"
		assert.ok setupFinished, "suiteSetup should have finished before the test ran"

	endSuite()

do ->
	teardownCount = 0
	suite "Can use suiteTeardown()", ->
		suiteTeardown -> teardownCount += 1
		test "setupCount should be 1", -> assert.equal setupCount, 1

	suite "Can verify suiteTeardown() ran", ->
		test "teardownCount should be 1", -> assert.equal teardownCount, 1

suite "Can use beforeEachTest and afterEachTest", (ready) ->
	beforeCounter = afterCounter = 0
	beforeEachTest -> beforeCounter += 1
	afterEachTest -> afterCounter += 1
	test "Test 1", -> assert.equal afterCounter, beforeCounter - 1
	test "Test 2", -> assert.equal afterCounter, beforeCounter - 1
	test "Test 3", -> assert.equal afterCounter, beforeCounter - 1
	test "Test 4", -> assert.equal afterCounter, beforeCounter - 1
	test "Test 5", -> assert.equal afterCounter, beforeCounter - 1
	test "Final Test", ->
		assert.equal beforeCounter, 6
		assert.equal afterCounter, 5
