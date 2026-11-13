# 撤销 apply_hidpi_compat.ps1 写入的兼容层标记,恢复原状。
# 用法: powershell -ExecutionPolicy Bypass -File .\restore_hidpi_compat.ps1 [exe 路径 ...]

param(
    [string[]]$Paths = @("C:\Users\snzzz\Desktop\feiq2013.exe", "$PSScriptRoot\feiq2013.exe", "$PSScriptRoot\feiq2013_hidpi.exe")
)

$ErrorActionPreference = "Stop"
$key = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

foreach ($p in $Paths) {
    if (Test-Path $key) {
        $prop = Get-ItemProperty -Path $key -Name $p -ErrorAction SilentlyContinue
        if ($prop) {
            Remove-ItemProperty -Path $key -Name $p
            Write-Host ("removed: {0}" -f $p)
        } else {
            Write-Host ("clean (no entry): {0}" -f $p)
        }
    }
}
Write-Host "done. 重启飞秋生效。"
