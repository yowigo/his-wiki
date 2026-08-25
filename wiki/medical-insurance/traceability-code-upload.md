# 追溯码上传查询模块

> 实现位置：`D:\work\his-medical-group\code\Plugins.EB_traceability_code_BJ\`
> 插件入口：`EB_traceability_code_BJ.ProcessRequest`

---

## 调用方式

通过 HIS 统一事件接口触发，`module_code`，`function_code` 区分场景：

| module_code    | function_code          | 触发场景       |
| -------------- | ---------------------- | -------------- |
| `drug_eisai` | `after_gvdrug`       | 处方发药执行后 |
| `drug_eisai` | `after_batch_gvdrug` | 批量发药执行后 |
| `drug_eisai` | `after_rtdrug`       | 退药执行后     |

---

## 追溯码上传查询模块入参

模块通过 `data` 字段传入业务参数。1920 和 1921 的顶层字段一致，仅 `upload_data` 结构不同。

### 顶层字段（1920 / 1921 通用）

| 字段              | 类型   | 必填 | 说明                                                                                                                                                 |
| ----------------- | ------ | ---- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `business_type` | string | 是   | **1920** = 商品销售（调用医保 0205 上传）；**1921** = 商品销售退货（调用医保 0206 删除）；<br />具体对应的医保交易编号以地区医保文档为准 |
| `token`         | string | 是   | JWT 认证令牌                                                                                                                                         |
| `org_id`        | string | 是   | 机构 ID                                                                                                                                              |
| `dept_id`       | string | 否   | 部门 ID                                                                                                                                              |
| `operator_id`   | string | 是   | 操作员 ID                                                                                                                                            |
| `operator_name` | string | 是   | 操作员姓名                                                                                                                                           |
| `ins_id`        | string | 是   | 保险系统 ID（`insur.ins_system.id`）                                                                                                               |
| `upload_data`   | array  | 是   | 上传明细数组，格式见下方 1920 / 1921 分述                                                                                                            |

### upload_data — 1920 上传（商品销售）

通过 `drug_id` + `no` + `detail_id` 从 HIS 业务表实时查询药品和追溯码数据。

```json
"upload_data": [
    {
        "data_type": "销售环节",
        "io_id": "",
        "bill_type": "",
        "drug_id": "279ca7310465b84a",
        "no": "2606000953",
        "detail_id": "5685133284677240897"
    }
]
```

| 字段          | 类型   | 必填 | 说明                                                           |
| ------------- | ------ | ---- | -------------------------------------------------------------- |
| `data_type` | string | 是   | 环节类型：`"销售环节"` = 发药上传，`"退货环节"` = 退药上传 |
| `io_id`     | string | 否   | 入库/出库 ID，销售环节留空                                     |
| `bill_type` | string | 否   | 单据类型，留空                                                 |
| `drug_id`   | string | 是   | 药品 ID（`qw_base.b_drug.id`）                               |
| `no`        | string | 是   | 费用单据号 / 处方号，关联`outp_fee.no` 和 `drug_give.no`   |
| `detail_id` | string | 是   | 费用明细 ID（`outp_fee_detail.id`）                          |

### upload_data — 1921 删除（商品销售退货）

通过已保存的上传记录 ID 直接定位历史数据，不需重新查询 HIS 业务表。

```json
"upload_data": [
    {
        "data_type": "销售环节",
        "upload_id": "drug.ins_traceability_code_record.id"
    }
]
```

| 字段          | 类型   | 必填 | 说明                                                                                                                                                    |
| ------------- | ------ | ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `data_type` | string | 是   | 环节类型：`"销售环节"` = 发药场景，`"退货环节"` = 退药场景                                                                                          |
| `upload_id` | string | 是   | 上传记录主键，格式`{库名}.{表名}.{id列名}`，指向 `BaseDataHelper.SaveTraceabilityCodeUpload()` 保存的记录，用于反查历史追溯码数据组装 0206 退货入参 |

---

## business_type ↔ 医保接口映射

| business_type | 医保交易编号 | 交易名称     | 说明                        |
| ------------- | ------------ | ------------ | --------------------------- |
| `1920`      | 0205         | 商品销售     | 上传发药追溯码              |
| `1921`      | 0206         | 商品销售退货 | 上传退药追溯码（删除/冲正） |

> ⚠️ 具体对应的医保交易编号以当地区医保文档为准，不同地区不可直接复用。

---

## 处理流程

1. 解析 `upload_data`，遍历每条记录
2. 根据 `no` + `org_id` 查询 `pt_balance` → `outp_fee_detail` 获取结算费用信息
3. 根据 `no` + `drug_id` + `org_id` 查询 `drug_give` + `drug_give_detail` 获取发药明细
4. 根据 `drug_detail_id` 查询 `drug_traceability_code` 获取已扫码追溯码
5. 组装医保 0205/0206 入参 JArray，调用 `YBInsure.YBBusiness()`
6. 调用 `BaseDataHelper.SaveTraceabilityCodeUpload()` 保存上传记录

详细实现见 `BusinessHelper.GiveGrug()`（0205）和 `BusinessHelper.ReturnGrug()`（0206）。

---

## 医保接口调用

```
POST http://ip+端口/ybCommService/v1/func
```

请求体：

```json
{
    "INF_VER": "V1.0",
    "HOSP_CODE": "<insureOrgCode>",
    "MSG_NO": "<msgid>",
    "MSG_TYPE": "0205",
    "IN_DATA": "<SM4加密后的业务数据>"
}
```

`IN_DATA` 明文 = `MSG_NO + MSG_TYPE + input`，再经 SM4 对称加密 + Base64 编码。密钥：`70CE085BB0D94F5E90FDE11E604E85B7`。


---

## 判重与重复上传（2026-08 分析）

> 详细分析：[MI-20260824-INS-002 追溯码上传重复问题分析](../troubleshooting/medical-insurance/issue-20260824-traceability-duplicate-upload.md)

三个地区版本（GZ / SH / BJ）的判重能力差异：

| 版本 | 门诊发药 | 门诊退药 | 住院结账/作废 | 判重方式 |
| --- | --- | --- | --- | --- |
| GZ（基础版） | 有 | 有 | 有（3505A/3506A） | 门诊：查 `ins_traceability_code_record`；住院：批次标记 + 明细判重 + 进程内锁 |
| SH（分化版） | 有 | 有 | 无 | 查 `ins_traceability_code_record`（同 GZ 门诊） |
| BJ（分化版） | **无** | **无** | 无 | **无任何判重** |

重复上传根因：判重逻辑缺失（BJ）或 **check-then-act 竞态窗口**（GZ 门诊/SH：判重→上传→记账非事务，重入/并发可同时通过）；记账失败后重试也会重复。GZ 住院版进程内锁不跨进程，多实例部署仍有缝隙。

修复方向（详见案例页）：

1. BJ 补齐判重；
2. 三版本统一改「**先占坑记账（upload_status=0）→ 上传 → 更新状态（1/-1）**」，消除窗口期；
3. 数据库唯一约束兜底（`(org_id, business_code, no, drug_id, drug_detail_id)` + `ON CONFLICT DO NOTHING`）；
4. 住院锁升级为 PostgreSQL 咨询锁（`pg_advisory_xact_lock`）覆盖多实例；
5. 唯一键是否含「同单同药品多次发药/退药」、平台重复上传报错语义需业务确认。

