# HIS 知识库索引

欢迎使用医院信息系统（HIS）知识库！这里是所有技术文档、业务知识和故障案例的中心枢纽。

## 快速导航

### 📚 API 文档
- [ADT^A01 入院通知接口](/wiki/api/api-hl7-adt-a01.md) `#api` `#hl7` `#adt`
- [ORM^O01 医嘱接口](/wiki/api/api-hl7-orm-o01.md) `#api` `#hl7` `#orm` (待创建)
- [ORU^R01 检验结果接口](/wiki/api/api-hl7-oru-r01.md) `#api` `#hl7` `#oru` (待创建)

### 🧩 设计模式
- [医嘱生命周期状态机](/wiki/patterns/pattern-order-lifecycle.md) `#pattern` `#state-machine` `#order`
- [患者就诊流程模式](/wiki/patterns/pattern-patient-visit.md) `#pattern` `#workflow` `#patient` (待创建)
- [药品库存管理模式](/wiki/patterns/pattern-drug-inventory.md) `#pattern` `#inventory` `#drug` (待创建)

### 🏥 子系统
- [住院子系统](/wiki/subsystems/inpatient/index.md) `#subsystem` `#inpatient` `#ward`
- [门诊子系统](/wiki/subsystems/outpatient/index.md) `#subsystem` `#outpatient` `#clinic` (待创建)
- [药房子系统](/wiki/subsystems/pharmacy/index.md) `#subsystem` `#pharmacy` `#drug` (待创建)
- [检验子系统](/wiki/subsystems/lab/index.md) `#subsystem` `#lab` `#lis` (待创建)
- [影像子系统](/wiki/subsystems/imaging/index.md) `#subsystem` `#imaging` `#pacs` (待创建)

### 🔧 故障排查
- [床位冲突问题](/wiki/troubleshooting/issue-20250710-bed-conflict.md) `#troubleshooting` `#bed` `#conflict`
- [医嘱执行超时问题](/wiki/troubleshooting/issue-20250711-order-timeout.md) `#troubleshooting` `#order` `#timeout` (待创建)
- [HL7消息解析失败问题](/wiki/troubleshooting/issue-20250712-hl7-parse-error.md) `#troubleshooting` `#hl7` `#parse` (待创建)

## 知识库结构

```
his-wiki/
├── schema/                    # 模式定义层
│   └── CLAUDE.md             # 角色、模板、标签、流程定义
├── wiki/                     # 编译知识层（LLM 维护）
│   ├── index.md              # ← 你在这里
│   ├── log.md                # 操作日志（INGEST/QUERY/LINT）
│   ├── api/                  # 接口文档
│   ├── patterns/             # 设计模式
│   ├── subsystems/           # 子系统文档
│   └── troubleshooting/      # 故障案例
└── raw/                      # 原始资料层
    └── README.md             # 原始资料说明
```

## 使用指南

### 1. 查找文档
- **按标签搜索**: 点击页面中的标签快速过滤相关内容
- **全文搜索**: 使用浏览器的页面内搜索功能（Ctrl+F）
- **结构导航**: 按照目录结构逐层查找

### 2. 贡献文档
1. 阅读 [模式定义](/schema/CLAUDE.md) 了解文档规范
2. 选择合适的模板创建新文档
3. 添加正确的标签和分类
4. 提交到知识库并更新索引

### 3. 维护文档
- **定期检查**: 每月检查一次文档的准确性和链接有效性
- **版本更新**: 系统升级时同步更新相关文档
- **问题反馈**: 发现文档问题及时报告给知识工程团队

## 标签系统

### 分类标签
- `#api` - 接口文档
- `#pattern` - 设计模式
- `#subsystem` - 子系统
- `#troubleshooting` - 故障排查
- `#business-rule` - 业务规则
- `#technical` - 技术实现

### 技术标签
- `#hl7` - HL7标准相关
- `#state-machine` - 状态机设计
- `#database` - 数据库相关
- `#performance` - 性能优化
- `#security` - 安全相关

### 业务标签
- `#patient` - 患者管理
- `#order` - 医嘱管理
- `#drug` - 药品管理
- `#lab` - 检验检查
- `#billing` - 收费结算

## 最新更新

| 日期 | 文档 | 更新内容 | 状态 |
|------|------|----------|------|
| 2025-04-15 | [模式定义](/schema/CLAUDE.md) | 初始创建 | ✅ 已发布 |
| 2025-04-15 | [索引页面](/wiki/index.md) | 初始创建 | ✅ 已发布 |
| 2025-04-15 | [操作日志](/wiki/log.md) | 初始创建 | ✅ 已发布 |

## 相关资源

### 外部链接
- [HL7官方网站](https://www.hl7.org/)
- [IHE技术框架](https://www.ihe.net/)
- [医疗信息化标准](http://www.nhc.gov.cn/)

### 内部系统
- [开发文档库](http://dev-docs.internal/)
- [API测试平台](http://api-test.internal/)
- [监控仪表盘](http://monitor.internal/)

---

**维护团队**: 知识工程部  
**最后更新**: 2025-04-15  
**版本**: 1.0.0  

> 提示：所有文档均遵循 [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) 许可协议