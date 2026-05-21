# UILedStopwatch — LED 计时器

> raw 原文：`raw/SunnyUI文档/控件/UILedStopwatch.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`TimerTick`
- 用途：秒表 / 倒计时 / 用时显示

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `CharCount` | int | 10 | 显示字符个数（**决定控件宽度**，同 UILedDisplay） |
| `ShowType` | TimeShowType | - | 显示方式 |
| `Active` | bool | false | 是否开始工作（写） |
| `IsWorking` | bool | false | 是否开始工作（读） |
| `TimeSpan` | TimeSpan | - | 开始计时后用去的时间（只读） |
| `BorderColor` / `BorderInColor` / `LedBackColor` | Color | - | 颜色三件套 |
| `BorderWidth` / `BorderInWidth` | int | 1 / 1 | 边框/内线宽度 |
| `IntervalIn` / `IntervalOn` | int | 1 / 2 | LED 亮块间距 / 大小 |
| `IntervalH` / `IntervalV` | int | 2 / 5 | 左右/上下边距 |

## 事件

- `TimerTick`：定时器启动后，**Text 变化时触发一次**（每秒一次）

## 陷阱

- 中文同 [UILedDisplay](UILedDisplay.md) **不支持**
- V3.8.8 起小时显示**可超过 24 小时**（之前会回零）
