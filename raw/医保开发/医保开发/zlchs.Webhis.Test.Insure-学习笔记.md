# zlchs.Webhis.Test.Insure 学习笔记

> 源码路径：`D:\work\his-medical-group\code\HF.CPAPI.Insure\医保接口\zlchs.Webhis.Test.Insure`
> 文档日期：2026-04-08

---

## 1. 项目概述

### 1.1 项目定位

`zlchs.Webhis.Test.Insure` 是 HF.CPAPI.Insure 体系下的**通用医保接口参考实现**。在 `医保接口/` 目录下，与 15 个地区级医保实现（东莞、云南昆明、内蒙古、宁夏、广东、重庆等）并列存放。

它的作用是：

- 作为**新地区医保插件开发的模板/起点**
- 提供**完整的 IInsureInterface 方法实现示例**
- 内置测试工具 UI，方便开发联调

### 1.2 技术栈

| 项目     | 值                                    |
| -------- | ------------------------------------- |
| 项目类型 | Class Library（DLL）                  |
| 目标框架 | .NET Framework 4.7.2                  |
| 程序集名 | `zlchs.Webhis.Test.Insure`          |
| 命名空间 | `zlchs.Webhis.Test.Insure`          |
| UI 框架  | Windows Forms（弹窗式）               |
| 数据库   | PostgreSQL（通过 CPAPI 框架间接访问） |

### 1.3 文件结构

```
zlchs.Webhis.Test.Insure/
├── Cls_Webhis.cs                 # 核心：IInsureInterface 实现（69KB，30+ 方法）
├── Helper.cs                     # 辅助：Oracle 操作（已注释）+ 编码转换
├── Models/
│   └── Response.cs               # 统一响应模型 {code, message, data}
├── Frm身份验证.cs                 # UI：患者身份验证弹窗
├── Frm结算方式配置.cs              # UI：结算方式选择弹窗
├── Frm测试工具.cs                 # UI：通用测试/查询工具
├── Properties/AssemblyInfo.cs
└── zlchs.Webhis.Test.Insure.csproj
```

### 1.4 依赖

| DLL                              | 来源         | 用途                              |
| -------------------------------- | ------------ | --------------------------------- |
| `ZLSoft.CHSS.CPAPI.PluginBase` | CPAPI 客户端 | 插件基类、UPTools、PluginsTools   |
| `zlchs.Insure.Interface`       | 公司内部     | `IInsureInterface` 接口定义     |
| `zlchs.Common.Base`            | 公司内部     | `BaseDataHelper`、`LogHelper` |
| `Newtonsoft.Json` v13.0.1      | NuGet        | JSON 序列化                       |

---

## 2. HIS 交互机制

### 2.1 调用方式：反射加载 DLL

**这是最关键的一点**：HIS 系统**不是**通过 HTTP 或 WebSocket 调用医保插件，而是通过 **CPAPI 框架反射加载 DLL，直接调用接口方法**。

```
┌──────────────────────────────────────────────────────────┐
│  HIS 应用系统（B/S 客户端）                                │
│  ↓                                                        │
│  CPAPI 客户端框架（ZLSoft.CHSS.CPAPI）                      │
│  ↓ 反射加载 DLL + 获取 IInsureInterface 实例                │
│  PluginHandle → Assembly.Load → Activator.CreateInstance   │
└──────────────────────┬───────────────────────────────────┘
                       │ 直接方法调用
┌──────────────────────▼───────────────────────────────────┐
│  zlchs.Webhis.Test.Insure.dll                              │
│  Cls_Webhis : IInsureInterface                              │
│  ├── InitInsure(strJson) → bool                            │
│  ├── Identify(strJson)   → string (JSON)                   │
│  ├── ClinicSwap(strJson) → string (JSON)                   │
│  └── ...30+ 方法                                           │
└──────────────────────┬───────────────────────────────────┘
                       │ 框架服务调用
┌──────────────────────▼───────────────────────────────────┐
│  CPAPI 框架服务                                             │
│  ├── BaseDataHelper → UPTools.GetModelYB<T>() 查询数据库     │
│  ├── BaseDataHelper → UPTools.ExteSqlYB()     执行 SQL      │
│  ├── PluginsTools.ExeHttp()                   调 HTTP API   │
│  └── LogHelper                                写日志        │
└──────────────────────┬───────────────────────────────────┘
                       │
                  PostgreSQL
```

