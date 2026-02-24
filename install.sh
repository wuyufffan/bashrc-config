#!/bin/bash
#==========================================
# bashrc-config 安装脚本
# 支持多环境配置和模块化加载
#==========================================

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载检测库
source "${SCRIPT_DIR}/lib/detect_env.sh"

# 默认配置
ENV_TYPE=""
FORCE=false
BACKUP=true
DRY_RUN=false

# 显示帮助
show_help() {
    cat << 'EOF'
用法: ./install.sh [选项]

选项:
    -e, --env ENV       指定环境类型 (base|docker|login|compute)
    -f, --force         强制覆盖现有配置
    -n, --no-backup     不备份现有配置
    -d, --dry-run       试运行模式，显示将要执行的操作
    -h, --help          显示此帮助信息

环境类型:
    base    - 本地开发环境（默认）
    docker  - 容器环境
    login   - 集群登录节点
    compute - 计算节点

示例:
    ./install.sh                    # 自动检测并安装
    ./install.sh --env docker       # 强制安装 Docker 环境配置
    ./install.sh -e login -f        # 强制安装登录节点配置
    ./install.sh -d                 # 试运行模式

EOF
}

# 日志输出
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_dry() {
    echo -e "\033[1;36m[DRY-RUN]\033[0m $1"
}

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                ENV_TYPE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -n|--no-backup)
                BACKUP=false
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检测环境
get_env_type() {
    if [[ -n "$ENV_TYPE" ]]; then
        echo "$ENV_TYPE"
    else
        auto_detect_env
    fi
}

# 备份现有配置
backup_existing() {
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && [[ "$BACKUP" == true ]]; then
        local backup="${bashrc}.backup.$(date +%Y%m%d_%H%M%S)"
        if [[ "$DRY_RUN" == true ]]; then
            log_dry "将备份 $bashrc 到 $backup"
        else
            cp "$bashrc" "$backup"
            log_info "已备份现有配置: $backup"
        fi
    fi
}

# 生成 bashrc 配置
generate_bashrc() {
    local env_type=$1
    local output_file=$2
    
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "将生成配置: $output_file"
        log_dry "环境类型: $env_type"
        return 0
    fi
    
    cat > "$output_file" << EOF
#!/bin/bash
#==========================================
# bashrc-config 自动生成的配置
# 环境类型: $env_type
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
#==========================================

# 脚本所在目录（用于加载模块）
export BASHRC_CONFIG_DIR="${SCRIPT_DIR}"

# 加载检测库
source "${SCRIPT_DIR}/lib/detect_env.sh"

# 加载网络测试模块
if [[ -f "${SCRIPT_DIR}/lib/network_test.sh" ]]; then
    source "${SCRIPT_DIR}/lib/network_test.sh"
fi

# 加载基础配置
if [[ -f "${SCRIPT_DIR}/envs/base/config.sh" ]]; then
    source "${SCRIPT_DIR}/envs/base/config.sh"
fi

# 加载环境特定配置
if [[ -f "${SCRIPT_DIR}/envs/${env_type}/config.sh" ]]; then
    source "${SCRIPT_DIR}/envs/${env_type}/config.sh"
fi

# 加载用户自定义配置（如果不存在则创建）
USER_CONFIG="\${HOME}/.bashrc.local"
if [[ -f "\$USER_CONFIG" ]]; then
    source "\$USER_CONFIG"
fi

EOF
    
    log_info "已生成配置: $output_file"
}

# 创建用户自定义配置模板
create_user_template() {
    local user_config="$HOME/.bashrc.local"
    
    if [[ -f "$user_config" ]]; then
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "将创建用户配置模板: $user_config"
        return 0
    fi
    
    cat > "$user_config" << 'EOF'
#!/bin/bash
#==========================================
# 用户自定义 bashrc 配置
# 此文件不会被版本控制覆盖
#==========================================

# 在此添加您的自定义配置
# 例如：
# export MY_VAR="value"
# alias mycmd='command'

EOF
    
    log_info "已创建用户配置模板: $user_config"
}

# 主函数
main() {
    parse_args "$@"
    
    log_info "开始安装 bashrc-config..."
    
    # 检测环境
    local env_type=$(get_env_type)
    log_info "检测到的环境类型: $env_type"
    
    # 检查环境配置是否存在
    local env_config="${SCRIPT_DIR}/envs/${env_type}/config.sh"
    if [[ ! -f "$env_config" ]]; then
        log_error "环境配置不存在: $env_config"
        log_info "可用的环境类型: base, docker, login, compute"
        exit 1
    fi
    
    # 备份
    backup_existing
    
    # 生成新配置
    local bashrc="$HOME/.bashrc"
    generate_bashrc "$env_type" "$bashrc"
    
    # 创建用户模板
    create_user_template
    
    if [[ "$DRY_RUN" == false ]]; then
        log_info "安装完成！"
        log_info "请运行 'source ~/.bashrc' 或重新登录以应用配置"
    else
        log_info "试运行完成，未做任何更改"
    fi
}

# 运行主函数
main "$@"
