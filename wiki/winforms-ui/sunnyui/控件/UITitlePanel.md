# UITitlePanel — 带标题面板

> raw 原文：`raw/SunnyUI文档/控件/UITitlePanel.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：无
- 带独立标题栏的容器，可折叠

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 标题文本 |
| `ShowCollapse` | bool | false | 是否显示折叠按钮 |
| `Collapsed` | bool | false | 是否当前折叠 |
| `TitleHeight` | int | 35 | 标题栏高度 |
| `TitleInterval` | int | 10 | 标题文字距边框距离 |
| `TitleAlign` | HorizontalAlignment | Center | 标题对齐 |
| `TitleColor` | Color | - | 标题栏颜色 |
| `RadiusSides` | UICornerRadiusSides | All | 圆角显示位置 |
| `Radius` | int | 5 | 圆角角度 |
| `RectSides` | ToolStripStatusLabelBorderSides | All | 边框显示位置 |
| `TextAlign` | ContentAlignment | MiddleCenter | 文字对齐 |

颜色：FillColor / RectColor / ForeColor + Disable 三色。

## ⚠️ 陷阱

**标题栏高度内不可放置其他控件**——TitleHeight 区域是控件内部保留区，放进去的子控件会被遮挡或异常显示。子控件请放到 TitleHeight 下方。

## 与同类容器对比

| 容器 | 标题 | 可折叠 | 适用 |
| --- | --- | --- | --- |
| [UIPanel](UIPanel.md) | 否 | 否 | 通用容器 |
| [UIGroupBox](UIGroupBox.md) | 嵌边框 | 否 | 经典 GroupBox |
| **UITitlePanel** | 独立色块 | 是 | 折叠面板 / 卡片式分组 |
