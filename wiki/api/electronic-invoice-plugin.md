# 北京电子票据插件（Plugins.EB_BJElectronicBills）

> 原始资料：`../../raw/外部接口开发/北京电子票据/`（接口规范 V1.28、报文 0101/0103、表结构、实现摘要、快速参考、流程说明）
> 实现位置：`D:\work\his-medical-group\code\Plugins.EB_BJElectronicBills\`
> 关联页面：[插件开发模板](plugin-development.md)、[电子票据故障案例](../troubleshooting/electronic-invoice/issue-kingdee-duplicate-serialno.md)

## 一、整体架构

```
HIS工作站
  │
  ├─ 手动操作 ──→ BillQueryForm（查询界面）
  │                  ├─ 查询票据列表（QueryBillData）
  │                  ├─ 批量上传（UploadBills）
  │                  └─ 查询状态（0304→0305 自动衔接）
  │
  ├─ 接口调用 ──→ ProcessRequest（func_sign 路由）
  │                  ├─ 0301  医保票据上传
  │                  ├─ 0303  自费票据上传
  │                  ├─ 0304  查询结算清单生成状态
  │                  ├─ 0305  获取结算清单文件
  │                  ├─ QueryAndGetSettlement（0304+0305 一步完成）
  │                  └─ 0302（兼容旧入口 → 自动转 QueryAndGetSettlement）
  │
  └─ 定时器 ────→ ProcessPendingSettlements（批量轮询，自动完成未处理记录）
