## Bundled PDF generation skill

- [x] Restate goal and acceptance criteria
  - Goal: Ship an agent skill owned by md2pdf that generates PDFs only through
    the `md2pdf` CLI and documents its use for humans and agents.
  - Acceptance: canonical skill source lives under `skills/pdf-generation`;
    generation never invokes a renderer directly; no Rakefile is bundled;
    README documents scope, installation, triggers, and verification.
- [x] Inspect current CLI behavior and repository conventions.
- [x] Implement the smallest client-neutral skill.
- [x] Add agent-facing metadata and human installation documentation.
- [x] Validate skill metadata, documented commands, and repository checks.

### Working notes

- The general upstream PDF skill remains responsible for reading, editing, and
  filling existing PDFs. This skill is deliberately limited to md2pdf generation.
- Install global links only from a stable clone, never this disposable worktree.

### Results

- Added `skills/pdf-generation/SKILL.md` as the canonical md2pdf-owned agent
  workflow, limited to PDF generation through the `md2pdf` CLI.
- Added generated `agents/openai.yaml` metadata for discovery and explicit
  `$pdf-generation` invocation.
- Documented human scope, safe stable-clone installation, agent triggers, and
  workflow boundaries in `README.md`.
- Verification:
  - Skill validator passed.
  - `ruby -c bin/md2pdf` passed.
  - Version, mode listing, and `pandoc-xelatex --check-deps` passed.
  - A real `tests/fixtures/sample.md` build produced a valid one-page PDF; its
    Poppler rendering was inspected with no visible defects.
  - `make test` passed: 179 tests.
  - `git diff --check` passed.
## Implementation Simplification Pass 2

- [x] Restate goal + acceptance criteria
  - Goal: refactor and simplify implementation while confirming no degradation of user-visible behavior.
  - Acceptance: implementation complexity is reduced with no CLI/output behavior changes; existing tests continue to pass; any changed behavior surface is covered by focused tests.
- [x] Locate existing implementation / patterns
- [x] Design: minimal approach + key decisions
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification (lint/tests/build/manual repro)
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

### Working Notes

- Start from committed branch `alexg0/simplify-code-tests`; keep this as a follow-up commit-sized slice.
- Prefer extracting repeated option-resolution and warning patterns over changing renderer behavior.
- Extract small helpers only: avoid table-driven metaprogramming so the warning messages and precedence remain obvious.

### Results

- Added `supports?` to centralize mode feature checks.
- Added `resolved_option` for CLI > frontmatter > default precedence on boolean render options.
- Added small warning helpers for unsupported CLI/frontmatter options while preserving exact warning messages.
- Extracted `render_context` so `render` focuses on orchestration and command execution instead of constructing every renderer option inline.
- Extracted `warn_unknown_frontmatter_keys` and reused `supports?` for mermaid preprocessing checks.
- No new tests were needed; this pass is covered by existing warning, frontmatter, section-numbering, and full behavior tests.
- Verification:
  - `ruby -c bin/md2pdf` — Syntax OK.
  - `bats tests/warning_system.bats tests/frontmatter_options.bats tests/section_numbering.bats` — 62 tests passed.
  - `bats tests/frontmatter_options.bats tests/mermaid_preprocessing.bats tests/output_resolution.bats tests/warning_system.bats tests/section_numbering.bats` — 82 tests passed.
  - `make test` — 179 tests passed.
  - `git diff --check` — passed.
- Lessons: none; no correction or postmortem was needed.

## Simplification Pass

- [x] Restate goal + acceptance criteria
  - Goal: simplify the implementation and consolidate/combine tests where appropriate without changing user-visible behavior.
  - Acceptance: duplicated pandoc rendering/test setup is reduced; existing CLI/render behavior remains covered; syntax and tests pass.
- [x] Locate existing implementation / patterns
- [x] Design: minimal approach + key decisions
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification (lint/tests/build/manual repro)
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

### Working Notes

- `bin/md2pdf` is still a single-file Ruby CLI; keep changes local and avoid introducing new dependencies.
- `PANDOC_RENDER` and `PANDOC_DOCX_RENDER` duplicate title-block input construction and metadata override flags.
- Multiple Bats files duplicate fake-pandoc setup helpers.

