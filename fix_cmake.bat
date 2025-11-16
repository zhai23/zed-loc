@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo        CMake 安装和环境修复工具
echo ========================================
echo.

set "INFO=[信息]"
set "OK=[成功]"
set "ERROR=[错误]"
set "WARN=[警告]"

echo %INFO% 检查 CMake 安装状态...

:: 检查 CMake 是否已安装
cmake --version >nul 2>&1
if not errorlevel 1 (
    echo %OK% CMake 已安装:
    cmake --version
    echo.
    echo 如果编译仍然失败，请尝试重新启动命令提示符
    pause
    exit /b 0
)

echo %WARN% CMake 未找到或未添加到 PATH
echo.

echo 解决方案选择:
echo 1. 自动下载安装 CMake (推荐)
echo 2. 使用 Chocolatey 安装 (如果已安装 Chocolatey)
echo 3. 使用 winget 安装 (Windows 10/11)
echo 4. 手动安装指导
echo 5. 退出
echo.

set /p choice="请选择 [1-5]: "

if "%choice%"=="1" goto AUTO_INSTALL
if "%choice%"=="2" goto CHOCO_INSTALL
if "%choice%"=="3" goto WINGET_INSTALL
if "%choice%"=="4" goto MANUAL_INSTALL
if "%choice%"=="5" goto EXIT

echo %WARN% 无效选择，使用自动安装
goto AUTO_INSTALL

:AUTO_INSTALL
echo.
echo %INFO% 开始自动下载安装 CMake...
echo.

:: 创建临时目录
if not exist temp mkdir temp
cd temp

echo 正在下载 CMake 安装程序...
echo 这可能需要几分钟时间，请耐心等待...

:: 下载最新版本的 CMake
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $response = Invoke-WebRequest -Uri 'https://api.github.com/repos/Kitware/CMake/releases/latest' -UseBasicParsing; $json = $response.Content | ConvertFrom-Json; $asset = $json.assets | Where-Object { $_.name -like '*windows-x86_64.msi' } | Select-Object -First 1; if ($asset) { Write-Host 'Downloading:' $asset.name; Invoke-WebRequest -Uri $asset.browser_download_url -OutFile 'cmake-installer.msi' } else { throw 'CMake installer not found' } } catch { Write-Host 'Download failed, using fallback URL'; Invoke-WebRequest -Uri 'https://github.com/Kitware/CMake/releases/download/v3.30.5/cmake-3.30.5-windows-x86_64.msi' -OutFile 'cmake-installer.msi' } }"

if not exist cmake-installer.msi (
    echo %ERROR% 下载失败
    echo.
    echo 请尝试以下替代方案:
    echo 1. 重新运行此脚本选择其他安装方式
    echo 2. 手动访问 https://cmake.org/download/ 下载安装
    echo 3. 检查网络连接后重试
    cd ..
    rmdir /s /q temp >nul 2>&1
    pause
    exit /b 1
)

echo %OK% 下载完成，启动安装程序...
echo.
echo 重要提示:
echo 1. 安装时请勾选 "Add CMake to system PATH for all users"
echo 2. 或勾选 "Add CMake to system PATH for current user"
echo 3. 安装完成后需要重新启动命令提示符
echo.
pause

:: 启动安装程序
start /wait msiexec /i cmake-installer.msi

echo %INFO% 安装程序执行完成
cd ..
rmdir /s /q temp >nul 2>&1
goto VERIFY_INSTALL

:CHOCO_INSTALL
echo.
echo %INFO% 使用 Chocolatey 安装 CMake...

:: 检查 Chocolatey 是否可用
choco --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Chocolatey 未安装或不可用
    echo 请访问 https://chocolatey.org/install 安装 Chocolatey
    echo 或选择其他安装方式
    pause
    exit /b 1
)

echo 正在安装 CMake...
choco install cmake -y

if errorlevel 1 (
    echo %ERROR% Chocolatey 安装失败
    pause
    exit /b 1
)

goto VERIFY_INSTALL

:WINGET_INSTALL
echo.
echo %INFO% 使用 winget 安装 CMake...

:: 检查 winget 是否可用
winget --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% winget 不可用 (需要 Windows 10 1709+ 或 Windows 11)
    echo 请选择其他安装方式
    pause
    exit /b 1
)

echo 正在搜索并安装 CMake...
winget install Kitware.CMake

if errorlevel 1 (
    echo %ERROR% winget 安装失败
    pause
    exit /b 1
)

goto VERIFY_INSTALL

:MANUAL_INSTALL
echo.
echo %INFO% 手动安装指导
echo.
echo 请按照以下步骤手动安装 CMake:
echo.
echo 1. 访问 CMake 官网: https://cmake.org/download/
echo.
echo 2. 下载 "Binary distributions" 下的 Windows x64 Installer:
echo    例如: cmake-3.30.5-windows-x86_64.msi
echo.
echo 3. 运行下载的安装程序
echo.
echo 4. 安装时重要设置:
echo    ✓ 勾选 "Add CMake to system PATH for all users"
echo    或 "Add CMake to system PATH for current user"
echo.
echo 5. 完成安装后:
echo    - 重新启动命令提示符
echo    - 运行 "cmake --version" 验证安装
echo    - 重新运行编译脚本
echo.
echo 6. 如果仍然提示 CMake 未找到:
echo    - 手动添加 CMake 安装目录到系统 PATH
echo    - 通常位于: C:\Program Files\CMake\bin
echo.
pause
goto EXIT

:VERIFY_INSTALL
echo.
echo %INFO% 验证 CMake 安装...
echo.

:: 刷新环境变量 (尝试)
call :REFRESH_PATH

:: 检查 CMake 是否现在可用
cmake --version >nul 2>&1
if errorlevel 1 (
    echo %WARN% 当前会话中仍然检测不到 CMake
    echo.
    echo 这通常是正常的！请执行以下步骤:
    echo.
    echo 1. 关闭当前命令提示符窗口
    echo 2. 重新打开新的命令提示符窗口
    echo 3. 运行 "cmake --version" 验证安装
    echo 4. 如果显示版本号，重新运行 start_build.bat
    echo.
    echo 如果仍然无法使用，请:
    echo - 检查系统 PATH 是否包含 CMake 安装目录
    echo - 重新启动计算机
    echo - 手动添加 CMake 到 PATH 环境变量
) else (
    echo %OK% CMake 安装成功！
    cmake --version
    echo.
    echo 现在可以重新运行编译脚本了！
)

echo.
echo 按任意键退出...
pause >nul
goto EXIT

:REFRESH_PATH
:: 尝试刷新当前会话的环境变量
for /f "skip=2 tokens=3*" %%a in ('reg query HKCU\Environment /v PATH 2^>nul') do set "USER_PATH=%%b"
for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SYSTEM_PATH=%%b"
if defined USER_PATH set "PATH=%SYSTEM_PATH%;%USER_PATH%"
goto :EOF

:EXIT
echo.
echo 更多帮助信息:
echo - CMake 官网: https://cmake.org/
echo - 如果问题持续，请检查 Visual Studio Build Tools 是否正确安装
echo - 编译需要完整的 C++ 构建环境
exit /b 0
