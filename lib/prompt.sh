#!/bin/bash
#
# Prompt helpers
# 提供 Docker 提示标签与右侧时间提示（Bash 模拟版）
#

detect_te_prompt_name() {
    if type detect_te_prompt_tag >/dev/null 2>&1; then
        detect_te_prompt_tag && return 0
    fi

    local te_root="${TE_PATH:-/workspace/TransformerEngine}"
    local version_file=""
    local version_text=""

    if [[ -f "${te_root}/build_tools/VERSION.txt" ]]; then
        version_file="${te_root}/build_tools/VERSION.txt"
    elif [[ -f "${te_root}/VERSION.txt" ]]; then
        version_file="${te_root}/VERSION.txt"
    fi

    if [[ -n "$version_file" ]]; then
        version_text="$(head -n 1 "$version_file" 2>/dev/null | tr -d '[:space:]')"
    fi

    if [[ "$version_text" =~ ^([0-9]+)\.([0-9]+) ]]; then
        echo "te${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
        return 0
    fi

    return 1
}

detect_container_prompt_name() {
    if [[ -n "${CONTAINER_NAME:-}" ]]; then
        echo "$CONTAINER_NAME"
        return 0
    fi

    if type detect_os >/dev/null 2>&1; then
        local detected_os=""
        detected_os="$(detect_os 2>/dev/null || true)"
        if [[ -n "$detected_os" ]]; then
            echo "$detected_os"
            return 0
        fi
    fi

    if [[ -f /etc/os-release ]]; then
        local distro_id=""
        distro_id="$(. /etc/os-release && printf '%s' "${ID:-}")"
        if [[ -n "$distro_id" ]]; then
            echo "$distro_id"
            return 0
        fi
    fi

    hostname | sed 's/\..*$//'
}

build_docker_prompt_label() {
    if type docker_prompt_label >/dev/null 2>&1; then
        local existing_label=""
        existing_label="$(docker_prompt_label 2>/dev/null || true)"
        if [[ -n "$existing_label" ]]; then
            echo "$existing_label"
            return 0
        fi
    fi

    local te_name=""
    local container_name=""

    te_name="$(detect_te_prompt_name 2>/dev/null || true)"
    container_name="$(detect_container_prompt_name 2>/dev/null || true)"

    if [[ -z "$te_name" || -z "$container_name" ]]; then
        return 1
    fi

    echo "[${te_name}-${container_name}]"
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

__my_linux_right_time_prompt() {
    local exit_code=$?
    __my_linux_should_show_right_time || return $exit_code

    local time_text cols start_col
    time_text=${MLC_PROMPT_CLOCK_TEXT:-$(date +"${MY_LINUX_RIGHT_TIME_FORMAT:-%H:%M:%S}")}
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

_mlc_prompt_command_with_clock() {
    __my_linux_right_time_prompt
}

__my_linux_right_time_backspace() {
    local point=${READLINE_POINT:-0}
    local line=${READLINE_LINE:-}

    if (( point > 0 )); then
        READLINE_LINE=${line:0:point-1}${line:point}
        READLINE_POINT=$((point - 1))
    fi

    __my_linux_right_time_prompt
}

__my_linux_right_time_delete_char() {
    local point=${READLINE_POINT:-0}
    local line=${READLINE_LINE:-}

    if (( point < ${#line} )); then
        READLINE_LINE=${line:0:point}${line:point+1}
    fi

    __my_linux_right_time_prompt
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

    if [[ ";${PROMPT_COMMAND:-};" == *";${hook};"* ]]; then
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