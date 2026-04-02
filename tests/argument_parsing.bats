#!/usr/bin/env bats

load test_helper

@test "help flag exits 0" {
  run "$MD2PDF" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "short help flag exits 0" {
  run "$MD2PDF" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "unknown option fails" {
  run "$MD2PDF" --bogus-option
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown option"* ]]
}

@test "--mode requires a value" {
  run "$MD2PDF" --mode
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires a value"* ]]
}

@test "-t requires a value" {
  run "$MD2PDF" -t
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires a value"* ]]
}

@test "-a requires a value" {
  run "$MD2PDF" -a
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires a value"* ]]
}

@test "--font requires a value" {
  run "$MD2PDF" --font
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires a value"* ]]
}

@test "-m requires a value" {
  run "$MD2PDF" -m
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires a value"* ]]
}

@test "-s requires a value" {
  run "$MD2PDF" -s
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires a value"* ]]
}

@test "extra positional arguments fail" {
  run "$MD2PDF" input.md output.pdf extra.txt
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unexpected extra"* ]]
}

@test "unknown mode fails" {
  run "$MD2PDF" --mode nonexistent --mode-help
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown mode"* ]]
}

@test "--mode=value equals syntax works" {
  run "$MD2PDF" --mode=pandoc-lualatex --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"LuaLaTeX"* ]]
}

@test "default mode is pandoc-xelatex" {
  load_md2pdf_functions
  [ "$mode" = "pandoc-xelatex" ]
}

@test "default margin is 1in" {
  load_md2pdf_functions
  [ "$margin" = "1in" ]
}

@test "default fontsize is 11pt" {
  load_md2pdf_functions
  [ "$fontsize" = "11pt" ]
}

@test "default toc is enabled" {
  load_md2pdf_functions
  [ "$toc_enabled" = "1" ]
}

@test "default page numbers are enabled" {
  load_md2pdf_functions
  [ "$page_numbers_enabled" = "1" ]
}

@test "parse_args sets mode" {
  load_md2pdf_functions
  parse_args --mode pandoc-lualatex --mode-help
  [ "$mode" = "pandoc-lualatex" ]
}

@test "parse_args sets title" {
  load_md2pdf_functions
  parse_args -t "My Title" --mode-help
  [ "$title" = "My Title" ]
}

@test "parse_args sets author" {
  load_md2pdf_functions
  parse_args -a "John Doe" --mode-help
  [ "$author" = "John Doe" ]
}

@test "parse_args sets margin" {
  load_md2pdf_functions
  parse_args -m "2in" --mode-help
  [ "$margin" = "2in" ]
}

@test "parse_args sets fontsize" {
  load_md2pdf_functions
  parse_args -s "14pt" --mode-help
  [ "$fontsize" = "14pt" ]
}

@test "parse_args sets font and font_explicit" {
  load_md2pdf_functions
  parse_args --font "Arial" --mode-help
  [ "$font_family" = "Arial" ]
  [ "$font_explicit" = "1" ]
}

@test "parse_args handles --no-toc" {
  load_md2pdf_functions
  parse_args --no-toc --mode-help
  [ "$toc_enabled" = "0" ]
}

@test "parse_args handles --no-page-numbers" {
  load_md2pdf_functions
  parse_args --no-page-numbers --mode-help
  [ "$page_numbers_enabled" = "0" ]
}

@test "parse_args handles --page-numbers" {
  load_md2pdf_functions
  parse_args --no-page-numbers --page-numbers --mode-help
  [ "$page_numbers_enabled" = "1" ]
}

@test "parse_args sets input file" {
  load_md2pdf_functions
  parse_args "$FIXTURES_DIR/sample.md"
  [ "$input_file" = "$FIXTURES_DIR/sample.md" ]
}

@test "parse_args sets output file" {
  load_md2pdf_functions
  parse_args "$FIXTURES_DIR/sample.md" "/tmp/out.pdf"
  [ "$output_file" = "/tmp/out.pdf" ]
}

@test "parse_args handles -- stop" {
  load_md2pdf_functions
  parse_args -- "$FIXTURES_DIR/sample.md"
  [ "$input_file" = "$FIXTURES_DIR/sample.md" ]
}

@test "latex alias resolves to pandoc-xelatex" {
  load_md2pdf_functions
  parse_args --mode latex --mode-help
  [ "$mode" = "pandoc-xelatex" ]
}
