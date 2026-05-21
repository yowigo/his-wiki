# UICheckBox — 复选框

> raw 原文：`raw/SunnyUI文档/控件/UICheckBox.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Checked` ｜ **默认事件**：`CheckedChanged`

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Checked` | bool | false | 是否选中 |
| `Text` | string | - | 显示文本 |
| `AutoSize` | bool | true | 自动大小 |
| `ImageSize` | int | 16 | 图标大小 |
| `ImageInterval` | int | 3 | 图标与文字间隔 |
| `ReadOnly` | bool | false | 是否只读 |
| `ForeColor` | Color | - | 字体颜色 |
| `CheckBoxColor` | Color | - | 复选框填充颜色 |

## 事件

| 事件 | 签名 | 参数 |
| --- | --- | --- |
| `CheckedChanged` | `event EventHandler` | sender |
| `ValueChanged` | `delegate void(object sender, bool value)` | sender + value（Checked 当前值） |

两个事件都会触发——`CheckedChanged` 更通用，`ValueChanged` 可直接拿到布尔值。
