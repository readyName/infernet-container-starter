#!/bin/bash

set -e

# 定义日志函数
log_file="$HOME/infernet-no-docker.log"
info() { echo "ℹ️  $1" | tee -a "$log_file"; }
warn() { echo "⚠️  $1" | tee -a "$log_file"; }
error() { echo "❌ 错误：$1" | tee -a "$log_file"; exit 1; }

echo "======================================="
echo "🚀 Infernet 非 Docker 模式启动脚本 🚀"
echo "=======================================" | tee -a "$log_file"
echo "📝 模式：纯节点模式（无容器服务）" | tee -a "$log_file"

# 配置文件路径
config_file="$HOME/.infernet_config"
infernet_binary_dir="$HOME/.infernet"
infernet_binary="$infernet_binary_dir/infernet-node"

# 函数：加载或提示输入配置
load_or_prompt_config() {
    if [ -f "$config_file" ]; then
        info "检测到已保存的配置：$config_file"
        source "$config_file"
        info "当前 RPC_URL: $RPC_URL"
        info "当前 PRIVATE_KEY: ${PRIVATE_KEY:0:4}...（已隐藏后部分）"
        read -p "是否更新 RPC_URL 和 PRIVATE_KEY？(y/n): " update_config
        if [[ "$update_config" != "y" && "$update_config" != "Y" ]]; then
            return
        fi
    fi

    info "请输入以下信息以继续部署："
    read -p "请输入你的 RPC URL（Alchemy/Infura，例如 Base Mainnet 或 Sepolia）： " RPC_URL
    read -p "请输入你的私钥（0x 开头，不要泄露）： " PRIVATE_KEY

    # 输入校验
    if [[ -z "$RPC_URL" || -z "$PRIVATE_KEY" ]]; then
        error "RPC URL 和私钥不能为空。"
    fi
    if [[ ! "$RPC_URL" =~ ^https?://[a-zA-Z0-9.-]+ ]]; then
        error "无效的 RPC URL 格式。"
    fi
    if [[ ! "$PRIVATE_KEY" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
        error "无效的私钥格式（必须是 0x 开头的 64 位十六进制）。"
    fi

    # 保存到配置文件
    cat <<EOF > "$config_file"
RPC_URL="$RPC_URL"
PRIVATE_KEY="$PRIVATE_KEY"
EOF
    chmod 600 "$config_file"
    info "配置已保存至 $config_file"
}

# 函数：检查并安装系统依赖
check_system_dependencies() {
    info "检查系统依赖..."
    
    # 检查操作系统
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            OS="ubuntu"
            PACKAGE_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            OS="centos"
            PACKAGE_MANAGER="yum"
        else
            error "不支持的操作系统包管理器"
        fi
    else
        error "不支持的操作系统: $OSTYPE"
    fi
    
    info "检测到操作系统: $OS"
    
    # 安装基本依赖
    case $PACKAGE_MANAGER in
        "brew")
            if ! command -v brew &> /dev/null; then
                info "安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            for pkg in curl jq wget; do
                if ! command -v $pkg &> /dev/null; then
                    info "安装 $pkg..."
                    brew install $pkg
                fi
            done
            ;;
        "apt")
            sudo apt update
            for pkg in curl jq wget; do
                if ! command -v $pkg &> /dev/null; then
                    info "安装 $pkg..."
                    sudo apt install -y $pkg
                fi
            done
            ;;
        "yum")
            for pkg in curl jq wget; do
                if ! command -v $pkg &> /dev/null; then
                    info "安装 $pkg..."
                    sudo yum install -y $pkg
                fi
            done
            ;;
    esac
}

# 函数：安装 Redis
install_redis() {
    info "检查 Redis..."
    if ! command -v redis-server &> /dev/null; then
        info "Redis 未安装，正在安装..."
        case $PACKAGE_MANAGER in
            "brew")
                brew install redis
                ;;
            "apt")
                sudo apt install -y redis-server
                ;;
            "yum")
                sudo yum install -y redis
                ;;
        esac
    fi
    info "Redis 已安装，版本：$(redis-server --version | head -n 1)"
}

# 函数：下载 Infernet 节点二进制文件
download_infernet_binary() {
    info "检查 Infernet 节点二进制文件..."
    
    if [ ! -f "$infernet_binary" ]; then
        info "Infernet 节点二进制文件不存在，正在下载..."
        mkdir -p "$infernet_binary_dir"
        
        # 根据操作系统下载对应版本
        case $OS in
            "macos")
                if [[ $(uname -m) == "arm64" ]]; then
                    ARCH="aarch64-apple-darwin"
                else
                    ARCH="x86_64-apple-darwin"
                fi
                ;;
            "ubuntu"|"centos")
                ARCH="x86_64-unknown-linux-gnu"
                ;;
        esac
        
        # 下载最新版本（这里使用示例 URL，实际需要从官方获取）
        VERSION="1.4.0"
        DOWNLOAD_URL="https://github.com/ritual-net/infernet/releases/download/v${VERSION}/infernet-node-${VERSION}-${ARCH}.tar.gz"
        
        info "下载 Infernet 节点 v${VERSION}..."
        if wget -O /tmp/infernet-node.tar.gz "$DOWNLOAD_URL"; then
            tar -xzf /tmp/infernet-node.tar.gz -C "$infernet_binary_dir"
            chmod +x "$infernet_binary"
            rm /tmp/infernet-node.tar.gz
            info "Infernet 节点下载完成"
        else
            error "下载 Infernet 节点失败，请检查网络连接或手动下载"
        fi
    else
        info "Infernet 节点二进制文件已存在"
    fi
}

