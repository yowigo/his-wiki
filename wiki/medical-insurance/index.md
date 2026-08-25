# 医保开发

> 原始资料：[raw/外部接口开发/](../../raw/外部接口开发/)（医保开发文档、上海医保项目五期、广东深圳医保、北京电子票据等）

---

## 目录

### 架构与设计

- [医保总控架构](architecture.md) — 三层插件化架构、HIS5.0/5.1 差异、反射加载机制
- [IInsureInterface 接口契约](iinsure-interface.md) — 54 个方法完整清单、入参出参格式、CA 签名接口
- [CA 签名模块](ca-signature.md) — HIS5.0 新增双插件体系、`I_CAInterface` 6 个方法
- [程序集依赖 / 反射加载](assembly-loading.md) — `Assembly.Load(byte[])` 场景的依赖解析（AssemblyResolver + libs 目录）

### 铁则

- [🚨 结算误差费铁则](settlement-error-check.md) — 所有结算流程必须校验 `|HIS总费用 - 医保总费用| > 0.1元`，超标即拦截；正式结算须配套撤销
- [医保自费分离结算改造方案](self-pay-separation.md) — 盈利性机构未对码项目过滤自费结算 + `SkipInsureErrorCheck` 跳过误差判断

### 业务流程

- [门诊结算完整流程](outpatient-flow.md) — 1101-1107 业务类型、全链路代码走查
- [住院结算完整流程](inpatient-flow.md) — 1201-1219 业务类型、SOAP/HTTP 交互

### 数据与通信

- [医保数据库表结构](database-schema.md) — `insur` schema 核心表、关联关系、数据操作模式
- [通信层详解](communication.md) — HTTP WebAPI(SHA256签名)、SOAP、本地 DLL、冲正机制
- [医保对账（日对账 / 结算对账）](reconcile.md) — 国家 3201/3202/9101/9102 对账、五期 SL01、对账记录查询

### 运维与部署

- [医院部署前置配置清单](deployment-checklist.md) — 10 步配置链、InitInsure 卡点对照表、医保工具 function_no 速查
- [医保错误码处理手册](error-code-handbook.md) — 国家 infcode / 五期 xxfhm / 读卡器 / 业务前置弹窗、日志查阅

### 地区实现

| 地区 | 通信协议 | 数据格式 | 备注 |
|------|---------|---------|------|
| 北京 | COM 接口 + HTTP/SOAP | XML + JSON | `Cls_BJGJBYB.cs`，本地医保库 DLL |
| [上海（五期+国家）](shanghai-5th.md) | `SendRcv4.dll` / CSB HTTP | JSON | `zlchs.SH.GJBYB.insure`，19 个五期接口（15 在用 + 4 新增） |
| [广东深圳（市直）](guangdong-szsz.md) | HTTP（YBBusiness） | XML | `Plugins.insure.GD.SZSZ`，2026-07 贯标改造审计 |
| 其他地区 | 各异 | 各异 | 参考 `zlchs.Webhis.Test.Insure` 模板 |

### 上海医保五期

- [上海医保五期插件总览](shanghai-5th.md) — 双通道路由（insSno 11/12）、业务边界（互助帮困/离休干部）、15+4 交易码、V1.0→V1.0.6 升级状态、核心文件与易踩坑
- 规范位置：[raw/外部接口开发/上海医保项目五期/](../../raw/外部接口开发/上海医保项目五期/)
- 实现位置：`D:\work\his-medical-group\code\zlchs.SH.GJBYB.insure\`

### 医保扩展

- [追溯码流通环节](traceability-code-flow.md) — 8个流通环节全景（3501-3513）、数据流关系、核心约束规则、各地实现现状
- [追溯码上传查询模块](traceability-code-upload.md) — 北京电子溯源码插件入参结构、business_type（1920/1921）与医保交易编号对应关系、判重机制
- [医保对码工具](coding-tool.md) — Plugins.MedicalMatch / Plugins.InsureTools、已对照目录 JOIN 问题分析
- [北京电子票据插件](../api/electronic-invoice-plugin.md) — 0301/0303/0304/0305 报文、SM4 加密、elect_bill_upload_log 表结构

### 排查案例

- [住院护士站打标后自动触发费用明细上传](../troubleshooting/medical-insurance/issue-20260424-inpatient-nurse-fee-upload-after-item-marking.md) — 住院护士站缺少参数导致 `1206` 后自动触发 `1207`
- [医保原生动态库缺失导致框架层 ArgumentNullException](../troubleshooting/medical-insurance/issue-20260606-native-dll-not-found.md) — 反射加载 + 原生 DLL 缺失
- [五期 SL01 对账落库失败与费用明细 SQL 语法错误](../troubleshooting/medical-insurance/issue-20260807-sh5-sl01-reconcile-fee-type.md) — 前置机不可达、落库静默失败、PG 不认 `//` 注释
- [追溯码上传重复问题分析（GZ/SH/BJ 判重缺陷）](../troubleshooting/medical-insurance/issue-20260824-traceability-duplicate-upload.md) — check-then-act 竞态、先占坑记账修复建议

---

## 核心架构速览

HIS 通过 **CPAPI 框架反射加载 DLL**，直接调用医保插件方法，不走 HTTP/WebSocket：

```
HIS 客户端
  ↓ ProcessRequest("Interface", jsonParams)
CPAPI 总控（zlchs.Interface.Control.dll）
  ↓ switch(business_type) → Business 编排
  ├─ 1xxx/2xxx → InsureBusiness → 反射加载医保 DLL
  └─ 8xxx      → CAInterfaceBusiness → 反射加载 CA DLL
    ↓
IInsureInterface / I_CAInterface 实现（各地区插件）
  ├─ BaseDataHelper → PostgreSQL (insur schema)
  └─ HTTP/SOAP/本地DLL → 医保中心
```

所有方法签名统一为：
- 入参：`string strJson`（JSON 字符串，含 ins_id、org_id、pt_id 等）
- 出参：`string`（JSON 字符串，`{code, message, data}`）或 `bool`

---

## 参考资料

| 文档 | 内容 | 路径 |
|------|------|------|
| 参考实现学习笔记 | `zlchs.Webhis.Test.Insure` 完整分析 | [raw](../../raw/外部接口开发/医保开发文档/zlchs.Webhis.Test.Insure-学习笔记.md) |
| HIS5.0 北京医保代码走查 | 总控 + 北京医保完整调用链 | [raw](../../raw/外部接口开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md) |
| HIS5.0 模拟医保代码走查 | 总控 + 测试实现 + HIS5.0 vs 5.1 对比 | [raw](../../raw/外部接口开发/医保开发文档/HIS-5.0医保总控-模拟医保中心-代码走查.md) |
| 上海五期升级清单 | AI 执行 + 用户审阅的唯一真相源 | [raw](../../raw/外部接口开发/上海医保项目五期/医保五期接口升级清单.md) |
| 医保错误码处理手册 | 双通道错误分类处置 | [raw](../../raw/外部接口开发/上海医保项目五期/医保错误码处理手册.md) |
| 医院部署前置配置清单 | 首次部署配置链 | [raw](../../raw/外部接口开发/上海医保项目五期/医院部署前置配置清单.md) |
| 广东深圳审计报告 / 落实清单 | 市直贯标改造 | [raw](../../raw/外部接口开发/广东深圳医保/市直医保接口改造-代码审计报告.md) |
| 北京电子票据接口规范 V1.28 | 官方规范 md 版 | [raw](../../raw/外部接口开发/北京电子票据/北京市医保信息系统医院端接口服务技术规范V1.28.md) |

