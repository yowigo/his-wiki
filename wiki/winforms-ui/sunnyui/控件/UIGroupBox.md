# UIGroupBox — 组框

> raw 原文：`raw/SunnyUI文档/控件/UIGroupBox.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：无
- 用途：带标题的分组容器

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 标题文本 |
| `TitleTop` | int | 16 | 标题高度 |
| `TitleInterval` | int | 10 | 标题显示间隔 |
| `TitleAlignment` | HorizontalAlignment | Left | 标题对齐 |
| `RadiusSides` | UICornerRadiusSides | All | 圆角显示位置 |
| `Radius` | int | 5 | 圆角角度 |
| `RectSides` | ToolStripStatusLabelBorderSides | All | 边框显示位置 |
| `TextAlign` | ContentAlignment | MiddleCenter | 文字对齐 |

颜色：FillColor / RectColor / ForeColor + Disable 三色。

## 与 UITitlePanel 的区别

- **UIGroupBox**：标题嵌入边框线（经典 GroupBox 样式）
- **UITitlePanel**：标题独立色块、可折叠（带 ShowCollapse）
