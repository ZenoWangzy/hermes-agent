#!/bin/bash
# Hermes Gateway 连接级健康检查 — 定时巡检 Discord(等)连接,断了自动 kickstart
#
# 数据源:~/.hermes/gateway_state.json (hermes gateway 运行时状态,字段 platforms.<name>.state)
# 策略:
#   - platform state != connected  →  launchctl kickstart -k ai.hermes.gateway
#   - 含 300s kickstart 冷却,防反复重启
#   - state 文件陈旧只告警不重启(hermes 只在状态变化时写文件,陈旧 ≠ 断连)
#
# 由 ai.hermes.health.plist (StartInterval 30) 定时调用。
# 对标 openclaw 的 unified-health-check.sh,补齐 hermes 缺失的连接级自愈。

set -u

HERMES_LABEL="${HERMES_LAUNCHD_LABEL:-ai.hermes.gateway}"
STATE_FILE="${HERMES_STATE_FILE:-$HOME/.hermes/gateway_state.json}"
STATE_DIR="$(dirname "$STATE_FILE")"
LOG_FILE="${HERMES_HEALTH_LOG:-$HOME/.hermes/logs/health-check.log}"
LAST_KICKSTART_FILE="$STATE_DIR/health-last-kickstart-at"
KICKSTART_COOLDOWN="${HERMES_KICKSTART_COOLDOWN:-300}"        # 5 分钟,防反复重启
STALE_WARN_SECONDS="${HERMES_STATE_STALE_SECONDS:-1800}"      # 30 分钟无更新才告警
WATCH_PLATFORM="${HERMES_WATCH_PLATFORM:-discord}"

mkdir -p "$(dirname "$LOG_FILE")" "$STATE_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$LOG_FILE"; }

# 读 platform 状态 + 更新时间,输出 "state<TAB>updated_at"
platform_state() {
  python3 - "$STATE_FILE" "$1" <<'PY' 2>/dev/null
import json, sys
from datetime import datetime, timezone
try:
    d = json.load(open(sys.argv[1]))
    p = d.get("platforms", {}).get(sys.argv[2], {})
    state = p.get('state', 'unknown')
    raw = p.get('updated_at') or d.get('updated_at') or ''
    epoch = ''
    if raw:
        try:
            s = raw.replace('Z', '+00:00')
            dt = datetime.fromisoformat(s)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)   # naive 视作 UTC,避免按本地时区误解析
            epoch = str(int(dt.timestamp()))
        except Exception:
            epoch = ''   # 解析失败:交由上层按"无时间戳"处理(不误判 stale)
    print(f"{state}\t{epoch}")
except Exception:
    print("unknown\t")
PY
}

# 冷却期内返回 0(真),否则返回 1
cooldown_active() {
  local now last elapsed
  now=$(date +%s)
  [[ -f "$LAST_KICKSTART_FILE" ]] || return 1
  last=$(tr -dc '0-9' <"$LAST_KICKSTART_FILE" 2>/dev/null)   # 只保留数字,防损坏文件污染算术
  [[ -n "$last" ]] || return 1                               # 空/损坏 → 视为不在冷却(允许 kickstart)
  elapsed=$((now - last))
  (( elapsed < KICKSTART_COOLDOWN )) && return 0
  return 1
}

kickstart() {
  local reason="$1"
  if cooldown_active; then
    log "[skip] $reason — kickstart cooldown active (<= ${KICKSTART_COOLDOWN}s)"
    return 0
  fi
  log "[fix] kickstart $HERMES_LABEL: $reason"
  launchctl kickstart -k "gui/$(id -u)/$HERMES_LABEL" 2>>"$LOG_FILE"
  date +%s >"$LAST_KICKSTART_FILE"
}

main() {
  if [[ ! -f "$STATE_FILE" ]]; then
    log "[warn] state file missing: $STATE_FILE"
    kickstart "state file missing"
    return
  fi

  local state updated
  IFS=$'\t' read -r state updated <<<"$(platform_state "$WATCH_PLATFORM")"

  # 主逻辑:平台标记非 connected → 视为断连,重启网关
  if [[ "$state" != "connected" ]]; then
    log "[issue] $WATCH_PLATFORM state='$state' (expected connected)"
    kickstart "$WATCH_PLATFORM disconnected (state=$state)"
    return
  fi

  # state=connected:检查文件是否严重陈旧(只告警,不重启)
  # 保守策略 — hermes 仅在状态变化时写文件,陈旧可能只是长期稳定无变化,贸然重启会误杀健康进程
  # updated 现在已是 UTC epoch(platform_state python 统一解析 ISO8601 含时区,避免本地时区偏差)
  if [[ -n "$updated" ]]; then
    local now stale
    now=$(date +%s); stale=$((now - updated))
    if (( stale > STALE_WARN_SECONDS )); then
      log "[warn] $WATCH_PLATFORM connected but state untouched ${stale}s (> ${STALE_WARN_SECONDS}s) — possibly idle, NOT restarting"
    fi
  fi

  log "[ok] $WATCH_PLATFORM connected"
}

main "$@"
