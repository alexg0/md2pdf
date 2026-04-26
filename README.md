# md2pdf

Multi-engine Markdown to PDF converter. Supports 10 rendering backends with a unified CLI interface.

## Features

- **10 rendering backends** with automatic fallback and dependency management
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

## Installation

```bash
git clone <repo-url> ~/work/dev/md2pdf
cd ~/work/dev/md2pdf
make install
```

This creates a symlink at `/usr/local/bin/md2pdf`. To install elsewhere:

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

### macOS quick start (default mode)

```bash
brew install pandoc
brew install --cask basictex
brew install --cask font-noto-serif
```

## Usage

```
Usage: md2pdf [options] input.md [input2.md ...] [output.pdf | -o output.pdf]

Common options:
  --mode MODE         Renderer mode (default: pandoc-xelatex)
  -t TITLE            PDF title (default: first # H1 from file, or filename)
  -a AUTHOR           Author line (default: none)
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

Pandoc modes also honor YAML frontmatter for table-of-contents and section
numbering control:

```yaml
---
toc: false
numbersections: false
---
```

`number_sections:` is accepted by `md2pdf` and normalized to pandoc's
`numbersections:` metadata key before rendering.

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

## Author

Alexander Goldstein <alexg@alexland.org>

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
