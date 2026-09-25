#!/bin/sh
JANE_STATE_DIR=${JANE_STATE_DIR:-/jane}
JANE_SETTINGS_FILE=${JANE_SETTINGS_FILE:-$JANE_STATE_DIR/config/settings.conf}
tool_read_file() { cat "$1"; }
tool_write_file() { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }
tool_get_processes() { ps; }
tool_launch_program() { "$@"; }
tool_network_request() {
    if command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
    elif command -v curl >/dev/null 2>&1; then
        curl --fail --silent --show-error "$1"
    else
        echo 'No network client available (wget/curl missing).'
        return 1
    fi
}
tool_change_setting() {
    setting=$1
    value=$2
    case "$setting" in
        hostname)
            hostname "$value" 2>/dev/null || echo '[WARN] unable to change hostname in current environment'
            mkdir -p "$(dirname "$JANE_SETTINGS_FILE")"
            [ -f "$JANE_SETTINGS_FILE" ] || : > "$JANE_SETTINGS_FILE"
            awk -F= '$1 != "hostname"' "$JANE_SETTINGS_FILE" > "$JANE_SETTINGS_FILE.tmp" 2>/dev/null || true
            printf 'hostname=%s\n' "$value" >> "$JANE_SETTINGS_FILE.tmp"
            mv "$JANE_SETTINGS_FILE.tmp" "$JANE_SETTINGS_FILE"
            echo "RESULT: hostname set to $value"
            ;;
        *)
            echo "Unsupported setting: $setting"
            return 1
            ;;
    esac
}
