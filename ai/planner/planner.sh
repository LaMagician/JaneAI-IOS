#!/bin/sh
# Emits an intentionally small structured plan: action|target|argument.
plan_request() {
    case "$1" in
        help|status|exit|memory) printf '%s||\n' "$1";;
        processes) printf 'get_processes||\n';;
        read\ *) printf 'read_file|%s|\n' "${1#read }";;
        write\ *) rest=${1#write }; path=${rest%% *}; printf 'write_file|%s|%s\n' "$path" "${rest#* }";;
        remember\ *) rest=${1#remember }; key=${rest%% *}; printf 'remember|%s|%s\n' "$key" "${rest#* }";;
        recall\ *) printf 'recall|%s|\n' "${1#recall }";;
        launch\ *) printf 'launch_program|%s|\n' "${1#launch }";;
        settings\ hostname\ *) printf 'change_setting|hostname|%s\n' "${1#settings hostname }";;
        network\ *) printf 'network_request|%s|\n' "${1#network }";;
        *) printf 'unknown||\n';;
    esac
}
