#!/bin/sh
# Permission boundary: tools call these predicates before touching the system.
is_safe_read_path() {
    case "$1" in /etc/hostname|/proc/*|/jane/*|/tmp/*|/root/*) return 0;; *) return 1;; esac
}
is_safe_write_path() {
    case "$1" in /tmp/*|/jane/memory/*|/jane/config/*|/jane/state/memory/*|/jane/state/config/*|/root/*) return 0;; *) return 1;; esac
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
                case "$target" in /root/*) printf 'confirm\n';; *) printf 'allow\n';; esac
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
