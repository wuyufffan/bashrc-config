#!/bin/bash
#
# Docker 容器环境配置
#

#==========================================
# 容器特定配置
#==========================================

# 容器内提示符 - 识别到 TE 版本时显示 [teXX-ubuntu]，否则仅显示常规前缀
DOCKER_PROMPT_LABEL=""
if type build_docker_prompt_label >/dev/null 2>&1; then
	DOCKER_PROMPT_LABEL=$(build_docker_prompt_label 2>/dev/null || true)
elif type docker_prompt_label >/dev/null 2>&1; then
	DOCKER_PROMPT_LABEL=$(docker_prompt_label 2>/dev/null || true)
fi

if [[ -n "$DOCKER_PROMPT_LABEL" ]]; then
	export PS1="\[\033[1;32m\]${DOCKER_PROMPT_LABEL}\[\033[0m\] \[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ "
else
	export PS1='\[\033[1;33m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ '
fi

export MY_LINUX_RIGHT_TIME_FORMAT="${MY_LINUX_RIGHT_TIME_FORMAT:-%H:%M:%S}"
export MY_LINUX_RIGHT_TIME="${MY_LINUX_RIGHT_TIME:-1}"

if type enable_docker_right_prompt_clock >/dev/null 2>&1; then
	enable_docker_right_prompt_clock
elif type enable_right_time_prompt >/dev/null 2>&1; then
	enable_right_time_prompt
fi

# 容器常用别名
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='docker images'
alias dlogs='docker logs -f'

# 容器环境变量
export TERM=xterm-256color
