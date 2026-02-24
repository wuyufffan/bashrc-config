#!/bin/bash
#
# 网络连通性测试模块
# 测试代理、DNS、镜像源等网络连接
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
# 配置
#==========================================
# 测试超时时间（秒）
NETWORK_TEST_TIMEOUT=${NETWORK_TEST_TIMEOUT:-5}

# 测试目标列表
NETWORK_TEST_HOSTS=(
    "github.com"
    "www.google.com"
    "pypi.org"
)

# 镜像源测试列表
MIRROR_TEST_URLS=(
    "https://github.com"
    "https://pypi.org/simple"
    "https://registry.npmjs.org"
)

#==========================================
# 核心测试函数
#==========================================

# 测试 DNS 解析
test_dns() {
    local host=$1
    local timeout=${2:-$NETWORK_TEST_TIMEOUT}
    
    if command -v nslookup &>/dev/null; then
        timeout $timeout nslookup "$host" &>/dev/null
    elif command -v dig &>/dev/null; then
        timeout $timeout dig +short "$host" &>/dev/null
    else
        # 退而使用 ping 的解析
        timeout $timeout ping -c 1 "$host" &>/dev/null
    fi
}

# 测试 HTTP 连通性
test_http() {
    local url=$1
    local timeout=${2:-$NETWORK_TEST_TIMEOUT}
    
    if command -v curl &>/dev/null; then
        curl -s --max-time $timeout -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q "200\|301\|302"
    elif command -v wget &>/dev/null; then
        timeout $timeout wget -q --spider "$url" 2>/dev/null
    else
        return 1
    fi
}

# 测试 ICMP (ping)
test_ping() {
    local host=$1
    local timeout=${2:-$NETWORK_TEST_TIMEOUT}
    
    timeout $timeout ping -c 1 -W 2 "$host" &>/dev/null
}

# 检测代理设置
detect_proxy() {
    local proxy_vars=("http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY" "all_proxy" "ALL_PROXY")
    local found=false
    
    echo -e "${BLUE}代理设置检测:${RESET}"
    for var in "${proxy_vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            echo -e "  ${GREEN}✓${RESET} $var = ${!var}"
            found=true
        fi
    done
    
    if [[ "$found" == false ]]; then
        echo -e "  ${YELLOW}⚠${RESET} 未设置代理"
    fi
}

#==========================================
# 综合测试
#==========================================

# 快速网络测试
network_quick_test() {
    local host=${1:-"github.com"}
    local failed=0
    
    echo -e "${BLUE}快速网络测试: $host${RESET}"
    
    # DNS 测试
    if test_dns "$host"; then
        echo -e "  ${GREEN}✓${RESET} DNS 解析正常"
    else
        echo -e "  ${RED}✗${RESET} DNS 解析失败"
        ((failed++))
    fi
    
    # Ping 测试
    if test_ping "$host"; then
        echo -e "  ${GREEN}✓${RESET} ICMP 连通正常"
    else
        echo -e "  ${YELLOW}⚠${RESET} ICMP 不通 (可能禁止 ping)"
    fi
    
    # HTTP 测试
    if test_http "https://$host"; then
        echo -e "  ${GREEN}✓${RESET} HTTP 连接正常"
    else
        echo -e "  ${RED}✗${RESET} HTTP 连接失败"
        ((failed++))
    fi
    
    return $failed
}

