# 挂号费用接口（第二部分）

> 原始资料：[raw/HIS接口文档1.0/1-标准文档/2-飞跃智慧系统标准化接口文档（第二部分：挂号、费用）V1.0.docx](../../raw/HIS接口文档1.0/1-标准文档/2-飞跃智慧系统标准化接口文档（第二部分：挂号、费用）V1.0.docx)

---

## 挂号模块（C*）

### C1001 获取挂号科室

- **V1.0 地址**: `instance/publish/yhis/V1/GetWosDeptByOrgId`
- **V1.1 地址**: `instance/publish/yhis/V1.1/GetWosDeptByOrgId`
- **功能**: 按机构获取挂号科室
- **入参**: `org_id`(必填), `is_release`(1=仅对外发布排班科室, 0=所有)
- **出参**: 科室列表，V1.1 额外返回 `description`(简介), `tel`, `address`

### C1002 获取科室医生

- **地址**: `instance/publish/yhis/V1/GetWosDeptDoctor`
- **功能**: 获取指定科室下的出诊医生
- **入参**: `org_id`(必填), `dept_id`(必填)
- **出参**: 医生列表，含 `staff_id`, `staff_name`, `py_code`, `title_name`, `expertise`

### C1003 获取排班信息

- **V1.0 地址**: `instance/publish/yhis/V1/GetScheduleInfo`
- **V1.1 地址**: `instance/publish/yhis/V1.1/GetScheduleInfo`
- **功能**: 获取科室医生的排班信息（日期、上下午、号源数）
- **入参**: `org_id`(必填), `dept_id`, `staff_id`, `begin_date`, `end_date`
- **出参**: 排班列表，含 `schedule_date`, `apm`(上下午), `total_num`(总号源), `remain_num`(剩余号源)

### C1004 获取排班号别时段

- **地址**: `instance/publish/yhis/V1/GetScheduleTime`
- **功能**: 获取排班的具体时段（如 08:00-08:30）
- **入参**: `org_id`(必填), `schedule_id`(排班ID)

### C1005 获取挂号记录信息

- **地址**: `instance/publish/yhis/V1/GetRegistrationRecord`
- **功能**: 查询已挂号记录
- **入参**: `org_id`(必填), `patient_id`, `begin_date`, `end_date`, `status`

### C1006 获取挂号科室及医生

- **地址**: `instance/publish/yhis/V1/GetWosDeptAndDoctor`
- **功能**: 一次性获取科室及下属医生（树形结构）
- **入参**: `org_id`(必填), `is_release`

### C2001 提交挂号

- **地址**: `instance/publish/yhis/V1/SubmitRegistration`
- **功能**: 提交挂号请求，锁定号源
- **入参**: `org_id`(必填), `patient_id`(必填), `dept_id`(必填), `staff_id`, `schedule_id`, `apm`, `visit_date`, `pay_type`, `pay_amount`
- **出参**: `visit_id`(就诊ID), `register_id`(挂号ID), `visit_no`(就诊序号), `status`

### C2005 取消挂号

- **地址**: `instance/publish/yhis/V1/CancelRegistration`
- **功能**: 取消已挂号，释放号源
- **入参**: `org_id`(必填), `register_id`(必填), `cancel_reason`

---

## 费用模块（D*）

### D1017 获取就诊信息

- **地址**: `instance/publish/yhis/V1/GetVisitInfo`
- **功能**: 获取患者就诊基本信息
- **入参**: `org_id`(必填), `visit_id`(必填)

### D1001 获取未缴费信息

- **地址**: `instance/publish/yhis/V1/GetUnpaidInfo`
- **功能**: 查询患者待缴费项目汇总
- **入参**: `org_id`(必填), `patient_id`(必填), `visit_id`
- **出参**: 待缴费列表，含 `item_name`, `price`, `qty`, `amount`, `dept_name`, `doctor_name`

### D1001A 查询未交费明细

- **地址**: `instance/publish/yhis/V1/GetUnpaidDetail`
- **功能**: 查询未缴费的详细项目清单
- **入参**: 同 D1001

### D1002 门诊收费

- **地址**: `instance/publish/yhis/V1/OutpatientCharge`
- **功能**: 门诊收费结算
- **入参**: `org_id`(必填), `visit_id`(必填), `patient_id`(必填), `pay_type`, `pay_amount`, `item_list`
- **出参**: `charge_id`(收费单ID), `receipt_no`(收据号)

