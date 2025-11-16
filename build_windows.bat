@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Windows Zed 自动编译脚本
:: 需要预先安装：VS BuildTools, Python 3.10, Git, Rust

echo ========================================
echo    Windows Zed 自动编译脚本
echo ========================================
echo.

:: 设置简单的标签输出（避免颜色问题）
set "INFO=[信息]"
set "OK=[成功]"
set "ERROR=[错误]"
set "WARN=[警告]"

:: 检查必要工具
echo %INFO% 检查必要工具...

:: 检查Python
python --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Python 未找到，请安装 Python 3.10
    echo 请从 https://www.python.org/downloads/ 下载安装
    pause
    exit /b 1
)
echo %OK% Python 已安装

:: 检查Git
git --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Git 未找到，请安装 Git
    echo 请从 https://git-scm.com/download/win 下载安装
    pause
    exit /b 1
)
echo %OK% Git 已安装

:: 检查Cargo
cargo --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Rust/Cargo 未找到，请先安装 Rust
    echo 请访问 https://rustup.rs/ 安装 Rust
    echo.
    echo 安装 Rust 后请重新运行此脚本
    pause
    exit /b 1
)
echo %OK% Rust/Cargo 已安装

echo.

:: 获取用户选择的构建类型
echo 选择构建类型:
echo 1. Vulkan 版本 (推荐)
echo 2. OpenGL 版本 (兼容性更好)
echo 3. 同时构建两个版本
set /p choice="请选择 [1-3]: "

if "%choice%"=="1" (
    set "backends=vulkan"
) else if "%choice%"=="2" (
    set "backends=opengl"
) else if "%choice%"=="3" (
    set "backends=vulkan opengl"
) else (
    echo %WARN% 无效选择，使用默认的 Vulkan 版本
    set "backends=vulkan"
)

echo.

:: 启用长路径支持
echo %INFO% 启用长路径支持...
git config --global core.longpaths true

:: 启用Windows长路径支持 (需要管理员权限)
powershell -Command "try { New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue } catch { Write-Host '无法设置长路径支持 (可能需要管理员权限)' }"

echo.

:: 检查并克隆 Zed 源代码
echo %INFO% 检查 Zed 源代码...
if not exist "zed" (
    echo %INFO% 克隆 Zed 源代码...
    git clone https://github.com/zed-industries/zed.git
    if errorlevel 1 (
        echo %ERROR% 克隆 Zed 源代码失败
        pause
        exit /b 1
    )
) else (
    echo %WARN% Zed 目录已存在，正在更新...
    cd zed
    git fetch origin
    git reset --hard origin/main
    cd ..
)
echo %OK% Zed 源代码准备完成

echo.

:: 应用翻译
echo %INFO% 应用中文翻译...
python replace.py
if errorlevel 1 (
    echo %ERROR% 应用翻译失败
    pause
    exit /b 1
)
echo %OK% 翻译应用完成

echo.

:: 安装 Rust nightly 和目标平台
echo %INFO% 准备 Rust 环境...
rustup toolchain install nightly
rustup target add wasm32-wasip1
rustup default nightly
echo %OK% Rust 环境准备完成

echo.

:: 创建输出目录
if not exist "output" mkdir output

:: 构建循环
for %%b in (%backends%) do (
    echo.
    echo %INFO% 开始构建 %%b 版本...

    cd zed

    :: 设置 rustflags
    if "%%b"=="vulkan" (
        set "RUSTFLAGS="
        set "output_name=zed-windows.exe"
    ) else if "%%b"=="opengl" (
        set "RUSTFLAGS=--cfg gles"
        set "output_name=zed-windows-opengl.exe"
    )

    :: 设置环境变量
    set RUSTFLAGS=!RUSTFLAGS!

    :: 构建
    echo %INFO% 构建 %%b 版本 (这可能需要较长时间)...
    cargo build --release
    if errorlevel 1 (
        echo %ERROR% 构建 %%b 版本失败
        cd ..
        pause
        exit /b 1
    )

    :: 复制可执行文件
    if exist "target\release\zed.exe" (
        copy "target\release\zed.exe" "..\output\!output_name!"
        echo %OK% %%b 版本构建完成: output\!output_name!
    ) else (
        echo %ERROR% 找不到构建的可执行文件
        cd ..
        pause
        exit /b 1
    )

    cd ..
)

echo.
echo =======================================
echo           构建完成！
echo =======================================
echo.
echo 构建的文件位于 output 目录:
dir /b output\*.exe

echo.
echo %INFO% 构建信息:
if exist "output\zed-windows.exe" (
    echo - Vulkan 版本: output\zed-windows.exe
)
if exist "output\zed-windows-opengl.exe" (
    echo - OpenGL 版本: output\zed-windows-opengl.exe
)

echo.
echo 使用说明:
echo 1. Vulkan 版本性能更好，但需要较新的显卡驱动
echo 2. OpenGL 版本兼容性更好，适合老显卡或虚拟机
echo 3. 如遇到图形问题，请尝试 OpenGL 版本

echo.
echo 构建完成！按任意键退出...
pause >nul
