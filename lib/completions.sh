#!/bin/bash
#
# Bash completions for my_linux_config helpers.
#

_my_linux_logs_root() {
    local workspace_root="${WORK_SPACE:-/workspace}"
    printf '%s\n' "${workspace_root}/logs"
}

_my_linux_log_timestamps() {
    local logs_root
    logs_root=$(_my_linux_logs_root)

    if [[ ! -d "$logs_root" ]]; then
        return 0
    fi

    find "$logs_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r
}

_my_linux_l0torch_logs() {
    local logs_root
    logs_root=$(_my_linux_logs_root)

    if [[ ! -d "$logs_root" ]]; then
        return 0
    fi

    find "$logs_root" -path '*/l0torch/*.log' -type f 2>/dev/null | sort -r
}

_bashrc_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]:-}"

    if (( COMP_CWORD == 1 )); then
        COMPREPLY=( $(compgen -W 'reload help list edit' -- "$cur") )
        return 0
    fi

    if [[ "$prev" == "edit" ]]; then
        COMPREPLY=( $(compgen -W '1 2 3 4 5 6 7 8' -- "$cur") )
        return 0
    fi
}

_proxy_completion() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]:-}"

    if (( COMP_CWORD == 1 )); then
        COMPREPLY=( $(compgen -W 'on off set status help' -- "$cur") )
        return 0
    fi

    if [[ "$prev" == "set" ]]; then
        COMPREPLY=()
        return 0
    fi
}

_te_completion() {
    local cur prev command
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]:-}"
    command="${COMP_WORDS[1]:-}"

    if (( COMP_CWORD == 1 )); then
        COMPREPLY=( $(compgen -W 'run log summary help -h --help -v --version -V --verbose --check-env -p --process -s --status -g --gpu -b --build -c --core --cpp -t --test --torch -r --rebuild -d --delete --clean -l --log -k --kill -0 --l0 -1 --l1' -- "$cur") )
        return 0
    fi

    case "$command" in
        run)
            if (( COMP_CWORD == 2 )); then
                COMPREPLY=( $(compgen -W 'l0cpp l0torch l1torch all help -g --gpu -h --help' -- "$cur") )
                return 0
            fi

            if [[ "$prev" == "-g" || "$prev" == "--gpu" ]]; then
                COMPREPLY=()
                return 0
            fi

            COMPREPLY=( $(compgen -W '-g --gpu -h --help' -- "$cur") )
            return 0
            ;;
        log)
            if (( COMP_CWORD == 2 )); then
                COMPREPLY=( $(compgen -W 'help list l0cpp l0torch l1torch' -- "$cur") )
                while IFS= read -r timestamp; do
                    COMPREPLY+=("$timestamp")
                done < <(compgen -W "$(_my_linux_log_timestamps | tr '\n' ' ')" -- "$cur")
                return 0
            fi

            if [[ "$prev" == "list" ]]; then
                COMPREPLY=( $(compgen -W "$(_my_linux_log_timestamps | tr '\n' ' ')" -- "$cur") )
                return 0
            fi

            if [[ "$prev" == "-n" ]]; then
                COMPREPLY=()
                return 0
            fi

            COMPREPLY=( $(compgen -W '-n -h --help' -- "$cur") )
            return 0
            ;;
        summary)
            if (( COMP_CWORD == 2 )); then
                COMPREPLY=( $(compgen -W "$(_my_linux_l0torch_logs | tr '\n' ' ') --brief --detailed -h --help" -- "$cur") )
                return 0
            fi

            COMPREPLY=( $(compgen -W '--brief --detailed -h --help' -- "$cur") )
            return 0
            ;;
        help)
            COMPREPLY=()
            return 0
            ;;
    esac
}

complete -F _bashrc_completion bashrc
complete -F _proxy_completion proxy
complete -F _te_completion te