#!/usr/bin/env bats

load test_helper

@test "mode_exists accepts pandoc-xelatex" {
  load_md2pdf_functions
  run mode_exists "pandoc-xelatex"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts latex alias" {
  load_md2pdf_functions
  run mode_exists "latex"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts pandoc-lualatex" {
  load_md2pdf_functions
  run mode_exists "pandoc-lualatex"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts pandoc-pdflatex" {
  load_md2pdf_functions
  run mode_exists "pandoc-pdflatex"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts pandoc-wkhtmltopdf" {
  load_md2pdf_functions
  run mode_exists "pandoc-wkhtmltopdf"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts pandoc-weasyprint" {
  load_md2pdf_functions
  run mode_exists "pandoc-weasyprint"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts md-to-pdf" {
  load_md2pdf_functions
  run mode_exists "md-to-pdf"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts mdpdf" {
  load_md2pdf_functions
  run mode_exists "mdpdf"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts go-md2pdf" {
  load_md2pdf_functions
  run mode_exists "go-md2pdf"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts weasy-md2pdf" {
  load_md2pdf_functions
  run mode_exists "weasy-md2pdf"
  [ "$status" -eq 0 ]
}

@test "mode_exists accepts percollate" {
  load_md2pdf_functions
  run mode_exists "percollate"
  [ "$status" -eq 0 ]
}

@test "mode_exists rejects invalid mode" {
  load_md2pdf_functions
  run mode_exists "not-a-mode"
  [ "$status" -eq 1 ]
}

@test "mode_exists rejects empty string" {
  load_md2pdf_functions
  run mode_exists ""
  [ "$status" -eq 1 ]
}

@test "canonicalize_mode converts latex to pandoc-xelatex" {
  load_md2pdf_functions
  result="$(canonicalize_mode latex)"
  [ "$result" = "pandoc-xelatex" ]
}

@test "canonicalize_mode preserves pandoc-xelatex" {
  load_md2pdf_functions
  result="$(canonicalize_mode pandoc-xelatex)"
  [ "$result" = "pandoc-xelatex" ]
}

@test "canonicalize_mode preserves other modes" {
  load_md2pdf_functions
  result="$(canonicalize_mode md-to-pdf)"
  [ "$result" = "md-to-pdf" ]
}

@test "mode_label returns correct label for each mode" {
  load_md2pdf_functions
  [ "$(mode_label pandoc-xelatex)" = "Pandoc + XeLaTeX" ]
  [ "$(mode_label pandoc-lualatex)" = "Pandoc + LuaLaTeX" ]
  [ "$(mode_label pandoc-pdflatex)" = "Pandoc + pdfLaTeX" ]
  [ "$(mode_label pandoc-wkhtmltopdf)" = "Pandoc + wkhtmltopdf" ]
  [ "$(mode_label pandoc-weasyprint)" = "Pandoc + WeasyPrint" ]
  [ "$(mode_label md-to-pdf)" = "Node/Puppeteer (md-to-pdf)" ]
  [ "$(mode_label mdpdf)" = "Node/Puppeteer (mdpdf)" ]
  [ "$(mode_label go-md2pdf)" = "Go/fpdf" ]
  [ "$(mode_label weasy-md2pdf)" = "Python/WeasyPrint" ]
  [ "$(mode_label percollate)" = "Experimental HTML-first" ]
}

@test "mode_runtime returns correct runtime for each mode" {
  load_md2pdf_functions
  [ "$(mode_runtime pandoc-xelatex)" = "pandoc, xelatex" ]
  [ "$(mode_runtime pandoc-lualatex)" = "pandoc, lualatex" ]
  [ "$(mode_runtime pandoc-pdflatex)" = "pandoc, pdflatex" ]
  [ "$(mode_runtime md-to-pdf)" = "node, npm" ]
  [ "$(mode_runtime go-md2pdf)" = "go" ]
  [ "$(mode_runtime weasy-md2pdf)" = "python3, brew" ]
  [ "$(mode_runtime percollate)" = "pandoc, node, npm" ]
}

@test "mode_note returns non-empty for all modes" {
  load_md2pdf_functions
  for m in pandoc-xelatex pandoc-lualatex pandoc-pdflatex pandoc-wkhtmltopdf pandoc-weasyprint md-to-pdf mdpdf go-md2pdf weasy-md2pdf percollate; do
    result="$(mode_note "$m")"
    [ -n "$result" ]
  done
}
