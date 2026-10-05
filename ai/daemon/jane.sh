#!/bin/sh
# Jane terminal: understand -> plan -> permission -> act -> memory.
JANE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$JANE_DIR/lib/permissions.sh"
. "$JANE_DIR/lib/tools.sh"
. "$JANE_DIR/lib/audit.sh"
. "$JANE_DIR/lib/identity.sh"
. "$JANE_DIR/lib/backend.sh"
. "$JANE_DIR/lib/memory.sh"
. "$JANE_DIR/lib/planner.sh"
. "$JANE_DIR/lib/skills.sh"
. "$JANE_DIR/lib/profile.sh"

execute_action() {
  action=$1; target=$2; argument=$3
  audit_event permission "$action" "$target" allow ''
  echo "PERMISSION: allow $action $target"
  result=''
  action_status=0
  case "$action" in
    read_file) result=$(tool_read_file "$target") || action_status=$?;;
    write_file) result=$(tool_write_file "$target" "$argument") || action_status=$?;;
    get_processes|processes) result=$(tool_get_processes) || action_status=$?;;
    get_system_information) result=$(tool_system_information) || action_status=$?;;
    list_files) result=$(tool_list_files "$target") || action_status=$?;;
    search_files) result=$(tool_search_files "$target" "$argument") || action_status=$?;;
    launch_program) result=$(tool_launch_program "$target") || action_status=$?;;
    network_request) result=$(tool_network_request "$target") || action_status=$?;;
    change_setting) result=$(tool_change_setting "$action" "$argument") || action_status=$?;;
  esac
  if [ "$action_status" -eq 0 ] && [ "$action" = write_file ]; then
    [ "$(cat "$target" 2>/dev/null)" = "$argument" ] || action_status=1
    audit_event verify "$action" "$target" "$([ "$action_status" -eq 0 ] && echo passed || echo failed)" ''
  fi
  [ -n "$result" ] && printf '%s\n' "$result"
  if [ "$action_status" -eq 0 ]; then
    audit_event tool "$action" "$target" complete success
  else
    audit_event tool "$action" "$target" failed "$action_status"
  fi
  return "$action_status"
}

snapshot_sequence_step() {
  step=$1
  plan=$(plan_request "$step")
  IFS='|' read -r step_action step_target step_argument <<EOF
$plan
EOF
  [ "$step_action" = write_file ] || return 0
  backup_name=$(printf '%s' "$step_target" | tr '/ ' '__')
  if [ -e "$step_target" ]; then
    cp "$step_target" "$JANE_ROLLBACK_DIR/$backup_name"
    printf '%s\told\t%s\n' "$step_target" "$backup_name" >> "$JANE_ROLLBACK_DIR/manifest"
  else
    printf '%s\tnew\t%s\n' "$step_target" "$backup_name" >> "$JANE_ROLLBACK_DIR/manifest"
  fi
}

rollback_sequence() {
  [ -f "$JANE_ROLLBACK_DIR/manifest" ] || return 0
  while IFS="$(printf '\t')" read -r rollback_target rollback_kind backup_name; do
    if [ "$rollback_kind" = old ]; then
      cp "$JANE_ROLLBACK_DIR/$backup_name" "$rollback_target"
    else
      rm -f "$rollback_target"
    fi
    audit_event rollback write_file "$rollback_target" restored "$rollback_kind"
  done < "$JANE_ROLLBACK_DIR/manifest"
}

run_plan() {
  request=$1
  if [ -n "${PENDING_ACTION:-}" ]; then
    case "$request" in
      confirm)
        action=$PENDING_ACTION; target=$PENDING_TARGET; argument=$PENDING_ARGUMENT
        unset PENDING_ACTION PENDING_TARGET PENDING_ARGUMENT
        execute_action "$action" "$target" "$argument"
        return 0
        ;;
      deny)
        audit_event permission "$PENDING_ACTION" "$PENDING_TARGET" deny user
        echo "PERMISSION: denied $PENDING_ACTION $PENDING_TARGET"
        unset PENDING_ACTION PENDING_TARGET PENDING_ARGUMENT
        return 0
        ;;
      *)
        echo 'CONFIRM: pending action; type confirm or deny'
        return 0
        ;;
    esac
  fi
  audit_event request "$request" '' received ''
  if [ "${request#answer }" != "$request" ]; then
    identity_answer "${request#answer }"
    audit_event identity answer '' accepted success
    return 0
  fi

  plan=$(plan_request "$request")
  IFS='|' read -r action target argument <<EOF
