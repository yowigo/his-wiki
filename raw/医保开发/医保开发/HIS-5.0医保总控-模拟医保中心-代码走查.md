# HIS5.0 → 医保总控 → 模拟医保中心：完整代码走查

> 基于 HIS5.0 新总控 `zlsoft.cpapi.insure` + 测试医保实现 `zlchs.Webhis.Test.Insure`，逐层展示完整调用链路。
>
> **总控代码位置**: `D:\work\his-medical-group\zlsoft.cpapi.insure`（命名空间 `zlchs.*`）
> **测试实现位置**: `D:\work\his-medical-group\code\HF.CPAPI.Insure\医保接口\zlchs.Webhis.Test.Insure`

---

## 与 HIS5.1 版本总控的差异速览

| 方面                       | HIS5.1 (CICT)                                                                 | HIS5.0 (zlchs)                                                                    |
| -------------------------- | ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **命名空间**         | `CICT.Interface.Control` / `CICT.Common.Base` / `CICT.Insure.Interface` | `zlchs.Interface.Control` / `zlchs.Common.Base` / `zlchs.Insure.Interface`  |
| **总控DLL名**        | `CICT.Interface.Control.dll`                                                | `zlchs.Interface.Control.dll`                                                   |
| **登录信息解析**     | 所有业务类型都解析 token                                                      | CA 业务 (8xxx)**跳过** token 解析                                           |
| **业务类型数**       | 45 个                                                                         | 53 个（新增 8 个 CA 签名类型 8001-8008）                                          |
| **新增模块**         | 无                                                                            | CA 客户端签名模块（`CAInterfaceBusiness` + `I_CAInterface`）                  |
| **新增编排方法**     | 无                                                                            | `ClincPreSettleSingle()` / `ClincSettleSingle()` / `HospitalSettleSingle()` |
| **Business.cs 行数** | 2455                                                                          | 2972 (+517 行)                                                                    |
| **动态加载**         | 直接设置工作目录                                                              | 增加 `!path.Contains(folder)` 路径重复检查                                      |
| **CA反射机制**       | 无                                                                            | 独立反射：前缀 `CA_`，目录 `Plugins.CAInterface`，使用字典缓存                |
| **医保接口方法**     | 完全相同                                                                      | 完全相同（54 个方法）                                                             |

---

## 一、整体架构概览

```
┌──────────────────────────────────────────┐
│         HIS 客户端 (sdp.cpapi)            │
│  Plugins.WebInsurance 插件                │
│  ProcessRequest("Interface", jsonParams)  │
└──────────────┬───────────────────────────┘
               │ 反射调用
               ▼
┌──────────────────────────────────────────────────────┐
│    CommonTools.ExceInsureMethod()                      │
│    ★ Assembly.Load("zlchs.Interface.Control")          │
│    → zlchs.Interface.Control.Common.Interface(strJson) │
└──────────────┬───────────────────────────────────────┘
               │ switch(business_type)
               ▼
┌──────────────────────────────────────────────────────┐
│    医保总控 (zlchs.Interface.Control)                  │
│    ├─ 1xxx/2xxx: Business → InsureBusiness (医保)      │
│    └─ 8xxx: Business → CAInterfaceBusiness (CA签名) ★  │
└──────────────┬───────────────────────────────────────┘
               │ InsureBusiness._objectReflection(ins_id)
               │ 查库 → 动态加载 DLL
               ▼
┌──────────────────────────────────────────┐
│    具体医保实现 (Cls_Webhis 等)            │
│    实现 IInsureInterface 接口              │
│    操作数据库 + 调用外部医保API             │
└──────────────────────────────────────────┘
```

系统采用 **三层插件化架构**：

1. **HIS 客户端层** — 通过 CPAPI 插件机制发起医保调用
2. **医保总控层** — 路由分发 + 业务编排 + 动态插件加载 + ★ CA 签名
3. **医保接口层** — 各地区医保的具体实现（20+ 实现）

### HIS5.0 双插件体系 ★

```
                zlchs.Interface.Control
                   ┌─────┴─────┐
                   │           │
         InsureBusiness    CAInterfaceBusiness ★ 新增
         (医保路由代理)    (CA签名路由代理)
              │                  │
    前缀: "Cls_"          前缀: "CA_"
    目录: Plugins.WebInsurance   目录: Plugins.CAInterface
    接口: IInsureInterface       接口: I_CAInterface
              │                  │
    ┌─────────┴────┐     ┌──────┴──────┐
    │ 测试实现 DLL  │     │ CA签名 DLL   │
    │ 北京医保 DLL  │     └─────────────┘
    │ 广东医保 DLL  │
    │ ...          │
    └──────────────┘
```

---

## 二、第一层：HIS 客户端发起调用

### 2.1 插件入口 — WebInsurance.ProcessRequest()

> 文件: `code/sdp.cpapi/Plugins.WebInsurance/WebInsurance.cs:34`

HIS 前端通过 CPAPI 插件框架，以 `action="Interface"` 调用 WebInsurance 插件：

```csharp
public override PluginResult ProcessRequest(string action, string jsonParams)
{
    PluginResult pluginResult = new PluginResult();
    try
    {
        // 1. 验证 action 是否合法（枚举中只有 Interface）
        if (!Enum.IsDefined(typeof(WebInsuranceEnum), action))
        {
            pluginResult.Error = "action未定义，请联系管理员";
            pluginResult.State = System.Net.HttpStatusCode.PreconditionFailed;
            return pluginResult;
        }

        // 2. 反射查找 WebInsuranceHelper 类并调用同名方法
        Assembly assembly = Assembly.GetExecutingAssembly();
        Type[] types = assembly.GetTypes();
        Type type = types.Where(x => x.Name == "WebInsuranceHelper").FirstOrDefault();

        MethodInfo methodInfo = type.GetMethod(action);     // 获取 Interface 方法
        object objInvoke = Activator.CreateInstance(type);   // 创建 Helper 实例
        object[] objArr = null;
        if (methodInfo.GetParameters().Length > 0)
            objArr = new object[] { jsonParams };            // 传入完整业务参数 JSON

        pluginResult = methodInfo.Invoke(objInvoke, objArr) as PluginResult;
    }
    catch (Exception ex)
    {
        pluginResult.Error = "反射异常，请查看运维日志";
        Log($"反射异常,入参{jsonParams}", ex);
    }
    return pluginResult;
}
```

**要点**：WebInsurance 只是一个薄壳，通过反射将请求转发给 `WebInsuranceHelper`。

---

### 2.2 业务助手 — WebInsuranceHelper.Interface()

> 文件: `code/sdp.cpapi/Plugins.WebInsurance/WebInsuranceHelper.cs:19`

