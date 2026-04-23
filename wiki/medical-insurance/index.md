# 医保开发

> 原始资料：[raw/医保开发/](../../raw/医保开发/README.md)

---

## 目录

### 架构与设计

- [医保总控架构](architecture.md) — 三层插件化架构、HIS5.0/5.1 差异、反射加载机制
- [IInsureInterface 接口契约](iinsure-interface.md) — 54 个方法完整清单、入参出参格式、CA 签名接口
- [CA 签名模块](ca-signature.md) — HIS5.0 新增双插件体系、`I_CAInterface` 6 个方法

### 业务流程

- [门诊结算完整流程](outpatient-flow.md) — 1101-1107 业务类型、全链路代码走查
- [住院结算完整流程](inpatient-flow.md) — 1201-1219 业务类型、SOAP/HTTP 交互

### 数据与通信

- [医保数据库表结构](database-schema.md) — `insur` schema 核心表、关联关系、数据操作模式
- [通信层详解](communication.md) — HTTP WebAPI(SHA256签名)、SOAP、本地 DLL、冲正机制

### 地区实现

| 地区 | 通信协议 | 数据格式 | 备注 |
|------|---------|---------|------|
| 北京 | COM 接口 + HTTP/SOAP | XML + JSON | `Cls_BJGJBYB.cs`，本地医保库 DLL |
| 上海（五期） | `SendRcv4.dll` | JSON | `Cls_SHXBYB.cs`，23 个接口 |
| 其他地区 | 各异 | 各异 | 参考 `zlchs.Webhis.Test.Insure` 模板 |

### 上海医保五期

- 接口数：23 个线下接口，最终版本 **V1.0.5**
- 规范位置：[raw/医保开发/上海医保项目五期/](../../raw/医保开发/README.md)
- 实现位置：`D:\work\his-medical-group\shanghai-yibao\src\zlchs.SH.XBYB.insure\`
- 接口状态：[interfaces-tracker.md](../../interfaces-tracker.md)（项目内）

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
| 参考实现学习笔记 | `zlchs.Webhis.Test.Insure` 完整分析 | [raw](../../raw/医保开发/医保开发文档/zlchs.Webhis.Test.Insure-学习笔记.md) |
| HIS5.0 北京医保代码走查 | 总控 + 北京医保完整调用链 | [raw](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md) |
| HIS5.0 模拟医保代码走查 | 总控 + 测试实现 + HIS5.0 vs 5.1 对比 | [raw](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-模拟医保中心-代码走查.md) |