### Results

- Extracted shared pandoc markdown generation into `RenderHelpers.pandoc_markdown`.
- Extracted shared pandoc CLI metadata/TOC flags into `RenderHelpers.add_pandoc_document_flags`.
- Kept Unicode normalization explicit for PDF pandoc renderers so DOCX behavior stays unchanged.
- Moved fake pandoc/TeX setup, markdown fixture writing, and argument assertions into `tests/test_helper.bash`.
- Removed duplicated fake-pandoc setup from frontmatter, section-numbering, author, unicode, mermaid, and output-resolution tests.
- Verification:
  - `ruby -c bin/md2pdf` — Syntax OK.
  - `bats tests/frontmatter_options.bats tests/section_numbering.bats tests/author_resolution.bats tests/unicode_normalization.bats` — 77 tests passed.
  - `bats tests/frontmatter_options.bats tests/section_numbering.bats tests/author_resolution.bats tests/unicode_normalization.bats tests/mermaid_preprocessing.bats tests/output_resolution.bats` — 97 tests passed.
  - `make test` — 179 tests passed.
  - `git diff --check` — passed.
- Lessons: none; no correction or postmortem was needed.

## Unknown Frontmatter PDF Error

- [x] Restate goal + acceptance criteria
  - Goal: Rendering PDFs should not fail when the input markdown contains frontmatter keys md2pdf does not recognize, such as Obsidian `tags`.
  - Acceptance: unknown frontmatter keys still warn; they are not passed through to pandoc; known pandoc metadata like `toc` and `numbersections` still survives; consumed md2pdf keys are still stripped.
- [x] Locate existing implementation / patterns
- [x] Design: minimal approach + key decisions
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification (lint/tests/build/manual repro)
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

### Working Notes

- Exact sample file rendered successfully with this checkout and `/opt/homebrew/bin/md2pdf`, so this branch may already avoid the reported crash for that specific document.
- The remaining risk is that unknown app-specific YAML is preserved into the generated pandoc input, where pandoc/LaTeX can interpret it unexpectedly.
- Frontmatter pruning is now whitelist-based: only recognized, non-consumed pandoc metadata (`toc`, `numbersections`) survives into generated pandoc input.

### Results

- Replaced line-based consumed-key pruning with YAML parsing and re-emission of only renderer-relevant metadata.
- Unknown top-level frontmatter keys still warn, but are stripped before pandoc sees them.
- Obsidian-style `tags:` plus consumed `date:` frontmatter now leaves no YAML block in pandoc input.
- Updated README frontmatter semantics.
- Verification:
  - `ruby -c bin/md2pdf` — Syntax OK.
  - `bats tests/frontmatter_options.bats` — 35 tests passed.
  - `bats tests/frontmatter_options.bats tests/section_numbering.bats` — 47 tests passed.
  - `bats tests/multi_input.bats` — 6 tests passed.
  - `make test` — 167 tests passed.
  - `git diff --check` — passed.
  - Manual render of the provided Obsidian file produced `/tmp/md2pdf-unknown-frontmatter-after.pdf` and warned only for `tags`.
- Lessons: none; no user correction or postmortem was needed.

## Unknown Frontmatter Warning Controls

- [x] Restate goal + acceptance criteria
  - Goal: Let users suppress unknown frontmatter warnings globally, and provide an Obsidian-friendly mode that suppresses common Obsidian metadata warnings.
  - Acceptance: default behavior still warns for arbitrary unknown keys; `--no-warn-unknown-frontmatter` suppresses all unknown-key warnings; `--obsidian` suppresses warnings for common Obsidian keys while preserving warnings for other unknown keys; unknown keys remain stripped before pandoc.
- [x] Locate existing implementation / patterns
- [x] Design: minimal approach + key decisions
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification (lint/tests/build/manual repro)
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

### Working Notes

- Unknown-key warnings are emitted in `Md2Pdf#render` after `RenderHelpers.frontmatter_options`.
- Obsidian frontmatter keys to treat as expected foreign metadata: `tags`, `aliases`, `cssclasses`, `cssclass`, `publish`, `permalink`.

### Results

