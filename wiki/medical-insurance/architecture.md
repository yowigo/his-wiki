# 医保总控架构

> 原始资料：[HIS5.0 北京医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md)、[HIS5.0 模拟医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-模拟医保中心-代码走查.md)

---

## 整体架构

系统采用 **三层插件化架构**：

```
┌──────────────────────────────────────────┐
│         HIS 客户端 (sdp.cpapi)            │
│  Plugins.WebInsurance 插件                │
│  ProcessRequest("Interface", jsonParams)  │
└──────────────┬───────────────────────────┘
               │ 反射 → CommonTools.ExceInsureMethod()
               │ ★ HIS5.0: Assembly.Load("zlchs.Interface.Control")
               ▼
┌──────────────────────────────────────────────────────┐
│    医保总控 (zlchs.Interface.Control)                  │
│    Common.Interface() → switch 路由                    │
│    ├─ 1xxx/2xxx: Business → InsureBusiness (医保)      │
│    └─ 8xxx: Business → CAInterfaceBusiness (CA签名) ★  │
└──────────────┬───────────────────────────────────────┘
               │ _objectReflection("ins_id")
               │ 查库 insur.ins_system → 动态加载 DLL
               ▼
┌──────────────────────────────────────────┐
│    具体医保实现 (Cls_* / CA_*)             │
│    ├─ 本地数据库操作 (insur schema)        │
│    ├─ 🔗 HTTP WebAPI → 医保中心           │
│    └─ 🔗 SOAP WebService → 住院实时接口   │
└──────────────────────────────────────────┘
```

### 各层职责

| 层级 | 核心文件 | 职责 |
|------|----------|------|
| **HIS 客户端** | `WebInsurance.cs`、`WebInsuranceHelper.cs`、`CommonTools.cs` | 插件入口、反射加载总控 DLL |
| **医保总控** | `Common.cs`、`Business.cs`、`InsureBusiness.cs` | 业务路由、编排、动态插件加载 |
| **医保实现** | `Cls_BJGJBYB.cs`、`Cls_SHXBYB.cs` 等 | 对接各地医保中心、操作数据库 |

---

## HIS5.0 双插件体系

HIS5.0 在总控层新增 **CA 签名插件体系**，与原有医保插件并行：

```
                zlchs.Interface.Control
                   ┌─────┴─────┐
                   │           │
         InsureBusiness    CAInterfaceBusiness
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

### 医保路由 vs CA 路由

| 方面 | InsureBusiness (医保) | CAInterfaceBusiness (CA) |
|------|----------------------|-------------------------|
| 反射前缀 | `"Cls_"` | `"CA_"` |
| DLL 目录 | `Plugins.WebInsurance` | `Plugins.CAInterface` |
| 接口 | `IInsureInterface` | `I_CAInterface` |
| 路由字段 | `ins_id` → 查库获取 DLL 名 | `interface_name` → 直接从 JSON 取 |
| 实例缓存 | 无缓存（每次重新加载） | 字典缓存（首次加载后复用） |

---

## HIS5.0 vs HIS5.1 差异

| 方面 | HIS5.1 (CICT) | HIS5.0 (zlchs) |
|------|--------------|----------------|
| **命名空间** | `CICT.*` | `zlchs.*` |
| **总控 DLL** | `CICT.Interface.Control.dll` | `zlchs.Interface.Control.dll` |
| **登录信息解析** | 所有业务类型都解析 token | CA 业务 (8xxx) **跳过** token 解析 |
| **业务类型数** | 45 个 | 53 个（新增 8 个 CA 签名类型 8001-8008） |
| **新增模块** | 无 | CA 客户端签名模块 |
| **新增编排方法** | 无 | `ClincPreSettleSingle()` / `ClincSettleSingle()` / `HospitalSettleSingle()` |
| **动态加载** | 直接设置工作目录 | 增加 `!path.Contains(folder)` 路径重复检查 |
| **医保接口方法** | 54 个 | 完全相同（54 个） |

---

## 反射加载机制

### 第一层：HIS → 总控

```csharp
// CommonTools.ExceInsureMethod()
Assembly assembly1 = Assembly.Load("zlchs.Interface.Control");
Type type1 = assembly1.GetType("zlchs.Interface.Control.Common");
MethodInfo method = type1.GetMethod("Interface");    // "Interface"
object activator = Activator.CreateInstance(type1);
return (string)method.Invoke(activator, new Object[] { param });
```

### 第二层：总控 → 医保实现

```csharp
// InsureBusiness._objectReflection()
DataTable dt = BaseDataHelper.GetInterfaceList(insureSystem, DataIn);
// SQL: SELECT interface_name FROM insur.ins_system WHERE id = @insureSystem

obj = ObjectReflection.CreateObject(
    dt.Rows[0]["医保部件"].ToString(),   // 如 "zlchs.BJ.XBYB.insure"
    "Cls_",                              // 类名前缀
    "Plugins.WebInsurance"               // DLL 所在文件夹
);
InsureBusiness.Iinterface = obj as IInsureInterface;
```

### 动态加载引擎

```csharp
// ObjectReflection.LoadSmartPartType()
if (!path.Contains(folder))   // ★ HIS5.0 新增：路径重复检查
{
    string patha = Path.Combine(path + "/" + folder, asseblyName + ".dll");
    if (File.Exists(patha))
        path = Path.Combine(path, folder);
    Directory.SetCurrentDirectory(path);
}