```csharp
public PluginResult Interface(string strJson)
{
    return CommonTools.CallBusinessControl(
        InsureanceType.PluginsWebInsurance,  // 医保结算类型
        ControlEnum.InsureControl,           // 调用总控 Interface 方法
        strJson                              // 原始业务参数 JSON 直传
    );
}
```

**一行代码，职责清晰**：将调用委托给 `CommonTools`，指定使用"医保结算"类型调用"总控入口"方法。

---

### 2.3 反射加载总控 — CommonTools.CallBusinessControl()

> 文件: `code/sdp.cpapi/ZLSoft.CHSS.CPAPI.CommonBase/CommonTools.cs:31`

```csharp
public static PluginResult CallBusinessControl(
    InsureanceType type, ControlEnum control, string strJson)
{
    PluginResult result = new PluginResult();
    try
    {
        LogTools.Info($"调用业务总控方法前，入参{strJson}", true);   // ← 日志追踪点1

        string res = string.Empty;
        if (control == ControlEnum.InsureControl)
        {
            res = ExceInsureMethod(type, "Interface", strJson);     // ← 核心：反射调用总控
        }
        else if (control == ControlEnum.InsureTools)
        {
            res = ExceInsureMethod(type, "InsureTools", strJson);
        }

        LogTools.Info($"调用业务总控方法后，出参{res}", true);       // ← 日志追踪点2

        // 解析返回值，验证 code 字段
        JObject @object = JObject.Parse(res);
        string code = @object["code"].ToString();
        if (!code.Equals("1"))
        {
            result.State = code.Equals("9")
                ? HttpStatusCode.RequestTimeout       // code=9 → 超时
                : HttpStatusCode.PreconditionFailed;  // 其他 → 业务失败
            result.Error = @object["message"].ToString();
            return result;
        }
        result.Value = @object["data"].ToString();    // 提取 data 字段返回 HIS
    }
    catch (Exception ex) { /* 异常处理 */ }
    return result;
}
```

---

### 2.4 反射执行总控方法 — CommonTools.ExceInsureMethod()

> 文件: `code/sdp.cpapi/ZLSoft.CHSS.CPAPI.CommonBase/CommonTools.cs:216`

```csharp
public static string ExceInsureMethod(string type, string methodName, string param)
{
    // 1. 确定总控 DLL 路径（优先级：总控文件夹 > 插件文件夹 > 根目录）
    var baseDir = AppDomain.CurrentDomain.BaseDirectory;
    var assibmliePath = Path.Combine(baseDir, "zlchs.Interface.Control.dll");

    // 检查插件目录是否存在总控 DLL
    var insureDirctory = Path.Combine(baseDir, type);  // "Plugins.WebInsurance"
    if (File.Exists(Path.Combine(insureDirctory, "zlchs.Interface.Control.dll")))
        assibmliePath = Path.Combine(insureDirctory, "zlchs.Interface.Control.dll");

    // 检查总控文件夹
    insureDirctory = Path.Combine(baseDir, Path.GetFileNameWithoutExtension(BaseTools.BUSINESSCONTROL));
    if (File.Exists(Path.Combine(insureDirctory, "zlchs.Interface.Control.dll")))
        assibmliePath = Path.Combine(insureDirctory, "zlchs.Interface.Control.dll");

    LogTools.Info($"当前调用医保总控DLL路径为：{assibmliePath}");    // ← 日志追踪点3

    // 2. ★ HIS5.0: 加载 zlchs.Interface.Control（非 CICT）
    Assembly assembly1 = Assembly.Load("zlchs.Interface.Control");
    Type type1 = assembly1.GetType("zlchs.Interface.Control.Common");
    MethodInfo method = type1.GetMethod(methodName);               // "Interface"
    object activator = Activator.CreateInstance(type1);
    Object[] parametors = new Object[] { param };
    return (string)method.Invoke(activator, parametors);           // → 进入总控
}
```

**关键**：通过 `Assembly.Load` 加载 `zlchs.Interface.Control.dll`，反射调用 `Common.Interface()` 方法。

---

### 2.5 第一层调用链路小结

```
HIS 前端请求
  │  {business_type: "1106", ins_id: "001", pt_id: "xxx", ...}
  ▼
WebInsurance.ProcessRequest("Interface", jsonParams)
  │  反射 → WebInsuranceHelper.Interface(jsonParams)
  ▼
CommonTools.CallBusinessControl(PluginsWebInsurance, InsureControl, jsonParams)
  │  ExceInsureMethod() → Assembly.Load("zlchs.Interface.Control")  ★ HIS5.0
  │  反射调用 zlchs.Interface.Control.Common.Interface(jsonParams)
  ▼
────────── 进入第二层：医保总控 ──────────
```

---

## 三、第二层：医保总控路由与业务编排

### 3.1 总控入口 — Common.Interface()

> 文件: `zlsoft.cpapi.insure/zlchs.Interface.Control/Common.cs:18`

