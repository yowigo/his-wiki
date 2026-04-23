# 门诊结算完整流程

> 原始资料：[HIS5.0 北京医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md)、[zlchs.Webhis.Test.Insure 学习笔记](../../raw/医保开发/医保开发文档/zlchs.Webhis.Test.Insure-学习笔记.md)

---

## 业务类型

| 编码 | 名称 | 对应方法 |
|------|------|----------|
| `1101` | 门诊选择保险 | `ClincChoseInsure()` |
| `1102` | 门诊取消保险 | `ClincCancelInsure()` |
| `1103` | 门诊医保项目打标 | `ClincInsureItemCheck()` |
| `1104` | 门诊费用明细上传 | `ClincDetailCancel()` |
| `1105` | 门诊费用明细撤销 | `ClincDetailCancel()` |
| `1106` | 门诊结算 | `ClincSettle()` |
| `1107` | 门诊取消结算 | `ClincSettleBack()` |

---

## 一、门诊选择保险 (1101)

### 流程

```
HIS 前端 → {business_type:"1101", org_id:"xxx", ...}
    │
    ▼
Common.Interface() → switch → Business.ClincChoseInsure(data)
    │
    ├─ ① 弹出医保选择对话框（Frm医保选择）
    │      → 用户选择医保类型 → 获取 ins_id
    │
    ├─ ② 初始化医保接口
    │      → InsureBusiness._objectReflection(ins_id)
    │      → 查库 insur.ins_system → 获取 DLL 名称
    │      → ObjectReflection.CreateObject() → 动态加载 DLL
    │      → IInsureInterface.InitInsure()
    │
    ├─ ③ 身份验证
    │      → IInsureInterface.Identify()
    │      → 查医保档案 / 或弹窗输入医保卡号
    │      → 保存到 insur.ins_archive + insur.ins_archive_vs
    │
    ├─ ④ 获取账户余额
    │      → IInsureInterface.SelfBalance()
    │      → SELECT swap_info->>'选择余额' FROM insur.ins_archive
    │
    └─ ⑤ 返回 {pt_id, ins_id, personal_account, patient_insur_type, ...}
```

### 关键代码

```csharp
public string ClincChoseInsure(JObject data)
{
    // ① 弹出医保选择对话框
    Frm医保选择 frm = new Frm医保选择(orgid, data.ToString());
    frm.ShowDialog();
    if (string.IsNullOrEmpty(frm.InsureSystem))
        return 错误响应("选择医保返回空!");

    // ② 将选择结果写入请求数据
    data.Add("ins_id", frm.InsureSystem);

    // ③ 初始化医保接口
    InsureBusiness insure = new InsureBusiness();
    bool b = insure.InitInsure(data.ToString());
    if (!b) return 错误响应("初始化失败!");

    // ④ 身份验证
    string identify = insure.Identify(data.ToString());
    // ... 校验 code

    // ⑤ 回写 pt_id
    data.Add("pt_id", identify_out.Value<JObject>("data").Value<string>("pt_id"));

    // ⑥ 获取账户余额
    string balance = insure.SelfBalance(data.ToString());
    // ... 校验 code

    // ⑦ 组织返回值
    JObject out_data = identify_out.Value<JObject>("data");
    out_data.Add("personal_account", balance_out.Value<JObject>("data").Value<string>("personal_account"));
    out_data.Add("name", frm.ins_name);
    out_data.Add("ins_code", frm.ins_code);
    return JsonConvert.SerializeObject(new Response { code = "1", data = out_data });
}
```

---

## 二、门诊结算 (1106)

### 完整流程

```
HIS 收费 → ClinicPreSwap (预结算)
    │
    ├─ 1. 查询 insur.ins_archive（患者医保档案）
    ├─ 2. SaveInsureVisit（保存就诊记录到 insur.ins_visit）
    ├─ 3. Frm结算方式配置.ShowDialog()（用户选择支付方式）
    ├─ 4. CheckBalanceWay（校验结算方式）
    └─ 5. 返回 {settle_type, defult_settle_type, is_split}
            │
HIS 确认 → ClinicSwap (正式结算)
    │
    ├─ 1. 查询 insur.ins_visit（获取就诊记录）
    ├─ 2. Frm结算方式配置.ShowDialog()（再次确认）
    ├─ 3. SaveInsureBalance（保存结算到 insur.ins_balance）
    └─ 4. 返回 {settle_type, patient_insur_type}
            │
HIS 退费 → ClinicDelSwap (结算作废)
    │
    ├─ 1. 查询 insur.ins_balance + ins_balance_info
    ├─ 2. 判断是否共济结算（关联记录）
    ├─ 3. 判断是否有退账ID
    │     ├── 有 → RefondBalance() 冲负
    │     └── 无 → 直接 DELETE
    └─ 4. 插入负数金额记录（冲负场景）
```

### 总控编排 (ClincSettle)

