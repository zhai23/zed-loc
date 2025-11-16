# Windows Zed 自动编译 PowerShell 脚本
# 需要预先安装：VS BuildTools, Python 3.10, Git, Rust

param(
    [string]$Backend = "vulkan",  # vulkan, opengl, both
    [switch]$Clean,               # 清理构建
    [switch]$Help                 # 显示帮助
)

# 显示帮助信息
if ($Help) {
    Write-Host @"
Zed Windows 自动编译脚本

用法: .\build_windows_fixed.ps1 [-Backend <vulkan|opengl|both>] [-Clean] [-Help]

参数:
  -Backend   指定构建后端 (vulkan|opengl|both) [默认: vulkan]
  -Clean     清理之前的构建
  -Help      显示此帮助信息

示例:
  .\build_windows_fixed.ps1                    # 构建 Vulkan 版本
  .\build_windows_fixed.ps1 -Backend opengl    # 构建 OpenGL 版本
  .\build_windows_fixed.ps1 -Backend both      # 构建两个版本
  .\build_windows_fixed.ps1 -Clean             # 清理构建
"@
    exit 0
}

# 设置控制台编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色函数
function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    switch ($Color) {
        "Red"    { Write-Host $Text -ForegroundColor Red }
        "Green"  { Write-Host $Text -ForegroundColor Green }
        "Yellow" { Write-Host $Text -ForegroundColor Yellow }
        "Blue"   { Write-Host $Text -ForegroundColor Blue }
        "Cyan"   { Write-Host $Text -ForegroundColor Cyan }
        default  { Write-Host $Text }
    }
}

function Write-Step {
    param([string]$Message)
    Write-ColorText "[步骤] $Message" "Blue"
}

function Write-Success {
    param([string]$Message)
    Write-ColorText "[成功] $Message" "Green"
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-ColorText "[错误] $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorText "[警告] $Message" "Yellow"
}

