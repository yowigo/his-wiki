# HIS5.0 → 医保总控 → 北京医保中心：完整代码走查

> 基于 HIS5.0 新总控 `zlsoft.cpapi.insure` + 北京医保 `zlchs.BJ.XBYB.insure`，逐层展示完整调用链路。
> 与医保中心的**真实数据交互**位置用 `🔗 医保中心交互` 标记。
>
> **总控代码位置**: `D:\work\his-medical-group\zlsoft.cpapi.insure`
> **北京医保位置**: `D:\work\his-medical-group\zlchs.BJ.XBYB.insure`

---

## 与 HIS5.1 版本的差异速览

| 方面 | HIS5.1 (CICT) | HIS5.0 (zlchs) |
|------|--------------|----------------|
| **命名空间** | `CICT.Interface.Control` / `CICT.Common.Base` / `CICT.Insure.Interface` | `zlchs.Interface.Control` / `zlchs.Common.Base` / `zlchs.Insure.Interface` |
| **总控DLL名** | `CICT.Interface.Control.dll` | `zlchs.Interface.Control.dll` |
| **登录信息解析** | 所有业务类型都解析 token | CA 业务 (8xxx) **跳过** token 解析 |
| **业务类型数** | 45 个 | 53 个（新增 8 个 CA 签名类型 8001-8008） |
| **新增模块** | 无 | CA 客户端签名模块（`CAInterfaceBusiness` + `I_CAInterface`） |
| **新增编排方法** | 无 | `ClincPreSettleSingle()` / `ClincSettleSingle()` / `HospitalSettleSingle()` |
| **Business.cs 行数** | 2455 | 2972 (+517 行) |
| **动态加载** | 直接设置工作目录 | 增加 `!path.Contains(folder)` 路径重复检查 |
| **CA反射机制** | 无 | 独立反射：前缀 `CA_`，目录 `Plugins.CAInterface`，使用字典缓存 |
| **医保接口方法** | 完全相同 | 完全相同（54 个方法） |

---

## 一、整体架构概览

```
┌──────────────────────────────────────────┐
│         HIS 客户端 (sdp.cpapi)            │
│  Plugins.WebInsurance 插件                │
│  ProcessRequest("Interface", jsonParams)  │
└──────────────┬───────────────────────────┘
               │ 反射 → CommonTools.ExceInsureMethod()
               │ ★ HIS5.0 加载 zlchs.Interface.Control.dll（非 CICT）
               ▼
┌──────────────────────────────────────────────────────┐
│    医保总控 (zlchs.Interface.Control)                  │
│    Common.Interface() → switch 路由                    │
│    ├─ 1xxx/2xxx: Business → InsureBusiness (医保)      │
│    └─ 8xxx: Business → CAInterfaceBusiness (CA签名) ★  │
└──────────────┬───────────────────────────────────────┘
               │ _objectReflection("ins_id")
               │ 查库 insur.ins_system → "zlchs.BJ.XBYB.insure"
               │ Assembly.LoadFrom → Cls_BJGJBYB
               ▼
┌──────────────────────────────────────────┐
│    北京医保 (Cls_BJGJBYB)                  │
│    ├─ 本地数据库操作 (insur schema)        │
│    ├─ 🔗 HTTP WebAPI → 医保中心           │
│    │   (SHA256签名, x-tif-* 请求头)       │
│    └─ 🔗 SOAP WebService → 住院实时接口   │
│        (UpInhospInfo)                     │
└──────────────────────────────────────────┘
```

### HIS5.0 双插件体系

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
    │ 北京医保 DLL  │     │ CA签名 DLL   │
    │ 广东医保 DLL  │     └─────────────┘
    │ ...          │
    └──────────────┘
