# AGENTS.md — md2pdf project notes

## Architecture in one paragraph

`bin/md2pdf` is a single self-contained Ruby script. For pandoc modes, `PANDOC_RENDER` (`bin/md2pdf:318`) builds a `combined.md` by prepending a pandoc title block (`% title / % author / % date`) to the source after passing it through `RenderHelpers.prune_frontmatter` (`bin/md2pdf:243`). Pandoc then reads `combined.md`. The render context is assembled in `Md2Pdf#render` (`bin/md2pdf:665`).

## Gotcha: empty pruned frontmatter is a YAML trap

`prune_frontmatter` strips keys md2pdf consumes (title, author, margin, fontsize, font, page_numbers, date — see `FRONTMATTER_CONSUMED` at `bin/md2pdf:70`). If a source file's frontmatter contains *only* consumed keys, naïvely keeping the `---/---` fences produces an empty YAML block:

```
---

---
```

Pandoc treats the first `---` as a horizontal rule (empty body), then sees the second `---` (preceded by a blank line) as the **start** of a fresh YAML metadata block. It scans forward to the next `---` in the body (typically a section divider) and parses everything in between as YAML. If that body contains a line starting with `**` (bold markdown), YAML's alias scanner (`*` is the alias indicator) blows up with:

```
while scanning an alias:
did not find expected alphabetic or numeric character
```

**Rule:** when modifying `prune_frontmatter`, always collapse to `""` if the pruned body is whitespace-only. Never leave bare `---/---` fences. Regression tests live in `tests/frontmatter_options.bats` under "fully-consumed frontmatter ...".

## Testing pattern

- `setup_fake_pandoc` in `tests/frontmatter_options.bats` installs a stub `pandoc` that captures the input file at `$MD2PDF_PANDOC_INPUT_LOG` and CLI args at `$MD2PDF_PANDOC_ARGS_LOG`. Use it to assert the exact bytes md2pdf hands to pandoc — fast, no LaTeX required.
- For end-to-end checks against real pandoc+xelatex, gate with `has_pandoc_xelatex || skip` (`tests/test_helper.bash:9`).
- Run `make test` (or `bats tests/`). Full suite is ~150 tests.

## Local dev install

The Homebrew formula installs to `/opt/homebrew/bin/md2pdf`. To iterate locally without touching the brew install, use `make install-dev`, which symlinks `~/.local/bin/md2pdf -> $(pwd)/bin/md2pdf`. `~/.local/bin` is earlier in PATH than `/opt/homebrew/bin` on the maintainer's setup, so the dev shim wins. `make uninstall-dev` reverts. `brew upgrade md2pdf` is unaffected.