```csharp
public string Interface(string StrJObject)
{
    LogHelper log = new LogHelper();
    log.ProjectName = "内部处理日志";
    log.WriteLog("调用总控,入参:" + StrJObject);

    JObject DataIn = JObject.Parse(StrJObject);
    string businesstype = DataIn.Value<string>("business_type");

    // ★ HIS5.0 变化: CA 业务 (8xxx) 跳过 token 登录信息解析
    try
    {
        if (!businesstype.StartsWith("8"))                          // ← 新增条件
        {
            LoginUserInfo loginUserInfo = BaseTools.GetLoginUserInfo(DataIn.ToString());
            if (loginUserInfo != null)
            {
                DataIn.Remove("org_id");       DataIn.Add("org_id", loginUserInfo.org_id);
                DataIn.Remove("operator_id");  DataIn.Add("operator_id", loginUserInfo.id);
                DataIn.Remove("operator_name");DataIn.Add("operator_name", loginUserInfo.name);
                DataIn.Remove("dept_id");      DataIn.Add("dept_id", loginUserInfo.dept_id);
            }
        }
    }
    catch(Exception ex)
    {
        log.WriteLog("根据token获取登录信息失败!" + ex.Message + ex.StackTrace);
    }

    // ② 根据 business_type 路由到 Business 类的具体方法
    Business business = new Business();
    string result = "";
    switch (businesstype)
    {
        // ─── 门诊 ───
        case "1101": result = business.ClincChoseInsure(DataIn);    break; // 门诊选择保险
        case "1102": result = business.ClincCancelInsure(DataIn);   break; // 门诊取消保险
        case "1103": result = business.ClincInsureItemCheck(DataIn);break; // 门诊医保项目打标
        case "1104": result = business.ClincDetailCancel(DataIn);   break; // 门诊费用明细上传
        case "1105": result = business.ClincDetailCancel(DataIn);   break; // 门诊费用明细撤销
        case "1106": result = business.ClincSettle(DataIn);         break; // 门诊结算 ★
        case "1107": result = business.ClincSettleBack(DataIn);     break; // 门诊取消结算
        case "1190": result = business.Advance_function(DataIn);    break; // 自费转共济支付
        case "1191": result = business.Advance_function(DataIn);    break; // 共济支付作废
        case "1109": result = business.Advance_function(DataIn);    break; // 医生站绑保险

        // ─── 住院 ───
        case "1201": result = business.HospitalChoseInsure(DataIn);   break; // 住院选择保险
        case "1202": result = business.HospitalIn(DataIn);            break; // 入院登记
        case "1203": result = business.HospitalSupplement(DataIn);    break; // 住院补登记
        case "1204": result = business.HospitalCancelInsure(DataIn);  break; // 住院取消保险
        case "1205": result = business.HospitalInfoChange(DataIn);    break; // 住院信息变更
        case "1206": result = business.HospitalInsureItemCheck(DataIn);break;// 住院医保项目打标
        case "1207": result = business.HospitalDetailUpload(DataIn);  break; // 住院费用明细上传
        case "1208": result = business.HospitalDetailCancel(DataIn);  break; // 住院费用明细撤销
        case "1209": result = business.HospitalOut(DataIn);           break; // 出院登记
        case "1210": result = business.HospitalOutCancel(DataIn);     break; // 撤销出院
        case "1211": result = business.HospitalSettle(DataIn);        break; // 住院结算 ★
        case "1212": result = business.HospitalSettleBack(DataIn);    break; // 住院取消结算
        case "1213": result = business.HospitalModiDisease(DataIn);   break; // 住院更新病种
        case "1219": result = business.HospitalPreSettle(DataIn);     break; // 住院预结算
        case "1292": result = business.Advance_function(DataIn);      break; // 住院自费转共济
        case "1293": result = business.Advance_function(DataIn);      break; // 住院共济作废

        // ─── 拓展 ───
        case "1901": case "1902":
            result = business.Advance_function(DataIn); break;
        case "1909": result = business.Advance_function(DataIn); break; // 家床批量预结算
        case "1001": result = business.Advance_function(DataIn); break; // 医保卡读卡
        case "1291": result = business.Advance_function(DataIn); break; // 费用拆分
        case "1910": result = business.Advance_function(DataIn); break; // 作废预结算
        case "1920": result = business.Advance_function(DataIn); break; // 追溯码上传
        case "1921": result = business.Advance_function(DataIn); break; // 追溯码删除

        // ─── 电子健康卡 ───
        case "2001": result = business.HealthCard(DataIn); break;

        // ─── 电子票据 ───
        case "3001": result = business.ElectronicInvoice(DataIn);     break;
        case "3002": result = business.ElectronicInvoiceBack(DataIn); break;
        case "3003": result = business.ElectronicPrint(DataIn);       break;

        // ─── 身份证读卡器 ───
        case "4001": result = business.ReadIDCard(DataIn); break;

        // ─── 语音报价器 ───
        case "5001": result = business.InvoiceTips(DataIn);        break;
        case "5002": result = business.InvoiceTipsSetting(DataIn); break;

        // ─── POS机支付 ───
        case "6001": result = business.GetBalanceAccunt(DataIn); break;
        case "6002": result = business.PaySettle(DataIn);        break;
        case "6003": result = business.PaySettleBack(DataIn);    break;
        case "6004": result = business.CheckPayment(DataIn);     break;

        // ─── 仪器接口 ───
        case "7001": result = business.PhysicalExaminationsend(DataIn);    break;
        case "7002": result = business.PhysicalExaminationreceive(DataIn); break;
        case "7010": result = business.LisConnect(DataIn);  break;
        case "7011": result = business.LisAnalysis(DataIn); break;

        // ─── ★ HIS5.0 新增: 客户端CA签名 ───
        case "8001": result = business.QrCode(DataIn.ToString());        break; // 获取登录二维码
        case "8002": result = business.LoginUserInfo(DataIn.ToString()); break; // 获取U盾信息
        case "8003": result = business.synDoctor(DataIn.ToString());     break; // 同步人员信息
        case "8004": result = business.SendSginData(DataIn.ToString());  break; // 执行签名
        case "8005": result = business.GetSginResult(DataIn.ToString()); break; // 获取签名结果
        case "8006": result = business.DownloadSginData(DataIn.ToString()); break; // 下载签名原文
        case "8007": result = business.GetSginResult(DataIn.ToString()); break; // 签名结果(批量)
        case "8008": result = business.CASignConfim(DataIn.ToString());  break; // 签名确认

        default:
            result = JsonConvert.SerializeObject(new Response { code = "0", message = "未识别的业务类型!" });
            break;
    }

    log.WriteLog("调用总控,出参:" + result);
    return result;
}
```

**职责**：解析 `business_type` → 注入登录信息(非CA) → switch 路由到 Business 的具体方法。

---

### 3.2 业务编排 — Business.ClincChoseInsure() (门诊选择保险)

> 文件: `zlsoft.cpapi.insure/zlchs.Interface.Control/Business.cs:28`

```csharp
public string ClincChoseInsure(JObject data)
{
    string orgid = data.Value<string>("org_id");

    // ① 弹出医保选择对话框，用户选择医保类型
    Frm医保选择 frm = new Frm医保选择(orgid, data.ToString());
    frm.ShowDialog();
    if (string.IsNullOrEmpty(frm.InsureSystem))
        return 错误响应("选择医保返回空!");

    // ② 将选择结果（ins_id）写入请求数据
    if (data.Property("ins_id") != null)
        data.Remove("ins_id");
    data.Add("ins_id", frm.InsureSystem);

    // ③ 初始化医保接口
    InsureBusiness insure = new InsureBusiness();
    bool b = insure.InitInsure(data.ToString());
    //    └→ InsureBusiness._objectReflection() → 查库 → 动态加载 DLL
    //    └→ IInsureInterface.InitInsure() → 具体实现初始化

    if (!b) return 错误响应("初始化失败!");

    // ④ 身份验证
    string identify = insure.Identify(data.ToString());
    JObject identify_out = JObject.Parse(identify);
    if (identify_out.Value<string>("code") != "1")
        return 错误响应("身份验证失败!");

    // ⑤ 从身份验证结果中提取 pt_id，回写到请求数据
    if (data.Property("pt_id") != null)
        data.Remove("pt_id");
    data.Add("pt_id", identify_out.Value<JObject>("data").Value<string>("pt_id"));

    // ⑥ 获取账户余额
    string balance = insure.SelfBalance(data.ToString());
    JObject balance_out = JObject.Parse(balance);
    if (balance_out.Value<string>("code") != "1")
        return 错误响应("获取账户余额失败!");

    // ⑦ 组织返回值
    JObject out_data = identify_out.Value<JObject>("data");
    out_data.Add("personal_account", balance_out.Value<JObject>("data").Value<string>("personal_account"));
    out_data.Add("personal_sum", balance_out.Value<JObject>("data").Value<string>("personal_sum"));
    out_data.Add("name", frm.ins_name);
    out_data.Add("ins_code", frm.ins_code);
    return JsonConvert.SerializeObject(new Response { code = "1", data = out_data });
}
```

