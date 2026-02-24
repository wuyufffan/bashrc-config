#!/bin/bash
#
# 计算节点配置
#

#==========================================
# 计算节点特定配置
#==========================================

# 简洁提示符（批量作业不需要太复杂）
export PS1='\[\033[1;35m\][compute]\[\033[0m\] \w \$ '

# 作业信息
alias jobinfo='echo "Job ID: $SLURM_JOB_ID" 2>/dev/null || echo "Job ID: $PBS_JOBID" 2>/dev/null || echo "No job ID"'
alias nodelist='echo "Nodes: $SLURM_JOB_NODELIST" 2>/dev/null'

# 资源监控
alias meminfo='free -h'
alias cpuinfo='lscpu | grep "CPU(s):"'

# 禁用历史记录（计算节点通常不需要）
unset HISTFILE
