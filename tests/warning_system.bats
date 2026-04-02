#!/usr/bin/env bats

load test_helper

# Warning tests use --mode-help as the action so we don't need to actually
# render (which would require all deps installed). Warnings are emitted to
# stderr before the action runs.

@test "no warnings for pandoc-xelatex with defaults" {
  output=$("$MD2PDF" --mode-help 2>&1)
  [[ "$output" != *"warning:"* ]]
}

@test "no warnings for pandoc-lualatex with defaults" {
  output=$("$MD2PDF" --mode pandoc-lualatex --mode-help 2>&1)
  [[ "$output" != *"warning:"* ]]
}

@test "pandoc-pdflatex warns on explicit font" {
  output=$("$MD2PDF" --mode pandoc-pdflatex --font "Arial" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"font"* ]]
}

@test "pandoc-wkhtmltopdf warns on author" {
  output=$("$MD2PDF" --mode pandoc-wkhtmltopdf -a "Some Author" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"author"* ]]
}

@test "pandoc-weasyprint warns on author" {
  output=$("$MD2PDF" --mode pandoc-weasyprint -a "Some Author" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"author"* ]]
}

@test "md-to-pdf warns on author" {
  output=$("$MD2PDF" --mode md-to-pdf -a "Some Author" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"author"* ]]
}

@test "mdpdf warns on author" {
  output=$("$MD2PDF" --mode mdpdf -a "Some Author" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"author"* ]]
}

@test "go-md2pdf warns on non-default margin" {
  output=$("$MD2PDF" --mode go-md2pdf -m "2in" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"margin"* ]]
}

@test "go-md2pdf warns on non-default fontsize" {
  output=$("$MD2PDF" --mode go-md2pdf -s "14pt" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"size"* ]]
}

@test "go-md2pdf warns on explicit font" {
  output=$("$MD2PDF" --mode go-md2pdf --font "Arial" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"font"* ]]
}

@test "weasy-md2pdf warns on title" {
  output=$("$MD2PDF" --mode weasy-md2pdf -t "Some Title" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"title"* ]]
}

@test "weasy-md2pdf warns on author" {
  output=$("$MD2PDF" --mode weasy-md2pdf -a "Some Author" --mode-help 2>&1)
  [[ "$output" == *"warning:"* ]]
  [[ "$output" == *"author"* ]]
}

@test "multiple warnings accumulate for go-md2pdf" {
  output=$("$MD2PDF" --mode go-md2pdf -m "2in" -s "14pt" --font "Arial" --mode-help 2>&1)
  count=$(echo "$output" | grep -c "warning:")
  [ "$count" -eq 3 ]
}
