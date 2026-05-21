# UIAvatar — 头像

> raw 原文：`raw/SunnyUI文档/控件/UIAvatar.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Symbol` ｜ **默认事件**：`Click`
- 三种显示方式：字体图标（Symbol） / 图片（Image） / 文字（Text）

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `AvatarSize` | int | 60 | 头像大小 |
| `Icon` | UIIcon | Symbol | 显示方式：Symbol / Image / Text |
| `Symbol` | int | 61452 | 字体图标编号 |
| `SymbolColor` | Color | - | 图标颜色 |
| `SymbolSize` | int | 45 | 字体图标大小 |
| `Text` | string | - | 文字内容（Icon=Text 时用） |
| `Image` | Image | - | 图片（Icon=Image 时用） |
| `Shape` | UIShape | Circle | 显示形状：Circle / Square |
| `OffsetX` / `OffsetY` | int | 0 / 0 | 水平 / 垂直偏移 |
| `ForeColor` / `FillColor` | Color | - / - | 字体 / 填充颜色 |

## 用法要点

- **切换显示方式**：设 `Icon` 属性
- **方形头像**：`Shape = Square`（默认 Circle）
- **字体图标选择**：见 [入门/字体图标.md](../入门/字体图标.md)
