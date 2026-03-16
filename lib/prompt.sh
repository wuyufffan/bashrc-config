#!/bin/bash
#
# Prompt helpers
# 提供右侧时间提示（Bash 模拟版）
#

__my_linux_should_show_right_time() {
    [[ $- == *i* ]] || return 1
    [[ -t 1 ]] || return 1
    [[ "${TERM:-}" != "dumb" ]] || return 1
    [[ "${MY_LINUX_CURRENT_ENV:-}" == "docker" ]] || return 1
    [[ "${MY_LINUX_RIGHT_TIME:-1}" != "0" ]] || return 1

    local cols
    cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 0)}
    (( cols >= ${MY_LINUX_RIGHT_TIME_MIN_COLS:-100} )) || return 1
    return 0
}

__my_linux_right_time_prompt() {
    __my_linux_should_show_right_time || return 0

    local time_text cols time_len start_col
    time_text=$(date +"${MY_LINUX_RIGHT_TIME_FORMAT:-%H:%M:%S}")
    cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 0)}
    time_len=${#time_text}
    start_col=$((cols - time_len + 1))

    (( start_col > 1 )) || return 0

    printf '\0337\033[%dG\033[%dD\033[0;37m%s\033[0m\0338' "$cols" "$((time_len - 1))" "$time_text"
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

enable_right_time_readline_bindings() {
    local binding_del='"\C-?": "__my_linux_right_time_backspace"'
    local binding_bs='"\C-h": "__my_linux_right_time_backspace"'
    local existing

    existing=$(bind -X 2>/dev/null || true)
    [[ "$existing" == *'"\C-?": "__my_linux_right_time_backspace"'* ]] || bind -x '"\C-?": "__my_linux_right_time_backspace"'
    [[ "$existing" == *'"\C-h": "__my_linux_right_time_backspace"'* ]] || bind -x '"\C-h": "__my_linux_right_time_backspace"'
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