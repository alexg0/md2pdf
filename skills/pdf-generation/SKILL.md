---
name: pdf-generation
description: Generate polished PDF files from one or more Markdown sources by calling the md2pdf CLI, including renderer selection, YAML document options, Mermaid diagrams, dependency checks, and visual verification. Use when the user asks to create, build, rebuild, or troubleshoot a Markdown-to-PDF output with md2pdf; use a general PDF workflow instead for reading, editing, or filling an existing PDF.
---

# PDF generation with md2pdf

Generate PDFs only through the `md2pdf` CLI. Do not invoke Pandoc, LaTeX,
WeasyPrint, Puppeteer, or another renderer directly; let `md2pdf` select and
configure its backend.

## Workflow

1. Inspect the Markdown sources, frontmatter, embedded images, Mermaid blocks,
   and requested output path.
2. Confirm `md2pdf` and a suitable PDF renderer are available:

   ```bash
   command -v md2pdf
   md2pdf --version
   md2pdf --list-modes
   md2pdf --mode pandoc-xelatex --check-deps
   ```

3. Choose an installed PDF mode. Prefer `pandoc-xelatex` unless the user or
   project specifies another mode. Do not select the `pandoc-docx`, `docx`, or
   `word` modes in this skill.
4. Generate the PDF with an explicit output path.
5. Render and inspect every final page. Correct the Markdown, frontmatter, or
   `md2pdf` options and rebuild until the output is clean.

## Generate PDFs

Single source:

```bash
md2pdf report.md -o output/report.pdf
```

Multiple sources combined into one PDF:

```bash
md2pdf intro.md chapter1.md appendix.md -o output/book.pdf
```

Alternative renderer:

```bash
md2pdf --mode pandoc-lualatex report.md -o output/report.pdf
```

For multiple inputs, require an explicit output path. `md2pdf` concatenates the
files, uses frontmatter from the first input, strips later frontmatter blocks,
and includes every input directory in the resource path so relative images can
resolve.

Use `md2pdf --mode-help` before selecting an unfamiliar mode. Use
`--check-deps` during normal work. Treat `--install-deps` as a package
installation action and run it only with user authorization.

## Document options

Put document-specific options in the first Markdown source:

```yaml
---
title: Custom report title
author: Author name
date: 2026-08-08
margin: 0.75in
fontsize: 11pt
font: Noto Serif
toc: true
numbersections: true
page_numbers: true
prevent_widows: true
---
```

CLI flags override frontmatter, which overrides built-in defaults. Avoid CLI
formatting overrides unless the user wants them to apply to the entire output.
Use `--no-author` when the PDF must not inherit author metadata.

For Obsidian sources, pass `--obsidian` to suppress warnings for recognized
Obsidian metadata while retaining warnings for unexpected keys. Do not suppress
all unknown-frontmatter warnings unless the user asks.

## Mermaid diagrams

Keep diagrams as fenced `mermaid` blocks. `md2pdf` renders them through `mmdc`
and caches the images by content hash. If Mermaid is present and `mmdc` is
missing, report the dependency and request installation approval. Do not use
`--no-mermaid` merely to make a failing build pass.

## Verify the output

For each generated PDF:

1. Confirm it exists, is non-empty, and has the expected page count:

   ```bash
   pdfinfo output/report.pdf
   ```

2. Render every page to a temporary directory:

   ```bash
   mkdir -p tmp/pdfs/report
   pdftoppm -png output/report.pdf tmp/pdfs/report/page
   ```

3. Inspect the rendered pages with the available image-viewing capability.
   Check typography, margins, page breaks, tables, diagrams, images, links,
   headers, footers, numbering, and glyph rendering.
4. Optionally use `pdftotext` as a content sanity check, but never treat text
   extraction as evidence of layout correctness.
5. Fix defects in the source or `md2pdf` options, then regenerate and inspect
   again after every meaningful change.
6. Remove temporary page images after validation. Report the final PDF path,
   page count, file size, renderer mode, and any remaining limitations.

Do not deliver a PDF with clipped or overlapping text, broken tables, missing
images, unreadable glyphs, unrendered Mermaid fences, or placeholder content.
