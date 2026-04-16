# 患者管理

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/01-HIS业务/患者管理.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/subsystems/patient/index.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

> 待完善：基于项目代码补充详细流程

## 核心概念

- 患者ID（pt_id）：系统内唯一标识
- 身份证号（id_card / ideno）：自然人唯一标识
- 就诊号：每次就诊的唯一标识

## 接口组相关

- Plugins.HealthCard — 健康卡读取
- Plugins.IDCard — 身份证读取
- zlchs.ReadCard.Interface — 读卡接口

## 相关Schema

- `patient` — 患者基础数据
- `outpatient` — 门诊就诊数据
- `inp` — 住院就诊数据

## 详细业务流程

### 1. 患者建档阶段
- 基本信息登记（姓名、性别、出生日期、身份证号）
- 联系方式登记（电话、地址）
- 医保信息登记（医保类型、医保卡号）
- 过敏史登记
- 既往病史登记

### 2. 患者识别阶段
- 身份证读取
- 医保卡读取
- 健康卡读取
- 就诊卡读取
- 人脸识别（如支持）

### 3. 就诊信息管理
- 门诊就诊记录
- 住院就诊记录
- 急诊就诊记录
- 体检记录
- 随访记录

### 4. 患者信息查询
- 基本信息查询
- 就诊历史查询
- 检验检查报告查询
- 用药记录查询
- 费用记录查询

## 接口集成点

### 读卡接口
- 身份证读卡器对接
- 医保卡读卡器对接
- 健康卡读卡器对接
- 就诊卡读卡器对接

### 患者信息同步
- 院内系统间患者信息同步
- 医联体内患者信息共享
- 区域平台患者信息交换

### 身份认证
- 实名认证
- 医保身份认证
- 电子健康卡认证
- 生物特征认证

## 数据表结构

### 核心数据表
- `patient.patient_info` — 患者基本信息
- `patient.patient_contact` — 患者联系方式
- `patient.patient_medical_history` — 患者病史
- `patient.patient_allergy` — 患者过敏史

### 就诊相关表
- `outpatient.outp_visit` — 门诊就诊记录
- `inp.inp_admission` — 住院入院记录
- `inp.inp_discharge` — 住院出院记录
- `emergency.emerg_visit` — 急诊就诊记录

### 身份识别表
- `patient.patient_identity` — 患者身份标识
- `patient.patient_card` — 患者卡信息
- `patient.patient_biometric` — 患者生物特征

## 技术实现要点

### 患者唯一标识
- 院内患者ID生成规则
- 患者主索引（EMPI）管理
- 患者信息合并与拆分
- 患者信息去重机制

### 信息安全管理
- 患者隐私保护
- 信息访问权限控制
- 信息脱敏处理
- 操作日志记录

### 数据一致性
- 患者信息同步机制
- 数据冲突解决策略
- 信息更新通知机制
- 历史数据保留策略

## 特殊业务场景

### 新生儿管理
- 母亲信息关联
- 临时身份标识
- 正式身份更新
- 出生证明关联

### 急诊患者管理
- 无名氏患者处理
- 紧急救治记录
- 身份后续确认
- 信息补全机制

### 跨院区患者管理
- 患者信息共享
- 就诊记录同步
- 检验检查结果互认
- 费用结算统一

---
**文档来源**: Keiskei 整理的HIS知识库  
**整理说明**: 从Windows桌面知识库整理到his-wiki统一管理  
**子系统**: 患者管理  
**相关文档**: [HIS业务概览](overview.md)、[门诊流程](../outpatient/index.md)、[住院流程](../inpatient/index.md)、[接口设计规范](../../schema/规范/接口设计规范.md)