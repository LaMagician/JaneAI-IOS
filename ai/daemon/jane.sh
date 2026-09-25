#!/bin/sh
# Deterministic Jane v0.1 terminal: understand -> plan -> permission -> act -> memory.
JANE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$JANE_DIR/lib/permissions.sh"
. "$JANE_DIR/lib/tools.sh"
. "$JANE_DIR/lib/memory.sh"
. "$JANE_DIR/lib/planner.sh"
JANE_AUDIT_FILE=${JANE_AUDIT_FILE:-/jane/memory/audit.log}
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
      help) echo 'Commands: help status remember KEY VALUE recall KEY memory audit processes read PATH write PATH TEXT launch PROGRAM settings hostname NAME network URL exit';;
      status) echo 'Jane v0.1: deterministic backend; permission boundary active; network denied.';;
      exit) return 10;;
      remember) memory_remember "$target" "$argument"; echo "RESULT: remembered $target";;
      recall) if result=$(memory_recall "$target"); then echo "RESULT: $result"; else echo 'RESULT: no memory for that key'; fi;;
      memory) memory_list;;
      audit) [ -f "$JANE_AUDIT_FILE" ] && cat "$JANE_AUDIT_FILE" || echo 'RESULT: no audit events yet';;
      unknown) echo 'RESULT: unknown request (type help)';;
      *)
         decision=$(permission_decide "$action" "$target")
         case "$decision" in
           allow)
             echo "PERMISSION: allow $action $target"
             audit_log "$request" "$action" "$target" allow
             case "$action" in
               read_file) tool_read_file "$target";;
               write_file) tool_write_file "$target" "$argument";;
               get_processes|processes) tool_get_processes;;
               launch_program) tool_launch_program "$target";;
               network_request) tool_network_request "$target";;
               change_setting) tool_change_setting "$target" "$argument";;
             esac
             ;;
           confirm)
             if confirm_action "$action" "$target"; then
               echo "PERMISSION: allow $action $target"
               audit_log "$request" "$action" "$target" confirm_allow
               case "$action" in
                 read_file) tool_read_file "$target";;
                 write_file) tool_write_file "$target" "$argument";;
                 get_processes|processes) tool_get_processes;;
                 launch_program) tool_launch_program "$target";;
                 network_request) tool_network_request "$target";;
                 change_setting) tool_change_setting "$target" "$argument";;
               esac
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
exec sh
