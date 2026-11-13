# feiq2013.exe HiDPI patch - by 海鸥
# 原理:exe 内嵌 manifest 声明 <dpiAware>true</dpiAware>,自称支持 DPI 但界面全按 96DPI 硬编码,
#       Windows 因此拒绝拉伸,3K 高分屏上显示极小。
# 本补丁把 manifest 里 <application>...(dpiAware)...</application> 整块替换成等长空格:
#   - 文件总长度、资源段偏移完全不变,不破坏 PE 资源表
#   - XML 合法(根元素内空白合法),dpiAware 声明消失 => 进程按 DPI-unaware 处理
#   - Windows DWM 自动按缩放比位图放大(200% 就是 2x),显示大小恢复正常
# 用法: powershell -ExecutionPolicy Bypass -File .\patch_hidpi.ps1 [-Source feiq2013.exe] [-Dest feiq2013_hidpi.exe]

param(
    [string]$Source = "$PSScriptRoot\feiq2013.exe",
    [string]$Dest   = "$PSScriptRoot\feiq2013_hidpi.exe"
)

$ErrorActionPreference = "Stop"
$bytes = [System.IO.File]::ReadAllBytes($Source)

function Find-BytePattern([byte[]]$haystack, [byte[]]$needle, [int]$from) {
    $last = $haystack.Length - $needle.Length
    for ($i = $from; $i -le $last; $i++) {
        if ($haystack[$i] -ne $needle[0]) { continue }
        $j = 1
        while ($j -lt $needle.Length -and $haystack[$i + $j] -eq $needle[$j]) { $j++ }
        if ($j -eq $needle.Length) { return $i }
    }
    return -1
}

$tagBytes    = [System.Text.Encoding]::ASCII.GetBytes('<application xmlns="urn:schemas-microsoft-com:asm.v3">')
$endBytes    = [System.Text.Encoding]::ASCII.GetBytes('</application>')
$markerBytes = [System.Text.Encoding]::ASCII.GetBytes('ms_windowsSettings:dpiAware')

$start = Find-BytePattern $bytes $tagBytes 0
if ($start -lt 0) { throw "manifest application block not found - wrong target binary" }
if ((Find-BytePattern $bytes $tagBytes ($start + 1)) -ge 0) { throw "multiple application blocks - abort for manual review" }

$end = Find-BytePattern $bytes $endBytes $start
if ($end -lt 0) { throw "closing application tag not found" }
$end = $end + $endBytes.Length   # exclusive

if ((Find-BytePattern $bytes $markerBytes $start) -lt 0 -or (Find-BytePattern $bytes $markerBytes $start) -ge $end) {
    throw "no dpiAware declaration inside application block - already patched?"
}

$origLen = $bytes.Length
$patched = New-Object byte[] $origLen
[Array]::Copy($bytes, $patched, $origLen)
for ($i = $start; $i -lt $end; $i++) { $patched[$i] = 0x20 }   # equal-length space fill

if ($patched.Length -ne $origLen) { throw "internal error: length changed" }
for ($i = 0; $i -lt $origLen; $i++) {
    if ($bytes[$i] -ne $patched[$i] -and ($i -lt $start -or $i -ge $end)) {
        throw ("internal error: modified byte outside block at offset 0x{0:X}" -f $i)
    }
}

[System.IO.File]::WriteAllBytes($Dest, $patched)

# verification pass
$check = [System.IO.File]::ReadAllBytes($Dest)
if ((Find-BytePattern $check $markerBytes 0) -ge 0) { throw "verification failed: dpiAware residue" }
Write-Host ("patched OK: {0}" -f $Dest)
Write-Host ("block range : 0x{0:X} - 0x{1:X} ({2} bytes replaced with spaces)" -f $start, $end, ($end - $start))
Write-Host ("file size   : {0} bytes (original {1}, identical)" -f $check.Length, $origLen)
Write-Host "verification: dpiAware declaration removed"
