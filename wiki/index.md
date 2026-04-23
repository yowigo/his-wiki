# HIS 知识库

**最后更新时间**: 2026-04-23
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
│   │   └── ca-signature.md      # CA签名模块
│   │
│   ├── patterns/                # 设计模式与经验
│   │   ├── pattern-order-lifecycle.md
│   │   └── pattern-github-backup-lessons.md
│   │
│   ├── troubleshooting/         # 故障案例
│   │   └── issue-20250710-bed-conflict.md
│   │
│   └── work-log/                # 工作日志
│       ├── 2026-04-15-summary.md
│       └── task-system-full-report-with-paths.md
│
└── raw/                         # 原始资料层（只增不改）
    ├── HIS接口文档1.0/          # 飞跃智慧系统标准化接口（15份docx）
    ├── 医保开发/                # 医保开发原始资料
    └── skills技能/              # gstack 技能手册
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
| 医保开发 | 已完成 | 90% | 架构、接口、数据库、流程、通信、CA签名已整理 |
| 标准化接口 | 进行中 | 40% | 总览、基础数据、挂号费用、医保集成已整理 |
| 故障案例 | 进行中 | 25% | 床位冲突案例已整理，更多案例待提取 |
| 设计模式 | 进行中 | 50% | 医嘱状态机、GitHub备份经验已整理 |

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
- [医保数据库表结构](medical-insurance/database-schema.md)
- [门诊结算流程](medical-insurance/outpatient-flow.md)
- [住院结算流程](medical-insurance/inpatient-flow.md)
- [通信层详解](medical-insurance/communication.md)
- [CA签名模块](medical-insurance/ca-signature.md)

### 故障排查
- [床位冲突案例](troubleshooting/issue-20250710-bed-conflict.md)

### 设计模式
- [医嘱状态机](patterns/pattern-order-lifecycle.md)
- [GitHub备份经验教训](patterns/pattern-github-backup-lessons.md)

---

## 操作日志

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