- Added `--[no-]warn-unknown-frontmatter`, defaulting to warning.
- Added `--obsidian`, which suppresses warnings for common Obsidian metadata keys while still warning for unrelated unknown keys.
- Unknown frontmatter keys remain stripped before pandoc regardless of warning settings.
- README usage and frontmatter docs updated.
- Verification:
  - `ruby -c bin/md2pdf` — Syntax OK.
  - `bats tests/frontmatter_options.bats` — 37 tests passed.
  - `make test` — 169 tests passed.
  - `git diff --check` — passed.
  - `./bin/md2pdf --help | rg -- '--\\[no-\\]warn-unknown-frontmatter|--obsidian'` showed both flags.
  - Manual render of the provided Obsidian file with `--obsidian` produced `/tmp/md2pdf-obsidian.pdf` without the `tags` warning.
- Lessons: none; no correction or postmortem was needed.

- [x] Restate goal + acceptance criteria
  - Goal: Do not add pandoc's automatic `--number-sections` flag when the source already signals section numbering.
  - Acceptance: `--number-sections` is omitted when YAML frontmatter includes `numbersections`, `number_section`, or `number_sections`, or when an existing level-2 heading starts with a number; default behavior remains numbered.
- [x] Locate existing implementation / patterns
  - Pandoc arguments are built in `PANDOC_RENDER` in `bin/md2pdf`.
  - CLI defaults live in `DEFAULTS` and are copied into render context in `Md2Pdf#render`.
- [x] Design: minimal approach + key decisions
  - Add a `number_sections` context value derived from source content before rendering.
  - Omit hard-coded `--number-sections` when frontmatter or existing H2 numbering indicates numbering is already controlled by the document.
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification (lint/tests/build/manual repro)
- [x] Summarize changes + verification story
- [x] Record lessons (if any)
- [x] Add explicit section numbering and TOC override flags
  - Acceptance: `--number-sections` and `--no-number-sections` explicitly set pandoc section numbering.
  - Acceptance: `--toc` and `--no-toc` override frontmatter, while `toc: true/false` is honored when no CLI TOC flag is provided.
  - Acceptance: `number_sections:` continues to normalize to pandoc's `numbersections:`.

## Follow-up Results

- Added `--[no-]number-sections`.
- Changed TOC handling so frontmatter `toc: true/false` is honored unless `--toc` or `--no-toc` is supplied.
- CLI overrides emit pandoc metadata (`numbersections:true/false`, `toc:true/false`) so they win over document frontmatter.
- Verified pandoc's frontmatter key for TOC is `toc`; `toc-depth` controls depth.
- Verification:
  - `ruby -c bin/md2pdf` passed.
  - `git diff --check` passed.
  - `./bin/md2pdf --help` shows `--[no-]toc` and `--[no-]number-sections`.
  - Manual fake-pandoc harness passed for default behavior, frontmatter detection, and CLI overrides.
  - `make test` passed: 89 tests.

## Working Notes

- Keep this as source-content detection, not a new user-facing flag.
- Use fake `pandoc` and TeX binaries in tests so argv can be asserted without external renderer dependencies.
- Normalize `number_sections:` to pandoc's `numbersections:` metadata key in the temporary markdown passed to pandoc.

## Results

- Added source-content detection for `numbersections`, `number_section`, `number_sections`, numbered markdown H2 headings, and numbered HTML H2 tags.
- Added frontmatter normalization so `number_sections:` is rewritten to `numbersections:` before pandoc runs.
- Pandoc still defaults to `--number-sections` unless one of those document-level signals is present.
- Added `tests/section_numbering.bats` with fake renderer assertions for the pandoc argv.
- Verification:
  - `ruby -c bin/md2pdf` passed.
  - Direct `RenderHelpers.number_sections?` checks passed.
  - Manual fake-pandoc CLI harness passed for default, all three frontmatter spellings, markdown H2, and HTML H2 cases.
  - Manual pandoc metadata probe confirmed pandoc reads `numbersections` from the generated metadata position.
  - `git diff --check` passed.
  - `make test` could not run because `bats-core` is not installed.
- Lessons: none; no correction or postmortem occurred.

## AG-5: Native fenced ```mermaid rendering