### 2.2 数据格式

**入参**：所有方法接收 `string strJson`（JSON 字符串），包含业务参数。

常见入参字段：

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

**出参**：统一 `Response` 模型序列化为 JSON 字符串。

```csharp
// Models/Response.cs
public class Response
{
    public string code { set; get; }      // "1"=成功, "0"=失败
    public string message { set; get; }    // 错误信息
    public object data { set; get; }       // 业务数据（JObject/JArray/null）
}
```

示例返回：

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

### 2.3 注意

- `InitInsure` 返回 `bool`，`EndInsure` 返回 `bool`
- 其余所有方法返回 `string`（JSON）

---

## 3. 关键框架服务

### 3.1 BaseDataHelper — 数据库操作

所有数据库操作都通过 `BaseDataHelper` 封装，底层调用 `UPTools`（CPAPI 框架提供的跨域数据库访问工具）。

```csharp
// 查询（返回 DataTable）
DataTable dt = BaseDataHelper.GetDataTable(
    strJson,           // 原始入参（框架需要的上下文）
    "InitInsure",      // 方法名（日志用）
    "fee",             // 表空间（数据库域）
    sql,               // SQL 语句（@参数占位符）
    param              // Param[] 参数数组
);

// 执行（INSERT/UPDATE/DELETE）
BaseDataHelper.ExteSql(strJson, "DetailUpload", "fee", sql, param);
```

**Param 参数定义**：

```csharp
Param[] param = new Param[2]
{
    new Param { pname = "orgid",  dbtype = 16, value = org_id },   // 16=varchar
    new Param { pname = "insure", dbtype = 12, value = ins_id }    // 12=bigint
};
```

**高级方法**：

```csharp
BaseDataHelper.SaveInsureVisit(siv, strJson);          // 保存就诊记录
BaseDataHelper.SaveInsureVisit(siv, strJson, "2");     // 保存住院就诊记录（类型2）
BaseDataHelper.SaveInsureBalance(sib, strJson);        // 保存结算记录
BaseDataHelper.SavePreSettleInfo(savePre, strJson);    // 保存预结算信息
BaseDataHelper.CheckBalanceWay(settletype, strJson, org_id);  // 校验结算方式
BaseDataHelper.RefondBalance(...);                     // 冲负退费
```

### 3.2 PluginsTools — HTTP API 调用

调用 CPAPI 后端 HTTP 接口（如查询患者信息）：

```csharp
string response = PluginsTools.ExeHttp(
    HttpMethod.Post,
    "api/pt/PtInfo/GetPtByKeyword",  // API 路径
    request,                          // 请求对象
    strJson                           // 上下文
);
```

### 3.3 LogHelper — 日志

```csharp
LogHelper log = new LogHelper();
log.ProjectName = "WebHisInsureLog";  // 日志文件前缀
log.WriteLog("[初始化]方法入参:" + strJson);
log.WriteLog("测试日志:预结算入参:" + strJson);
```

### 3.4 WinForms ShowDialog — UI 弹窗

项目用 `ShowDialog()` 阻塞式弹窗与用户交互，这是医保结算流程中**用户确认环节**的标准实现方式。

| 弹窗                | 调用时机                                                            | 返回值                                                                |
| ------------------- | ------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `Frm身份验证`     | `Identify()`                                                      | `result`（JSON 响应字符串）                                         |
| `Frm结算方式配置` | `ClinicPreSwap`, `ClinicSwap`, `WipeoffMoney`, `SettleSwap` | `result`(成功码), `settle_type`(JArray), `qrcode`, `pre_flag` |
| `Frm测试工具`     | `InterfaceTools(function_no="1000")`                              | 无（工具窗口）                                                        |

---

## 4. 接口方法清单

### 4.1 已实现（有实际业务逻辑）

