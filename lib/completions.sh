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

_my_linux_l0torch_log_names() {
    _my_linux_l0torch_logs | xargs -r -n1 basename | awk '!seen[$0]++'
}

_my_linux_te_sum_history_keywords() {
    local histfile="${HISTFILE:-$HOME/.bash_history}"

    if [[ ! -f "$histfile" ]]; then
        return 0
    fi

    awk '
        /^te sum / {
            if (NF >= 5 && $4 ~ /^l[123]$/) {
                print $5
            } else if (NF >= 4 && $4 !~ /^l[123]$/) {
                print $4
            }
        }
    ' "$histfile" | awk '!seen[$0]++'
}

_my_linux_resolve_sum_log() {
    local input="$1"
    local logs_root
    logs_root=$(_my_linux_logs_root)

    if [[ -f "$input" ]]; then
        printf '%s\n' "$input"
        return 0
    fi

    find "$logs_root" -path "*/l0torch/$input" -type f 2>/dev/null | sort -r | awk 'NR==1 {print; exit}'
}

_my_linux_te_sum_log_keywords() {
    local log_input="$1"
    local log_path
    local line

    log_path=$(_my_linux_resolve_sum_log "$log_input")
    if [[ -z "$log_path" || ! -f "$log_path" ]]; then
        return 0
    fi

    while IFS= read -r line; do
        local target=""
        local target_no_params
        local params=""
        local file_path
        local remainder
        local class_name=""
        local test_name
        local normalized
        local basename

        case "$line" in
            *FAILED*tests/*.py::*)
                target=${line#*FAILED }
                ;;
            *ERROR*tests/*.py::*)
                target=${line#*ERROR }
                ;;
            *)
                continue
                ;;
        esac

        target=${target%% *}
        target_no_params=${target%%\[*}
        if [[ "$target" != "$target_no_params" ]]; then
            params=${target#"$target_no_params"}
            params=${params#[}
            params=${params%]}
        fi

        file_path=${target_no_params%%::*}
        remainder=${target_no_params#*::}
        if [[ "$remainder" == "$target_no_params" ]]; then
            continue
        fi

        if [[ "$remainder" == *::* ]]; then
            class_name="${remainder%%::*}"
            test_name="${remainder##*::}"
        else
            test_name="$remainder"
        fi

        normalized="${file_path#TransformerEngine/}"
        basename=$(basename "$normalized")

        printf '%s\n' "$normalized"
        printf '%s\n' "$basename"
        printf '%s\n' "$test_name"
        printf '%s\n' "$basename::$test_name"
        printf '%s\n' "$normalized::$test_name"

        if [[ -n "$class_name" ]]; then
            printf '%s\n' "$normalized::$class_name::$test_name"
            printf '%s\n' "$basename::$class_name::$test_name"
        fi

        if [[ -n "$params" ]]; then
            printf '%s\n' "$normalized::$test_name[$params]"
            printf '%s\n' "$basename::$test_name[$params]"
            if [[ -n "$class_name" ]]; then
                printf '%s\n' "$normalized::$class_name::$test_name[$params]"
                printf '%s\n' "$basename::$class_name::$test_name[$params]"
            fi
        fi
    done < "$log_path" | awk '!seen[$0]++'
}

_my_linux_compgen_from_lines() {
    local cur="$1"
    shift
    local entries=()
    local value

    while IFS= read -r value; do
        [[ -z "$value" ]] && continue
        entries+=("$value")
    done

    if (( ${#entries[@]} == 0 )); then
        return 0
    fi

    COMPREPLY+=( $(compgen -W "${entries[*]}" -- "$cur") )
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
    local cur prev command subcommand
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]:-}"
    command="${COMP_WORDS[1]:-}"
    subcommand="${COMP_WORDS[2]:-}"

    if (( COMP_CWORD == 1 )); then
        COMPREPLY=( $(compgen -W 'run log build rebuild sum help -h --help -v --version -V --verbose --check-env -p --process -s --status -g --gpu -b --build -c --core --cpp -t --test --torch -r --rebuild -d --delete --clean -l --log -k --kill -0 --l0 -1 --l1' -- "$cur") )
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
                COMPREPLY=( $(compgen -W 'help list watch l0cpp l0torch l1torch' -- "$cur") )
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
        build|rebuild)
            if (( COMP_CWORD == 2 )); then
                COMPREPLY=( $(compgen -W 'help py cpp all -h --help' -- "$cur") )
                return 0
            fi

            COMPREPLY=( $(compgen -W '-h --help' -- "$cur") )
            return 0
            ;;
        sum)
            if (( COMP_CWORD == 2 )); then
                COMPREPLY=( $(compgen -W "$(_my_linux_l0torch_log_names | tr '\n' ' ') help -h --help" -- "$cur") )
                return 0
            fi

            if (( COMP_CWORD == 3 )); then
                COMPREPLY=( $(compgen -W 'l1 l2 l3 -h --help' -- "$cur") )
                _my_linux_compgen_from_lines "$cur" < <(_my_linux_te_sum_history_keywords)
                _my_linux_compgen_from_lines "$cur" < <(_my_linux_te_sum_log_keywords "$subcommand")
                return 0
            fi

            if (( COMP_CWORD == 4 )) && [[ "$subcommand" =~ ^l[123]$ ]]; then
                _my_linux_compgen_from_lines "$cur" < <(_my_linux_te_sum_history_keywords)
                _my_linux_compgen_from_lines "$cur" < <(_my_linux_te_sum_log_keywords "${COMP_WORDS[2]:-}")
                return 0
            fi

            COMPREPLY=( $(compgen -W '-h --help' -- "$cur") )
            return 0
            ;;
        help)
            COMPREPLY=( $(compgen -W 'run log build rebuild sum old' -- "$cur") )
            return 0
            ;;
    esac
}

complete -F _bashrc_completion bashrc
complete -F _proxy_completion proxy
complete -F _te_completion te