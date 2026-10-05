#!/bin/sh
# Append-only, tab-separated audit events for requests and tool decisions.
AUDIT_FILE=${JANE_AUDIT_FILE:-/jane/audit/events.log}

audit_clean() {
    printf '%s' "$1" | tr '\t\r\n' '   '
}

audit_event() {
    mkdir -p "$(dirname "$AUDIT_FILE")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        "$(audit_clean "$1")" "$(audit_clean "$2")" "$(audit_clean "$3")" \
        "$(audit_clean "$4")" "$(audit_clean "$5")" >> "$AUDIT_FILE"
}