# 完整网络测试
network_full_test() {
    local failed=0
    
    echo -e "\n${BLUE}=================================${RESET}"
    echo -e "${BLUE}     网络连通性测试报告          ${RESET}"
    echo -e "${BLUE}=================================${RESET}\n"
    
    # 代理检测
    detect_proxy
    echo ""
    
    # 主机连通性测试
    echo -e "${BLUE}主机连通性测试:${RESET}"
    for host in "${NETWORK_TEST_HOSTS[@]}"; do
        printf "  测试 %-20s " "$host"
        if test_http "https://$host"; then
            echo -e "${GREEN}✓ 正常${RESET}"
        else
            echo -e "${RED}✗ 失败${RESET}"
            ((failed++))
        fi
    done
    
    echo ""
    
    # 镜像源速度测试
    echo -e "${BLUE}镜像源响应测试:${RESET}"
    for url in "${MIRROR_TEST_URLS[@]}"; do
        printf "  测试 %-30s " "$url"
        
        local start_time end_time duration
        start_time=$(date +%s%N 2>/dev/null || date +%s)
        
        if test_http "$url"; then
            end_time=$(date +%s%N 2>/dev/null || date +%s)
            if [[ ${#start_time} -gt 10 ]]; then
                # 纳秒精度
                duration=$(( (end_time - start_time) / 1000000 ))
                echo -e "${GREEN}✓${RESET} ${duration}ms"
            else
                # 秒精度
                echo -e "${GREEN}✓${RESET} <1s"
            fi
        else
            echo -e "${RED}✗ 失败${RESET}"
            ((failed++))
        fi
    done
    
    echo ""
    echo -e "${BLUE}=================================${RESET}"
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ 所有测试通过${RESET}"
    else
        echo -e "${YELLOW}⚠ $failed 项测试失败${RESET}"
    fi
    echo -e "${BLUE}=================================${RESET}\n"
    
    return $failed
}

# 测试指定镜像源速度
test_mirror_speed() {
    local url=$1
    local name=${2:-"镜像源"}
    local timeout=${3:-10}
    
    printf "测试 %-25s " "$name"
    
    local start_time end_time duration_ms
    start_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
    
    if test_http "$url"; then
        end_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
        duration_ms=$(( (end_time - start_time) / 1000000 ))
        
        if [[ $duration_ms -lt 1000 ]]; then
            echo -e "${GREEN}${duration_ms}ms${RESET}"
        elif [[ $duration_ms -lt 3000 ]]; then
            echo -e "${YELLOW}${duration_ms}ms${RESET}"
        else
            echo -e "${RED}${duration_ms}ms${RESET}"
        fi
        return 0
    else
        echo -e "${RED}超时${RESET}"
        return 1
    fi
}

# 推荐最快的 PyPI 镜像
recommend_pypi_mirror() {
    echo -e "${BLUE}PyPI 镜像源速度测试:${RESET}"
    
    declare -A mirrors
    mirrors=(
        ["官方"]="https://pypi.org/simple"
        ["清华"]="https://pypi.tuna.tsinghua.edu.cn/simple"
        ["阿里云"]="https://mirrors.aliyun.com/pypi/simple"
        ["中科大"]="https://pypi.mirrors.ustc.edu.cn/simple"
        ["豆瓣"]="https://pypi.doubanio.com/simple"
    )
    
    local best_name=""
    local best_time=99999
    
    for name in "${!mirrors[@]}"; do
        local url="${mirrors[$name]}"
        local start_time end_time duration_ms
        
        start_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
        
        if test_http "$url"; then
            end_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
            duration_ms=$(( (end_time - start_time) / 1000000 ))
            
            printf "  %-10s %5sms\n" "$name:" "$duration_ms"
            
            if [[ $duration_ms -lt $best_time ]]; then
                best_time=$duration_ms
                best_name=$name
            fi
        else
            printf "  %-10s ${RED}失败${RESET}\n" "$name:"
        fi
    done
    
    if [[ -n "$best_name" ]]; then
        echo -e "\n${GREEN}推荐镜像: $best_name (${best_time}ms)${RESET}"
        echo -e "设置命令: pip config set global.index-url ${mirrors[$best_name]}"
    fi
}

#==========================================
# 便捷命令
#==========================================

# 命令别名
alias nettest='network_quick_test'
alias netfull='network_full_test'
alias netproxy='detect_proxy'
alias netpypi='recommend_pypi_mirror'