```

## 二、报文接口说明

| 报文编号 | 名称 | 方向 | 说明 |
| --- | --- | --- | --- |
| 0101 | 未医保结算门诊交易上传 | HIS → 医保 | 门诊结算流水上传 |
| 0103 | 住院费用结算上传 | HIS → 医保 | 住院结算流水上传 |
| 0301 | 医保电子票据信息上传 | HIS → 医保 | 医保结算后上传电子发票 PDF |
| 0302 | ~~电子票据状态查询~~ | - | **V1.28 已废弃**，自动转为 0304+0305 |
| 0303 | 全自费电子票据信息上传 | HIS → 医保 | 自费结算后上传电子发票 PDF |
| 0304 | 结算清单生成状态查询 | HIS → 医保 | 查询清单是否生成完成，获取 `ELEC_SSR_CODE` |
| 0305 | 结算清单文件获取 | HIS → 医保 | 用 `ELEC_SSR_CODE` 拉取结算清单 PDF |

## 三、核心流程

### 流程 1：票据上传（0301 / 0303）

传 `billNo`（结算记录 ID）：

1. `GetBillDetail`：从 `pt_balance` 查结算记录，未找到报错；
2. `GetInvoicePdfBase64`：优先 `nn_invoiceresult.pdfurl`（URL → HTTP 下载转 Base64；已是 Base64 直接用），都没有报错「未找到电子发票PDF数据」；
3. 判断结算类型：医保（`ins_id` 非空）→ 0301；自费（`ins_id` 空）→ 0303；
4. `HIS_BIZ_NO` 为空自动生成（10 位院区编码+时间戳+序号）；
5. SM4 加密 → HTTP POST → SM4 解密响应；
6. `RecordUploadLog` 写 `elect_bill_upload_log`（`upload_status`=1 成功 / 0 失败，`process_status`=-1 未处理）。

入参：简单模式只传 `{"billNo":"12345"}` 自动组装；完整模式传 0301/0303 完整 JSON。

### 流程 2：查询状态并获取清单（QueryAndGetSettlement，最常用）

0304+0305 自动衔接一次完成：

1. 传 billNo → 查 HIS_BIZ_NO（记录不存在 →「未找到结算记录」；未上传 →「请先完成上传再查询状态」）；
2. 调 0304 查状态，更新 `last_query_time`；
3. 判断 `BIZ_STATUS`：`"0"` 处理中 → 稍后再试；`"1"` 但 ELEC_SSR_CODE 空 → 联系医保中心；`"1"` 且有码 → 继续；
4. 调 0305 获取文件 → 保存本地 `ElectBills/{HIS_BIZ_NO}/*.pdf` + 写 `elect_bill_settlement`（防重复）；
5. 更新 `elect_bill_upload_log`：`process_status`=1、`settlement_data_count`=N。

### 流程 3：UI 界面（BillQueryForm）

查询票据列表（票据号/患者/金额/上传状态/处理状态）→ 批量上传（逐条按结算类型自动选 0301/0303，返回成功/失败计数+原因）→ 查询状态（未上传前置拦截不发请求）。

### 流程 4：定时批量轮询（ProcessPendingSettlements）

HIS 定时器（建议 30~60 秒）调 `ProcessPendingSettlements`：

- 查 `upload_status=1` 且 `process_status IN (-1,0)` 且 `last_query_time + pollingInterval < NOW()` 的记录；
- 逐条 0304 → 已完成+有码 → 0305 → 保存 → 标记完成；未完成仅更新 last_query_time；异常记失败跳过。
- 入参示例：`{"pollingIntervalSeconds": 30}`。

## 四、数据库表结构

### elect_bill_upload_log（上传记录表，insur schema）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | BIGSERIAL | 自增主键 |
| balance_id | BIGINT | 关联 `pt_balance.id` |
| his_biz_no | VARCHAR(30) | 医院业务流水号（唯一） |
| trade_no / bill_no | VARCHAR | 医保交易流水号 / 票据号 |
| settlement_type | VARCHAR(20) | 医保/自费 |
| msg_type | VARCHAR(10) | 0301/0303 |
| upload_status | SMALLINT | -1失败, 0未上传, 1成功 |
| upload_time | TIMESTAMP | 上传时间 |
| process_status | SMALLINT | -1未处理, 0处理中, 1已完成 |
| process_time / last_query_time | TIMESTAMP | 处理完成时间 / 最后查询时间（控制轮询频率） |
| settlement_data_count | SMALLINT | 结算清单数量 |

### elect_bill_settlement（结算清单数据表）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| his_biz_no | VARCHAR(30) | 关联 upload_log.his_biz_no |
| settlement_code | SMALLINT | 1门诊/2住院清单/3住院结算单/4特殊病 |
| settlement_name | VARCHAR(100) | 票据名称 |
| settlement_data | TEXT | PDF Base64 |
| create_time | TIMESTAMP | 创建时间 |

**唯一约束**：`(his_biz_no, settlement_code)` 防重复获取。

## 五、SM4 加密通信

所有报文采用 SM4 国密加密（ECB/PKCS7）：

```
请求：明文 = MSG_NO + MSG_TYPE + JSON入参
  → SM4/ECB/PKCS7 加密（密钥取前16字节，UTF8）→ Base64 → 放入请求体 IN_DATA
响应：取 OUT_DATA → Base64 解码 → SM4/ECB/PKCS7 解密
  → 去除 MSG_NO + MSG_TYPE 前缀 → JSON 反序列化
```

## 六、接口兼容性（0302 → 0304+0305）

| 原调用方式 | 现行为 |
| --- | --- |
| `func_sign = "0302"` | 自动转 QueryAndGetSettlement（查询+获取一步完成） |
| `func_sign = "QueryElectBillStatus"` | 同上 |
| 传 `{"billNo":"xxx"}` | 自动查 HIS_BIZ_NO 再走 0304+0305 |
| 传 `{"HIS_BIZ_NO":"xxx"}` | 直接走 0304+0305 |

返回结构新增 `message` 字段，原有字段保持不变。

## 七、核心表速查

| 表 | Schema/域 | 用途 |
| --- | --- | --- |
| `pt_balance` | public/fee | 结算主表（module_source: 1=门诊, 2=住院；ins_id 空/0=自费） |
| `outp_fee_detail` / `inp_fee_detail` | public | 门诊/住院费用明细（invoice_fee 分类） |
| `outp_recipe_detail` | public/outpatient | 处方明细（JSONB，跨域无法直接 JOIN，用 LATERAL） |
| `b_fee_item` / `b_drug` | qw_base | 费用项目/药品字典 |
| `nn_invoiceresult` | insur | 发票结果（取最新 status='2' 记录） |
| `elect_bill_upload_log` / `elect_bill_settlement` | insur | 上传日志 / 结算清单 |
| `ins_balance` | insur | 医保结算（swap_info JSONB 取现金支付金额） |

> 关键限制：fee_detail 无 dosage（从 recipe_detail LATERAL JOIN 取）；无 discharge_take_drug_flag（固定 "0"）；PDF URL 备选顺序 `pdfurl > paperpdfurl > pictureurl`；时间字段可能 VARCHAR 或 TIMESTAMP 需 `TO_CHAR` 转换。

## 八、异常处理要点

| 场景 | 处理 |
| --- | --- |
| 结算记录不存在 | 阻断返回错误 |
| 未上传就查状态 | 前置拦截「请先完成上传」，不发请求 |
| 清单生成中 | 正常返回，等待下次查询 |
| 已生成但获取码为空 | 需人工联系医保中心 |
| PDF 保存失败 / 上传日志写入失败 | 写日志不阻断主流程 |
| 结算清单重复获取 | SQL 层防重复（WHERE NOT EXISTS） |

