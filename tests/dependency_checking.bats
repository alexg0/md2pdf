#!/usr/bin/env bats

load test_helper

@test "--list-modes exits 0 and shows all modes" {
  run "$MD2PDF" --list-modes
  [ "$status" -eq 0 ]
  [[ "$output" == *"pandoc-xelatex"* ]]
  [[ "$output" == *"pandoc-lualatex"* ]]
  [[ "$output" == *"pandoc-pdflatex"* ]]
  [[ "$output" == *"md-to-pdf"* ]]
  [[ "$output" == *"mdpdf"* ]]
  [[ "$output" == *"go-md2pdf"* ]]
  [[ "$output" == *"weasy-md2pdf"* ]]
  [[ "$output" == *"percollate"* ]]
}

@test "--list-modes shows status for each mode" {
  run "$MD2PDF" --list-modes
  [ "$status" -eq 0 ]
  [[ "$output" == *"status="* ]]
}

@test "--mode-help shows info for default mode" {
  run "$MD2PDF" --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"pandoc-xelatex"* ]]
}

@test "--mode-help shows info for each mode" {
  for m in pandoc-xelatex pandoc-lualatex pandoc-pdflatex pandoc-wkhtmltopdf pandoc-weasyprint md-to-pdf mdpdf go-md2pdf weasy-md2pdf percollate; do
    run "$MD2PDF" --mode "$m" --mode-help
    [ "$status" -eq 0 ]
    [ -n "$output" ]
  done
}

@test "have_cmd finds bash" {
  load_md2pdf_functions
  run have_cmd bash
  [ "$status" -eq 0 ]
}

@test "have_cmd rejects nonexistent command" {
  load_md2pdf_functions
  run have_cmd __nonexistent_command_xyz__
  [ "$status" -eq 1 ]
}

@test "check_mode_deps fails for unknown mode" {
  load_md2pdf_functions
  run check_mode_deps "not-a-mode"
  [ "$status" -ne 0 ]
}
