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

## 验证

- `verify_before.png` / `verify_after.png`:修复前后桌面截图对比。
- 实测重启后主窗 2x 拉伸,在线列表 28 人正常加载,协议功能无影响
  (manifest 改动不影响网络栈)。

## 飞秋协议调研(回答"有没有人重构过")

**有,而且很多。** 飞秋协议本质是 IP Messenger (ipmsg) 协议的扩展变体:

- 传输:UDP 2425(消息/在线发现),TCP 2425(文件/目录传输)
- 报文:GB2312 明文,`版本:包编号:用户:主机:命令字:附加段` 冒号分段
- 命令字是位掩码(IPMSG_BR_ENTRY / IPMSG_SENDMSG / IPMSG_FILEATTACH ...),
  飞秋在标准 ipmsg 上加了私有扩展(表情、气泡、群组等)

已知开源兼容实现(GitHub 实搜):

| 项目 | 语言 | 说明 |
|---|---|---|
| iptux | C++/GTK | Linux 飞鸽/飞秋互通老牌项目 |
| hyberbin/J-Feiq | Java | 飞秋(飞鸽) IPMSG 协议实现,38★ |
| zyqg/feiq-android | Kotlin | Android FeiQ/IPMsg 客户端,28★ |
| tttmck/feiq-electron | Go+Electron | macOS 客户端,复刻飞秋2013皮肤,与 Windows 飞秋互通 |
| shidong814/FeiQiu | Swift | macOS 飞秋兼容实现 |
| smilearchery/AndroidIpmsg | Java | 兼容 FeiQ 和 Ipmsg |
| huangxiandong/codemsg | TypeScript | VS Code 的 IPMsg 兼容插件 |
| Enaium/ipmsg-rs | Rust | ipmsg/飞鸽/飞秋 兼容 |
| wowzhdang/feiQ-mobile | Java | Android,与 Windows 飞秋传文件 |
| Moxin1044/feiq-virtual-devices | C | 飞秋虚拟设备/消息测试工具 |

安全备忘:Moxin1044/feiq-dos-tool 记录了飞秋 3.0.0.2 UDP 2425 分片接收堆溢出,
局域网明文协议 + 无认证,内网环境别当可信信道用。

结论:想做"支持 HiDPI 的飞秋替代品"完全可行,协议不难,难点只在 UI 还原和
飞秋私有扩展的兼容细节。iptux / J-Feiq 的协议源码可以直接当协议文档读。
