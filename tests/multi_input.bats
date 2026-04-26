#!/usr/bin/env bats

load test_helper

has_pandoc_xelatex() {
  command -v pandoc >/dev/null 2>&1 && command -v xelatex >/dev/null 2>&1
}

@test "two inputs concatenate into a single PDF" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local a="$TEST_TEMP_DIR/a.md"
  local b="$TEST_TEMP_DIR/b.md"
  local out="$TEST_TEMP_DIR/combined.pdf"
  cat > "$a" <<'MD'
# First Document

Body of A.
MD
  cat > "$b" <<'MD'
## Section From B

Body of B.
MD
  run "$MD2PDF" --no-toc "$a" "$b" "$out"
  [ "$status" -eq 0 ]
  [ -s "$out" ]

  run pdftotext -layout "$out" -
  [ "$status" -eq 0 ]
  [[ "$output" == *"First Document"* ]]
  [[ "$output" == *"Section From B"* ]]
  # Page 1 starts with input 1's title
  page1="${output%%$'\f'*}"
  [[ "$page1" == *"First Document"* ]]
}

@test "image referenced from second input directory resolves" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  command -v python3 >/dev/null 2>&1 || skip "python3 not available"

  local d1="$TEST_TEMP_DIR/dir1"
  local d2="$TEST_TEMP_DIR/dir2"
  mkdir -p "$d1" "$d2"
  cat > "$d1/a.md" <<'MD'
# Doc A

Hello.
MD
  cat > "$d2/b.md" <<'MD'
## Doc B

![pic](pic.png)
MD
  python3 -c "import base64,sys; sys.stdout.buffer.write(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkAAIAAAoAAv/lxKUAAAAASUVORK5CYII='))" > "$d2/pic.png"

  local out="$TEST_TEMP_DIR/out.pdf"
  run "$MD2PDF" --no-toc "$d1/a.md" "$d2/b.md" -o "$out"
  [ "$status" -eq 0 ]
  [ -s "$out" ]
}

@test "multiple inputs without -o errors with helpful message" {
  run "$MD2PDF" "$FIXTURES_DIR/sample.md" "$FIXTURES_DIR/no-heading.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"specify output with -o when passing multiple inputs"* ]]
}

@test "trailing .pdf positional is treated as output for multi-input" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local out="$TEST_TEMP_DIR/trailing.pdf"
  run "$MD2PDF" --no-toc "$FIXTURES_DIR/sample.md" "$FIXTURES_DIR/no-heading.md" "$out"
  [ "$status" -eq 0 ]
  [ -s "$out" ]
}

@test "-o output with multiple inputs writes to specified path" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local out="$TEST_TEMP_DIR/explicit.pdf"
  run "$MD2PDF" --no-toc -o "$out" "$FIXTURES_DIR/sample.md" "$FIXTURES_DIR/no-heading.md"
  [ "$status" -eq 0 ]
  [ -s "$out" ]
}

@test "frontmatter from first input is preserved, subsequent stripped" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"

  local a="$TEST_TEMP_DIR/a.md"
  local b="$TEST_TEMP_DIR/b.md"
  local out="$TEST_TEMP_DIR/frontmatter.pdf"
  # First input sets toc:false via frontmatter; CLI does not override.
  cat > "$a" <<'MD'
---
toc: false
---
# Doc A

Body.
MD
  # Second input has frontmatter that would set toc:true if not stripped.
  cat > "$b" <<'MD'
---
toc: true
---
## Doc B

Body.
MD
  run "$MD2PDF" "$a" "$b" "$out"
  [ "$status" -eq 0 ]
  [ -s "$out" ]

  run pdftotext -layout "$out" -
  [ "$status" -eq 0 ]
  # No "Contents" / "Table of Contents" heading should appear since first
  # frontmatter wins (toc:false).
  [[ "$output" != *"Contents"* ]]
}
