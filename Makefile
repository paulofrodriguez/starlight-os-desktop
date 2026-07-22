SHELL := /usr/bin/env bash

.PHONY: build build-fast package clean clean-purge test validate

build:
	./scripts/build.sh

build-fast:
	./scripts/build.sh --fast

package:
	./scripts/package.sh

clean:
	./scripts/clean.sh

clean-purge:
	./scripts/clean.sh --purge-cache

test:
	./scripts/test.sh

validate:
	./scripts/validate.sh
