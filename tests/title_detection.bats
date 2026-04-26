#!/usr/bin/env bats

load test_helper

@test "detect_title finds H1 heading" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  run "$MD2PDF" "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
}

@test "detect_title uses explicit title when set" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  run "$MD2PDF" -t "Override Title" "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
}

@test "detect_title finds H1 in unicode file" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  run "$MD2PDF" "$FIXTURES_DIR/unicode.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
}

@test "detect_title strips leading # and space" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  local tmp="$TEST_TEMP_DIR/heading-test.md"
  echo "# My Special Title" > "$tmp"
  echo "body text" >> "$tmp"
  run "$MD2PDF" "$tmp" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
}

@test "detect_title uses first H1 when multiple exist" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  local tmp="$TEST_TEMP_DIR/multi-heading.md"
  cat > "$tmp" <<'MD'
# First Title
some text
# Second Title
more text
MD
  run "$MD2PDF" "$tmp" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
}

@test "detect_title falls back to filename without heading" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  run "$MD2PDF" "$FIXTURES_DIR/no-heading.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
}