- [x] Restate goal + acceptance criteria
  - Goal: Pre-render fenced ```mermaid blocks to cached PNGs via `mmdc` so callers don't have to preprocess markdown.
  - Acceptance: cache hits skip mmdc; no fences → no mmdc dep; missing mmdc with fences fails with actionable message; `--install-deps` installs mermaid-cli into `MD2PDF_TOOL_HOME`; `--list-modes` shows mermaid support; `--no-mermaid` disables preprocessing.
- [x] Locate existing implementation / patterns
  - Modes have `supports:` declaration consumed by warnings + display.
  - `ensure_npm_package` already installs locally to `${MD2PDF_TOOL_HOME}/npm/<package>`; reused for the scoped `@mermaid-js/mermaid-cli` package after sanitizing the package.json `name` field.
- [x] Design: minimal approach + key decisions
  - New `MermaidPreprocessor` module: line-by-line fence walk that ignores nested fences (delimiter+indent must match to close).
  - `Md2Pdf#preprocess_mermaid` runs before render lambda; rewritten markdown lives in tmpdir and `ctx[:input]` is swapped, leaving `resource_path` based on the original file.
  - `:mermaid` added to every mode's `supports:` (all current modes consume markdown).
- [x] Implement smallest safe slice
- [x] Add/adjust tests (`tests/mermaid_preprocessing.bats`)
- [x] Run verification

## AG-5 Results

- Mermaid blocks render to `${MD2PDF_TOOL_HOME}/cache/mermaid/mermaid-<sha12>.png`; fences replaced with absolute-path image refs.
- `mmdc` invoked as `mmdc -i tmp.mmd -o png --backgroundColor white --scale 2 --quiet`, with `-p $MMDC_PUPPETEER_CONFIG` appended when the env var points at an existing file.
- `--install-deps` for any mode also installs `@mermaid-js/mermaid-cli` locally (scoped names sanitized in package.json).
- `--list-modes` now shows `features=mermaid`.
- `--no-mermaid` short-circuits preprocessing; missing mmdc with fences aborts with actionable message.
- Verification:
  - `ruby -c bin/md2pdf` — Syntax OK.
  - `bats tests/` — 93 tests pass (4 new mermaid tests).
  - End-to-end: rendered a doc with a real graph through pandoc-xelatex; second run reused the cached PNG.

## AG-6: Mermaid regression follow-up

- [x] Restate goal + acceptance criteria
  - Goal: Fix the mermaid preprocessing regressions found in review without widening scope.
  - Acceptance: relative assets still resolve from the original markdown directory after preprocessing; mermaid blocks nested in list indentation keep that indentation; valid longer closing fences still render.
- [x] Locate existing implementation / patterns
  - Mermaid preprocessing lives in `MermaidPreprocessor` inside `bin/md2pdf`.
  - `md-to-pdf` derives `basedir` from `ctx[:input]`, which now changes after preprocessing.
- [x] Design: minimal approach + key decisions
  - Preserve the original source directory separately in render context instead of relying on the rewritten temp file path.
  - Store fence indentation in the detected block metadata and reuse it when emitting the replacement image.
  - Relax closing-fence matching to accept the same delimiter character with at least the opening fence length.
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification (lint/tests/build/manual repro)
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

## AG-6 Results

- Mermaid replacements now preserve the original fence indentation, so list-nested diagrams remain inside their list item structure.
- Closing-fence detection now accepts the same fence character repeated at least as many times as the opener, which covers valid longer closers like ```` after ```mermaid.
- `md-to-pdf` now keeps `basedir` pointed at the original markdown directory even when mermaid preprocessing rewrites the input into a temp file.
- Added regression coverage in `tests/mermaid_preprocessing.bats` for list indentation, longer closing fences, and `md-to-pdf` basedir preservation.
- Verification:
  - `ruby -c bin/md2pdf` — Syntax OK.
  - `bats tests/mermaid_preprocessing.bats` — 7 tests passed.
  - `bats tests/` — 96 tests passed.
  - `git diff --check` — passed.
- Lessons: none; the regressions were caught by review before merge, so no new prevention rule was needed beyond the added tests.

## Review Fix Follow-up

- [x] Restate goal + acceptance criteria
  - Goal: Address review findings for author precedence and README/CLI mismatch.
  - Acceptance: `--author` is accepted as an alias for `-a`; explicit author and `--no-author` override YAML `author:` in Pandoc-mode outputs.
- [x] Locate existing implementation / patterns
  - Author metadata is resolved in `Md2Pdf#resolve_author`; Pandoc temp markdown is built in `PANDOC_RENDER`.
