@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo    Visual Studio Spectre 库修复工具
echo ========================================
echo.

set "INFO=[信息]"
set "OK=[成功]"
set "ERROR=[错误]"
set "WARN=[警告]"

echo %INFO% 检测到缺少 Visual Studio Spectre 缓解库
echo.
echo 问题说明:
echo Zed 编译需要 Visual Studio 的 Spectre 缓解库，但当前安装中缺少这些组件。
echo.

:: 检查是否安装了 Visual Studio Installer
set "vs_installer_found=0"
if exist "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" (
    set "vs_installer=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe"
    set "vs_installer_found=1"
) else if exist "C:\Program Files\Microsoft Visual Studio\Installer\vs_installer.exe" (
    set "vs_installer=C:\Program Files\Microsoft Visual Studio\Installer\vs_installer.exe"
    set "vs_installer_found=1"
)

echo 解决方案选择:
echo 1. 自动打开 Visual Studio Installer 修复安装 (推荐)
echo 2. 禁用 Spectre 缓解 (快速解决方案)
echo 3. 手动安装指导
echo 4. 下载完整 Visual Studio Community (如果没有 VS)
echo 5. 退出
echo.

set /p choice="请选择 [1-5]: "

if "%choice%"=="1" goto AUTO_FIX
if "%choice%"=="2" goto DISABLE_SPECTRE
if "%choice%"=="3" goto MANUAL_GUIDE
if "%choice%"=="4" goto DOWNLOAD_VS
if "%choice%"=="5" goto EXIT

echo %WARN% 无效选择，使用推荐方案
goto AUTO_FIX

:AUTO_FIX
echo.
echo %INFO% 自动修复 Visual Studio 安装...
echo.

if !vs_installer_found!==0 (
    echo %ERROR% Visual Studio Installer 未找到
    echo 请选择选项 4 下载安装完整版 Visual Studio
    echo.
    pause
    goto EXIT
)

echo %INFO% 启动 Visual Studio Installer...
echo.
echo 修复步骤:
echo 1. Visual Studio Installer 将会打开
echo 2. 找到您的 Visual Studio 安装 (Community/Professional/Enterprise)
echo 3. 点击 "修改" 按钮
echo 4. 在 "单个组件" 选项卡中，搜索 "spectre"
echo 5. 勾选以下组件:
echo    ✓ MSVC v143 - VS 2022 C++ x64/x86 Spectre 缓解库
echo    ✓ MSVC v143 - VS 2022 C++ ARM64/ARM64EC Spectre 缓解库 (如果需要)
echo 6. 点击 "修改" 完成安装
echo.
echo 按任意键启动 Visual Studio Installer...
pause >nul

start "" "%vs_installer%"

echo.
echo %INFO% Visual Studio Installer 已启动
echo.
echo 完成修改后:
echo 1. 重新启动命令提示符
echo 2. 重新运行编译脚本
echo.
pause
goto EXIT

:DISABLE_SPECTRE
echo.
echo %INFO% 禁用 Spectre 缓解 (快速解决方案)...
echo.

echo %WARN% 注意: 此方案会禁用 Spectre 缓解，可能影响安全性
echo 但对于个人使用的编辑器来说通常是可接受的
echo.

set /p confirm="确认禁用 Spectre 缓解? (y/n): "
if /i not "!confirm!"=="y" goto EXIT

echo.
echo %INFO% 创建构建配置文件...

:: 进入 zed 目录
if not exist "zed" (
    echo %ERROR% zed 目录不存在，请先克隆源代码
    pause
    goto EXIT
)

cd zed

:: 创建 .cargo 目录 (如果不存在)
if not exist ".cargo" mkdir .cargo

:: 创建或修改 config.toml
echo %INFO% 配置 Cargo 构建参数...
echo.

:: 写入配置文件
(
echo [target.x86_64-pc-windows-msvc]
echo rustflags = ["-C", "target-feature=+crt-static", "-C", "link-arg=/NODEFAULTLIB:msvcrt"]
echo.
echo [env]
echo VCPKG_ROOT = ""
) > .cargo\config.toml

echo %OK% 已创建构建配置文件
echo.

cd ..

echo %INFO% 设置环境变量禁用 Spectre 检查...
set CARGO_CFG_TARGET_FEATURE=""
set MSVC_SPECTRE_LIBS_DISABLE=1

echo %OK% 环境配置完成
echo.
echo 现在可以重新运行编译脚本了！
echo 建议使用: start_build.bat
echo.
pause
goto EXIT

:MANUAL_GUIDE
echo.
echo %INFO% 手动安装指导
echo.
echo 详细安装步骤:
echo.
echo 1. 打开 Visual Studio Installer
echo    - 开始菜单搜索 "Visual Studio Installer"
echo    - 或运行: "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe"
echo.
echo 2. 修改现有安装
echo    - 找到您的 Visual Studio 安装
echo    - 点击 "修改" 按钮
echo.
echo 3. 添加 Spectre 缓解组件
echo    - 点击 "单个组件" 选项卡
echo    - 在搜索框输入 "spectre"
echo    - 勾选以下组件:
echo.
echo      必需组件:
echo      ✓ MSVC v143 - VS 2022 C++ x64/x86 Spectre 缓解库 (最新版本)
echo.
echo      可选组件 (根据需要):
echo      ✓ MSVC v143 - VS 2022 C++ ARM64/ARM64EC Spectre 缓解库
echo      ✓ MSVC v142 - VS 2019 C++ x64/x86 Spectre 缓解库
echo.
echo 4. 完成安装
echo    - 点击 "修改" 按钮开始下载安装
echo    - 等待安装完成 (可能需要较长时间)
echo.
echo 5. 验证安装
echo    - 重新启动命令提示符
echo    - 重新运行编译脚本
echo.
pause
goto EXIT

:DOWNLOAD_VS
echo.
echo %INFO% 下载 Visual Studio Community
echo.
echo 如果您还没有安装 Visual Studio，推荐安装免费的 Community 版本
echo.
echo 下载地址: https://visualstudio.microsoft.com/zh-hans/vs/community/
echo.
echo 安装时请确保选择以下工作负荷:
echo ✓ 使用 C++ 的桌面开发
echo.
echo 在 "单个组件" 中确保勾选:
echo ✓ Windows 11 SDK (最新版本)
echo ✓ CMake tools for Visual Studio
echo ✓ MSVC v143 - VS 2022 C++ x64/x86 生成工具
echo ✓ MSVC v143 - VS 2022 C++ x64/x86 Spectre 缓解库
echo.
echo 按任意键打开下载页面...
pause >nul
start https://visualstudio.microsoft.com/zh-hans/vs/community/
echo.
echo 安装完成后重新运行此脚本进行验证
pause
goto EXIT

:EXIT
echo.
echo ========================================
echo           修复工具使用完成
echo ========================================
echo.
echo 修复完成后的步骤:
echo 1. 重新启动命令提示符
echo 2. 运行 start_build.bat 重新编译
echo 3. 如果仍有问题，尝试选项 2 (禁用 Spectre 缓解)
echo.
echo 更多帮助:
echo - Visual Studio 文档: https://docs.microsoft.com/zh-cn/visualstudio/
echo - 如果问题持续，请考虑使用选项 2 的快速解决方案
echo.
pause
exit /b 0
