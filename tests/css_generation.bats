#!/usr/bin/env bats

load test_helper

@test "custom margin produces valid PDF" {
  run "$MD2PDF" -m "2in" "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out.pdf" ]
}

@test "custom fontsize produces valid PDF" {
  run "$MD2PDF" -s "14pt" "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out.pdf" ]
}

@test "custom font produces valid PDF" {
  run "$MD2PDF" --font "Helvetica" "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out.pdf" ]
}

@test "no-page-numbers produces valid PDF" {
  run "$MD2PDF" --no-page-numbers "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out.pdf" ]
}

@test "page-numbers produces valid PDF" {
  run "$MD2PDF" --page-numbers "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out.pdf" ]
}
