#!/usr/bin/env bash

# Absolute path to the md2pdf script
MD2PDF="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/md2pdf"

# Directory containing test fixtures
FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"

# Shared executables used by tests that exercise pandoc modes without invoking
# a real PDF engine. Per-test shims remain first in PATH so tests can override
# individual tools without rewriting these common fixtures.
FAKE_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/fake-bin" && pwd)"

has_pandoc_xelatex() {
  command -v pandoc >/dev/null 2>&1 && command -v xelatex >/dev/null 2>&1
}

setup_fake_pandoc() {
  mkdir -p "$TEST_TEMP_DIR/fake-bin"
  export PATH="$TEST_TEMP_DIR/fake-bin:$FAKE_BIN_DIR:$PATH"
  export MD2PDF_PANDOC_ARGS_LOG="$TEST_TEMP_DIR/pandoc-args.txt"
  export MD2PDF_PANDOC_INPUT_LOG="$TEST_TEMP_DIR/pandoc-input.md"
  export MD2PDF_PANDOC_CSS_LOG="$TEST_TEMP_DIR/pandoc-css.txt"
}

write_doc() {
  local path="$1"
  shift
  printf '%s\n' "$@" > "$path"
}

assert_arg_present() {
  grep -qx -- "$1" "$MD2PDF_PANDOC_ARGS_LOG"
}

assert_arg_absent() {
  ! grep -qx -- "$1" "$MD2PDF_PANDOC_ARGS_LOG"
}

setup() {
  TEST_TEMP_DIR="$BATS_TEST_TMPDIR"
  export MD2PDF_TOOL_HOME="$TEST_TEMP_DIR/tool_home"
  mkdir -p "$MD2PDF_TOOL_HOME"
}
