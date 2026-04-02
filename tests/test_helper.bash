#!/usr/bin/env bash

# Absolute path to the md2pdf script
MD2PDF="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/md2pdf"

# Directory containing test fixtures
FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"

setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export MD2PDF_TOOL_HOME="$TEST_TEMP_DIR/tool_home"
  mkdir -p "$MD2PDF_TOOL_HOME"
}

teardown() {
  if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}
