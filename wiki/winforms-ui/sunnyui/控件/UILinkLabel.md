# UILinkLabel — 超链接标签

> raw 原文：`raw/SunnyUI文档/控件/UILinkLabel.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`Click`

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `ForeColor` | Color | - | 字体颜色 |
| `LinkColor` | Color | - | 普通链接颜色 |
| `ActiveLinkColor` | Color | - | 活动链接颜色（鼠标按下时） |
| `VisitedLinkColor` | Color | - | 已访问链接颜色 |

> 行为类似 WinForms 原生 `LinkLabel`，但配色按 SunnyUI 主题统一管理。**点击事件用 Click**，没有特殊的 LinkClicked。
