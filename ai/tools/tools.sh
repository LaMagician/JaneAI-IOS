#!/bin/sh
tool_read_file() { cat "$1"; }
tool_write_file() { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }
tool_get_processes() { ps; }
tool_list_files() { ls -la "$1"; }
tool_search_files() { find "$1" -type f -name "$2" -print 2>/dev/null; }
tool_system_information() {
	printf 'hostname: '; hostname
	printf 'kernel: '; uname -sr
	printf 'memory: '; awk '/MemTotal:/ { print $2 " kB" }' /proc/meminfo
	printf 'storage: '; df -h / | awk 'NR == 2 { print $3 " used / " $4 " available" }'
	printf 'resource profile: %s\n' "${JANE_RESOURCE_PROFILE:-unknown}"
	printf 'model profile: %s\n' "${JANE_MODEL_PROFILE:-unknown}"
	printf 'context tokens: %s\n' "${JANE_CONTEXT_TOKENS:-unknown}"
}
tool_launch_program() { "$@"; }
tool_network_request() { echo 'Network access is disabled by JaneAI-IOS v0.1 policy.'; return 1; }
tool_change_setting() { hostname "$2"; }
