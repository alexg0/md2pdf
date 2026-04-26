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
