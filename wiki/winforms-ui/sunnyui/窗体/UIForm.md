# UIForm — 标准窗体基类

> raw 原文：`raw/SunnyUI文档/窗体/UIForm.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`Load`
- 用途：所有 SunnyUI 窗体的基类，提供圆角/阴影/扩展按钮/拖拽缩放等能力

## 特有属性（精选）

### 标题栏

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 窗体标题 |
| `TextAlignment` | StringAlignment | - | 标题对齐 |
| `AllowAddControlOnTitle` | bool | false | 允许在标题栏放置子控件 |
| `AllowShowTitle` | bool | true | 是否显示标题栏 |
| `TitleHeight` | int | 35 | 标题栏高度 |
| `TitleColor` | Color | - | 标题栏颜色 |
| `TitleForeColor` | Color | - | 标题前景色 |
| `ShowTitleIcon` | bool | false | 显示标题栏图标 |
| `ShowIcon` | bool | true | 是否显示窗体图标 |

### 控制按钮

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `ControlBox` | bool | true | 显示控制按钮区 |
| `MaximizeBox` | bool | true | 显示最大化按钮 |
| `MinimizeBox` | bool | true | 显示最小化按钮 |

### 扩展按钮（左侧追加按钮）

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `ExtendBox` | bool | false | 显示扩展按钮 |
| `ExtendSymbol` | int | 0 | 扩展按钮字体图标 |
| `ExtendSymbolSize` | int | 24 | 字体图标大小 |
| `ExtendSymbolOffset` | Point | 0, 0 | 字体图标偏移 |
| `ExtendMenu` | UIContextMenuStrip | - | 扩展按钮下拉菜单 |

### 外观

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `ShowRadius` | bool | true | 显示圆角 |
| `ShowRect` | bool | true | 显示边框 |
| `ShowShadow` | bool | false | 显示阴影（V3.6.0+ 默认开） |
| `ShowDragStretch` | bool | false | 边框可拖拽调整窗体大小 |
| `ShowFullScreen` | bool | false | 全屏模式进入最大化 |
| `RectColor` | Color | - | 边框颜色 |
| `ForeColor` | Color | - | 字体颜色 |

### 行为

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `StickyBorderTime` | long | 500 | 显示器边缘吸附停留时间(ms) |
| `IsForbidAltF4` | bool | false | 屏蔽 Alt+F4 |
| `EscClose` | bool | false | 用 Esc 键关闭窗体 |
| `CloseAskString` | string | - | 关闭时提示文字（非空则弹确认） |

## 创建窗体（标准步骤）

1. 引用 SunnyUI.dll + SunnyUI.Common.dll（或 Nuget）
2. 新建窗体 → 把 `Form` 改成 `UIForm`，加 `using Sunny.UI;`
3. **关键**：把窗体 `AutoScaleMode` 从 `Font` 改成 **`None`**（否则因屏幕分辨率变形）
4. 设标题、图标、扩展按钮等

## ⚠️ 全局陷阱

- **AutoScaleMode 必须设 None**——继承的 UIForm 默认已是 None，但用户自定义 UserControl 默认是 Font，需手改
- **不支持 MDI**——`IsMdiContainer = true` 无效，用 [多页面框架](../多页面框架/简述及示例.md) 替代
- **DPI 适配三步走**——见 [多页面框架/DPI缩放自适应方案.md](../多页面框架/DPI缩放自适应方案.md)
