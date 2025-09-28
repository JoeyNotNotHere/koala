#!/bin/bash

# Koala频率控制系统状态检查脚本
# Author: Auto-generated
# Description: 检查Koala服务状态的脚本

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
echo -e "${BLUE}       Koala 频率控制系统状态检查      ${NC}"
echo -e "${BLUE}======================================${NC}"

# 检查服务状态
check_service_status() {
    echo -e "${YELLOW}[检查] Koala服务状态...${NC}"
    
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${RED}[状态] 服务未运行 (PID文件不存在)${NC}"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE" 2>/dev/null)
    
    if [ -z "$pid" ]; then
        echo -e "${RED}[状态] 服务未运行 (PID文件为空)${NC}"
        return 1
    fi
    
    if ! kill -0 "$pid" 2>/dev/null; then
        echo -e "${RED}[状态] 服务未运行 (进程 $pid 不存在)${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[状态] 服务正在运行 (PID: $pid)${NC}"
    
    # 获取进程信息
    local process_info=$(ps -p "$pid" -o pid,ppid,cpu,pmem,etime,cmd --no-headers 2>/dev/null)
    if [ -n "$process_info" ]; then
        echo -e "${BLUE}[进程] $process_info${NC}"
    fi
    
    return 0
}

# 检查Redis状态
check_redis_status() {
    echo -e "${YELLOW}[检查] Redis服务状态...${NC}"
    
    if redis-cli ping > /dev/null 2>&1; then
        local redis_info=$(redis-cli info server 2>/dev/null | grep "redis_version" | cut -d: -f2 | tr -d '\r')
        echo -e "${GREEN}[状态] Redis服务运行正常 (版本: $redis_info)${NC}"
    else
        echo -e "${RED}[状态] Redis服务未运行${NC}"
        return 1
    fi
}

# 检查端口监听
check_port_status() {
    echo -e "${YELLOW}[检查] 端口监听状态...${NC}"
    
    local port_info=$(netstat -an 2>/dev/null | grep ":9981" | grep LISTEN)
    if [ -n "$port_info" ]; then
        echo -e "${GREEN}[状态] 端口9981正在监听${NC}"
        echo -e "${BLUE}[详情] $port_info${NC}"
    else
        echo -e "${RED}[状态] 端口9981未在监听${NC}"
        return 1
    fi
}

# 检查API接口
check_api_status() {
    echo -e "${YELLOW}[检查] API接口状态...${NC}"
    
    local api_response=$(curl -s --connect-timeout 3 "http://localhost:9981/monitor/alive" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$api_response" ]; then
        echo -e "${GREEN}[状态] API接口响应正常${NC}"
        echo -e "${BLUE}[响应] $api_response${NC}"
    else
        echo -e "${RED}[状态] API接口无响应${NC}"
        return 1
    fi
}

# 显示配置信息
show_config_info() {
    echo -e "${YELLOW}[配置] 服务配置信息...${NC}"
    
    if [ -f "conf/koala.conf" ]; then
        local listen_port=$(grep "^listen" conf/koala.conf | cut -d= -f2 | tr -d ' ')
        local redis_server=$(grep "^redis_server" conf/koala.conf | cut -d= -f2 | tr -d ' ')
        local rule_file=$(grep "^rule_file" conf/koala.conf | cut -d= -f2 | tr -d ' ')
        
        echo -e "${BLUE}[配置] 监听端口: $listen_port${NC}"
        echo -e "${BLUE}[配置] Redis服务器: $redis_server${NC}"
        echo -e "${BLUE}[配置] 规则文件: $rule_file${NC}"
    fi
}

# 显示日志信息
show_log_info() {
    echo -e "${YELLOW}[日志] 最近日志信息...${NC}"
    
    if [ -d "log" ] && [ "$(ls -A log 2>/dev/null)" ]; then
        local latest_log=$(ls -t log/*.log 2>/dev/null | head -1)
        if [ -f "$latest_log" ]; then
            echo -e "${BLUE}[日志] 最新日志文件: $latest_log${NC}"
            echo -e "${BLUE}[内容] 最近10行:${NC}"
            tail -10 "$latest_log" 2>/dev/null | while read line; do
                echo -e "${NC}  $line${NC}"
            done
        fi
    else
        echo -e "${YELLOW}[日志] 暂无日志文件${NC}"
    fi
}

# 主执行函数
main() {
    local service_running=0
    local redis_running=0
    local port_listening=0
    local api_responding=0
    
    check_service_status && service_running=1
    echo ""
    
    check_redis_status && redis_running=1
    echo ""
    
    check_port_status && port_listening=1
    echo ""
    
    check_api_status && api_responding=1
    echo ""
    
    show_config_info
    echo ""
    
    show_log_info
    echo ""
    
    # 总结状态
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}            状态总结                   ${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    if [ $service_running -eq 1 ] && [ $redis_running -eq 1 ] && [ $port_listening -eq 1 ] && [ $api_responding -eq 1 ]; then
        echo -e "${GREEN}[总结] 🟢 服务运行正常，所有检查通过${NC}"
        echo -e "${GREEN}[建议] 服务状态良好，可以正常使用${NC}"
    elif [ $service_running -eq 1 ]; then
        echo -e "${YELLOW}[总结] 🟡 服务进程运行中，但部分功能异常${NC}"
        echo -e "${YELLOW}[建议] 请检查Redis连接和网络配置${NC}"
    else
        echo -e "${RED}[总结] 🔴 服务未运行${NC}"
        echo -e "${RED}[建议] 请使用 ./start.sh 启动服务${NC}"
    fi
}

# 执行主函数
main "$@"
