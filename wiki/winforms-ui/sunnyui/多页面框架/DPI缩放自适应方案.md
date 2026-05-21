# DPI 缩放自适应方案

> raw 原文：`raw/SunnyUI文档/多页面框架/DPI缩放自适应方案.md` ｜ raw 同步：V3.9.7 / 2026-05-21

WinForm 窗体在高分屏 + 系统 DPI 缩放下会变形（字体/控件/布局放大或错位）。SunnyUI 的方案：**窗体和字体在 DPI 缩放下都不变形**。

---

## 三步组合（缺一不可）

### 第 1 步：所有窗体/UserControl 设 AutoScaleMode = None

**目的**：禁止窗体因字体大小自动缩放。

| 控件 | 默认 AutoScaleMode | 是否需要手改 |
| --- | --- | --- |
| UIForm / UIForm2 | None（V3.x 起已自动） | 不需要 |
| UIPage | None | 不需要 |
| UIUserControl | None | 不需要 |
| **自定义 UserControl** | **Font** | **必须改为 None** |

### 第 2 步：app.manifest 启用 dpiAware

**目的**：禁止窗体因 DPI 缩放变形。

右键工程 → 添加应用程序清单 `app.manifest`，修改：

```xml
<application xmlns="urn:schemas-microsoft-com:asm.v3">
  <windowsSettings>
    <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true</dpiAware>
    <longPathAware xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">true</longPathAware>
  </windowsSettings>
</application>

<!-- 启用 Windows 公共控件主题 -->
```

### 第 3 步：UIStyleManager 设 DPIScale = true

**目的**：DPI 缩放后字体大小不变。

**关键前提**：**编译时屏幕 DPI 缩放必须为 100%**！

1. Windows 显示设置 → 缩放 = 100%
2. 主窗体上放一个 `UIStyleManager`
3. 设 `DPIScale = true`
4. 编译

编译完成的 SunnyUI.Demo.exe 可在不同 DPI 缩放下测试。

---

## 自检清单

- [ ] 所有自定义 UserControl 的 AutoScaleMode 都设为 None
- [ ] app.manifest 已添加并启用 dpiAware
- [ ] UIStyleManager.DPIScale = true
- [ ] 编译时屏幕 DPI = 100%
- [ ] 在 125% / 150% / 200% 缩放下测试

## 配合全局字体

DPI 适配 + 全局字体可叠加：[全局字体设置.md](全局字体设置.md)。