**编排流程**: 选保险 → 初始化 → 身份验证 → 查余额 → 返回

---

### 3.3 业务编排 — Business.ClincSettle() (门诊结算)

> 文件: `zlsoft.cpapi.insure/zlchs.Interface.Control/Business.cs:293`

```csharp
public string ClincSettle(JObject data)
{
    // ① 初始化
    InsureBusiness insure = new InsureBusiness();
    bool b = insure.InitInsure(data.ToString());
    if (!b) return 错误响应("初始化失败!");

    // ② 预结算（如果不是费用拆分模式）
    JObject presettle_out = new JObject();
    string is_split = data.Value<string>("is_split");
    if (is_split != "1")
    {
        string presettle = insure.ClinicPreSwap(data.ToString());
        presettle_out = JObject.Parse(presettle);
        if (presettle_out.Value<string>("code") != "1")
            return 错误响应("预结算失败: " + presettle_out.Value<string>("message"));
    }

    // ③ 正式结算（如果预结算不需要拆分）
    JObject settle_out = new JObject();
    JObject presettle_out_data = presettle_out.Value<JObject>("data");
    if (presettle_out_data != null && presettle_out_data.Value<string>("is_split") == "1")
        settle_out = presettle_out;  // 拆分模式：预结算结果即为最终结果
    else
    {
        string settle = insure.ClinicSwap(data.ToString());
        settle_out = JObject.Parse(settle);
        if (settle_out.Value<string>("code") != "1")
            return 错误响应("结算失败: " + settle_out.Value<string>("message"));
    }

    // ④ 获取账户余额（失败则自动回滚结算）
    string balance = insure.SelfBalance(data.ToString());
    JObject balance_out = JObject.Parse(balance);
    if (balance_out.Value<string>("code") != "1")
    {
        // ★ 余额查询失败 → 自动撤销结算（事务回滚）
        string delswap = insure.ClinicDelSwap(data.ToString());
        JObject delswap_out = JObject.Parse(delswap);
        if (delswap_out.Value<string>("code") != "1")
            return 错误响应("结算作废失败!");
        return 错误响应("获取账户余额失败!");
    }

    // ⑤ 组织返回值
    JObject out_data = settle_out.Value<JObject>("data");
    out_data.Add("personal_account", balance_out.Value<JObject>("data").Value<string>("personal_account"));
    out_data.Add("personal_sum", balance_out.Value<JObject>("data").Value<string>("personal_sum"));
    return JsonConvert.SerializeObject(new Response { code = "1", data = out_data });
}
```

**编排流程**: 初始化 → 预结算 → 正式结算 → 查余额（失败则回滚）→ 返回

---

### 3.4 ★ HIS5.0 新增 — Business.ClincPreSettleSingle() (门诊单步预结算)

> 文件: `zlsoft.cpapi.insure/zlchs.Interface.Control/Business.cs:516`

HIS5.1 中预结算和结算在 `ClincSettle()` 内编排执行。HIS5.0 新增了单步方法，允许前端分步调用。

```csharp
public string ClincPreSettleSingle(JObject data)
{
    // ① 初始化
    InsureBusiness insure = new InsureBusiness();
    bool b = insure.InitInsure(data.ToString());
    if (!b) return 错误响应("初始化失败!");

    // ② 仅执行预结算（不执行正式结算）
    string presettle = insure.ClinicPreSwap(data.ToString());
    JObject presettle_out = JObject.Parse(presettle);
    if (presettle_out.Value<string>("code") != "1")
        return 错误响应("预结算失败!");

    // ③ 获取余额
    string balance = insure.SelfBalance(data.ToString());
    JObject balance_out = JObject.Parse(balance);

    // ④ 返回预结算结果
    JObject out_data = presettle_out.Value<JObject>("data");
    out_data.Add("personal_account", balance_out.Value<JObject>("data").Value<string>("personal_account"));
    out_data.Add("personal_sum", balance_out.Value<JObject>("data").Value<string>("personal_sum"));
    return JsonConvert.SerializeObject(new Response { code = "1", data = out_data });
}
```

---

### 3.5 路由代理 — InsureBusiness._objectReflection()

> 文件: `zlsoft.cpapi.insure/zlchs.Insure.Interface/InsureBusiness.cs:35`

```csharp
public class InsureBusiness
{
    public static IInsureInterface Iinterface;
    public static object obj = null;
    public static Dictionary<String, object> dic = new Dictionary<string, object>();

    /// <summary>
    /// 核心：根据 ins_id 动态反射加载医保 DLL
    /// </summary>
    public static void _objectReflection(string insureSystem, string DataIn)
    {
        // ① 查库获取 DLL 名称
        //    SQL: SELECT name AS 名称, interface_name AS 医保部件
        //         FROM insur.ins_system WHERE id = @insureSystem
        DataTable dt = BaseDataHelper.GetInterfaceList(insureSystem, DataIn);

        if (dt == null || dt.Rows.Count < 1)
        {
            // 查询失败 → 回退到测试实现
            obj = ObjectReflection.CreateObject("zlchs.TEST.Insure", "Cls_", "Plugins.WebInsurance");
            Iinterface = obj as IInsureInterface;
            return;
        }

        // ② 动态加载指定 DLL
        //    dt.Rows[0]["医保部件"] 如 "zlchs.Webhis.Test.Insure"
        obj = ObjectReflection.CreateObject(
            dt.Rows[0]["医保部件"].ToString(),  // DLL 程序集名称
            "Cls_",                            // 类名前缀匹配
            "Plugins.WebInsurance"             // DLL 所在文件夹
        );

        // ③ 转为接口引用
        InsureBusiness.Iinterface = obj as IInsureInterface;
    }
}
```

**每个业务方法的代理模式**（以 ClinicSwap 为例）：

```csharp
public string ClinicSwap(string strJson)
{
    JObject jObjec = JObject.Parse(strJson);
    string insureSystem = jObjec.Value<string>("ins_id");    // 提取 ins_id
    _objectReflection(insureSystem, strJson);                 // 动态加载 DLL
    return Iinterface.ClinicSwap(strJson);                    // 委托给具体实现
}
```

---

### 3.6 ★ HIS5.0 新增 — CAInterfaceBusiness (CA签名路由代理)

> 文件: `zlsoft.cpapi.insure/zlchs.Insure.Interface/CAInterfaceBusiness.cs`

