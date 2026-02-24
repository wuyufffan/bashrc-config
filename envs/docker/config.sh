#!/bin/bash
#
# Docker 容器环境配置
#

#==========================================
# 容器特定配置
#==========================================

# 容器内提示符 - 显示容器标识
export PS1='\[\033[1;32m\][docker]\[\033[0m\] \[\033[1;34m\]\w\[\033[0m\] \$ '

# 容器常用别名
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='docker images'
alias dlogs='docker logs -f'

# 容器环境变量
export TERM=xterm-256color