### D1002A 门诊缴费[含医保]

- **地址**: `instance/publish/yhis/V1/OutpatientChargeWithInsure`
- **功能**: 门诊缴费，支持医保结算
- **入参**: 同 D1002，额外含 `insure_type`, `insure_info`(医保信息)

### D1003 获取门诊已缴费记录

- **地址**: `instance/publish/yhis/V1/GetPaidRecord`
- **功能**: 查询已缴费记录
- **入参**: `org_id`(必填), `patient_id`, `visit_id`, `begin_date`, `end_date`

### D1010 查询门诊住院费用明细

- **V1.0 地址**: `instance/publish/yhis/V1/GetFeeDetail`
- **功能**: 查询门诊或住院的费用明细
- **入参**: `org_id`(必填), `patient_id`, `visit_id`, `inpatient_id`, `begin_date`, `end_date`

### D1010A 查询门诊住院费用明细(按单据号汇总)

- **地址**: `instance/publish/yhis/V1/GetFeeDetailByBill`
- **功能**: 按单据号汇总返回费用明细
- **入参**: 同 D1010

### D1019 生成结账id

- **地址**: `instance/publish/yhis/V1/GenerateCheckoutId`
- **功能**: 生成结账唯一标识
- **入参**: `org_id`(必填), `visit_id`(必填)

### D1013 预缴款

- **地址**: `instance/publish/yhis/V1/Prepayment`
- **功能**: 住院预交款充值
- **入参**: `org_id`(必填), `inpatient_id`(必填), `patient_id`(必填), `pay_type`, `pay_amount`
- **出参**: `prepay_id`, `receipt_no`

### D1014 获取住院已结账记录

- **地址**: `instance/publish/yhis/V1/GetInpatientCheckoutRecord`
- **功能**: 查询住院已结账记录
- **入参**: `org_id`(必填), `inpatient_id`(必填)

### D1015 查询预交记录

- **地址**: `instance/publish/yhis/V1/GetPrepaymentRecord`
- **功能**: 查询住院预交款记录
- **入参**: `org_id`(必填), `inpatient_id`(必填)

### D1020 获取收费的价目

- **地址**: `instance/publish/yhis/V1/GetChargePrice`
- **功能**: 获取收费项目的价目表
- **入参**: `org_id`(必填), `item_id_list`(项目ID列表)

### D1004 门诊新增费用划价单

- **V1.0 地址**: `instance/publish/yhis/V1/AddOutpatientFeeBill`
- **V1.1 地址**: `instance/publish/yhis/V1.1/AddOutpatientFeeBill`
- **功能**: 新增门诊费用划价单
- **入参**: `org_id`(必填), `visit_id`(必填), `patient_id`(必填), `item_list`(项目列表), `doctor_id`, `dept_id`

### D1005 门诊住院删除费用划价单

- **地址**: `instance/publish/yhis/V1/DeleteFeeBill`
- **功能**: 删除未收费的费用划价单或记账单
- **入参**: `org_id`(必填), `bill_id`(必填)

### D1006 门诊退费

- **地址**: `instance/publish/yhis/V1/OutpatientRefund`
- **功能**: 门诊已收费项目退费
- **入参**: `org_id`(必填), `charge_id`(必填), `refund_item_list`, `refund_reason`

### D1007 根据单据号结算ID获取退费信息

- **地址**: `instance/publish/yhis/V1/GetRefundInfo`
- **功能**: 查询可退费的项目信息
- **入参**: `org_id`(必填), `receipt_no` 或 `charge_id`

### D1021 住院新增费用记账单

- **地址**: `instance/publish/yhis/V1/AddInpatientFeeBill`
- **功能**: 新增住院费用记账单
- **入参**: `org_id`(必填), `inpatient_id`(必填), `item_list`, `doctor_id`, `dept_id`, `nurse_id`

---

## 调用时序

### 挂号流程

```
C1001 获取挂号科室
  → C1002 获取科室医生（如需要）
    → C1003 获取排班信息
      → C1004 获取排班号别时段
        → C2001 提交挂号
```

### 门诊缴费流程

```
D1017 获取就诊信息
  → D1001 获取未缴费信息
    → D1001A 查询未交费明细（如需详情）
      → D1002 门诊收费 / D1002A 门诊缴费[含医保]
```

### 住院预交流程

```
D1015 查询预交记录（查看余额）
  → D1013 预缴款（充值）
    → D1014 获取住院已结账记录（查询历史）
```