- [x] Implement smallest safe slice
  - Added `--author` as an alias for `-a`.
  - Removed top-level YAML `author:` from Pandoc temp input when CLI author or `--no-author` explicitly overrides source metadata.
- [x] Add/adjust tests
  - Added `--author` alias coverage.
  - Added assertions that explicit override/suppression removes simple and multiline frontmatter author metadata from the Pandoc input.
- [x] Run verification (syntax, diff check, focused tests, full test suite)
- [x] Summarize changes + verification story

## Review Fix Results

- `ruby -c bin/md2pdf` passed.
- `bats tests/author_resolution.bats` passed: 17 tests.
- `make test` passed: 106 tests.
- `git diff --check` passed.
- `./bin/md2pdf --help` shows `-a, --author AUTHOR`.

## AG-6 (Linear): Frontmatter-driven per-doc options

- [x] Add `frontmatter_options` parser returning `(options_hash, unknown_keys)`
- [x] Add `prune_frontmatter` to strip consumed keys + normalize aliases
- [x] Wire CLI > frontmatter > default precedence in `Md2Pdf#render`
- [x] Strip `title`, `author`, `date`, `margin`, `fontsize`, `font`, `page_numbers` from frontmatter passed to pandoc
- [x] Warn on unrecognized frontmatter keys
- [x] Tests for title, author, margin, fontsize, font, page_numbers, date, aliases, unknown-key warning
- [x] README updated with recognized keys, aliases, and precedence

### Lessons

- Ruby `Regexp` mixes named and unnamed capture groups badly — when a pattern contains
  a named group (e.g., `(?<body>...)`), unnamed groups stop being indexable via
  `m[1]`/`m[3]` and only the named ones populate. Fix: name *all* groups consistently
  in the same pattern.

## AG-6 Review Fixes: Frontmatter parser regressions

- [x] Restate goal + acceptance criteria
  - Goal: Add failing coverage for the three review findings, then fix frontmatter parsing and unsupported-option warnings.
  - Acceptance: quoted `#` scalar values remain intact; nested YAML keys are not treated as top-level md2pdf options or stripped; frontmatter options unsupported by a selected renderer warn before rendering.
- [x] Locate existing implementation / patterns
  - `RenderHelpers.frontmatter_options` owns option extraction; `prune_frontmatter` owns metadata stripping; `warn_unmapped_options` only sees CLI state before render.
- [x] Add regression tests for each reviewed issue and confirm they fail
  - `bats tests/frontmatter_options.bats` failed on the three new tests before implementation.
- [x] Implement smallest safe parser/warning fix
  - Use `YAML.safe_load` for top-level option extraction; constrain pruning to top-level consumed keys only; emit unsupported frontmatter warnings after parsing.
- [x] Run focused and full verification
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

### Working Notes

- The current parser is regex/line based; reviewed failures are in scalar comment handling, top-level key detection, and warning timing.

### Results

- Added regression tests for quoted hash scalars, nested YAML metadata, nested `numbersections`, and unsupported frontmatter `font` under `pandoc-pdflatex`.
- Replaced regex value extraction with YAML parsing for frontmatter options and kept nested metadata intact during pruning.
- Unsupported frontmatter options now warn during render after frontmatter is available.
- Verification:
  - `ruby -c bin/md2pdf` — Syntax OK.
  - `bats tests/frontmatter_options.bats tests/section_numbering.bats` — 33 tests passed.
  - `bats tests/author_resolution.bats tests/frontmatter_options.bats tests/section_numbering.bats` — 50 tests passed after rebase.
  - `bats tests/` — 143 tests passed after rebase.
  - `git diff --check origin/master...HEAD` — passed.
- Lessons: no new correction; these regressions were covered before fixing as requested.

## AG-7: Distribute via Homebrew tap

