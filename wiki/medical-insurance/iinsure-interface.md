# IInsureInterface 接口契约

> 原始资料：[zlchs.Webhis.Test.Insure 学习笔记](../../raw/医保开发/医保开发文档/zlchs.Webhis.Test.Insure-学习笔记.md)、[HIS5.0 北京医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md)

---

## 接口定义

```csharp
public interface IInsureInterface
{
    // 生命周期
    bool InitInsure(string strJson);
    bool EndInsure(string strJson);

    // 认证
    string SignIn(string strJson);
    string SignOut(string strJson);
    string Identify(string strJson);
    string IdentifyCancel(string strJson);

    // 账户
    string SelfBalance(string strJson);

    // 门诊
    string ClinicPreSwap(string strJson);
    string ClinicSwap(string strJson);
    string ClinicDelSwap(string strJson);

    // 住院
    string ComeInSwap(string strJson);
    string ComeInDelSwap(string strJson);
    string ModiPatiSwap(string strJson);
    string LeaveSwap(string strJson);
    string LeaveDelSwap(string strJson);
    string WipeoffMoney(string strJson);
    string SettleSwap(string strJson);
    string SettleDelSwap(string strJson);

    // 费用
    string ItemMarking(string strJson);
    string DetailUpload(string strJson);
    string DetailUploadDel(string strJson);

    // 目录
    string CatalogDownload(string strJson);
    string CatalogUpload(string strJson);
    string DiagnosisDownload(string strJson);

    // 人员科室
    string DoctorDownload(string strJson);
    string DoctorUpload(string strJson);
    string DoctorRegist(string strJson);
    string DepartmentDownload(string strJson);
    string DepartmentUpload(string strJson);

    // 病历
    string MedRecordUpload(string strJson);
    string MedRecordUploadDel(string strJson);
    string CaseUpload(string strJson);
    string CaseUploadDel(string strJson);

    // 对账
    string InsureCheck(string strJson);

    // 业务确认
    string BusinessConfirm(string strJson);

    // 扩展
    string Advance_function(string strJson);
    string InterfaceTools(string strJson);
}
```

---

## 方法分类详解

### 1. 生命周期

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `InitInsure(strJson)` | `bool` | 初始化医保接口，从 `insur.ins_initial` 加载配置 |
| `EndInsure(strJson)` | `bool` | 销毁医保接口 |

**InitInsure 典型实现**：

```csharp
public bool InitInsure(string strJson)
{
    JObject objIn = JObject.Parse(strJson);
    operator_id = objIn.Value<string>("operator_id");
    insureSystem = objIn.Value<string>("ins_id");
    organizationId = objIn.Value<string>("org_id");

    // 查询医保机构编码
    DataTable dtbx = DataHelpers.GetInsure(insureSystem, organizationId, strJson);
    for (int i = 0; i < dtbx.Rows.Count; i++)
    {
        switch (dtbx.Rows[i]["name"].ToString())
        {
            case "接口地址":          strIn接口地址 = dtbx.Rows[i]["value"].ToString(); break;
            case "账户编码":          strIn账户编码 = dtbx.Rows[i]["value"].ToString(); break;
            case "账户密钥":          strIn账户密钥 = dtbx.Rows[i]["value"].ToString(); break;
            // ... 30+ 配置参数
        }
    }
    return true;
}
```

### 2. 身份认证

| 方法 | 说明 |
|------|------|
| `SignIn` | 医保中心签到 |
| `SignOut` | 医保中心签退 |
| `Identify` | 患者身份验证（查医保档案） |
| `IdentifyCancel` | 取消身份验证 |

### 3. 门诊结算

| 方法 | 说明 | 调用链路 |
|------|------|----------|
| `ClinicPreSwap` | 门诊预结算 | 查档案 → 保存就诊 → 费用分解 → 返回结算方式 |
| `ClinicSwap` | 门诊正式结算 | 查就诊 → 交易确认 → 保存结算记录 |
| `ClinicDelSwap` | 门诊结算作废 | 查原结算 → 冲负/删除 |

### 4. 住院结算

| 方法 | 说明 |
|------|------|
| `ComeInSwap` | 入院登记（`rec_type=2`） |
| `ComeInDelSwap` | 撤销入院（回退费用 + 删除就诊记录） |
| `ModiPatiSwap` | 修改住院信息（如更新床位号） |
| `LeaveSwap` | 出院登记 |
| `LeaveDelSwap` | 撤销出院 |
| `WipeoffMoney` | 住院预结算 |
| `SettleSwap` | 住院正式结算 |
| `SettleDelSwap` | 住院结算作废 |

### 5. 费用管理

| 方法 | 说明 |
|------|------|
| `ItemMarking` | 医保项目打标（判断费用是否可医保报销） |
| `DetailUpload` | 费用明细上传（标记 `ins_fee_detail.ins_submit=1`） |
| `DetailUploadDel` | 费用明细撤销（标记 `ins_fee_detail.ins_submit=0`） |

### 6. 目录同步

| 方法 | 说明 |
|------|------|
| `CatalogDownload` | 下载医保项目目录 |
| `CatalogUpload` | 上传本地目录对照 |
| `DiagnosisDownload` | 下载疾病诊断目录 |

### 7. 人员科室

| 方法 | 说明 |
|------|------|
| `DoctorDownload` / `DoctorUpload` | 医护人员信息同步 |
| `DoctorRegist` | 医师注册 |
| `DepartmentDownload` / `DepartmentUpload` | 科室对照同步 |

### 8. 病历

| 方法 | 说明 |
|------|------|
| `MedRecordUpload` / `MedRecordUploadDel` | 病案首页上传/删除 |
| `CaseUpload` / `CaseUploadDel` | 病历信息上传/删除 |

### 9. 对账

| 方法 | 说明 |
|------|------|
| `InsureCheck` | 日/月对账 |

### 10. 扩展

| 方法 | 说明 |
|------|------|
| `Advance_function` | 共济支付等扩展功能 |
| `InterfaceTools` | 辅助工具（按 `function_no` 分发） |

---

## 数据格式

### 入参

所有方法接收 `string strJson`（JSON 字符串），常见字段：

```json
{
  "ins_id": "1",           // 医保系统 ID
  "org_id": "001",         // 机构 ID
  "pt_id": "123",          // 患者 ID
  "visit_id": "456",       // 就诊 ID
  "actual_charge": "500",  // 实际金额
  "balance_id": "789",     // 结算 ID
  "operator_id": "admin",  // 操作员
  "operator_name": "张三"  // 操作员姓名
}
```

### 出参

统一 `Response` 模型序列化为 JSON 字符串：

```csharp
public class Response
{
    public string code { set; get; }      // "1"=成功, "0"=失败
    public string message { set; get; }    // 错误信息
    public object data { set; get; }       // 业务数据（JObject/JArray/null）
}
```

示例：

```json
{
  "code": "1",
  "message": "",
  "data": {
    "settle_type": [
      {"balance_name": "账户支付", "balance_charge": "300"},
      {"balance_name": "个人现金", "balance_charge": "200"}
    ],
    "patient_insur_type": "310",
    "patient_insur_type_name": "职工医保"
  }
}
```

### 返回类型注意

- `InitInsure` 返回 `bool`
- `EndInsure` 返回 `bool`
- 其余所有方法返回 `string`（JSON）

---

## CA 签名接口（HIS5.0 新增）

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

业务类型 `8001-8008` 通过 `CAInterfaceBusiness` 路由到 CA 签名插件。
