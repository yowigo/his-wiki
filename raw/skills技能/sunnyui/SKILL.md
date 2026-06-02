---
name: sunnyui
description: SunnyUI WinForms 控件库开发护栏。AI 在创建或修改 SunnyUI 窗体/控件代码前强制走检查表，统一控件命名、AutoScaleMode、主题、颜色、字体、DPI、字体图标等团队约定。触发关键词：SunnyUI、UIForm、UIForm2、UIPage、UILoginForm、Sunny.UI、UIButton、UISymbolButton、UIPanel、UIDataGridView、UIEdit、UIComboBox、UINavMenu、winform 窗体、SunnyUI 控件、HIS 插件 UI、上海药事插件 UI。
---

# sunnyui — SunnyUI 开发护栏

让团队成员通过 AI 写出的 SunnyUI 窗体/控件代码**风格一致**：命名一致、主题一致、字体一致、DPI 适配一致、颜色定制方式一致。**AI 写 SunnyUI 代码前必须逐项走完本检查表，违反任一项不得直接动手——必须反问用户或主动 Read 权威源后再继续。**

---

## 强制触发条件（满足任一即必须调用）

- 用户主动调用 `/sunnyui`
- 任务涉及**创建**新窗体且项目使用 SunnyUI（csproj/packages.config 含 `SunnyUI`）
- 任务涉及**修改** SunnyUI 窗体（继承 `UIForm` / `UIForm2` / `UIPage` / `UILoginForm`）
- 任务涉及向窗体**添加/修改** SunnyUI 控件（命名以 `UI` 开头：UIButton / UIPanel / UIDataGridView 等）
- 用户表达"加一个界面/按钮/输入框/列表/弹窗"，且项目使用 SunnyUI

满足触发条件时**不得直接进入实现**——必须先按顺序走完下列 Steps。

---

## Step 0 — 必读权威源（强制 Read）

写代码前必须 Read 以下文件：

1. `his-wiki/wiki/winforms-ui/sunnyui/index.md` — 全局陷阱 + 通用属性约定
2. 即将使用的具体控件页（如 `his-wiki/wiki/winforms-ui/sunnyui/控件/UIButton.md`）

**找不到对应控件页时**（控件不在 his-wiki/raw/SunnyUI文档/控件/ 收录的 20 个内）→ 立即反问用户："这个控件 his-wiki 没收录，是否要先去 Gitee 现查、还是先记 TODO 后续补 wiki？"——**不要凭训练数据脑补控件属性**。

---

## Step 1 — 项目环境自检

| 检查项 | 不通过的处置 |
| --- | --- |
| 项目 csproj/packages.config 引用 SunnyUI | 反问用户是否用 Nuget 引入；不擅自加包 |
| .NET Framework **不是** "4 Client Profile" | 报错请用户改成完整 .Net Framework 4.0+ |
| 主窗体有 `UIStyleManager` 控件 | 反问"主窗体是否已有 UIStyleManager？没有需要现在加吗？" |
| app.manifest 含 `dpiAware=true` | 提示用户加（**不擅自加**）；引用 his-wiki/wiki/winforms-ui/sunnyui/多页面框架/DPI缩放自适应方案.md |

---

## Step 2 — 窗体级强制约定

写新窗体或修改现有窗体时，**这些项必须成立**：

| 项目 | 约束 |
| --- | --- |
| 窗体基类 | 必须 `UIForm` / `UIForm2` / `UIPage` / `UILoginForm`；**禁** `System.Windows.Forms.Form` |
| using | 必须 `using Sunny.UI;` |
| AutoScaleMode | 窗体和**所有自定义 UserControl** 设 `AutoScaleMode = AutoScaleMode.None`；UIForm/UIPage 自带 None，但自定义 UserControl 默认是 Font，**必须手改** |
| 多页面 | 用 `UIPage + PageIndex` + IFrame 的 `AddPage/ExistPage/SelectPage`；**禁** `IsMdiContainer = true` |
| 标题栏内放控件 | UITitlePanel 的 TitleHeight 区域内**不放子控件** |

---

## Step 3 — 控件命名约定（团队风格统一核心）

| 控件类型 | 前缀 | 示例 |
| --- | --- | --- |
| UIButton / UISymbolButton | `btn` | `btnSave`、`btnCancel`、`btnSubmit` |
| UIEdit / UITextBox / UIRichTextBox | `txt` | `txtUserName`、`txtRemark` |
| UILabel / UILinkLabel / UISymbolLabel / UIMarkLabel / UILedLabel | `lbl` | `lblTitle`、`lblStatus` |
| UICheckBox / UICheckBoxGroup | `chk` | `chkAgree`、`chkGrpRoles` |
| UIRadioButton / UIRadioButtonGroup | `rdo` | `rdoMale`、`rdoGrpGender` |
| UIComboBox / UIComboTreeView / UIComboDataGridView | `cmb` | `cmbCity`、`cmbDept` |
| UIDataGridView | `grid` | `gridOrders`、`gridDetail` |
| UIPanel / UIGroupBox / UITitlePanel / UISymbolPanel | `pnl` | `pnlForm`、`pnlHeader`、`pnlSearch` |
| UISwitch | `swt` | `swtEnable`、`swtAutoPrint` |
| UIDatePicker / UIDatetimePicker / UITimePicker | `dt` | `dtStart`、`dtBirthday` |
| UIAvatar | `ava` | `avaUser` |
| UIBreadcrumb | `bcr` | `bcrPath` |
| UILedDisplay / UILedStopwatch | `led` | `ledStatus`、`ledTimer` |
| UINavMenu / UINavBar | `nav` | `navMain`、`navTop` |
| UITabControl | `tab` | `tabMain` |
| UITreeView | `tree` | `treeMenu` |
| UIPagination | `pg` | `pgList` |

