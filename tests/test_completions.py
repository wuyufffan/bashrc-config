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
complete -p te
"""
    )

    assert result.returncode == 0
    assert "complete -F _bashrc_completion bashrc" in result.stdout
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
    assert result.stdout.splitlines() == ["1", "2", "3", "4", "5", "6", "7"]


def test_proxy_completion_is_not_registered():
    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
complete -p proxy >/dev/null 2>&1
printf '%s\n' "$?"
"""
    )

    assert result.returncode == 0
    assert result.stdout.splitlines() == ["1"]


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


def test_te_sum_completion_lists_l0torch_log_names(tmp_path):
    log_path = tmp_path / "logs" / "20260313_091738" / "l0torch" / "L0_pytorch_unittest_nmz76.log"
    log_path.parent.mkdir(parents=True)
    log_path.write_text("test", encoding="utf-8")

    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
COMP_WORDS=(te sum '')
COMP_CWORD=2
_te_completion
printf '%s\n' "${{COMPREPLY[@]}}"
""",
        env={"WORK_SPACE": str(tmp_path)},
    )

    assert result.returncode == 0
    lines = result.stdout.splitlines()
    assert "L0_pytorch_unittest_nmz76.log" in lines
    assert "summary" not in lines
    assert "--brief" not in lines
    assert "--detailed" not in lines


def test_te_sum_second_arg_lists_levels_and_keywords(tmp_path):
    logs_root = tmp_path / "logs"
    log_path = logs_root / "20260313_091738" / "l0torch" / "L0_pytorch_unittest_nmz76.log"
    log_path.parent.mkdir(parents=True)
    log_path.write_text(
        "\n".join(
            [
                "+ python3 -m pytest -v -s /workspace/TransformerEngine/tests/pytorch/test_sanity.py",
                "FAILED tests/pytorch/test_sanity.py::test_sanity_drop_path[param_a]",
                "FAILED tests/pytorch/test_sanity.py::test_sanity_drop_path[param_b]",
            ]
        ),
        encoding="utf-8",
    )
    histfile = tmp_path / ".bash_history"
    histfile.write_text(
        "te sum L0_pytorch_unittest_nmz76.log test_sanity_layernorm_linear\n",
        encoding="utf-8",
    )

    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
COMP_WORDS=(te sum L0_pytorch_unittest_nmz76.log '')
COMP_CWORD=3
_te_completion
printf '%s\n' "${{COMPREPLY[@]}}"
""",
        env={"WORK_SPACE": str(tmp_path), "HISTFILE": str(histfile)},
    )

    assert result.returncode == 0
    lines = result.stdout.splitlines()
    assert "l1" in lines
    assert "l2" in lines
    assert "l3" in lines
    assert "test_sanity_layernorm_linear" in lines
    assert "test_sanity.py" in lines
    assert "test_sanity_drop_path" in lines
    assert "test_sanity.py::test_sanity_drop_path" in lines


def test_te_help_completion_lists_named_subcommands():
    result = _run_bash(
        f"""
source {COMPLETIONS_LIB}
COMP_WORDS=(te help '')
COMP_CWORD=2
_te_completion
printf '%s\n' "${{COMPREPLY[@]}}"
"""
    )

    assert result.returncode == 0
    assert result.stdout.splitlines() == ["run", "log", "build", "rebuild", "sum", "old"]