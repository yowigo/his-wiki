# 医保通信层详解

> 原始资料：[HIS5.0 北京医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md)

---

## 通信方式概览

| 方式 | 协议 | 用途 | 调用位置 |
|------|------|------|----------|
| **HTTP WebAPI** | HTTP POST + SHA256 签名 | 门诊/住院结算、人员信息获取 | `HttpHelper.YBBusiness()` |
| **本地医保库 DLL** | .NET 本地调用 | 费用分解、交易确认 | `MedicareComHelper.Divide()` / `TradeAll()` |
| **SOAP WebService** | SOAP 1.1 | 住院登记/出院信息上传 | `MedicareWebHelper.UpInhospInfo()` |

---

## HTTP WebAPI

### 请求头签名

```csharp
// SHA256 签名: timestamp + 密钥 + nonce + timestamp
string signature = SHA256EncryptString(timeStamp + secretKey + nonce + timeStamp);

httpWebRequest.Headers.Add("x-tif-paasid", strIn账户编码);
httpWebRequest.Headers.Add("x-tif-signature", signature);
httpWebRequest.Headers.Add("x-tif-timestamp", timeStamp);
httpWebRequest.Headers.Add("x-tif-nonce", nonce);
```

### 报文封装

```csharp
JObject request = new JObject();
request.Add("infno", bussinessNo);           // "2304" 交易编码
request.Add("msgid", msgid);                 // 报文ID（全局唯一）
request.Add("insuplc_admdvs", 参保地区划);
request.Add("mdtrtarea_admvs", 就医地区划);
request.Add("fixmedins_code", 机构编号);
request.Add("sign_no", signNo);              // 签到序号
request.Add("input", input);                 // 交易输入数据
```

### 核心方法

```csharp
// HttpHelper.YBBusiness() — 通用医保 HTTP 调用
public static Tuple<bool, string> YBBusiness(
    string bussinessNo,      // 交易编码（如 "2304"）
    string bussinessName,    // 交易名称（如 "住院结算"）
    string msgid,            // 报文ID
    string insuplc_admdvs,   // 参保地区划
    string signNo,           // 签到序号
    JObject input,           // 输入数据
    string visit_id,         // 就诊ID（日志用）
    string pt_id,            // 患者ID（日志用）
    string strJson)          // 原始入参
```

---

## 本地医保库 DLL

北京医保使用本地医保库 DLL 进行费用分解和交易确认。

### 费用分解

```csharp
// ClinicPreSwap 中调用
Tuple<bool, string> tupleOutput = MedicareComHelper.Divide(input.OuterXml);
```

### 交易确认

```csharp
// ClinicSwap 中调用
Tuple<bool, string> tupleOutput = MedicareComHelper.TradeAll(...);
```

### 退费分解

```csharp
// ClinicDelSwap 中调用
MedicareComHelper.RefundmentDivideAll(...)
MedicareComHelper.TradeAll(...)
```

---

## SOAP WebService

住院登记和出院信息上传使用 SOAP 协议。

```csharp
// ComeInSwap / LeaveSwap 中调用
Tuple<bool, string> result = MedicareWebHelper.UpInhospInfo(
    YBList.str住院登记信息上传,
    "01-住院登记信息上传",
    requestRY, visit_id, pt_id, strJson);
```

### SOAP 报文格式

```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <UpInhospInfo xmlns="http://tempuri.org/">
      <inJson>
        {"INF_VER":"V1.0","BIZ_TYP":"01","INPUT_DATA":{...}}
      </inJson>
    </UpInhospInfo>
  </soap:Body>
</soap:Envelope>
```

---

## 冲正交易机制

### 触发场景

1. **超时**：HTTP 请求返回 "timed out"
2. **误差过大**：医保中心返回金额与本地计算误差 > 0.1 元

### 冲正流程

```
SettleSwap (2304 住院结算)
    │
    ├─ 调用 HttpHelper.YBBusiness("2304", ...)
    │      ↓
    ├─ 返回超时 / 或误差 > 0.1元
    │      ↓
    └─ 自动调用 HttpHelper.YBBusiness("2601", "冲正交易", ...)
           ↓
           成功 → 弹窗询问是否重试结算
           失败 → 返回错误
```

### 交易编码总表

| 编号 | 名称 | 通信方式 | 调用位置 |
|------|------|----------|----------|
| **1101** | 人员信息获取 | HTTP WebAPI | Frm身份验证 |
| **9001** | 签到 | HTTP WebAPI | SignIn() |
| **2206** | 门诊预结算 | 本地医保库 | ClinicPreSwap |
| **2207** | 门诊结算 | 本地医保库 | ClinicSwap |
| **2208** | 门诊结算撤销 | 本地医保库 | ClinicDelSwap |
| **01** | 住院登记信息上传 | SOAP | ComeInSwap |
| **02** | 出院信息上传 | SOAP | LeaveSwap |
| **2304** | 住院结算 | HTTP WebAPI | SettleSwap |
| **2305** | 住院结算撤销 | HTTP WebAPI | SettleDelSwap |
| **2601** | 冲正交易 | HTTP WebAPI | SettleSwap（超时/误差） |
