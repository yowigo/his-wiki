# HIS 知识库

**最后更新时间**: 2026-08-25
**整理者**: Keiskei
**知识库状态**: 持续完善中（医保文档已充实，HIS 标准化接口已入库）

---

## 知识库结构

```
his-wiki/
├── schema/                      # 模式定义层（规范、模板、流程）
│   └── 规范/
│       ├── 编码规范.md
│       ├── 接口设计规范.md
│       ├── 数据库设计规范.md
│       └── 公司禁令/
│           ├── README.md
│           ├── 编码禁止规范.md
│           ├── 实施禁止规范.md
│           └── 产品管理禁止规范.md
│
├── wiki/                        # 编译知识层（整理后的知识）
│   ├── index.md                 # 内容索引与导航（本文件）
│   ├── log.md                   # 操作日志
│   ├── api/                     # 接口开发文档
│   │   ├── plugin-development.md      # 插件开发模板
│   │   ├── crud-template.md           # CRUD接口模板
│   │   ├── query-template.md          # 查询接口模板
│   │   ├── third-party-integration.md # 第三方对接模板
│   │   ├── insurance-plugin-template.md # 医保插件模板
│   │   ├── electronic-invoice-plugin.md # 北京电子票据插件
│   │   ├── isb-service-design.md          # ISB服务设计数据库操作
│   │   ├── isb-signature-auth.md           # ISB接口签名认证
│   │   ├── api-hl7-adt-a01.md         # HL7 ADT^A01
│   │   ├── yhis-standard-api-overview.md  # HIS标准化接口总览
│   │   ├── yhis-base-data.md              # 基础数据接口
│   │   ├── yhis-registration-billing.md   # 挂号费用接口
│   │   └── yhis-medical-insurance-integration.md # 医保集成接口
│   │
│   ├── subsystems/              # 业务子系统文档
│   │   ├── overview.md          # HIS业务概览
│   │   ├── outpatient/          # 门诊管理
│   │   ├── inpatient/           # 住院管理
│   │   ├── billing/             # 费用结算
│   │   ├── lab-pacs/            # 检验检查
│   │   ├── pharmacy/            # 药品管理
│   │   └── patient/             # 患者管理
│   │
│   ├── medical-insurance/       # 医保开发文档
│   │   ├── index.md             # 医保开发索引
│   │   ├── architecture.md      # 医保总控架构
│   │   ├── iinsure-interface.md # IInsureInterface 接口契约
│   │   ├── database-schema.md   # 医保数据库表结构
│   │   ├── outpatient-flow.md   # 门诊结算流程
│   │   ├── inpatient-flow.md    # 住院结算流程
│   │   ├── communication.md     # 通信层详解
│   │   ├── ca-signature.md      # CA签名模块
│   │   ├── shanghai-5th.md      # 上海医保五期插件总览
│   │   ├── error-code-handbook.md  # 医保错误码处理手册
│   │   ├── deployment-checklist.md # 医院部署前置配置清单
│   │   ├── reconcile.md         # 医保对账（日对账/结算对账）
│   │   ├── self-pay-separation.md  # 自费分离结算改造方案
│   │   ├── assembly-loading.md  # 程序集依赖/反射加载
│   │   ├── guangdong-szsz.md    # 广东深圳（市直）医保
│   │   ├── coding-tool.md       # 医保对码工具
│   │   ├── traceability-code-flow.md  # 追溯码流通环节
│   │   └── traceability-code-upload.md  # 追溯码上传查询模块（北京）
│   │
│   ├── patterns/                # 设计模式与经验
│   │   ├── pattern-order-lifecycle.md
│   │   └── pattern-github-backup-lessons.md
│   │
│   ├── winforms-ui/             # WinForms UI 组件库（按库分子站）
│   │   ├── index.md             # UI 库子站总入口
│   │   └── sunnyui/             # SunnyUI 子站
│   │       ├── index.md         # SunnyUI 入口（全局陷阱 + 控件导航）
│   │       ├── 入门/             # 安装/主题/字体图标/国际化/常见问题
│   │       ├── 控件/             # 20 个控件文档 + 一览表
│   │       ├── 窗体/             # UIForm / UILoginForm
│   │       ├── 多页面框架/        # IFrame 框架 / DPI 适配 / 全局字体
│   │       ├── 工具类库/          # IniFile / IniConfig / Json
│   │       └── 升级指南/          # 3.5.2 → 3.6.0
│   │
│   ├── troubleshooting/         # 故障案例（按模块分子目录）
│   │   ├── inpatient/           # 住院系统故障
│   │   └── medical-insurance/   # 医保故障
│   │
│   ├── database-query/           # 数据库查询指南
│   │   ├── fee_schema_guide.md    # fee 库快速导览
│   │   ├── fee_schema.json        # fee 库结构化 schema
│   │   ├── fee_schema_ddl.sql     # fee 库完整 DDL dump
│   │   └── pg-sql-runner.md       # DDL 批处理执行工具
│   │
│   └── work-log/                # 工作日志
│       ├── 2026-04-15-summary.md
│       └── task-system-full-report-with-paths.md
│
└── raw/                         # 原始资料层（只增不改）
    ├── HIS接口文档1.0/          # 飞跃智慧系统标准化接口（15份docx）
    ├── 外部接口开发/            # 外部接口/医保开发原始资料
    │   ├── 医保开发文档/        # 医保架构、接口契约、流程代码走查
    │   ├── 上海医保项目五期/    # 五期规范 PDF/md、升级清单、错误码、部署清单、对账
    │   ├── 广东深圳医保/        # 市直医保接口规范、审计报告、落实清单
    │   └── 北京电子票据/        # 电子票据规范 V1.28、报文 0101/0103、表结构
    ├── CPAPI/                   # CPAPI 框架资料
    ├── 对码管理/                # 对码工具使用手册、ins_item.sql、分析
    ├── SunnyUI文档/             # SunnyUI 控件库原始文档（V3.9.7）
    └── skills技能/              # 技能手册 + 团队自研 skill
        ├── gstack技能手册.md     #   gstack 内置技能说明
        └── sunnyui/             #   团队自研：SunnyUI 开发护栏 skill
```

