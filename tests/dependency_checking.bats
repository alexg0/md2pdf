#!/usr/bin/env bats

load test_helper

@test "--list-modes exits 0 and shows all modes" {
  run "$MD2PDF" --list-modes
  [ "$status" -eq 0 ]
  [[ "$output" == *"pandoc-xelatex"* ]]
  [[ "$output" == *"pandoc-lualatex"* ]]
  [[ "$output" == *"pandoc-pdflatex"* ]]
  [[ "$output" == *"md-to-pdf"* ]]
  [[ "$output" == *"mdpdf"* ]]
  [[ "$output" == *"go-md2pdf"* ]]
  [[ "$output" == *"weasy-md2pdf"* ]]
  [[ "$output" == *"percollate"* ]]
  [[ "$output" == *"pandoc-docx"* ]]
}

@test "--list-modes shows status for each mode" {
  run "$MD2PDF" --list-modes
  [ "$status" -eq 0 ]
  [[ "$output" == *"status="* ]]
}

@test "--mode-help shows info for default mode" {
  run "$MD2PDF" --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"XeLaTeX"* ]]
}

@test "--mode-help shows info for each mode" {
  for m in pandoc-xelatex pandoc-lualatex pandoc-pdflatex pandoc-wkhtmltopdf pandoc-weasyprint md-to-pdf mdpdf go-md2pdf weasy-md2pdf percollate pandoc-docx; do
    run "$MD2PDF" --mode "$m" --mode-help
    [ "$status" -eq 0 ]
    [ -n "$output" ]
  done
}

@test "--check-deps succeeds for pandoc-xelatex when pandoc and xelatex are installed" {
  has_pandoc_xelatex || skip "pandoc and xelatex not available"
  run "$MD2PDF" --check-deps
  [ "$status" -eq 0 ]
  [[ "$output" == *"dependencies OK"* ]]
}

@test "--check-deps fails for unknown mode" {
  run "$MD2PDF" --mode not-a-mode --check-deps
  [ "$status" -ne 0 ]
}

@test "--install-deps installs TeX packages required by pandoc LaTeX output" {
  fake_bin="$TEST_TEMP_DIR/fake-bin"
  mkdir -p "$fake_bin"

  cat > "$fake_bin/brew" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MD2PDF_FAKE_BREW_LOG"
SH
  cat > "$fake_bin/tlmgr" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MD2PDF_FAKE_TLMGR_LOG"
SH
  cat > "$fake_bin/node" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  cat > "$fake_bin/npm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MD2PDF_FAKE_NPM_LOG"
SH
  chmod +x "$fake_bin/brew" "$fake_bin/tlmgr" "$fake_bin/node" "$fake_bin/npm"

  export MD2PDF_FAKE_BREW_LOG="$TEST_TEMP_DIR/brew.log"
  export MD2PDF_FAKE_TLMGR_LOG="$TEST_TEMP_DIR/tlmgr.log"
  export MD2PDF_FAKE_NPM_LOG="$TEST_TEMP_DIR/npm.log"

  run env PATH="$fake_bin:$PATH" "$MD2PDF" --mode pandoc-pdflatex --install-deps

  [ "$status" -eq 0 ]
  [[ "$output" == *"pandoc-pdflatex dependencies installed"* ]]
  [[ "$(cat "$MD2PDF_FAKE_BREW_LOG")" == *"list --formula pandoc"* ]]
  [[ "$(cat "$MD2PDF_FAKE_BREW_LOG")" != *"install pandoc"* ]]
  [[ "$(cat "$MD2PDF_FAKE_TLMGR_LOG")" == *"install soul"* ]]
}

@test "--install-deps uses tlmgr user mode when system TeX tree is not writable" {
  fake_bin="$TEST_TEMP_DIR/fake-bin"
  fake_tex_root="$TEST_TEMP_DIR/texlive-basic"
  fake_texmf="$TEST_TEMP_DIR/user-texmf"
  mkdir -p "$fake_bin" "$fake_tex_root/tlpkg"
  chmod 555 "$fake_tex_root/tlpkg"

  cat > "$fake_bin/brew" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MD2PDF_FAKE_BREW_LOG"
SH
  cat > "$fake_bin/tlmgr" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then
  echo "tlmgr using installation: $MD2PDF_FAKE_TEX_ROOT"
  exit 0
fi
printf '%s\n' "$*" >> "$MD2PDF_FAKE_TLMGR_LOG"
SH
  cat > "$fake_bin/kpsewhich" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "-var-value=TEXMFHOME" ]; then
  echo "$MD2PDF_FAKE_TEXMF"
fi
SH
  cat > "$fake_bin/node" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  cat > "$fake_bin/npm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MD2PDF_FAKE_NPM_LOG"
SH
  chmod +x "$fake_bin/brew" "$fake_bin/tlmgr" "$fake_bin/kpsewhich" "$fake_bin/node" "$fake_bin/npm"

  export MD2PDF_FAKE_BREW_LOG="$TEST_TEMP_DIR/brew.log"
  export MD2PDF_FAKE_TLMGR_LOG="$TEST_TEMP_DIR/tlmgr.log"
  export MD2PDF_FAKE_NPM_LOG="$TEST_TEMP_DIR/npm.log"
  export MD2PDF_FAKE_TEX_ROOT="$fake_tex_root"
  export MD2PDF_FAKE_TEXMF="$fake_texmf"

  run env PATH="$fake_bin:$PATH" "$MD2PDF" --mode pandoc-pdflatex --install-deps

  [ "$status" -eq 0 ]
  [[ "$output" == *"pandoc-pdflatex dependencies installed"* ]]
  [[ "$(cat "$MD2PDF_FAKE_TLMGR_LOG")" == *"init-usertree"* ]]
  [[ "$(cat "$MD2PDF_FAKE_TLMGR_LOG")" == *"--usermode install soul"* ]]
}
