---
name: his-wiki
version: 0.1.0
description: |
  HIS 知识库（C:\Users\xuyilai\Desktop\his-wiki\）的总管家入口。统一处理 HIS 业务接口、医保、字段字典、DB Schema、SunnyUI 控件、故障案例的查询。
  使用场景：开发上海药事平台/北京医保/苏州医保等外部接口插件，写代码前查接口规范/字段映射/字典含义/DB 表结构；开发 HIS 5.x 后端时查业务流程/子系统交互；调试时按症状查 troubleshooting。
  显式触发：用户输入 `/his-wiki <query>` 时生效。
allowed-tools:
  - Glob
  - Grep
  - Read
---

# /his-wiki — HIS 知识库总管家

被 `/his-wiki <query>` 触发后，按以下流程查询知识库并响应用户。

## 知识库根目录

```
C:\Users\xuyilai\Desktop\his-wiki\
├── schema/          规范层（编码/接口/DB 设计规范、公司禁令）
├── wiki/            编译知识层（整理后的所有 .md）
│   └── index.md     ← 完整目录地图，每次会话第一次触发时必读
└── raw/             原始资料层（只增不改，少用）
```

## 启动流程（每次会话第一次响应 /his-wiki）

1. Read `C:\Users\xuyilai\Desktop\his-wiki\wiki\index.md` 拿到完整目录地图
2. 同会话内 `index.md` 已读则直接复用，不重复读
3. 根据 query 关键词走下方对应分诊路径

## 分诊路径

### 1. 接口开发（信号词：`YY001-YY034` / `Plugins.EB_*` / `function_code` / `func_sign` / 统一事件 / 拓展菜单 / `ProcessRequest`）

**必读**：`wiki/api/plugin-development.md`（含「场景识别」章节—事件型 vs 菜单型判断标准）

**反纠正铁律**（version.json 里的 HIS 故意拼错字段，**任何"自动纠正"都会让 HIS 加载失败**）：
- `assimbelyName`（少一个 e，**不是** `assemblyName`）
- `flieList`（i 在 e 前，**不是** `fileList`）

**判断不出场景类型时**：直接反问用户「HIS 业务流程自动触发，还是用户在界面上点按钮触发？」——不靠经验猜。

### 2. 医保接口（信号词：`IInsureInterface` / `1101` / `9000` / 医保结算 / 打标 / 冲正 / 前置机 / CA 签名 / 医保插件）

入口：`wiki/medical-insurance/index.md`

具体子文档：
- 架构 → `architecture.md`
- 接口契约（54 方法 入参/出参） → `iinsure-interface.md`
- 数据库 → `database-schema.md`
- 门诊流程 → `outpatient-flow.md`
- 住院流程 → `inpatient-flow.md`
- 通信层（HTTP/SOAP/本地 DLL/冲正） → `communication.md`
- CA 签名（HIS 5.0 双插件） → `ca-signature.md`

### 3. SunnyUI / WinForms（信号词：`UITextBox` / `UIComboBox` / `UIDataGridView` / `UIForm` / `Style` / `StyleCustomMode` / `ShowScrollBar` / `WordWarp`）

入口：`wiki/winforms-ui/sunnyui/index.md`（含全局陷阱 + 通用属性约定 + 控件导航）

子目录：
- `入门/` — 安装/主题/字体图标/国际化/常见问题
- `控件/` — 20 个控件文档 + `控件/index.md` 一览表
- `窗体/` — UIForm / UILoginForm
- `多页面框架/`
- `工具类库/` — IniFile / IniConfig / Json
- `升级指南/`

**注意**：SunnyUI 3.9.7 有自有命名规范（如 `WordWarp` 是库自身 typo，不能改回 `WordWrap`），调用前先 `wiki/winforms-ui/sunnyui/入门/常见问题.md` 查 17 个高频踩坑。

### 4. DB Schema / 字段字典（信号词：`b_drug` / `b_patient` / `qw_base` / `insur` / 字段含义 / `drug_type` / `category` / 字典码）

