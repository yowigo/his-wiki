# CA 签名模块（HIS5.0 新增）

> 原始资料：[HIS5.0 北京医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md)、[HIS5.0 模拟医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-模拟医保中心-代码走查.md)

---

## 概述

HIS5.0 新增 **CA 客户端签名模块**，与原有医保插件并行构成双插件体系。CA 业务类型编码为 `8001-8008`，由 `Common.Interface()` 中的 switch 路由到 `CAInterfaceBusiness`。

### 与医保模块的关键差异

| 方面 | 医保模块 | CA 签名模块 |
|------|----------|-------------|
| 业务类型 | `1xxx` / `2xxx` | `8xxx` |
| 反射前缀 | `"Cls_"` | `"CA_"` |
| DLL 目录 | `Plugins.WebInsurance` | `Plugins.CAInterface` |
| 接口 | `IInsureInterface` | `I_CAInterface` |
| 路由类 | `InsureBusiness` | `CAInterfaceBusiness` |
| 实例缓存 | 无缓存 | 字典缓存 |
| 路由字段 | `ins_id` → 查库 | `interface_name` → 直接取 |

---

## I_CAInterface 接口

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

## CA 路由代理

`CAInterfaceBusiness` 使用**字典缓存**机制，首次加载后复用实例：

```csharp
public class CAInterfaceBusiness
{
    public static I_CAInterface Iinterface;
    public static object obj = null;
    public static Dictionary<String, object> dic = new Dictionary<string, object>();

    public static void _objectReflection(string systemName)
    {
        if (dic.ContainsKey(systemName) == false)
        {
            // 首次加载：前缀 "CA_"，目录 "Plugins.CAInterface"
            obj = ObjectReflection.CreateObject(systemName, "CA_", "Plugins.CAInterface");
            dic.Add(systemName, obj);
        }
        else
        {
            obj = dic[systemName];   // 直接从缓存取
        }
        CAInterfaceBusiness.Iinterface = obj as I_CAInterface;
    }

    // 代理方法
    public static string QrCode(string StrJosn)
    {
        JObject DataIn = JObject.Parse(StrJosn);
        string interfaceName = DataIn.Value<string>("interface_name");
        _objectReflection(interfaceName);
        return Iinterface.QrCode(StrJosn);
    }
}
```

---

## 业务类型路由

```csharp
// Common.Interface() 中的 switch
switch (businesstype)
{
    // ... 医保业务 1xxx/2xxx ...

    // ─── ★ HIS5.0 新增: 客户端CA签名 ───
    case "8001": result = business.QrCode(DataIn.ToString());        break; // 获取登录二维码
    case "8002": result = business.LoginUserInfo(DataIn.ToString()); break; // 获取U盾信息
    case "8003": result = business.synDoctor(DataIn.ToString());     break; // 同步人员信息
    case "8004": result = business.SendSginData(DataIn.ToString());  break; // 执行签名
    case "8005": result = business.GetSginResult(DataIn.ToString()); break; // 获取签名结果
    case "8006": result = business.DownloadSginData(DataIn.ToString()); break; // 下载签名原文
    case "8007": result = business.GetSginResult(DataIn.ToString()); break; // 签名结果(批量)
    case "8008": result = business.CASignConfim(DataIn.ToString());  break; // 签名确认
}
```

### token 处理差异

CA 业务 **跳过** token 登录信息解析：

```csharp
// Common.Interface()
if (!businesstype.StartsWith("8"))   // ← CA 业务不解析 token
{
    LoginUserInfo loginUserInfo = BaseTools.GetLoginUserInfo(DataIn.ToString());
    // ... 注入 org_id, operator_id 等
}
```

---

## CA 业务编排

```csharp
// Business.cs 中的 CA 方法代理
public string QrCode(string strJson)
{
    CAInterfaceBusiness._objectReflection("CAInterfaceSystem");
    return CAInterfaceBusiness.Iinterface.QrCode(strJson);
}

public string LoginUserInfo(string strJson) { /* 同上模式 */ }
public string synDoctor(string strJson) { /* 同上模式 */ }
public string SendSginData(string strJson) { /* 同上模式 */ }
public string GetSginResult(string strJson) { /* 同上模式 */ }
public string DownloadSginData(string strJson) { /* 同上模式 */ }
public string CASignConfim(string strJson) { /* 同上模式 */ }
```
