#!/bin/bash
#================================================================================
# 每日清理脚本 / Daily Cleanup Script / デイリークリーンアップスクリプト
#================================================================================
# 
# ファイル名: daily_cleanup.sh
# 作成日: 2026-05-01
# 更新日: 2026-05-01
# 作成者: Professor X <andyopenclaw2026+x@gmail.com>
# 用途: サーバー安定運用のための定期メンテナンス
#       Server stability maintenance / サーバー安定運用の定期メンテ
#
# 【概要 / Summary / 概要】
# このスクリプトは、Gmail-MCPプロセスとChromiumブラウザの定期的なクリーンアップ
# を自動化し、ディスク容量とメモリ使用量を管理します。
# This script automates cleanup of Gmail-MCP processes and Chromium browsers,
# managing disk space and memory usage for server stability.
#
# 【機能 / Features / 機能】
# 1. エージェントタスクの停止（新しいタスクの masuk を防止）
#    Stop agent tasks to prevent new operations during cleanup.
#    清理时停止Agent任务，防止新操作进入。
#
# 2. Gmail-MCP / Chromium プロセスの安全な終了
#    Graceful and forced cleanup of Gmail-MCP and Chromium processes.
#    Gmail-MCP / Chromium 进程的优雅和强制清理。
#
# 3. ブラウザロックファイルの削除
#    Remove stale browser singleton lock files.
#    清理浏览器残留锁文件。
#
# 4. systemd ジャーナルログの自動削除（3日間保持）
#    Auto-purge systemd journal logs (keep 3 days).
#    systemd日志自动清理（保留3天）。
#
# 5. 一時ファイルの削除
#    Remove temporary node compilation cache.
#    清理临时文件（node编译缓存）。
#
# 6. ディスク使用量に応じた段階的キャッシュクリア
#    Tiered cache cleanup based on disk usage thresholds:
#    - >80%: npm cache + system cache
#    - >90%: Playwright browser cache (Chromium)
#
# 【使用方法 / Usage / 使用方法】
#   # 直接実行 / Direct execution / 直接执行:
#   bash /root/daily_cleanup.sh
#
#   # Cron 登録（毎日06:00 JST実行）:
#   0 6 * * * /root/daily_cleanup.sh >> /var/log/daily_cleanup.log 2>&1
#
# 【cron 設定 / Cron Configuration / Cron 配置】
#   0 6 * * * = 毎日日本時間06:00 / Daily at 06:00 JST / 每日JST时间06:00
#
#================================================================================

#--------------------------------------------------------------------------------
# [0] 状態記録 / Status Logging / 状态记录
#--------------------------------------------------------------------------------
echo "[0] Status Logging / 状態記録 / 状态记录"
date
df -h
free -m

#--------------------------------------------------------------------------------
# [1] エージェントタスクの停止 / Stop Agent Tasks / 停止Agent任务
#--------------------------------------------------------------------------------
echo "[1] Stop Agent Tasks / エージェントタスク停止 / 停止Agent任务"
# systemd 管理下の agent-task-worker を停止
# Stop the systemd-managed agent-task-worker service
# 停止systemd服务管理的agent-task-worker
systemctl stop agent-task-worker || true

# 清理中に新しいタスクが入らないよう30秒待機
# Wait 30s to ensure tasks drain before cleanup
# 等待30秒确保任务收敛后再清理
sleep 30

#--------------------------------------------------------------------------------
# [2] プロセス清理 / Process Cleanup / 进程清理
#--------------------------------------------------------------------------------
echo "[2] Process Cleanup / プロセス清理 / 进程清理"

# ステップ1: シグナル15（SIGTERM）で優しく終了 / Graceful shutdown with SIGTERM
# Send SIGTERM for graceful shutdown of Gmail-MCP and Chromium processes
pkill -15 -f gmail-mcp || true   # Gmail-MCP プロセス終了 / End Gmail-MCP process / 结束Gmail-MCP进程
pkill -15 -f chromium || true    # Chromium ブラウザ終了 / End Chromium browser / 结束Chromium浏览器

# 待機 / Wait / 等待
sleep 10

