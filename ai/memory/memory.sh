#!/bin/sh
MEMORY_FILE=${JANE_MEMORY_FILE:-/jane/memory/facts.tsv}
CONTEXT_FILE=${JANE_CONTEXT_FILE:-$(dirname "$MEMORY_FILE")/recent.log}
MEMORY_MAX_ENTRY_BYTES=${JANE_MEMORY_MAX_ENTRY_BYTES:-4096}
memory_remember() {
	key=$1; value=$2
	case "$key" in ''|*"$(printf '\t')"*) return 1;; esac
	value=$(printf '%s' "$value" | tr '\t\r\n' '   ')
	[ "$(printf '%s\t%s' "$key" "$value" | wc -c)" -le "$MEMORY_MAX_ENTRY_BYTES" ] || return 1
	umask 077
	mkdir -p "$(dirname "$MEMORY_FILE")"
	printf '%s\t%s\n' "$key" "$value" >> "$MEMORY_FILE"
}
memory_recall() { [ -f "$MEMORY_FILE" ] && awk -F '\t' -v key="$1" '$1 == key { value=$2 } END { if (value != "") print value; else exit 1 }' "$MEMORY_FILE"; }
memory_search() {
	query=$1
	[ -f "$MEMORY_FILE" ] || return 1
	awk -F '\t' -v query="$query" 'BEGIN { query=tolower(query) } index(tolower($0), query) { print; found=1; count++; if (count >= 8) exit } END { exit(found ? 0 : 1) }' "$MEMORY_FILE"
}
memory_compact() {
	[ -f "$MEMORY_FILE" ] || return 0
	compact_file="$MEMORY_FILE.compact.$$"
	awk -F '\t' '!seen[$1]++ { values[$1]=$0 } { latest[$1]=$0 } END { for (key in latest) print latest[key] }' "$MEMORY_FILE" | LC_ALL=C sort > "$compact_file"
	chmod 0600 "$compact_file"
	mv "$compact_file" "$MEMORY_FILE"
}
memory_context_add() {
	mkdir -p "$(dirname "$CONTEXT_FILE")"
	printf '%s\n' "$1" >> "$CONTEXT_FILE"
	tail -n 8 "$CONTEXT_FILE" > "$CONTEXT_FILE.tmp.$$"
	mv "$CONTEXT_FILE.tmp.$$" "$CONTEXT_FILE"
	chmod 0600 "$CONTEXT_FILE"
}
memory_context() { [ -f "$CONTEXT_FILE" ] && cat "$CONTEXT_FILE" || true; }
memory_list() { [ -f "$MEMORY_FILE" ] && cat "$MEMORY_FILE" || true; }
