# md2pdf

Multi-engine Markdown to PDF (and DOCX) converter. Supports 11 rendering backends with a unified CLI interface.

## Features

- **11 rendering backends** with automatic fallback and dependency management
- Configurable title, author, margins, font size, and page numbering
- Automatic table of contents generation (where supported)
- Automatic title detection from first H1 heading
- Isolated tool home directory to avoid global binary conflicts
- Unicode character normalization for LaTeX engines
- Native rendering of fenced ```` ```mermaid ```` blocks via `mmdc` (cached)
- Per-mode warnings when options are unsupported

## Supported Modes

| Mode | Engine | Runtime Dependencies |
|------|--------|---------------------|
| `pandoc-xelatex` (default) | Pandoc + XeLaTeX | pandoc, xelatex |
| `latex` | Alias for pandoc-xelatex | pandoc, xelatex |
| `pandoc-lualatex` | Pandoc + LuaLaTeX | pandoc, lualatex |
| `pandoc-pdflatex` | Pandoc + pdfLaTeX | pandoc, pdflatex |
| `pandoc-wkhtmltopdf` | Pandoc + wkhtmltopdf | pandoc, wkhtmltopdf |
| `pandoc-weasyprint` | Pandoc + WeasyPrint | pandoc, weasyprint |
| `md-to-pdf` | Node/Puppeteer | node, npm |
| `mdpdf` | Node/Puppeteer | node, npm |
| `go-md2pdf` | Go/fpdf | go |
| `weasy-md2pdf` | Python/WeasyPrint | python3, brew |
| `percollate` | Experimental HTML-first | pandoc, node, npm |
| `pandoc-docx` (aliases: `docx`, `word`) | Pandoc → DOCX (Word) | pandoc, zip |

## Installation

### Homebrew (recommended)

```bash
brew install alexg0/tap/md2pdf
```

This installs `md2pdf` and `pandoc` (the default rendering backend's main dependency).
For the default `pandoc-xelatex` mode you also need a TeX distribution and a body font:

```bash
brew install --cask basictex
brew install --cask font-noto-serif
```

### Install from source

```bash
git clone https://github.com/alexg0/md2pdf
cd md2pdf
make install
```

This copies `md2pdf` to `/usr/local/bin`. Override the prefix:

```bash
make install PREFIX=~/.local
```

To uninstall:

```bash
make uninstall
```

### Install rendering engine dependencies

```bash
# Install dependencies for the default mode (pandoc-xelatex)
md2pdf --install-deps

# Install dependencies for a specific mode
md2pdf --mode md-to-pdf --install-deps

# Install all mode dependencies
md2pdf --install-deps-all
```

## Usage

```
Usage: md2pdf [options] input.md [input2.md ...] [output.pdf|output.docx | -o PATH]

