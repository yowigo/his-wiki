# UICheckBoxGroup — 多选框组

> raw 原文：`raw/SunnyUI文档/控件/UICheckBoxGroup.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Items` ｜ **默认事件**：`ValueChanged`

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Items` | ObjectCollection | - | 多选框组中项的集合 |
| `Text` | string | - | 显示文本 |
| `ColumnCount` | int | 1 | 显示列数 |
| `ColumnInterval` | int | 0 | 列间距 |
| `RowInterval` | int | 0 | 行间距 |
| `ItemSize` | Size | 150, 30 | 单项大小 |
| `StartPos` | Point | 12, 12 | 起始位置 |
| `TitleTop` | int | 16 | 标题高度 |
| `TitleInterval` | int | 10 | 标题显示间隔 |
| `TitleAlignment` | HorizontalAlignment | Left | 标题对齐 |
| `Radius` / `RadiusSides` / `RectSides` / `TextAlign` | - | - | 圆角与边框（同 UIButton） |

颜色：FillColor / RectColor / ForeColor + Disable 三色（同标准模式）。

## 事件

```csharp
public delegate void OnValueChanged(object sender, int index, string text, bool isChecked);
```

| 参数 | 含义 |
| --- | --- |
| `sender` | 当前控件 |
| `index` | 选中索引 |
| `text` | 选中项文本 |
| `isChecked` | 当前选中状态 |

> V3.6.0 起 ValueChanged 签名变化，详见 [升级指南/3.5.2-3.6.0.md](../升级指南/3.5.2-3.6.0.md)。

## 函数方法

| 方法 / 属性 | 用途 |
| --- | --- |
| `SelectAll()` | 全选 |
| `UnSelectAll()` | 全不选 |
| `ReverseSelected()` | 反选 |
| `Clear()` | 清空 |
| `SelectedIndexes = new List<int>{ 2, 4 }` | 设置选中项（索引列表） |
| `SelectedIndexes` | 选中索引列表 |
| `SelectedItems` | 选中项列表 |

## 用法

- 设计期：通过 `Items` 编辑器添加项
- **多列显示**：设 `ColumnCount = 2` 等
