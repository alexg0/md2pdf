#!/usr/bin/env bats

load test_helper

@test "resolve_output_file defaults to .pdf extension" {
  cp "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/sample.md"
  run "$MD2PDF" "$TEST_TEMP_DIR/sample.md"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/sample.pdf" ]
}

@test "resolve_output_file uses explicit output when set" {
  run "$MD2PDF" "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/custom.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/custom.pdf" ]
}

@test "resolve_output_file preserves directory of input" {
  local subdir="$TEST_TEMP_DIR/subdir"
  mkdir -p "$subdir"
  cp "$FIXTURES_DIR/sample.md" "$subdir/doc.md"
  run "$MD2PDF" "$subdir/doc.md"
  [ "$status" -eq 0 ]
  [ -f "$subdir/doc.pdf" ]
}

@test "auto-creates parent directory of output path" {
  local nested="$TEST_TEMP_DIR/out/nested/deeper"
  [ ! -d "$nested" ]
  run "$MD2PDF" "$FIXTURES_DIR/sample.md" "$nested/x.pdf"
  [ "$status" -eq 0 ]
  [ -f "$nested/x.pdf" ]
}
