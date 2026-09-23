DETECTOR := detector
P ?= ../flutter-tests/apps/slop_app/lib
TARGET ?= phone

.PHONY: all check test analyze detect rules registry clean

all: check

## check: everything CI would run
check: analyze test

analyze:
	cd $(DETECTOR) && dart analyze

test:
	cd $(DETECTOR) && dart test

## detect: run the detector over a Flutter project — make detect P=path/to/lib [TARGET=tv]
detect:
	cd $(DETECTOR) && dart run bin/impeccable_flutter.dart detect $(abspath $(P)) --target $(TARGET)

## rules: print the rule catalog
rules:
	cd $(DETECTOR) && dart run bin/impeccable_flutter.dart rules

## registry: re-extract the upstream Rust catalog — make registry SRC=path/to/impeccable
registry:
	@test -n "$(SRC)" || { echo "usage: make registry SRC=<impeccable checkout>"; exit 64; }
	perl tool/extract_registry.pl "$(SRC)" > tool/upstream_registry.json
	@echo "extracted $$(grep -c '\"id\"' tool/upstream_registry.json) rules"

clean:
	rm -rf $(DETECTOR)/.dart_tool
