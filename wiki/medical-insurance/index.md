# 医保开发

> 原始资料：[raw/医保开发/](../../raw/医保开发/README.md)

## 核心架构

HIS 通过 **CPAPI 框架反射加载 DLL**，直接调用医保插件方法，不走 HTTP/WebSocket：

```
HIS 客户端
  ↓ ProcessRequest("Interface", jsonParams)
CPAPI 总控（zlchs/CICT.Interface.Control.dll）
  ↓ 反射加载医保插件 DLL
IInsureInterface 实现（各地区插件）
  ↓ BaseDataHelper → PostgreSQL
  ↓ SendRcv4.dll / HTTP → 医保中心
```

所有方法签名统一为：
- 入参：`string strJson`（JSON 字符串，含 ins_id、org_id、pt_id 等）
- 出参：`string`（JSON 字符串）或 `bool`

## HIS 版本差异

| 方面 | HIS5.1（CICT） | HIS5.0（zlchs） |
|------|---------------|----------------|
| 命名空间前缀 | `CICT.*` | `zlchs.*` |
| 业务类型数 | 45 个 | 53 个（含 8 个 CA 签名类型 8001-8008） |
| CA 模块 | 无 | `CAInterfaceBusiness` + `I_CAInterface` |
| 额外编排方法 | 无 | `ClincPreSettleSingle/Single/HospitalSettleSingle` |
| 医保接口方法 | 完全相同（54 个） | 完全相同（54 个） |

## IInsureInterface 方法分类

| 分类 | 主要方法 |
|------|---------|
| 初始化 | `InitInsure` |
| 身份认证 | `Identify` |
| 门诊 | `ClinicPreSwap`、`ClinicSwap`、`ClinicDelSwap` |
| 住院 | `HospitalRegister`、`HospitalSettle`、`HospitalDelSettle` |
| 账单 | `UploadBill`、`DelBill` |
| 查询 | `InterfaceTools`（function_no 分发多个辅助接口） |
| 本地操作 | `LeaveSwap`、`LeaveDelSwap`、`ModiPatiSwap`、`ModiDiseaseSwap` |

## 各地区实现

| 地区 | 通信协议 | 数据格式 | 备注 |
|------|---------|---------|------|
| 北京 | COM 接口 | XML | `Cls_BJXBYB.cs` |
| 上海（五期） | `SendRcv4.dll` | JSON | `Cls_SHXBYB.cs`，23 个接口 |
| 其他地区 | 各异 | 各异 | 参考 `zlchs.Webhis.Test.Insure` 模板 |

## 上海医保五期

- 接口数：23 个线下接口，最终版本 **V1.0.5**
- 规范位置：[raw/医保开发/上海医保项目五期/](../../raw/医保开发/README.md)
- 实现位置：`D:\work\his-medical-group\shanghai-yibao\src\zlchs.SH.XBYB.insure\`
- 接口状态：[interfaces-tracker.md](../../interfaces-tracker.md)（项目内）

## 参考资料

| 文档 | 内容 | 路径 |
|------|------|------|
| 参考实现学习笔记 | `zlchs.Webhis.Test.Insure` 完整分析 | [raw](../../raw/医保开发/医保开发/zlchs.Webhis.Test.Insure-学习笔记.md) |
| HIS5.0 北京医保代码走查 | 总控 + 北京医保完整调用链 | [raw](../../raw/医保开发/医保开发/HIS-5.0医保总控-北京医保中心-代码走查.md) |
| HIS5.0 模拟医保代码走查 | 总控 + 测试实现 + HIS5.0 vs 5.1 对比 | [raw](../../raw/医保开发/医保开发/HIS-5.0医保总控-模拟医保中心-代码走查.md) |