```

---

## 二、第一层：HIS 客户端发起调用

### 2.1 插件入口 — WebInsurance.ProcessRequest()

> 文件: `code/sdp.cpapi/Plugins.WebInsurance/WebInsurance.cs:34`

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
        LogTools.Info($"调用业务总控方法前，入参{strJson}", true);

        string res = string.Empty;
        if (control == ControlEnum.InsureControl)
        {
            res = ExceInsureMethod(type, "Interface", strJson);
        }
        else if (control == ControlEnum.InsureTools)
        {
            res = ExceInsureMethod(type, "InsureTools", strJson);
        }

        LogTools.Info($"调用业务总控方法后，出参{res}", true);

        // 解析返回值，验证 code 字段
        JObject @object = JObject.Parse(res);
        string code = @object["code"].ToString();
        if (!code.Equals("1"))
        {
            result.State = code.Equals("9")
                ? HttpStatusCode.RequestTimeout
                : HttpStatusCode.PreconditionFailed;
            result.Error = @object["message"].ToString();
            return result;
        }
        result.Value = @object["data"].ToString();
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
    var baseDir = AppDomain.CurrentDomain.BaseDirectory;
    var assibmliePath = Path.Combine(baseDir, "zlchs.Interface.Control.dll");

    // 按优先级查找总控 DLL
    var insureDirctory = Path.Combine(baseDir, type);
    if (File.Exists(Path.Combine(insureDirctory, "zlchs.Interface.Control.dll")))
        assibmliePath = Path.Combine(insureDirctory, "zlchs.Interface.Control.dll");

    insureDirctory = Path.Combine(baseDir, Path.GetFileNameWithoutExtension(BaseTools.BUSINESSCONTROL));
    if (File.Exists(Path.Combine(insureDirctory, "zlchs.Interface.Control.dll")))
        assibmliePath = Path.Combine(insureDirctory, "zlchs.Interface.Control.dll");

    // ★ HIS5.0: 加载 zlchs.Interface.Control（非 CICT）
    Assembly assembly1 = Assembly.Load("zlchs.Interface.Control");
    Type type1 = assembly1.GetType("zlchs.Interface.Control.Common");
    MethodInfo method = type1.GetMethod(methodName);    // "Interface"
    object activator = Activator.CreateInstance(type1);
    Object[] parametors = new Object[] { param };
    return (string)method.Invoke(activator, parametors);
}
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

---

### 3.2 业务编排 — Business.ClincChoseInsure() (门诊选择保险)

> 文件: `zlsoft.cpapi.insure/zlchs.Interface.Control/Business.cs:28`

```csharp
public string ClincChoseInsure(JObject data)
{
    string orgid = data.Value<string>("org_id");

    // ① 弹出医保选择对话框
    Frm医保选择 frm = new Frm医保选择(orgid, data.ToString());
    frm.ShowDialog();
    if (string.IsNullOrEmpty(frm.InsureSystem))
        return 错误响应("选择医保返回空!");

    // ② 将选择结果写入请求数据
    if (data.Property("ins_id") != null)
        data.Remove("ins_id");
    data.Add("ins_id", frm.InsureSystem);

    // ③ 初始化医保接口
    InsureBusiness insure = new InsureBusiness();
    bool b = insure.InitInsure(data.ToString());
    if (!b) return 错误响应("初始化失败!");

    // ④ 身份验证
    string identify = insure.Identify(data.ToString());
    JObject identify_out = JObject.Parse(identify);
    if (identify_out.Value<string>("code") != "1")
        return 错误响应("身份验证失败!");

    // ⑤ 回写 pt_id
    if (data.Property("pt_id") != null) data.Remove("pt_id");
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

    // ② 预结算（非拆分模式）
    JObject presettle_out = new JObject();
    string is_split = data.Value<string>("is_split");
    if (is_split != "1")
    {
        string presettle = insure.ClinicPreSwap(data.ToString());
        presettle_out = JObject.Parse(presettle);
        if (presettle_out.Value<string>("code") != "1")
            return 错误响应("预结算失败!");
    }

    // ③ 正式结算
    JObject settle_out = new JObject();
    JObject presettle_out_data = presettle_out.Value<JObject>("data");
    if (presettle_out_data != null && presettle_out_data.Value<string>("is_split") == "1")
        settle_out = presettle_out;
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
    out_data.Add("personal_sum", balance_out.Value<JObject>("data").Value<string>("personal_sum"));
    return JsonConvert.SerializeObject(new Response { code = "1", data = out_data });
}
```

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
    if (balance_out.Value<string>("code") != "1")
        return 错误响应("获取账户余额失败!");

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

    public static void _objectReflection(string insureSystem, string DataIn)
    {
        DataTable dt = BaseDataHelper.GetInterfaceList(insureSystem, DataIn);
        //   SQL: SELECT name AS 名称, interface_name AS 医保部件
        //        FROM insur.ins_system WHERE id = @insureSystem

        if (dt == null || dt.Rows.Count < 1)
        {
            // 回退到测试实现
            obj = ObjectReflection.CreateObject("zlchs.TEST.Insure", "Cls_", "Plugins.WebInsurance");
            Iinterface = obj as IInsureInterface;
            return;
        }

        // 动态加载: dt["医保部件"] = "zlchs.BJ.XBYB.insure"
        obj = ObjectReflection.CreateObject(dt.Rows[0]["医保部件"].ToString(), "Cls_", "Plugins.WebInsurance");
        InsureBusiness.Iinterface = obj as IInsureInterface;
    }
}
```