---

## 知识库用途

### 1. 开发规范参考
- **编码规范**: 统一代码风格和质量标准
- **接口设计规范**: RESTful API设计原则
- **数据库设计规范**: Schema划分、命名规范、SQL规范
- **公司禁令**: 编码、实施、产品管理红线

### 2. 业务知识学习
- **HIS业务概览**: 系统定位、项目关系、核心业务
- **门诊流程**: 挂号、接诊、开医嘱、收费、执行、报告
- **住院流程**: 入院登记、医嘱、执行、费用、出院结算
- **费用结算**: 医保结算、支付处理、票据管理
- **检验检查**: 检验流程、互认平台、影像管理
- **药品管理**: 药品医嘱、发药流程、库存管理
- **患者管理**: 患者建档、身份识别、就诊管理

### 3. 接口开发模板
- **插件开发模板**: .NET Framework接口组插件开发
- **CRUD接口模板**: .NET 8.0 HIS 5.1标准CRUD接口
- **查询接口模板**: 分页查询、复杂筛选、关联查询
- **第三方对接模板**: 医保平台、互认平台、药事平台对接
- **医保插件模板**: 各地医保平台对接开发

### 4. 医保开发指南
- **总控架构**: 三层插件化架构、HIS5.0/5.1差异、反射加载机制
- **接口契约**: IInsureInterface 54个方法、入参出参格式
- **数据库**: insur schema 核心表、关联关系
- **业务流程**: 门诊/住院结算完整流程、代码走查
- **通信层**: HTTP WebAPI、SOAP、本地DLL、冲正机制
- **CA签名**: HIS5.0新增双插件体系

