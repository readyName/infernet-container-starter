#!/bin/bash

# Infernet 二进制文件手动安装脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "======================================="
echo "🔧 Infernet 二进制文件手动安装工具"
echo "======================================="

# 检测操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    if [[ $(uname -m) == "arm64" ]]; then
        ARCH="aarch64-apple-darwin"
    else
        ARCH="x86_64-apple-darwin"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    ARCH="x86_64-unknown-linux-gnu"
else
    error "不支持的操作系统: $OSTYPE"
    exit 1
fi

info "检测到操作系统: $OS ($ARCH)"

# 安装目录
INSTALL_DIR="$HOME/.infernet"
BINARY_PATH="$INSTALL_DIR/infernet-node"

# 创建安装目录
mkdir -p "$INSTALL_DIR"

# 显示可用的下载选项
echo ""
info "请选择下载方式："
echo "1. 自动下载最新版本"
echo "2. 手动指定下载 URL"
echo "3. 从本地文件安装"
read -p "请选择 (1-3): " choice

case $choice in
    1)
        info "正在获取最新版本信息..."
        # 尝试获取最新版本
        LATEST_VERSION=$(curl -s https://api.github.com/repos/ritual-net/infernet/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        if [ -z "$LATEST_VERSION" ]; then
            LATEST_VERSION="1.4.0"
            warn "无法获取最新版本，使用默认版本: $LATEST_VERSION"
        else
            info "最新版本: $LATEST_VERSION"
        fi
        
        # 尝试不同的下载 URL 格式
        DOWNLOAD_URLS=(
            "https://github.com/ritual-net/infernet/releases/download/${LATEST_VERSION}/infernet-node-${LATEST_VERSION}-${ARCH}.tar.gz"
            "https://github.com/ritual-net/infernet/releases/download/${LATEST_VERSION}/infernet-node-${ARCH}.tar.gz"
            "https://github.com/ritual-net/infernet/releases/latest/download/infernet-node-${ARCH}.tar.gz"
        )
        
        success=false
        for url in "${DOWNLOAD_URLS[@]}"; do
            info "尝试下载: $url"
            if curl -L -o /tmp/infernet-node.tar.gz "$url" 2>/dev/null; then
                info "下载成功！"
                success=true
                break
            else
                warn "下载失败，尝试下一个..."
            fi
        done
        
        if [ "$success" = false ]; then
            error "自动下载失败，请尝试手动下载"
            exit 1
        fi
        ;;
        
    2)
        read -p "请输入下载 URL: " DOWNLOAD_URL
        info "正在下载: $DOWNLOAD_URL"
        if ! curl -L -o /tmp/infernet-node.tar.gz "$DOWNLOAD_URL"; then
            error "下载失败"
            exit 1
        fi
        ;;
        
    3)
        read -p "请输入本地文件路径: " LOCAL_FILE
        if [ ! -f "$LOCAL_FILE" ]; then
            error "文件不存在: $LOCAL_FILE"
            exit 1
        fi
        cp "$LOCAL_FILE" /tmp/infernet-node.tar.gz
        info "文件已复制到临时目录"
        ;;
        
    *)
        error "无效选择"
        exit 1
        ;;
esac

# 解压文件
info "正在解压文件..."
cd /tmp
if ! tar -xzf infernet-node.tar.gz; then
    error "解压失败"
    exit 1
fi

# 查找二进制文件
info "查找二进制文件..."
BINARY_FOUND=$(find . -name "infernet-node" -type f | head -1)

if [ -z "$BINARY_FOUND" ]; then
    # 尝试查找其他可能的二进制文件名
    BINARY_FOUND=$(find . -name "*infernet*" -type f | head -1)
    if [ -z "$BINARY_FOUND" ]; then
        error "未找到 Infernet 二进制文件"
        info "解压后的文件列表："
        find . -type f | head -10
        exit 1
    else
        warn "找到可能的二进制文件: $BINARY_FOUND"
        read -p "是否使用此文件？(y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            error "安装取消"
            exit 1
        fi
    fi
fi

# 移动到安装目录
info "正在安装到: $BINARY_PATH"
cp "$BINARY_FOUND" "$BINARY_PATH"
chmod +x "$BINARY_PATH"

# 清理临时文件
rm -rf /tmp/infernet-node.tar.gz
rm -rf /tmp/infernet-*

# 验证安装
if [ -x "$BINARY_PATH" ]; then
    info "✅ 安装成功！"
    info "二进制文件位置: $BINARY_PATH"
    info "版本信息:"
    "$BINARY_PATH" --version 2>/dev/null || info "无法获取版本信息"
else
    error "安装失败"
    exit 1
fi

echo ""
info "现在你可以运行 ./start-infernet-no-docker.sh 来启动 Infernet 节点" 