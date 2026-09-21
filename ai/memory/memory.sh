#!/bin/sh
MEMORY_FILE=${JANE_MEMORY_FILE:-/jane/memory/facts.tsv}
memory_remember() { mkdir -p "$(dirname "$MEMORY_FILE")"; printf '%s\t%s\n' "$1" "$2" >> "$MEMORY_FILE"; }
memory_recall() { [ -f "$MEMORY_FILE" ] && awk -F '\t' -v key="$1" '$1 == key { value=$2 } END { if (value != "") print value; else exit 1 }' "$MEMORY_FILE"; }
memory_list() { [ -f "$MEMORY_FILE" ] && cat "$MEMORY_FILE" || true; }
