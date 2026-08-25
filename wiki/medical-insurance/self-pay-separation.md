# 医保自费分离结算改造方案

> 原始资料：`../../raw/外部接口开发/上海医保项目五期/医保自费分离结算改造方案.md`
> 适用项目：`zlchs.SH.GJBYB.insure`（国家医保 + 上海五期双通道）
> 关联页面：[结算误差费铁则](settlement-error-check.md)、[上海医保五期插件](shanghai-5th.md)

## 一、改造背景

按医保规范，结算项目原则上都应完成医保对码后方可上传结算。但对**盈利性医疗机构**（如希玛眼科），大量项目不纳入医保报销、不走对码流程是常态。

- 旧行为：费用上传检测到未对码项目 → 直接报错中断 → 要求对码后重新结算（公立医院场景合理）。
- 需求：**医保项目和自费项目分开结算**。检测到未对码项目时弹窗二选一：
  1. **对码后重新结算** — 当前做法，直接 return；
  2. **继续结算** — 过滤掉没有医保编码的明细不上传国家平台，同时跳过医保误差判断。

**业务原理**：HIS 结算时汇总所有结算方式（个人账户、医保基金、现金等）的返还金额，患者现金支付 = 总金额 − 各医保结算方式返还。未对码项目不上传后，医保平台只对已上传项目计算返还，被过滤项目的费用自然落入差额由患者自费承担，无需额外处理。

## 二、改造范围

### 2.1 弹窗改造（3 处）

「医保未对码」判定：`InsMedicalCode`（门诊）/ `InsItemCode`（住院）为空，且 `LocalFeeType != "自费"`。

| # | 方法 | 场景 |
| --- | --- | --- |
| A1 | `ClinicPreSwap` | 门诊预结算（国家+五期） |
| A2 | `ProcessNationalInpatientPreSettlement` | 国家住院预结算 |
| A3 | `ProcessFifthVersionInpatientPreSettlement` | 五期住院预结算 |

> 不在范围（保持现状直接报错）：材料国家码、非材料国家码、五期自付比例、科别对照、医生编码。

### 2.2 误差判断跳过（6 处）

选「继续结算」后设置标志位 `SkipInsureErrorCheck`，后续 `|HIS总费用 - 医保总费用| > 0.1 元` 硬阻塞检查到该标志为 true 时**仅记日志不阻塞**。

| # | 方法 | 场景 |
| --- | --- | --- |
| B1 | `ProcessSI11Charge` | 五期门诊 SI11 试算 |
| B2 | `ProcessNationalPreSettlement` | 国家门诊预结算 |
| B3 | `ProcessNationalInsuranceSettlement` | 国家门诊正式结算（含 2208 撤销，跳过时一并跳过） |
| B4 | `ProcessNationalInpatientPreSettlement` | 国家住院预结算 |
| B5 | `ProcessNationalInpatientSettlement` | 国家住院正式结算（含 2305 撤销，一并跳过） |
| B6 | `ProcessFifthVersionInpatientSettlement` | 五期住院正式结算 |

### 2.3 标志位生命周期

- `private static bool SkipInsureErrorCheck = false;` 类级字段，跨预结算→正式结算保持。
- 每个 public 入口方法起始处重置：`ClinicPreSwap` / `ClinicSwap` / `WipeoffMoney` / `SettleSwap` + `InitInsure` 兜底。

## 三、改造逻辑（伪代码）

```
if (未对码项目.Count > 0)
{
    收集未对码项列表 → undmlist（去重）; 写日志;
    弹窗：是否对码后重新结算？
    if (是)  { result["code"]="0"; return; }                    // 同现有行为
    else     { feeList = feeList.Where(有医保编码); SkipInsureErrorCheck = true; }
}

#region 医保误差
if (SkipInsureErrorCheck)  log.WriteLog("跳过误差判断（已过滤未对码项目继续结算）");
else                       { /* 原有误差判断 + 撤销逻辑不变 */ }
dc医保误差 = SkipInsureErrorCheck ? "0" : 误差计算值;
```

## 四、关键结论

- `actual_charge` 在整个流程中**仅用于误差比较**，不参与上传请求体的费用总额计算。请求体 `medfee_sumamt`（国家）/ `bcmxylfyze`（五期）均由过滤后的 feeList 实时累加，金额正确。
- 不影响项：自费项目（原本就排除）、材料/非材料国家码校验、五期自付比例、科别对照、医生编码、正式结算撤销逻辑（仅误差跳过时同步跳过）。

## 五、测试要点（节选）

- 功能：全部已对码 → 无弹窗正常结算；选「对码后重新结算」→ 同现有行为；选「继续结算」→ 过滤+跳过误差正常返回；全部未对码选继续 → feeList 全空上传 0 条；仅自费项目未对码 → 无弹窗。
- 回归：正常结算不受影响；材料缺国家码/科别未对照/医生缺编码仍直接报错；误差 0.05 元不触发；误差 0.15 元正常报错 + 撤销。