### 5. 标准化接口文档
- **总览**: 全部9部分标准文档 + 6份系统对接文档索引
- **基础数据**: 部门、人员、患者档案、标签、收费诊疗项目、字典
- **挂号费用**: 挂号科室、排班、提交/取消挂号、门诊收费、缴费、退费、住院记账
- **医保集成**: 传染病前置机接口、公卫数据查询

---

## 当前整理进度

| 模块 | 状态 | 完成度 | 备注 |
|------|------|--------|------|
| 规范文档 | 已完成 | 100% | 编码规范、接口规范、数据库规范、公司禁令 |
| 业务文档 | 已完成 | 100% | 概览、门诊、住院、费用、检验、药品、患者 |
| 接口模板 | 已完成 | 100% | 插件开发、CRUD、查询、第三方对接、医保插件 |
| 医保开发 | 已完成 | 95% | 架构、接口、数据库、流程、通信、CA签名、上海五期、错误码、部署清单、对账、自费分离、程序集加载、广东深圳、对码工具、北京电子票据已整理 |
| 标准化接口 | 进行中 | 40% | 总览、基础数据、挂号费用、医保集成已整理 |
| 故障案例 | 进行中 | 40% | 按模块分子目录，已入库 6 个案例 |
| 数据库查询 | 新建 | 5% | fee 库快速导览、结构化 schema、DDL dump |
| 设计模式 | 进行中 | 50% | 医嘱状态机、GitHub备份经验已整理 |
| WinForms UI 库 | 进行中 | 60% | SunnyUI 子站已收录 raw 子集：20 控件 + 2 窗体 + 多页框架 + 3 工具类（V3.9.7 同步） |

---

## 快速导航

### 开发规范
- [编码规范](../schema/规范/编码规范.md)
- [接口设计规范](../schema/规范/接口设计规范.md)
- [数据库设计规范](../schema/规范/数据库设计规范.md)
- [公司禁令](../schema/规范/公司禁令/README.md)

### 业务知识
- [HIS业务概览](subsystems/overview.md)
- [门诊流程](subsystems/outpatient/index.md)
- [住院流程](subsystems/inpatient/index.md)
- [费用结算](subsystems/billing/index.md)
- [检验检查](subsystems/lab-pacs/index.md)
- [药品管理](subsystems/pharmacy/index.md)
- [患者管理](subsystems/patient/index.md)

### 接口开发
- [插件开发模板](api/plugin-development.md)
- [CRUD接口模板](api/crud-template.md)
- [查询接口模板](api/query-template.md)
- [第三方对接模板](api/third-party-integration.md)
- [医保插件模板](api/insurance-plugin-template.md)
- [HIS标准化接口总览](api/yhis-standard-api-overview.md)

### 医保开发
- [医保开发索引](medical-insurance/index.md)
- [医保总控架构](medical-insurance/architecture.md)
- [IInsureInterface接口契约](medical-insurance/iinsure-interface.md)
- [上海医保五期插件](medical-insurance/shanghai-5th.md) — 双通道路由、19 接口、V1.0.6 升级状态
- [医保错误码处理手册](medical-insurance/error-code-handbook.md)
- [医院部署前置配置清单](medical-insurance/deployment-checklist.md)
- [医保对账（日对账/结算对账）](medical-insurance/reconcile.md)
- [自费分离结算改造方案](medical-insurance/self-pay-separation.md)
- [程序集依赖/反射加载](medical-insurance/assembly-loading.md)
- [广东深圳（市直）医保](medical-insurance/guangdong-szsz.md)
- [医保对码工具](medical-insurance/coding-tool.md)
- [北京电子票据插件](api/electronic-invoice-plugin.md)
- [医保数据库表结构](medical-insurance/database-schema.md)
- [门诊结算流程](medical-insurance/outpatient-flow.md)
- [住院结算流程](medical-insurance/inpatient-flow.md)
- [通信层详解](medical-insurance/communication.md)
- [CA签名模块](medical-insurance/ca-signature.md)
- [追溯码流通环节](medical-insurance/traceability-code-flow.md)
- [追溯码上传查询模块](medical-insurance/traceability-code-upload.md)

