#!/bin/sh
# Deterministic Jane v0.1 terminal: understand -> plan -> permission -> act -> memory.
JANE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$JANE_DIR/lib/permissions.sh"
. "$JANE_DIR/lib/tools.sh"
. "$JANE_DIR/lib/memory.sh"
. "$JANE_DIR/lib/planner.sh"
JANE_STATE_DIR=${JANE_STATE_DIR:-/jane}
JANE_AUDIT_FILE=${JANE_AUDIT_FILE:-$JANE_STATE_DIR/memory/audit.log}
audit_log() {
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'unknown')
    mkdir -p "$(dirname "$JANE_AUDIT_FILE")"
    printf '%s\t%s\t%s\t%s\t%s\n' "$timestamp" "$1" "$2" "$3" "$4" >> "$JANE_AUDIT_FILE"
}
confirm_action() {
    printf 'CONFIRM: allow %s %s ? [y/N] ' "$1" "$2"
    IFS= read -r answer || return 1
    case "$answer" in y|Y|yes|YES) return 0;; *) return 1;; esac
}
emit_response() {
    output=$1
    if [ -z "$output" ]; then
        echo 'RESULT: ok'
        return
    fi
    case "$output" in
        *'
'*)
            echo 'RESULT:'
            printf '%s\n' "$output"
            ;;
        *)
            echo "RESULT: $output"
            ;;
    esac
}
execute_action() {
    action=$1
    target=$2
    argument=$3
    request=$4
    case "$action" in
      read_file) output=$(tool_read_file "$target" 2>&1); rc=$?;;
      write_file) output=$(tool_write_file "$target" "$argument" 2>&1); rc=$?;;
      get_processes|processes) output=$(tool_get_processes 2>&1); rc=$?;;
      launch_program) output=$(tool_launch_program "$target" 2>&1); rc=$?;;
      network_request) output=$(tool_network_request "$target" 2>&1); rc=$?;;
      change_setting) output=$(tool_change_setting "$target" "$argument" 2>&1); rc=$?;;
      *) output='unsupported action'; rc=1;;
    esac
    if [ "$rc" -eq 0 ]; then
        emit_response "$output"
        audit_log "$request" "$action" "$target" execute_success
        return 0
    fi
    echo "ERROR: action failed for $action $target"
    [ -n "$output" ] && printf '%s\n' "$output"
    audit_log "$request" "$action" "$target" execute_failure
    return 1
}
run_plan() {
    request=$1
    plan=$(plan_request "$request")
    IFS='|' read -r action target argument <<EOF
$plan
EOF
    echo "UNDERSTAND: request=$request"
    echo "PLAN: action=$action target=$target"
    audit_log "$request" "$action" "$target" plan
    case "$action" in
      help) echo 'Commands: help status remember KEY VALUE recall KEY forget KEY memory audit processes read PATH write PATH TEXT launch PROGRAM settings hostname NAME network URL exit';;
      status) echo "Jane v0.1: deterministic backend; permission boundary active; state_dir=$JANE_STATE_DIR";;
      exit) return 10;;
      remember) if memory_remember "$target" "$argument"; then echo "RESULT: remembered $target"; else echo "ERROR: failed to remember $target"; fi;;
      recall) if result=$(memory_recall "$target"); then echo "RESULT: $result"; else echo 'RESULT: no memory for that key'; fi;;
      forget) if memory_forget "$target"; then echo "RESULT: forgot $target"; else echo 'RESULT: no memory for that key'; fi;;
      memory) if output=$(memory_list 2>&1); then emit_response "$output"; else echo "ERROR: unable to read memory"; printf '%s\n' "$output"; fi;;
      audit) [ -f "$JANE_AUDIT_FILE" ] && cat "$JANE_AUDIT_FILE" || echo 'RESULT: no audit events yet';;
      unknown) echo 'RESULT: unknown request (type help)';;
      *)
         decision=$(permission_decide "$action" "$target")
         case "$decision" in
           allow)
             echo "PERMISSION: allow $action $target"
             audit_log "$request" "$action" "$target" allow
             execute_action "$action" "$target" "$argument" "$request" || true
             ;;
           confirm)
             if confirm_action "$action" "$target"; then
               echo "PERMISSION: allow $action $target"
               audit_log "$request" "$action" "$target" confirm_allow
               execute_action "$action" "$target" "$argument" "$request" || true
             else
               echo "PERMISSION: denied by user for $action $target"
               audit_log "$request" "$action" "$target" confirm_deny
             fi
             ;;
           *)
             echo "PERMISSION: deny $action $target"
             audit_log "$request" "$action" "$target" deny
             ;;
         esac
         ;;
    esac
    memory_remember last_request "$request"
}
echo 'Jane terminal ready. Type help.'
while :; do
  printf 'jane> '
  IFS= read -r request || break
  run_plan "$request"; rc=$?
  [ "$rc" -eq 10 ] && break
done
echo 'Jane stopped. Starting recovery shell.'
if [ -t 0 ]; then
  exec sh
fi
