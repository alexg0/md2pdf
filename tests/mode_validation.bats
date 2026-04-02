#!/usr/bin/env bats

load test_helper

@test "valid mode accepted: pandoc-xelatex" {
  run "$MD2PDF" --mode pandoc-xelatex --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: latex alias" {
  run "$MD2PDF" --mode latex --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: pandoc-lualatex" {
  run "$MD2PDF" --mode pandoc-lualatex --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: pandoc-pdflatex" {
  run "$MD2PDF" --mode pandoc-pdflatex --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: pandoc-wkhtmltopdf" {
  run "$MD2PDF" --mode pandoc-wkhtmltopdf --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: pandoc-weasyprint" {
  run "$MD2PDF" --mode pandoc-weasyprint --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: md-to-pdf" {
  run "$MD2PDF" --mode md-to-pdf --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: mdpdf" {
  run "$MD2PDF" --mode mdpdf --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: go-md2pdf" {
  run "$MD2PDF" --mode go-md2pdf --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: weasy-md2pdf" {
  run "$MD2PDF" --mode weasy-md2pdf --mode-help
  [ "$status" -eq 0 ]
}

@test "valid mode accepted: percollate" {
  run "$MD2PDF" --mode percollate --mode-help
  [ "$status" -eq 0 ]
}

@test "invalid mode rejected" {
  run "$MD2PDF" --mode not-a-mode --mode-help
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown mode"* ]]
}

@test "empty mode rejected" {
  run "$MD2PDF" --mode "" --mode-help
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown mode"* ]]
}

@test "latex alias shows XeLaTeX help" {
  run "$MD2PDF" --mode latex --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"XeLaTeX"* ]]
}

@test "mode_label shown in --list-modes for each mode" {
  run "$MD2PDF" --list-modes
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pandoc + XeLaTeX"* ]]
  [[ "$output" == *"Pandoc + LuaLaTeX"* ]]
  [[ "$output" == *"Pandoc + pdfLaTeX"* ]]
  [[ "$output" == *"Pandoc + wkhtmltopdf"* ]]
  [[ "$output" == *"Pandoc + WeasyPrint"* ]]
  [[ "$output" == *"Node/Puppeteer (md-to-pdf)"* ]]
  [[ "$output" == *"Node/Puppeteer (mdpdf)"* ]]
  [[ "$output" == *"Go/fpdf"* ]]
  [[ "$output" == *"Python/WeasyPrint"* ]]
  [[ "$output" == *"Experimental HTML-first"* ]]
}

@test "mode_runtime shown in --list-modes" {
  run "$MD2PDF" --list-modes
  [ "$status" -eq 0 ]
  [[ "$output" == *"runtime=pandoc, xelatex"* ]]
  [[ "$output" == *"runtime=pandoc, lualatex"* ]]
  [[ "$output" == *"runtime=pandoc, pdflatex"* ]]
  [[ "$output" == *"runtime=node, npm"* ]]
  [[ "$output" == *"runtime=go"* ]]
  [[ "$output" == *"runtime=python3, brew"* ]]
  [[ "$output" == *"runtime=pandoc, node, npm"* ]]
}

@test "mode_note is non-empty for all modes" {
  for m in pandoc-xelatex pandoc-lualatex pandoc-pdflatex pandoc-wkhtmltopdf pandoc-weasyprint md-to-pdf mdpdf go-md2pdf weasy-md2pdf percollate; do
    run "$MD2PDF" --mode "$m" --mode-help
    [ "$status" -eq 0 ]
    [ -n "$output" ]
  done
}
