# bashrc-config 开发指南

## 项目架构

### 目录结构
```
bashrc-config/
├── envs/               # 环境配置
│   ├── base/           # 基础配置（必需）
│   │   └── config.sh
│   ├── docker/         # 容器环境
│   │   └── config.sh
│   ├── login/          # 登录节点
│   │   └── config.sh
│   └── compute/        # 计算节点
│       └── config.sh
├── lib/                # 共享库
│   ├── detect_env.sh   # 环境检测函数
│   └── network_test.sh # 网络连通性测试
├── install.sh          # 安装脚本
└── README.md
```

### 环境检测逻辑
检测优先级：
1. 容器环境（检查 `/.dockerenv` 或 cgroup）
2. 计算节点（检查作业环境变量或主机名）
3. 登录节点（检查主机名）
4. 默认为 base

### 配置加载顺序
生成的 `~/.bashrc` 按以下顺序加载：
1. `lib/detect_env.sh` - 检测函数
2. `envs/base/config.sh` - 基础配置
3. `envs/{env}/config.sh` - 环境特定配置
4. `~/.bashrc.local` - 用户自定义配置

## 开发规范

### 添加新环境
1. 在 `envs/` 下创建新目录
2. 创建 `config.sh` 文件
3. 在 `lib/detect_env.sh` 中添加检测逻辑
4. 更新 README.md

### 代码风格
- 使用 4 空格缩进
- 函数名使用小写加下划线
- 添加函数注释说明用途
- 错误处理使用 `set -e`

### 测试
```bash
# 试运行模式
./install.sh --dry-run

# 指定环境测试
./install.sh --env docker --dry-run
```

## 注意事项

- 所有配置脚本必须能在 Bash 4.0+ 运行
- 避免使用特定系统的命令
- 保持向后兼容
