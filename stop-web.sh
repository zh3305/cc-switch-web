#!/bin/bash

# CC-Switch Web 模式停止脚本

echo "🛑 Stopping CC-Switch Web Mode..."

# 从 PID 文件停止
if [ -f /tmp/cc-switch-backend.pid ]; then
    BACKEND_PID=$(cat /tmp/cc-switch-backend.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        kill $BACKEND_PID
        echo "✓ Stopped backend (PID: $BACKEND_PID)"
    fi
    rm -f /tmp/cc-switch-backend.pid
fi

if [ -f /tmp/cc-switch-frontend.pid ]; then
    FRONTEND_PID=$(cat /tmp/cc-switch-frontend.pid)
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        kill $FRONTEND_PID
        echo "✓ Stopped frontend (PID: $FRONTEND_PID)"
    fi
    rm -f /tmp/cc-switch-frontend.pid
fi

# 额外清理端口占用
lsof -ti:17666 | xargs -r kill -9 2>/dev/null && echo "✓ Cleaned port 17666"
lsof -ti:3001 | xargs -r kill -9 2>/dev/null && echo "✓ Cleaned port 3001"

echo "✓ All services stopped"
