# HiDPI 兼容层 - 一键应用。把飞秋标记为 DPI-unaware,Windows 自动位图放大。
# 适用于:不想换 exe、直接修原版的情况(比如桌面 C:\Users\snzzz\Desktop\feiq2013.exe)。
# 用法: powershell -ExecutionPolicy Bypass -File .\apply_hidpi_compat.ps1 [exe 路径 ...]
# 恢复: powershell -ExecutionPolicy Bypass -File .\restore_hidpi_compat.ps1

param(
    [string[]]$Paths = @("C:\Users\snzzz\Desktop\feiq2013.exe", "$PSScriptRoot\feiq2013.exe", "$PSScriptRoot\feiq2013_hidpi.exe")
)

$ErrorActionPreference = "Stop"
$key = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }

foreach ($p in $Paths) {
    if (-not (Test-Path $p)) { Write-Host ("skip (not found): {0}" -f $p); continue }
    # ~ DPIUNAWARE = "替代高DPI缩放行为: 缩放执行方 = 系统"
    # 备选 ~ GDISCALED = "系统(增强)",GDI 文字更锐利,兼容性略差,自己换着试
    Set-ItemProperty -Path $key -Name $p -Value "~ DPIUNAWARE"
    Write-Host ("applied: {0} -> ~ DPIUNAWARE" -f $p)
}
Write-Host "done. 重启飞秋生效。"
