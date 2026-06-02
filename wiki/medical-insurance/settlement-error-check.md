# 结算误差费铁则

> **级别**：🚨 硬性红线，不可跳过  
> **适用**：所有医保结算流程（国家医保 + 五期，门诊 + 住院，预结算 + 正式结算）  
> **阈值**：`|HIS总费用 - 医保返回总费用| > 0.1元` 即拦截  
> **后果**：缺校验会导致**单边账**（HIS 认为结算成功，医保侧金额不一致）

---

## 为什么这条是铁则

医保正式结算 API 调用成功后，医保中心已生成结算记录。如果此时发现 HIS 侧金额与医保侧金额不一致（差额 > 0.1 元），不拦截意味着：

- HIS 侧记录了一笔"成功结算"
- 医保侧记录的金额不同
- 两边对不上 → **单边账**，财务无法平账

拦截 + 撤销机制可以把这个场景从"人工发现 → 对账 → 冲正 → 重算"（小时级甚至天级）压低到**实时拦截 + 自动撤销**（秒级）。

---

## 覆盖范围

| 通道 | 流程 | 方法 | `dc医保误差` 来源 | 超标动作 |
|---|---|---|---|---|
| 国家医保 | 门诊预结算 | `ProcessNationalPreSettlement` | `Math.Abs(actual_charge - setlinfo.medfee_sumamt)` | 🚫 返回失败 |
| 国家医保 | **门诊结算** | `ProcessNationalInsuranceSettlement` | 同上 | 🔄 调 2208 撤销 + 🚫 返回失败 |
| 国家医保 | 住院预结算 | `ProcessNationalInpatientPreSettlement` | 同上 | 🚫 返回失败 |
| 国家医保 | **住院结算** | `ProcessNationalInpatientSettlement` | 同上 | 🔄 调 2305 撤销 + 📝 保存作废记录 + 🚫 返回失败 |
| 五期 | 门诊挂号(SH01) | `ProcessFifthVersionRegister` | `Math.Abs(actual_charge - sh01Resp.totalexpense)` | 🚫 返回失败 |
| 五期 | 门诊收费(SI11) | `ProcessSI11Charge` | `Math.Abs(actual_charge - si11Resp.totalexpense)` | 🚫 返回失败 |
| 五期 | 住院结算(SI52) | `ProcessFifthVersionInpatientSettlement` | `Math.Abs(actual_charge - si52Resp.totalexpense)` | 🚫 返回失败 |

> **预结算 vs 正式结算**：预结算阶段未产生实际结算记录，阻塞即可。正式结算阶段医保侧已记账，必须**先调撤销接口冲正医保侧**，再返回失败。

---

## 代码模板

### 预结算（仅阻塞）

```csharp
string dc医保误差 = Math.Abs(decimal.Parse(actual_charge) - decimal.Parse(setlinfo.Value<string>("medfee_sumamt"))).ToString();
if (decimal.Parse(dc医保误差) > 0.1m)
{
    msg = "医保误差超过0.1元,HIS总费用:" + actual_charge + " 医保返回总费用:" + setlinfo.Value<string>("medfee_sumamt");
    log.WriteLog(msg);
    BaseTools.ShowMsg("医保接口提示", msg);
    result.Add("code", "0");
    result.Add("message", msg);
    return result;  // or return false for bool methods
}
```

### 正式结算（阻塞 + 撤销）

```csharp
decimal dc医保误差金额 = Math.Abs(actual_charge - decimal.Parse(setlinfo.Value<string>("medfee_sumamt")));
if (dc医保误差金额 > 0.1m)
{
    msg = "医保误差超过0.1元,HIS总费用:" + actual_charge + " 医保返回总费用:" + setlinfo.Value<string>("medfee_sumamt");
    log.WriteLog(msg);
    BaseTools.ShowMsg("医保接口提示", msg);

    // 调用撤销接口冲正医保侧记录
    JObject cancelReq = new JObject();
    JObject cancelData = new JObject();
    cancelData.Add("psn_no", setlinfo.Value<string>("psn_no"));
    cancelData.Add("mdtrt_id", setlinfo.Value<string>("mdtrt_id"));
    cancelData.Add("setl_id", setlinfo.Value<string>("setl_id"));
    cancelReq.Add("data", cancelData);

    string cancelRes = "";
    Random rc = new Random();
    string cancelMsgid = BusinessHelper.HisCode + DateTime.Now.ToString("yyyyMMddHHmmss") + rc.Next(1000, 9999);
    string cancelResult = BusinessHelper.YBBusiness(YBList.门诊结算撤销, cancelReq, cancelMsgid, insuplcAdmdvs, ref cancelRes);
    log.WriteLog($"误差费超标自动撤销结算,返回值:{cancelResult},返回信息:{cancelRes}");

    result.Add("code", "0");
    result.Add("message", msg);
    return result.ToString();
}
```

> **国家医保撤销交易号**：门诊 `2208`（`YBList.门诊结算撤销`），住院 `2305`（`YBList.住院结算撤销`）

---

## 常见漏加场景

### 为什么预结算加了、正式结算没加？

开发者在预结算阶段"顺手"写了误差判断（刚拿到返回值自然想到校验），但到正式结算阶段心理上已经过了校验关，以为"预结算过了数据一定一致"。实际上预结算和正式结算之间有时差（病人缴费、退费、加项），HIS 侧费用可能变化。

**检查清单**：每新增一个结算流程，检查 3 个位置——

1. ✅ 误差计算：`Math.Abs(actual_charge - 医保返回总费用)`
2. ✅ `> 0.1m` 拦截
3. ✅ 正式结算需要配套的撤销逻辑

### 五期通道容易遗漏

五期 `SendRcv4.dll` 不经 AOP 日志链，测试时不像国家医保通道那样能看到 `ins_log` 表记录。开发者容易只关注返回码（`xxfhm == "P001"`）而忘记校验金额。

---

## 历史教训

| 时间 | 项目 | 问题 |
|---|---|---|
| 2026-05 | 上海医保 | 住院正式结算误差费校验代码已写好但**被整段注释**，门诊结算完全没写校验。国家医保住院预结算硬编码 `"0"`，五期全通道硬编码 `"0"` |
| 2026-05 | 其他医保项目 | 门诊预结算加了误差判断，门诊正式结算漏加（开发者口述："只顾着预结算，忘了正式结算"） |

---

**维护者**：Keiskei  
**创建日期**：2026-05-26
