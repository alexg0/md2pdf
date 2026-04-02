#!/usr/bin/env bats

load test_helper

@test "resolve_output_file defaults to .pdf extension" {
  load_md2pdf_functions
  result="$(resolve_output_file "$FIXTURES_DIR/sample.md")"
  [ "$result" = "$FIXTURES_DIR/sample.pdf" ]
}

@test "resolve_output_file uses explicit output when set" {
  load_md2pdf_functions
  output_file="/tmp/custom.pdf"
  result="$(resolve_output_file "$FIXTURES_DIR/sample.md")"
  [ "$result" = "/tmp/custom.pdf" ]
}

@test "resolve_output_file preserves directory of input" {
  load_md2pdf_functions
  result="$(resolve_output_file "/some/path/doc.md")"
  [ "$result" = "/some/path/doc.pdf" ]
}

@test "resolve_output_file handles filename without path" {
  load_md2pdf_functions
  result="$(resolve_output_file "readme.md")"
  [ "$result" = "./readme.pdf" ]
}