| 分组               | 方法               | 说明                                                 |
| ------------------ | ------------------ | ---------------------------------------------------- |
| **初始化**   | `InitInsure`     | 查询 `insur.ins_org_vs` 获取机构代码               |
| **初始化**   | `EndInsure`      | 直接返回 true                                        |
| **身份验证** | `Identify`       | 弹出 `Frm身份验证`，返回患者信息                   |
| **身份验证** | `IdentifyCancel` | 返回成功                                             |
| **余额**     | `SelfBalance`    | 返回硬编码余额（测试）                               |
| **打标**     | `ItemMarking`    | 查询 `b_fee_item`/`b_drug`，弹窗确认是否医保报销 |
| **费用**     | `DetailUpload`   | 更新 `ins_fee_detail.ins_submit=1`                 |
| **门诊**     | `ClinicPreSwap`  | 查档案→保存就诊→弹窗配置结算方式→返回             |
| **门诊**     | `ClinicSwap`     | 查就诊记录→弹窗→保存结算记录→返回                 |
| **门诊**     | `ClinicDelSwap`  | 冲负处理（最复杂：查原记录→关联共济→冲负/删除）    |
| **住院**     | `ComeInSwap`     | 查档案→保存就诊记录→弹窗确认→返回                 |
| **住院**     | `ComeInDelSwap`  | 回退费用 `ins_submit=0` + 删除就诊记录             |
| **住院**     | `ModiPatiSwap`   | 更新床位号 `bed_no`                                |
| **住院**     | `LeaveSwap`      | 保存出院信息（`exinfo` 存为 JSON）                 |
| **住院**     | `LeaveDelSwap`   | 撤销出院                                             |
| **住院结算** | `WipeoffMoney`   | 查档案→弹窗→保存预结算信息                         |
| **住院结算** | `SettleSwap`     | 查就诊→弹窗→保存结算记录                           |
| **住院结算** | `SettleDelSwap`  | 冲负退费（类似 ClinicDelSwap）                       |
| **工具**     | `InterfaceTools` | 按 `function_no` 弹出不同工具窗口                  |

### 4.2 占位（返回 `code=1` 无逻辑）

`SignIn`, `SignOut`, `DetailUploadDel`, `BusinessConfirm`, `CaseUpload`, `CaseUploadDel`, `CatalogDownload`, `CatalogUpload`, `DepartmentDownload`, `DepartmentUpload`, `DiagnosisDownload`, `DoctorDownload`, `DoctorRegist`, `DoctorUpload`, `InsureCheck`, `MedRecordUpload`, `MedRecordUploadDel`, `RegistSwap`, `RegistDelSwap`

---

## 5. 核心业务流程

### 5.1 门诊结算完整流程

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

### 5.2 住院结算完整流程

```
HIS 入院 → ComeInSwap (住院登记)
             ├─ 查档案 → 保存就诊记录(type=2) → 弹窗确认
             └─ 返回 {ins_card_no, patient_insur_type}
                │
HIS 修改 → ModiPatiSwap (修改登记)
             └─ 更新 ins_visit.bed_no
                │
HIS 费用 → DetailUpload (明细上传)
             └─ 更新 ins_fee_detail.ins_submit = 1
                │
HIS 出院 → LeaveSwap (出院登记)
             └─ 保存出院信息到 ins_visit.exinfo
                │
HIS 预算 → WipeoffMoney (住院预结算)
             ├─ 查档案 → 弹窗配置结算方式
             ├─ SavePreSettleInfo（保存预结算信息）
             └─ 返回 {settle_type, defult_settle_type, is_split}
                │
HIS 结算 → SettleSwap (住院结算)
             ├─ 查就诊记录 → 弹窗确认
             ├─ SaveInsureBalance（保存结算记录）
             └─ 返回 {settle_type, patient_insur_type}
                │
HIS 退费 → SettleDelSwap (结算作废)
             └─ 冲负退费逻辑
                │
HIS 撤销 → ComeInDelSwap (撤销住院)
             ├─ 回退费用: ins_fee_detail.ins_submit = 0
             └─ 删除就诊记录: DELETE ins_visit
```

---

## 6. 数据库表结构

### 6.1 核心表

