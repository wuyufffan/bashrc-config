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

## 自定义与安全

- 用户自定义请写入：`~/.bashrc.local`
- 安装前默认会备份旧配置，便于回滚

## 许可证

MIT
