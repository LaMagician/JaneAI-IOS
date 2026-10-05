#!/bin/sh
# Permission boundary: tools call these predicates before touching the system.
is_safe_read_path() {
    case "$1" in
        ''|/*/*/../*|*/../*|*/..|*/./*|*/.|*//*|..*) return 1;;
        /etc/hostname|/proc/*|/jane/*|/tmp/*|/root/*) return 0;;
        *) return 1;;
    esac
}
is_safe_write_path() {
    case "$1" in
        ''|/*/*/../*|*/../*|*/..|*/./*|*/.|*//*|..*) return 1;;
        /tmp/*|/jane/memory/*|/jane/state/*|/root/*) return 0;;
        *) return 1;;
    esac
}
is_safe_program() {
    case "$1" in /bin/echo|/bin/date|/bin/ls|echo|date|ls) return 0;; *) return 1;; esac
}
permission_check() {
    action=${1:-}; target=${2:-}
    case "$action" in
        read_file) is_safe_read_path "$target";;
        write_file) is_safe_write_path "$target";;
        launch_program) is_safe_program "$target";;
        get_processes) return 0;;
        get_system_information) return 0;;
        list_files|search_files) is_safe_read_path "$target";;
        skill_search) return 0;;
        network_request) return 1;;
        change_setting) [ "$target" = hostname ];;
        *) return 1;;
    esac
}

permission_decision() {
    action=${1:-}; target=${2:-}
    permission_check "$action" "$target" || { echo deny; return 0; }
    [ "$action" = change_setting ] && { echo confirm; return 0; }
    echo allow
}
