#!/usr/bin/env bats

load test_helper

setup_fake_pandoc() {
  mkdir -p "$TEST_TEMP_DIR/fake-bin"

  cat > "$TEST_TEMP_DIR/fake-bin/xelatex" <<'SH'
#!/usr/bin/env bash
exit 0
SH

  cat > "$TEST_TEMP_DIR/fake-bin/pandoc" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MD2PDF_PANDOC_ARGS_LOG"
cp "$1" "$MD2PDF_PANDOC_INPUT_LOG"
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    shift
    touch "$1"
    exit 0
  fi
  shift
done
exit 0
SH

  chmod +x "$TEST_TEMP_DIR/fake-bin/pandoc" "$TEST_TEMP_DIR/fake-bin/xelatex"
  export PATH="$TEST_TEMP_DIR/fake-bin:$PATH"
  export MD2PDF_PANDOC_ARGS_LOG="$TEST_TEMP_DIR/pandoc-args.txt"
  export MD2PDF_PANDOC_INPUT_LOG="$TEST_TEMP_DIR/pandoc-input.md"
}

write_doc() {
  local path="$1"
  shift
  printf '%s\n' "$@" > "$path"
}

assert_arg_present() {
  grep -qx -- "$1" "$MD2PDF_PANDOC_ARGS_LOG"
}

assert_arg_absent() {
  ! grep -qx -- "$1" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "default pandoc render numbers sections" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/default.md"
  write_doc "$input" "# Title" "" "## Introduction" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_present "--number-sections"
}

@test "frontmatter numbersections disables automatic section numbering" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/frontmatter-numbersections.md"
  write_doc "$input" "---" "numbersections: true" "---" "" "# Title" "" "## Introduction"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_absent "--number-sections"
}

@test "frontmatter number_section disables automatic section numbering" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/frontmatter-number-section.md"
  write_doc "$input" "---" "number_section: true" "---" "" "# Title" "" "## Introduction"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_absent "--number-sections"
}

@test "frontmatter number_sections is converted to pandoc numbersections" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/frontmatter-number-sections.md"
  write_doc "$input" "---" "number_sections: true" "---" "" "# Title" "" "## Introduction"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_absent "--number-sections"
  grep -qx -- "numbersections: true" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -qx -- "number_sections: true" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "nested frontmatter numbersections does not disable automatic section numbering" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/nested-numbersections.md"
  write_doc "$input" "---" "project:" "  numbersections: false" "---" "" "# Title" "" "## Introduction"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_present "--number-sections"
  grep -qx -- "  numbersections: false" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "--no-number-sections disables default automatic section numbering" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/no-number-sections.md"
  write_doc "$input" "# Title" "" "## Introduction" "" "Body"

  run "$MD2PDF" --no-number-sections "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_absent "--number-sections"
  assert_arg_present "--metadata=numbersections:false"
}

@test "--number-sections overrides existing numbered h2 detection" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/force-numbered-h2.md"
  write_doc "$input" "# Title" "" "## 1. Introduction" "" "Body"

  run "$MD2PDF" --number-sections "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_present "--number-sections"
  assert_arg_present "--metadata=numbersections:true"
}

@test "numbered markdown h2 disables automatic section numbering" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/numbered-h2.md"
  write_doc "$input" "# Title" "" "## 1. Introduction" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_absent "--number-sections"
}

@test "numbered html h2 disables automatic section numbering" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/numbered-html-h2.md"
  write_doc "$input" "# Title" "" "<h2>1. Introduction</h2>" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_absent "--number-sections"
}

@test "frontmatter toc false disables automatic toc" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/toc-false.md"
  write_doc "$input" "---" "toc: false" "---" "" "# Title" "" "## Introduction"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_absent "--toc"
}

@test "--toc overrides frontmatter toc false" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/toc-override-true.md"
  write_doc "$input" "---" "toc: false" "---" "" "# Title" "" "## Introduction"

  run "$MD2PDF" --toc "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_present "--toc"
  assert_arg_present "--metadata=toc:true"
}

@test "--no-toc overrides frontmatter toc true" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/toc-override-false.md"
  write_doc "$input" "---" "toc: true" "---" "" "# Title" "" "## Introduction"

  run "$MD2PDF" --no-toc "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  assert_arg_absent "--toc"
  assert_arg_present "--metadata=toc:false"
}
