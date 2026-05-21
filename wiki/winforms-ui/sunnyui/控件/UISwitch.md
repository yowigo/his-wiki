# UISwitch — 开关

> raw 原文：`raw/SunnyUI文档/控件/UISwitch.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Active` ｜ **默认事件**：`ValueChanged`

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Active` | bool | false | 是否打开 |
| `ActiveText` | string | 开 | 打开时显示文字 |
| `InActiveText` | string | 关 | 关闭时显示文字 |
| `ActiveColor` | Color | - | 打开背景色 |
| `InActiveColor` | Color | Silver | 关闭背景色 |
| `ButtonColor` | Color | White | 拉杆按钮填充色 |
| `SwitchShape` | UISwitchShape | Round | 形状：Round 圆角 / Square 方角 |
| `ForeColor` | Color | - | 字体颜色 |

## 事件

```csharp
public delegate void OnValueChanged(object sender, bool value);
```

参数 `value` 等于 `Active` 当前值。

## 用法

代码切换状态：直接设 `swt.Active = true / false`，会触发 ValueChanged。