- [x] Restate goal + acceptance criteria
  - Goal: `brew install alexg0/tap/md2pdf` installs a working `md2pdf` from a tagged release; future releases automated via tag-push.
  - Acceptance:
    - `md2pdf --version` reports the tag (e.g. `0.1.0`).
    - `Formula/md2pdf.rb` template exists in this repo as the seed for `alexg0/homebrew-tap`.
    - `make release-tag VERSION=X.Y.Z` bumps `VERSION`, rewrites the baked constant, commits, creates annotated tag.
    - On tag push, GitHub Action computes tarball sha256 and opens a PR against `alexg0/homebrew-tap` updating url/sha256/version.
    - README installation section leads with `brew tap` / `brew install`; `make install` retained as "Install from source".
- [x] Locate existing implementation / patterns
  - `bin/md2pdf` uses `OptionParser`; options defined around line 416.
  - `Makefile` uses `.PHONY` targets with `## help` comments.
  - No `.github/workflows/` exists yet.
- [x] Design: minimal approach + key decisions
  - Bake `MD2PDF_VERSION` constant in `bin/md2pdf` (no extra install file needed for Homebrew).
  - Keep a `VERSION` file for human/CI consumption; `release-tag` updates both via `sed`.
  - Reference formula at `packaging/homebrew/md2pdf.rb` (not auto-installed; just a seed for the tap).
  - GitHub Action uses `peter-evans/create-pull-request` against `alexg0/homebrew-tap` with `HOMEBREW_TAP_TOKEN` PAT.
- [x] Implement smallest safe slice
- [x] Add/adjust tests (smoke `--version`)
- [x] Run verification (`ruby -c`, `--version`, `make test` if bats present)
- [x] Summarize changes + verification story

## AG-7 Results

- `VERSION` file created at `0.1.0`.
- `MD2PDF_VERSION = "0.1.0"` baked in `bin/md2pdf`; `--version` prints it and exits 0.
- `Makefile` gains `release-tag` target: validates VERSION, requires clean tree, checks tag absence, rewrites `VERSION` and the constant via `sed`, commits, creates annotated `vX.Y.Z` tag.
- `README.md` Installation now leads with `brew install alexg0/tap/md2pdf`; `make install` retained as "Install from source"; new "Releasing" section documents the tap bootstrap and PAT requirement.
- `.github/workflows/release.yml` triggers on `v*.*.*` tag push: downloads release tarball, computes sha256, rewrites `Formula/md2pdf.rb` (url/sha256/version) in the tap checkout, opens PR via `peter-evans/create-pull-request@v6` using `HOMEBREW_TAP_TOKEN`.
- `packaging/homebrew/md2pdf.rb` is the seed formula for `alexg0/homebrew-tap` (depends on `pandoc`, suggests TeX + font casks in `caveats`, has a `--version` / `--help` smoke test).
- Verification:
  - `ruby -c bin/md2pdf` passed.
  - `bin/md2pdf --version` prints `0.1.0`, exit 0.
  - `bin/md2pdf --help` lists `--version`, exit 0.
  - `ruby -c packaging/homebrew/md2pdf.rb` passed.
  - `ruby -ryaml -e YAML.load_file(workflow)` passed.
  - Sed pattern dry-run rewrote `MD2PDF_VERSION = "0.1.0"` to `"9.9.9"` cleanly.
  - `make test` passed (89 tests, all `ok`).

### AG-7 Working Notes

- One-time prerequisite: create `alexg0/homebrew-tap` repo, drop `packaging/homebrew/md2pdf.rb` in as `Formula/md2pdf.rb` with the real sha256 from the first tarball, and add `HOMEBREW_TAP_TOKEN` PAT secret to this repo. (Done during this branch: tap repo created, formula seeded with placeholder sha256 that the release workflow will overwrite, secret set using the gh CLI token.)
- Tarball URL pattern: `https://github.com/alexg0/md2pdf/archive/refs/tags/vX.Y.Z.tar.gz`.
- Future releases: `make release-tag VERSION=X.Y.Z && git push origin master vX.Y.Z`.

## Output Directory Target for -o

- [x] Restate goal + acceptance criteria
  - Goal: Let `-o/--output` accept a directory and write the converted file there using the input basename and mode-specific output extension.
  - Acceptance: existing directory paths and trailing-slash directory paths work; explicit file output remains unchanged; parent directories are still auto-created.
