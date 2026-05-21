# UIRadioButtonGroup — 单选框组

> raw 原文：`raw/SunnyUI文档/控件/UIRadioButtonGroup.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Items` ｜ **默认事件**：`ValueChanged`

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Items` | ObjectCollection | - | 单选项集合 |
| `SelectedIndex` | int | -1 | 当前选中索引 |
| `Text` | string | - | 标题文本 |
| `ColumnCount` | int | 1 | 显示列数 |
| `ColumnInterval` / `RowInterval` | int | 0 / 0 | 列/行间距 |
| `ItemSize` | Size | 150, 30 | 单项大小 |
| `StartPos` | Point | 12, 12 | 起始位置 |
| `TitleTop` / `TitleInterval` / `TitleAlignment` | - | 16 / 10 / Left | 标题布局 |
| `Radius` / `RadiusSides` / `RectSides` / `TextAlign` | - | - | 圆角与边框（同 UIButton） |

颜色：FillColor / RectColor / ForeColor + Disable 三色。

## 事件

```csharp
public delegate void OnValueChanged(object sender, int index, string text);
```

| 参数 | 含义 |
| --- | --- |
| `sender` | 当前控件 |
| `index` | 选中索引（SelectedIndex） |
| `text` | 选中项文本 |

## 函数方法

| 方法 | 用途 |
| --- | --- |
| `SelectedNone()` | 全不选 |
| `SelectedIndex = 6` | 设置选中项 |
| `Clear()` | 清空 |

## 与 UICheckBoxGroup 对比

| 控件 | 选择数 | ValueChanged 参数 |
| --- | --- | --- |
| UIRadioButtonGroup | 单选 | `(sender, index, text)` |
| [UICheckBoxGroup](UICheckBoxGroup.md) | 多选 | `(sender, index, text, isChecked)` |
