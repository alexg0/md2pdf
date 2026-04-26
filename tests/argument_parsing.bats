#!/usr/bin/env bats

load test_helper

@test "help flag exits 0" {
  run "$MD2PDF" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "short help flag exits 0" {
  run "$MD2PDF" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "unknown option fails" {
  run "$MD2PDF" --bogus-option
  [ "$status" -ne 0 ]
}

@test "--mode requires a value" {
  run "$MD2PDF" --mode
  [ "$status" -ne 0 ]
}

@test "-t requires a value" {
  run "$MD2PDF" -t
  [ "$status" -ne 0 ]
}

@test "-a requires a value" {
  run "$MD2PDF" -a
  [ "$status" -ne 0 ]
}

@test "--font requires a value" {
  run "$MD2PDF" --font
  [ "$status" -ne 0 ]
}

@test "-m requires a value" {
  run "$MD2PDF" -m
  [ "$status" -ne 0 ]
}

@test "-s requires a value" {
  run "$MD2PDF" -s
  [ "$status" -ne 0 ]
}

@test "multiple inputs without -o or trailing .pdf fail" {
  run "$MD2PDF" input.md another.md
  [ "$status" -ne 0 ]
  [[ "$output" == *"specify output with -o"* ]]
}

@test "-o requires a value" {
  run "$MD2PDF" -o
  [ "$status" -ne 0 ]
}

@test "unknown mode fails" {
  run "$MD2PDF" --mode nonexistent --mode-help
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown mode"* ]]
}

@test "--mode=value equals syntax works" {
  run "$MD2PDF" --mode=pandoc-lualatex --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"LuaLaTeX"* ]]
}

@test "latex alias resolves to pandoc-xelatex" {
  run "$MD2PDF" --mode latex --mode-help
  [ "$status" -eq 0 ]
  [[ "$output" == *"XeLaTeX"* ]]
}
