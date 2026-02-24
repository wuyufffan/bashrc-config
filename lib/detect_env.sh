#!/bin/bash
#
# 环境检测库
# 用于自动检测当前运行环境
#

# 检测是否为容器
detect_container() {
    if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
        echo "docker"
        return 0
    fi
    # 检查 cgroup
    if grep -q "docker\|kubepods" /proc/1/cgroup 2>/dev/null; then
        echo "docker"
        return 0
    fi
    return 1
}

# 检测是否为登录节点
detect_login_node() {
    local hostname=$(hostname)
    # 常见的登录节点命名模式
    if [[ "$hostname" == *"login"* ]] || \
       [[ "$hostname" == *"mgmt"* ]] || \
       [[ "$hostname" == *"master"* ]]; then
        echo "login"
        return 0
    fi
    return 1
}

# 检测是否为计算节点
detect_compute_node() {
    # 检查是否在作业中
    if [[ -n "$SLURM_JOB_ID" ]] || [[ -n "$PBS_JOBID" ]]; then
        echo "compute"
        return 0
    fi
    
    local hostname=$(hostname)
    if [[ "$hostname" == *"compute"* ]] || \
       [[ "$hostname" == *"node"* ]] || \
       [[ "$hostname" == *"worker"* ]]; then
        echo "compute"
        return 0
    fi
    return 1
}

# 自动检测环境类型
auto_detect_env() {
    local env_type=""
    
    # 优先级：容器 > 计算节点 > 登录节点 > 本地
    env_type=$(detect_container)
    if [[ -n "$env_type" ]]; then
        echo "$env_type"
        return 0
    fi
    
    env_type=$(detect_compute_node)
    if [[ -n "$env_type" ]]; then
        echo "$env_type"
        return 0
    fi
    
    env_type=$(detect_login_node)
    if [[ -n "$env_type" ]]; then
        echo "$env_type"
        return 0
    fi
    
    # 默认本地环境
    echo "base"
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        uname -s | tr '[:upper:]' '[:lower:]'
    fi
}

# 检测显卡类型
detect_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        echo "nvidia"
        return 0
    fi
    if command -v rocm-smi &> /dev/null; then
        echo "amd"
        return 0
    fi
    echo "none"
}

# 检测 DTK 版本
detect_dtk() {
    if [[ -f /opt/dtk-26.04/env.sh ]]; then
        echo "26.04"
    elif [[ -f /opt/dtk-25.04.2/env.sh ]]; then
        echo "25.04.2"
    else
        echo "none"
    fi
}