```csharp
public string ClincSettle(JObject data)
{
    // ① 初始化
    InsureBusiness insure = new InsureBusiness();
    bool b = insure.InitInsure(data.ToString());
    if (!b) return 错误响应("初始化失败!");

    // ② 预结算（非拆分模式）
    string is_split = data.Value<string>("is_split");
    if (is_split != "1")
    {
        string presettle = insure.ClinicPreSwap(data.ToString());
        presettle_out = JObject.Parse(presettle);
        if (presettle_out.Value<string>("code") != "1")
            return 错误响应("预结算失败!");
    }

    // ③ 正式结算
    if (presettle_out_data != null && presettle_out_data.Value<string>("is_split") == "1")
        settle_out = presettle_out;  // 拆分模式
    else
    {
        string settle = insure.ClinicSwap(data.ToString());
        settle_out = JObject.Parse(settle);
        if (settle_out.Value<string>("code") != "1")
            return 错误响应("结算失败!");
    }

    // ④ 获取余额（失败则自动回滚结算）
    string balance = insure.SelfBalance(data.ToString());
    JObject balance_out = JObject.Parse(balance);
    if (balance_out.Value<string>("code") != "1")
    {
        insure.ClinicDelSwap(data.ToString());  // ★ 自动撤销
        return 错误响应("获取账户余额失败!");
    }

    // ⑤ 组织返回值
    JObject out_data = settle_out.Value<JObject>("data");
    out_data.Add("personal_account", balance_out.Value<JObject>("data").Value<string>("personal_account"));
    return JsonConvert.SerializeObject(new Response { code = "1", data = out_data });
}
```

---

## 三、门诊结算作废 (1107)

### 撤销策略

```csharp
public string ClinicDelSwap(string strJson)
{
    string balance_id = model.Value<string>("balance_id");
    string refund_id = model.Value<string>("refund_id");

    // ① 查询结算记录
    DataTable dt = BaseDataHelper.GetDataTable(strJson, "ClinicDelSwap", "fee",
        "select * from insur.ins_balance where balance_id = @balanceid", ...);

    // ② 检查是否有共济结算关联
    DataTable dt1 = BaseDataHelper.GetDataTable(strJson, "ClinicDelSwap", "fee",
        @"select pb.id, pb.description from public.pt_balance pb, insur.ins_balance ib
           where pb.id = ib.balance_id and (pb.id = @balanceid or pb.complement_id = @balanceid)", ...);

    // ③ 根据 refund_id 决定撤销方式
    if (string.IsNullOrEmpty(refund_id))
    {
        // 直接删除模式
        BaseDataHelper.ExteSql(strJson, "ClinicDelSwap", "fee",
            "delete from insur.ins_balance_info where balance_id = @balanceid", ...);
        BaseDataHelper.ExteSql(strJson, "ClinicDelSwap", "fee",
            "delete from insur.ins_balance where balance_id = @balanceid", ...);
    }
    else
    {
        // 冲负模式（退费）
        BaseDataHelper.RefondBalance(balance_id, refund_id, org_id, strJson);
        // 生成负数结算明细
    }
}
```

---

## 四、全链路代码走查（以 1106 为例）

```
步骤 1: HIS 前端 → {business_type:"1106", ins_id:"002", pt_id:"xxx", ...}

步骤 2: WebInsurance.ProcessRequest("Interface", jsonParams)
         → WebInsuranceHelper.Interface(jsonParams)
         → CommonTools.ExceInsureMethod()
         → Assembly.Load("zlchs.Interface.Control")
         → 反射调用 zlchs.Interface.Control.Common.Interface(jsonParams)

步骤 3: Common.Interface()
         → businesstype = "1106"
         → ★ 非 "8" 开头 → 从 token 解析登录信息
         → switch → Business.ClincSettle(DataIn)

步骤 4: Business.ClincSettle()
         ├─ insure.InitInsure()
         │   ├─ InsureBusiness._objectReflection("002")
         │   │   → SQL: SELECT interface_name FROM insur.ins_system WHERE id='002'
         │   │   → "zlchs.BJ.XBYB.insure"
         │   │   → ObjectReflection.CreateObject(...)
         │   │   → Cls_BJGJBYB 实例
         │   └─ Cls_BJGJBYB.InitInsure()
         │       → 读取 insur.ins_initial 配置
         │
         ├─ insure.ClinicPreSwap()
         │   └─ 查询档案/费用/处方 → 🔗 MedicareComHelper.Divide() → 更新数据库
         │
         ├─ insure.ClinicSwap()
         │   └─ 查询就诊记录 → 确认窗口 → 🔗 MedicareComHelper.TradeAll() → 保存结算
         │
         ├─ insure.SelfBalance()
         │   └─ SELECT swap_info->>'选择余额' FROM insur.ins_archive
         │
         └─ 返回 → Business → Common → CommonTools → WebInsurance → HIS 前端
```
