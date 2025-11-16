@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo        Rust 自动安装脚本
echo ========================================
echo.

echo [信息] 检查 Rust 是否已安装...

:: 检查是否已安装 Rust
cargo --version >nul 2>&1
if not errorlevel 1 (
    echo [成功] Rust 已经安装，版本信息：
    cargo --version
    rustc --version
    echo.
    echo 如需重新安装，请先运行以下命令卸载：
    echo   rustup self uninstall
    echo.
    pause
    exit /b 0
)

echo [信息] Rust 未安装，开始安装过程...
echo.

:: 检查网络连接
echo [信息] 检查网络连接...
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (
    echo [警告] 网络连接可能有问题，但继续尝试安装...
) else (
    echo [成功] 网络连接正常
)

echo.

:: 下载并运行 Rust 安装程序
echo [信息] 下载 Rust 安装程序...
echo 这将下载并运行官方的 rustup-init.exe

:: 创建临时目录
if not exist temp mkdir temp
cd temp

:: 下载 rustup-init.exe
echo 正在下载 rustup-init.exe...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://win.rustup.rs/x86_64' -OutFile 'rustup-init.exe'}"

if not exist rustup-init.exe (
    echo [错误] 下载失败，请检查网络连接
    echo.
    echo 手动安装步骤：
    echo 1. 访问 https://rustup.rs/
    echo 2. 下载 rustup-init.exe
    echo 3. 运行下载的文件
    echo.
    cd ..
    pause
    exit /b 1
)

echo [成功] 下载完成
echo.

:: 运行安装程序
echo [信息] 启动 Rust 安装程序...
echo.
echo 重要说明：
echo 1. 安装程序会提示选择安装选项，建议选择默认选项 (1)
echo 2. 安装完成后需要重新启动命令提示符
echo 3. 如果出现 Visual Studio Build Tools 相关提示，请先安装它
echo.
echo 按任意键开始安装...
pause >nul

:: 运行安装程序
rustup-init.exe

echo.
echo [信息] 安装程序执行完成
echo.

:: 清理临时文件
cd ..
rmdir /s /q temp >nul 2>&1

echo [信息] 验证安装结果...
echo.

:: 刷新环境变量
call "%USERPROFILE%\.cargo\env.bat" 2>nul

:: 重新检查 Rust 安装
cargo --version >nul 2>&1
if errorlevel 1 (
    echo [警告] 当前命令窗口中检测不到 Rust
    echo.
    echo 这是正常的！请执行以下步骤：
    echo 1. 关闭当前命令提示符窗口
    echo 2. 重新打开新的命令提示符窗口
    echo 3. 运行 'cargo --version' 验证安装
    echo 4. 如果成功显示版本号，则继续运行构建脚本
    echo.
    echo 如果仍然无法使用，请手动添加以下路径到系统 PATH：
    echo   %USERPROFILE%\.cargo\bin
) else (
    echo [成功] Rust 安装成功！
    echo.
    echo 版本信息：
    cargo --version
    rustc --version
    echo.
    echo 现在可以运行 build_windows.bat 开始编译 Zed 了！
)

echo.
echo 按任意键退出...
pause >nul
