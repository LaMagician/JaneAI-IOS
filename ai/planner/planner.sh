#!/bin/sh
# Emits an intentionally small structured plan: action|target|argument.
plan_request() {
    case "$1" in
        help|status|identity|exit|memory|context|skills|system|hardware) printf '%s||\n' "$1";;
        find\ *) printf 'memory_search||%s\n' "${1#find }";;
        compact\ memory) printf 'memory_compact||\n';;
        sequence\ *) printf 'sequence||%s\n' "${1#sequence }";;
        processes) printf 'get_processes||\n';;
        list\ *) printf 'list_files|%s|\n' "${1#list }";;
        search\ *) rest=${1#search }; path=${rest%% *}; printf 'search_files|%s|%s\n' "$path" "${rest#* }";;
        system\ info) printf 'get_system_information||\n';;
        skills\ *) printf 'skill_search||%s\n' "${1#skills }";;
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

plan_sequence() {
    printf '%s\n' "$1" | awk -F '&&' '{ for (step_number = 1; step_number <= NF; step_number++) { step=$step_number; sub(/^[[:space:]]+/, "", step); sub(/[[:space:]]+$/, "", step); if (step != "") print step } }'
}
