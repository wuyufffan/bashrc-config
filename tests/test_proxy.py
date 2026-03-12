"""
测试 lib/proxy.sh 中的代理管理命令
"""
import os
import subprocess
from pathlib import Path

PROXY_LIB = Path(__file__).resolve().parents[1] / "lib" / "proxy.sh"


def _run(script: str, env: dict = None) -> subprocess.CompletedProcess:
    cmd = f"source {PROXY_LIB} && {script}"
    return subprocess.run(
        ["bash", "-c", cmd],
        capture_output=True,
        text=True,
        env={**os.environ, **(env or {})},
    )


def test_proxy_on_sets_all_proxy_vars():
    result = _run("proxy on >/dev/null && printf '%s|%s|%s\n' \"$http_proxy\" \"$https_proxy\" \"$all_proxy\"")

    assert result.returncode == 0
    assert result.stdout.strip() == "http://127.0.0.1:7890|http://127.0.0.1:7890|http://127.0.0.1:7890"


def test_proxy_off_unsets_proxy_vars():
    env = {
        **os.environ,
        "http_proxy": "http://127.0.0.1:7890",
        "https_proxy": "http://127.0.0.1:7890",
        "all_proxy": "http://127.0.0.1:7890",
    }
    result = _run("proxy off >/dev/null && printf '%s|%s|%s\n' \"${http_proxy:-}\" \"${https_proxy:-}\" \"${all_proxy:-}\"", env=env)

    assert result.returncode == 0
    assert result.stdout.strip() == "||"


def test_proxy_set_updates_port_and_applies_when_enabled():
    result = _run("proxy on >/dev/null && proxy set 8080 >/dev/null && printf '%s\n' \"$http_proxy\"")

    assert result.returncode == 0
    assert result.stdout.strip() == "http://127.0.0.1:8080"


def test_proxy_set_without_port_uses_default_port():
    result = _run("proxy set 8080 >/dev/null && proxy set >/dev/null && proxy on >/dev/null && printf '%s\n' \"$http_proxy\"")

    assert result.returncode == 0
    assert result.stdout.strip() == "http://127.0.0.1:7890"


def test_proxy_status_reports_enabled_and_port():
    result = _run("proxy set 9090 >/dev/null && proxy on >/dev/null && proxy status")

    assert result.returncode == 0
    assert "代理状态: 已开启" in result.stdout
    assert "代理端口: 9090" in result.stdout


def test_proxy_status_reports_disabled_and_default_port():
    result = _run("proxy off >/dev/null && proxy status")

    assert result.returncode == 0
    assert "代理状态: 已关闭" in result.stdout
    assert "代理端口: 7890" in result.stdout


def test_proxy_help_shows_usage_when_called_explicitly():
    result = _run("proxy help")

    assert result.returncode == 0
    assert "用法: proxy <command> [port]" in result.stdout
    assert "proxy set 8080" in result.stdout


def test_proxy_without_args_defaults_to_help():
    result = _run("proxy")

    assert result.returncode == 0
    assert "用法: proxy <command> [port]" in result.stdout


def test_proxy_set_rejects_invalid_port():
    result = _run("proxy set abc")

    assert result.returncode == 1
    assert "无效端口" in result.stdout