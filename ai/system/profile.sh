#!/bin/sh
# One-shot, low-cost hardware profiling. No background polling is required.
JANE_MEMINFO_FILE=${JANE_MEMINFO_FILE:-/proc/meminfo}
JANE_CPUINFO_FILE=${JANE_CPUINFO_FILE:-/proc/cpuinfo}
JANE_SYSFS_ROOT=${JANE_SYSFS_ROOT:-/sys}
JANE_PROFILE_FILE=${JANE_PROFILE_FILE:-/jane/state/hardware/profile.tsv}

hardware_detect() {
    memory_kb=$(awk '/MemTotal:/ { print $2; exit }' "$JANE_MEMINFO_FILE" 2>/dev/null || printf 0)
    memory_mb=$((memory_kb / 1024))
    cpu_count=$(awk '/^processor[[:space:]]*:/ { count++ } END { print count + 0 }' "$JANE_CPUINFO_FILE" 2>/dev/null)
    [ "$cpu_count" -gt 0 ] || cpu_count=1
    gpu_count=$(find "$JANE_SYSFS_ROOT/class/drm" -maxdepth 1 -name 'card[0-9]*' -type d 2>/dev/null | wc -l)
    storage_available=$(df -Pm / 2>/dev/null | awk 'NR == 2 { print $4 }')
    [ -n "$storage_available" ] || storage_available=0
    network_count=$(find "$JANE_SYSFS_ROOT/class/net" -maxdepth 1 -mindepth 1 -type d ! -name lo 2>/dev/null | wc -l)

    if [ "$memory_mb" -le 4096 ]; then
        JANE_RESOURCE_PROFILE=ULTRA_LOW
        JANE_MODEL_PROFILE=LOW
        JANE_CONTEXT_TOKENS=2048
        JANE_VOICE_MODE=PUSH_TO_TALK
    elif [ "$memory_mb" -le 8192 ]; then
        JANE_RESOURCE_PROFILE=LOW
        JANE_MODEL_PROFILE=LOW
        JANE_CONTEXT_TOKENS=4096
        JANE_VOICE_MODE=PUSH_TO_TALK
    elif [ "$memory_mb" -le 16384 ]; then
        JANE_RESOURCE_PROFILE=STANDARD
        JANE_MODEL_PROFILE=BALANCED
        JANE_CONTEXT_TOKENS=8192
        JANE_VOICE_MODE=ON_DEMAND
    else
        JANE_RESOURCE_PROFILE=PERFORMANCE
        JANE_MODEL_PROFILE=HIGH
        JANE_CONTEXT_TOKENS=16384
        JANE_VOICE_MODE=ON_DEMAND
    fi

    case "${JANE_RESOURCE_PROFILE_OVERRIDE:-}" in
        ULTRA_LOW|LOW|STANDARD|PERFORMANCE) JANE_RESOURCE_PROFILE=$JANE_RESOURCE_PROFILE_OVERRIDE;;
    esac
    case "${JANE_MODEL_PROFILE_OVERRIDE:-}" in
        LOW|BALANCED|HIGH|CLOUD) JANE_MODEL_PROFILE=$JANE_MODEL_PROFILE_OVERRIDE;;
    esac
    case "${JANE_CONTEXT_TOKENS_OVERRIDE:-}" in
        ''|*[!0-9]*) ;;
        *) [ "$JANE_CONTEXT_TOKENS_OVERRIDE" -le 32768 ] && JANE_CONTEXT_TOKENS=$JANE_CONTEXT_TOKENS_OVERRIDE;;
    esac
    [ -n "${JANE_VOICE_MODE_OVERRIDE:-}" ] && JANE_VOICE_MODE=$JANE_VOICE_MODE_OVERRIDE

    export JANE_RESOURCE_PROFILE JANE_MODEL_PROFILE JANE_CONTEXT_TOKENS JANE_VOICE_MODE
    JANE_HARDWARE_SUMMARY="ram=${memory_mb}MB cpu=${cpu_count} gpu=${gpu_count} storage=${storage_available}MB network=${network_count}"
    export JANE_HARDWARE_SUMMARY
    profile_write memory_mb "$memory_mb"
    profile_write cpu_count "$cpu_count"
    profile_write gpu_count "$gpu_count"
    profile_write storage_available_mb "$storage_available"
    profile_write network_count "$network_count"
    profile_write resource_profile "$JANE_RESOURCE_PROFILE"
    profile_write model_profile "$JANE_MODEL_PROFILE"
    profile_write context_tokens "$JANE_CONTEXT_TOKENS"
    profile_write voice_mode "$JANE_VOICE_MODE"
}

profile_write() {
    mkdir -p "$(dirname "$JANE_PROFILE_FILE")" 2>/dev/null || return 0
    printf '%s\t%s\n' "$1" "$2" >> "$JANE_PROFILE_FILE" 2>/dev/null || true
}

hardware_summary() {
    printf 'resource profile: %s\nmodel profile: %s\ncontext tokens: %s\nvoice mode: %s\nhardware: %s\n' \
        "${JANE_RESOURCE_PROFILE:-unknown}" "${JANE_MODEL_PROFILE:-unknown}" \
        "${JANE_CONTEXT_TOKENS:-unknown}" "${JANE_VOICE_MODE:-unknown}" \
        "${JANE_HARDWARE_SUMMARY:-unknown}"
}

hardware_apply_pressure_policy() {
    available_kb=$(awk '/MemAvailable:/ { print $2; exit }' "$JANE_MEMINFO_FILE" 2>/dev/null || printf 0)
    if [ "$available_kb" -gt 0 ] && [ "$available_kb" -le 262144 ]; then
        JANE_CONTEXT_TOKENS=512
        JANE_VOICE_MODE=PUSH_TO_TALK
        export JANE_CONTEXT_TOKENS JANE_VOICE_MODE
        profile_write pressure_mode constrained
    else
        profile_write pressure_mode normal
    fi
}