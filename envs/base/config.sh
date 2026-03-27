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
# 历史记录设置
#==========================================
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend 2>/dev/null || true

bind '"\e[A": history-search-backward' 2>/dev/null || true
bind '"\e[B": history-search-forward' 2>/dev/null || true

#==========================================
# 基础提示符定义
#==========================================
export PS1='\[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ '
