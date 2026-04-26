#!/usr/bin/env bats

load test_helper

setup_fake_pandoc() {
  mkdir -p "$TEST_TEMP_DIR/fake-bin"

  cat > "$TEST_TEMP_DIR/fake-bin/xelatex" <<'SH'
#!/usr/bin/env bash
exit 0
SH

  cat > "$TEST_TEMP_DIR/fake-bin/pdflatex" <<'SH'
#!/usr/bin/env bash
exit 0
SH

  cat > "$TEST_TEMP_DIR/fake-bin/pandoc" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MD2PDF_PANDOC_ARGS_LOG"
cp "$1" "$MD2PDF_PANDOC_INPUT_LOG"
saved_args=("$@")
while [ "$#" -gt 0 ]; do
  if [ "$1" = "--css" ]; then
    shift
    [ -n "$MD2PDF_PANDOC_CSS_LOG" ] && [ -f "$1" ] && cp "$1" "$MD2PDF_PANDOC_CSS_LOG"
  fi
  shift
done
set -- "${saved_args[@]}"
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

  chmod +x "$TEST_TEMP_DIR/fake-bin/pandoc" "$TEST_TEMP_DIR/fake-bin/xelatex" "$TEST_TEMP_DIR/fake-bin/pdflatex"
  export PATH="$TEST_TEMP_DIR/fake-bin:$PATH"
  export MD2PDF_PANDOC_ARGS_LOG="$TEST_TEMP_DIR/pandoc-args.txt"
  export MD2PDF_PANDOC_INPUT_LOG="$TEST_TEMP_DIR/pandoc-input.md"
  export MD2PDF_PANDOC_CSS_LOG="$TEST_TEMP_DIR/pandoc-css.txt"
}

write_doc() {
  local path="$1"
  shift
  printf '%s\n' "$@" > "$path"
}

@test "frontmatter title is used as title block" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-title.md"
  write_doc "$input" "---" "title: Frontmatter Title" "---" "" "# H1 Heading" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Frontmatter Title$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^% H1 Heading$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "CLI -t overrides frontmatter title" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-title.md"
  write_doc "$input" "---" "title: Frontmatter Title" "---" "" "# H1 Heading" "" "Body"

  run "$MD2PDF" -t "CLI Title" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% CLI Title$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^% Frontmatter Title$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "frontmatter author is used in title block" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-author.md"
  write_doc "$input" "---" "author: Jane Doe" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Jane Doe$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "CLI -a overrides frontmatter author" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-author.md"
  write_doc "$input" "---" "author: Jane Doe" "---" "" "# Title" "" "Body"

  run "$MD2PDF" -a "John Smith" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% John Smith$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^% Jane Doe$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "frontmatter margin produces matching geometry arg" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-margin.md"
  write_doc "$input" "---" "margin: 0.5in" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "geometry:margin=0.5in" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "CLI -m overrides frontmatter margin" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-margin.md"
  write_doc "$input" "---" "margin: 0.5in" "---" "" "# Title" "" "Body"

  run "$MD2PDF" -m "0.75in" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "geometry:margin=0.75in" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "frontmatter fontsize produces matching fontsize arg" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-fontsize.md"
  write_doc "$input" "---" "fontsize: 13pt" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "fontsize:13pt" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "frontmatter font_size alias normalizes to fontsize" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-fontsize-alias.md"
  write_doc "$input" "---" "font_size: 13pt" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "fontsize:13pt" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "frontmatter font produces matching mainfont arg" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-font.md"
  write_doc "$input" "---" "font: Helvetica" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "mainfont:Helvetica" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "frontmatter page_numbers false disables page numbers" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-pages.md"
  write_doc "$input" "---" "page_numbers: false" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "pagestyle:empty" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "frontmatter page-numbers alias is honored" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-pages-alias.md"
  write_doc "$input" "---" "page-numbers: false" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "pagestyle:empty" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "CLI --page-numbers overrides frontmatter page_numbers false" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-pages.md"
  write_doc "$input" "---" "page_numbers: false" "---" "" "# Title" "" "Body"

  run "$MD2PDF" --page-numbers "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "pagestyle:plain" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "frontmatter date appears in title block" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-date.md"
  write_doc "$input" "---" "date: January 1, 2026" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% January 1, 2026$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "consumed frontmatter keys are stripped from pandoc input" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-strip.md"
  write_doc "$input" "---" "title: T" "author: A" "margin: 0.5in" "fontsize: 9pt" "font: F" "page_numbers: false" "date: D" "---" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  ! grep -q "^title:" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^author:" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^margin:" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^fontsize:" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^font:" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^page_numbers:" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^date:" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "toc and numbersections survive frontmatter pruning" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-survive.md"
  write_doc "$input" "---" "title: T" "toc: true" "numbersections: true" "---" "" "# Title" "" "## Intro"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -qx -- "toc: true" "$MD2PDF_PANDOC_INPUT_LOG"
  grep -qx -- "numbersections: true" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "unknown frontmatter key emits warning to stderr" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-unknown.md"
  write_doc "$input" "---" "title: T" "bogus_key: value" "---" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  [[ "$output" == *"warning: unrecognized frontmatter key: bogus_key"* ]]
}

