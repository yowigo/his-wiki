# ISB 接口签名认证

## 请求头

每次请求 **HTTP Header** 必须携带以下 3 个字段：

| Header          | 说明                               | 示例                                 |
| --------------- | ---------------------------------- | ------------------------------------ |
| `appid`         | ISB 颁发的应用标识                 | `201912181131469`                    |
| `timestamp`     | 当前 Unix 时间戳（**毫秒级**）     | `1779415116521`                      |
| `authorization` | 签名结果（MD5，32 位小写十六进制） | `bfc2b8bf11a9679f5b260e3df14cd8fe`   |

> `appid` 和 `app_auth_key` 由 ISB 运维线下颁发。**`app_auth_key` 等同于密码，不要写入源码、提交 git、打印日志。**

## 签名算法

```
signStr = "SOFTUN" + "|" + appid + "|" + app_auth_key + "|" + timestamp + "|" + "SOFTUN"
authorization = MD5(signStr)     // 32位小写十六进制，UTF-8编码
```

规则：

- 分隔符是**半角竖线** `|`（ASCII 0x7C），不是全角 `｜`
- `SOFTUN` 前后各一份，区分大小写
- `timestamp` 必须与同次请求 Header 里的 `timestamp` 完全一致，只能取一次
- 字符串编码 UTF-8
- 服务端校验 `timestamp` 与服务器时间偏差**超过 5 分钟即拒绝**，请确保调用方机器已同步 NTP

## 测试用例

用以下固定参数验证你的签名实现：

| 参数           | 值                                                             |
| -------------- | -------------------------------------------------------------- |
| `appid`        | `TEST_APPID`                                                   |
| `app_auth_key` | `TEST_APP_AUTH_KEY`                                            |
| `timestamp`    | `1779415116521`                                                |
| `signStr`      | `SOFTUN\|TEST_APPID\|TEST_APP_AUTH_KEY\|1779415116521\|SOFTUN` |
| `authorization`| `bfc2b8bf11a9679f5b260e3df14cd8fe`                             |

## Postman 集成

### 1. 配置环境变量

右上角眼睛图标 → Environments → 新建环境，添加两个 `secret` 类型变量（`Initial Value` 留空，只填 `Current Value`）：

| Variable       | Type   | Current Value          |
| -------------- | ------ | ---------------------- |
| `appid`        | secret | 你拿到的真实 appid     |
| `app_auth_key` | secret | 你拿到的真实 auth key  |

### 2. Pre-request Script

放到 Collection 或单个请求的 `Pre-request Script` 中：

```javascript
const appid = pm.environment.get("appid");
const app_auth_key = pm.environment.get("app_auth_key");

if (!appid || !app_auth_key) {
    throw new Error("appid 或 app_auth_key 未配置");
}

const timestamp = Date.now();
const authorization = CryptoJS.MD5(`SOFTUN|${appid}|${app_auth_key}|${timestamp}|SOFTUN`).toString();

pm.collectionVariables.set("timestamp", timestamp);
pm.collectionVariables.set("authorization", authorization);
```

### 3. 请求头

| Key             | Value               |
| --------------- | ------------------- |
| `appid`         | `{{appid}}`         |
| `timestamp`     | `{{timestamp}}`     |
| `authorization` | `{{authorization}}` |

## C# 集成

```csharp
using System;
using System.Linq;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;

public class IsbAuth
{
    private readonly string _appId;
    private readonly string _appAuthKey;

    public IsbAuth(string appId, string appAuthKey)
    {
        _appId = appId;
        _appAuthKey = appAuthKey;
    }

    /// <summary>生成签名三件套</summary>
    public (string appid, string timestamp, string authorization) Build()
    {
        var timestamp = DateTimeOffset.Now.ToUnixTimeMilliseconds().ToString();
        var signStr = $"SOFTUN|{_appId}|{_appAuthKey}|{timestamp}|SOFTUN";
        using var md5 = MD5.Create();
        var hash = md5.ComputeHash(Encoding.UTF8.GetBytes(signStr));
        var auth = string.Concat(hash.Select(b => b.ToString("x2")));
        return (_appId, timestamp, auth);
    }

    /// <summary>写入 HttpClient 默认请求头（每次请求前调用）</summary>
    public void ApplyTo(HttpClient client)
    {
        var (appid, ts, auth) = Build();
        client.DefaultRequestHeaders.Remove("appid");
        client.DefaultRequestHeaders.Remove("timestamp");
        client.DefaultRequestHeaders.Remove("authorization");
        client.DefaultRequestHeaders.Add("appid", appid);
        client.DefaultRequestHeaders.Add("timestamp", ts);
        client.DefaultRequestHeaders.Add("authorization", auth);
    }
}
```

调用：

```csharp
var auth = new IsbAuth("你的appid", "你的app_auth_key");
using var client = new HttpClient { BaseAddress = new Uri("https://isb-host/") };
auth.ApplyTo(client);
var resp = await client.PostAsJsonAsync("api/xxx", payload);
```

> `ApplyTo` 写的是 `DefaultRequestHeaders`，复用 `HttpClient` 时每次请求前都要调用一次，否则 `timestamp` 过期（>5 分钟）会被拒绝。

## 常见错误

| 现象                      | 原因                                      | 排查                                     |
| ------------------------- | ----------------------------------------- | ---------------------------------------- |
| `401 invalid authorization` | 签名不匹配                                | 用测试用例自校验；检查竖线是否全角、MD5 大小写 |
| `401 timestamp expired`     | 客户端时间与服务器偏差 > 5 分钟           | 同步 NTP                                 |
| `401 appid not found`       | appid 未注册                              | 联系 ISB 运维核对                        |
| signStr 中间出现 `\|\|`     | appid 或 app_auth_key 为空                | 检查配置是否加载                         |
