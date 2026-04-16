# 费用结算

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/01-HIS业务/费用结算.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/subsystems/billing/index.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

> 待完善：基于项目代码补充详细流程

## 基本流程

```
产生费用 → 费用汇总 → 医保结算 → 自费支付 → 打印票据
```

## 接口组相关

- Plugins.MedicalInsurance — 医保结算插件
- Plugins.Payment — 银联POS支付
- Plugins.ElecBill — 电子票据
- Plugins.InsuranceReconc — 医保对账
- HF.CPAPI.Insure — 新医保接口
- 上海医保：`D:\work\his-medical-group\上海医保五期接口\`
- 北京医保：`D:\work\his-medical-group\zlchs.BJ.XBYB.insure\`

## 相关Schema

- `fee` — 费用数据
- `insur` — 医保数据

## 详细流程说明

### 1. 费用产生阶段
- 门诊费用：挂号费、诊查费、药品费、检验检查费
- 住院费用：床位费、药品费、治疗费、手术费、检验检查费
- 实时计费：医嘱执行时自动计费
- 批量计费：夜间批量处理

### 2. 费用汇总阶段
- 按患者汇总费用
- 按费用类型分类
- 医保目录匹配
- 自费项目识别

### 3. 医保结算阶段
- 调用医保接口
- 费用明细上传
- 医保政策计算
- 结算结果返回
- 自付比例计算

### 4. 自费支付阶段
- 现金支付
- 银行卡支付（POS）
- 移动支付
- 医保卡支付
- 预交金抵扣

### 5. 票据处理阶段
- 纸质票据打印
- 电子票据生成
- 票据信息上传财政平台
- 票据归档管理

## 医保结算流程

### 门诊医保结算
```
费用明细 → 医保目录匹配 → 政策计算 → 接口调用 → 结算返回 → 支付处理
```

### 住院医保结算
```
预结算 → 费用上传 → 医保审核 → 最终结算 → 结算单生成 → 出院结算
```

## 接口技术要点

### 医保接口特点
- 各地医保政策不同
- 接口标准不统一
- 实时性要求高
- 数据准确性要求严格

### 支付接口特点
- 多种支付方式支持
- 交易安全性要求高
- 对账准确性重要
- 退款处理复杂

### 票据接口特点
- 财政标准严格
- 票据号码管理
- 作废处理流程
- 归档要求规范

## 数据表关系

### 核心数据表
- `fee.fee_detail` — 费用明细表
- `fee.fee_settle` — 结算记录表
- `insur.insur_settle` — 医保结算表
- `fee.payment_record` — 支付记录表
- `fee.elec_bill` — 电子票据表

### 关联数据表
- `outpatient.outp_fee_detail` — 门诊费用明细
- `inp.inp_fee_detail` — 住院费用明细
- `patient.patient_info` — 患者信息
- `drug.drug_dispense` — 药品发放记录

---
**文档来源**: Keiskei 整理的HIS知识库  
**整理说明**: 从Windows桌面知识库整理到his-wiki统一管理  
**子系统**: 费用结算  
**相关文档**: [HIS业务概览](overview.md)、[门诊流程](../outpatient/index.md)、[住院流程](../inpatient/index.md)、[接口设计规范](../../schema/规范/接口设计规范.md)