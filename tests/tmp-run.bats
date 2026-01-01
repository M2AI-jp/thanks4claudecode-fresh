#!/usr/bin/env bats
#
# tests/tmp-run.bats - Integration tests for tmp/run.sh pipeline
#

setup() {
    SCRIPT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    RUN_SH="$SCRIPT_DIR/tmp/run.sh"
}

@test "run.sh exists and is executable" {
    [ -f "$RUN_SH" ]
    [ -x "$RUN_SH" ]
}

@test "run.sh with valid JSON input produces JSON output" {
    result=$(bash "$RUN_SH" '{"input":"test"}' 2>/dev/null)
    echo "$result" | jq . > /dev/null 2>&1
}

@test "run.sh output contains processed_by: typescript" {
    result=$(bash "$RUN_SH" '{"input":"hello"}' 2>/dev/null)
    echo "$result" | jq -e '.processed_by == "typescript"'
}

@test "run.sh output contains python_output with step 1" {
    result=$(bash "$RUN_SH" '{"input":"hello"}' 2>/dev/null)
    echo "$result" | jq -e '.python_output.added_fields.step == 1'
}

@test "run.sh output contains reversed_input" {
    result=$(bash "$RUN_SH" '{"input":"hello"}' 2>/dev/null)
    echo "$result" | jq -e '.added_fields.reversed_input == "olleh"'
}

@test "run.sh output contains input_length" {
    result=$(bash "$RUN_SH" '{"input":"hello"}' 2>/dev/null)
    echo "$result" | jq -e '.added_fields.input_length == 5'
}

@test "run.sh stderr shows pipeline steps" {
    stderr=$(bash "$RUN_SH" '{"input":"test"}' 2>&1 >/dev/null)
    [[ "$stderr" == *"[Step 1]"* ]]
    [[ "$stderr" == *"[Step 2]"* ]]
}

@test "run.sh uppercase transformation works" {
    result=$(bash "$RUN_SH" '{"input":"hello"}' 2>/dev/null)
    echo "$result" | jq -e '.python_output.added_fields.uppercase_input == "HELLO"'
}