每个业务方法的代理模式：
```csharp
public string ClinicSwap(string strJson)
{
    JObject jObjec = JObject.Parse(strJson);
    string insureSystem = jObjec.Value<string>("ins_id");
    _objectReflection(insureSystem, strJson);
    return Iinterface.ClinicSwap(strJson);    // → Cls_BJGJBYB.ClinicSwap()
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

| 方面 | InsureBusiness (医保) | CAInterfaceBusiness (CA) |
|------|----------------------|-------------------------|
| 反射前缀 | `"Cls_"` | `"CA_"` |
| DLL 目录 | `Plugins.WebInsurance` | `Plugins.CAInterface` |
| 接口 | `IInsureInterface` | `I_CAInterface` |
| 路由字段 | `ins_id` → 查库获取 DLL 名 | `interface_name` → 直接从 JSON 取 |
| 实例缓存 | 无缓存（每次重新加载） | 字典缓存（首次加载后复用） |

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

    // 扫描类型，匹配前缀（"Cls_" 或 "CA_"）
    foreach (Type clsName in targetAssembly.GetTypes())
    {
        if (clsName.Name.IndexOf(ProjType) != -1)
        {
            _className = asseblyName + "." + clsName.Name;
            break;
        }
    }

    type = targetAssembly.GetType(_className);
    return type;
}
```

---

### 3.9 IInsureInterface 接口契约

> 文件: `zlsoft.cpapi.insure/zlchs.Insure.Interface/IInsureInterface.cs`

与 HIS5.1 完全相同，54 个方法：

| 类别 | 方法 | 用途 |
|------|------|------|
| **生命周期** | `InitInsure` / `EndInsure` | 初始化/销毁 |
| **认证** | `SignIn` / `SignOut` / `Identify` / `IdentifyCancel` | 签到/签退/身份验证 |
| **账户** | `SelfBalance` | 获取余额 |
| **门诊** | `ClinicPreSwap` / `ClinicSwap` / `ClinicDelSwap` | 预结算/结算/作废 |
| **住院** | `ComeInSwap` / `ComeInDelSwap` / `ModiPatiSwap` | 入院/撤销/修改 |
| **住院** | `LeaveSwap` / `LeaveDelSwap` | 出院/撤销出院 |
| **住院** | `WipeoffMoney` / `SettleSwap` / `SettleDelSwap` | 预结算/结算/撤销 |
| **费用** | `ItemMarking` / `DetailUpload` / `DetailUploadDel` | 打标/上传/撤销 |
| **目录** | `CatalogDownload` / `CatalogUpload` / `DiagnosisDownload` | 目录同步 |
| **人员** | `DoctorDownload` / `DoctorUpload` / `DepartmentDownload` / `DepartmentUpload` | 人员科室 |
| **病历** | `MedRecordUpload` / `MedRecordUploadDel` / `CaseUpload` / `CaseUploadDel` | 病案首页/病历 |
| **对账** | `InsureCheck` | 日/月对账 |
| **扩展** | `Advance_function` / `InterfaceTools` | 扩展功能 |

---

## 四、第三层：北京医保具体实现 (Cls_BJGJBYB)

> 文件: `zlchs.BJ.XBYB.insure/Cls_BJGJBYB.cs` (4622 行)
> 此层与 HIS5.1 文档完全相同，以下为完整展示。

