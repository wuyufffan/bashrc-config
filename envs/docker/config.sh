#!/bin/bash
#
# Docker 容器环境配置
#

#==========================================
# 容器特定配置
#==========================================

# 容器内提示符 - 仅在识别到 TE 版本时显示标签
DOCKER_PROMPT_LABEL=""
if type docker_prompt_label >/dev/null 2>&1; then
	DOCKER_PROMPT_LABEL=$(docker_prompt_label 2>/dev/null || true)
fi

if [[ -n "$DOCKER_PROMPT_LABEL" ]]; then
	export PS1="\[\033[1;32m\]${DOCKER_PROMPT_LABEL}\[\033[0m\] \[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ "
else
	export PS1='\[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ '
fi

# 容器常用别名
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='docker images'
alias dlogs='docker logs -f'

# 容器环境变量
export TERM=xterm-256color
