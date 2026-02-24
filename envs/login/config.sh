#!/bin/bash
#
# 集群登录节点配置
#

#==========================================
# 登录节点特定配置
#==========================================

# 提示符显示主机名
export PS1='\[\033[1;33m\][login]\[\033[0m\] \[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ '

# 集群管理常用别名
alias squeue='squeue -u $USER'
alias sq='squeue -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"'
alias sinfo='sinfo -N -o "%N %T %C %m"'
alias myjobs='squeue -u $USER -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"'

# 快速目录切换
alias work='cd $HOME/work'
alias scratch='cd /scratch/$USER 2>/dev/null || cd /tmp'

# 环境变量
export HISTSIZE=10000
export HISTFILESIZE=20000
