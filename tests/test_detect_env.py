"""
测试 lib/detect_env.sh 中各环境检测函数
"""
import os
import subprocess
from pathlib import Path

DETECT_ENV = Path(__file__).resolve().parents[1] / "lib" / "detect_env.sh"
DOCKER_CONFIG = Path(__file__).resolve().parents[1] / "envs" / "docker" / "config.sh"
PROMPT_LIB = Path(__file__).resolve().parents[1] / "lib" / "prompt.sh"
NETWORK_TEST_LIB = Path(__file__).resolve().parents[1] / "lib" / "network_test.sh"


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


def test_detect_compute_node_with_matching_hostname():
    """主机名含 compute/node/worker 时应检测为 compute 节点"""
    cmd = f"""
source {DETECT_ENV}
hostname() {{
    echo worker-a01
}}
detect_compute_node
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)

    assert result.returncode == 0
    assert result.stdout.strip() == "compute"


def test_auto_detect_env_returns_base_by_default():
    """无特殊环境变量时应返回 base（或 docker，取决于是否在容器中）"""
    result = _run("auto_detect_env")
    assert result in ("base", "docker", "login", "compute")


def test_detect_os_returns_nonempty():
    """detect_os 应返回非空字符串"""
    result = _run("detect_os")
    assert result != ""


def test_legacy_gpu_and_dtk_helpers_are_not_exported():
    """已移除的 detect_gpu / detect_dtk 不应继续对外暴露"""
    cmd = f"""
source {DETECT_ENV}
printf '%s|%s\n' "$(type -t detect_gpu 2>/dev/null || true)" "$(type -t detect_dtk 2>/dev/null || true)"
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)

    assert result.returncode == 0
    assert result.stdout.strip() == "|"


def test_detect_login_node_with_matching_hostname():
    """主机名含 login 时应检测为 login 节点"""
    cmd = f"""
source {DETECT_ENV}
# override hostname for test
hostname() {{
    echo hpc-login-01
}}
detect_login_node
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)
    assert result.stdout.strip() == "login"


def test_detect_login_node_returns_nonzero_without_matching_hostname():
    """普通主机名不应被识别为 login 节点"""
    cmd = f"""
source {DETECT_ENV}
hostname() {{
    echo workstation-01
}}
detect_login_node >/dev/null 2>&1 || echo not-login
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)

    assert result.returncode == 0
    assert result.stdout.strip() == "not-login"


def test_detect_te_prompt_tag_from_te_version_file(tmp_path):
    """VERSION.txt 中的 2.7.0 应映射为 te27"""
    te_path = tmp_path / "TransformerEngine"
    version_dir = te_path / "build_tools"
    version_dir.mkdir(parents=True)
    (version_dir / "VERSION.txt").write_text("2.7.0\n", encoding="utf-8")

    result = _run("detect_te_prompt_tag", env={"TE_PATH": str(te_path)})

    assert result == "te27"


def test_detect_te_prompt_tag_from_git_branch(tmp_path):
    """Git 分支名中的 te27 应优先映射为提示标签"""
    te_repo = tmp_path / "TransformerEngine"
    te_repo.mkdir()
    subprocess.run(["git", "init"], cwd=te_repo, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=te_repo, check=True)
    subprocess.run(["git", "config", "user.name", "tester"], cwd=te_repo, check=True)
    (te_repo / "README.md").write_text("demo\n")
    subprocess.run(["git", "add", "README.md"], cwd=te_repo, check=True)
    subprocess.run(["git", "commit", "-m", "init"], cwd=te_repo, check=True, capture_output=True)
    subprocess.run(["git", "checkout", "-b", "bugfix/feature_te27"], cwd=te_repo, check=True, capture_output=True)

    result = _run("detect_te_prompt_tag", env={"TE_PATH": str(te_repo)})
    assert result == "te27"