```csharp
public class CAInterfaceBusiness
{
    public static I_CAInterface Iinterface;
    public static object obj = null;
    public static Dictionary<String, object> dic = new Dictionary<string, object>();

    // ★ CA 反射：与医保反射不同，使用字典缓存实例
    public static void _objectReflection(string systemName)
    {
        if (dic.ContainsKey(systemName) == false)
        {
            // 前缀 "CA_"（医保是 "Cls_"），目录 "Plugins.CAInterface"
            obj = ObjectReflection.CreateObject(systemName, "CA_", "Plugins.CAInterface");
            dic.Add(systemName, obj);
        }
        else
        {
            obj = dic[systemName];   // 直接从缓存取
        }
        CAInterfaceBusiness.Iinterface = obj as I_CAInterface;
    }

    // 代理方法（从 JSON 中取 interface_name 作为 DLL 名称）
    public static string QrCode(string StrJosn)
    {
        JObject DataIn = JObject.Parse(StrJosn);
        string interfaceName = DataIn.Value<string>("interface_name");
        _objectReflection(interfaceName);
        return Iinterface.QrCode(StrJosn);
    }

    public static string LoginUserInfo(string StrJosn) { /* 同上模式 */ }
    public static string synDoctor(string StrJosn) { /* 同上模式 */ }
    public static string SendSginData(string StrJosn) { /* 同上模式 */ }
    public static string GetSginResult(string StrJosn) { /* 同上模式 */ }
    public static string DownloadSginData(string StrJosn) { /* 同上模式 */ }
}
```

**与医保路由代理的对比**：

| 方面     | InsureBusiness (医保)         | CAInterfaceBusiness (CA)             |
| -------- | ----------------------------- | ------------------------------------ |
| 反射前缀 | `"Cls_"`                    | `"CA_"`                            |
| DLL 目录 | `Plugins.WebInsurance`      | `Plugins.CAInterface`              |
| 接口     | `IInsureInterface`          | `I_CAInterface`                    |
| 路由字段 | `ins_id` → 查库获取 DLL 名 | `interface_name` → 直接从 JSON 取 |
| 实例缓存 | 无缓存（每次重新加载）        | 字典缓存（首次加载后复用）           |

---

### 3.7 ★ HIS5.0 新增 — I_CAInterface 接口

> 文件: `zlsoft.cpapi.insure/zlchs.Insure.Interface/I_CAInterface.cs`

```csharp
public interface I_CAInterface
{
    string QrCode(string StrJosn);           // 获取 CA 登录二维码
    string LoginUserInfo(string StrJosn);    // 获取登录用户信息（U盾信息）
    string synDoctor(string StrJosn);        // 同步人员信息到 CA 系统
    string SendSginData(string StrJosn);     // 执行签名
    string GetSginResult(string StrJosn);    // 获取签名结果
    string DownloadSginData(string StrJosn); // 下载签名记录原文
}
```

---

### 3.8 动态加载引擎 — ObjectReflection.CreateObject()

> 文件: `zlsoft.cpapi.insure/zlchs.Common.Base/ObjectReflection.cs:19`

```csharp
public static object CreateObject(string typeInfo, string ProjType, string folder)
{
    // typeInfo  = "zlchs.Webhis.Test.Insure" (程序集名)
    // ProjType  = "Cls_"                      (类名前缀)
    // folder    = "Plugins.WebInsurance"       (文件夹)

    Type objType = LoadSmartPartType(typeInfo, ProjType, folder);
    if (objType != null)
        return Activator.CreateInstance(objType);
    return null;
}

public static Type LoadSmartPartType(string asseblyName, string ProjType, string folder)
{
    string path = Application.StartupPath;

    // ★ HIS5.0 变化: 增加路径重复检查，避免重复设置工作目录
    if (!path.Contains(folder))                                     // ← 新增
    {
        string patha = Path.Combine(path + "/" + folder, asseblyName + ".dll");
        if (File.Exists(patha))
            path = Path.Combine(path, folder);
        Directory.SetCurrentDirectory(path);
    }

    // 加载程序集
    targetAssembly = Assembly.LoadFrom(Path.Combine(path, asseblyName + ".dll"));
    //   如: Plugins.WebInsurance/zlchs.Webhis.Test.Insure.dll

    // 遍历类型，匹配前缀（"Cls_" 或 "CA_"）
    foreach (Type clsName in targetAssembly.GetTypes())
    {
        if (clsName.Name.IndexOf(ProjType) != -1)
        {
            _className = asseblyName + "." + clsName.Name;
            //   如: "zlchs.Webhis.Test.Insure.Cls_Webhis"
            break;
        }
    }

    type = targetAssembly.GetType(_className);
    return type;
}
```

**加载链**: DLL 文件名（从数据库查出）→ `Assembly.LoadFrom` → 扫描 `Cls_` 前缀类 → `Activator.CreateInstance`

---

### 3.9 IInsureInterface 接口契约

> 文件: `zlsoft.cpapi.insure/zlchs.Insure.Interface/IInsureInterface.cs`

所有医保实现必须实现此接口（30+ 方法），与 HIS5.1 完全相同：

| 类别               | 方法                                      | 用途               |
| ------------------ | ----------------------------------------- | ------------------ |
| **生命周期** | `InitInsure(strJson) → bool`           | 初始化医保接口     |
|                    | `EndInsure(strJson) → bool`            | 销毁医保接口       |
| **认证**     | `SignIn / SignOut`                      | 签到/签退          |
|                    | `Identify(strJson)`                     | 身份验证           |
|                    | `IdentifyCancel(strJson)`               | 取消身份验证       |
| **账户**     | `SelfBalance(strJson)`                  | 获取个人账户余额   |
| **门诊**     | `ClinicPreSwap(strJson)`                | 门诊预结算         |
|                    | `ClinicSwap(strJson)`                   | 门诊正式结算       |
|                    | `ClinicDelSwap(strJson)`                | 门诊结算作废       |
| **住院**     | `ComeInSwap / ComeInDelSwap`            | 入院登记/撤销      |
|                    | `ModiPatiSwap`                          | 住院信息修改       |
|                    | `LeaveSwap / LeaveDelSwap`              | 出院登记/撤销      |
|                    | `WipeoffMoney`                          | 住院预结算         |
|                    | `SettleSwap / SettleDelSwap`            | 住院结算/撤销      |
| **费用**     | `ItemMarking`                           | 医保项目打标       |
|                    | `DetailUpload / DetailUploadDel`        | 费用明细上传/撤销  |
| **目录**     | `CatalogDownload / CatalogUpload`       | 目录下载/上传      |
|                    | `DiagnosisDownload`                     | 疾病目录下载       |
|                    | `DoctorDownload / DoctorUpload`         | 医护人员同步       |
|                    | `DepartmentDownload / DepartmentUpload` | 科室对照           |
| **病历**     | `MedRecordUpload / MedRecordUploadDel`  | 病案首页           |
|                    | `CaseUpload / CaseUploadDel`            | 病历信息           |
| **对账**     | `InsureCheck`                           | 日/月对账          |
| **扩展**     | `Advance_function`                      | 共济支付等扩展功能 |
|                    | `InterfaceTools`                        | 补充工具           |

