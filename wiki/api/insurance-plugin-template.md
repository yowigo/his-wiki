# 医保插件开发模板

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/02-接口模板/医保插件开发模版.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/api/insurance-plugin-template.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

> 待完善：基于现有医保插件（Plugins.MedicalInsurance、HF.CPAPI.Insure）补充详细内容

## 医保插件概述

医保插件是HIS系统对接医保平台的核心组件，负责：
- 医保费用实时结算
- 医保目录对码
- 医保政策计算
- 医保对账管理

## 现有医保插件参考

### 1. 旧版医保插件（Plugins.MedicalInsurance）
- **路径**: `D:\work\his-medical-group\code\sdp.cpapi\Plugins.MedicalInsurance\`
- **技术栈**: .NET Framework 4.8
- **功能**: 医保结算、对码、对账
- **对接平台**: 各地医保中心

### 2. 新版医保插件（HF.CPAPI.Insure）
- **路径**: `D:\work\his-medical-group\code\HF.CPAPI.Insure\`
- **技术栈**: .NET Framework 4.8
- **功能**: 新医保接口标准
- **特点**: 模块化设计，支持多地区配置

### 3. 上海医保五期接口
- **路径**: `D:\work\his-medical-group\上海医保五期接口\`
- **特点**: 上海地区专用，符合五期标准

### 4. 北京医保接口
- **路径**: `D:\work\his-medical-group\zlchs.BJ.XBYB.insure\`
- **特点**: 北京地区专用，新医保标准

## 医保插件开发要点

### 1. 地区差异处理
- 各地医保政策不同
- 接口标准不统一
- 加密方式差异
- 数据格式差异

### 2. 核心业务流程

#### 医保结算流程
```
费用明细 → 医保目录匹配 → 政策计算 → 接口调用 → 结算返回 → 支付处理
```

#### 医保对码流程
```
医院项目 → 医保目录匹配 → 编码映射 → 审核确认 → 同步医保平台
```

#### 医保对账流程
```
日终对账 → 数据汇总 → 差异比对 → 问题处理 → 对账确认
```

### 3. 数据表结构

#### 核心数据表
- `insur.insur_settle` — 医保结算记录
- `insur.insur_item_map` — 医保项目映射
- `insur.insur_reconc` — 医保对账记录
- `insur.insur_policy` — 医保政策配置

#### 关联数据表
- `fee.fee_detail` — 费用明细
- `patient.patient_info` — 患者信息
- `drug.drug_info` — 药品信息
- `b_clin_item` — 临床项目字典

## 医保插件开发模板

### 1. 插件入口类

```csharp
using Newtonsoft.Json.Linq;
using ZLSoft.CHSS.CPAPI.PluginBase.Base;

namespace Plugins.EB_Insurance
{
    /// <summary>
    /// 医保插件入口
    /// </summary>
    public class EB_Insurance : CPAPIPluginBase
    {
        public override string PluginName => "医保结算插件";
        public override string Description => "对接各地医保平台，实现医保实时结算";

        private readonly InsuranceService _service = new InsuranceService();

        public override PluginResult ProcessRequest(string action, string jsonParams)
        {
            LogTools.Info($"[EB_Insurance] ProcessRequest: action={action}");

            try
            {
                JObject busiParam = JObject.Parse(jsonParams);
                string functionCode = busiParam.Value<string>("function_code");
                string data = busiParam.Value<string>("data");

                object result = null;

                switch (functionCode)
                {
                    case "InsuranceSettlement":
                        result = _service.InsuranceSettlement(data, jsonParams);
                        break;
                    case "InsuranceItemMapping":
                        result = _service.InsuranceItemMapping(data, jsonParams);
                        break;
                    case "InsuranceReconciliation":
                        result = _service.InsuranceReconciliation(data, jsonParams);
                        break;
                    default:
                        return new PluginResult
                        {
                            Code = -1,
                            Message = $"未知的医保功能标识: {functionCode}"
                        };
                }

                return new PluginResult
                {
                    Code = 0,
                    Message = "操作成功",
                    Data = result
                };
            }
            catch (Exception ex)
            {
                LogTools.Error($"[EB_Insurance] ProcessRequest failed: {ex.Message}", ex);
                return new PluginResult
                {
                    Code = -1,
                    Message = $"医保操作失败：{ex.Message}"
                };
            }
        }
    }
}
```

### 2. 医保服务类

```csharp
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ZLSoft.CHSS.CPAPI.PluginBase.Base;

namespace Plugins.EB_Insurance.Service
{
    /// <summary>
    /// 医保服务实现
    /// </summary>
    public class InsuranceService
    {
        /// <summary>
        /// 医保结算
        /// </summary>
        public object InsuranceSettlement(string data, string jsonParams)
        {
            // 1. 解析结算参数
            var param = JObject.Parse(data);
            var patientId = param.Value<string>("patientId");
            var feeItems = param.Value<JArray>("feeItems");

