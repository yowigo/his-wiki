# UILedLabel — LED 标签

> raw 原文：`raw/SunnyUI文档/控件/UILedLabel.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`Click`
- 单行 LED 点阵风格的标签

## ⚠️ 字符限制

**仅支持英文、数字、标点符号、希腊字母，不支持中文。**

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `BackColor` | Color | - | 背景颜色 |
| `ForeColor` | Color | - | 字体颜色 |
| `IntervalIn` | int | 1 | LED 亮块间距 |
| `IntervalOn` | int | 2 | LED 亮块大小 |

> 比 [UILedDisplay](UILedDisplay.md) 简单：无边框、无 CharCount——按文本长度自适应宽度。
