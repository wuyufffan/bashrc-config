"""
测试 install.sh 安装流程（dry-run 及实际安装）
"""
import os
import subprocess
from pathlib import Path

INSTALL_SH = Path(__file__).resolve().parents[1] / "install.sh"


def _run(args: list, env: dict = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", str(INSTALL_SH)] + args,
        cwd=INSTALL_SH.parent,
        capture_output=True,
        text=True,
        env={**os.environ, **(env or {})},
    )


def test_help_exits_zero():
    """--help 应正常退出"""
    result = _run(["--help"])
    assert result.returncode == 0
    assert "用法" in result.stdout or "Usage" in result.stdout


def test_unknown_option_exits_nonzero():
    """未知选项应返回非零退出码"""
    result = _run(["--bad-option-xyz"])
    assert result.returncode != 0


def test_dry_run_does_not_modify_home(tmp_path):
    """dry-run 模式不应修改 HOME 目录"""
    env = {**os.environ, "HOME": str(tmp_path)}
    result = _run(["--dry-run"], env=env)
    assert result.returncode == 0
    assert "DRY-RUN" in result.stdout or "试运行" in result.stdout
    written = list(tmp_path.iterdir())
    assert written == [], f"dry-run 不应写文件，但写了: {written}"


def test_force_install_creates_bashrc(tmp_path):
    """强制安装应在 HOME 下生成 .bashrc"""
    env = {**os.environ, "HOME": str(tmp_path)}
    result = _run(["--force", "--env", "base"], env=env)
    assert result.returncode == 0
    assert (tmp_path / ".bashrc").exists(), ".bashrc 应被生成"


def test_install_base_env_bashrc_sources_base_config(tmp_path):
    """.bashrc 应 source base/config.sh"""
    env = {**os.environ, "HOME": str(tmp_path)}
    _run(["--force", "--env", "base"], env=env)
    content = (tmp_path / ".bashrc").read_text()
    assert "base/config.sh" in content


def test_install_creates_bashrc_local_template(tmp_path):
    """安装后应生成 .bashrc.local 模板"""
    env = {**os.environ, "HOME": str(tmp_path)}
    _run(["--force", "--env", "base"], env=env)
    assert (tmp_path / ".bashrc.local").exists(), ".bashrc.local 模板应被生成"


def test_force_install_creates_te_env_component(tmp_path):
    """安装后应生成 TE_PATH 组件脚本"""
    env = {**os.environ, "HOME": str(tmp_path)}
    result = _run(["--force", "--env", "base"], env=env)
    assert result.returncode == 0
    te_env = tmp_path / ".config" / "my_linux_config" / "components" / "te_env.sh"
    assert te_env.exists(), "te_env.sh 应被生成"
    assert os.access(te_env, os.X_OK), "te_env.sh 应为可执行"
    content = te_env.read_text()
    assert 'export TE_PATH=' in content


def test_dry_run_flag_short(tmp_path):
    """-d 短标志等价于 --dry-run"""
    env = {**os.environ, "HOME": str(tmp_path)}
    result = _run(["-d"], env=env)
    assert result.returncode == 0
    written = list(tmp_path.iterdir())
    assert written == []
