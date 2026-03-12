#!/bin/bash
#
# 通用 alias 配置
# 集中维护跨环境共享的 shell alias
#

alias ll='ls -alF --color=auto 2>/dev/null || ls -alF'
alias la='ls -A --color=auto 2>/dev/null || ls -A'
alias l='ls -CF --color=auto 2>/dev/null || ls -CF'
alias c='clear'
alias h='history'
alias ..='cd ..'
alias ...='cd ../..'

# 防止误覆盖
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias TE='cd $TE_PATH'
alias config='cd /workspace/my_linux_config'
alias home='cd /workspace'
