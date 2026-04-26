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
  [[ "$output" == *"XeLaTeX"* ]]
}

@test "--mode-help shows info for each mode" {
  for m in pandoc-xelatex pandoc-lualatex pandoc-pdflatex pandoc-wkhtmltopdf pandoc-weasyprint md-to-pdf mdpdf go-md2pdf weasy-md2pdf percollate; do
    run "$MD2PDF" --mode "$m" --mode-help
    [ "$status" -eq 0 ]
    [ -n "$output" ]
  done
}

@test "--check-deps succeeds for pandoc-xelatex when pandoc and xelatex are installed" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  run "$MD2PDF" --check-deps
  [ "$status" -eq 0 ]
  [[ "$output" == *"dependencies OK"* ]]
}

@test "--check-deps fails for unknown mode" {
  run "$MD2PDF" --mode not-a-mode --check-deps
  [ "$status" -ne 0 ]
}
