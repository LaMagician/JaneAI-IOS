#!/bin/sh
JANE_STATE_DIR=${JANE_STATE_DIR:-/jane}
JANE_SETTINGS_FILE=${JANE_SETTINGS_FILE:-$JANE_STATE_DIR/config/settings.conf}
tool_read_file() { [ -r "$1" ] || return 1; cat "$1"; }
tool_write_file() {
    target=$1
    value=$2
    [ -L "$target" ] && { echo 'refusing to write through symlink'; return 1; }
    mkdir -p "$(dirname "$target")"
    tmp="$target.tmp.$$"
    umask 077
    printf '%s\n' "$value" > "$tmp"
    mv -f "$tmp" "$target"
}
tool_get_processes() { ps; }
tool_launch_program() { "$@"; }
tool_network_request() {
    if command -v wget >/dev/null 2>&1; then
        wget -T 3 -qO- "$1"
    elif command -v curl >/dev/null 2>&1; then
        curl --max-time 3 --fail --silent --show-error "$1"
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
            runtime_msg='runtime hostname updated'
            hostname "$value" 2>/dev/null || runtime_msg='runtime hostname unchanged (insufficient privilege)'
            mkdir -p "$(dirname "$JANE_SETTINGS_FILE")"
            [ -f "$JANE_SETTINGS_FILE" ] || : > "$JANE_SETTINGS_FILE"
            awk -F= '$1 != "hostname"' "$JANE_SETTINGS_FILE" > "$JANE_SETTINGS_FILE.tmp" 2>/dev/null || true
            printf 'hostname=%s\n' "$value" >> "$JANE_SETTINGS_FILE.tmp"
            chmod 600 "$JANE_SETTINGS_FILE.tmp" 2>/dev/null || true
            mv "$JANE_SETTINGS_FILE.tmp" "$JANE_SETTINGS_FILE"
            echo "hostname set to $value ($runtime_msg)"
            ;;
        *)
            echo "Unsupported setting: $setting"
            return 1
            ;;
    esac
}