@test "unknown frontmatter key does not abort rendering" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-unknown-render.md"
  write_doc "$input" "---" "bogus: x" "---" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out.pdf" ]
}

@test "quoted frontmatter string values are unwrapped" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-quoted.md"
  write_doc "$input" "---" 'title: "Quoted Title"' "---" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Quoted Title$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "quoted frontmatter values may contain hash characters" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-quoted-hash.md"
  write_doc "$input" "---" 'title: "C# Guide"' "---" "" "# H1 Heading" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% C# Guide$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q '^% "C$' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "nested frontmatter keys are not treated as md2pdf options" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-nested.md"
  write_doc "$input" "---" "project:" "  title: Nested Title" "---" "" "# H1 Heading" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% H1 Heading$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "^% Nested Title$" "$MD2PDF_PANDOC_INPUT_LOG"
  grep -qx -- "  title: Nested Title" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "frontmatter options unsupported by selected mode emit warnings" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-unsupported-font.md"
  write_doc "$input" "---" "font: Helvetica" "---" "" "# Title" "" "Body"

  run "$MD2PDF" --mode pandoc-pdflatex "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  [[ "$output" == *"warning: mode pandoc-pdflatex does not support arbitrary system font selection"* ]]
}

@test "fully-consumed frontmatter leaves no empty YAML block in pandoc input" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-all-consumed.md"
  write_doc "$input" "---" "fontsize: 11pt" "author: Jane Doe" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  # combined.md must not contain a bare `---\n\n---` empty YAML block,
  # which pandoc reinterprets as a hr followed by a fresh YAML block start.
  run python3 -c "import sys, re; sys.exit(0 if re.search(r'(?m)^---[ \t]*\n[ \t]*\n---[ \t]*$', open(sys.argv[1]).read()) is None else 1)" "$MD2PDF_PANDOC_INPUT_LOG"
  [ "$status" -eq 0 ]
}

@test "fully-consumed frontmatter with body hr and bold does not crash pandoc" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local input="$TEST_TEMP_DIR/regression-empty-fm.md"
  cat > "$input" <<'MD'
---
fontsize: 11pt
author: Alexander Goldstein
---
# Title

**Bold paragraph** that follows a horizontal rule below.

---

## Section

| A | B |
|---|---|
| 1 | 2 |
MD

  run "$MD2PDF" --no-toc "$input" "$TEST_TEMP_DIR/regression.pdf"
  [ "$status" -eq 0 ]
  [ -s "$TEST_TEMP_DIR/regression.pdf" ]
}

@test "frontmatter with only one consumed key leaves no empty YAML block" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-one-consumed.md"
  write_doc "$input" "---" "author: Solo" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  run python3 -c "import sys, re; sys.exit(0 if re.search(r'(?m)^---[ \t]*\n[ \t]*\n---[ \t]*$', open(sys.argv[1]).read()) is None else 1)" "$MD2PDF_PANDOC_INPUT_LOG"
  [ "$status" -eq 0 ]
}