---

### 4.1 InitInsure() — 初始化 (行151)

**纯本地操作**，从 `insur.ins_initial` 加载全部配置参数。

```csharp
public bool InitInsure(string strJson)
{
    JObject objIn = JObject.Parse(strJson);
    operator_id = objIn.Value<string>("operator_id");
    insureSystem = objIn.Value<string>("ins_id");
    organizationId = objIn.Value<string>("org_id");
    operator_code = DataHelpers.GetDoctorCode(operator_id, strJson);

    DataTable dtbx = DataHelpers.GetInsure(insureSystem, organizationId, strJson);
    for (int i = 0; i < dtbx.Rows.Count; i++)
    {
        switch (dtbx.Rows[i]["name"].ToString())
        {
            case "接口地址":          strIn接口地址 = dtbx.Rows[i]["value"].ToString(); break;
            case "住院实时接口地址":   strIn住院实时接口地址 = dtbx.Rows[i]["value"].ToString(); break;
            case "账户编码":          strIn账户编码 = dtbx.Rows[i]["value"].ToString(); break;
            case "账户密钥":          strIn账户密钥 = dtbx.Rows[i]["value"].ToString(); break;
            case "就医地医保区划":     strIn就医地行政区划 = dtbx.Rows[i]["value"].ToString(); break;
            case "定点医药机构编号":   strIn定点医药机构编号 = dtbx.Rows[i]["value"].ToString(); break;
            // ... 30+ 配置参数
        }
    }
    return true;
}
```

---

### 4.2 Identify() — 身份验证 (行437)

```csharp
public string Identify(string strJson)
{
    // ─────────────────────────────────────────────────────────────────
    // 🔗 医保中心交互 (间接): Frm身份验证窗口内部
    //    → HttpHelper.YBBusiness("1101", "人员信息获取", ...)
    //    → HTTP POST 到医保中心获取参保人员信息
    //    → 保存到: insur.ins_archive + insur.ins_archive_vs
    // ─────────────────────────────────────────────────────────────────
    Frm身份验证 frm = new Frm身份验证(patientId, insureSystem, operatorInfo,
        insureOrgCode, organizationId, dept_id, handle_type, strJson);
    frm.ShowDialog();

    if (frm.strReturnData != null)
        return {code:"1", data: frm.strReturnData};
    else
        return {code:"0", message:"医保身份验证返回空!"};
}
```

---

### 4.3 SelfBalance() — 获取账户余额 (行513)

**纯本地操作**，从 `ins_archive.swap_info` JSON 字段读取。

```csharp
public string SelfBalance(string strJson)
{
    string sql = @"select (a.swap_info->>'选择余额') as 账户余额
        from insur.ins_archive a
        left join insur.ins_archive_vs b on a.ins_id = b.ins_id and a.ins_card_no = b.ins_card_no
        where a.ins_id = @insureSystem and b.pt_id = @patientID";
    DataTable dt = BaseDataHelper.GetDataTable(strJson, "SelfBalance", "fee", sql, parameters);
    // 返回: {code:"1", data:{personal_account:"500.00"}}
}
```

---

### 4.4 ClinicPreSwap() — 门诊预结算 (行623) ★ 核心方法

```csharp
public string ClinicPreSwap(string strJson)
{
    // 阶段1: 本地查询（档案、在院标识、费用明细、处方、科室对照）
    dt_dangan = DataHelpers.QueryPatientInfo(insureSystem, patientID, strJson);
    dt_FeiY = DataHelpers.GetFeeDetails(patientID, fee_detail_id, ...);
    dt_RecipeInfo = DataHelpers.GetRecipeInfo(organizationId, visitId, ...);

    // 阶段2: 构建费用分解 XML
    for (int i = 0; i < dt_FeiY.Rows.Count; i++) { /* 构建 XML */ }

    // ─────────────────────────────────────────────────────────────────
    // 🔗 医保中心交互: 本地医保分解库
    // ─────────────────────────────────────────────────────────────────
    Tuple<bool, string> tupleOutput = MedicareComHelper.Divide(input.OuterXml);   // 行859
    // ─────────────────────────────────────────────────────────────────

    // 阶段3: 解析分解结果 XML
    // 阶段4: UPDATE insur.ins_fee_detail 更新医保编码                    行917
    // 阶段5: 医保误差检查 > 0.1元 → 阻断                                行940
    // 阶段6: 并发控制                                                    行956
    // 阶段7: 返回预结算结果
}
```

