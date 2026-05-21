# SunnyUI 控件一览表

> raw 同步：V3.9.7 / 2026-05-21 ｜ 共 **20** 个控件

按功能分组的所有控件速查。点击进入对应详细页。

---

## 按钮 & 选择

| 控件 | 默认属性 | 默认事件 | 说明 |
| --- | --- | --- | --- |
| [UIButton](UIButton.md) | Text | Click | 常用操作按钮（圆角/按下/选中/角标） |
| [UISymbolButton](UISymbolButton.md) | Text | Click | 字体图标按钮（含圆形/按钮组） |
| [UISwitch](UISwitch.md) | Active | ValueChanged | 开关 |
| [UICheckBox](UICheckBox.md) | Checked | CheckedChanged | 复选框 |
| [UICheckBoxGroup](UICheckBoxGroup.md) | Items | ValueChanged | 多选框组（多列/全选/反选） |
| [UIRadioButton](UIRadioButton.md) | Checked | CheckedChanged | 单选框（**GroupIndex 分组**） |
| [UIRadioButtonGroup](UIRadioButtonGroup.md) | Items | ValueChanged | 单选框组（多列） |

## 文本 & 标签

| 控件 | 默认属性 | 默认事件 | 说明 |
| --- | --- | --- | --- |
| [UILabel](UILabel.md) | Text | Click | 最简标签 |
| [UILinkLabel](UILinkLabel.md) | Text | Click | 超链接标签 |
| [UIMarkLabel](UIMarkLabel.md) | Text | Click | 带色条标签 |
| [UISymbolLabel](UISymbolLabel.md) | Text | Click | 字体图标标签 |

## 容器

| 控件 | 默认属性 | 默认事件 | 说明 |
| --- | --- | --- | --- |
| [UIPanel](UIPanel.md) | Text | Click | 通用面板 |
| [UIGroupBox](UIGroupBox.md) | Text | - | 嵌边框标题的组框 |
| [UITitlePanel](UITitlePanel.md) | Text | - | 独立标题栏面板，**可折叠** |

## 导航

| 控件 | 默认属性 | 默认事件 | 说明 |
| --- | --- | --- | --- |
| [UIBreadcrumb](UIBreadcrumb.md) | ItemIndex | ItemIndexChanged | 面包屑导航条 |

## 展示 & 工控

| 控件 | 默认属性 | 默认事件 | 说明 | 限制 |
| --- | --- | --- | --- | --- |
| [UIAvatar](UIAvatar.md) | Symbol | Click | 头像（字体图标/图片/文字） | - |
| [UIBattery](UIBattery.md) | Power | - | 电池电量图标 | - |
| [UILedDisplay](UILedDisplay.md) | Text | - | LED 点阵显示屏 | ⚠️ 不支持中文 |
| [UILedLabel](UILedLabel.md) | Text | Click | LED 点阵标签 | ⚠️ 不支持中文 |
| [UILedStopwatch](UILedStopwatch.md) | Text | TimerTick | LED 计时器 | ⚠️ 不支持中文 |

---

## 通用约定（适用所有控件）

所有 SunnyUI 控件都有这 4 个通用属性，控件页不再重复：

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Style` | UIStyle | Blue | 主题样式（见 [入门/主题.md](../入门/主题.md)） |
| `StyleCustomMode` | bool | false | 自定义颜色必须设 true 才生效 |
| `Version` | string | - | 控件版本（只读） |
| `TagString` | string | - | 控件附加数据字符串 |

## 通用陷阱

- **自定义颜色被主题覆盖**：必须 `Style = Custom` + `StyleCustomMode = true` 同时设置
- **LED 系列三个控件不支持中文**：仅 ASCII 字符（英文/数字/标点/希腊字母）
- **窗体级陷阱**（DPI / MDI / 字体）：见 [子站 index.md](../index.md#全局陷阱写第一行代码前必看)

---

## raw 范围说明

**当前仅整理了 raw/SunnyUI文档/控件/ 下已存在的 20 个**。SunnyUI 官方还有 60+ 控件（如 UIDataGridView / UIComboBox / UIEdit / UIPagination / UINavMenu / UINavBar / UITreeView / UILineChart / UIBarChart / UIDatePicker / UIDateTimePicker / UITabControl / UIPage / UIDataGridViewFooter 等），等项目实际用到时再补到 raw 然后 wiki 化。

需要时可参考 raw 之外的官方文档：[gitee.com/yhuse/SunnyUI/wikis](https://gitee.com/yhuse/SunnyUI/wikis)