**严禁**：

- IDE 自动命名：`uiButton1` / `uiPanel1` / `uiCheckBox1` 等带数字后缀的默认名
- 拼音命名：`anNiu1` / `wenBenKuang1`
- 不带前缀的语义命名：`Save` / `UserName`（与字段/方法混淆）

**发现违反时**：

1. 反问用户："这个控件按 sunnyui skill 默认（如 `btnSave`）命名，还是项目已有别的约定？"
2. 用户确认前**不直接重命名现有控件**——避免破坏既有事件绑定

---

## Step 4 — 颜色与主题

| 项目 | 约束 |
| --- | --- |
| 控件默认 Style | `UIStyle.Inherited`（继承全局主题） |
| 全局主题切换 | 走 `UIStyleManager.Style`，不在单个控件改 |
| 硬编码 ARGB | **禁** `Color.FromArgb(r, g, b)` 之类直接写死颜色 |
| 自定义颜色合法路径 | **同时** 设 `Style = UIStyle.Custom` **和** `StyleCustomMode = true`——缺一不可，缺一被主题覆盖 |

**发现需要自定义颜色时**：

1. 先反问用户："这个颜色需要走 UIStyleManager 统一定（推荐，后续切主题自动同步），还是单独硬编（只本控件生效，切主题不变）？"
2. 用户选硬编时，再设 Style=Custom + StyleCustomMode=true

---

## Step 5 — 字体

| 项目 | 约束 |
| --- | --- |
| 控件级 Font / FontFamily / Size | **禁** 在单个控件设 |
| 全局字体来源 | `UIStyleManager.GlobalFont` + `GlobalFontName` + `GlobalFontScale` |
| 字号换算 | `字号 = 12 × GlobalFontScale / 100`；默认 Scale=100 即 12px |

**发现要改字号时**：反问"这是全局调整（走 GlobalFontScale）还是单控件特殊？"——单控件特殊需要充分理由。

---

## Step 6 — 字体图标（UISymbolButton / UISymbolLabel / UIAvatar）

| 项目 | 约束 |
| --- | --- |
| Symbol 编号 | **禁** 凭直觉/训练数据填编号 |
| 选编号合法路径 | 先反问用户语义（保存/关闭/搜索/打印/设置 等）→ 查 his-wiki 或 Gitee 字体图标速查页 → 拿到准确编号 |
| SymbolSize | 必须配套设；UISymbolButton 默认 24，UIAvatar 默认 45 |
| 居中陷阱 | 字体图标非等宽等高，UISymbolButton 居中偏移时设 `ImageAlign = TopLeft` + `Padding = 5,5,0,0` |

---

## Step 7 — 控件陷阱自查（写完成代码前再看一遍）

| 陷阱 | 自查方式 |
| --- | --- |
| UILedDisplay / UILedLabel / UILedStopwatch 不支持中文 | 凡是塞了中文 → 改成 UILabel 或 UISymbolLabel |
| UICheckBoxGroup ValueChanged 签名（V3.6.0+） | 新签名 `(object sender, CheckBoxGroupEventArgs e)`，**不是**旧 `(sender, index, text, isChecked)` |
| UITitlePanel 标题栏内不能放子控件 | 子控件必须放 `TitleHeight` 下方 |
| UIRadioButton 同容器互斥 | 同容器内按 `GroupIndex` 分组；多组互斥用不同 GroupIndex |
| UILedDisplay 调宽度 | 不要改 `Width`，改 `CharCount` |
| .NET 6/7 下 Symbol 没右键按钮 | 改运行环境为 .NetFramework，或手填编号 |
| MDI | SunnyUI 不支持 `IsMdiContainer=true`，用 UIPage 多页框架 |

---

## Step 8 — 必须反问用户的场景（不要替用户决策）

| 情形 | 反问语模板 |
| --- | --- |
| 控件命名前缀冲突 | "命名按 sunnyui skill 约定（如 `btnSave`）还是沿用项目现有的（如 `XX`）？" |
| 控件未在 his-wiki 收录 | "这个控件 wiki 没收录，要我去 Gitee 现查、还是先记 TODO 后续补 wiki？" |
| 颜色定制 | "走 UIStyleManager 统一（推荐）还是单独硬编（切主题不同步）？" |
| 字号特殊 | "这是全局调整（GlobalFontScale）还是单控件特殊？" |
| 字体图标编号 | "你要什么语义的图标？保存/关闭/搜索/...，我帮你查准编号" |
| 主窗体没 UIStyleManager | "要现在加 UIStyleManager 吗？还是这次先不加？" |
| app.manifest 没 dpiAware | "项目 app.manifest 还没启用 dpiAware，要现在加吗？" |
| 现有控件命名违反约定 | "现有 `xxx` 命名不符约定，要顺便重命名吗（注意会改事件绑定）？" |

---

## 违反检查表的处理流程

1. 发现违反 → **立即停下**，不要继续往下写代码
2. 在用户可见的回应里**明确说**违反了哪一项
3. 按 Step 8 模板反问用户：是按 skill 约定改、还是这次破例
4. 收到用户答复后才继续

**不允许**："顺便""我觉得"地擅自决定。

---

## 与 his-wiki 的关系

- 本 skill = **行为规范**（写代码时该做什么、不该做什么）
- his-wiki/wiki/winforms-ui/sunnyui/ = **查询手册**（控件具体属性、用法）
- 两者互补：skill 强制 AI 在写代码前去 Read 手册，并按手册里的"全局陷阱"自查

每个 Step 引用的 wiki 路径不会随版本变化，但 wiki 内容会随 SunnyUI 版本同步——以 `his-wiki/wiki/winforms-ui/sunnyui/index.md` 头部"raw 同步版本"为准。
