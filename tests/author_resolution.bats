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

# Install a fake `git` shim that returns a configured user.name. The shim is
# placed in fake-bin and shadows the real git for the test process.
install_fake_git() {
  local name="$1"
  cat > "$TEST_TEMP_DIR/fake-bin/git" <<SH
#!/usr/bin/env bash
# Match: git -C <dir> config user.name
if [ "\$1" = "-C" ] && [ "\$3" = "config" ] && [ "\$4" = "user.name" ]; then
  printf '%s\n' "${name}"
  exit 0
fi
exit 1
SH
  chmod +x "$TEST_TEMP_DIR/fake-bin/git"
}

# Install a fake git that fails (simulates "outside a git repo")
install_failing_git() {
  cat > "$TEST_TEMP_DIR/fake-bin/git" <<'SH'
#!/usr/bin/env bash
exit 1
SH
  chmod +x "$TEST_TEMP_DIR/fake-bin/git"
}

write_doc() {
  local path="$1"
  shift
  printf '%s\n' "$@" > "$path"
}

# Strip the env so leftover GIT_AUTHOR_NAME etc. from the surrounding shell
# don't leak into tests that exercise the env-var fallback path.
clear_author_env() {
  unset GIT_AUTHOR_NAME
  unset GIT_COMMITTER_NAME
  unset NAME
  unset MAILNAME
}

@test "CLI -a wins over everything" {
  setup_fake_pandoc
  install_fake_git "Git Name"
  clear_author_env
  export GIT_AUTHOR_NAME="Env Name"
  local input="$TEST_TEMP_DIR/cli-author.md"
  write_doc "$input" "---" "author: Frontmatter Name" "---" "" "# Title" "Body"

  run "$MD2PDF" -a "CLI Name" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% CLI Name$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Frontmatter Name" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "CLI --author alias wins over everything" {
  setup_fake_pandoc
  install_fake_git "Git Name"
  clear_author_env
  export GIT_AUTHOR_NAME="Env Name"
  local input="$TEST_TEMP_DIR/long-cli-author.md"
  write_doc "$input" "---" "author: Frontmatter Name" "---" "" "# Title" "Body"

  run "$MD2PDF" --author "CLI Alias Name" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% CLI Alias Name$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Frontmatter Name" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "frontmatter author wins over git and env" {
  setup_fake_pandoc
  install_fake_git "Git Name"
  clear_author_env
  export GIT_AUTHOR_NAME="Env Name"
  local input="$TEST_TEMP_DIR/fm-author.md"
  write_doc "$input" "---" "author: Frontmatter Name" "---" "" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Frontmatter Name$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "frontmatter author handles double-quoted value" {
  setup_fake_pandoc
  install_failing_git
  clear_author_env
  local input="$TEST_TEMP_DIR/fm-quoted.md"
  write_doc "$input" "---" 'author: "Quoted Name"' "---" "" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Quoted Name$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "git config user.name is used when frontmatter lacks author" {
  setup_fake_pandoc
  install_fake_git "Jane Doe"
  clear_author_env
  local input="$TEST_TEMP_DIR/git-author.md"
  write_doc "$input" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Jane Doe$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "GIT_AUTHOR_NAME overrides git config user.name (matches git semantics)" {
  setup_fake_pandoc
  install_fake_git "Config Name"
  clear_author_env
  export GIT_AUTHOR_NAME="Env Author"
  local input="$TEST_TEMP_DIR/env-overrides-git.md"
  write_doc "$input" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Env Author$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Config Name" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "GIT_COMMITTER_NAME overrides git config user.name when GIT_AUTHOR_NAME is unset" {
  setup_fake_pandoc
  install_fake_git "Config Name"
  clear_author_env
  export GIT_COMMITTER_NAME="Committer Name"
  local input="$TEST_TEMP_DIR/committer-overrides-git.md"
  write_doc "$input" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Committer Name$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Config Name" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "GIT_AUTHOR_NAME wins over GIT_COMMITTER_NAME" {
  setup_fake_pandoc
  install_failing_git
  clear_author_env
  export GIT_AUTHOR_NAME="Author Wins"
  export GIT_COMMITTER_NAME="Committer Loses"
  local input="$TEST_TEMP_DIR/author-over-committer.md"
  write_doc "$input" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Author Wins$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "git config user.name is used when GIT_*_NAME env vars are absent" {
  setup_fake_pandoc
  install_fake_git "Config Wins"
  clear_author_env
  export NAME="NAME Loses"
  local input="$TEST_TEMP_DIR/git-over-name.md"
  write_doc "$input" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Config Wins$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "NAME Loses" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "env var NAME is used when git and GIT_* env vars are absent" {
  setup_fake_pandoc
  install_failing_git
  clear_author_env
  export NAME="Plain Name"
  local input="$TEST_TEMP_DIR/env-name.md"
  write_doc "$input" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Plain Name$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "env var MAILNAME is used as a last resort" {
  setup_fake_pandoc
  install_failing_git
  clear_author_env
  export MAILNAME="Mail Name"
  local input="$TEST_TEMP_DIR/env-mailname.md"
  write_doc "$input" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% Mail Name$" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "no author line when nothing resolves" {
  setup_fake_pandoc
  install_failing_git
  clear_author_env
  local input="$TEST_TEMP_DIR/no-author.md"
  write_doc "$input" "# Title" "Body"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  # The pandoc title block writes the author line as `% ` (empty after the marker)
  grep -q "^% $" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "--no-author suppresses everything including frontmatter and git" {
  setup_fake_pandoc
  install_fake_git "Git Name"
  clear_author_env
  export GIT_AUTHOR_NAME="Env Name"
  local input="$TEST_TEMP_DIR/no-author-flag.md"
  write_doc "$input" "---" "author: Frontmatter Name" "---" "" "# Title" "Body"

  run "$MD2PDF" --no-author "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% $" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Frontmatter Name" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Git Name" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Env Name" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "--no-author removes multiline frontmatter author metadata" {
  setup_fake_pandoc
  install_failing_git
  clear_author_env
  local input="$TEST_TEMP_DIR/no-author-multiline.md"
  write_doc "$input" "---" "title: Frontmatter Title" "author:" "  - Frontmatter One" "  - Frontmatter Two" "toc: true" "---" "" "# Title" "Body"

  run "$MD2PDF" --no-author "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -q "^% $" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Frontmatter One" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "Frontmatter Two" "$MD2PDF_PANDOC_INPUT_LOG"
  grep -q "^% Frontmatter Title$" "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -q "title: Frontmatter Title" "$MD2PDF_PANDOC_INPUT_LOG"
  grep -q "toc: true" "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "implicit author fallback does not warn for modes that ignore author" {
  clear_author_env
  output=$("$MD2PDF" --mode pandoc-wkhtmltopdf --mode-help 2>&1)
  [[ "$output" != *"warning:"*"author"* ]]
}

@test "explicit -a still warns for modes that ignore author" {
  clear_author_env
  output=$("$MD2PDF" --mode pandoc-wkhtmltopdf -a "Some Author" --mode-help 2>&1)
  [[ "$output" == *"warning:"*"author"* ]]
}

@test "--no-author does not warn for modes that ignore author" {
  clear_author_env
  output=$("$MD2PDF" --mode pandoc-wkhtmltopdf --no-author --mode-help 2>&1)
  [[ "$output" != *"warning:"*"author"* ]]
}
