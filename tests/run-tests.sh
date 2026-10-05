#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }
. "$REPO_ROOT/ai/permissions/permissions.sh"
. "$REPO_ROOT/ai/planner/planner.sh"
. "$REPO_ROOT/ai/audit/audit.sh"
. "$REPO_ROOT/ai/identity/identity.sh"
. "$REPO_ROOT/ai/backend/backend.sh"
. "$REPO_ROOT/ai/skills/registry.sh"
. "$REPO_ROOT/ai/system/profile.sh"
permission_check read_file /etc/hostname || fail 'safe read denied'
! permission_check read_file /etc/shadow || fail 'sensitive read allowed'
! permission_check read_file /tmp/../etc/passwd || fail 'traversal read allowed'
permission_check write_file /tmp/example || fail 'safe write denied'
! permission_check write_file /etc/hostname || fail 'system write allowed'
! permission_check write_file /jane/state/../etc/passwd || fail 'traversal write allowed'
[ "$(permission_decision change_setting hostname)" = confirm ] || fail 'setting confirmation missing'
[ "$(permission_decision network_request example)" = deny ] || fail 'blocked network decision missing'
[ "$(plan_request 'read /etc/hostname')" = 'read_file|/etc/hostname|' ] || fail 'read plan invalid'
[ "$(plan_request 'processes')" = 'get_processes||' ] || fail 'process plan invalid'
[ "$(plan_request 'system info')" = 'get_system_information||' ] || fail 'system plan invalid'
[ "$(plan_request 'hardware')" = 'hardware||' ] || fail 'hardware plan invalid'
[ "$(plan_request 'sequence status && processes')" = 'sequence||status && processes' ] || fail 'sequence plan invalid'
[ "$(plan_request 'find editor')" = 'memory_search||editor' ] || fail 'memory search plan invalid'
[ "$(plan_request 'compact memory')" = 'memory_compact||' ] || fail 'memory compact plan invalid'
sequence_steps=$(plan_sequence 'status && processes')
[ "$(printf '%s\n' "$sequence_steps" | wc -l)" = 2 ] || fail 'sequence step count invalid'
[ "$(plan_request 'search /tmp *.log')" = 'search_files|/tmp|*.log' ] || fail 'search plan invalid'
permission_check skill_search || fail 'skill discovery denied'
JANE_SKILLS_FILE="$REPO_ROOT/ai/skills/registry.tsv"
export JANE_SKILLS_FILE
SKILLS_FILE=$JANE_SKILLS_FILE
skills_find system >/dev/null || fail 'system skill unavailable'
profile_fixture=$(mktemp -d)
printf 'MemTotal:        3900000 kB\n' > "$profile_fixture/meminfo"
printf 'MemAvailable:     200000 kB\n' >> "$profile_fixture/meminfo"
printf 'processor\t: 0\n' > "$profile_fixture/cpuinfo"
mkdir -p "$profile_fixture/sys/class/drm" "$profile_fixture/sys/class/net"
JANE_MEMINFO_FILE="$profile_fixture/meminfo"
JANE_CPUINFO_FILE="$profile_fixture/cpuinfo"
JANE_SYSFS_ROOT="$profile_fixture/sys"
JANE_PROFILE_FILE="$profile_fixture/profile.tsv"
hardware_detect
[ "$JANE_RESOURCE_PROFILE" = ULTRA_LOW ] || fail 'low-memory profile not selected'
[ "$JANE_MODEL_PROFILE" = LOW ] || fail 'low-memory model not selected'
[ "$JANE_CONTEXT_TOKENS" = 2048 ] || fail 'low-memory context not reduced'
[ "$JANE_VOICE_MODE" = PUSH_TO_TALK ] || fail 'low-memory voice mode not selected'
hardware_apply_pressure_policy
[ "$JANE_CONTEXT_TOKENS" = 512 ] || fail 'pressure context reduction missing'
JANE_RESOURCE_PROFILE_OVERRIDE=STANDARD
JANE_MODEL_PROFILE_OVERRIDE=BALANCED
JANE_CONTEXT_TOKENS_OVERRIDE=4096
JANE_VOICE_MODE_OVERRIDE=ON_DEMAND
hardware_detect
[ "$JANE_RESOURCE_PROFILE" = STANDARD ] || fail 'resource override ignored'
[ "$JANE_MODEL_PROFILE" = BALANCED ] || fail 'model override ignored'
[ "$JANE_CONTEXT_TOKENS" = 4096 ] || fail 'context override ignored'
fake_runtime=$(mktemp)
fake_model=$(mktemp)
printf '#!/bin/sh\nprintf "local response\\n"\n' > "$fake_runtime"
chmod +x "$fake_runtime"
printf 'model\n' > "$fake_model"
JANE_MODEL_RUNTIME=$fake_runtime
JANE_MODEL_FILE=$fake_model
[ "$(backend_name)" = local-quantized-BALANCED ] || fail 'local runtime not selected'
[ "$(backend_respond hello)" = 'local response' ] || fail 'local runtime response invalid'
rm -f "$fake_runtime" "$fake_model"
rm -rf "$profile_fixture"
JANE_MEMORY_FILE=$(mktemp); export JANE_MEMORY_FILE
. "$REPO_ROOT/ai/memory/memory.sh"
CONTEXT_FILE=$(mktemp)
memory_remember color blue
[ "$(memory_recall color)" = blue ] || fail 'memory recall failed'
memory_remember editor vscode
[ "$(memory_search editor)" = "$(printf 'editor\tvscode')" ] || fail 'memory search failed'
memory_context_add 'opened editor'
[ "$(memory_context)" = 'opened editor' ] || fail 'recent context failed'
memory_compact
! memory_remember "bad$(printf '\t')key" value || fail 'invalid memory key accepted'
rm -f "$JANE_MEMORY_FILE"
rm -f "$CONTEXT_FILE"
JANE_AUDIT_FILE=$(mktemp); export JANE_AUDIT_FILE
AUDIT_FILE=$JANE_AUDIT_FILE
audit_event test read_file /etc/hostname allow success
grep -q 'test.*read_file.*allow.*success' "$JANE_AUDIT_FILE" || fail 'audit event missing'
rm -f "$JANE_AUDIT_FILE"
JANE_IDENTITY_DIR=$(mktemp -d); export JANE_IDENTITY_DIR
IDENTITY_DIR=$JANE_IDENTITY_DIR
IDENTITY_FILE="$IDENTITY_DIR/identity.tsv"
identity_initialize
identity_onboarding_complete && fail 'identity starts complete'
identity_answer 'a software assistant'
[ "$(identity_get onboarding_step)" = 1 ] || fail 'identity answer not recorded'
rm -rf "$JANE_IDENTITY_DIR"
JANE_MODEL_COMMAND='tr a-z A-Z'; export JANE_MODEL_COMMAND
[ "$(backend_name)" = external-command ] || fail 'external backend not selected'
[ "$(backend_respond hello)" = HELLO ] || fail 'external backend response invalid'
unset JANE_MODEL_COMMAND
if [ "${1:-}" = --built ]; then
  [ -x "$REPO_ROOT/rootfs/init" ] || fail '/init absent'
  [ -x "$REPO_ROOT/rootfs/bin/busybox" ] || fail 'busybox absent'
  [ -x "$REPO_ROOT/rootfs/jane/jane" ] || fail 'Jane daemon absent'
  [ -s "$REPO_ROOT/build/janeai-initramfs.cpio.gz" ] || fail 'initramfs absent'
  [ -s "$REPO_ROOT/build/jane-state.img" ] || fail 'state disk absent'
  [ -s "$REPO_ROOT/kernel/build/arch/x86/boot/bzImage" ] || fail 'kernel absent'
  grep -q 'Jane terminal ready' "$REPO_ROOT/rootfs/jane/jane" || fail 'Jane daemon source invalid'
  grep -q 'recovery wait mode' "$REPO_ROOT/rootfs/init" || fail 'init recovery policy missing'
  [ -x "$REPO_ROOT/tests/resource-test.sh" ] || fail 'resource test missing'
  confirmation_output=$(mktemp)
  JANE_AUDIT_FILE=$(mktemp); JANE_IDENTITY_DIR=$(mktemp -d); JANE_MEMORY_FILE=$(mktemp)
  export JANE_AUDIT_FILE JANE_IDENTITY_DIR JANE_MEMORY_FILE
  printf 'settings hostname jane-test\nconfirm\nexit\n' | "$REPO_ROOT/rootfs/jane/jane" > "$confirmation_output" 2>&1 || true
  grep -q 'requires approval; type confirm or deny' "$confirmation_output" || fail 'confirmation prompt missing'
  grep -q 'PERMISSION: allow change_setting hostname' "$confirmation_output" || fail 'confirmation approval missing'
  rm -f "$confirmation_output" "$JANE_AUDIT_FILE" "$JANE_MEMORY_FILE"
  rm -rf "$JANE_IDENTITY_DIR"
  sequence_output=$(mktemp)
  JANE_AUDIT_FILE=$(mktemp); JANE_IDENTITY_DIR=$(mktemp -d); JANE_MEMORY_FILE=$(mktemp)
  export JANE_AUDIT_FILE JANE_IDENTITY_DIR JANE_MEMORY_FILE
  printf 'sequence status && processes\nexit\n' | "$REPO_ROOT/rootfs/jane/jane" > "$sequence_output" 2>&1 || true
  grep -q 'PLAN: action=status' "$sequence_output" || fail 'sequence status step missing'
  grep -q 'PLAN: action=get_processes' "$sequence_output" || fail 'sequence process step missing'
  rm -f "$sequence_output" "$JANE_AUDIT_FILE" "$JANE_MEMORY_FILE"
  rm -rf "$JANE_IDENTITY_DIR"
  retry_output=$(mktemp)
  JANE_AUDIT_FILE=$(mktemp); JANE_IDENTITY_DIR=$(mktemp -d); JANE_MEMORY_FILE=$(mktemp)
  export JANE_AUDIT_FILE JANE_IDENTITY_DIR JANE_MEMORY_FILE
  printf 'sequence read /tmp/missing-file && status\nexit\n' | "$REPO_ROOT/rootfs/jane/jane" > "$retry_output" 2>&1 || true
  [ "$(grep -c 'PLAN: action=read_file' "$retry_output")" = 2 ] || fail 'sequence retry count invalid'
  ! grep -q 'PLAN: action=status' "$retry_output" || fail 'failed sequence continued'
  rm -f "$retry_output" "$JANE_AUDIT_FILE" "$JANE_MEMORY_FILE"
  rm -rf "$JANE_IDENTITY_DIR"
  rollback_target="/tmp/jane-rollback-test.$$"
  rm -f "$rollback_target"
  rollback_output=$(mktemp)
  JANE_AUDIT_FILE=$(mktemp); JANE_IDENTITY_DIR=$(mktemp -d); JANE_MEMORY_FILE=$(mktemp); JANE_SEQUENCE_RETRIES=0
  export JANE_AUDIT_FILE JANE_IDENTITY_DIR JANE_MEMORY_FILE JANE_SEQUENCE_RETRIES
  printf 'sequence write %s value && read /tmp/jane-missing-step\nexit\n' "$rollback_target" | "$REPO_ROOT/rootfs/jane/jane" > "$rollback_output" 2>&1 || true
  grep -q 'rolled_back' "$JANE_AUDIT_FILE" || fail 'sequence rollback audit missing'
  [ ! -e "$rollback_target" ] || fail 'sequence rollback did not remove new file'
  rm -f "$rollback_output" "$JANE_AUDIT_FILE" "$JANE_MEMORY_FILE" "$rollback_target"
  rm -rf "$JANE_IDENTITY_DIR"
fi
python3 -m py_compile "$REPO_ROOT/tools/jane-interface.py" || fail 'human interface syntax invalid'
python3 "$REPO_ROOT/tools/jane-interface.py" --check || fail 'human interface prerequisites invalid'
echo 'PASS: JaneAI-IOS tests'