---

### 4.5 ClinicSwap() — 门诊正式结算 (行1290)

```csharp
public string ClinicSwap(string strJson)
{
    // 阶段1: 查询档案 + 就诊记录
    dt_dangan = DataHelpers.QueryPatientInfo(insureSystem, patientID, strJson);
    dt_jiuzhen = DataHelpers.QueryMedicalRecordsMZ(patientID, insureSystem, visitId, strJson);

    // 阶段2: Frm医保结算报销信息 → 操作员确认

    // ─────────────────────────────────────────────────────────────────
    // 🔗 医保中心交互: 本地医保库交易确认
    // ─────────────────────────────────────────────────────────────────
    Tuple<bool, string> tupleOutput = MedicareComHelper.TradeAll(...);              // 行~1425
    // ─────────────────────────────────────────────────────────────────

    // 阶段3: 处理结算方式（基金、个账、军残、退休、大病、民政等）
    // 阶段4: INSERT insur.ins_balance + insur.ins_balance_info
    // 阶段5: 返回结算结果
}
```

---

### 4.6 ClinicDelSwap() — 门诊结算作废 (行1591)

```csharp
public string ClinicDelSwap(string strJson)
{
    // 查询原结算 → SELECT FROM insur.ins_balance

    // ─────────────────────────────────────────────────────────────────
    // 🔗 医保中心交互: 退费分解 + 交易确认
    // ─────────────────────────────────────────────────────────────────
    MedicareComHelper.RefundmentDivideAll(...)                                      // 行~1640
    MedicareComHelper.TradeAll(...)
    // ─────────────────────────────────────────────────────────────────

    // 冲负处理: INSERT insur.ins_balance (负数) / 或 DELETE
}
```

---

### 4.7 ComeInSwap() — 住院登记 (行1979)

```csharp
public string ComeInSwap(string strJson)
{
    // 阶段1: 查询档案、住院信息、科室对照、诊断
    // 阶段2: 构建上传数据 (CASE_CODE, INHOSP_DATE, ATT_DOCT_CODE, PRI_DIAG_CODE...)

    // ─────────────────────────────────────────────────────────────────
    // 🔗 医保中心交互: SOAP WebService — 住院登记信息上传
    // ─────────────────────────────────────────────────────────────────
    // 协议: SOAP 1.1, 地址: strIn住院实时接口地址
    // BIZ_TYP = "01", 响应: RESULT_STATE = "0000" 成功
    Tuple<bool, string> result1 = MedicareWebHelper.UpInhospInfo(
        YBList.str住院登记信息上传, "01-住院登记信息上传",
        requestRY, visit_id, pt_id, strJson);                                      // 行2085
    // ─────────────────────────────────────────────────────────────────

    // 阶段3: INSERT insur.ins_visit (rec_type=2)
}
```

---

### 4.8 SettleSwap() — 住院结算 (行3173) ★ 最复杂

```csharp
public string SettleSwap(string strJson)
{
    // 阶段1: 查询档案 + 就诊记录 + 预结记录
    // 阶段2: 构建请求 (psn_no, mdtrt_id, medfee_sumamt, insutype...)

    // ─────────────────────────────────────────────────────────────────
    // 🔗 医保中心交互: HTTP WebAPI — 住院结算 (2304)
    // ─────────────────────────────────────────────────────────────────
    // SHA256 签名, x-tif-* 请求头
    Tuple<bool, string> result2303 = HttpHelper.YBBusiness(
        YBList.str住院结算, "住院结算", msgid,
        strIn参保地医保区划, signNo, request2304,
        visit_id, pt_id, strJson);                                                  // 行3338
    // ─────────────────────────────────────────────────────────────────

    // 阶段3: 超时冲正
    if (strMsg.Contains("timed out"))
    {
        // ─────────────────────────────────────────────────────────
        // 🔗 医保中心交互: HTTP WebAPI — 冲正交易 (2601)
        // ─────────────────────────────────────────────────────────
        HttpHelper.YBBusiness(YBList.str冲正交易, "冲正交易", ...);                  // 行3360
        // → 成功则弹窗询问是否重试结算
    }

    // 阶段4: 医保误差检查 > 0.1元 → 自动冲正
    if (dc医保误差 > 0.1m)
    {
        // 🔗 冲正交易 (2601)                                                      行3417
    }

    // 阶段5: INSERT insur.ins_balance
}
```

