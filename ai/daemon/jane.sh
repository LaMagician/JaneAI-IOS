#!/bin/sh
# Deterministic Jane v0.1 terminal: understand -> plan -> permission -> act -> memory.
JANE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$JANE_DIR/lib/permissions.sh"
. "$JANE_DIR/lib/tools.sh"
. "$JANE_DIR/lib/memory.sh"
. "$JANE_DIR/lib/planner.sh"
run_plan() {
    request=$1
    plan=$(plan_request "$request")
    IFS='|' read -r action target argument <<EOF
$plan
EOF
    echo "UNDERSTAND: request=$request"
    echo "PLAN: action=$action target=$target"
    case "$action" in
      help) echo 'Commands: help status remember KEY VALUE recall KEY memory processes read PATH write PATH TEXT launch PROGRAM settings hostname NAME network URL exit';;
      status) echo 'Jane v0.1: deterministic backend; permission boundary active; network denied.';;
      exit) return 10;;
      remember) memory_remember "$target" "$argument"; echo "RESULT: remembered $target";;
      recall) if result=$(memory_recall "$target"); then echo "RESULT: $result"; else echo 'RESULT: no memory for that key'; fi;;
      memory) memory_list;;
      unknown) echo 'RESULT: unknown request (type help)';;
      *) if permission_check "$action" "$target"; then
           echo "PERMISSION: allow $action $target"
           case "$action" in
             read_file) tool_read_file "$target";; write_file) tool_write_file "$target" "$argument";;
             get_processes|processes) tool_get_processes;; launch_program) tool_launch_program "$target";;
             network_request) tool_network_request "$target";; change_setting) tool_change_setting "$action" "$argument";; esac
         else echo "PERMISSION: deny $action $target"; fi;;
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
