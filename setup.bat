@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo      Zed 中文版编译环境检查工具
echo ========================================
echo.

set "INFO=[信息]"
set "OK=[成功]"
set "ERROR=[错误]"
set "WARN=[警告]"
set "INSTALL=[安装]"

echo %INFO% 正在检查编译环境...
echo.

:: 创建检查结果记录
set "python_ok=0"
set "git_ok=0"
set "rust_ok=0"
set "vs_ok=0"

:: 检查 Python
echo 1. 检查 Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Python 未安装
    echo        请从 https://www.python.org/downloads/ 安装 Python 3.10+
    echo        安装时请勾选 "Add Python to PATH"
) else (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do (
        echo %OK% Python 已安装 - 版本: %%v
        set "python_ok=1"
    )
)

echo.

:: 检查 Git
echo 2. 检查 Git...
git --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Git 未安装
    echo        请从 https://git-scm.com/download/win 下载安装
) else (
    for /f "tokens=3" %%v in ('git --version 2^>^&1') do (
        echo %OK% Git 已安装 - 版本: %%v
        set "git_ok=1"
    )
)

echo.

:: 检查 Rust
echo 3. 检查 Rust/Cargo...
cargo --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Rust 未安装
    echo        可以运行 install_rust.bat 自动安装
    echo        或手动访问 https://rustup.rs/ 安装
) else (
    for /f "tokens=2" %%v in ('cargo --version 2^>^&1') do (
        echo %OK% Rust 已安装 - Cargo 版本: %%v
        set "rust_ok=1"
    )
    for /f "tokens=2" %%v in ('rustc --version 2^>^&1') do (
        echo        Rustc 版本: %%v
    )
)

echo.

:: 检查 Visual Studio Build Tools
echo 4. 检查 Visual Studio Build Tools...
set "vcvars_found=0"

if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    echo %OK% Visual Studio Build Tools 2022 已安装 (x86 目录)
    set "vcvars_found=1"
    set "vs_ok=1"
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    echo %OK% Visual Studio Build Tools 2022 已安装
    set "vcvars_found=1"
    set "vs_ok=1"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    echo %OK% Visual Studio Build Tools 2019 已安装 (x86 目录)
    set "vcvars_found=1"
    set "vs_ok=1"
) else if exist "C:\Program Files\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    echo %OK% Visual Studio Build Tools 2019 已安装
    set "vcvars_found=1"
    set "vs_ok=1"
)

if !vcvars_found!==0 (
    echo %ERROR% Visual Studio Build Tools 未找到
    echo        请安装 Visual Studio Build Tools 2019 或 2022
    echo        下载地址: https://visualstudio.microsoft.com/zh-hans/downloads/
    echo        选择 "Build Tools for Visual Studio" 下载
    echo.
    echo        安装时请确保选择:
    echo        - C++ 构建工具
    echo        - Windows 10/11 SDK
    echo        - CMake 工具
)

echo.

:: 检查磁盘空间
echo 5. 检查磁盘空间...
for /f "tokens=3" %%s in ('dir /-c "%~dp0" ^| find "可用字节"') do (
    set "available_space=%%s"
)
if defined available_space (
    echo %OK% 当前磁盘可用空间充足
) else (
    echo %WARN% 无法检测磁盘空间，请确保至少有 10GB 可用空间
)

echo.

:: 生成总结报告
echo ========================================
echo           环境检查总结
echo ========================================

set /a "total_score=python_ok+git_ok+rust_ok+vs_ok"

if !total_score!==4 (
    echo %OK% 所有依赖已正确安装！
    echo.
    echo 您现在可以运行以下命令开始编译:
    echo   build_windows.bat        - 完整编译脚本
    echo   build_simple.bat         - 简化编译脚本
    echo.

    set /p start_build="是否现在开始编译? (y/n): "
    if /i "!start_build!"=="y" (
        echo.
        echo 启动编译脚本...
        call build_windows.bat
    )
) else (
    echo %WARN% 发现 !total_score!/4 个依赖已安装，需要安装缺失的依赖
    echo.
    echo 安装建议:

    if !python_ok!==0 (
        echo   1. 安装 Python: https://www.python.org/downloads/
    )
    if !git_ok!==0 (
        echo   2. 安装 Git: https://git-scm.com/download/win
    )
    if !rust_ok!==0 (
        echo   3. 安装 Rust: 运行 install_rust.bat 或访问 https://rustup.rs/
    )
    if !vs_ok!==0 (
        echo   4. 安装 VS Build Tools: https://visualstudio.microsoft.com/zh-hans/downloads/
    )

    echo.
    echo 安装完成后请重新运行此脚本检查环境
)

echo.

:: 提供快速安装选项
if !rust_ok!==0 (
    echo ----------------------------------------
    echo 快速安装选项:
    echo ----------------------------------------
    echo.
    if exist "install_rust.bat" (
        set /p install_rust="是否现在自动安装 Rust? (y/n): "
        if /i "!install_rust!"=="y" (
            echo.
            echo 启动 Rust 自动安装...
            call install_rust.bat
            echo.
            echo Rust 安装完成后，请重新运行 setup.bat 检查环境
        )
    ) else (
        echo   install_rust.bat 文件不存在，无法自动安装 Rust
    )
)

echo.
echo 按任意键退出...
pause >nul
