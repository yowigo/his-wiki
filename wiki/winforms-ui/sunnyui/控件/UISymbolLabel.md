# UISymbolLabel — 字体图标标签

> raw 原文：`raw/SunnyUI文档/控件/UISymbolLabel.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`Click`
- 简化版 [UISymbolButton](UISymbolButton.md)，纯文本 + 图标，无背景/边框/按下态

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `AutoSize` | bool | true | 自动大小 |
| `Symbol` | int | 61452 | 字体图标编号 |
| `SymbolColor` | Color | - | 图标颜色（独立于 ForeColor） |
| `SymbolSize` | int | 24 | 图标大小 |
| `ImageInterval` | int | 2 | 图标与文字间隔 |
| `TextAlign` | ContentAlignment | MiddleCenter | 文字对齐 |
| `ForeColor` | Color | - | 字体颜色 |

> 字体图标选择见 [入门/字体图标.md](../入门/字体图标.md)。

## 与 UISymbolButton 的区别

- **UISymbolButton**：按钮——有背景填充、边框、按下/悬停/选中状态颜色
- **UISymbolLabel**：标签——纯展示，无边框/无背景/无交互状态色，但可独立设 SymbolColor 与 ForeColor
- **场景**：菜单项前缀图标、状态栏图标 → UISymbolLabel；可点击按钮 → UISymbolButton
