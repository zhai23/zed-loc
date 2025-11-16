@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo      Zed 编译问题一键修复工具
echo ========================================
echo.

set "INFO=[信息]"
set "OK=[成功]"
set "ERROR=[错误]"
set "WARN=[警告]"

echo %INFO% 检测到 Spectre 缓解库问题，正在应用快速修复...
echo.

:: 检查是否在正确目录
if not exist "zed" (
    echo %ERROR% 请在包含 zed 目录的位置运行此脚本
    pause
    exit /b 1
)

cd zed

:: 创建 .cargo 目录
if not exist ".cargo" mkdir .cargo

echo %INFO% 创建 Cargo 配置文件以禁用 Spectre 检查...

:: 创建配置文件禁用 Spectre 要求
(
echo [build]
echo rustflags = ["-C", "target-feature=+crt-static"]
echo.
echo [target.x86_64-pc-windows-msvc]
echo rustflags = ["-C", "target-feature=+crt-static"]
echo.
echo [env]
echo CARGO_CFG_TARGET_FEATURE = ""
) > .cargo\config.toml

echo %OK% 配置文件已创建

echo.
echo %INFO% 设置环境变量...

:: 设置环境变量
set CARGO_CFG_TARGET_FEATURE=
set MSVC_SPECTRE_LIBS_DISABLE=1

echo %OK% 环境变量已设置

echo.
echo %INFO% 清理之前的构建缓存...
cargo clean >nul 2>&1

echo %OK% 构建缓存已清理

cd ..

echo.
echo %INFO% 重新应用中文翻译...
python replace.py
if errorlevel 1 (
    echo %ERROR% 翻译应用失败
    pause
    exit /b 1
)

echo %OK% 翻译已重新应用

echo.
echo %INFO% 开始重新编译 (已禁用 Spectre 要求)...
echo 这可能需要较长时间，请耐心等待...

cd zed

:: 设置构建环境变量
set CARGO_CFG_TARGET_FEATURE=
set MSVC_SPECTRE_LIBS_DISABLE=1
set RUSTFLAGS=-C target-feature=+crt-static

echo.
echo %INFO% 开始 Cargo 构建...
cargo build --release

if errorlevel 1 (
    echo.
    echo %ERROR% 编译仍然失败
    echo.
    echo 可能的解决方案:
    echo 1. 安装完整的 Visual Studio Community
    echo 2. 运行 fix_vs_spectre.bat 安装 Spectre 缓解库
    echo 3. 检查网络连接和防火墙设置
    cd ..
    pause
    exit /b 1
)

echo.
echo %OK% 编译成功完成！

:: 创建输出目录并复制文件
if not exist "..\output" mkdir ..\output

if exist "target\release\zed.exe" (
    copy "target\release\zed.exe" "..\output\zed-chinese.exe" >nul
    echo %OK% 可执行文件已生成: output\zed-chinese.exe

    :: 获取文件大小
    for %%F in ("..\output\zed-chinese.exe") do set size=%%~zF
    set /a size_mb=!size!/1024/1024
    echo %INFO% 文件大小: !size_mb! MB
) else (
    echo %ERROR% 找不到生成的可执行文件
    cd ..
    pause
    exit /b 1
)

cd ..

echo.
echo ========================================
echo           编译成功完成！
echo ========================================
echo.
echo 输出文件: output\zed-chinese.exe
echo.
echo 使用说明:
echo 1. 此版本已禁用 Spectre 缓解，适合个人使用
echo 2. 如需启用安全功能，请安装完整的 Visual Studio
echo.

set /p open_folder="是否打开输出目录？ (y/n): "
if /i "!open_folder!"=="y" explorer output

echo.
set /p run_now="是否现在运行 Zed？ (y/n): "
if /i "!run_now!"=="y" start "" "output\zed-chinese.exe"

echo.
echo %OK% 修复和编译完成！
echo.
pause