targetAssembly = Assembly.LoadFrom(Path.Combine(path, asseblyName + ".dll"));
foreach (Type clsName in targetAssembly.GetTypes())
{
    if (clsName.Name.IndexOf(ProjType) != -1)   // 匹配 "Cls_" 或 "CA_"
    {
        _className = asseblyName + "." + clsName.Name;
        break;
    }
}
return targetAssembly.GetType(_className);
```

---

## 业务编排模式

总控层的 `Business.cs` 采用 **模板方法模式**，每个业务类型对应一个编排方法，固定流程：

### 门诊结算编排 (ClincSettle)

```
初始化 → 预结算 → 正式结算 → 查余额（失败则回滚）→ 返回
```

```csharp
public string ClincSettle(JObject data)
{
    // ① 初始化
    InsureBusiness insure = new InsureBusiness();
    bool b = insure.InitInsure(data.ToString());
    if (!b) return 错误响应("初始化失败!");

    // ② 预结算（非拆分模式）
    if (is_split != "1")
    {
        string presettle = insure.ClinicPreSwap(data.ToString());
        // ... 校验
    }

    // ③ 正式结算
    string settle = insure.ClinicSwap(data.ToString());
    // ... 校验

    // ④ 获取余额（失败则自动回滚结算）
    string balance = insure.SelfBalance(data.ToString());
    if (balance_out.Value<string>("code") != "1")
    {
        insure.ClinicDelSwap(data.ToString());  // ★ 自动撤销
        return 错误响应("获取账户余额失败!");
    }

    // ⑤ 组织返回值
    return JsonConvert.SerializeObject(new Response { code = "1", data = out_data });
}
```

### HIS5.0 新增单步方法

| 方法 | 用途 |
|------|------|
| `ClincPreSettleSingle()` | 仅执行门诊预结算，不执行正式结算 |
| `ClincSettleSingle()` | 仅执行门诊正式结算 |
| `HospitalSettleSingle()` | 仅执行住院结算 |

---

## 业务类型路由总表

```csharp
switch (businesstype)
{
    // ─── 门诊 ───
    case "1101": business.ClincChoseInsure(DataIn);    break; // 门诊选择保险
    case "1102": business.ClincCancelInsure(DataIn);   break; // 门诊取消保险
    case "1103": business.ClincInsureItemCheck(DataIn);break; // 门诊医保项目打标
    case "1104": business.ClincDetailCancel(DataIn);   break; // 门诊费用明细上传
    case "1105": business.ClincDetailCancel(DataIn);   break; // 门诊费用明细撤销
    case "1106": business.ClincSettle(DataIn);         break; // 门诊结算
    case "1107": business.ClincSettleBack(DataIn);     break; // 门诊取消结算
    case "1190": business.Advance_function(DataIn);    break; // 自费转共济支付
    case "1191": business.Advance_function(DataIn);    break; // 共济支付作废

    // ─── 住院 ───
    case "1201": business.HospitalChoseInsure(DataIn);   break; // 住院选择保险
    case "1202": business.HospitalIn(DataIn);            break; // 入院登记
    case "1203": business.HospitalSupplement(DataIn);    break; // 住院补登记
    case "1204": business.HospitalCancelInsure(DataIn);  break; // 住院取消保险
    case "1205": business.HospitalInfoChange(DataIn);    break; // 住院信息变更
    case "1206": business.HospitalInsureItemCheck(DataIn);break;// 住院医保项目打标
    case "1207": business.HospitalDetailUpload(DataIn);  break; // 住院费用明细上传
    case "1208": business.HospitalDetailCancel(DataIn);  break; // 住院费用明细撤销
    case "1209": business.HospitalOut(DataIn);           break; // 出院登记
    case "1210": business.HospitalOutCancel(DataIn);     break; // 撤销出院
    case "1211": business.HospitalSettle(DataIn);        break; // 住院结算
    case "1212": business.HospitalSettleBack(DataIn);    break; // 住院取消结算
    case "1213": business.HospitalModiDisease(DataIn);   break; // 住院更新病种
    case "1219": business.HospitalPreSettle(DataIn);     break; // 住院预结算

    // ─── 拓展 ───
    case "1901": case "1902": business.Advance_function(DataIn); break;
    case "1909": business.Advance_function(DataIn); break; // 家床批量预结算
    case "1001": business.Advance_function(DataIn); break; // 医保卡读卡
    case "1291": business.Advance_function(DataIn); break; // 费用拆分

    // ─── 电子健康卡 / 电子票据 / 身份证 / POS / 仪器 / CA ───
    case "2001": business.HealthCard(DataIn); break;
    case "3001": business.ElectronicInvoice(DataIn); break;
    case "4001": business.ReadIDCard(DataIn); break;
    case "6001": business.GetBalanceAccunt(DataIn); break;
    case "8001": business.QrCode(DataIn.ToString()); break; // ★ CA
}
```

---

## 设计模式

| 模式 | 位置 | 作用 |
|------|------|------|
| **Facade** | `Common.Interface()` | 对外统一入口，屏蔽内部复杂性 |
| **Strategy** | `IInsureInterface` / `I_CAInterface` | 各地医保可互换；CA 实现可互换 |
| **Factory** | `ObjectReflection.CreateObject()` | 根据配置动态创建实例 |
| **Proxy** | `InsureBusiness` / `CAInterfaceBusiness` | 自动处理 DLL 加载，对上层透明 |
| **Template Method** | `Business.ClincSettle()` | 编排固定步骤：初始化→预结算→结算→查余额 |
