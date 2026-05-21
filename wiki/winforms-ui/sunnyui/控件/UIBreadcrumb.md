# UIBreadcrumb — 面包屑导航条

> raw 原文：`raw/SunnyUI文档/控件/UIBreadcrumb.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`ItemIndex` ｜ **默认事件**：`ItemIndexChanged`

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Items` | ObjectCollection | - | 列表项集合 |
| `ItemIndex` | int | 0 | 当前节点索引 |
| `ItemWidth` | int | 120 | 当前节点宽度 |
| `Interval` | int | 1 | 节点间隔 |
| `ForeColor` | Color | - | 字体颜色 |
| `SelectedColor` | Color | - | 已选节点颜色 |
| `UnSelectedColor` | Color | - | 未选节点颜色 |

## 用法要点

设计期通过 `Items` 编辑器添加节点；运行期改 `ItemIndex` 高亮当前节点。点击节点触发 `ItemIndexChanged`。
