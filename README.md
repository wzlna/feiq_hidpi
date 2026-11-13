# feiq2013 HiDPI 修复 - 工作笔记

## 根因

feiq2013.exe (PE32 x86, 18MB, 纯 Win32 + GDI+, 非 Qt/Delphi) 内嵌 manifest 声明:

```xml
<ms_windowsSettings:dpiAware ...>true</ms_windowsSettings:dpiAware>
```

自称支持 DPI,实际界面全是 96DPI 硬编码像素(代码里只有 GetDeviceCaps/CreateFont,
无 SetProcessDpiAwareness 调用)。Windows 因此**不做任何拉伸**,16寸 3K 屏
(系统缩放 200%,逻辑分辨率 1600x1000)上按物理像素绘制,小得像蚂蚁。

## 修复产物

| 文件 | 说明 |
|---|---|
| `feiq2013_hidpi.exe` | 打过补丁的改版。manifest 中 `<application>(dpiAware)</application>` 块被等长空格替换(0x11710BB-0x11711F0, 309 bytes),文件尺寸与资源偏移零变动,dpiAware 声明消失 => Windows 按 DPI-unaware 自动位图放大。SHA256 原版 `480FF41B...` / 补丁版 `18A21925...` |
| `patch_hidpi.ps1` | 补丁脚本,可复现(字节级操作 + 完整性校验) |
| `apply_hidpi_compat.ps1` | 注册表兼容层 `~ DPIUNAWARE`,不换 exe 直接修原版(HKCU AppCompatFlags\Layers) |
| `restore_hidpi_compat.ps1` | 一键还原注册表改动 |
| `manifest_extracted.xml` | 原版 manifest 全文 |

## 用法

```powershell
# 方案A:直接用改版 exe
.\feiq2013_hidpi.exe

# 方案B:原版 exe + 兼容层(已对桌面版生效)
powershell -ExecutionPolicy Bypass -File .\apply_hidpi_compat.ps1

# 还原
powershell -ExecutionPolicy Bypass -File .\restore_hidpi_compat.ps1
```

注意:
- 补丁版和原版**不要同时开**(单实例互斥,且局域网重复上线)。
- 位图放大会略糊。想更锐利把 apply 脚本里的 `~ DPIUNAWARE` 换成 `~ GDISCALED`
  ("系统(增强)"缩放),GDI 文字渲染更清晰,个别界面元素可能异常,自己试。
- 两种方案均需重启飞秋生效。