Common options:
  --mode MODE         Renderer mode (default: pandoc-xelatex)
  -t TITLE            PDF title (default: first # H1 from file, or filename)
  -a, --author AUTHOR Author line (default: frontmatter `author:`, then `git config user.name`, then env vars)
  --no-author         Suppress author line entirely
  -o, --output PATH   Output PDF path (required when passing multiple inputs
                      unless the last positional ends in .pdf)
  --font FONT         Preferred body font where supported (default: Noto Serif)
  -m MARGIN           Page margin (default: 1in)
  -s SIZE             Font size (default: 11pt)
  --page-numbers      Show page numbers where supported (default: on)
  --no-page-numbers   Hide page numbers where supported
  --toc               Generate table of contents where supported
  --no-toc            Omit table of contents where supported
  --number-sections   Number section headings
  --no-number-sections
                      Do not number section headings
  --mermaid           Pre-render fenced ```mermaid blocks via mmdc (default)
  --no-mermaid        Skip mermaid preprocessing
  --reference-doc PATH
                      DOCX template for pandoc-docx mode (controls fonts,
                      margins, styles via Word's reference-doc mechanism)

Actions:
  --list-modes        List modes and install status
  --check-deps        Validate dependencies for the selected mode
  --check-deps-all    Validate dependencies for all modes
  --install-deps      Install dependencies for the selected mode
  --install-deps-all  Install dependencies for all modes
  --mode-help         Show notes for the selected mode
```

### Examples

```bash
# Convert with default engine
md2pdf README.md

# Specify output file
md2pdf README.md output.pdf

# Concatenate multiple inputs into a single PDF (last positional .pdf is output)
md2pdf intro.md chapter1.md chapter2.md book.pdf

# Same, with explicit -o (all positionals are inputs)
md2pdf -o book.pdf intro.md chapter1.md chapter2.md

# Use a different engine
md2pdf --mode pandoc-lualatex README.md

# Custom title, author, and formatting
md2pdf -t "My Report" -a "Jane Doe" -m "0.5in" -s "12pt" report.md

# Override frontmatter-controlled generated structure
md2pdf --toc --no-number-sections report.md

# List all modes and their install status
md2pdf --list-modes

# Check if dependencies are met
md2pdf --mode go-md2pdf --check-deps
```

### Multiple inputs

When multiple input files are passed, they are concatenated (separated by a
blank line) and rendered as a single PDF. Title auto-detection runs on the
first input only. YAML frontmatter from the first input is preserved;
frontmatter blocks in subsequent inputs are stripped silently. For pandoc
modes, the resource path includes every input file's directory, so embedded
images resolve relative to whichever input referenced them.

### Per-document options via YAML frontmatter

Pandoc modes honor a YAML frontmatter block at the top of the markdown file
for per-document overrides:

```yaml
---
title:        # string, overrides H1 auto-detection
author:       # string
date:         # string, overrides file mtime
margin:       # bare value like 0.75in or 20mm
fontsize:     # e.g. 10pt
font:         # e.g. Noto Serif
page_numbers: # bool
toc:          # bool
numbersections: # bool
---
```

**Precedence:** CLI flag > frontmatter > built-in default.

**Key aliases (normalized to canonical):**

* `font_size` -> `fontsize`
* `page-numbers`, `pageNumbers` -> `page_numbers`
* `number_sections`, `number_section` -> `numbersections`

Consumed keys (`title`, `author`, `date`, `margin`, `fontsize`, `font`,
`page_numbers`) are stripped from the frontmatter before pandoc reads it, to
avoid double-emission in the title block. `toc` and `numbersections` are
preserved so pandoc reads them directly.

Unrecognized frontmatter keys emit a warning to stderr but do not abort
rendering.

### Author resolution

When `-a/--author` is not supplied on the CLI, `md2pdf` resolves the author line
in this order:

1. `-a AUTHOR` / `--author AUTHOR` on the command line
2. `author:` in YAML frontmatter
3. `GIT_AUTHOR_NAME` (env)
4. `GIT_COMMITTER_NAME` (env)
5. `git config user.name` (run from the input file's directory)
6. `NAME`, then `MAILNAME` (env)
7. No author line

Steps 3–4 sit above `git config user.name` to mirror git's own override
semantics: when `GIT_AUTHOR_NAME` is set, `git commit` ignores `user.name`,
and `md2pdf` does the same.

`--no-author` short-circuits the chain and produces a blank author line, which
is useful in CI or when the document should appear unsigned.

## Mermaid diagrams

Fenced ```` ```mermaid ```` blocks are rendered to cached PNGs via
[mermaid-cli](https://github.com/mermaid-js/mermaid-cli) before the markdown is
handed to the renderer. PNGs are cached in
`${MD2PDF_TOOL_HOME}/cache/mermaid/mermaid-<hash>.png` keyed by a SHA-256 of
the block contents, so repeated runs skip `mmdc`.

If a document has no mermaid fences, `mmdc` is never invoked and is not a
required dependency. When fences are present but `mmdc` is missing, `md2pdf`
exits with instructions to install it (`md2pdf --install-deps` for the
selected mode, or `npm i -g @mermaid-js/mermaid-cli`). Pass `--no-mermaid` to
leave fences untouched.

## DOCX output

Despite the name, `md2pdf` also produces Microsoft Word documents via the
`pandoc-docx` mode (also accepts `--mode docx` or `--mode word`):

```bash
# Default output extension follows the mode (foo.md -> foo.docx)
md2pdf --mode docx report.md

# Or pass an explicit .docx path as the last positional
md2pdf --mode docx report.md report.docx

# Use a Word template to control fonts, margins, and paragraph styles
md2pdf --mode word --reference-doc template.docx report.md
```

`--reference-doc` is forwarded to pandoc's `--reference-doc` flag. To create a
starter template, run `pandoc -o template.docx --print-default-data-file reference.docx`,
edit it in Word, then point `--reference-doc` at it.

`pandoc-docx` honors `-t/--title`, `-a/--author`, `--toc`, `--number-sections`,
and mermaid preprocessing. The same keys are also read from YAML frontmatter
(`title`, `author`, `date`, `toc`, `numbersections`) — same precedence as the
PDF modes (CLI > frontmatter > default). `margin`/`fontsize`/`font` are
ignored (with warnings) because docx layout is template-driven; control them
through `--reference-doc` instead. `--reference-doc` itself is CLI-only.

`md2pdf` post-processes the docx to set `<w:updateFields w:val="true"/>` in
`word/settings.xml`. Without it, Word opens the file with a blank TOC and
prompts the user to "update fields" / "update external references" — pandoc
emits TOC fields with no cached body that Word evaluates lazily. The patch
asks Word to evaluate fields at open time so the TOC populates and the
prompt is suppressed. Requires `unzip` and `zip` on PATH (preinstalled on
macOS and most Linux distros).

## Configuration

| Environment Variable | Description |
|---------------------|-------------|
| `MD2PDF_TOOL_HOME` | Override tool install root (default: `~/.local/share/md2pdf`) |
| `MD2PDF_DEBUG=1` | Keep temporary files on failure for debugging |
| `MMDC_PUPPETEER_CONFIG` | Path to a Puppeteer JSON config file passed to `mmdc -p` when set and existing |

## Testing

The test suite uses [bats-core](https://github.com/bats-core/bats-core).

```bash
# Install bats
brew install bats-core

# Run all tests
make test

# Run a specific test file
bats tests/argument_parsing.bats
```

Unit tests run without any rendering engine installed. Integration tests automatically skip when `pandoc` and `xelatex` are not available.

## Releasing

```bash
make release-tag VERSION=0.2.0
git push origin master && git push origin v0.2.0
```

`release-tag` writes the new version to `VERSION` and to the `MD2PDF_VERSION`
constant in `bin/md2pdf`, commits, and creates an annotated tag. Pushing the tag
triggers `.github/workflows/release.yml`, which computes the release tarball's
sha256 and opens a PR against [`alexg0/homebrew-tap`](https://github.com/alexg0/homebrew-tap)
updating `Formula/md2pdf.rb`.

Prerequisite (one-time): create the `alexg0/homebrew-tap` repo, seed it with
[`packaging/homebrew/md2pdf.rb`](packaging/homebrew/md2pdf.rb), and add a
`HOMEBREW_TAP_TOKEN` secret to this repo (PAT with `contents:write` and
`pull-requests:write` on the tap).

## Author

Alexander Goldstein <alexg@alexland.org>

## License

This project is licensed under the [MIT License](LICENSE).
