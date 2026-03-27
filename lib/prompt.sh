#!/bin/bash
#
# Prompt helpers
# 提供 Docker 提示标签与右侧时间提示（Bash 模拟版）
#

_MLC_PROMPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_docker_prompt_label() {
    local detect_env_lib="${_MLC_PROMPT_LIB_DIR}/detect_env.sh"

    if ! type docker_prompt_label >/dev/null 2>&1; then
        if [[ ! -f "$detect_env_lib" ]]; then
            return 1
        fi
        source "$detect_env_lib"
    fi

    docker_prompt_label 2>/dev/null || return 1
}

__my_linux_should_show_right_time() {
    if [[ -z "${MLC_FORCE_INTERACTIVE_PROMPT:-}" ]]; then
        [[ $- == *i* ]] || return 1
        [[ -t 1 ]] || return 1
    fi

    [[ "${TERM:-}" != "dumb" ]] || return 1
    [[ "${MY_LINUX_CURRENT_ENV:-}" == "docker" ]] || return 1
    [[ "${MY_LINUX_RIGHT_TIME:-1}" != "0" ]] || return 1

    local cols
    cols=${MLC_PROMPT_CLOCK_COLUMNS:-${COLUMNS:-$(tput cols 2>/dev/null || echo 0)}}
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=0
    (( cols >= ${MY_LINUX_RIGHT_TIME_MIN_COLS:-1} )) || return 1
    return 0
}

__my_linux_compute_right_time_text() {
    printf '%s' "${MLC_PROMPT_CLOCK_TEXT:-$(date +"${MY_LINUX_RIGHT_TIME_FORMAT:-%H:%M:%S}")}"
}

__my_linux_update_right_time_cache() {
    MY_LINUX_CACHED_RIGHT_TIME="$(__my_linux_compute_right_time_text)"
    export MY_LINUX_CACHED_RIGHT_TIME
}