---

## 五、通信层详解

### 5.1 HTTP WebAPI — HttpHelper.GetPost() (行22)

```csharp
// SHA256 签名: timestamp + 密钥 + nonce + timestamp
string signature = SHA256EncryptString(timeStamp + secretKey + nonce + timeStamp);

httpWebRequest.Headers.Add("x-tif-paasid", strIn账户编码);
httpWebRequest.Headers.Add("x-tif-signature", signature);
httpWebRequest.Headers.Add("x-tif-timestamp", timeStamp);
httpWebRequest.Headers.Add("x-tif-nonce", nonce);
```

### 5.2 HTTP 报文封装 — HttpHelper.YBBusiness() (行176)

```csharp
JObject.Add("infno", bussinessNo);           // "2304"
JObject.Add("msgid", msgid);                 // 报文ID
JObject.Add("insuplc_admdvs", 参保地区划);
JObject.Add("mdtrtarea_admvs", 就医地区划);
JObject.Add("fixmedins_code", 机构编号);
JObject.Add("sign_no", signNo);
JObject.Add("input", input);                 // 交易输入
```

### 5.3 SOAP WebService — MedicareWebHelper.UpInhospInfo() (行34)

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <UpInhospInfo xmlns="http://tempuri.org/">
      <inJson>{"INF_VER":"V1.0","BIZ_TYP":"01","INPUT_DATA":{...}}</inJson>
    </UpInhospInfo>
  </soap:Body>
</soap:Envelope>
```

---

## 六、🔗 医保中心交互位置汇总

| 方法 | 行号 | 交互方式 | 交易 | 说明 |
|------|------|----------|------|------|
| **Frm身份验证 (内部)** | — | HTTP WebAPI | 1101 | 获取参保人员信息 |
| **ClinicPreSwap** | 859 | 本地医保库 DLL | 费用分解 | MedicareComHelper.Divide() |
| **ClinicSwap** | ~1425 | 本地医保库 DLL | 交易确认 | MedicareComHelper.TradeAll() |
| **ClinicDelSwap** | ~1640 | 本地医保库 DLL | 退费分解+确认 | RefundmentDivideAll + TradeAll |
| **ComeInSwap** | 2085 | SOAP WebService | 01-住院登记 | MedicareWebHelper.UpInhospInfo() |
| **SettleSwap** | 3338 | HTTP WebAPI | 2304-住院结算 | HttpHelper.YBBusiness() |
| **SettleSwap** | 3360 | HTTP WebAPI | 2601-冲正 | 超时自动冲正 |
| **SettleSwap** | 3417 | HTTP WebAPI | 2601-冲正 | 误差过大自动冲正 |

---

## 七、交易编码总表

> 文件: `zlchs.BJ.XBYB.insure/YBList.cs`

| 编号 | 名称 | 通信方式 | 调用位置 |
|------|------|----------|----------|
| **1101** | 人员信息获取 | HTTP WebAPI | Frm身份验证 |
| **9001** | 签到 | HTTP WebAPI | SignIn() |
| **2206** | 门诊预结算 | 本地医保库 | ClinicPreSwap:859 |
| **2207** | 门诊结算 | 本地医保库 | ClinicSwap:~1425 |
| **2208** | 门诊结算撤销 | 本地医保库 | ClinicDelSwap:~1640 |
| **01** | 住院登记信息上传 | SOAP | ComeInSwap:2085 |
| **02** | 出院信息上传 | SOAP | LeaveSwap |
| **2304** | 住院结算 | HTTP WebAPI | SettleSwap:3338 |
| **2305** | 住院结算撤销 | HTTP WebAPI | SettleDelSwap |
| **2601** | 冲正交易 | HTTP WebAPI | SettleSwap:3360,3417 |

---

## 八、数据库表关系

```
insur.ins_initial             ← 医保参数配置（接口地址、密钥、区划代码等）
insur.ins_system              ← 医保系统配置（ins_id → DLL 名称）

