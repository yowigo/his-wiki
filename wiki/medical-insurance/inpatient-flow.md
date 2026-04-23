# 住院结算完整流程

> 原始资料：[zlchs.Webhis.Test.Insure 学习笔记](../../raw/医保开发/医保开发文档/zlchs.Webhis.Test.Insure-学习笔记.md)、[HIS5.0 北京医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md)

---

## 业务类型

| 编码 | 名称 | 对应方法 |
|------|------|----------|
| `1201` | 住院选择保险 | `HospitalChoseInsure()` |
| `1202` | 入院登记 | `HospitalIn()` |
| `1203` | 住院补登记 | `HospitalSupplement()` |
| `1204` | 住院取消保险 | `HospitalCancelInsure()` |
| `1205` | 住院信息变更 | `HospitalInfoChange()` |
| `1206` | 住院医保项目打标 | `HospitalInsureItemCheck()` |
| `1207` | 住院费用明细上传 | `HospitalDetailUpload()` |
| `1208` | 住院费用明细撤销 | `HospitalDetailCancel()` |
| `1209` | 出院登记 | `HospitalOut()` |
| `1210` | 撤销出院 | `HospitalOutCancel()` |
| `1211` | 住院结算 | `HospitalSettle()` |
| `1212` | 住院取消结算 | `HospitalSettleBack()` |
| `1213` | 住院更新病种 | `HospitalModiDisease()` |
| `1219` | 住院预结算 | `HospitalPreSettle()` |

---

## 一、住院登记 (1202)

### 流程

```
HIS 入院 → ComeInSwap (住院登记)
    │
    ├─ 1. 查询 insur.ins_archive（患者医保档案）
    ├─ 2. 查询住院信息、科室对照、诊断信息
    ├─ 3. 构建上传数据（CASE_CODE, INHOSP_DATE, ATT_DOCT_CODE, PRI_DIAG_CODE...）
    ├─ 4. 🔗 SOAP WebService — 住院登记信息上传（UpInhospInfo）
    │      协议: SOAP 1.1, BIZ_TYP = "01"
    │      响应: RESULT_STATE = "0000" 成功
    └─ 5. INSERT insur.ins_visit (rec_type=2)
           返回 {ins_card_no, patient_insur_type}
```

### 关键代码

```csharp
public string ComeInSwap(string strJson)
{
    // 阶段1: 查询档案、住院信息、科室对照、诊断
    dt_dangan = DataHelpers.QueryPatientInfo(insureSystem, patientID, strJson);
    dt_zhuyuan = DataHelpers.QueryHospitalInfo(...);
    dt_dept = DataHelpers.QueryDeptCompare(...);
    dt_diag = DataHelpers.QueryDiagnosis(...);

    // 阶段2: 构建上传数据
    JObject requestRY = new JObject();
    requestRY.Add("CASE_CODE", caseCode);
    requestRY.Add("INHOSP_DATE", inhospDate);
    requestRY.Add("ATT_DOCT_CODE", attendDoctorCode);
    requestRY.Add("PRI_DIAG_CODE", primaryDiagnosisCode);
    // ...

    // 阶段3: 🔗 SOAP WebService — 住院登记信息上传
    Tuple<bool, string> result1 = MedicareWebHelper.UpInhospInfo(
        YBList.str住院登记信息上传, "01-住院登记信息上传",
        requestRY, visit_id, pt_id, strJson);

    // 阶段4: INSERT insur.ins_visit (rec_type=2)
    SaveInsureVisit siv = new SaveInsureVisit();
    siv.ins_id = long.Parse(ins_id);
    siv.pt_id = pt_id;
    siv.visit_id = visit_id;
    siv.rec_type = "2";  // 住院
    BaseDataHelper.SaveInsureVisit(siv, strJson);

    return Response(code:"1", data: new { ins_card_no, patient_insur_type });
}
```

---

## 二、住院费用明细上传 (1207)

### 流程

```
HIS 费用 → DetailUpload (明细上传)
    │
    ├─ 1. 查询未提交的费用明细
    │      SELECT * FROM insur.ins_fee_detail WHERE fee_detail_id = @id AND ins_submit=0
    │
    └─ 2. 标记为已提交
           UPDATE insur.ins_fee_detail SET ins_submit = 1 WHERE fee_detail_id = @id
```

