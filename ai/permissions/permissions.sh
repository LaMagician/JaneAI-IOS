#!/bin/sh
# Permission boundary: tools call these predicates before touching the system.
is_absolute_clean_path() {
    case "$1" in
        /*) ;;
        *) return 1 ;;
    esac
    case "$1" in
        *'/../'*|*'/..'|'..'|../*|*'/./'*|*'/.') return 1 ;;
        *) return 0 ;;
    esac
}
is_under_path() {
    path=$1
    base=$2
    case "$path" in
        "$base"|"$base"/*) return 0 ;;
        *) return 1 ;;
    esac
}
resolve_read_path() {
    is_absolute_clean_path "$1" || return 1
    readlink -f "$1" 2>/dev/null
}
resolve_write_path() {
    is_absolute_clean_path "$1" || return 1
    parent=$(dirname "$1")
    base=$(basename "$1")
    parent_real=$(readlink -f "$parent" 2>/dev/null) || return 1
    printf '%s/%s\n' "$parent_real" "$base"
}
is_safe_read_path() {
    resolved=$(resolve_read_path "$1") || return 1
    [ "$resolved" = /etc/hostname ] && return 0
    is_under_path "$resolved" /proc && return 0
    is_under_path "$resolved" /tmp && return 0
    is_under_path "$resolved" /jane/memory && return 0
    is_under_path "$resolved" /jane/config && return 0
    is_under_path "$resolved" /jane/state/memory && return 0
    is_under_path "$resolved" /jane/state/config && return 0
    return 1
}
is_safe_write_path() {
    resolved=$(resolve_write_path "$1") || return 1
    is_under_path "$resolved" /tmp && return 0
    is_under_path "$resolved" /jane/memory && return 0
    is_under_path "$resolved" /jane/config && return 0
    is_under_path "$resolved" /jane/state/memory && return 0
    is_under_path "$resolved" /jane/state/config && return 0
    is_under_path "$resolved" /root && return 0
    return 1
}
is_safe_program() {
    case "$1" in /bin/echo|/bin/date|/bin/ls|echo|date|ls) return 0;; *) return 1;; esac
}
permission_decide() {
    action=$1
    target=${2:-}
    case "$action" in
        read_file)
            if is_safe_read_path "$target"; then printf 'allow\n'; else printf 'deny\n'; fi
            ;;
        write_file)
            if is_safe_write_path "$target"; then
                resolved=$(resolve_write_path "$target" 2>/dev/null || printf '%s' "$target")
                case "$resolved" in /root/*) printf 'confirm\n';; *) printf 'allow\n';; esac
            else
                printf 'deny\n'
            fi
            ;;
        launch_program)
            if is_safe_program "$target"; then printf 'confirm\n'; else printf 'deny\n'; fi
            ;;
        get_processes)
            printf 'allow\n'
            ;;
        network_request)
            case "$target" in
                http://127.0.0.1/*|http://localhost/*|https://127.0.0.1/*|https://localhost/*) printf 'confirm\n';;
                *) printf 'deny\n';;
            esac
            ;;
        change_setting)
            [ "$target" = hostname ] && printf 'confirm\n' || printf 'deny\n'
            ;;
        *)
            printf 'deny\n'
            ;;
    esac
}
permission_check() {
    action=$1; target=$2
    decision=$(permission_decide "$action" "$target")
    [ "$decision" = allow ] || [ "$decision" = confirm ]
}
