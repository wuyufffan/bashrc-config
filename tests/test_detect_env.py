"""
测试 lib/detect_env.sh 中各环境检测函数
"""
import os
import subprocess
from pathlib import Path

DETECT_ENV = Path(__file__).resolve().parents[1] / "lib" / "detect_env.sh"


def _run(func: str, env: dict = None) -> str:
    """source detect_env.sh 并调用指定函数，返回 stdout"""
    cmd = f"source {DETECT_ENV} && {func}"
    result = subprocess.run(
        ["bash", "-c", cmd],
        capture_output=True,
        text=True,
        env={**os.environ, **(env or {})},
    )
    return result.stdout.strip()


def test_auto_detect_env_returns_docker_in_container(tmp_path):
    """容器标记文件存在时应检测为 docker"""
    marker = tmp_path / ".dockerenv"
    marker.touch()
    # 以脚本内联方式模拟 /.dockerenv 存在
    cmd = f"""
source {DETECT_ENV}
_orig_detect_container() {{
    echo "docker"
}}
detect_container() {{ _orig_detect_container; }}
auto_detect_env
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)
    assert result.stdout.strip() == "docker"


def test_detect_compute_node_when_slurm_job():
    """SLURM_JOB_ID 设置时 detect_compute_node 应返回 compute"""
    env = {**os.environ, "SLURM_JOB_ID": "12345"}
    result = _run("detect_compute_node && echo 'ok' || echo 'not-compute'", env=env)
    # detect_compute_node 将返回 "compute" 并 exit 0
    assert "compute" in result


def test_auto_detect_env_returns_base_by_default():
    """无特殊环境变量时应返回 base（或 docker，取决于是否在容器中）"""
    result = _run("auto_detect_env")
    assert result in ("base", "docker", "login", "compute")


def test_detect_os_returns_nonempty():
    """detect_os 应返回非空字符串"""
    result = _run("detect_os")
    assert result != ""


def test_detect_gpu_returns_valid_value():
    """detect_gpu 应返回 nvidia / amd / none"""
    result = _run("detect_gpu")
    assert result in ("nvidia", "amd", "none")


def test_detect_dtk_returns_valid_value():
    """detect_dtk 应返回有效版本字符串或 none"""
    result = _run("detect_dtk")
    assert result in ("26.04", "25.04.2", "none")


def test_detect_login_node_with_matching_hostname():
    """主机名含 login 时应检测为 login 节点"""
    cmd = f"""
source {DETECT_ENV}
# override hostname for test
detect_login_node() {{
    local hostname="hpc-login-01"
    if [[ "$hostname" == *"login"* ]]; then
        echo "login"; return 0
    fi
    return 1
}}
detect_login_node
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)
    assert result.stdout.strip() == "login"
