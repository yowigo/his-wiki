# 医保集成接口（第七部分）

> 原始资料：[raw/HIS接口文档1.0/1-标准文档/7-飞跃智慧系统标准化接口文档（第七部分：医保集成）V1.0.docx](../../raw/HIS接口文档1.0/1-标准文档/7-飞跃智慧系统标准化接口文档（第七部分：医保集成）V1.0.docx)
>
> 注意：本部分接口主要用于**传染病前置机**等公卫系统对接，与 [medical-insurance/](../medical-insurance/) 中的医保结算接口属于不同体系。

---

## 概述

第七部分接口属于**医保集成系统**对外提供的标准接口，主要面向：
- 传染病前置机（统一事件调用）
- 公共卫生系统
- 医保监管平台

与 CPAPI 医保结算接口的区别：

| 维度 | 本部分接口 | CPAPI 医保结算接口 |
|------|-----------|-------------------|
| 协议 | HTTP REST | DLL 反射调用 |
| 定位 | 数据查询/上报 | 实时结算 |
| 调用方 | 公卫系统、监管平台 | HIS 前端 |
| 接口前缀 | `A6*` | `IInsureInterface` 方法 |

---

## 接口列表

### A6001 获取患者基本信息

- **服务编码**: `B6001`
- **地址**: `instance/publish/yhis/V1/GetPtInfoByInfct`
- **功能**: 获取患者基本信息（用于传染病报告等场景）
- **入参**: `pt_id`(必填)
- **出参**: 患者详细信息
  - `id`: 患者ID
  - `patient_name`: 患者姓名
  - `id_card_type_code` / `id_card_type_name`: 证件类型
  - `id_card`: 身份证号
  - `gender_code` / `gender_name`: 性别
  - `birth_date`: 出生日期
  - `nationality_code` / `nationality_name`: 国籍
  - `nation_code` / `nation_name`: 民族
  - `permanent_addr_code` / `permanent_addr_name` / `permanent_addr_detail`: 户籍地址
  - `current_addr_code` / `current_addr_name` / `current_addr_detail`: 现住地址
  - `workunit`: 工作单位
  - `marital_status_code` / `marital_status_name`: 婚姻状况
  - `education_code` / `education_name`: 学历
  - `nultitude_type_code` / `nultitude_type_name` / `nultitude_type_other`: 人群分类
  - `tel`: 患者电话
  - `contacts` / `contacts_tel`: 联系人
  - `org_code` / `org_name`: 所属机构
  - `operator_id` / `operation_time`: 操作人及时间

### A6002 获取患者诊疗活动信息

- **服务编码**: `B6002`
- **地址**: `instance/publish/yhis/V1/GetPtMedicalActivity`
- **功能**: 获取患者的诊疗活动记录（就诊、住院等）
- **入参**: `pt_id`(必填), `begin_date`, `end_date`
- **出参**: 诊疗活动列表

### A6003 获取患者传染病报告卡信息

- **服务编码**: `B6003`
- **地址**: `instance/publish/yhis/V1/GetInfectiousDiseaseReport`
- **功能**: 获取患者的传染病报告卡信息
- **入参**: `pt_id`(必填), `report_id`
- **出参**: 传染病报告卡详情

### A6004 获取机构人员信息

- **服务编码**: `B6004`
- **地址**: `instance/publish/yhis/V1/GetOrgStaffInfo`
- **功能**: 获取指定机构的医护人员信息
- **入参**: `org_id`(必填), `dept_id`, `staff_id`, `key_word`
- **出参**: 人员列表

### A6005 获取机构部门信息

- **服务编码**: `B6005`
- **地址**: `instance/publish/yhis/V1/GetOrgDeptInfo`
- **功能**: 获取指定机构的部门（科室）信息
- **入参**: `org_id`(必填), `dept_id`, `key_word`
- **出参**: 部门列表

### A6006 获取患者诊疗活动信息（扩展）

- **服务编码**: `B6006`
- **地址**: `instance/publish/yhis/V1/GetPtMedicalActivityEx`
- **功能**: 扩展版诊疗活动查询（返回更详细的诊疗信息）
- **入参**: `pt_id`(必填), `begin_date`, `end_date`, `visit_type`

### A6007 获取患者检验报告项目信息

- **服务编码**: `B6007`
- **地址**: `instance/publish/yhis/V1/GetLabReportItemInfo`
- **功能**: 获取患者的检验报告及项目明细
- **入参**: `pt_id`(必填), `report_id`, `begin_date`, `end_date`
- **出参**: 检验报告列表，含项目指标结果

---

## 使用场景

### 场景一：传染病上报

```
A6001 获取患者基本信息
  → A6002 获取患者诊疗活动信息
    → A6003 获取患者传染病报告卡信息
      → 组装上报数据 → 推送至疾控系统
```

### 场景二：公卫数据抽取

```
A6005 获取机构部门信息
  → A6004 获取机构人员信息
    → A6002 获取患者诊疗活动信息（按日期范围批量）
      → A6007 获取患者检验报告项目信息
```

---

## 与医保结算接口的关系

| 需求 | 应使用接口 |
|------|-----------|
| 医保实时结算（门诊/住院） | [medical-insurance/architecture.md](../medical-insurance/architecture.md) CPAPI 插件 |
| 患者医保档案查询 | `IInsureInterface.Identify()` / `SelfBalance()` |
| 公卫系统数据上报 | 本部分 A6001-A6007 HTTP 接口 |
| 传染病报告卡查询 | 本部分 A6003 |
| 检验报告共享 | 本部分 A6007 |