- [x] Locate existing implementation / patterns
  - Output path handling is centralized in `Md2Pdf#resolve_output`.
- [x] Design: minimal approach + key decisions
  - Treat `-o` as a directory only when the path already exists as a directory or clearly ends with a directory separator.
  - Preserve traditional explicit-file semantics for non-existing paths like `build/report.pdf`.
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

### Results

- `-o DIR input.md` now resolves to `DIR/input.pdf` for PDF modes.
- `--mode pandoc-docx -o DIR input.md` now resolves to `DIR/input.docx`.
- `-o DIR/ input.md` creates `DIR/` and writes the mode-specific output filename there.
- README usage now documents output directories.
- Verification:
  - `bats tests/output_resolution.bats` passed: 13 tests.
  - `make test` passed: 172 tests.
- Lessons: none; no correction or postmortem occurred.

## Pandoc LaTeX --install-deps TeX Packages

- [x] Restate goal + acceptance criteria
  - Goal: `md2pdf --install-deps` for Pandoc LaTeX modes installs the TeX Live packages needed by Pandoc's generated LaTeX.
  - Acceptance: Markdown strikethrough no longer fails after running install deps on BasicTeX because `soul.sty` is installed.
  - Acceptance: Already-installed Homebrew formulae/casks, TeX packages, and local npm packages are skipped so `--install-deps` avoids noisy up-to-date warnings.
- [x] Locate existing implementation / patterns
  - Mode dependency recipes live in `MODES[*][:install]`.
  - `install_mode_deps` already handles recipe keys for brew, casks, npm, go, and weasy.
- [x] Design: minimal approach + key decisions
  - Add a `tlmgr:` recipe key for Pandoc LaTeX modes.
  - Keep package names in a shared constant so xelatex/lualatex/pdflatex stay aligned.
  - Use `tlmgr` user mode when the system TeX tree is not writable, avoiding sudo prompts for normal macOS BasicTeX installs.
  - Check Homebrew install status before calling `brew install`.
  - Check TeX and local npm package status before rerunning their installers.
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

### Results

- Pandoc LaTeX install recipes now install `soul` through `tlmgr`, covering Pandoc strikethrough output (`soul.sty`).
- `--install-deps` uses TeX Live user mode when the system TeX tree is not writable, avoiding sudo for normal BasicTeX installs.
- Already-installed Homebrew formulae/casks are skipped with `brew list` checks, so Homebrew no longer emits up-to-date warnings during `--install-deps`.
- Already-installed TeX and npm packages are skipped too, so repeat `--install-deps` runs are quiet.
- Verification:
  - `ruby -c bin/md2pdf` passed.
  - `bats tests/dependency_checking.bats` passed: 8 tests.
  - `./bin/md2pdf --install-deps` installed `soul` into the user TeX tree.
  - A repeat `./bin/md2pdf --install-deps` emitted only `pandoc-xelatex dependencies installed`.
  - `kpsewhich soul.sty` resolves to `~/Library/texmf/tex/generic/soul/soul.sty`.
  - `make test` passed: 174 tests.
  - `git diff --check` passed.
  - Original failing health target `rake 'pdf:build[retatrutide-monitoring]'` passed after `soul` was installed.
- Lessons: none; no correction or postmortem occurred.

## LaTeX Comparison Symbol Normalization

- [x] Restate goal + acceptance criteria
  - Goal: Unicode comparison symbols should typeset as LaTeX math in Pandoc LaTeX output instead of depending on the body font.
  - Acceptance: `≤` becomes `$\leq$` and `≥` becomes `$\geq$` in the markdown handed to Pandoc.
- [x] Locate existing implementation / patterns
  - LaTeX Unicode normalization happens in `LATEX_UNICODE` before `PANDOC_RENDER` writes `combined.md`.
- [x] Design: minimal approach + key decisions
  - Keep the existing normalization table and update only the comparison symbol mappings.
  - Cover the real md2pdf-to-Pandoc input path with a fake Pandoc test.
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

### Results

