@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo    Zed Windows 简化编译脚本
echo ========================================
echo.

:: 检查必要工具
echo [检查] Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到 Python，请安装 Python 3.10
    pause
    exit /b 1
)
echo [OK] Python 已安装

echo [检查] Git...
git --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到 Git
    pause
    exit /b 1
)
echo [OK] Git 已安装

echo [检查] Rust...
cargo --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到 Rust/Cargo，请从 https://rustup.rs/ 安装
    pause
    exit /b 1
)
echo [OK] Rust/Cargo 已安装

echo.

:: 设置长路径支持
echo [步骤1] 设置长路径支持...
git config --global core.longpaths true

:: 检查 Zed 源代码
echo [步骤2] 检查 Zed 源代码...
if not exist "zed" (
    echo 正在克隆 Zed 源代码...
    git clone https://github.com/zed-industries/zed.git
    if errorlevel 1 (
        echo 错误: 克隆失败
        pause
        exit /b 1
    )
) else (
    echo Zed 目录已存在，更新代码...
    cd zed
    git pull origin main
    cd ..
)

:: 应用翻译
echo [步骤3] 应用中文翻译...
python replace.py
if errorlevel 1 (
    echo 错误: 翻译应用失败
    pause
    exit /b 1
)
echo 翻译应用完成

:: 安装 Rust 工具链
echo [步骤4] 准备 Rust 环境...
rustup toolchain install nightly
rustup target add wasm32-wasip1
rustup default nightly

:: 创建输出目录
if not exist "output" mkdir output

echo [步骤5] 开始编译 (Vulkan版本)...
cd zed
echo 正在编译，请耐心等待...
cargo build --release
if errorlevel 1 (
    echo 编译失败，请检查错误信息
    cd ..
    pause
    exit /b 1
)

:: 复制可执行文件
if exist "target\release\zed.exe" (
    echo 复制可执行文件...
    copy "target\release\zed.exe" "..\output\zed-chinese.exe"
    cd ..
    echo.
    echo ========================================
    echo           编译完成！
    echo ========================================
    echo.
    echo 输出文件: output\zed-chinese.exe
    echo.
    echo 按任意键打开输出目录...
    pause >nul
    explorer output
) else (
    echo 错误: 找不到编译输出文件
    cd ..
    pause
)
