import os
import pty
import select
import subprocess
import time
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


def _run_interactive(script: str, keystrokes: bytes, env: dict | None = None) -> str:
    merged_env = {**os.environ, **(env or {})}
    merged_env.setdefault("TERM", "xterm-256color")
    merged_env.setdefault("PS1", "$ ")

    master, slave = pty.openpty()
    process = subprocess.Popen(
        ["bash", "--noprofile", "--norc", "-i"],
        cwd=ROOT,
        stdin=slave,
        stdout=slave,
        stderr=slave,
        env=merged_env,
    )
    os.close(slave)

    def read_all(delay: float = 0.2) -> bytes:
        end = time.time() + delay
        data = b""
        while time.time() < end:
            ready, _, _ = select.select([master], [], [], 0.05)
            if master not in ready:
                continue
            try:
                chunk = os.read(master, 65536)
            except OSError:
                break
            if not chunk:
                break
            data += chunk
            end = time.time() + delay
        return data

    try:
        read_all()
        os.write(master, script.encode())
        read_all(0.5)
        os.write(master, keystrokes)
        output = read_all(0.5)
    finally:
        process.terminate()
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)

    return output.decode("utf-8", errors="replace")


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


def test_backspace_handler_redraws_right_time_after_line_edit():
    result = _run(
        (
            f'source "{PROMPT_LIB}" && '
            'export MLC_FORCE_INTERACTIVE_PROMPT=1 && '
            'export MY_LINUX_CURRENT_ENV=docker && '
            'export MY_LINUX_RIGHT_TIME=1 && '
            'export MLC_PROMPT_CLOCK_TEXT=12:34:56 && '
            'export MLC_PROMPT_CLOCK_COLUMNS=20 && '
            'READLINE_LINE=abcd && '
            'READLINE_POINT=4 && '
            '__my_linux_right_time_backspace && '
            'printf "\nline=%s\npoint=%s" "$READLINE_LINE" "$READLINE_POINT"'
        )
    )

    assert result.returncode == 0
    assert result.stdout == "\x1b[s\x1b[13G12:34:56\x1b[u\nline=abc\npoint=3"


def test_del_key_redraws_time_in_interactive_shell():
    output = _run_interactive(
        (
            f'source "{PROMPT_LIB}"\n'
            'export MLC_FORCE_INTERACTIVE_PROMPT=1 MY_LINUX_CURRENT_ENV=docker MY_LINUX_RIGHT_TIME=1 '\
            'MLC_PROMPT_CLOCK_TEXT=12:34:56 COLUMNS=20\n'
            'enable_right_time_prompt\n'
            'abcd'
        ),
        b'\x7f',
    )

    assert "\x1b[s\x1b[13G12:34:56\x1b[u" in output
    assert output.endswith("abc")


def test_del_key_redraws_time_after_cursor_move():
    output = _run_interactive(
        (
            f'source "{PROMPT_LIB}"\n'
            'export MLC_FORCE_INTERACTIVE_PROMPT=1 MY_LINUX_CURRENT_ENV=docker MY_LINUX_RIGHT_TIME=1 '
            'MLC_PROMPT_CLOCK_TEXT=12:34:56 COLUMNS=20\n'
            'enable_right_time_prompt\n'
            'abcd'
        ),
        b'\x1b[D\x7f',
    )

    assert "\x1b[s\x1b[13G12:34:56\x1b[u" in output
    assert output.endswith("abd\x08")