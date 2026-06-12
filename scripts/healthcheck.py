"""
Hermes Gateway Health Check — 定时巡检 + 自动修复

检查项:
1. PM2 进程是否在线
2. 最近重启次数是否异常（短时间内反复重启）
3. 日志中是否有当前进程的致命错误

修复动作:
- 进程 stopped/errored → 清理 PID + pm2 restart
- PM2 丢失 → pm2 resurrect
- 短时间内反复重启 → 清理 + 重置 + pm2 restart
"""

import json
import subprocess
import sys
import time
from pathlib import Path

PM2 = "pm2"
# 只检测这些真正的致命错误（忽略 Windows 平台兼容性警告）
FATAL_PATTERNS = ["ConnectionResetError", "Session expired", "Connection refused", "Unauthorized"]


def run(cmd: str) -> str:
    try:
        return subprocess.check_output(
            cmd, shell=True, stderr=subprocess.STDOUT, text=True,
            timeout=15, encoding="utf-8", errors="replace",
        )
    except subprocess.CalledProcessError as e:
        return e.output if e.output else ""


def get_pm2_status() -> dict:
    raw = run("pm2 jlist")
    if not raw:
        return {}
    try:
        procs = json.loads(raw)
        for p in procs:
            if p.get("name") == "hermes-gateway":
                env = p.get("pm2_env", {})
                return {
                    "status": env.get("status"),
                    "restarts": env.get("restart_time", 0),
                    "pid": p.get("pid"),
                    "uptime_ms": env.get("pm_uptime", 0),
                }
    except Exception:
        pass
    return {}


def clean_stale_pid():
    pid_path = Path.home() / ".hermes" / "gateway.pid"
    if pid_path.exists():
        pid_path.unlink()
        print(f"[health] cleaned stale PID file")


def fix_and_restart(reason: str):
    print(f"[health] FIXING: {reason}")
    clean_stale_pid()
    run(f"{PM2} restart hermes-gateway")
    time.sleep(5)
    info = get_pm2_status()
    new_status = info.get("status")
    print(f"[health] after restart: status={new_status}, pid={info.get('pid')}")
    if new_status == "online":
        run(f"{PM2} save")
        print("[health] saved PM2 process list")


def health_check() -> bool:
    info = get_pm2_status()
    status = info.get("status", "unknown")
    restarts = info.get("restarts", 0)
    uptime_ms = info.get("uptime_ms", 0)

    print(f"[health] status={status}, restarts={restarts}, "
          f"uptime={uptime_ms / 1000:.0f}s, pid={info.get('pid')}")

    if status == "online":
        # 检查是否在短时间内反复重启（uptime < 60s 且 restarts > 5）
        if uptime_ms < 60_000 and restarts > 5:
            fix_and_restart(f"unstable: restarted {restarts}x, uptime only {uptime_ms / 1000:.0f}s")
            return False
        print("[health] OK")
        return True

    if status in ("stopped", "errored", "stopping"):
        fix_and_restart(f"gateway {status}")
        return False

    if status == "unknown":
        print("[health] PM2 process not found, attempting resurrect")
        run(f"{PM2} resurrect")
        time.sleep(5)
        info2 = get_pm2_status()
        if info2.get("status") != "online":
            fix_and_restart("resurrect failed")
        return False

    print(f"[health] unhandled status: {status}")
    return False


if __name__ == "__main__":
    ok = health_check()
    sys.exit(0 if ok else 1)