insur.ins_archive             ← 参保人员档案（swap_info JSON）
insur.ins_archive_vs          ← 患者与档案绑定

insur.ins_fee_detail          ← 费用明细（ins_item_code, ins_submit, ins_info）
insur.ins_item / ins_item_vs  ← 医保项目目录 / HIS对照
insur.ins_dept_compare        ← 科室对照

insur.ins_visit               ← 就诊记录（rec_type: 1=门诊, 2=住院）
insur.ins_balance             ← 结算记录（swap_info 含医保返回完整数据）
insur.ins_balance_info        ← 结算支付方式明细

insur.ins_log                 ← 🔗 接口交易日志
insur.ins_dictionary          ← 医保字典
```

---

## 九、完整流程示例：门诊结算全链路

```
步骤 1: HIS 前端 → {business_type:"1106", ins_id:"002", ...}

步骤 2: WebInsurance.ProcessRequest("Interface", jsonParams)
         → WebInsuranceHelper.Interface(jsonParams)
         → CommonTools.ExceInsureMethod()
         → Assembly.Load("zlchs.Interface.Control")  ★ HIS5.0 命名空间
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
         │   │     ★ if (!path.Contains(folder)) 检查后加载
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

---

## 十、关键文件索引

| 层级 | 文件路径 | 行数 | 核心内容 |
|------|----------|------|----------|
| HIS 客户端 | `sdp.cpapi/Plugins.WebInsurance/WebInsurance.cs:34` | 72 | ProcessRequest() |
| HIS 客户端 | `sdp.cpapi/Plugins.WebInsurance/WebInsuranceHelper.cs:19` | 24 | Interface() |
| HIS 客户端 | `sdp.cpapi/ZLSoft.CHSS.CPAPI.CommonBase/CommonTools.cs:31` | 255 | CallBusinessControl() / ExceInsureMethod() |
| **总控入口** | `zlsoft.cpapi.insure/zlchs.Interface.Control/Common.cs:18` | 364 | Interface() + 53 个 switch 分支 |
| **总控业务** | `zlsoft.cpapi.insure/zlchs.Interface.Control/Business.cs:28` | 2972 | 编排方法 + CA 签名方法 |
| **医保路由** | `zlsoft.cpapi.insure/zlchs.Insure.Interface/InsureBusiness.cs:35` | 523 | _objectReflection() + 54 个代理方法 |
| **CA路由** ★ | `zlsoft.cpapi.insure/zlchs.Insure.Interface/CAInterfaceBusiness.cs` | 128 | CA 签名路由代理 |
| **医保接口** | `zlsoft.cpapi.insure/zlchs.Insure.Interface/IInsureInterface.cs` | 320 | 54 个接口方法 |
| **CA接口** ★ | `zlsoft.cpapi.insure/zlchs.Insure.Interface/I_CAInterface.cs` | 47 | 6 个 CA 接口方法 |
| **动态加载** | `zlsoft.cpapi.insure/zlchs.Common.Base/ObjectReflection.cs:19` | 127 | CreateObject() + 路径重复检查 |
| **数据访问** | `zlsoft.cpapi.insure/zlchs.Common.Base/BaseDataHelper.cs` | 1000+ | SQL 操作 + CA 签名方法 |
| 北京医保 | `zlchs.BJ.XBYB.insure/Cls_BJGJBYB.cs` | 4622 | IInsureInterface 实现 |
| HTTP 通信 | `zlchs.BJ.XBYB.insure/HttpHelper.cs` | 361 | SHA256 签名 + WebAPI |
| SOAP 通信 | `zlchs.BJ.XBYB.insure/Common/MedicareWebHelper.cs` | 226 | SOAP WebService |
| 交易编码 | `zlchs.BJ.XBYB.insure/YBList.cs` | 172 | 全部交易编码常量 |
