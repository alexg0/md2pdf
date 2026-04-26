# Reference Homebrew formula for alexg0/homebrew-tap.
#
# Drop this file into alexg0/homebrew-tap as Formula/md2pdf.rb to seed the tap.
# After the initial seed, .github/workflows/release.yml in alexg0/md2pdf will
# open PRs that bump url, sha256, and version on each tag push.
class Md2pdf < Formula
  desc     "Multi-engine Markdown to PDF converter"
  homepage "https://github.com/alexg0/md2pdf"
  url      "https://github.com/alexg0/md2pdf/archive/refs/tags/v0.1.0.tar.gz"
  sha256   "0000000000000000000000000000000000000000000000000000000000000000"
  version  "0.1.0"
  license  "GPL-3.0-or-later"

  depends_on "pandoc" => :recommended
  depends_on "ruby"

  def install
    bin.install "bin/md2pdf"
  end

  def caveats
    <<~EOS
      The default rendering mode (pandoc-xelatex) needs a TeX distribution and a
      body font. On macOS, the lightweight setup is:

        brew install --cask basictex
        brew install --cask font-noto-serif

      Other rendering backends (md-to-pdf, weasyprint, go-md2pdf, etc.) can be
      installed on demand with:

        md2pdf --mode <mode> --install-deps
        md2pdf --install-deps-all
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/md2pdf --version")
    assert_match "Usage:", shell_output("#{bin}/md2pdf --help")
  end
end
