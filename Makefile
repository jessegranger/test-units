
MINIFY=cat

SRC_FILES=$(wildcard src/**.coffee)
BUILD_FILES=$(subst src/,dist/,$(subst .coffee,.js,${SRC_FILES}))
COFFEE=node_modules/.bin/coffee

all: ${BUILD_FILES}

test: ${BUILD_FILES}
	@echo SRC_FILES=${SRC_FILES}
	@echo BUILD_FILES=${BUILD_FILES}
	coffee test/index.coffee

dist:
	# Building $@:
	mkdir -p dist

dist/%.js: src/%.coffee
	# Building $@:
	${COFFEE} -sc --no-header < $^ > $@

clean:
	rm -f dist/*.js

.PHONY: clean test all
