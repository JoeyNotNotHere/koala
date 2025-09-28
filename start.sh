#!/bin/bash

# Koala频率控制系统启动脚本
# Author: Auto-generated
# Description: 启动Koala服务的便捷脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# 配置文件路径
CONFIG_FILE="conf/koala.conf"
BINARY_FILE="bin/koala"
PID_FILE="data/koala.pid"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}       Koala 频率控制系统启动脚本      ${NC}"
echo -e "${BLUE}======================================${NC}"

# 检查Redis是否运行
check_redis() {
    echo -e "${YELLOW}[检查] 检查Redis服务状态...${NC}"
    if ! redis-cli ping > /dev/null 2>&1; then
        echo -e "${RED}[错误] Redis服务未启动，正在尝试启动...${NC}"
        if command -v brew > /dev/null 2>&1; then
            brew services start redis
            sleep 2
            if redis-cli ping > /dev/null 2>&1; then
                echo -e "${GREEN}[成功] Redis服务启动成功${NC}"
            else
                echo -e "${RED}[失败] Redis服务启动失败，请手动启动Redis${NC}"
                exit 1
            fi
        else
            echo -e "${RED}[错误] 请先安装并启动Redis服务${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[成功] Redis服务运行正常${NC}"
    fi
}

# 检查并创建必要目录
create_dirs() {
    echo -e "${YELLOW}[检查] 创建必要目录...${NC}"
    mkdir -p data log
    echo -e "${GREEN}[成功] 目录检查完成${NC}"
}

# 检查配置文件
check_config() {
    echo -e "${YELLOW}[检查] 检查配置文件...${NC}"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}[错误] 配置文件不存在: $CONFIG_FILE${NC}"
        exit 1
    fi
    echo -e "${GREEN}[成功] 配置文件存在${NC}"
}

# 编译项目
build_project() {
    echo -e "${YELLOW}[构建] 编译Koala项目...${NC}"
    if [ ! -f "$BINARY_FILE" ] || [ cmd/main.go -nt "$BINARY_FILE" ]; then
        echo -e "${YELLOW}[构建] 检测到源码更新，重新编译...${NC}"
        go build -o "$BINARY_FILE" cmd/main.go
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[成功] 项目编译完成${NC}"
        else
            echo -e "${RED}[失败] 项目编译失败${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[跳过] 可执行文件已是最新${NC}"
    fi
}

# 检查服务是否已运行
check_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}[警告] Koala服务已在运行 (PID: $pid)${NC}"
            echo -e "${YELLOW}[提示] 如需重启，请先运行 ./stop.sh${NC}"
            exit 0
        else
            # PID文件存在但进程不存在，删除过期的PID文件
            rm -f "$PID_FILE"
        fi
    fi
}

# 启动服务
start_service() {
    echo -e "${YELLOW}[启动] 启动Koala服务...${NC}"
    
    # 后台启动服务
    nohup ./"$BINARY_FILE" -f "$CONFIG_FILE" > /dev/null 2>&1 &
    local pid=$!
    
    # 保存PID
    echo $pid > "$PID_FILE"
    
    # 等待服务启动
    sleep 2
    
    # 检查服务是否成功启动
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${GREEN}[成功] Koala服务启动成功 (PID: $pid)${NC}"
        echo -e "${GREEN}[信息] 服务监听端口: 9981${NC}"
        echo -e "${GREEN}[信息] 监控接口: http://localhost:9981/monitor/alive${NC}"
        
        # 测试服务是否响应
        sleep 1
        if curl -s "http://localhost:9981/monitor/alive" > /dev/null 2>&1; then
            echo -e "${GREEN}[测试] 服务接口响应正常${NC}"
        else
            echo -e "${YELLOW}[警告] 服务已启动但接口暂未响应，请稍等片刻${NC}"
        fi
    else
        echo -e "${RED}[失败] Koala服务启动失败${NC}"
        rm -f "$PID_FILE"
        exit 1
    fi
}

# 显示使用说明
show_usage() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}            使用说明                   ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e "${GREEN}启动服务: ./start.sh${NC}"
    echo -e "${GREEN}停止服务: ./stop.sh${NC}"
    echo -e "${GREEN}重启服务: ./restart.sh${NC}"
    echo -e "${GREEN}查看状态: ./status.sh${NC}"
    echo ""
    echo -e "${YELLOW}API接口示例:${NC}"
    echo -e "  监控接口: curl http://localhost:9981/monitor/alive"
    echo -e "  查询接口: curl 'http://localhost:9981/rule/browse?act=addreview&uid=12345'"
    echo -e "  更新接口: curl 'http://localhost:9981/rule/update?act=addreview&uid=12345'"
    echo ""
}

# 主执行流程
main() {
    check_redis
    create_dirs
    check_config
    build_project
    check_running
    start_service
    show_usage
}

# 执行主函数
main "$@"
