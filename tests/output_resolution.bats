#!/usr/bin/env bats

load test_helper

@test "resolve_output_file defaults to .pdf extension" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  cp "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/sample.md"
  run "$MD2PDF" "$TEST_TEMP_DIR/sample.md"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/sample.pdf" ]
}

@test "resolve_output_file uses explicit output when set" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  run "$MD2PDF" "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/custom.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/custom.pdf" ]
}

@test "resolve_output_file preserves directory of input" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  local subdir="$TEST_TEMP_DIR/subdir"
  mkdir -p "$subdir"
  cp "$FIXTURES_DIR/sample.md" "$subdir/doc.md"
  run "$MD2PDF" "$subdir/doc.md"
  [ "$status" -eq 0 ]
  [ -f "$subdir/doc.pdf" ]
}

@test "auto-creates parent directory of output path" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  local nested="$TEST_TEMP_DIR/out/nested/deeper"
  [ ! -d "$nested" ]
  run "$MD2PDF" "$FIXTURES_DIR/sample.md" "$nested/x.pdf"
  [ "$status" -eq 0 ]
  [ -f "$nested/x.pdf" ]
}

@test "pandoc-docx defaults output extension to .docx" {
  command -v pandoc >/dev/null 2>&1 || skip "pandoc not available"
  cp "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/sample.md"
  run "$MD2PDF" --mode pandoc-docx "$TEST_TEMP_DIR/sample.md"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/sample.docx" ]
  [ ! -f "$TEST_TEMP_DIR/sample.pdf" ]
}

@test "pandoc-docx accepts trailing .docx as output positional" {
  command -v pandoc >/dev/null 2>&1 || skip "pandoc not available"
  run "$MD2PDF" --mode pandoc-docx "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/explicit.docx"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/explicit.docx" ]
}

@test "pandoc-docx multi-input with trailing .docx concatenates" {
  command -v pandoc >/dev/null 2>&1 || skip "pandoc not available"
  run "$MD2PDF" --mode pandoc-docx "$FIXTURES_DIR/sample.md" "$FIXTURES_DIR/no-heading.md" "$TEST_TEMP_DIR/concat.docx"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/concat.docx" ]
}

@test "missing --reference-doc file aborts" {
  run "$MD2PDF" --mode pandoc-docx --reference-doc "$TEST_TEMP_DIR/nope.docx" "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/out.docx"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Reference doc not found"* ]]
}

@test "--reference-doc warns when used outside pandoc-docx" {
  run "$MD2PDF" --mode pandoc-xelatex --reference-doc "$TEST_TEMP_DIR/anything.docx" --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"ignores --reference-doc"* ]]
}

@test "pandoc-docx output has updateFields=true so Word populates TOC on open" {
  command -v pandoc >/dev/null 2>&1 || skip "pandoc not available"
  command -v unzip >/dev/null 2>&1 || skip "unzip not available"
  run "$MD2PDF" --mode pandoc-docx --toc "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/withtoc.docx"
  [ "$status" -eq 0 ]
  run unzip -p "$TEST_TEMP_DIR/withtoc.docx" word/settings.xml
  [ "$status" -eq 0 ]
  [[ "$output" == *'<w:updateFields w:val="true"/>'* ]]
}
