#!/bin/bash

# Koala频率控制系统停止脚本
# Author: Auto-generated
# Description: 停止Koala服务的脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

PID_FILE="data/koala.pid"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}       Koala 频率控制系统停止脚本      ${NC}"
echo -e "${BLUE}======================================${NC}"

# 停止服务
stop_service() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}[提示] Koala服务未在运行${NC}"
        return 0
    fi
    
    local pid=$(cat "$PID_FILE" 2>/dev/null)
    
    if [ -z "$pid" ]; then
        echo -e "${YELLOW}[提示] PID文件为空，清理PID文件${NC}"
        rm -f "$PID_FILE"
        return 0
    fi
    
    if ! kill -0 "$pid" 2>/dev/null; then
        echo -e "${YELLOW}[提示] 进程 $pid 不存在，清理PID文件${NC}"
        rm -f "$PID_FILE"
        return 0
    fi
    
    echo -e "${YELLOW}[停止] 正在停止Koala服务 (PID: $pid)...${NC}"
    
    # 尝试优雅停止
    kill "$pid"
    
    # 等待进程停止
    local count=0
    while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
        echo -e "${YELLOW}[等待] 等待进程停止... ($count/10)${NC}"
    done
    
    # 检查进程是否已停止
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${YELLOW}[强制] 进程未响应，强制终止...${NC}"
        kill -9 "$pid"
        sleep 1
        
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${RED}[失败] 无法停止进程 $pid${NC}"
            return 1
        fi
    fi
    
    # 清理PID文件
    rm -f "$PID_FILE"
    echo -e "${GREEN}[成功] Koala服务已停止${NC}"
}

# 主执行函数
main() {
    stop_service
}

# 执行主函数
main "$@"
