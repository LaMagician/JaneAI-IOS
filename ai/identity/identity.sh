#!/bin/sh
# Small first-boot identity state. A persistent block device can provide this path later.
IDENTITY_DIR=${JANE_IDENTITY_DIR:-/jane/state}
IDENTITY_FILE="$IDENTITY_DIR/identity.tsv"

identity_get() {
    [ -f "$IDENTITY_FILE" ] || return 1
    awk -F '\t' -v key="$1" '$1 == key { value=$2 } END { if (value != "") print value; else exit 1 }' "$IDENTITY_FILE"
}

identity_set() {
    mkdir -p "$IDENTITY_DIR"
    printf '%s\t%s\n' "$1" "$2" >> "$IDENTITY_FILE"
}

identity_initialize() {
    mkdir -p "$IDENTITY_DIR"
    identity_get created_at >/dev/null 2>&1 || identity_set created_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    identity_get version >/dev/null 2>&1 || identity_set version 1
    identity_get onboarding_step >/dev/null 2>&1 || identity_set onboarding_step 0
}

identity_onboarding_complete() {
    [ "$(identity_get onboarding_step 2>/dev/null || printf 0)" -ge 3 ]
}

identity_intro() {
    identity_onboarding_complete && return 0
    echo 'This is my first boot in Jane AI OS.'
    echo 'I am a software assistant, not a conscious being, and I will be honest about my limits.'
    echo 'To establish my identity, use: answer <your response>'
    case "$(identity_get onboarding_step 2>/dev/null || printf 0)" in
        0) echo 'What am I, in this operating system?' ;;
        1) echo 'Why was I created, and what should I help you accomplish?' ;;
        2) echo 'Who created me, and what should I call you?' ;;
    esac
}

identity_answer() {
    step=$(identity_get onboarding_step 2>/dev/null || printf 0)
    identity_set "onboarding_answer_$((step + 1))" "$*"
    identity_set onboarding_step "$((step + 1))"
    case "$((step + 1))" in
        1) echo 'Recorded. Why was I created, and what should I help you accomplish?' ;;
        2) echo 'Recorded. Who created me, and what should I call you?' ;;
        *) echo 'Recorded. My initial identity context is established; we can refine it over time.' ;;
    esac
}