@test "frontmatter with surviving keys still emits non-empty YAML block" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/fm-mixed.md"
  write_doc "$input" "---" "author: Solo" "toc: true" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  # toc must survive into the YAML block, author must be stripped.
  grep -qx -- "toc: true" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -qx -- "author: Solo" "$MD2PDF_PANDOC_INPUT_LOG"
}

# --- Widow/orphan protection ----------------------------------------------

@test "default behavior does not add LaTeX widow/club penalties" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/widow-default.md"
  write_doc "$input" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  ! grep -q "widowpenalty" "$MD2PDF_PANDOC_ARGS_LOG"
  ! grep -q "clubpenalty" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "--prevent-widows adds LaTeX widow/club penalties for xelatex" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/widow-on.md"
  write_doc "$input" "# Title" "" "Body"

  run "$MD2PDF" --prevent-widows "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q '\\widowpenalty=10000' "$MD2PDF_PANDOC_ARGS_LOG"
  grep -q '\\clubpenalty=10000' "$MD2PDF_PANDOC_ARGS_LOG"
  grep -q '\\displaywidowpenalty=10000' "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "--prevent-widows works for pdflatex too" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/widow-pdflatex.md"
  write_doc "$input" "# Title" "" "Body"

  run "$MD2PDF" --mode pandoc-pdflatex --prevent-widows "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q '\\widowpenalty=10000' "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "frontmatter prevent_widows: true enables protection" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/widow-fm.md"
  write_doc "$input" "---" "prevent_widows: true" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q '\\widowpenalty=10000' "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "frontmatter alias prevent-widows is honored" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/widow-fm-alias.md"
  write_doc "$input" "---" "prevent-widows: true" "---" "" "# Title" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q '\\widowpenalty=10000' "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "CLI --no-prevent-widows overrides frontmatter true" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/widow-override.md"
  write_doc "$input" "---" "prevent_widows: true" "---" "" "# Title" "" "Body"

  run "$MD2PDF" --no-prevent-widows "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  ! grep -q "widowpenalty" "$MD2PDF_PANDOC_ARGS_LOG"
}

@test "prevent_widows is stripped from pandoc input" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/widow-stripped.md"
  write_doc "$input" "---" "prevent_widows: true" "title: T" "---" "" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  ! grep -q "^prevent_widows:" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "weasyprint mode embeds CSS widows/orphans rules when --prevent-widows" {
  setup_fake_pandoc
  # weasyprint binary stub so dep check passes
  cat > "$TEST_TEMP_DIR/fake-bin/weasyprint" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$TEST_TEMP_DIR/fake-bin/weasyprint"

  local input="$TEST_TEMP_DIR/widow-css.md"
  write_doc "$input" "# Title" "" "Body"

  run "$MD2PDF" --mode pandoc-weasyprint --prevent-widows "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  [ -f "$MD2PDF_PANDOC_CSS_LOG" ]
  grep -q "widows" "$MD2PDF_PANDOC_CSS_LOG"
  grep -q "orphans" "$MD2PDF_PANDOC_CSS_LOG"
}

@test "weasyprint mode without --prevent-widows omits widows/orphans CSS" {
  setup_fake_pandoc
  cat > "$TEST_TEMP_DIR/fake-bin/weasyprint" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$TEST_TEMP_DIR/fake-bin/weasyprint"

  local input="$TEST_TEMP_DIR/widow-css-off.md"
  write_doc "$input" "# Title" "" "Body"

  run "$MD2PDF" --mode pandoc-weasyprint "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  [ -f "$MD2PDF_PANDOC_CSS_LOG" ]
  ! grep -q "widows" "$MD2PDF_PANDOC_CSS_LOG"
  ! grep -q "orphans" "$MD2PDF_PANDOC_CSS_LOG"
}
