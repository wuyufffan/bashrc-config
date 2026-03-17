import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROMPT_LIB = ROOT / "lib" / "prompt.sh"
DOCKER_CONFIG = ROOT / "envs" / "docker" / "config.sh"


def _run(script: str, env: dict | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", "-lc", script],
        cwd=ROOT,
        capture_output=True,
        text=True,
        env={**os.environ, **(env or {})},
    )


def test_detect_te_prompt_name_from_version_file(tmp_path):
    te_root = tmp_path / "TransformerEngine"
    version_dir = te_root / "build_tools"
    version_dir.mkdir(parents=True)
    (version_dir / "VERSION.txt").write_text("2.7.0\n")

    result = _run(
        f'source "{PROMPT_LIB}" && TE_PATH="{te_root}" detect_te_prompt_name'
    )

    assert result.returncode == 0
    assert result.stdout.strip() == "te27"


def test_detect_container_prompt_name_prefers_os_release_id():
    result = _run(f'source "{PROMPT_LIB}" && detect_container_prompt_name')

    assert result.returncode == 0
    assert result.stdout.strip() == "ubuntu"


def test_build_docker_prompt_label_combines_te_and_container_name(tmp_path):
    te_root = tmp_path / "TransformerEngine"
    version_dir = te_root / "build_tools"
    version_dir.mkdir(parents=True)
    (version_dir / "VERSION.txt").write_text("2.7.0\n")

    result = _run(
        f'source "{PROMPT_LIB}" && TE_PATH="{te_root}" build_docker_prompt_label'
    )

    assert result.returncode == 0
    assert result.stdout.strip() == "[te27-ubuntu]"


def test_docker_config_enables_te_prompt_and_clock():
    content = DOCKER_CONFIG.read_text()

    assert "build_docker_prompt_label" in content
    assert "enable_docker_right_prompt_clock" in content


def test_enable_docker_right_prompt_clock_sets_prompt_command():
    result = _run(
        f'source "{PROMPT_LIB}" && enable_docker_right_prompt_clock && printf "%s" "$PROMPT_COMMAND"',
        env={"TERM": "xterm-256color", "MLC_FORCE_INTERACTIVE_PROMPT": "1"},
    )

    assert result.returncode == 0
    assert result.stdout.strip() == "__my_linux_right_time_prompt"


def test_prompt_clock_renders_right_aligned_without_newline_and_preserves_status():
    result = _run(
        (
            f'source "{PROMPT_LIB}" && '
            'false && :; '
            '_mlc_prompt_command_with_clock; '
            'status=$?; '
            'printf "\nstatus=%s" "$status"'
        ),
        env={
            "MLC_FORCE_INTERACTIVE_PROMPT": "1",
            "MY_LINUX_CURRENT_ENV": "docker",
            "MY_LINUX_RIGHT_TIME": "1",
            "MLC_PROMPT_CLOCK_TEXT": "12:34:56",
            "MLC_PROMPT_CLOCK_COLUMNS": "20",
        },
    )

    assert result.returncode == 0
    assert result.stdout == "\x1b[s\x1b[13G12:34:56\x1b[u\nstatus=1"


def test_prompt_clock_falls_back_to_first_column_when_terminal_is_too_narrow():
    result = _run(
        (
            f'source "{PROMPT_LIB}" && '
            '_mlc_prompt_command_with_clock'
        ),
        env={
            "MLC_FORCE_INTERACTIVE_PROMPT": "1",
            "MY_LINUX_CURRENT_ENV": "docker",
            "MY_LINUX_RIGHT_TIME": "1",
            "MLC_PROMPT_CLOCK_TEXT": "12:34:56",
            "MLC_PROMPT_CLOCK_COLUMNS": "4",
        },
    )

    assert result.returncode == 0
    assert result.stdout == "\x1b[s\x1b[1G12:34:56\x1b[u"