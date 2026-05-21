# UIMarkLabel — 带颜色标签

> raw 原文：`raw/SunnyUI文档/控件/UIMarkLabel.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`Click`
- 在文字旁边显示一条短色块标签条纹（左/右/上/下）

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `AutoSize` | bool | true | 自动大小 |
| `ForeColor` | Color | - | 字体颜色 |
| `MarkSize` | int | 3 | 标签条纹大小（宽度） |
| `MarkPos` | UIMarkPos | Left | 标签位置：Left / Right / Top / Bottom |
| `MarkColor` | Color | - | 标签条纹颜色 |

## 用法

适用于侧栏菜单项、状态指示、待办事项前缀等需要"色条 + 文本"组合的场景。