| 表名                       | 说明         | 关键字段                                                                                                                                         |
| -------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `insur.ins_org_vs`       | 机构对应关系 | `ins_id`, `org_id`, `ins_code`                                                                                                             |
| `insur.ins_archive`      | 医保个人档案 | `ins_card_no`, `name`, `sex_name`, `id_card_no`, `birthday`                                                                            |
| `insur.ins_archive_vs`   | 档案关联     | `ins_id`, `ins_card_no`, `pt_id`（患者ID↔医保卡号）                                                                                       |
| `insur.ins_visit`        | 就诊记录     | `ins_id`, `visit_id`, `pt_id`, `ins_card_no`, `pt_name`, `pt_sex_name`, `id_card_no`, `bed_no`, `exinfo`(JSON), `visit_time` |
| `insur.ins_balance`      | 结算记录     | `balance_id`, `ins_id`, `org_id`, `pt_id`, `ins_no`, `settle_type`(JArray), `swapinfo`(JSON)                                       |
| `insur.ins_balance_info` | 结算明细     | 多条支付方式记录（冲负时插入负数金额）                                                                                                           |
| `insur.ins_fee_detail`   | 费用明细     | `fee_detail_id`, `ins_submit`(0/1)                                                                                                           |

### 6.2 HIS 关联表

| 表名                       | 说明                                |
| -------------------------- | ----------------------------------- |
| `qw_base.b_fee_item`     | 费用项目基础数据（code, name）      |
| `qw_base.b_drug`         | 药品基础数据                        |
| `public.pt_balance`      | 患者结算主表                        |
| `public.outp_fee_detail` | 门诊费用明细（关联 ins_fee_detail） |

### 6.3 关联关系

```
患者(pt_id) ──┬── ins_archive_vs ── ins_archive (医保档案)
              ├── ins_visit (就诊记录)
              ├── ins_balance (结算记录) ── ins_balance_info (结算明细)
              └── ins_fee_detail (费用明细) ── outp_fee_detail (HIS 费用)
```

---

## 7. 对上海五期插件的借鉴意义

### 7.1 可直接复用的模式

| 模式                              | 说明                                                         | 对应我们的实现                                                        |
| --------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------- |
| **Response 模型**           | `{code, message, data}` 统一返回格式                       | 已在 `Cls_SHXBYB.cs` 中实现 `BuildSuccessResult/BuildErrorResult` |
| **BaseDataHelper 调用方式** | `GetDataTable(strJson, funcName, tableSpace, sql, params)` | 上海五期可直接使用，参数模式相同                                      |
| **SaveInsureVisit/Balance** | 封装好的就诊/结算保存方法                                    | 直接调用，传入对应数据模型                                            |
| **Param 参数化查询**        | `new Param { pname, dbtype, value }` 防 SQL 注入           | 必须使用此模式                                                        |
| **LogHelper 日志**          | `log.ProjectName + log.WriteLog()`                         | 已采用                                                                |
| **初始化模式**              | `InitInsure` 从 `insur.ins_org_vs` 查机构代码            | 可复用查询逻辑                                                        |

### 7.2 需要调整的部分

| 差异点                 | Webhis.Test 的做法                        | 上海五期的做法                                             |
| ---------------------- | ----------------------------------------- | ---------------------------------------------------------- |
| **医保中心通信** | 不直接调医保中心（测试项目，模拟返回）    | 通过 `SendRcv4.dll` P/Invoke 调用上海医保中心            |
| **业务逻辑层次** | `IInsureInterface` 方法内直接写全部逻辑 | 分为 Handler 层（单接口）+ IInsureInterface 层（流程编排） |
| **结算方式**     | 弹窗让用户手动配置                        | 根据医保中心返回自动计算                                   |
| **UI 弹窗**      | 大量 `ShowDialog()` 阻塞弹窗            | 减少弹窗，数据尽量从医保中心获取                           |
| **通信层**       | 无（测试项目不调外部接口）                | `MedicalInsuranceClient.Send()` 统一封装报文外壳 + 日志  |

### 7.3 关键结论

1. **IInsureInterface 是 HIS 调医保的唯一入口**。HIS 不关心医保中心的通信细节，只调接口方法、收 JSON 返回。
2. **BaseDataHelper + UPTools 是数据库操作的标准方式**，不要自己建 DB 连接。
3. **insur.* 表结构是公司统一标准**（ins_archive, ins_visit, ins_balance 等），上海五期必须写入相同的表。
4. **strJson 透传很重要**——`BaseDataHelper.GetDataTable(strJson, ...)` 的第一个参数 `strJson` 包含框架需要的上下文信息（org_id 等），必须原样传递。
