#!/bin/bash
#
# 基础环境配置 - 所有环境共享
#

#==========================================
# 颜色定义
#==========================================
export RESET='\033[0m'
export BOLD='\033[1m'
export RED='\033[1;31m'
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[1;34m'
export GREY='\033[0;37m'
export PURPLE='\033[1;35m'
export CYAN='\033[1;36m'

#==========================================
# 通用函数
#==========================================

# 时间戳函数
now() {
    echo -e "${GREY}[$(date +'%H:%M:%S')]${RESET}"
}

timestamp() {
    echo -e "${GREY}[$(date +'%Y-%m-%d %H:%M:%S')]${RESET}"
}

# 信息输出
info() {
    echo -e "$(now) ${BLUE}INFO${RESET} $*"
}

ok() {
    echo -e "$(now) ${GREEN}OK${RESET} $*"
}

warn() {
    echo -e "$(now) ${YELLOW}WARN${RESET} $*"
}

err() {
    echo -e "$(now) ${RED}ERROR${RESET} $*"
}

#==========================================
# 通用别名
#==========================================
alias ll='ls -alF --color=auto 2>/dev/null || ls -alF'
alias la='ls -A --color=auto 2>/dev/null || ls -A'
alias l='ls -CF --color=auto 2>/dev/null || ls -CF'
alias c='clear'
alias h='history'
alias ..='cd ..'
alias ...='cd ../..'

#==========================================
# 安全设置
#==========================================
# 防止意外覆盖
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# 历史记录设置
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend 2>/dev/null || true

#==========================================
# 加载网络测试模块（如果存在）
#==========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -f "${SCRIPT_DIR}/lib/network_test.sh" ]]; then
    source "${SCRIPT_DIR}/lib/network_test.sh"
fi