### 故障排查

**住院（inpatient）**
- [床位冲突案例](troubleshooting/inpatient/issue-20250710-bed-conflict.md)

**医保（medical-insurance）**
- [住院护士站打标后自动触发费用明细上传](troubleshooting/medical-insurance/issue-20260424-inpatient-nurse-fee-upload-after-item-marking.md)
- [导入医保目录时 py_code 字段长度不足](troubleshooting/medical-insurance/issue-20260428-ins-item-py-code-too-long.md)
- [医保原生动态库缺失导致框架层 ArgumentNullException](troubleshooting/medical-insurance/issue-20260606-native-dll-not-found.md)
- [五期 SL01 对账落库失败与费用明细 SQL 语法错误排查](troubleshooting/medical-insurance/issue-20260807-sh5-sl01-reconcile-fee-type.md) — SQL 内 `//` 注释致 PG 语法错误、费用类型字段三语义（mr_fee）、双通道共用明细查询
- [追溯码上传重复问题分析（GZ/SH/BJ 判重缺陷）](troubleshooting/medical-insurance/issue-20260824-traceability-duplicate-upload.md) — check-then-act 竞态、先占坑记账修复建议

**电子票据（electronic-invoice）**
- [找不到 ElectronicInvoiceInterfaceDelaut.dll](troubleshooting/electronic-invoice/issue-electronicinvoiceinterfacedelaut-not-found.md)
- [开蓝票金蝶返回 serialNo 重复（"请勿重复提交" / 20013"流水号已开具发票"）](troubleshooting/electronic-invoice/issue-kingdee-duplicate-serialno.md)

### 数据库查询
- [fee 库快速导览](database-query/fee_schema_guide.md) — 核心链路、表卡、排查入口（配套 DDL + JSON schema 同目录）
- [pg-sql-runner](database-query/pg-sql-runner.md) — PostgreSQL DDL 批处理执行工具，双击即跑，便携免安装

### 设计模式
- [医嘱状态机](patterns/pattern-order-lifecycle.md)
- [GitHub备份经验教训](patterns/pattern-github-backup-lessons.md)

### WinForms UI 库
- [WinForms UI 库总入口](winforms-ui/index.md)
- [SunnyUI 子站入口](winforms-ui/sunnyui/index.md) — 含全局陷阱、通用属性约定、控件导航
- [SunnyUI 控件一览表](winforms-ui/sunnyui/控件/index.md) — 20 个控件速查
- [SunnyUI 主题系统](winforms-ui/sunnyui/入门/主题.md) — Style/StyleCustomMode 必读
- [SunnyUI 常见问题](winforms-ui/sunnyui/入门/常见问题.md) — 17 个高频踩坑

### 团队 Skill（AI 开发护栏）

> 这些 skill 是给 **Claude Code** 加载的 AI 行为规范，需要拷贝到本机 `~/.claude/skills/` 才能生效。源仓库在 `raw/skills技能/`，安装方式见各 skill 的 INSTALL.md。

| Skill | 用途 | 源路径 |
| --- | --- | --- |
| `sunnyui` | SunnyUI WinForms 开发护栏：统一控件命名、AutoScaleMode、主题、字体、DPI、字体图标等团队约定 | [raw/skills技能/sunnyui/SKILL.md](../raw/skills技能/sunnyui/SKILL.md) ｜ [安装说明](../raw/skills技能/sunnyui/INSTALL.md) |

---

## 操作日志

