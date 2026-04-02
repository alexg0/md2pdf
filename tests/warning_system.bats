#!/usr/bin/env bats

load test_helper

@test "no warnings for pandoc-xelatex with defaults" {
  load_md2pdf_functions
  warnings=()
  warn_unmapped_options "pandoc-xelatex"
  [ "${#warnings[@]}" -eq 0 ]
}

@test "no warnings for pandoc-lualatex with defaults" {
  load_md2pdf_functions
  warnings=()
  warn_unmapped_options "pandoc-lualatex"
  [ "${#warnings[@]}" -eq 0 ]
}

@test "pandoc-pdflatex warns on explicit font" {
  load_md2pdf_functions
  warnings=()
  font_explicit=1
  warn_unmapped_options "pandoc-pdflatex"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"font"* ]]
}

@test "pandoc-wkhtmltopdf warns on author" {
  load_md2pdf_functions
  warnings=()
  author="Some Author"
  warn_unmapped_options "pandoc-wkhtmltopdf"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"author"* ]]
}

@test "pandoc-weasyprint warns on author" {
  load_md2pdf_functions
  warnings=()
  author="Some Author"
  warn_unmapped_options "pandoc-weasyprint"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"author"* ]]
}

@test "md-to-pdf warns on author" {
  load_md2pdf_functions
  warnings=()
  author="Some Author"
  warn_unmapped_options "md-to-pdf"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"author"* ]]
}

@test "mdpdf warns on author" {
  load_md2pdf_functions
  warnings=()
  author="Some Author"
  warn_unmapped_options "mdpdf"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"author"* ]]
}

@test "go-md2pdf warns on non-default margin" {
  load_md2pdf_functions
  warnings=()
  margin="2in"
  warn_unmapped_options "go-md2pdf"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"margin"* ]]
}

@test "go-md2pdf warns on non-default fontsize" {
  load_md2pdf_functions
  warnings=()
  fontsize="14pt"
  warn_unmapped_options "go-md2pdf"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"size"* ]]
}

@test "go-md2pdf warns on explicit font" {
  load_md2pdf_functions
  warnings=()
  font_explicit=1
  warn_unmapped_options "go-md2pdf"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"font"* ]]
}

@test "weasy-md2pdf warns on title" {
  load_md2pdf_functions
  warnings=()
  title="Some Title"
  warn_unmapped_options "weasy-md2pdf"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"title"* ]]
}

@test "weasy-md2pdf warns on author" {
  load_md2pdf_functions
  warnings=()
  author="Some Author"
  warn_unmapped_options "weasy-md2pdf"
  [ "${#warnings[@]}" -eq 1 ]
  [[ "${warnings[0]}" == *"author"* ]]
}

@test "flush_warnings outputs accumulated warnings" {
  load_md2pdf_functions
  warnings=()
  warn "test warning 1"
  warn "test warning 2"
  run flush_warnings
  [[ "$output" == *"warning: test warning 1"* ]]
  [[ "$output" == *"warning: test warning 2"* ]]
}

@test "flush_warnings is silent with no warnings" {
  load_md2pdf_functions
  warnings=()
  run flush_warnings
  [ -z "$output" ]
}

@test "multiple warnings accumulate for go-md2pdf" {
  load_md2pdf_functions
  warnings=()
  margin="2in"
  fontsize="14pt"
  font_explicit=1
  warn_unmapped_options "go-md2pdf"
  [ "${#warnings[@]}" -eq 3 ]
}
