# SunnyUI 子站

> raw 同步版本：**V3.9.7**（2026-05-14） ｜ 子站建立日期：**2026-05-21** ｜ 整理者：**Keiskei**

SunnyUI 是基于 .NET Framework 4.0+ / .NET6+ 的 C# WinForm 开源控件库，参考 Element 设计风格。开源地址：[gitee.com/yhuse/SunnyUI](https://gitee.com/yhuse/SunnyUI)。

**许可证警告**：个人学习交流免费，**商业/公司项目使用需联系作者授权**（QQ 17612584）。HIS 插件商用场景必走授权流程。

---

## 全局陷阱（写第一行代码前必看）

| 陷阱 | 解决方案 | 引用 |
| --- | --- | --- |
| 自定义颜色编辑期生效、运行期被主题覆盖 | 同时设 `Style = UIStyle.Custom` **和** `StyleCustomMode = true`；缺一不可 | [入门/主题.md](入门/主题.md) |
| 窗体在高分屏 / DPI 缩放下变形 | UIForm / UIPage / 自定义 UserControl 全部 `AutoScaleMode = None` + app.manifest 启用 `dpiAware=true` + UIStyleManager.DPIScale = true（编译时 DPI 必须 100%） | [多页面框架/DPI缩放自适应方案.md](多页面框架/DPI缩放自适应方案.md) |
| UIForm 不能做 MDI 容器 | SunnyUI 自带多页框架（IFrame + UIPage + PageIndex），不支持 `IsMdiContainer=true` | [多页面框架/简述及示例.md](多页面框架/简述及示例.md) |
| UISymbolButton 字体图标不居中 | 字体图标非等宽等高；设 `ImageAlign=TopLeft` + `Padding=5,5,0,0` 微调 | [控件/UISymbolButton.md](控件/UISymbolButton.md) |
| UILedDisplay / UILedLabel / UILedStopwatch 不支持中文 | 仅支持英文、数字、标点、希腊字母 | [控件/UILedDisplay.md](控件/UILedDisplay.md) |
| 工具箱拖控件失败 / SunnyUI.dll 无可放置组件 | 检查项目不是 `.Net Framework 4 Client Profile`；工具箱与项目引用版本一致 | [入门/常见问题.md](入门/常见问题.md) |
| .NET 6/7 下 Symbol 没有点选按钮、UINavBar 报错 | 这是 .NET WinForms 设计器问题，建议项目运行环境换回 .NetFramework | [入门/常见问题.md](入门/常见问题.md) |

---

## 通用属性约定（所有 SunnyUI 控件都有）

| 属性 | 类型 | 含义 |
| --- | --- | --- |
| `Style` | `UIStyle` | 主题样式；可选 Blue/Green/Orange/Red/Gray/Purple/LayuiGreen/LayuiRed/LayuiOrange/DarkBlue/Black/Custom/Inherited/Dark |
| `StyleCustomMode` | `bool` | 设 true 才接受用户自定义颜色（不被主题覆盖） |
| `Version` | `string` | 控件版本（只读） |
| `TagString` | `string` | 控件附加数据字符串 |

控件页面内不再重复这 4 个；只列控件**特有**属性。

---

## 子站结构

### 入门（必读）

- [安装.md](入门/安装.md) — Nuget / 手动 DLL 引用、工具箱安装
- [主题.md](入门/主题.md) — Color/Rect/Radius/Font/Style 五大主题维度
- [字体图标.md](入门/字体图标.md) — FontAwesome / ElegantIcons 用法
- [国际化.md](入门/国际化.md) — V3.7.2+ 多语言切换（CultureInfos + TranslateHelper）
- [常见问题.md](入门/常见问题.md) — 12 个高频踩坑解答

### 控件（20 个）

完整一览表见 [控件/index.md](控件/index.md)。按功能分组：

- **按钮/选择**：[UIButton](控件/UIButton.md) ｜ [UISymbolButton](控件/UISymbolButton.md) ｜ [UISwitch](控件/UISwitch.md) ｜ [UICheckBox](控件/UICheckBox.md) ｜ [UICheckBoxGroup](控件/UICheckBoxGroup.md) ｜ [UIRadioButton](控件/UIRadioButton.md) ｜ [UIRadioButtonGroup](控件/UIRadioButtonGroup.md)
- **文本/标签**：[UILabel](控件/UILabel.md) ｜ [UILinkLabel](控件/UILinkLabel.md) ｜ [UIMarkLabel](控件/UIMarkLabel.md) ｜ [UISymbolLabel](控件/UISymbolLabel.md)
- **容器**：[UIPanel](控件/UIPanel.md) ｜ [UIGroupBox](控件/UIGroupBox.md) ｜ [UITitlePanel](控件/UITitlePanel.md)
- **导航**：[UIBreadcrumb](控件/UIBreadcrumb.md)
- **展示/工控**：[UIAvatar](控件/UIAvatar.md) ｜ [UIBattery](控件/UIBattery.md) ｜ [UILedDisplay](控件/UILedDisplay.md) ｜ [UILedLabel](控件/UILedLabel.md) ｜ [UILedStopwatch](控件/UILedStopwatch.md)

### 窗体

- [UIForm.md](窗体/UIForm.md) — 标准窗体基类（圆角/阴影/扩展按钮/拖拽缩放）
- [UILoginForm.md](窗体/UILoginForm.md) — 登录窗体基类

### 多页面框架

- [简述及示例.md](多页面框架/简述及示例.md) — IFrame 的三个核心方法（AddPage/ExistPage/SelectPage）
- [DPI缩放自适应方案.md](多页面框架/DPI缩放自适应方案.md) — 高分屏不变形三步
- [全局字体设置.md](多页面框架/全局字体设置.md) — GlobalFont / GlobalFontScale

### 工具类库

- [IniFile.md](工具类库/IniFile.md) — Ini 文件读写类（中文支持、Section/Name/Value）
- [IniConfig.md](工具类库/IniConfig.md) — 基于反射的 Ini 配置文件类
- [Json.md](工具类库/Json.md) — 简易 Json 静态类（不依赖 Newtonsoft）

### 升级指南

- [3.5.2-3.6.0.md](升级指南/3.5.2-3.6.0.md) — 主题重构、UICheckBoxGroup ValueChanged 签名变更

---

## raw 原文位置

- 本机：`C:\Users\xuyilai\Desktop\his-wiki\raw\SunnyUI文档\`
- 在线：[gitee.com/yhuse/SunnyUI/wikis](https://gitee.com/yhuse/SunnyUI/wikis)

raw 是只增不改的原始资料（含截图）；本子站是 AI 优先精简化重写。**遇到版本不一致以 raw 为准，再以 gitee 为准。**
