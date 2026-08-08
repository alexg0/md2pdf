#!/usr/bin/env bash

# Absolute path to the md2pdf script
MD2PDF="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/md2pdf"

# Directory containing test fixtures
FIXTURES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"

has_pandoc_xelatex() {
  command -v pandoc >/dev/null 2>&1 && command -v xelatex >/dev/null 2>&1
}

setup_fake_pandoc() {
  mkdir -p "$TEST_TEMP_DIR/fake-bin"

  for engine in xelatex lualatex pdflatex; do
    cat > "$TEST_TEMP_DIR/fake-bin/$engine" <<'SH'
#!/usr/bin/env bash
exit 0
SH
    chmod +x "$TEST_TEMP_DIR/fake-bin/$engine"
  done

  cat > "$TEST_TEMP_DIR/fake-bin/pandoc" <<'SH'
#!/usr/bin/env bash
[ -n "$MD2PDF_PANDOC_ARGS_LOG" ] && printf '%s\n' "$@" > "$MD2PDF_PANDOC_ARGS_LOG"
[ -n "$MD2PDF_PANDOC_INPUT_LOG" ] && cp "$1" "$MD2PDF_PANDOC_INPUT_LOG"
saved_args=("$@")
while [ "$#" -gt 0 ]; do
  if [ "$1" = "--css" ]; then
    shift
    [ -n "$MD2PDF_PANDOC_CSS_LOG" ] && [ -f "$1" ] && cp "$1" "$MD2PDF_PANDOC_CSS_LOG"
  fi
  shift
done
set -- "${saved_args[@]}"
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    shift
    touch "$1"
    exit 0
  fi
  shift
done
exit 0
SH

  chmod +x "$TEST_TEMP_DIR/fake-bin/pandoc"
  export PATH="$TEST_TEMP_DIR/fake-bin:$PATH"
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
  TEST_TEMP_DIR="$(mktemp -d)"
  export MD2PDF_TOOL_HOME="$TEST_TEMP_DIR/tool_home"
  mkdir -p "$MD2PDF_TOOL_HOME"
}

teardown() {
  if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}