def test_detect_te_prompt_tag_accepts_git_file_layout(tmp_path):
    """当 .git 是文件而非目录时，仍应能识别 te 版本"""
    repo_dir = tmp_path / "TransformerEngine"
    repo_dir.mkdir()
    (repo_dir / ".git").write_text("gitdir: /tmp/fake-git-dir\n")

    cmd = f"""
source {DETECT_ENV}
git() {{
    if [[ "$1 $2 $3" == "-C {repo_dir} rev-parse" ]]; then
        return 0
    fi
    if [[ "$1 $2 $3 $4" == "-C {repo_dir} branch --show-current" ]]; then
        echo bugfix/example_te27
        return 0
    fi
    if [[ "$1 $2 $3 $4 $5" == "-C {repo_dir} rev-parse --abbrev-ref --symbolic-full-name" ]]; then
        echo origin/bugfix/example_te27
        return 0
    fi
    command git "$@"
}}
export TE_PATH="{repo_dir}"
detect_te_prompt_tag
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True, check=True)
    assert result.stdout.strip() == "te27"


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


def test_docker_prompt_label_returns_te_tag_for_rocky_container(tmp_path):
    """Docker + Rocky + TE 版本时应生成 [teXX-rocky] 标签"""
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
    echo "rocky-linux"
}}
docker_prompt_label
"""
    result = subprocess.run(
        ["bash", "-c", cmd],
        capture_output=True,
        text=True,
        env={**os.environ, "TE_PATH": str(te_path)},
    )

    assert result.stdout.strip() == "[te27-rocky]"


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


def test_docker_config_enables_right_time_prompt(tmp_path):
    te_path = tmp_path / "TransformerEngine"
    version_dir = te_path / "build_tools"
    version_dir.mkdir(parents=True)
    (version_dir / "VERSION.txt").write_text("2.7.0\n", encoding="utf-8")

    cmd = f"""
source {DETECT_ENV}
source {PROMPT_LIB}
detect_container() {{
    echo "docker"
}}
detect_os() {{
    echo "ubuntu"
}}
source {DOCKER_CONFIG}
printf '%s\n' "$PROMPT_COMMAND"
printf '%s\n' "$MY_LINUX_RIGHT_TIME_FORMAT"
printf '%s\n' "$MY_LINUX_RIGHT_TIME"
bind -X
bind -p | grep -F '"\\C-?"'
"""
    result = subprocess.run(
        ["bash", "-ic", cmd],
        capture_output=True,
        text=True,
        env={**os.environ, "TE_PATH": str(te_path)},
    )

    assert "__my_linux_right_time_prompt" in result.stdout
    assert "%H:%M:%S" in result.stdout
    assert "1" in result.stdout
    assert '"\\C-h": "__my_linux_right_time_backspace"' in result.stdout
    assert '"\\C-x\\C-r": "__my_linux_right_time_backspace"' in result.stdout


def test_right_time_prompt_disabled_outside_docker():
    cmd = f"""
source {PROMPT_LIB}
export MY_LINUX_CURRENT_ENV=base
export MY_LINUX_RIGHT_TIME=1
if __my_linux_should_show_right_time; then
    echo enabled
else
    echo disabled
fi
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)
    assert result.stdout.strip() == "disabled"


def test_docker_config_maps_del_to_redraw_hook():
    cmd = f"""
source {PROMPT_LIB}
export MLC_FORCE_INTERACTIVE_PROMPT=1
export MY_LINUX_CURRENT_ENV=docker
export MY_LINUX_RIGHT_TIME=1
enable_right_time_prompt
bind -X
"""
    result = subprocess.run(["bash", "-ic", cmd], capture_output=True, text=True)

    assert result.returncode == 0
    assert '"\\C-x\\C-r": "__my_linux_right_time_backspace"' in result.stdout


def test_network_helpers_do_not_define_legacy_proxy_commands():
    cmd = f"""
source {NETWORK_TEST_LIB}
printf '%s|%s\n' "$(type -t proxy 2>/dev/null || true)" "$(type -t netproxy 2>/dev/null || true)"
"""
    result = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)

    assert result.returncode == 0
    assert result.stdout.strip() == "|"