            // 2. 查询患者医保信息
            var patientInfo = GetPatientInsuranceInfo(patientId, jsonParams);

            // 3. 医保目录匹配
            var matchedItems = MatchInsuranceItems(feeItems, jsonParams);

            // 4. 医保政策计算
            var settlementResult = CalculateInsuranceSettlement(matchedItems, patientInfo);

            // 5. 调用医保平台接口
            var platformResult = CallInsurancePlatform(settlementResult);

            // 6. 保存结算记录
            SaveSettlementRecord(settlementResult, platformResult, jsonParams);

            return platformResult;
        }

        /// <summary>
        /// 医保项目对码
        /// </summary>
        public object InsuranceItemMapping(string data, string jsonParams)
        {
            // 1. 解析对码参数
            var param = JObject.Parse(data);
            var hospitalItemCode = param.Value<string>("hospitalItemCode");
            var itemType = param.Value<string>("itemType");

            // 2. 查询医保目录
            var insuranceItems = QueryInsuranceCatalog(itemType, jsonParams);

            // 3. 智能匹配
            var matchedItems = IntelligentMatch(hospitalItemCode, insuranceItems);

            // 4. 保存映射关系
            SaveItemMapping(hospitalItemCode, matchedItems, jsonParams);

            return matchedItems;
        }

        /// <summary>
        /// 医保对账
        /// </summary>
        public object InsuranceReconciliation(string data, string jsonParams)
        {
            // 1. 解析对账参数
            var param = JObject.Parse(data);
            var startDate = param.Value<string>("startDate");
            var endDate = param.Value<string>("endDate");

            // 2. 查询本地结算记录
            var localRecords = QueryLocalSettlementRecords(startDate, endDate, jsonParams);

            // 3. 查询医保平台记录
            var platformRecords = QueryPlatformSettlementRecords(startDate, endDate);

            // 4. 对账比对
            var reconciliationResult = ReconcileRecords(localRecords, platformRecords);

            // 5. 保存对账结果
            SaveReconciliationResult(reconciliationResult, jsonParams);

            return reconciliationResult;
        }
    }
}
```

## 配置文件示例

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <!-- 地区配置 -->
    <region_code>310000</region_code>
    <region_name>上海市</region_name>
    
    <!-- 医保平台地址 -->
    <insurance_platform_url>https://shyb.sh.gov.cn/api</insurance_platform_url>
    
    <!-- 认证信息 -->
    <hospital_code>H001</hospital_code>
    <hospital_name>XX医院</hospital_name>
    <certificate_path>cert/hospital.pfx</certificate_path>
    <certificate_password>******</certificate_password>
    
    <!-- 加密配置 -->
    <encryption_type>SM2</encryption_type>
    <public_key>MFkwEwYHKoZIzj0CAQYIKoEcz1UBgi0DQgAExxxxxx</public_key>
    <private_key>MIGHAgEAMBMGByqGSM49AgEGCCqBHM9VAYItBG0wawIBAQQgxxxxxx</private_key>
    
    <!-- 业务配置 -->
    <settlement_timeout>30</settlement_timeout>
    <reconciliation_time>02:00</reconciliation_time>
    <max_retry_count>3</max_retry_count>
</configuration>
```

## 开发注意事项

### 1. 地区适配
- 不同地区医保政策差异大
- 接口标准需要单独适配
- 加密方式可能不同
- 数据格式需要转换

### 2. 性能优化
- 医保目录缓存
- 结算结果缓存
- 批量处理优化
- 异步处理机制

### 3. 错误处理
- 网络异常处理
- 平台返回错误处理
- 数据格式错误处理
- 重试机制

### 4. 日志记录
- 详细的操作日志
- 错误日志记录
- 性能日志记录
- 审计日志记录

## 测试要点

### 1. 单元测试
- 医保政策计算测试
- 目录匹配测试
- 数据转换测试
- 错误处理测试

### 2. 集成测试
- 医保平台接口测试
- 结算流程测试
- 对账流程测试
- 性能压力测试

### 3. 回归测试
- 地区政策变更测试
- 接口升级测试
- 数据迁移测试
- 兼容性测试

---
**文档来源**: Keiskei 整理的HIS知识库  
**整理说明**: 基于现有医保插件整理开发模板  
**模板类型**: 医保插件开发  
**适用项目**: 各地医保平台对接  
**核心内容**: 插件结构、业务流程、配置模板、开发要点  
**相关文档**: [插件开发模板](plugin-development.md)、[第三方对接模板](third-party-integration.md)