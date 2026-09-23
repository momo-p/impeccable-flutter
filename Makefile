DETECTOR := detector
LINT := lint
P ?= detector/test/fixtures
TARGET ?= phone

.PHONY: all check test analyze detect rules signals example registry build install clean

all: check

## check: everything CI would run
check: analyze test

analyze:
	cd $(DETECTOR) && dart analyze
	cd $(LINT) && dart analyze

test:
	cd $(DETECTOR) && dart test
	cd $(LINT) && dart test

## detect: run the detector over a Flutter project — make detect P=path/to/lib [TARGET=tv]
detect:
	cd $(DETECTOR) && dart run bin/impeccable_flutter.dart detect $(abspath $(P)) --target $(TARGET)

## signals: report what a project already is — make signals P=path/to/app
signals:
	cd $(DETECTOR) && dart run bin/impeccable_flutter.dart signals $(abspath $(P))

## example: run the detector over examples/watchlist
example: build
	@echo "--- before (phone): expect findings ---"
	@$(DETECTOR)/build/impeccable-flutter detect examples/watchlist/lib/screens/library_before.dart | tail -2
	@echo "--- after (phone): expect none ---"
	@$(DETECTOR)/build/impeccable-flutter detect examples/watchlist/lib/screens/library_after.dart
	@echo "--- tv: expect none ---"
	@$(DETECTOR)/build/impeccable-flutter detect examples/watchlist/lib/screens/library_tv.dart --target tv
	@echo "--- theme: expect none ---"
	@$(DETECTOR)/build/impeccable-flutter detect examples/watchlist/lib/theme.dart

## build: compile the standalone detector binary (no Dart needed to run it)
build:
	@mkdir -p $(DETECTOR)/build
	cd $(DETECTOR) && dart compile exe bin/impeccable_flutter.dart \
	  -o build/impeccable-flutter

## install: put the launcher on PATH (override with PREFIX=)
PREFIX ?= $(HOME)/.local/bin
install: build
	@mkdir -p $(PREFIX)
	ln -sf $(abspath skills/impeccable-flutter/scripts/impeccable-flutter) \
	  $(PREFIX)/impeccable-flutter
	@echo "linked $(PREFIX)/impeccable-flutter"
	@command -v impeccable-flutter >/dev/null 2>&1 \
	  || echo "note: $(PREFIX) is not on your PATH"

## rules: print the rule catalog
rules:
	cd $(DETECTOR) && dart run bin/impeccable_flutter.dart rules

## registry: re-extract the upstream Rust catalog — make registry SRC=path/to/impeccable
registry:
	@test -n "$(SRC)" || { echo "usage: make registry SRC=<impeccable checkout>"; exit 64; }
	perl tool/extract_registry.pl "$(SRC)" > tool/upstream_registry.json
	@echo "extracted $$(grep -c '\"id\"' tool/upstream_registry.json) rules"

clean:
	rm -rf 100 1 100DETECTOR)/.dart_tool 100 1 100DETECTOR)/build 100 1 100LINT)/.dart_tool