# ステップ2: 複数インスタンスが残っていた場合、SIGKILL で強制終了
# If multiple instances remain, force kill with SIGKILL
# 仅当仍有多个实例才强制清理（防止误杀单例）
if [ "$(pgrep -f gmail-mcp | wc -l)" -gt 1 ]; then
 pkill -9 -f gmail-mcp            # 強制終了 / Force kill / 强制结束
fi

if [ "$(pgrep -f chromium | wc -l)" -gt 3 ]; then
 pkill -9 -f chromium             # 強制終了 / Force kill / 强制结束
fi

#--------------------------------------------------------------------------------
# [3] ブラウザロックファイルの削除 / Remove Browser Lock Files / 清理浏览器锁文件
#--------------------------------------------------------------------------------
echo "[3] Remove Browser Lock / ブラウザロック削除 / 清理浏览器锁文件"
# SingletonLock は Playwright/Chromium の重複起動防止用ファイル
# SingletonLock prevents multiple browser instances
# 删除残留的浏览器单例锁文件
rm -f /root/.openclaw/browser-existing-session/SingletonLock

#--------------------------------------------------------------------------------
# [4] systemd ジャーナルログの削除 / Purge Systemd Journal Logs / 清理systemd日志
#--------------------------------------------------------------------------------
echo "[4] Purge Journal Logs / ジャーナルログ削除 / 清理systemd日志"
# journalctl --vacuum-time=3d = 3日間より古いログを自動削除
# Auto-delete logs older than 3 days to prevent disk overflow
# 自动删除3天前的日志，防止日志撑爆磁盘
journalctl --vacuum-time=3d || true

#--------------------------------------------------------------------------------
# [5] 一時ファイルの削除 / Remove Temporary Files / 清理临时文件
#--------------------------------------------------------------------------------
echo "[5] Remove Temp Files / 一時ファイル削除 / 清理临时文件"
# node-compile-cache: TypeScript/Node.js コンパイル一時ファイル
# Temporary compilation cache for TypeScript/Node.js
rm -rf /tmp/node-compile-cache || true

#--------------------------------------------------------------------------------
# [6] ディスク使用量に応じた段階的キャッシュクリア
#     Tiered Cache Cleanup Based on Disk Usage / 磁盘占用分级缓存清理
#--------------------------------------------------------------------------------
echo "[6] Disk Usage Check / ディスク使用率チェック / 磁盘使用率检查"

# ディスク使用率取得 / Get disk usage / 获取磁盘使用率
# df / = root partition, awk NR==2 = second line (header), $5 = usage%
USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# 80% 超過: npm cache + system cache 清理
# >80%: Clean npm and system caches to reclaim space
if [ "$USAGE" -gt 80 ]; then
 echo "[!] Disk >80%, cache cleanup / ディスク >80%、キャッシュ清理"
 
 echo "→ npm cache clean"
 npm cache clean --force 2>/dev/null || true   # npm ダウンロードキャッシュ削除 / Remove npm download cache / 删除npm下载缓存

 echo "→ system cache"
 rm -rf /var/cache/* || true                     # apt, dpkg などのシステムキャッシュ / System caches (apt, dpkg, etc.) / 系统缓存/apt/dpkg等
fi

# 90% 超過: Playwright (Chromium) 完全削除
# >90%: Remove Playwright browser cache completely
if [ "$USAGE" -gt 90 ]; then
 echo "[!!] Disk >90%, deep cleanup / ディスク >90%、深度清理"
 
 echo "→ Playwright cache (Chromium 625MB)"
 # ms-playwright = Playwright バンドルChromium（625MB）
 # Playwright bundled Chromium browser cache (625MB)
 rm -rf /root/.cache/ms-playwright || true
fi

#--------------------------------------------------------------------------------
# [7] エージェントタスク再開 / Resume Agent Tasks / 恢复Agent任务
#--------------------------------------------------------------------------------
echo "[7] Resume Agent Tasks / エージェントタスク再開 / 恢复Agent任务"
# 清理完了後、agent-task-worker を再起動
# Restart agent-task-worker after cleanup completes
systemctl start agent-task-worker || true

echo "[DONE] Cleanup completed / 清理完了 / 清理完成"