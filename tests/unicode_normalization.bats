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
  export MD2PDF_PANDOC_INPUT_LOG="$TEST_TEMP_DIR/pandoc-input.md"
}

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
  local input="$TEST_TEMP_DIR/input.md"
  echo "Next → step" > "$input"
  python3 - "$input" "xelatex" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text(encoding='utf-8')
text = text.replace("→", "->")
p.write_text(text, encoding='utf-8')
PY
  result="$(cat "$input")"
  [[ "$result" == *"->"* ]]
  [[ "$result" != *"→"* ]]
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
  local input="$TEST_TEMP_DIR/input.md"
  echo "Value ≥ 10" > "$input"
  python3 - "$input" "xelatex" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text(encoding='utf-8')
text = text.replace("≥", "$\\geq$")
p.write_text(text, encoding='utf-8')
PY
  result="$(cat "$input")"
  [[ "$result" == *"\$\\geq\$"* ]]
}

@test "latex unicode normalization typesets comparison symbols as math" {
  setup_fake_pandoc
  local input="$TEST_TEMP_DIR/input.md"
  printf 'Range: value ≤ 10 and score ≥ 5\n' > "$input"

  run "$MD2PDF" "$input" "$TEST_TEMP_DIR/out.pdf"

  [ "$status" -eq 0 ]
  grep -Fq 'Range: value $\leq$ 10 and score $\geq$ 5' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '≤' "$MD2PDF_PANDOC_INPUT_LOG"
  ! grep -Fq '≥' "$MD2PDF_PANDOC_INPUT_LOG"
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
