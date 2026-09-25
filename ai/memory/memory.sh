#!/bin/sh
JANE_STATE_DIR=${JANE_STATE_DIR:-/jane}
MEMORY_FILE=${JANE_MEMORY_FILE:-$JANE_STATE_DIR/memory/facts.tsv}
memory_prepare() {
    mkdir -p "$(dirname "$MEMORY_FILE")"
    [ -L "$MEMORY_FILE" ] && return 1
    [ -d "$MEMORY_FILE" ] && return 1
    [ -f "$MEMORY_FILE" ] || : > "$MEMORY_FILE"
}
memory_normalize() {
    memory_prepare || return 1
    tmp="$MEMORY_FILE.tmp.$$"
    awk -F '\t' 'index($0,"\t") > 0 && $1 != "" { key=$1; value=substr($0, index($0,"\t")+1); print key "\t" value }' "$MEMORY_FILE" > "$tmp"
    mv -f "$tmp" "$MEMORY_FILE"
}
memory_remember() {
    key=$1
    value=$2
    memory_normalize || return 1
    tmp="$MEMORY_FILE.tmp.$$"
    awk -F '\t' -v key="$key" '$1 != key { print $0 }' "$MEMORY_FILE" > "$tmp"
    printf '%s\t%s\n' "$key" "$value" >> "$tmp"
    mv -f "$tmp" "$MEMORY_FILE"
}
memory_forget() {
    key=$1
    memory_normalize || return 1
    tmp="$MEMORY_FILE.tmp.$$"
    awk -F '\t' -v key="$key" '$1 != key { print $0 }' "$MEMORY_FILE" > "$tmp"
    if cmp -s "$MEMORY_FILE" "$tmp"; then
        rm -f "$tmp"
        return 1
    fi
    mv -f "$tmp" "$MEMORY_FILE"
}
memory_recall() {
    key=$1
    memory_normalize || return 1
    awk -F '\t' -v key="$key" '$1 == key { value=substr($0, index($0,"\t")+1) } END { if (value != "") print value; else exit 1 }' "$MEMORY_FILE"
}
memory_list() {
    memory_normalize || return 1
    cat "$MEMORY_FILE"
}