---

## 四、第三层：zlchs.Webhis.Test.Insure 具体实现

### 4.1 项目信息

- **路径**: `医保接口/zlchs.Webhis.Test.Insure/`
- **主类**: `Cls_Webhis : IInsureInterface`
- **文件**: `Cls_Webhis.cs`（1538 行）
- **定位**: 测试/WebHis 通用实现，不对接真实医保中心

---

### 4.2 InitInsure() — 初始化 (行111)

```csharp
public bool InitInsure(string strJson)
{
    log.ProjectName = "内部处理日志";
    JObject DataIn = JObject.Parse(strJson);

    string org_id = DataIn.Value<string>("org_id");
    string ins_id = DataIn.Value<string>("ins_id");

    // 查询医保机构编码
    string sql = @"select ins_code from insur.ins_org_vs a
                where a.ins_id = @insure and org_id = @orgid";
    Param[] param = new Param[2]
    {
        new Param { pname= "orgid", dbtype=16, value=org_id  },
        new Param { pname= "insure", dbtype=12, value=ins_id }
    };
    DataTable dt = BaseDataHelper.GetDataTable(strJson, "InitInsure", "fee", sql, param);
    if (dt != null && dt.Rows.Count > 0)
    {
        Org_code = dt.Rows[0]["ins_code"].ToString();  // 保存机构在医保系统中的编码
    }
    return true;
}
```

**数据库**: `insur.ins_org_vs` — 机构与医保系统的对照关系表

---

### 4.3 Identify() — 身份验证 (行267)

```csharp
public string Identify(string strJson)
{
    JObject model = JObject.Parse(strJson);
    string ins_id = model.Value<string>("ins_id");
    string org_id = model.Value<string>("org_id");
    string operator_id = model.Value<string>("operator_id");
    string operator_name = model.Value<string>("operator_name");

    // 弹出身份验证对话框（WinForm）
    Frm身份验证 frm = new Frm身份验证(ins_id, org_id,
        operator_id + "|" + operator_name, "", strJson);
    frm.ShowDialog();

    if (!string.IsNullOrEmpty(frm.result))
        return frm.result;    // 返回验证结果 JSON：{code:"1", data:{pt_id, ins_no, name...}}
    else
        return Response(code:"0", message:"医保身份验证返回空!");
}
```

**特点**: 测试实现使用 WinForm 对话框模拟身份验证，不调用外部医保中心。

---

### 4.4 DetailUpload() — 费用明细上传 (行206)

```csharp
public string DetailUpload(string strJson)
{
    JObject model = JObject.Parse(strJson);
    JArray fee_detial_id_list = model.Value<JArray>("fee_detial_id_list");

    for (int i = 0; i < fee_detial_id_list.Count; i++)
    {
        // ① 查询未提交的费用明细
        string sql = @"select * from insur.ins_fee_detail
                 where fee_detail_id = @fees and ins_submit=0";
        DataTable dt = BaseDataHelper.GetDataTable(strJson, "DetailUpload", "fee", sql, ...);

        if (dt != null && dt.Rows.Count > 0)
        {
            // ② 标记为已提交
            sql = "update insur.ins_fee_detail set ins_submit = 1 where fee_detail_id = @fees";
            BaseDataHelper.ExteSql(strJson, "DetailUpload", "fee", sql, ...);
        }
    }
    return Response(code:"1");
}
```

**数据库**: `insur.ins_fee_detail` — `ins_submit` 字段：0=未提交，1=已提交

---

### 4.5 ClinicPreSwap() — 门诊预结算 (行409)

```csharp
public string ClinicPreSwap(string strJson)
{
    JObject model = JObject.Parse(strJson);
    string actual_charge = model.Value<string>("actual_charge");
    string pt_id = model.Value<string>("pt_id");
    string ins_id = model.Value<string>("ins_id");
    string visit_id = model.Value<string>("visit_id");

    // ① 获取保险个人档案数据
    string sql_da = @"select a.* from insur.ins_archive a, insur.ins_archive_vs b
        where a.ins_id = b.ins_id and a.ins_card_no = b.ins_card_no
        and b.pt_id = @patientid and a.ins_id = @insure";
    DataTable dt_da = BaseDataHelper.GetDataTable(strJson, "ClinicPreSwap", "fee", sql_da, ...);

    // ② 构建就诊信息并保存到 insur.ins_visit
    SaveInsureVisit siv = new SaveInsureVisit();
    siv.birthday = DateTime.Parse(dt_da.Rows[0]["birthday"].ToString());
    siv.ins_id = long.Parse(ins_id);
    siv.ins_no = dt_da.Rows[0]["ins_card_no"].ToString();
    siv.name = dt_da.Rows[0]["name"].ToString();
    siv.pt_id = pt_id;
    siv.visit_id = visit_id;
    BaseDataHelper.SaveInsureVisit(siv, strJson);

    // ③ 弹出结算方式配置窗口
    Frm结算方式配置 frm = new Frm结算方式配置(amont, "1");
    frm.ShowDialog();
    settletype = frm.settle_type;

    // ④ 校验结算方式
    BaseDataHelper.CheckBalanceWay(settletype, strJson, org_id);

    // ⑤ 返回预结算结果
    JObject data = new JObject();
    data.Add("defult_settle_type", st);
    data.Add("settle_type", settletype);
    data.Add("is_split", frm.pre_flag);
    return Response(code:"1", data:data);
}
```

**数据库操作**:

- 查询: `insur.ins_archive` + `insur.ins_archive_vs` （关联查询档案）
- 写入: `insur.ins_visit` （保存就诊记录）

---

### 4.6 ClinicSwap() — 门诊正式结算 (行529)

```csharp
public string ClinicSwap(string strJson)
{
    JObject clinc = JObject.Parse(strJson);
    string ins_id = clinc.Value<string>("ins_id");
    string visit_id = clinc.Value<string>("visit_id");
    string balance_id = clinc.Value<string>("balance_id");

    // ① 查询就诊记录
    string sql_jz = "select * from insur.ins_visit where ins_id = @insure and visit_id = @eventid";
    DataTable dt_jz = BaseDataHelper.GetDataTable(strJson, "ClinicSwap", "fee", sql_jz, ...);

    // 如未查到，按 pt_id 倒序查询最近一次
    if (dt_jz == null || dt_jz.Rows.Count < 1)
    {
        sql_jz = "select * from insur.ins_visit where ins_id = @insure and pt_id = @pt_id order by visit_time desc";
        dt_jz = BaseDataHelper.GetDataTable(strJson, "ClinicSwap", "fee", sql_jz, ...);
    }

    // ② 弹出结算方式配置确认
    Frm结算方式配置 frm = new Frm结算方式配置(double.Parse(actual_charge), "0");
    frm.ShowDialog();
    settletype = frm.settle_type;

    // ③ 构建结算信息并保存到 insur.ins_balance
    SaveInsureBalance sib = new SaveInsureBalance();
    sib.balance_id = long.Parse(balance_id);
    sib.ins_id = long.Parse(ins_id);
    sib.ins_no = dt_jz.Rows[0]["ins_card_no"].ToString();
    sib.name = dt_jz.Rows[0]["pt_name"].ToString();
    sib.settle_type = settletype;
    sib.swapinfo = json;
    sib.time = DateTime.Now;
    BaseDataHelper.SaveInsureBalance(sib, strJson);

    // ④ 返回结算结果
    JObject data = new JObject();
    data.Add("settle_type", settletype);
    data.Add("patient_insur_type", "310");
    data.Add("patient_insur_type_name", "职工医保");
    return Response(code:"1", data:data);
}
```

