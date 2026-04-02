#!/usr/bin/env bats

load test_helper

@test "detect_title finds H1 heading" {
  load_md2pdf_functions
  result="$(detect_title "$FIXTURES_DIR/sample.md")"
  [ "$result" = "Sample Document" ]
}

@test "detect_title falls back to filename without heading" {
  load_md2pdf_functions
  result="$(detect_title "$FIXTURES_DIR/no-heading.md")"
  [ "$result" = "no-heading" ]
}

@test "detect_title uses explicit title when set" {
  load_md2pdf_functions
  title="Override Title"
  result="$(detect_title "$FIXTURES_DIR/sample.md")"
  [ "$result" = "Override Title" ]
}

@test "detect_title finds H1 in unicode file" {
  load_md2pdf_functions
  result="$(detect_title "$FIXTURES_DIR/unicode.md")"
  [ "$result" = "Unicode Test" ]
}

@test "detect_title strips leading # and space" {
  local tmp="$TEST_TEMP_DIR/heading-test.md"
  echo "# My Special Title" > "$tmp"
  echo "body text" >> "$tmp"
  load_md2pdf_functions
  result="$(detect_title "$tmp")"
  [ "$result" = "My Special Title" ]
}

@test "detect_title uses first H1 when multiple exist" {
  local tmp="$TEST_TEMP_DIR/multi-heading.md"
  cat > "$tmp" <<'MD'
# First Title
some text
# Second Title
more text
MD
  load_md2pdf_functions
  result="$(detect_title "$tmp")"
  [ "$result" = "First Title" ]
}
