#!/bin/sh
tool_read_file() { cat "$1"; }
tool_write_file() { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }
tool_get_processes() { ps; }
tool_launch_program() { "$@"; }
tool_network_request() { echo 'Network access is disabled by JaneAI-IOS v0.1 policy.'; return 1; }
tool_change_setting() { hostname "$2"; }