__my_linux_render_right_time() {
    local exit_code=$?
    __my_linux_should_show_right_time || return $exit_code

    local time_text cols start_col
    time_text="${MY_LINUX_CACHED_RIGHT_TIME:-}"
    if [[ -z "$time_text" ]]; then
        __my_linux_update_right_time_cache
        time_text="$MY_LINUX_CACHED_RIGHT_TIME"
    fi

    cols=${MLC_PROMPT_CLOCK_COLUMNS:-${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}}

    if [[ ! "$cols" =~ ^[0-9]+$ ]]; then
        cols=80
    fi

    start_col=$(( cols - ${#time_text} + 1 ))
    if (( start_col < 1 )); then
        start_col=1
    fi

    printf '\033[s\033[%dG%s\033[u' "$start_col" "$time_text"
    return $exit_code
}

__my_linux_right_time_prompt() {
    local exit_code=$?
    __my_linux_update_right_time_cache
    __my_linux_render_right_time
    return $exit_code
}

render_right_prompt_time() {
    __my_linux_right_time_prompt "$@"
}

_mlc_prompt_command_with_clock() {
    __my_linux_right_time_prompt
}

normalize_right_time_prompt_command() {
    local hook="__my_linux_right_time_prompt"

    [[ -n "${PROMPT_COMMAND:-}" ]] || return 0

    PROMPT_COMMAND="${PROMPT_COMMAND//render_right_prompt_time/${hook}}"
    PROMPT_COMMAND="${PROMPT_COMMAND//_mlc_prompt_command_with_clock/${hook}}"

    while [[ "$PROMPT_COMMAND" == *';;'* ]]; do
        PROMPT_COMMAND="${PROMPT_COMMAND//;;/;}"
    done

    PROMPT_COMMAND="${PROMPT_COMMAND#;}"
    PROMPT_COMMAND="${PROMPT_COMMAND%;}"
}

__my_linux_right_time_backspace() {
    local point=${READLINE_POINT:-0}
    local line=${READLINE_LINE:-}

    if (( point > 0 )); then
        READLINE_LINE=${line:0:point-1}${line:point}
        READLINE_POINT=$((point - 1))
    fi

    __my_linux_render_right_time
}

__my_linux_right_time_delete_char() {
    local point=${READLINE_POINT:-0}
    local line=${READLINE_LINE:-}

    if (( point < ${#line} )); then
        READLINE_LINE=${line:0:point}${line:point+1}
    fi

    __my_linux_render_right_time
}

enable_right_time_readline_bindings() {
    local existing
    local bindings

    existing=$(bind -X 2>/dev/null || true)
    [[ "$existing" == *'"\C-h": "__my_linux_right_time_backspace"'* ]] || bind -x '"\C-h": "__my_linux_right_time_backspace"'
    [[ "$existing" == *'"\C-x\C-r": "__my_linux_right_time_backspace"'* ]] || bind -x '"\C-x\C-r": "__my_linux_right_time_backspace"'
    [[ "$existing" == *'"\C-x\C-d": "__my_linux_right_time_delete_char"'* ]] || bind -x '"\C-x\C-d": "__my_linux_right_time_delete_char"'

    bind -r '"\C-?"' 2>/dev/null || true
    bind -r '"\e[3~"' 2>/dev/null || true
    bindings=$(bind -p 2>/dev/null || true)
    [[ "$bindings" == *'"\C-?": "\C-x\C-r"'* ]] || bind '"\C-?": "\C-x\C-r"'
    [[ "$bindings" == *'"\e[3~": "\C-x\C-d"'* ]] || bind '"\e[3~": "\C-x\C-d"'
}

enable_right_time_prompt() {
    local hook="__my_linux_right_time_prompt"

    normalize_right_time_prompt_command

    if [[ ";${PROMPT_COMMAND:-};" == *";${hook};"* ]]; then
        enable_right_time_readline_bindings
        return 0
    fi

    if [[ -n "${PROMPT_COMMAND:-}" ]]; then
        PROMPT_COMMAND="${hook};${PROMPT_COMMAND}"
    else
        PROMPT_COMMAND="${hook}"
    fi

    enable_right_time_readline_bindings
}

enable_docker_right_prompt_clock() {
    if [[ -n "${MLC_DISABLE_RIGHT_PROMPT_CLOCK:-}" ]]; then
        return 0
    fi

    export MY_LINUX_CURRENT_ENV="${MY_LINUX_CURRENT_ENV:-docker}"
    export MY_LINUX_RIGHT_TIME_FORMAT="${MY_LINUX_RIGHT_TIME_FORMAT:-%H:%M:%S}"
    export MY_LINUX_RIGHT_TIME="${MY_LINUX_RIGHT_TIME:-1}"

    if [[ -z "${MLC_FORCE_INTERACTIVE_PROMPT:-}" ]]; then
        case $- in
            *i*) ;;
            *) return 0 ;;
        esac
    fi

    enable_right_time_prompt
}

update_shell_prompt() {
    case "${MY_LINUX_CURRENT_ENV:-base}" in
        docker)
            local docker_prompt_label_text=""

            if type resolve_docker_prompt_label >/dev/null 2>&1; then
                docker_prompt_label_text="$(resolve_docker_prompt_label 2>/dev/null || true)"
            elif type docker_prompt_label >/dev/null 2>&1; then
                docker_prompt_label_text="$(docker_prompt_label 2>/dev/null || true)"
            fi

            if [[ -n "$docker_prompt_label_text" ]]; then
                export PS1="\[\033[1;32m\]${docker_prompt_label_text}\[\033[0m\] \[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ "
            else
                export PS1='\[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ '
            fi

            enable_docker_right_prompt_clock
            ;;
        login)
            export PS1='\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ '
            ;;
        compute)
            export PS1='\[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ '
            ;;
        *)
            export PS1='\[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ '
            ;;
    esac
}