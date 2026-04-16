# 第三方平台对接模板

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/02-接口模板/第三方对接模板.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/api/third-party-integration.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

## 适用场景

对接医保平台、检验互认平台、药事平台等外部系统。

## 对接模式总结

基于现有项目（广东互认、北京CHIMA、上海医保等），总结两种典型对接模式：

### 模式一：Token认证 + XML（广东省互认）

```csharp
/// <summary>
/// Token认证对接服务
/// </summary>
public class TokenAuthService
{
    private static string _cachedToken;
    private static DateTime _tokenExpiry;

    /// <summary>
    /// 获取Token（带缓存，默认6小时）
    /// </summary>
    public string GetToken()
    {
        if (!string.IsNullOrEmpty(_cachedToken) && DateTime.Now < _tokenExpiry)
            return _cachedToken;

        var publicKey = Common.GetFromConfig("publickey");
        var consumerId = Common.GetFromConfig("consumerId");
        var tokenUrl = Common.GetFromConfig("token_url");

        // SM2公钥加密认证
        var encryptedId = Sm2Crypto.Encrypt(consumerId, publicKey);

        var response = HttpPost(tokenUrl, new { consumerId = encryptedId });
        var result = JsonConvert.DeserializeObject<TokenResponse>(response);

        _cachedToken = result.Token;
        _tokenExpiry = DateTime.Now.AddHours(6);

        return _cachedToken;
    }

    /// <summary>
    /// 带Token的HTTP请求
    /// </summary>
    public string PostWithToken(string url, string xmlBody)
    {
        var token = GetToken();
        using (var client = new HttpClient())
        {
            client.DefaultRequestHeaders.Add("Authorization", $"Bearer {token}");
            var content = new StringContent(xmlBody, Encoding.UTF8, "application/xml");
            var response = client.PostAsync(url, content).Result;
            return response.Content.ReadAsStringAsync().Result;
        }
    }
}
```

### 模式二：SM4加密 + SM3签名 + JSON（北京CHIMA）

```csharp
/// <summary>
/// 国密加密对接服务
/// </summary>
public class SmCryptoService
{
    private readonly string _sm4Key;
    private readonly string _signKey;

    public SmCryptoService()
    {
        _sm4Key = Common.GetFromConfig("sm4key");
        _signKey = Common.GetFromConfig("signKey");
    }

    /// <summary>
    /// 加密请求并发送
    /// </summary>
    public string PostEncrypted(string url, object requestData)
    {
        // 1. 序列化请求体
        var jsonBody = JsonConvert.SerializeObject(requestData);

        // 2. SM4加密请求体
        var encryptedBody = Sm4Crypto.Encrypt(jsonBody, _sm4Key);

        // 3. SM3签名
        var timestamp = DateTimeOffset.Now.ToUnixTimeMilliseconds().ToString();
        var signContent = $"{encryptedBody}{timestamp}{_signKey}";
        var sign = SM3Helper.Hash(signContent);

        // 4. 发送HTTPS请求
        using (var client = new HttpClient())
        {
            client.DefaultRequestHeaders.Add("X-Timestamp", timestamp);
            client.DefaultRequestHeaders.Add("X-Sign", sign);

            var content = new StringContent(encryptedBody, Encoding.UTF8, "application/json");
            var response = client.PostAsync(url, content).Result;
            var responseBody = response.Content.ReadAsStringAsync().Result;

            // 5. SM4解密响应
            return Sm4Crypto.Decrypt(responseBody, _sm4Key);
        }
    }
}
```

## 通用对接流程

```
接收触发 → ProcessRequest(action, jsonParams)
    ↓
1. 从HIS数据库查询业务数据
    ↓
2. 数据转换/组装（匹配平台数据格式）
    ↓
3. 认证（Token / 国密加密签名）
    ↓
4. 发送HTTP请求
    ↓
5. 解析响应（解密 / XML解析 / JSON解析）
    ↓
6. 写入本地记录表（上传状态、响应结果）
    ↓
7. 返回PluginResult
```

## 配置文件结构

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <!-- 平台类型：1=模式A, 2=模式B -->
    <project_type>1</project_type>

    <!-- 平台接口地址 -->
    <platform_url>https://api.platform.com</platform_url>

    <!-- 认证凭据 -->
    <consumerId>YOUR_CONSUMER_ID</consumerId>
    <publickey>SM2公钥</publickey>
    <sm4key>SM4密钥</sm4key>
    <signKey>签名密钥</signKey>

    <!-- 机构信息 -->
    <hospital_code>H001</hospital_code>
    <hospital_name>XX医院</hospital_name>
    <region_code>310000</region_code>
</configuration>
```

## 错误处理规范

```csharp
try
{
    var result = service.PostEncrypted(url, data);
    var response = JsonConvert.DeserializeObject<PlatformResponse>(result);

    if (response.Code != "0")
    {
        LogTools.Error($"[Upload] Platform returned error: code={response.Code}, msg={response.Message}");
        return new PluginResult
        {
            Code = 4001,
            Message = $"平台返回错误：{response.Message}"
        };
    }

    return new PluginResult { Code = 0, Message = "上传成功", Data = response.Data };
}
catch (HttpRequestException ex)
{
    LogTools.Error($"[Upload] Network error: {ex.Message}", ex);
    return new PluginResult { Code = 4002, Message = "网络连接失败，请检查网络" };
}
catch (TimeoutException ex)
{
    LogTools.Error($"[Upload] Request timeout: {ex.Message}", ex);
    return new PluginResult { Code = 4003, Message = "请求超时，请稍后重试" };
}
catch (Exception ex)
{
    LogTools.Error($"[Upload] Unexpected error: {ex.Message}", ex);
    return new PluginResult { Code = 9001, Message = $"系统异常：{ex.Message}" };
}
```

## 日志文件

各插件日志独立存放：

```
{BaseDirectory}/插件名日志/Log_yyyyMMdd.txt
```

格式：`yyyy-MM-dd HH:mm:ss.fff [级别] 内容`

---
**文档来源**: Keiskei 整理的HIS知识库  
**整理说明**: 从Windows桌面知识库整理到his-wiki统一管理  
**模板类型**: 第三方平台对接  
**适用项目**: 医保平台、互认平台、药事平台等外部系统对接  
**核心内容**: 对接模式、认证方式、加密签名、错误处理  
**相关文档**: [插件开发模板](plugin-development.md)、[CRUD接口模板](crud-template.md)