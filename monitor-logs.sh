#!/bin/bash

# 日志监控脚本 - 同时显示所有服务的日志

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_redis() { echo -e "${BLUE}[REDIS]${NC} $1"; }
log_infernet() { echo -e "${GREEN}[INFERNET]${NC} $1"; }
log_container() { echo -e "${YELLOW}[CONTAINER]${NC} $1"; }

echo "======================================="
echo "📊 Infernet 服务日志监控器"
echo "======================================="

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    if pgrep -f "infernet-node" > /dev/null; then
        log_info "✅ Infernet 节点正在运行"
    else
        log_warn "❌ Infernet 节点未运行"
    fi
    
    if pgrep -x "redis-server" > /dev/null; then
        log_info "✅ Redis 正在运行"
    else
        log_warn "❌ Redis 未运行"
    fi
}

# 监控 Redis 日志
monitor_redis() {
    if [ -f "logs/redis.log" ]; then
        log_redis "开始监控 Redis 日志..."
        tail -f logs/redis.log | while read line; do
            log_redis "$line"
        done &
        REDIS_MONITOR_PID=$!
    else
        log_warn "Redis 日志文件不存在"
    fi
}

# 监控 Infernet 节点日志
monitor_infernet() {
    if [ -f "logs/infernet-node.log" ]; then
        log_infernet "开始监控 Infernet 节点日志..."
        tail -f logs/infernet-node.log | while read line; do
            log_infernet "$line"
        done &
        INFERNET_MONITOR_PID=$!
    else
        log_warn "Infernet 节点日志文件不存在"
    fi
}

# 清理监控进程
cleanup() {
    log_info "正在停止日志监控..."
    [ ! -z "$REDIS_MONITOR_PID" ] && kill $REDIS_MONITOR_PID 2>/dev/null || true
    [ ! -z "$INFERNET_MONITOR_PID" ] && kill $INFERNET_MONITOR_PID 2>/dev/null || true
    exit 0
}

# 捕获 Ctrl+C 信号
trap cleanup INT

# 主函数
main() {
    case "${1:-monitor}" in
        "monitor")
            check_services
            echo ""
            log_info "开始监控所有服务日志..."
            log_info "按 Ctrl+C 停止监控"
            echo ""
            
            monitor_redis
            monitor_infernet
            
            # 等待所有后台进程
            wait
            ;;
        "status")
            check_services
            ;;
        *)
            echo "用法: $0 {monitor|status}"
            echo "  monitor - 监控所有服务日志（默认）"
            echo "  status  - 检查服务状态"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@" 