# 函数：更新配置文件
update_config_files() {
    info "更新配置文件..."
    
    # 更新 deploy/config.json
    if [ -f "deploy/config.json" ]; then
        jq ".chain.rpc_url = \"$RPC_URL\" | .chain.wallet.private_key = \"$PRIVATE_KEY\"" deploy/config.json > deploy/config.json.tmp
        mv deploy/config.json.tmp deploy/config.json
        info "已更新 deploy/config.json"
    fi
    
    # 更新 projects/hello-world/container/config.json
    if [ -f "projects/hello-world/container/config.json" ]; then
        jq ".chain.rpc_url = \"$RPC_URL\" | .chain.wallet.private_key = \"$PRIVATE_KEY\"" projects/hello-world/container/config.json > projects/hello-world/container/config.json.tmp
        mv projects/hello-world/container/config.json.tmp projects/hello-world/container/config.json
        info "已更新 projects/hello-world/container/config.json"
    fi
}

# 函数：启动服务
start_services() {
    info "启动服务..."
    
    # 启动 Redis
    info "启动 Redis 服务..."
    if ! pgrep -x "redis-server" > /dev/null; then
        # 前台运行 Redis 并重定向日志
        info "Redis 日志将显示在当前页面"
        redis-server --daemonize no 2>&1 | tee logs/redis.log &
        REDIS_PID=$!
        info "Redis 已启动 (PID: $REDIS_PID)"
    else
        info "Redis 已在运行"
    fi
    
    # 等待 Redis 启动
    sleep 2
    
    # 检查 Redis 连接
    if redis-cli ping | grep -q "PONG"; then
        info "Redis 连接正常"
    else
        error "Redis 连接失败"
    fi
    
    # 启动 Infernet 节点
    info "启动 Infernet 节点..."
    cd "$(dirname "$0")"
    
    # 创建日志目录
    mkdir -p logs
    
    # 启动 Infernet 节点（前台运行）
    info "Infernet 节点正在启动..."
    info "所有日志将显示在当前页面"
    info "日志文件：logs/infernet-node.log"
    info "按 Ctrl+C 停止服务"
    
    # 启动节点并重定向日志
    "$infernet_binary" --config deploy/config.json 2>&1 | tee logs/infernet-node.log
}

# 函数：停止服务
stop_services() {
    info "停止服务..."
    
    # 停止 Infernet 节点
    if pgrep -f "infernet-node" > /dev/null; then
        pkill -f "infernet-node"
        info "已停止 Infernet 节点"
    fi
    
    # 停止 Redis
    if pgrep -x "redis-server" > /dev/null; then
        redis-cli shutdown
        info "已停止 Redis"
    fi
    
    # 停止后台 Redis 进程（如果有）
    if [ ! -z "$REDIS_PID" ] && kill -0 $REDIS_PID 2>/dev/null; then
        kill $REDIS_PID
        info "已停止后台 Redis 进程"
    fi
}

# 函数：检查服务状态
check_status() {
    info "检查服务状态..."
    
    if pgrep -f "infernet-node" > /dev/null; then
        info "✅ Infernet 节点正在运行"
    else
        info "❌ Infernet 节点未运行"
    fi
    
    if pgrep -x "redis-server" > /dev/null; then
        info "✅ Redis 正在运行"
    else
        info "❌ Redis 未运行"
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        "start")
            check_system_dependencies
            load_or_prompt_config
            install_redis
            download_infernet_binary
            update_config_files
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "status")
            check_status
            ;;
        "restart")
            stop_services
            sleep 2
            check_system_dependencies
            load_or_prompt_config
            install_redis
            download_infernet_binary
            update_config_files
            start_services
            ;;
        *)
            echo "用法: $0 {start|stop|status|restart}"
            echo "  start   - 启动 Infernet 节点（默认）"
            echo "  stop    - 停止所有服务"
            echo "  status  - 检查服务状态"
            echo "  restart - 重启所有服务"
            exit 1
            ;;
    esac
}

# 捕获 Ctrl+C 信号
trap 'echo -e "\n正在停止服务..."; stop_services; exit 0' INT

# 运行主函数
main "$@" 