# UIPanel — 面板

> raw 原文：`raw/SunnyUI文档/控件/UIPanel.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`Click`
- 通用容器面板，支持圆角、边框、主题色

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `TextAlignment` | ContentAlignment | MiddleCenter | 文字对齐方向 |
| `RadiusSides` | UICornerRadiusSides | All | 圆角显示位置 |
| `Radius` | int | 5 | 圆角角度 |
| `RectSides` | ToolStripStatusLabelBorderSides | All | 边框显示位置 |
| `TextAlign` | ContentAlignment | MiddleCenter | （同 TextAlignment，向后兼容） |

颜色：FillColor / RectColor / ForeColor + Disable 三色。

## 与同类容器对比

| 控件 | 是否有标题 | 是否可折叠 | 适用 |
| --- | --- | --- | --- |
| UIPanel | 否 | 否 | 通用容器 |
| [UIGroupBox](UIGroupBox.md) | 是（嵌边框） | 否 | 经典 GroupBox 风格 |
| [UITitlePanel](UITitlePanel.md) | 是（独立色块） | 是 | 折叠面板 |
