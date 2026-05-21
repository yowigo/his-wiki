---
title: MI-20260424-INP-NURSE-001 - 住院护士站打标后自动触发费用明细上传
date: 2026-04-24
author: Keiskei
tags:
  - troubleshooting
  - medical-insurance
  - inpatient
  - nurse-station
aliases:
  - 住院护士站打标后自动上传费用明细
  - 1206后自动调用1207
status: resolved
---

# MI-20260424-INP-NURSE-001 - 住院护士站打标后自动触发费用明细上传

## 故障概述

- **故障编号**: MI-20260424-INP-NURSE-001
- **排查日期**: 2026-04-24
- **影响范围**: 住院护士站记账、医保项目打标、住院费用明细上传
- **影响用户**: 住院护士站操作员
- **表现形式**: 护士记账住院患者费用并进行医保项目打标后，HIS 自动触发住院费用明细上传，随后调用医保初始化；护士电脑没有医保网时初始化失败并报错。
- **处理状态**: 已定位根因

## 现象描述

护士在住院护士站为住院患者记账费用，费用完成医保项目打标后，系统又调用住院费用明细上传。项目现场护士电脑没有医保网，因此上传前的医保初始化失败。

日志文件：

```text
C:\Users\xuyilai\xwechat_files\wxid_ii4x8c7a7uwb22_dfc5\msg\attach\773d9ee4b84afb3347520cc7b2937b7f\2026-04\Rec\31da89f5b3c6fe92\F\0\2026-04-24.txt
```

## 日志时间线

### 1. 住院医保项目打标

```json
{
  "business_type": "1206",
  "handle_type": 2,
  "clin_item_id": "",
  "fee_item_id": "c3e73c80c3321166",
  "tips": "正在调用医保项目打标，请稍后..."
}
```

日志时间：

```text
2026-04-24 14:50:00,312
```

### 2. 住院费用明细上传触发医保初始化

```json
{
  "business_type": "1207",
  "handle_type": 2,
  "pt_id": "81dca4332328db8a",
  "fee_detial_id_list": [
    "c3e73c80c3321166"
  ],
  "tips": "正在调用住院费用明细上传，请稍后..."
}
```

日志时间：

```text
2026-04-24 14:50:01,643
```

## DLL 排查结论

现场拷回 DLL：

```text
C:\Users\xuyilai\Desktop\素材\新建文件夹\zlchs.Interface.Control.dll
```

相关 DLL：

```text
C:\Users\xuyilai\Desktop\素材\新建文件夹\zlchs.Insure.Interface.dll
C:\Users\xuyilai\Desktop\素材\新建文件夹\zlchs.Common.Base.dll
```

排查结论：

- `zlchs.Interface.Control.dll` 中 `1206` 映射到 `Business.HospitalInsureItemCheck`。
- `zlchs.Interface.Control.dll` 中 `1207` 映射到 `Business.HospitalDetailUpload`。
- `Business.HospitalInsureItemCheck` 只调用 `InsureBusiness.ItemMarking`，没有在该方法内部调用医保初始化或费用明细上传。
- `Business.HospitalDetailUpload` 会先调用 `InsureBusiness.InitInsure`，初始化成功后再调用 `InsureBusiness.DetailUpload`。
- `zlchs.Insure.Interface.dll` 中 `InsureBusiness.ItemMarking` 只转调具体医保插件的 `IInsureInterface.ItemMarking`，没有串到 `DetailUpload`。

对应当前源码位置：

```text
D:\work\his-medical-group\code\zlsoft.cpapi.insure\zlchs.Interface.Control\Common.cs
D:\work\his-medical-group\code\zlsoft.cpapi.insure\zlchs.Interface.Control\Business.cs
D:\work\his-medical-group\code\zlsoft.cpapi.insure\zlchs.Insure.Interface\InsureBusiness.cs
```

## 根因

住院护士站缺少参数（序号 1、2），导致 HIS 在 `1206` 住院医保项目打标后，自动发起 `1207` 住院费用明细上传。

`1207` 的总控逻辑会先执行医保初始化。护士电脑没有医保网，因此初始化阶段报错。

## 正确理解

本次链路不是 `1206` 方法内部主动调用初始化，而是：

```text
住院护士站记账
  -> 1206 住院医保项目打标
  -> 因护士站缺少参数（序号 1、2），HIS 自动发起 1207 住院费用明细上传
  -> 1207 先执行医保初始化
  -> 护士电脑无医保网，初始化失败
```

## 处理建议

1. 优先补齐住院护士站缺失参数（序号 1、2），避免 HIS 在护士站记账打标后自动触发 `1207`。
2. 不建议直接改 `zlchs.Interface.Control.dll` 中 `1207` 的初始化逻辑，因为住院费用明细上传本身依赖初始化，贸然改动会影响正常医保上传链路。
3. 若后续需要防御性处理，应在调用方区分护士站记账场景、收费结算场景、有无医保网终端场景，避免护士站误触发需要医保网的上传动作。

## 关联知识

- [医保开发索引](../medical-insurance/index.md)
- [医保总控架构](../medical-insurance/architecture.md)
- [住院结算完整流程](../medical-insurance/inpatient-flow.md)
- [通信层详解](../medical-insurance/communication.md)

