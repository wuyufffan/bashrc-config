import os
import subprocess
from pathlib import Path

COMPLETIONS_LIB = Path(__file__).resolve().parents[1] / "lib" / "completions.sh"


def _run_bash(script: str, env: dict | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", "-c", script],
        capture_output=True,
        text=True,
        env={**os.environ, **(env or {})},
    )


def test_completions_register_complete_functions():
    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
complete -p bashrc
complete -p proxy
complete -p te
"""
    )

    assert result.returncode == 0
    assert "complete -F _bashrc_completion bashrc" in result.stdout
    assert "complete -F _proxy_completion proxy" in result.stdout
    assert "complete -F _te_completion te" in result.stdout


def test_bashrc_completion_lists_edit_indices():
    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
COMP_WORDS=(bashrc edit '')
COMP_CWORD=2
_bashrc_completion
printf '%s\n' "${{COMPREPLY[@]}}"
"""
    )

    assert result.returncode == 0
    assert result.stdout.splitlines() == ["1", "2", "3", "4", "5", "6", "7", "8"]


def test_proxy_completion_lists_commands():
    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
COMP_WORDS=(proxy '')
COMP_CWORD=1
_proxy_completion
printf '%s\n' "${{COMPREPLY[@]}}"
"""
    )

    assert result.returncode == 0
    assert result.stdout.splitlines() == ["on", "off", "set", "status", "help"]


def test_te_log_completion_lists_timestamps(tmp_path):
    logs_root = tmp_path / "logs"
    (logs_root / "20260313_091738").mkdir(parents=True)
    (logs_root / "20260312_101815").mkdir(parents=True)

    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
COMP_WORDS=(te log list '')
COMP_CWORD=3
_te_completion
printf '%s\n' "${{COMPREPLY[@]}}"
""",
        env={"WORK_SPACE": str(tmp_path)},
    )

    assert result.returncode == 0
    assert result.stdout.splitlines() == ["20260313_091738", "20260312_101815"]


def test_te_summary_completion_lists_l0torch_logs(tmp_path):
    log_path = tmp_path / "logs" / "20260313_091738" / "l0torch" / "L0_pytorch_unittest_nmz76.log"
    log_path.parent.mkdir(parents=True)
    log_path.write_text("test", encoding="utf-8")

    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
COMP_WORDS=(te summary '')
COMP_CWORD=2
_te_completion
printf '%s\n' "${{COMPREPLY[@]}}"
""",
        env={"WORK_SPACE": str(tmp_path)},
    )

    assert result.returncode == 0
    lines = result.stdout.splitlines()
    assert str(log_path) in lines
    assert "--brief" in lines
    assert "--detailed" in lines