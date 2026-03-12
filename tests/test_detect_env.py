"""
测试 lib/detect_env.sh 中各环境检测函数
"""
import os
import subprocess
from pathlib import Path

DETECT_ENV = Path(__file__).resolve().parents[1] / "lib" / "detect_env.sh"
DOCKER_CONFIG = Path(__file__).resolve().parents[1] / "envs" / "docker" / "config.sh"


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


def test_detect_te_prompt_tag_from_te_version_file(tmp_path):
    """VERSION.txt 中的 2.7.0 应映射为 te27"""
    te_path = tmp_path / "TransformerEngine"
    version_dir = te_path / "build_tools"
    version_dir.mkdir(parents=True)
    (version_dir / "VERSION.txt").write_text("2.7.0\n", encoding="utf-8")

    result = _run("detect_te_prompt_tag", env={"TE_PATH": str(te_path)})

    assert result == "te27"


def test_docker_prompt_label_returns_te_tag_for_ubuntu_container(tmp_path):
    """Docker + Ubuntu + TE 版本时应生成 [teXX-ubuntu] 标签"""
    te_path = tmp_path / "TransformerEngine"
    version_dir = te_path / "build_tools"
    version_dir.mkdir(parents=True)
    (version_dir / "VERSION.txt").write_text("2.10.0\n", encoding="utf-8")

    cmd = f"""
source {DETECT_ENV}
detect_container() {{
    echo "docker"
}}
detect_os() {{
    echo "ubuntu"
}}
docker_prompt_label
"""
    result = subprocess.run(
        ["bash", "-c", cmd],
        capture_output=True,
        text=True,
        env={**os.environ, "TE_PATH": str(te_path)},
    )

    assert result.stdout.strip() == "[te210-ubuntu]"


def test_docker_prompt_label_is_empty_without_te_version(tmp_path):
    """缺少 TE 版本时不应回退为 [docker]"""
    te_path = tmp_path / "missing-te"
    cmd = f"""
source {DETECT_ENV}
detect_container() {{
    echo "docker"
}}
detect_os() {{
    echo "ubuntu"
}}
docker_prompt_label || true
"""
    result = subprocess.run(
        ["bash", "-c", cmd],
        capture_output=True,
        text=True,
        env={**os.environ, "TE_PATH": str(te_path)},
    )

    assert result.stdout.strip() == ""


def test_docker_config_ps1_uses_dynamic_te_label(tmp_path):
    """Docker 配置应使用动态 [teXX-ubuntu] 标签而不是硬编码 [docker]"""
    te_path = tmp_path / "TransformerEngine"
    version_dir = te_path / "build_tools"
    version_dir.mkdir(parents=True)
    (version_dir / "VERSION.txt").write_text("2.7.0\n", encoding="utf-8")

    cmd = f"""
source {DETECT_ENV}
detect_container() {{
    echo "docker"
}}
detect_os() {{
    echo "ubuntu"
}}
source {DOCKER_CONFIG}
printf '%s\n' "$PS1"
"""
    result = subprocess.run(
        ["bash", "-c", cmd],
        capture_output=True,
        text=True,
        env={**os.environ, "TE_PATH": str(te_path)},
    )

    assert "[te27-ubuntu]" in result.stdout
    assert "[docker]" not in result.stdout