**数据库操作**:

- 查询: `insur.ins_visit` （就诊记录）
- 写入: `insur.ins_balance` （结算记录）+ `insur.ins_balance_info` （结算明细）

---

### 4.7 ClinicDelSwap() — 门诊结算作废 (行652)

```csharp
public string ClinicDelSwap(string strJson)
{
    string balance_id = model.Value<string>("balance_id");
    string refund_id = model.Value<string>("refund_id");

    // ① 查询结算记录
    string sql = "select * from insur.ins_balance where balance_id = @balanceid";
    DataTable dt = BaseDataHelper.GetDataTable(strJson, "ClinicDelSwap", "fee", sql, ...);

    // ② 检查是否有共济结算关联
    string sql1 = @"select pb.id, pb.description from public.pt_balance pb, insur.ins_balance ib
        where pb.id = ib.balance_id and (pb.id = @balanceid or pb.complement_id = @balanceid)";

    // ③ 根据 refund_id 决定撤销方式
    if (string.IsNullOrEmpty(refund_id))
    {
        // 直接删除模式
        "delete from insur.ins_balance_info where balance_id = @balanceid";
        "delete from insur.ins_balance where balance_id = @balanceid";
    }
    else
    {
        // 冲负模式（退费）
        BaseDataHelper.RefondBalance(balance_id, refund_id, org_id, strJson);
        @"insert into insur.ins_balance(balance_id,...) select @tzbalance,...
          from insur.ins_balance where balance_id = @balanceid";
        // 生成负数结算明细
    }
}
```

**撤销策略**: refund_id 为空 → 直接删除 | refund_id 有值 → 生成冲负记录

---

## 五、关键数据模型

### 5.1 SaveInsureVisit — 就诊记录

```csharp
public class SaveInsureVisit
{
    public long ins_id { set; get; }         // 保险系统ID
    public string ins_no { set; get; }       // 保险号
    public string id_card { set; get; }      // 身份证号
    public string org_id { set; get; }       // 机构ID
    public string name { set; get; }         // 患者姓名
    public string sex { set; get; }          // 性别
    public DateTime birthday { set; get; }   // 出生日期
    public string pt_id { set; get; }        // 患者ID
    public string visit_id { set; get; }     // 事件ID
    public string pt_account { set; get; }   // 个人账户余额
    public string exinfo { set; get; }       // 扩展信息 (JSON)
}
```

### 5.2 SaveInsureBalance — 结算记录

```csharp
public class SaveInsureBalance
{
    public long balance_id { get; set; }     // 结算ID
    public long ins_id { get; set; }         // 保险系统ID
    public string org_id { get; set; }       // 机构ID
    public string pt_id { get; set; }        // 患者ID
    public string name { get; set; }         // 患者姓名
    public string id_card { get; set; }      // 身份证号
    public string ins_no { get; set; }       // 保险号
    public string sex { get; set; }          // 性别
    public DateTime time { get; set; }       // 结算时间
    public string swapinfo { get; set; }     // 结算信息 (JSON)
    public object settle_type { get; set; }  // 结算方式 (JArray)
}
```

### 5.3 Response — 统一返回模型

```csharp
public class Response
{
    public string code { set; get; }         // "1"=成功, "0"=失败
    public string message { set; get; }      // 错误描述
    public object data { set; get; }         // 业务数据
}
```

---

## 六、数据库表关系

```
insur.ins_system              ← 医保系统配置（ins_id → interface_name，决定加载哪个 DLL）
  │
insur.ins_org_vs              ← 机构与医保系统的对照关系（org_id + ins_id → ins_code）
  │
insur.ins_archive             ← 参保人员档案（ins_card_no, name, id_card_no, ...）
insur.ins_archive_vs          ← 患者与档案的绑定关系（pt_id + ins_id → ins_card_no）
  │
insur.ins_fee_detail          ← 费用明细提交状态（ins_submit: 0=未提交, 1=已提交）
  │
insur.ins_visit               ← 就诊记录（预结算时创建，rec_type: 1=门诊, 2=住院）
  │
insur.ins_balance             ← 结算记录（正式结算后创建，含 swap_info JSON）
  │
insur.ins_balance_info        ← 结算明细（balance_name + balance_charge）
```

---

## 七、完整流程示例：门诊结算全链路代码走查

以 `business_type = "1106"` (门诊结算) 为例：

