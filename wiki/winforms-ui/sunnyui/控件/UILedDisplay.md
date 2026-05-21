# UILedDisplay — LED 显示屏

> raw 原文：`raw/SunnyUI文档/控件/UILedDisplay.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：无
- 用途：工控/数据大屏的 LED 点阵显示效果

## ⚠️ 字符限制

**仅支持英文、数字、标点符号、希腊字母，不支持中文。**

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `CharCount` | int | 10 | 显示字符个数（**决定控件宽度**） |
| `BorderColor` | Color | - | 边框颜色 |
| `BorderInColor` | Color | - | 内线颜色 |
| `LedBackColor` | Color | - | LED 背景色 |
| `BorderWidth` | int | 1 | 边框宽度 |
| `BorderInWidth` | int | 1 | 内线宽度 |
| `IntervalIn` | int | 1 | LED 亮块间距 |
| `IntervalOn` | int | 2 | LED 亮块大小 |
| `IntervalH` | int | 2 | 左右边距 |
| `IntervalV` | int | 5 | 上下边距 |

## 陷阱

- **调宽度不要改 Width**——模拟点阵显示屏，宽度由字符数决定 → **改 `CharCount`**
- **中文显示不出来**——只支持 ASCII 范围，要显示中文用 [UILabel](UILabel.md) 或 [UISymbolLabel](UISymbolLabel.md)
