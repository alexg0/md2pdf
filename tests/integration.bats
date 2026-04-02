#!/usr/bin/env bats

load test_helper

has_pandoc_xelatex() {
  command -v pandoc >/dev/null 2>&1 && command -v xelatex >/dev/null 2>&1
}

@test "end-to-end PDF generation with pandoc-xelatex" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local output_pdf="$TEST_TEMP_DIR/sample.pdf"
  run "$MD2PDF" --no-toc "$FIXTURES_DIR/sample.md" "$output_pdf"
  [ "$status" -eq 0 ]
  [ -f "$output_pdf" ]
  [ -s "$output_pdf" ]
}

@test "PDF generation with custom title and author" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local output_pdf="$TEST_TEMP_DIR/titled.pdf"
  run "$MD2PDF" --no-toc -t "Custom Title" -a "Test Author" "$FIXTURES_DIR/sample.md" "$output_pdf"
  [ "$status" -eq 0 ]
  [ -f "$output_pdf" ]
  [ -s "$output_pdf" ]
}

@test "PDF generation with no page numbers" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local output_pdf="$TEST_TEMP_DIR/no-pages.pdf"
  run "$MD2PDF" --no-toc --no-page-numbers "$FIXTURES_DIR/sample.md" "$output_pdf"
  [ "$status" -eq 0 ]
  [ -f "$output_pdf" ]
  [ -s "$output_pdf" ]
}

@test "PDF generation with custom margin and fontsize" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local output_pdf="$TEST_TEMP_DIR/custom.pdf"
  run "$MD2PDF" --no-toc -m "0.5in" -s "12pt" "$FIXTURES_DIR/sample.md" "$output_pdf"
  [ "$status" -eq 0 ]
  [ -f "$output_pdf" ]
  [ -s "$output_pdf" ]
}

@test "PDF default output filename matches input" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  # Copy fixture to temp dir so we control the output location
  cp "$FIXTURES_DIR/sample.md" "$TEST_TEMP_DIR/sample.md"
  run "$MD2PDF" --no-toc "$TEST_TEMP_DIR/sample.md"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/sample.pdf" ]
}

@test "render fails on missing input file" {
  run "$MD2PDF" nonexistent-file.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "render fails with no input file" {
  run "$MD2PDF"
  [ "$status" -ne 0 ]
}

@test "complex report with tables and bold/italic converts with pandoc-xelatex" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local output_pdf="$TEST_TEMP_DIR/complex-report.pdf"
  run "$MD2PDF" --no-toc "$FIXTURES_DIR/complex-report.md" "$output_pdf"
  [ "$status" -eq 0 ]
  [ -f "$output_pdf" ]
  [ -s "$output_pdf" ]
}

@test "unicode file converts with pandoc-xelatex" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local output_pdf="$TEST_TEMP_DIR/unicode.pdf"
  run "$MD2PDF" --no-toc "$FIXTURES_DIR/unicode.md" "$output_pdf"
  [ "$status" -eq 0 ]
  [ -f "$output_pdf" ]
  [ -s "$output_pdf" ]
}
