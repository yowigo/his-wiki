# UIRadioButton — 单选框

> raw 原文：`raw/SunnyUI文档/控件/UIRadioButton.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Checked` ｜ **默认事件**：`CheckedChanged`

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Checked` | bool | false | 是否选中 |
| `Text` | string | - | 显示文本 |
| `GroupIndex` | int | 0 | **分组编号**（同容器同 GroupIndex 互斥） |
| `AutoSize` | bool | true | 自动大小 |
| `ImageSize` | int | 16 | 图标大小 |
| `ImageInterval` | int | 3 | 图标与文字间隔 |
| `ReadOnly` | bool | false | 是否只读 |
| `ForeColor` | Color | - | 字体颜色 |
| `RadioButtonColor` | Color | - | 单选框填充颜色 |

## 事件

| 事件 | 签名 |
| --- | --- |
| `CheckedChanged` | `event EventHandler(object sender)` |
| `ValueChanged` | `delegate void(object sender, bool value)` |

## 分组规则

在**同一个容器**中，多个 UIRadioButton 按 `GroupIndex` 分组——**同一个 GroupIndex 的只能选中一个**。需要多组互斥时用不同 GroupIndex。

> 比原生 RadioButton 灵活：原生靠"父容器"分组（必须放到不同 GroupBox），SunnyUI 靠 GroupIndex 数值分组，在同一容器内即可分组。
