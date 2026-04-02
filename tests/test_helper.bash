#!/usr/bin/env bash

# Absolute path to the md2pdf.sh script
MD2PDF="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/md2pdf.sh"

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

# Source md2pdf.sh to expose internal functions for unit testing.
# The main guard prevents parse_args/run_action from executing.
load_md2pdf_functions() {
  source "$MD2PDF"
}
