#!/bin/sh
# Permission boundary: tools call these predicates before touching the system.
is_safe_read_path() {
    case "$1" in /etc/hostname|/proc/*|/jane/*|/tmp/*|/root/*) return 0;; *) return 1;; esac
}
is_safe_write_path() {
    case "$1" in /tmp/*|/jane/memory/*|/root/*) return 0;; *) return 1;; esac
}
is_safe_program() {
    case "$1" in /bin/echo|/bin/date|/bin/ls|echo|date|ls) return 0;; *) return 1;; esac
}
permission_check() {
    action=$1; target=$2
    case "$action" in
        read_file) is_safe_read_path "$target";;
        write_file) is_safe_write_path "$target";;
        launch_program) is_safe_program "$target";;
        get_processes) return 0;;
        network_request) return 1;;
        change_setting) [ "$target" = hostname ];;
        *) return 1;;
    esac
}
