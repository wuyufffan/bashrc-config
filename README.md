# bashrc-config

跨环境 Bash 配置管理工具，支持自动环境识别与按环境装配。

## 仓库定位

- 统一管理 `~/.bashrc` 及环境相关别名、函数、提示符。
- 支持 `base / docker / login / compute` 四类场景。
- 提供网络连通性与代理检查命令。

## 安装

### 独立安装

```bash
git clone https://github.com/wuyufffan/bashrc-config.git
cd bashrc-config
./install.sh
```

### 通过主仓安装

```bash
cd ~/my_linux_config
make install C=bashrc
```

## 常用命令

```bash
./install.sh --help
./install.sh --env docker
./install.sh --env login --force
./install.sh --dry-run
```

参数说明：

- `-e, --env`：指定环境（`base|docker|login|compute`）
- `-f, --force`：覆盖已有配置
- `-n, --no-backup`：不创建备份
- `-d, --dry-run`：只预览，不落盘

## 自动检测规则（简版）

- 容器标记（如 `/.dockerenv`）→ `docker`
- 调度器环境变量（如 `SLURM_JOB_ID`）→ `compute`
- 主机名包含 `login/mgmt/master` → `login`
- 其余默认 `base`

## 内置网络工具

- `nettest [host]`：快速 DNS/Ping/HTTP 检查
- `netfull`：完整网络测试
- `netproxy`：查看代理环境变量
- `netpypi`：测速并推荐 PyPI 镜像
- `proxy on|off|set|status|help`：管理本地代理环境变量

安装 `bashrc-config` 后，`make install C=bashrc` 会同时安装独立命令 `~/.local/bin/proxy`。

- 已 `source ~/.bashrc` 的交互式 shell：`proxy` 作为 shell function 使用，可直接影响当前 shell 环境
- 独立 `proxy` 命令：提供同一套 `help/status/on/off/set` 入口，适合未 reload shell 时直接调用

## Bashrc 维护

- 通用 alias 集中维护在 `lib/bash_alias.sh`
- 环境专属 alias 仍位于 `envs/docker|login|compute/config.sh`
- 安装后可用 `bashrc help` 查看 bashrc 相关命令
- Docker 环境默认显示右侧时间，格式为 `HH:MM:SS`
- 可在 `~/.bashrc.local` 中通过 `export MY_LINUX_RIGHT_TIME=0` 关闭右侧时间

## 自定义与安全

- 用户自定义请写入：`~/.bashrc.local`
- 安装前默认会备份旧配置，便于回滚

## 许可证

MIT