### 2026-08-25
- 医保插件知识全量整理入库（本批次）：
  - raw 补档：上海五期（V1.0.6 通知、升级清单、错误码手册、部署清单、自费分离、对账手册、程序集依赖、SQL 脚本）、广东深圳医保（规范/审计报告/落实清单/改造指引）、北京电子票据（规范 V1.28、报文 0101/0103、表结构、实现摘要）、对码管理（ins_item.sql、已对照目录分析）
  - 新建 wiki 页面 10 篇：上海五期插件总览、医保错误码处理手册、医院部署前置配置清单、医保对账、自费分离结算改造、程序集依赖/反射加载、广东深圳（市直）医保、北京电子票据插件、医保对码工具、追溯码重复上传排查案例
  - 更新：追溯码上传查询模块（判重章节）、医保开发索引、知识库首页
- 未入库：市直升级改造测试医院账号信息.md（含账号，避免进 GitHub 仓库）

### 2026-08-07
- 新增医保故障案例：五期 SL01 对账落库失败与费用明细 SQL 语法错误排查 — ① SL01 出参为空（前置机连不上）加友好提示；② 对账成功但落库无数据（DDL 未执行/静默失败），加固 ExteSql 影响行数检查；③ SQL 字符串内 `//` 注释致 PG 语法错误（PG 只认 `--`/`/* */`）；附带费用类型字段三语义对照（mr_fee 收费类型 / b_fee_item.fee_type 本地费用类型 / ins_item.fee_type 医保目录类型）与双通道共用明细查询影响面

### 2026-07-28
- 新增医保文档：追溯码流通环节（traceability-code-flow.md）— 8 个流通环节（3501-3513）全景图、Mermaid 数据流图、核心约束规则 6 条、广州/北京实现现状对比

### 2026-07-07
- 新建数据库查询（database-query）分类：入库 fee 库快速导览、结构化 schema、完整 DDL dump
- fee 库导览覆盖 6 个 schema（qw_base / public / pay / insur / schedule / misl）、核心链路（收费项目→费用明细→未结/结算→支付→医保→退费）、9 张核心表卡、前端入口反查
- 结构化 schema 供 db-reader 子代理直接索引，DDL dump 为完整权威源

### 2026-05-26
- 新增医保铁则：结算误差费校验（`settlement-error-check.md`）— 所有结算流程必须校验 `|HIS总费用 - 医保总费用| > 0.1元`，超标即拦截；正式结算须配套撤销

### 2026-05-21
- 新增 WinForms UI 库子站：基于 raw/SunnyUI文档/ 整理 SunnyUI（V3.9.7 同步）AI 优先版 wiki 化文档 37 篇
- 子站结构：入门 5 + 控件 21（20+索引） + 窗体 2 + 多页面框架 3 + 工具类库 3 + 升级指南 1 + 顶层 2
- 风格：去图保表 + 全局陷阱前置 + 通用属性提取（不重复进每个控件页）
- 新增团队自研 skill `sunnyui`（raw/skills技能/sunnyui/）：8 Steps 强制检查表 + 反问清单，约束 AI 写 SunnyUI 代码时的命名/主题/字体/DPI/字体图标风格一致性；同步配套 INSTALL.md

### 2026-04-28
- 故障案例目录重组：troubleshooting/ 下按模块拆分子目录（inpatient/、medical-insurance/）
- 新增医保故障案例：ins_item.py_code varchar(20) 长度不足导致导入失败

### 2026-04-24
- 新增医保故障案例：住院护士站缺少参数（序号 1、2）导致 `1206` 打标后自动触发 `1207` 住院费用明细上传，护士电脑无医保网时在医保初始化阶段报错

### 2026-04-23
- 入库 HIS 接口文档 1.0（15份标准/对接文档）
- 整理医保开发文档：架构、接口契约、数据库、门诊/住院流程、通信层、CA签名
- 整理 HIS 标准化接口：总览、基础数据、挂号费用、医保集成
- 更新知识库首页索引和导航

### 2026-04-16
- 完成规范文档整理（编码规范、接口规范、数据库规范、公司禁令）
- 完成业务文档整理（7个子系统文档）
- 完成接口模板整理（5个开发模板）
- 创建知识库首页和导航结构

---

**维护者**: Keiskei
**更新频率**: 按需更新
**备份地址**: GitHub仓库 `yowigo/his-wiki`
