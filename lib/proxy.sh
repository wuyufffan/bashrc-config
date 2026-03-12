#!/bin/bash
#
# 代理管理模块
# 提供 proxy on/off/set/status/help 命令
#

#==========================================
# 颜色定义（如果尚未加载）
#==========================================
[[ -z "$GREEN" ]] && export GREEN='\033[1;32m'
[[ -z "$RED" ]] && export RED='\033[1;31m'
[[ -z "$YELLOW" ]] && export YELLOW='\033[1;33m'
[[ -z "$BLUE" ]] && export BLUE='\033[1;34m'
[[ -z "$RESET" ]] && export RESET='\033[0m'

#==========================================
# 默认配置
#==========================================
PROXY_DEFAULT_HOST=${PROXY_DEFAULT_HOST:-127.0.0.1}
PROXY_DEFAULT_PORT=${PROXY_DEFAULT_PORT:-7890}
_PROXY_PORT=${_PROXY_PORT:-$PROXY_DEFAULT_PORT}

_proxy_help() {
    cat <<'EOF'
用法: proxy <command> [port]

命令:
    on            开启代理，默认端口 7890
    off           关闭代理
    set [port]    设置代理端口，缺省为 7890
    status        查看代理状态和端口
    help          显示本帮助

示例:
    proxy on
    proxy off
    proxy set 8080
    proxy status
EOF
}

_proxy_validate_port() {
    local port=$1

    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if (( port < 1 || port > 65535 )); then
        return 1
    fi

    return 0
}

_proxy_is_enabled() {
    [[ -n "$http_proxy" || -n "$https_proxy" || -n "$all_proxy" || -n "$HTTP_PROXY" || -n "$HTTPS_PROXY" || -n "$ALL_PROXY" ]]
}

_proxy_current_url() {
    local proxy_url
    local proxy_vars=(
        "$http_proxy"
        "$https_proxy"
        "$all_proxy"
        "$HTTP_PROXY"
        "$HTTPS_PROXY"
        "$ALL_PROXY"
    )

    for proxy_url in "${proxy_vars[@]}"; do
        if [[ -n "$proxy_url" ]]; then
            printf '%s\n' "$proxy_url"
            return 0
        fi
    done

    return 1
}

_proxy_current_port() {
    local proxy_url

    if proxy_url=$(_proxy_current_url); then
        if [[ "$proxy_url" =~ :([0-9]+)$ ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
            return 0
        fi
    fi

    printf '%s\n' "${_PROXY_PORT:-$PROXY_DEFAULT_PORT}"
    return 0
}

_proxy_export_vars() {
    local port=$1
    local proxy_url="http://${PROXY_DEFAULT_HOST}:${port}"

    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export all_proxy="$proxy_url"
}

_proxy_on() {
    local port="${_PROXY_PORT:-$PROXY_DEFAULT_PORT}"

    _proxy_export_vars "$port"
    echo -e "${GREEN}代理已开启${RESET}: http://${PROXY_DEFAULT_HOST}:${port}"
}

_proxy_off() {
    unset http_proxy https_proxy all_proxy
    echo -e "${YELLOW}代理已关闭${RESET}"
}

_proxy_set() {
    local port="${1:-$PROXY_DEFAULT_PORT}"

    if ! _proxy_validate_port "$port"; then
        echo -e "${RED}无效端口${RESET}: $port"
        return 1
    fi

    export _PROXY_PORT="$port"

    if _proxy_is_enabled; then
        _proxy_export_vars "$port"
        echo -e "${GREEN}代理端口已更新${RESET}: $port"
    else
        echo -e "${GREEN}默认代理端口已设置${RESET}: $port"
    fi
}

_proxy_status() {
    local current_port
    current_port=$(_proxy_current_port)

    if _proxy_is_enabled; then
        echo "代理状态: 已开启"
        echo "代理端口: ${current_port}"
    else
        echo "代理状态: 已关闭"
        echo "代理端口: ${current_port}"
    fi
}

proxy() {
    local command="${1:-help}"

    case "$command" in
        on)
            _proxy_on
            ;;
        off)
            _proxy_off
            ;;
        set)
            _proxy_set "$2"
            ;;
        status)
            _proxy_status
            ;;
        help|-h|--help)
            _proxy_help
            ;;
        *)
            echo -e "${RED}未知命令${RESET}: $command"
            _proxy_help
            return 1
            ;;
    esac
}
