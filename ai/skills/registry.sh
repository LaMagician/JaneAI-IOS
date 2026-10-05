#!/bin/sh
SKILLS_FILE=${JANE_SKILLS_FILE:-/jane/skills/registry.tsv}

skills_list() {
    [ -f "$SKILLS_FILE" ] || return 0
    awk -F '\t' '!/^#/ && NF >= 4 { printf "%s v%s: %s [%s]\n", $1, $2, $3, $4 }' "$SKILLS_FILE"
}

skills_find() {
    query=$1
    [ -f "$SKILLS_FILE" ] || return 1
    awk -F '\t' -v query="$query" 'BEGIN { query=tolower(query) } !/^#/ && index(tolower($0), query) { printf "%s v%s: %s [%s]\n", $1, $2, $3, $4; found=1 } END { exit(found ? 0 : 1) }' "$SKILLS_FILE"
}