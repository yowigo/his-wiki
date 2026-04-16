# HIS 业务概览

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/01-HIS业务/01概览.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/subsystems/overview.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

## 系统定位

HIS（Hospital Information System，医院信息系统）是医院核心业务系统，覆盖诊疗全流程。

## 工作目录与项目关系

| 目录 | 项目 | 定位 | 技术栈 | 处理状态 |
|------|------|------|--------|----------|
| D:\work\his-medical-group | 接口组 | 客户端插件平台，对接外部系统 | .NET Framework 4.8 | 处理中 |
| D:\work\his510 | HIS 5.1 | 新版HIS主系统 | .NET 8.0 + KendoUI | 暂不处理 |
| D:\work\his5.0 | HIS 5.0 | 主力HIS系统 | .NET Core + KendoUI | 暂不处理 |
| D:\work\his | HIS | 旧版HIS | 待整理 | 暂不处理 |

## 接口组（his-medical-group）核心业务

接口组负责 HIS 客户端与外部系统的对接，通过插件架构实现：

### 主要业务插件

| 插件 | 功能 | 对接系统 |
|------|------|----------|
| Plugins.MedicalInsurance | 医保结算 | 医保中心 |
| Plugins.MedicalMatch | 医保对码 | 医保编码库 |
| Plugins.EB_TestRecongnition | 检验检查互认 | 广东/北京互认平台 |
| Plugins.ElecBill | 电子票据 | 财政票据平台 |
| Plugins.Drug | 药品管理 | 药品系统 |
| Plugins.Payment | 支付处理 | 银联POS |
| Plugins.HealthCard / Plugins.IDCard | 读卡 | 读卡设备 |
| Plugins.PhysicalExamination | 体检接口 | 体检设备 |
| Plugins.InsuranceReconc | 医保对账 | 医保中心 |
| HF.CPAPI.Insure | 医保（新） | 医保中心 |

### 核心代码结构

```
his-medical-group/code/
├── sdp.cpapi/                       # 主客户端框架（40+子项目）
│   ├── CPAPI.Client.new/            # 主客户端应用
│   ├── CPAPI.Client.Base/           # WebSocket通信
│   ├── SDP.CPAPI.Core/              # 路由/IoC/日志
│   ├── CPAPI.Client.PluginHandle/   # 插件加载器
│   ├── ZLSoft.CHSS.CPAPI.PluginBase/ # 插件基类
│   ├── Plugins.MedicalInsurance/    # 医保结算
│   ├── Plugins.MedicalMatch/        # 医保对码
│   └── ...其他插件
├── plugins.eb_testrecongnition/     # 检验检查互认
├── CodingToolTranslation/           # 对码工具
├── HF.CPAPI.Insure/                 # 新医保接口
├── QWSB.Plugin.Demo/               # 插件开发模板
├── Common/                          # 共享公共类库
└── zlchs.ReadCard.Interface/        # 读卡接口
```

## HIS 核心业务模块

| 模块 | HIS工作站 | 说明 |
|------|-----------|------|
| 门诊 | outp_doc_wksta | 门诊医生工作站 |
| 住院 | inp_doctor_wksta | 住院医生工作站 |
| 检验 | lab_wksta | 检验工作站 |
| 影像 | rad_wksta | 放射工作站 |
| 护理 | nurse_wksta | 护士工作站 |
| 收费 | fee_wksta | 收费工作站 |
| 药房 | drug_wksta | 药房工作站 |

## 业务流程简述

### 门诊流程

```
挂号 → 接诊 → 开医嘱（检验/检查/药品）→ 收费 → 执行（取药/检验/检查）→ 报告
```

### 住院流程

```
入院登记 → 医生下医嘱 → 护士执行 → 费用记录 → 出院结算
```

### 接口触发时机

```
门诊接诊后     → after_outp_recvt          → 上传患者+查询互认报告
开检验医嘱前   → before_lab_apply_save     → 检查互认匹配
检验审核后     → after_lab_audit           → 上传检验数据
影像审核后     → after_rad_rpt_audit       → 上传影像数据
住院切换患者前 → before_doctor_next_patient → 上传患者+查询互认报告
保存住院医嘱前 → before_inp_order_save     → 检查互认匹配
```

---
**文档来源**: Keiskei 整理的HIS知识库  
**整理说明**: 从Windows桌面知识库整理到his-wiki统一管理  
**核心内容**: 系统定位、项目关系、插件架构、业务流程  
**相关文档**: [接口设计规范](../schema/规范/接口设计规范.md)、[编码规范](../schema/规范/编码规范.md)