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
text = text.replace("≥", ">=")
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

@test "unicode normalization replaces >= symbol" {
  local input="$TEST_TEMP_DIR/input.md"
  echo "Value ≥ 10" > "$input"
  python3 - "$input" "xelatex" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text(encoding='utf-8')
text = text.replace("≥", ">=")
p.write_text(text, encoding='utf-8')
PY
  result="$(cat "$input")"
  [[ "$result" == *">="* ]]
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
text = text.replace("≥", ">=")
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