**优先级**：
1. `wiki/medical-insurance/database-schema.md` — 医保表结构
2. `schema/规范/数据库设计规范.md` — Schema 划分、命名、SQL 规范
3. 整库 Grep 列名/表名找散落的引用

**禁止行为**：
- ❌ 不能凭 distinct 值的计数大小推断字典语义（LRN-20260521-001：drug.category 4/5/6/7 被这么推断过、出错被纠正）
- ❌ 不能从样本药品名推回 category 归属（多数被脱敏）

字典语义只能从 his-wiki 拿；缺失时反问用户、不猜。

### 5. 业务子系统（信号词：门诊 / 住院 / 收费 / 检验 / 检查 / 药品 / 患者 / 医嘱 / 床位）

入口：`wiki/subsystems/overview.md`

按业务定位子目录：`outpatient/` `inpatient/` `billing/` `lab-pacs/` `pharmacy/` `patient/`

### 6. 接口模板（信号词：CRUD / 查询接口 / 插件开发模板 / 第三方对接 / 标准化接口）

- 通用插件骨架 → `wiki/api/plugin-development.md`
- CRUD → `wiki/api/crud-template.md`
- 查询（分页/筛选/关联） → `wiki/api/query-template.md`
- 第三方对接（医保/互认/药事） → `wiki/api/third-party-integration.md`
- 医保插件 → `wiki/api/insurance-plugin-template.md`
- HIS 标准化接口总览 → `wiki/api/yhis-standard-api-overview.md`
- HL7 → `wiki/api/api-hl7-adt-a01.md`

### 7. 故障排查（信号词：报错 / 异常 / 失败 / 错误码 / 报错号 / 9000 / 1206 / 1207）

- 住院 → `wiki/troubleshooting/inpatient/`
- 医保 → `wiki/troubleshooting/medical-insurance/`

### 8. 设计模式与经验（信号词：状态机 / 生命周期 / 经验 / 教训 / pattern）

入口：`wiki/patterns/`

已收录：
- `pattern-order-lifecycle.md` — 医嘱状态机
- `pattern-github-backup-lessons.md` — GitHub 备份经验教训

### 9. 工作日志 / 学习记录（信号词：log / 日志 / 复盘 / 历史 / 整理记录）

- 工作总结 → `wiki/work-log/`
- 知识库自身操作日志 → `wiki/log.md`

### 10. 公司禁令（信号词：禁令 / 红线 / 不可 / 严禁）

入口：`C:\Users\xuyilai\Desktop\his-wiki\schema\规范\公司禁令\README.md`

子文档：
- `编码禁止规范.md`
- `实施禁止规范.md`
- `产品管理禁止规范.md`

## 只读约束

- ✅ 用 Glob / Grep / Read 访问 his-wiki
- ❌ 绝不写入 his-wiki 任何文件
- ❌ 绝不修改 README.md（his-wiki 自身 CLAUDE.md 规定）
- ❌ raw/ 层只增不改，本 skill 默认不碰 raw/，除非用户显式要求

## 响应输出模板

回答用户 query 时按以下格式：

```
## 命中文档
- `wiki/api/foo.md` — 一句话简介
- `wiki/medical-insurance/bar.md` — 一句话简介

## 关键提取
[从命中文档摘出最相关的字段/规则/字典/代码片段；带具体出处链接]

## 下一步建议
- 想深入 X？读 `wiki/aaa.md`
- 想看 Y 实现？读 `wiki/bbb.md`
```

## 边界

**本 skill 干**：
- 查 his-wiki 拿事实（路径 / 字段 / 字典 / 流程 / 模板代码）
- 跨多个子目录拼接答案

**本 skill 不干**：
- 写代码（让主代理处理，本 skill 只输出"应该这么写"的引用）
- 修改 his-wiki 知识库本身（由用户/Keiskei 维护）
- 自动接管会话（按用户决策，本 skill 只显式触发，不嗅探信号词自动加载）

如果用户的 query 完全不在 HIS 范畴（如纯 React 问题），直接告知"超出 his-wiki 覆盖范围，建议直接问主代理"，不强行匹配。
