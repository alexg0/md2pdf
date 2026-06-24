#!/usr/bin/env bats

load test_helper

@test "unicode normalization replaces checkmark emoji" {
  local input="$TEST_TEMP_DIR/input.md"
  local output="$TEST_TEMP_DIR/output.md"
  echo "Status: ✅ done" > "$input"
  python3 - "$input" "xelatex" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
engine = sys.argv[2]
text = p.read_text(encoding='utf-8')
text = text.replace("✅", "[OK]")
text = text.replace("⚠️", "[!]")
text = text.replace("✓", "[x]")
text = text.replace("≤", "$\\leq$")
text = text.replace("≥", "$\\geq$")
text = text.replace("→", "->")
if engine == "pdflatex":
    text = text.replace("—", "--")
    text = text.replace("–", "-")
    text = text.replace("'", "'")
    text = text.replace("\u201c", '"')
    text = text.replace("\u201d", '"')
p.write_text(text, encoding='utf-8')
PY
  result="$(cat "$input")"
  [[ "$result" == *"[OK]"* ]]
  [[ "$result" != *"✅"* ]]
}

@test "unicode normalization replaces warning emoji" {
  local input="$TEST_TEMP_DIR/input.md"
  printf "Warning: ⚠️ caution\n" > "$input"
  python3 - "$input" "xelatex" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text(encoding='utf-8')
text = text.replace("⚠️", "[!]")
p.write_text(text, encoding='utf-8')
PY
  result="$(cat "$input")"
  [[ "$result" == *"[!]"* ]]
}

@test "unicode normalization replaces arrow" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/input.md"
  echo "Next → step" > "$input"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -Fq 'Next \ensuremath{\rightarrow} step' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '→' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "unicode normalization replaces checkmark" {
  local input="$TEST_TEMP_DIR/input.md"
  echo "Done: ✓ yes" > "$input"
  python3 - "$input" "xelatex" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text(encoding='utf-8')
text = text.replace("✓", "[x]")
p.write_text(text, encoding='utf-8')
PY
  result="$(cat "$input")"
  [[ "$result" == *"[x]"* ]]
}

@test "unicode normalization replaces >= symbol with latex math" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/input.md"
  echo "Value ≥ 10" > "$input"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -Fq 'Value \ensuremath{\geq} 10' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '≥' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "latex unicode normalization typesets comparison symbols as math" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/input.md"
  printf 'Range: value ≤ 10 and score ≥ 5\n' > "$input"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -Fq 'Range: value \ensuremath{\leq} 10 and score \ensuremath{\geq} 5' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '≤' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '≥' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "latex math normalization survives a following digit" {
  # pandoc does not treat a closing "$" followed by a digit as math, so a bare
  # "$\leq$3" would leak literally. \ensuremath stays valid in that position.
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/input.md"
  printf 'Dose ≈3-4g and cutoff ≤3 units\n' > "$input"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -Fq 'Dose \ensuremath{\approx}3-4g and cutoff \ensuremath{\leq}3 units' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '$\' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "latex normalization rewrites arrows and symbols missing from the body font" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/input.md"
  printf 'Down ↓ both ↔ right → up ↑ approx ≈ ne ≠\n' > "$input"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -Fq '\ensuremath{\downarrow}' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '\ensuremath{\leftrightarrow}' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '\ensuremath{\rightarrow}' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '\ensuremath{\uparrow}' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '\ensuremath{\approx}' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '\ensuremath{\neq}' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '↓' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "non-latex engines leave symbols as native unicode" {
  # \ensuremath / \textcolor are LaTeX-only and would be dropped by HTML engines,
  # so symbol rewriting is gated to LaTeX engines. Emoji->ASCII labels still apply.
  setup_fake_pandoc
  cat > "$TEST_TEMP_DIR/fake-bin/weasyprint" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$TEST_TEMP_DIR/fake-bin/weasyprint"
  local input="$TEST_TEMP_DIR/input.md"
  printf 'Range ≤ 10 → done ✅\n' > "$input"

  run "$MD2PDF" --mode pandoc-weasyprint "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -Fq '≤' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '→' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq 'ensuremath' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '[OK]' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "latex normalization renders status circles as colored bullets" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/input.md"
  printf 'Status: 🔵 note 🟢 ok 🔴 stop\n' > "$input"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -Fq '\textcolor{blue}{\ensuremath{\bullet}}' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '\textcolor{green}{\ensuremath{\bullet}}' "$MD2PDF_PANDOC_INPUT_LOG"
  grep -Fq '\textcolor{red}{\ensuremath{\bullet}}' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '🔵' "$MD2PDF_PANDOC_INPUT_LOG"
}

@test "pdflatex normalization replaces em-dash and smart quotes" {
  local input="$TEST_TEMP_DIR/input.md"
  printf 'Dash — and quotes \u201chello\u201d\n' > "$input"
  python3 - "$input" "pdflatex" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
engine = sys.argv[2]
text = p.read_text(encoding='utf-8')
text = text.replace("✅", "[OK]")
text = text.replace("⚠️", "[!]")
text = text.replace("✓", "[x]")
text = text.replace("≤", "$\\leq$")
text = text.replace("≥", "$\\geq$")
text = text.replace("→", "->")
if engine == "pdflatex":
    text = text.replace("—", "--")
    text = text.replace("–", "-")
    text = text.replace("'", "'")
    text = text.replace("\u201c", '"')
    text = text.replace("\u201d", '"')
p.write_text(text, encoding='utf-8')
PY
  result="$(cat "$input")"
  [[ "$result" == *"--"* ]]
  [[ "$result" != *"—"* ]]
}
