import os
import subprocess
from pathlib import Path


def test_history_search_bindings(tmp_path):
    repo_root = Path(__file__).resolve().parents[1]
    base_config = repo_root / "envs" / "base" / "config.sh"

    # Use a clean HOME to avoid user inputrc/bashrc side effects
    env = {
        "HOME": str(tmp_path),
        # Minimal environment to avoid locale/charset surprises
        "LANG": "C",
        "LC_ALL": "C",
        "TERM": "xterm-256color",
    }
    # Preserve PATH so bash can find binaries
    if "PATH" in os.environ:
        env["PATH"] = os.environ["PATH"]

    cmd = [
        "bash",
        "--noprofile",
        "--norc",
        "-lc",
        # Enable readline, source config, then dump bindings
        f'set -o emacs; source "{base_config}" >/dev/null 2>&1; bind -p'
    ]
    result = subprocess.run(cmd, capture_output=True, env=env)
    assert result.returncode == 0, result.stderr.decode(errors="ignore")

    out = (result.stdout + result.stderr).decode(errors="ignore")
    # bind -p may emit \e or \M-[ depending on locale/term; accept both
    assert ('"\\e[A": history-search-backward' in out) or ('"\\M-[A": history-search-backward' in out)
    assert ('"\\e[B": history-search-forward' in out) or ('"\\M-[B": history-search-forward' in out)
