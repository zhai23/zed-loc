@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo      Zed 中文版快速编译启动器
echo ========================================
echo.

set "INFO=[信息]"
set "OK=[成功]"
set "ERROR=[错误]"
set "WARN=[警告]"

:: 检查是否在正确的目录
if not exist "zh.json" (
    echo %ERROR% 请在 zed-loc 项目根目录运行此脚本
    echo        当前目录: %CD%
    echo        应该包含: zh.json, replace.py 等文件
    pause
    exit /b 1
)

echo %INFO% 开始 Zed 中文版编译流程...
echo.

:: 快速检查必要工具
echo %INFO% 检查编译环境...

python --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Python 未安装，请先运行 setup.bat 检查环境
    pause
    exit /b 1
)

git --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Git 未安装，请先运行 setup.bat 检查环境
    pause
    exit /b 1
)

cargo --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Rust 未安装，请先运行 setup.bat 检查环境
    pause
    exit /b 1
)

echo %OK% 编译环境检查通过
echo.

:: 显示菜单
:MENU
echo ========================================
echo         选择编译选项
echo ========================================
echo.
echo 1. 快速编译 (Vulkan版本，推荐)
echo 2. 兼容编译 (OpenGL版本)
echo 3. 完整编译 (两个版本都编译)
echo 4. 清理重新编译
echo 5. 检查系统环境
echo 6. 退出
echo.
set /p choice="请输入选项 [1-6]: "

if "%choice%"=="1" goto BUILD_VULKAN
if "%choice%"=="2" goto BUILD_OPENGL
if "%choice%"=="3" goto BUILD_BOTH
if "%choice%"=="4" goto CLEAN_BUILD
if "%choice%"=="5" goto CHECK_ENV
if "%choice%"=="6" goto EXIT
echo %WARN% 无效选择，请重新输入
echo.
goto MENU

:BUILD_VULKAN
echo.
echo %INFO% 开始 Vulkan 版本编译...
call :DO_BUILD vulkan
goto FINISH

:BUILD_OPENGL
echo.
echo %INFO% 开始 OpenGL 版本编译...
call :DO_BUILD opengl
goto FINISH

:BUILD_BOTH
echo.
echo %INFO% 开始完整编译 (两个版本)...
call :DO_BUILD both
goto FINISH

:CLEAN_BUILD
echo.
echo %INFO% 清理之前的构建...
if exist "zed\target" (
    cd zed
    cargo clean
    cd ..
    echo %OK% 清理完成
) else (
    echo %WARN% 没有找到构建缓存
)
echo.
goto MENU

:CHECK_ENV
echo.
echo %INFO% 启动环境检查工具...
call setup.bat
goto EXIT

:DO_BUILD
set "build_type=%1"

:: 启用长路径支持
git config --global core.longpaths true

:: 检查/克隆源代码
if not exist "zed" (
    echo %INFO% 克隆 Zed 源代码...
    git clone https://github.com/zed-industries/zed.git
    if errorlevel 1 (
        echo %ERROR% 克隆失败
        goto ERROR_EXIT
    )
) else (
    echo %INFO% 更新 Zed 源代码...
    cd zed
    git fetch origin >nul 2>&1
    git reset --hard origin/main >nul 2>&1
    cd ..
)

:: 应用翻译
echo %INFO% 应用中文翻译...
python replace.py
if errorlevel 1 (
    echo %ERROR% 翻译应用失败
    goto ERROR_EXIT
)

:: 准备 Rust 环境
echo %INFO% 准备 Rust 环境...
rustup toolchain install nightly >nul 2>&1
rustup target add wasm32-wasip1 >nul 2>&1
rustup default nightly >nul 2>&1

:: 创建输出目录
if not exist "output" mkdir output

:: 记录开始时间
set "start_time=%time%"

:: 根据类型进行编译
if "%build_type%"=="vulkan" (
    call :BUILD_SINGLE vulkan
) else if "%build_type%"=="opengl" (
    call :BUILD_SINGLE opengl
) else if "%build_type%"=="both" (
    call :BUILD_SINGLE vulkan
    if errorlevel 1 goto ERROR_EXIT
    call :BUILD_SINGLE opengl
)

goto :EOF

:BUILD_SINGLE
set "backend=%1"
echo.
echo %INFO% 编译 %backend% 版本...

cd zed

if "%backend%"=="vulkan" (
    set "RUSTFLAGS="
    set "output_name=zed-chinese-vulkan.exe"
) else (
    set "RUSTFLAGS=--cfg gles"
    set "output_name=zed-chinese-opengl.exe"
)

echo %INFO% 开始 Cargo 构建 (这将需要一些时间)...
cargo build --release
if errorlevel 1 (
    echo %ERROR% 编译失败
    cd ..
    goto ERROR_EXIT
)

if exist "target\release\zed.exe" (
    copy "target\release\zed.exe" "..\output\%output_name%" >nul
    echo %OK% %backend% 版本编译完成: output\%output_name%
) else (
    echo %ERROR% 找不到编译输出
    cd ..
    goto ERROR_EXIT
)

cd ..
goto :EOF

:FINISH
echo.
echo ========================================
echo          编译完成！
echo ========================================

:: 计算耗时
set "end_time=%time%"

echo.
echo %INFO% 构建结果:
if exist "output\zed-chinese-vulkan.exe" (
    echo   ✓ Vulkan 版本: output\zed-chinese-vulkan.exe
)
if exist "output\zed-chinese-opengl.exe" (
    echo   ✓ OpenGL 版本: output\zed-chinese-opengl.exe
)

echo.
echo %INFO% 使用说明:
echo   • Vulkan 版本: 性能更好，适合现代显卡
echo   • OpenGL 版本: 兼容性更好，适合老显卡或虚拟机

echo.
set /p open_folder="是否打开输出目录？ (y/n): "
if /i "!open_folder!"=="y" explorer output

echo.
set /p run_app="是否现在运行 Zed？ (y/n): "
if /i "!run_app!"=="y" (
    if exist "output\zed-chinese-vulkan.exe" (
        start "" "output\zed-chinese-vulkan.exe"
    ) else if exist "output\zed-chinese-opengl.exe" (
        start "" "output\zed-chinese-opengl.exe"
    )
)

goto EXIT

:ERROR_EXIT
echo.
echo %ERROR% 编译过程中发生错误
echo.
echo 故障排除建议:
echo 1. 检查网络连接
echo 2. 重新运行 setup.bat 检查环境
echo 3. 尝试清理重新编译 ^(选项 4^)
echo 4. 查看上方错误信息
echo 5. 如果提示缺少 CMake，请运行 fix_cmake.bat
echo.
pause
goto EXIT

:EXIT
echo.
echo 感谢使用 Zed 中文版编译工具！
echo 如有问题请查看 BUILD_README.md
pause >nul
