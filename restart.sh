#!/bin/bash

# Koala频率控制系统重启脚本
# Author: Auto-generated
# Description: 重启Koala服务的脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}       Koala 频率控制系统重启脚本      ${NC}"
echo -e "${BLUE}======================================${NC}"

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo -e "${YELLOW}[重启] 正在重启Koala服务...${NC}"

# 停止服务
echo -e "${YELLOW}[步骤1] 停止现有服务...${NC}"
./stop.sh

# 等待一秒
sleep 1

# 启动服务
echo -e "${YELLOW}[步骤2] 启动服务...${NC}"
./start.sh

echo -e "${GREEN}[完成] Koala服务重启完成${NC}"