- `LATEX_UNICODE` now maps `≤` to `$\leq$` and `≥` to `$\geq$` before Pandoc writes LaTeX-backed PDFs.
- Added a fake-Pandoc regression test that verifies the actual markdown handed to Pandoc contains math commands instead of raw Unicode comparison glyphs.
- Verification:
  - `ruby -c bin/md2pdf` passed.
  - `bats tests/unicode_normalization.bats` passed: 7 tests.
  - Real render of `Limit ≤ 10 and floor ≥ 5` produced a PDF without missing-character warnings.
- `make test` passed: 175 tests.
- Lessons: none; no correction or postmortem occurred.

## Test Suite Runtime

- [x] Restate goal and acceptance criteria.
  - Goal: reduce full test-suite wall time by at least 25%.
  - Acceptance: all 167 existing tests and assertions still run and pass; measured elapsed time is at most 75% of the serial baseline.
- [x] Locate the current test runner and isolation conventions.
- [x] Measure the serial baseline and identify slow tests.
- [x] Apply the smallest coverage-preserving runner optimization.
- [x] Benchmark the optimized suite and verify the full test count.
- [x] Record results and remaining constraints.

### Working notes

- Bats 1.14.0 and GNU Parallel are available locally.
- Every test creates an independent `TEST_TEMP_DIR` and `MD2PDF_TOOL_HOME`, so test processes do not share generated artifacts.
- Serial baseline: 149.87 seconds for 167 tests.
- Direct `bats --jobs 8 tests/` benchmark: 37.31 seconds for the same 167 tests (75.1% faster).
- `make test` uses eight jobs when GNU Parallel or `rush` is available and otherwise preserves the serial fallback.
- The documented developer setup and CI install GNU Parallel so the parallel path is the normal default.

### Results

- `make test` now runs the suite with eight Bats jobs by default; `TEST_JOBS` can override the concurrency.
- Serial baseline: 149.87 seconds. Optimized `make test`: 36.73 seconds, a 75.5% reduction and well beyond the required 25%.
- A second parallel run completed in 37.31 seconds, confirming the result was repeatable.
- Coverage-equivalent verification: all 167 tests passed in both optimized runs, `bats --count tests/` still reports 167, and no Bats test or production source file changed.
- Environments without GNU Parallel or `rush` fall back to the original serial runner.
- `make install-prereqs` and CI now install GNU Parallel; workflow YAML syntax and `git diff --check` pass.
- Lessons: none; no correction or postmortem was needed.

### Coverage follow-up

- [x] Preserve the same 167-test suite and parallel runner.
- [x] Add dependency-free line coverage for every `md2pdf` subprocess.
- [x] Merge coverage data safely across parallel test jobs.
- [x] Add `make coverage` and run it in CI without duplicating the suite.
- [x] Measure line coverage and instrumented wall time.

Coverage result: `make coverage` passed all 167 tests, covered 538 of 608
executable lines (88.49%), and completed in 35.25 seconds. Instrumentation still
leaves the suite 76.5% faster than the 149.87-second serial baseline.

### Runtime follow-up

- [x] Benchmark 16, 24, and 28 parallel jobs without changing tests.
- [x] Keep concurrency below the measured contention point.
- [x] Reuse Bats' native per-test temporary directory instead of nesting `mktemp` and duplicate cleanup.
- [x] Reuse checked-in fake render executables instead of recreating them in every test.
- [x] Verify a stable measured run at least 10 seconds faster than 35.25 seconds.

Optimized `make coverage` runs completed in 16.82–18.55 seconds with all 167 tests
passing and line coverage unchanged at 538 of 608 executable lines (88.49%). The
16.70-second worst-case reduction exceeds the requested additional 10 seconds. All
existing real-pandoc/XeLaTeX integration tests remain unchanged; the speedup comes
from using 16 workers, Bats' native temporary directories, and shared fake render
executables instead of rewriting and chmodding four copies per fake-render test.

Shebang microbenchmark (2,000 no-op fake-engine launches): `/usr/bin/env bash`
16.84 seconds, `/bin/sh` 8.26 seconds, and direct `/bin/bash` 5.66 seconds. Direct
Bash retained the existing fake-Pandoc implementation and produced full coverage
runs of 18.55, 17.47, and 16.82 seconds; the full-suite improvement over `env` is
small relative to scheduling variance, but `/bin/sh` was slower and required a
needless POSIX rewrite.