### 关键代码

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

---

## 三、住院预结算 (1219)

### 流程

```
HIS 预算 → WipeoffMoney (住院预结算)
    │
    ├─ 1. 查询 insur.ins_archive（患者医保档案）
    ├─ 2. Frm结算方式配置.ShowDialog()（用户配置结算方式）
    ├─ 3. SavePreSettleInfo（保存预结算信息）
    └─ 4. 返回 {settle_type, defult_settle_type, is_split}
```

---

## 四、住院正式结算 (1211)

### 流程（最复杂）

```
HIS 结算 → SettleSwap (住院结算)
    │
    ├─ 1. 查询档案 + 就诊记录 + 预结记录
    ├─ 2. 构建请求（psn_no, mdtrt_id, medfee_sumamt, insutype...）
    │
    ├─ 3. 🔗 HTTP WebAPI — 住院结算 (2304)
    │      SHA256 签名, x-tif-* 请求头
    │
    ├─ 4. 超时冲正
    │      如果返回 "timed out" → 🔗 冲正交易 (2601)
    │      → 成功则弹窗询问是否重试结算
    │
    ├─ 5. 医保误差检查 > 0.1元 → 自动冲正
    │      → 🔗 冲正交易 (2601)
    │
    └─ 6. INSERT insur.ins_balance
           返回结算结果
```

### 关键代码

```csharp
public string SettleSwap(string strJson)
{
    // 阶段1: 查询档案 + 就诊记录 + 预结记录
    dt_dangan = DataHelpers.QueryPatientInfo(insureSystem, patientID, strJson);
    dt_jiuzhen = DataHelpers.QueryMedicalRecordsZY(patientID, insureSystem, visitId, strJson);

    // 阶段2: 构建请求
    JObject request2304 = new JObject();
    request2304.Add("psn_no", psnNo);
    request2304.Add("mdtrt_id", mdtrtId);
    request2304.Add("medfee_sumamt", medfeeSumamt);
    request2304.Add("insutype", insutype);
    // ...

    // 阶段3: 🔗 HTTP WebAPI — 住院结算
    Tuple<bool, string> result2303 = HttpHelper.YBBusiness(
        YBList.str住院结算, "住院结算", msgid,
        strIn参保地医保区划, signNo, request2304,
        visit_id, pt_id, strJson);

    // 阶段4: 超时冲正
    if (strMsg.Contains("timed out"))
    {
        HttpHelper.YBBusiness(YBList.str冲正交易, "冲正交易", ...);  // 2601
        // → 弹窗询问是否重试
    }

    // 阶段5: 医保误差检查 > 0.1元 → 自动冲正
    if (dc医保误差 > 0.1m)
    {
        HttpHelper.YBBusiness(YBList.str冲正交易, "冲正交易", ...);  // 2601
    }

    // 阶段6: INSERT insur.ins_balance
    SaveInsureBalance sib = new SaveInsureBalance();
    sib.balance_id = long.Parse(balance_id);
    sib.ins_id = long.Parse(ins_id);
    sib.settle_type = settletype;
    sib.swapinfo = resultJson;
    BaseDataHelper.SaveInsureBalance(sib, strJson);

    return Response(code:"1", data: new { settle_type, patient_insur_type });
}
```

---

## 五、住院结算作废 (1212)

### 流程

```
HIS 退费 → SettleDelSwap (结算作废)
    │
    ├─ 1. 查询原结算记录（insur.ins_balance）
    ├─ 2. 🔗 HTTP WebAPI — 住院结算撤销 (2305)
    └─ 3. 冲负处理
           ├── 有退账ID → RefondBalance() 冲负
           └── 无退账ID → DELETE ins_balance / ins_balance_info
```

---

## 六、撤销住院 (1204)

### 流程

```
HIS 撤销 → ComeInDelSwap (撤销住院)
    │
    ├─ 1. 回退费用: UPDATE ins_fee_detail SET ins_submit = 0
    └─ 2. 删除就诊记录: DELETE FROM insur.ins_visit WHERE visit_id = @id
```

---

## 七、住院流程总览

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
