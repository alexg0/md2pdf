#!/usr/bin/env bats

load test_helper

# Build a fake-bin directory containing fake pandoc + xelatex (so we don't need
# the real renderer toolchain). The fake pandoc logs argv and the input markdown
# it received, then writes an empty PDF to -o. The fake xelatex always succeeds.
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

# Add a fake mmdc that records each invocation and produces an empty PNG.
setup_fake_mmdc() {
  export MD2PDF_MMDC_CALLS_LOG="$TEST_TEMP_DIR/mmdc-calls.log"
  : > "$MD2PDF_MMDC_CALLS_LOG"

  cat > "$TEST_TEMP_DIR/fake-bin/mmdc" <<'SH'
#!/usr/bin/env bash
echo "$@" >> "$MD2PDF_MMDC_CALLS_LOG"
out=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    shift
    out="$1"
  fi
  shift
done
[ -n "$out" ] && touch "$out"
exit 0
SH
  chmod +x "$TEST_TEMP_DIR/fake-bin/mmdc"
}

setup_fake_md_to_pdf() {
  mkdir -p "$TEST_TEMP_DIR/fake-bin"
  mkdir -p "$MD2PDF_TOOL_HOME/npm/md-to-pdf/node_modules/.bin"
  export MD2PDF_CONFIG_LOG="$TEST_TEMP_DIR/md-to-pdf-config.json"

  cat > "$TEST_TEMP_DIR/fake-bin/node" <<'SH'
#!/usr/bin/env bash
exit 0
SH

  cat > "$MD2PDF_TOOL_HOME/npm/md-to-pdf/node_modules/.bin/md-to-pdf" <<'SH'
#!/usr/bin/env bash
config=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = "--config-file" ]; then
    shift
    config="$1"
  fi
  shift
done
cp "$config" "$MD2PDF_CONFIG_LOG"
exit 0
SH

  chmod +x "$TEST_TEMP_DIR/fake-bin/node" "$MD2PDF_TOOL_HOME/npm/md-to-pdf/node_modules/.bin/md-to-pdf"
  export PATH="$TEST_TEMP_DIR/fake-bin:$PATH"
}

mmdc_call_count() {
  if [ -s "$MD2PDF_MMDC_CALLS_LOG" ]; then
    awk 'END { print NR }' "$MD2PDF_MMDC_CALLS_LOG"
  else
    echo 0
  fi
}

write_mermaid_doc() {
  local path="$1"
  cat > "$path" <<'EOF'
# Title

```mermaid
graph TD
    A --> B
```

End.
EOF
}

@test "mermaid block is rendered with mmdc and reused from cache on second run" {
  setup_fake_pandoc
  setup_fake_mmdc

  local input="$TEST_TEMP_DIR/with-mermaid.md"
  write_mermaid_doc "$input"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out1.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out1.pdf" ]
  [ "$(mmdc_call_count)" -eq 1 ]

  # Cached PNG should now exist in the tool home cache directory.
  shopt -s nullglob
  cached=( "$MD2PDF_TOOL_HOME"/cache/mermaid/mermaid-*.png )
  [ "${#cached[@]}" -eq 1 ]

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out2.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out2.pdf" ]
  # Second run hits the cache, so mmdc should NOT have been invoked again.
  [ "$(mmdc_call_count)" -eq 1 ]

  # The pandoc input from the second run should reference the cached PNG and
  # contain no remaining mermaid fence.
  ! grep -q '^```mermaid' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -q "${cached[0]}" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "input with no mermaid blocks does not require mmdc" {
  setup_fake_pandoc
  setup_fake_mmdc

  local input="$TEST_TEMP_DIR/plain.md"
  cat > "$input" <<'EOF'
# Title

Just plain text, no diagrams here.

```bash
echo hi
```
EOF

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out.pdf" ]
  # No mermaid blocks → mmdc must not have been invoked.
  [ "$(mmdc_call_count)" -eq 0 ]
}

@test "--no-mermaid leaves the fence untouched" {
  setup_fake_pandoc
  setup_fake_mmdc

  local input="$TEST_TEMP_DIR/skip-mermaid.md"
  write_mermaid_doc "$input"

  run "$MD2PDF" --no-mermaid "$input" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TEMP_DIR/out.pdf" ]

  # mmdc must not have been invoked when --no-mermaid is set.
  [ "$(mmdc_call_count)" -eq 0 ]

  # The original mermaid fence should still be present in what pandoc received.
  grep -q '^```mermaid' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -q '^graph TD' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "fenced mermaid nested inside another code block is ignored" {
  setup_fake_pandoc
  setup_fake_mmdc

  local input="$TEST_TEMP_DIR/nested-fence.md"
  cat > "$input" <<'EOF'
# Title

````markdown
```mermaid
graph TD
    A --> B
```
````

End.
EOF

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  # The inner fence is part of an outer fence, so mermaid preprocessing
  # should not run and mmdc should not have been invoked.
  [ "$(mmdc_call_count)" -eq 0 ]
  grep -q '```mermaid' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "mermaid block inside a list preserves indentation" {
  setup_fake_pandoc
  setup_fake_mmdc

  local input="$TEST_TEMP_DIR/list-mermaid.md"
  cat > "$input" <<'EOF'
# Title

- item before

  ```mermaid
  graph TD
      A --> B
  ```

  item after
EOF

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ "$(mmdc_call_count)" -eq 1 ]
  grep -q '^  !\[\](' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -q '^  item after$' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "mermaid block with longer closing fence is still rendered" {
  setup_fake_pandoc
  setup_fake_mmdc

  local input="$TEST_TEMP_DIR/long-close-mermaid.md"
  cat > "$input" <<'EOF'
# Title

```mermaid
graph TD
    A --> B
````
EOF

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ "$(mmdc_call_count)" -eq 1 ]
  ! grep -q '^```mermaid' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -q '!\[\](' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "md-to-pdf keeps basedir anchored to the source document directory" {
  setup_fake_md_to_pdf
  setup_fake_mmdc

  local docs_dir="$TEST_TEMP_DIR/docs"
  mkdir -p "$docs_dir"
  touch "$docs_dir/image.png"

  local input="$docs_dir/with-assets.md"
  cat > "$input" <<'EOF'
# Title

![local](image.png)

```mermaid
graph TD
    A --> B
```
EOF

  run "$MD2PDF" --mode md-to-pdf "$input" "$TEST_TEMP_DIR/out.pdf"
  [ "$status" -eq 0 ]
  [ "$(mmdc_call_count)" -eq 1 ]
  grep -F "\"basedir\":\"$docs_dir\"" "$MD2PDF_CONFIG_LOG"
}