$plan
EOF
  audit_event plan "$action" "$target" generated "$plan"
  action_status=0
  echo "UNDERSTAND: request=$request"
  echo "PLAN: action=$action target=$target"
  case "$action" in
    help)
            echo 'Commands: help status hardware identity answer TEXT remember KEY VALUE recall KEY find TEXT context compact memory skills [QUERY] system info processes list PATH search PATH PATTERN sequence COMMAND && COMMAND read PATH write PATH launch PROGRAM settings hostname NAME network URL exit'
      ;;
    status)
      echo "Jane v0.1: backend=$(backend_name); model=${JANE_MODEL_PROFILE:-unknown}; resource=${JANE_RESOURCE_PROFILE:-unknown}; context=${JANE_CONTEXT_TOKENS:-unknown}; voice=${JANE_VOICE_MODE:-unknown}; permission boundary active; audit enabled; network denied."
      ;;
    identity)
      identity_intro
      identity_onboarding_complete && echo 'Identity context is established.'
      ;;
    skills)
      skills_list
      ;;
    skill_search)
      if [ -n "$argument" ]; then skills_find "$argument" || echo 'RESULT: no matching skill'; else skills_list; fi
      ;;
    hardware)
      hardware_summary
      ;;
    sequence)
      sequence_file=/tmp/jane-plan.$$
      JANE_ROLLBACK_DIR=/tmp/jane-rollback.$$
      mkdir -p "$JANE_ROLLBACK_DIR"
      plan_sequence "$argument" > "$sequence_file"
      sequence_count=0
      sequence_failed=0
      while IFS= read -r sequence_step; do
        sequence_count=$((sequence_count + 1))
        if [ "$sequence_count" -gt 8 ]; then
          echo 'RESULT: plan rejected (maximum 8 steps)'
          audit_event sequence "$request" '' rejected max_steps
          sequence_failed=1
          break
        fi
        snapshot_sequence_step "$sequence_step"
        attempts=0
        step_status=1
        while [ "$attempts" -le "${JANE_SEQUENCE_RETRIES:-1}" ]; do
          attempts=$((attempts + 1))
          audit_event checkpoint "$sequence_step" "$sequence_count" attempt "$attempts"
          run_plan "$sequence_step"
          step_status=$?
          [ -n "${PENDING_ACTION:-}" ] && break
          [ "$step_status" -eq 0 ] && break
        done
        if [ "$step_status" -ne 0 ] || [ -n "${PENDING_ACTION:-}" ]; then
          audit_event sequence "$sequence_step" "$sequence_count" failed "$step_status"
          sequence_failed=1
          break
        fi
      done < "$sequence_file"
      rm -f "$sequence_file"
      if [ "$sequence_failed" -eq 0 ]; then
        audit_event sequence "$request" '' complete success
        action_status=0
      else
        rollback_sequence
        audit_event sequence "$request" '' rolled_back failure
        action_status=1
      fi
      rm -rf "$JANE_ROLLBACK_DIR"
      ;;
    exit)
      return 10
      ;;
    remember)
      memory_remember "$target" "$argument"
      echo "RESULT: remembered $target"
      ;;
    recall)
      if result=$(memory_recall "$target"); then
        echo "RESULT: $result"
      else
        echo 'RESULT: no memory for that key'
      fi
      ;;
    memory)
      memory_list
      ;;
    context)
      memory_context
      ;;
    memory_search)
      if memory_search "$argument"; then :; else echo 'RESULT: no matching memory'; fi
      ;;
    memory_compact)
      memory_compact
      echo 'RESULT: memory compacted'
      ;;
    unknown)
      if response=$(backend_respond "$request"); then
        echo "RESPONSE: $response"
      else
        echo 'RESULT: unknown request (type help)'
      fi
      ;;
    *)
      decision=$(permission_decision "$action" "$target")
      case "$decision" in
        allow)
          execute_action "$action" "$target" "$argument"
          action_status=$?
          ;;
        confirm)
          PENDING_ACTION=$action
          PENDING_TARGET=$target
          PENDING_ARGUMENT=$argument
          audit_event permission "$action" "$target" confirm pending
          echo "CONFIRM: $action $target requires approval; type confirm or deny"
          ;;
        *)
          audit_event permission "$action" "$target" deny blocked
          echo "PERMISSION: deny $action $target"
          action_status=1
          ;;
      esac
      ;;
  esac
  memory_remember last_request "$request"
  memory_context_add "$request"
  return "$action_status"
}

identity_initialize
hardware_detect
hardware_apply_pressure_policy
echo 'Jane terminal ready. Type help.'
identity_intro
while :; do
  printf 'jane> '
  IFS= read -r request || break
  run_plan "$request"
  rc=$?
  [ "$rc" -eq 10 ] && break
done
echo 'Jane stopped. Starting recovery shell.'
exec sh
