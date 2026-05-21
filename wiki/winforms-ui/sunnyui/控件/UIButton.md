# UIButton — 常用操作按钮

> raw 原文：`raw/SunnyUI文档/控件/UIButton.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`Click`
- 通用属性（Style / StyleCustomMode / Version / TagString）见 [子站 index.md](../index.md)

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `RadiusSides` | UICornerRadiusSides | All | 圆角显示位置 |
| `Radius` | int | 5 | 圆角角度 |
| `RectSides` | ToolStripStatusLabelBorderSides | All | 边框显示位置 |
| `TextAlign` | ContentAlignment | MiddleCenter | 文字对齐 |
| `Selected` | bool | false | 是否选中 |
| `DialogResult` | DialogResult | None | 对话框返回值 |
| `ShowFocusLine` | bool | false | 显示激活时边框线 |
| `ShowTips` | bool | false | 是否显示角标 |
| `TipsText` / `TipsFont` / `TipsColor` | string / Font / Color | - / - / Red | 角标文字/字体/颜色 |
| `UseDoubleClick` | bool | false | 是否启用双击事件 |

## 颜色属性（共 7 组 × 3 = 21 个）

按状态分组：

| 状态 | Fill | Rect | Fore |
| --- | --- | --- | --- |
| 普通 | FillColor | RectColor | ForeColor |
| 不可用 | FillDisableColor | RectDisableColor | ForeDisableColor |
| 悬停 | FillHoverColor | RectHoverColor | ForeHoverColor |
| 按下 | FillPressColor | RectPressColor | ForePressColor |
| 选中 | FillSelectedColor | RectSelectedColor | ForeSelectedColor |

## 常用用法

- **圆角按钮 / 胶囊按钮**：`Size: 100,35` + `Radius: 35`（Radius = Height）
- **自定义颜色**：`Style = UIStyle.Custom` + `StyleCustomMode = true`，再改 FillColor 等
- **按钮组左中右**：左按钮 `RadiusSides = LeftTop, LeftBottom`，中按钮 `None`，右按钮 `RightTop, RightBottom`
