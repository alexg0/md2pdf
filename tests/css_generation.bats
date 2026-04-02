#!/usr/bin/env bats

load test_helper

@test "write_weasy_css includes margin" {
  load_md2pdf_functions
  margin="1.5in"
  local css_file="$TEST_TEMP_DIR/test.css"
  write_weasy_css "$css_file"
  result="$(cat "$css_file")"
  [[ "$result" == *"margin: 1.5in"* ]]
}

@test "write_weasy_css includes font-size" {
  load_md2pdf_functions
  fontsize="14pt"
  local css_file="$TEST_TEMP_DIR/test.css"
  write_weasy_css "$css_file"
  result="$(cat "$css_file")"
  [[ "$result" == *"font-size: 14pt"* ]]
}

@test "write_weasy_css includes font-family" {
  load_md2pdf_functions
  font_family="Helvetica"
  local css_file="$TEST_TEMP_DIR/test.css"
  write_weasy_css "$css_file"
  result="$(cat "$css_file")"
  [[ "$result" == *"Helvetica"* ]]
}

@test "write_weasy_css includes page counter when page numbers enabled" {
  load_md2pdf_functions
  page_numbers_enabled=1
  local css_file="$TEST_TEMP_DIR/test.css"
  write_weasy_css "$css_file"
  result="$(cat "$css_file")"
  [[ "$result" == *"counter(page)"* ]]
}

@test "write_weasy_css omits page counter when page numbers disabled" {
  load_md2pdf_functions
  page_numbers_enabled=0
  local css_file="$TEST_TEMP_DIR/test.css"
  write_weasy_css "$css_file"
  result="$(cat "$css_file")"
  [[ "$result" != *"counter(page)"* ]]
}

@test "write_font_css includes font-size and font-family" {
  load_md2pdf_functions
  fontsize="12pt"
  font_family="Georgia"
  local css_file="$TEST_TEMP_DIR/font.css"
  write_font_css "$css_file"
  result="$(cat "$css_file")"
  [[ "$result" == *"font-size: 12pt"* ]]
  [[ "$result" == *"Georgia"* ]]
}

@test "write_puppeteer_footer_template creates HTML with pageNumber" {
  load_md2pdf_functions
  local footer_file="$TEST_TEMP_DIR/footer.html"
  write_puppeteer_footer_template "$footer_file"
  result="$(cat "$footer_file")"
  [[ "$result" == *"pageNumber"* ]]
}

@test "write_puppeteer_footer_template includes font-family" {
  load_md2pdf_functions
  font_family="Times New Roman"
  local footer_file="$TEST_TEMP_DIR/footer.html"
  write_puppeteer_footer_template "$footer_file"
  result="$(cat "$footer_file")"
  [[ "$result" == *"Times New Roman"* ]]
}