# 检查命令是否存在
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# 主函数
function Main {
    Write-ColorText "========================================" "Cyan"
    Write-ColorText "    Windows Zed 自动编译脚本 (PowerShell)" "Cyan"
    Write-ColorText "========================================" "Cyan"
    Write-Host

    # 检查必要工具
    Write-Step "检查编译环境..."

    if (-not (Test-Command "python")) {
        Write-ErrorMsg "Python 未找到，请安装 Python 3.10"
        exit 1
    }
    Write-Success "Python 已安装: $(python --version 2>&1)"

    if (-not (Test-Command "git")) {
        Write-ErrorMsg "Git 未找到，请安装 Git"
        exit 1
    }
    Write-Success "Git 已安装: $(git --version 2>&1)"

    if (-not (Test-Command "cargo")) {
        Write-ErrorMsg "Rust/Cargo 未找到，请从 https://rustup.rs/ 安装"
        exit 1
    }
    Write-Success "Rust/Cargo 已安装: $(cargo --version 2>&1)"

    Write-Host

    # 启用长路径支持
    Write-Step "配置环境..."
    try {
        git config --global core.longpaths true
        Write-Success "Git 长路径支持已启用"

        # 尝试启用 Windows 长路径支持
        try {
            New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
            Write-Success "Windows 长路径支持已启用"
        }
        catch {
            Write-Warning "无法设置 Windows 长路径支持 (可能需要管理员权限)"
        }
    }
    catch {
        Write-Warning "配置环境时出现问题，但继续构建"
    }

    Write-Host

    # 检查和准备源代码
    Write-Step "准备 Zed 源代码..."
    if (-not (Test-Path "zed")) {
        Write-Host "克隆 Zed 源代码..."
        try {
            git clone https://github.com/zed-industries/zed.git
            if ($LASTEXITCODE -ne 0) {
                throw "Git clone failed"
            }
            Write-Success "Zed 源代码克隆完成"
        }
        catch {
            Write-ErrorMsg "克隆 Zed 源代码失败: $_"
            exit 1
        }
    } else {
        Write-Host "Zed 目录已存在，更新代码..."
        Push-Location "zed"
        try {
            git fetch origin
            git reset --hard origin/main
            Write-Success "Zed 源代码更新完成"
        }
        catch {
            Write-Warning "更新源代码失败，使用现有版本"
        }
        finally {
            Pop-Location
        }
    }

    Write-Host

    # 应用翻译
    Write-Step "应用中文翻译..."
    try {
        python replace.py
        if ($LASTEXITCODE -ne 0) {
            throw "Translation failed"
        }
        Write-Success "翻译应用完成"
    }
    catch {
        Write-ErrorMsg "翻译应用失败: $_"
        exit 1
    }

    Write-Host

    # 准备 Rust 环境
    Write-Step "准备 Rust 环境..."
    try {
        rustup toolchain install nightly 2>&1 | Out-Null
        rustup target add wasm32-wasip1 2>&1 | Out-Null
        rustup default nightly 2>&1 | Out-Null
        Write-Success "Rust 环境准备完成"
    }
    catch {
        Write-Warning "Rust 环境配置可能有问题，但继续构建"
    }

    Write-Host

    # 创建输出目录
    if (-not (Test-Path "output")) {
        New-Item -ItemType Directory -Name "output" | Out-Null
    }

    # 清理构建（如果需要）
    if ($Clean) {
        Write-Step "清理之前的构建..."
        Push-Location "zed"
        try {
            cargo clean 2>&1 | Out-Null
            Write-Success "构建清理完成"
        }
        finally {
            Pop-Location
        }
        Write-Host
    }

    # 确定要构建的后端
    $buildBackends = @()
    switch ($Backend.ToLower()) {
        "vulkan" { $buildBackends = @("vulkan") }
        "opengl" { $buildBackends = @("opengl") }
        "both"   { $buildBackends = @("vulkan", "opengl") }
        default  {
            Write-Warning "未知的后端类型: $Backend，使用默认的 vulkan"
            $buildBackends = @("vulkan")
        }
    }

    # 构建循环
    foreach ($backend in $buildBackends) {
        Write-Host
        Write-Step "构建 $backend 版本..."

        Push-Location "zed"

        try {
            # 设置环境变量
            if ($backend -eq "vulkan") {
                $env:RUSTFLAGS = ""
                $outputName = "zed-windows.exe"
            } else {
                $env:RUSTFLAGS = "--cfg gles"
                $outputName = "zed-windows-opengl.exe"
            }

            Write-Host "开始编译，这可能需要较长时间..."
            $buildStart = Get-Date

            cargo build --release

            if ($LASTEXITCODE -ne 0) {
                throw "Cargo build failed"
            }

            $buildEnd = Get-Date
            $buildTime = $buildEnd - $buildStart

            # 复制可执行文件
            if (Test-Path "target\release\zed.exe") {
                Copy-Item "target\release\zed.exe" "..\output\$outputName"
                Write-Success "$backend 版本构建完成 (用时: $($buildTime.ToString('mm\:ss')))"
                Write-Host "输出文件: output\$outputName"
            } else {
                throw "构建的可执行文件未找到"
            }
        }
        catch {
            Write-ErrorMsg "$backend 版本构建失败: $_"
            Pop-Location
            exit 1
        }
        finally {
            Pop-Location
        }
    }

    Write-Host
    Write-ColorText "========================================" "Green"
    Write-ColorText "           构建完成！" "Green"
    Write-ColorText "========================================" "Green"
    Write-Host

    Write-ColorText "构建的文件:" "Cyan"
    Get-ChildItem "output\*.exe" | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  $($_.Name) ($size MB)" -ForegroundColor White
    }

    Write-Host
    Write-ColorText "使用说明:" "Yellow"
    Write-Host "1. Vulkan 版本性能更好，但需要较新的显卡驱动"
    Write-Host "2. OpenGL 版本兼容性更好，适合老显卡或虚拟机"
    Write-Host "3. 如遇到图形问题，请尝试 OpenGL 版本"

    Write-Host
    $openFolder = Read-Host "是否打开输出目录？(y/n)"
    if ($openFolder -eq 'y' -or $openFolder -eq 'Y') {
        explorer "output"
    }

    Write-Success "脚本执行完成！"
}

# 执行主函数
try {
    Main
}
catch {
    Write-ErrorMsg "脚本执行失败: $_"
    Write-Host "按任意键退出..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
