#!/bin/bash
#
# bashrc-config 安装脚本
#

set -e

# 获取脚本所在目录
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 备份现有的 .bashrc（如果存在）
if [ -f "$HOME/.bashrc" ]; then
    print_info "备份现有的 .bashrc 到 $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.bashrc" "$BACKUP_DIR/"
    print_success "备份已创建"
fi

# 创建软链接
print_info "创建 .bashrc 软链接"
ln -sf "$REPO_DIR/.bashrc" "$HOME/.bashrc"
print_success ".bashrc 链接已创建"

# 创建组件目录
mkdir -p "$HOME/.config/my_linux_config/components"

echo ""
echo "=================================================="
echo -e "${GREEN}✅ bashrc-config 安装成功${NC}"
echo "=================================================="
echo ""
echo "后续步骤："
echo "  source ~/.bashrc"
echo ""
echo "备份保存在：$BACKUP_DIR"
