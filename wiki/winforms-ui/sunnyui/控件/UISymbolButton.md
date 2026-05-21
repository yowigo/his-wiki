# UISymbolButton — 字体图标按钮

> raw 原文：`raw/SunnyUI文档/控件/UISymbolButton.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`Click`
- 在 [UIButton](UIButton.md) 基础上增加字体图标支持，外加图片/圆形按钮能力

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Text` | string | - | 显示文本 |
| `Symbol` | int | 61452 | 字体图标编号 |
| `SymbolSize` | int | 24 | 图标大小 |
| `Image` | Image | - | 自定义图片（与 Symbol 互斥） |
| `ImageAlign` | ContentAlignment | MiddleCenter | 图片放置位置 |
| `ImageInterval` | int | 2 | 图标/图片与文字间隔 |
| `IsCircle` | bool | false | 是否圆形按钮 |
| `CircleRectWidth` | int | 1 | 圆形按钮边框大小 |
| `RadiusSides` / `Radius` / `RectSides` | - | All / 5 / All | 圆角和边框 |
| `TextAlign` | ContentAlignment | MiddleCenter | 文字对齐 |
| `Selected` | bool | false | 是否选中 |
| `DialogResult` | DialogResult | None | 对话框返回值 |
| `ShowFocusLine` | bool | false | 显示激活时边框线 |
| `ShowTips` / `TipsText` / `TipsFont` / `TipsColor` | bool / string / Font / Color | false / - / - / Red | 角标 |
| `UseDoubleClick` | bool | false | 启用双击 |

## 颜色矩阵（同 UIButton：7 状态 × 3 类型）

普通 / 不可用 / 悬停 / 按下 / 选中 × Fill / Rect / Fore，共 15 个颜色属性（详见 [UIButton.md](UIButton.md)）。

## 常用用法

- **圆形按钮**：`IsCircle = true`，`CircleRectWidth` 控制边框粗细
- **按钮组**：左/中/右按钮分别设 `RadiusSides`：
  - 左：`LeftTop, LeftBottom`
  - 中：`None`
  - 右：`RightTop, RightBottom`
- **自定义图片**：设 `Image` 属性（与 Symbol 二选一显示）

## ⚠️ 字体图标不居中

字体图标**非等宽等高**，居中容易偏移。**解决方案**：

```csharp
btn.ImageAlign = ContentAlignment.TopLeft;
btn.Padding = new Padding(5, 5, 0, 0);  // 按需微调
```

详见 [入门/字体图标.md](../入门/字体图标.md)。
