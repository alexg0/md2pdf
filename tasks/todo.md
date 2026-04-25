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