```
步骤 1: HIS 前端
         用户点击"医保结算"按钮
         ┌─────────────────────────────────────────────────┐
         │ {                                               │
         │   "business_type": "1106",                      │
         │   "ins_id": "001",                              │
         │   "pt_id": "P001",                              │
         │   "visit_id": "V001",                           │
         │   "balance_id": "B001",                         │
         │   "actual_charge": "100.00",                    │
         │   "token": "xxx"                                │
         │ }                                               │
         └─────────────────────┬───────────────────────────┘
                               │
步骤 2: WebInsurance.ProcessRequest("Interface", jsonParams)
         │ → 反射调用 WebInsuranceHelper.Interface(jsonParams)
         │ → CommonTools.CallBusinessControl(PluginsWebInsurance, InsureControl, jsonParams)
         │ → ExceInsureMethod()
         │ → ★ Assembly.Load("zlchs.Interface.Control")   ← HIS5.0 命名空间
         │ → 反射调用 zlchs.Interface.Control.Common.Interface(jsonParams)
         │                                     │
步骤 3: Common.Interface(strJson)              │
         │ → 解析 business_type = "1106"       │
         │ → ★ 非 "8" 开头 → 从 token 解析登录信息
         │ → switch → Business.ClincSettle(DataIn)
         │                                     │
步骤 4: Business.ClincSettle(data)             │ 业务编排
         │                                     │
         ├─ 4a. insure.InitInsure(data)        │
         │   ├─ InsureBusiness._objectReflection("001")
         │   │   ├─ BaseDataHelper.GetInterfaceList("001")
         │   │   │   → SQL: SELECT interface_name FROM insur.ins_system WHERE id='001'
         │   │   │   → 结果: "zlchs.Webhis.Test.Insure"
         │   │   │
         │   │   ├─ ObjectReflection.CreateObject("zlchs.Webhis.Test.Insure", "Cls_", ...)
         │   │   │   → ★ if (!path.Contains(folder)) 检查后设置目录
         │   │   │   → Assembly.LoadFrom("Plugins.WebInsurance/zlchs.Webhis.Test.Insure.dll")
         │   │   │   → 扫描类型 → 找到 Cls_Webhis
         │   │   │   → Activator.CreateInstance(typeof(Cls_Webhis))
         │   │   │
         │   │   └─ Iinterface = new Cls_Webhis()
         │   │
         │   └─ Cls_Webhis.InitInsure(data)
         │       → SQL: SELECT ins_code FROM insur.ins_org_vs
         │              WHERE ins_id='001' AND org_id='xxx'
         │       → Org_code = "H001"
         │                                     │
         ├─ 4b. insure.ClinicPreSwap(data)     │ 预结算
         │   └─ Cls_Webhis.ClinicPreSwap(data)
         │       → SQL: SELECT * FROM insur.ins_archive a, insur.ins_archive_vs b
         │              WHERE ... AND b.pt_id='P001' AND a.ins_id='001'
         │       → BaseDataHelper.SaveInsureVisit(siv)  → 写入 insur.ins_visit
         │       → 弹出 Frm结算方式配置 → 用户选择结算方式
         │       → 返回: {code:"1", data:{settle_type:[...], is_split:"0"}}
         │                                     │
         ├─ 4c. insure.ClinicSwap(data)        │ 正式结算
         │   └─ Cls_Webhis.ClinicSwap(data)
         │       → SQL: SELECT * FROM insur.ins_visit
         │              WHERE ins_id='001' AND visit_id='V001'
         │       → 弹出 Frm结算方式配置 → 确认结算
         │       → BaseDataHelper.SaveInsureBalance(sib)  → 写入 insur.ins_balance
         │       → 返回: {code:"1", data:{settle_type:[...], patient_insur_type:"310"}}
         │                                     │
         ├─ 4d. insure.SelfBalance(data)       │ 查余额
         │   └─ 返回: {code:"1", data:{personal_account:"500.00"}}
         │                                     │
         └─ 4e. 组织最终返回值
             → {code:"1", data:{settle_type, patient_insur_type, personal_account, ...}}
                               │
步骤 5: 结果逐层返回
         Cls_Webhis → InsureBusiness → Business → Common → CommonTools → WebInsurance → HIS
                               │
步骤 6: HIS 前端
         → CommonTools 解析 code="1"，提取 data 字段
         → PluginResult.Value = data
         → 前端显示"结算完成"
```

---

## 八、设计模式总结

| 模式                      | 位置                                            | 作用                                       |
| ------------------------- | ----------------------------------------------- | ------------------------------------------ |
| **Facade**          | `Common.Interface()`                          | 对外统一入口，屏蔽内部复杂性               |
| **Strategy**        | `IInsureInterface` / `I_CAInterface` ★     | 各地医保可互换；CA 实现可互换              |
| **Factory**         | `ObjectReflection.CreateObject()`             | 根据配置动态创建实例                       |
| **Proxy**           | `InsureBusiness` / `CAInterfaceBusiness` ★ | 自动处理 DLL 加载，对上层透明              |
| **Template Method** | `Business.ClincSettle()`                      | 编排固定步骤：初始化→预结算→结算→查余额 |

---

## 九、关键文件索引

| 层级                  | 文件路径                                                              | 核心类/方法                         |
| --------------------- | --------------------------------------------------------------------- | ----------------------------------- |
| HIS 客户端            | `sdp.cpapi/Plugins.WebInsurance/WebInsurance.cs:34`                 | `ProcessRequest()`                |
| HIS 客户端            | `sdp.cpapi/Plugins.WebInsurance/WebInsuranceHelper.cs:19`           | `Interface()`                     |
| HIS 客户端            | `sdp.cpapi/ZLSoft.CHSS.CPAPI.CommonBase/CommonTools.cs:31`          | `CallBusinessControl()`           |
| HIS 客户端            | `sdp.cpapi/ZLSoft.CHSS.CPAPI.CommonBase/CommonTools.cs:216`         | `ExceInsureMethod()`              |
| **总控入口**    | `zlsoft.cpapi.insure/zlchs.Interface.Control/Common.cs:18`          | `Interface()` 53 个 switch 分支   |
| **总控业务**    | `zlsoft.cpapi.insure/zlchs.Interface.Control/Business.cs:28`        | `ClincChoseInsure()` 等 + CA 方法 |
| **总控业务**    | `zlsoft.cpapi.insure/zlchs.Interface.Control/Business.cs:293`       | `ClincSettle()`                   |
| **总控业务** ★ | `zlsoft.cpapi.insure/zlchs.Interface.Control/Business.cs:516`       | `ClincPreSettleSingle()` 新增     |
| **总控路由**    | `zlsoft.cpapi.insure/zlchs.Insure.Interface/InsureBusiness.cs:35`   | `_objectReflection()`             |
| **CA路由** ★   | `zlsoft.cpapi.insure/zlchs.Insure.Interface/CAInterfaceBusiness.cs` | CA 签名路由代理                     |
| **接口契约**    | `zlsoft.cpapi.insure/zlchs.Insure.Interface/IInsureInterface.cs`    | 30+ 接口方法                        |
| **CA接口** ★   | `zlsoft.cpapi.insure/zlchs.Insure.Interface/I_CAInterface.cs`       | 6 个 CA 方法                        |
| **动态加载**    | `zlsoft.cpapi.insure/zlchs.Common.Base/ObjectReflection.cs:19`      | `CreateObject()` 含路径检查       |
| **数据访问**    | `zlsoft.cpapi.insure/zlchs.Common.Base/BaseDataHelper.cs`           | `GetDataTable()`, `ExteSql()`   |
| 测试实现              | `医保接口/zlchs.Webhis.Test.Insure/Cls_Webhis.cs:111`               | `InitInsure()`                    |
| 测试实现              | `医保接口/zlchs.Webhis.Test.Insure/Cls_Webhis.cs:267`               | `Identify()`                      |
| 测试实现              | `医保接口/zlchs.Webhis.Test.Insure/Cls_Webhis.cs:409`               | `ClinicPreSwap()`                 |
| 测试实现              | `医保接口/zlchs.Webhis.Test.Insure/Cls_Webhis.cs:529`               | `ClinicSwap()`                    |
| 测试实现              | `医保接口/zlchs.Webhis.Test.Insure/Cls_Webhis.cs:652`               | `ClinicDelSwap()`                 |
| 返回模型              | `医保接口/zlchs.Webhis.Test.Insure/Models/Response.cs`              | `Response{code,message,data}`     |
