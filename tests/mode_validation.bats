#!/usr/bin/env bats

load test_helper

@test "docx alias resolves to pandoc-docx" {
  run "$MD2PDF" --mode docx --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"DOCX"* ]]
}

@test "word alias resolves to pandoc-docx" {
  run "$MD2PDF" --mode word --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"DOCX"* ]]
}

@test "alias_tag for pandoc-docx shown in --list-modes" {
  run "$MD2PDF" --list-modes
  [ "$status" -eq 0 ]
  [[ "$output" == *"[aliases: docx, word]"* ]]
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
  [[ "$output" == *"Pandoc -> DOCX"* ]]
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

@test "all modes are accepted and have help" {
  for m in pandoc-xelatex pandoc-lualatex pandoc-pdflatex pandoc-wkhtmltopdf pandoc-weasyprint md-to-pdf mdpdf go-md2pdf weasy-md2pdf percollate pandoc-docx; do
    run "$MD2PDF" --mode "$m" --mode-help
    [ "$status" -eq 0 ]
    [ -n "$output" ]
  done
}
