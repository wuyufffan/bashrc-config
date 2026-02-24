# bashrc-config

个人 Bash 配置文件，包含优雅的配色主题和实用函数。

## 特性

- 🎨 优雅的配色方案（红、绿、黄、蓝、灰、紫、青）
- 🕒 时间函数 (`now()`, `timestamp()`)
- 🔧 实用别名（rm、cp、mv 安全提示）
- 📦 支持组件扩展机制

## 安装

### 独立安装

```bash
git clone https://github.com/wuyufffan/bashrc-config.git
cd bashrc-config
./install.sh
```

### 作为 my_linux_config 的一部分安装

```bash
cd ~/my_linux_config
./install.sh --with-bashrc
```

## 组件扩展

其他组件（如 te-cli）可以将自己的初始化脚本添加到：

```
~/.config/my_linux_config/components/
├── te-cli.sh
└── other-component.sh
```

这些脚本会被 .bashrc 自动加载。

## 包含的别名

| 别名 | 命令 | 说明 |
|------|------|------|
| `rm` | `rm -i` | 删除前确认 |
| `cp` | `cp -i` | 覆盖前确认 |
| `mv` | `mv -i` | 移动前确认 |
| `c` | `clear` | 清屏 |
| `h` | `history` | 显示历史 |
| `ll` | `ls -alF --color=auto` | 详细列表 |
| `ls` | `ls --color=auto` | 彩色列表 |
| `tree` | `tree -C` | 彩色树形显示 |
| `bashrc` | `source ~/.bashrc` | 重载配置 |

## 颜色变量

在 .bashrc 中定义了以下颜色变量供使用：

```bash
$RED      # 亮红色
$GREEN    # 亮绿色
$YELLOW   # 亮黄色
$BLUE     # 亮蓝色
$GREY     # 灰色
$PURPLE   # 亮紫色
$CYAN     # 亮青色
$RESET    # 重置颜色
```

## 许可证

MIT License
