# 医保数据库表结构

> 原始资料：[zlchs.Webhis.Test.Insure 学习笔记](../../raw/医保开发/医保开发文档/zlchs.Webhis.Test.Insure-学习笔记.md)、[HIS5.0 北京医保代码走查](../../raw/医保开发/医保开发文档/HIS-5.0医保总控-北京医保中心-代码走查.md)

---

## 核心表关系

```
insur.ins_system
  │
  ├─ insur.ins_org_vs              ← 机构与医保系统的对照关系
  │
  ├─ insur.ins_initial             ← 医保参数配置（接口地址、密钥、区划代码等）
  │
  ├─ insur.ins_archive             ← 参保人员档案
  │   └─ insur.ins_archive_vs      ← 患者与档案的绑定关系
  │
  ├─ insur.ins_item                ← 医保项目目录
  │   └─ insur.ins_item_vs         ← HIS 费用项目与医保目录对照
  │
  ├─ insur.ins_dept_compare        ← 科室对照
  │
  ├─ insur.ins_fee_detail          ← 费用明细提交状态
  │
  ├─ insur.ins_visit               ← 就诊记录（rec_type: 1=门诊, 2=住院）
  │   └─ insur.ins_balance         ← 结算记录
  │       └─ insur.ins_balance_info ← 结算支付方式明细
  │
  ├─ insur.ins_log                 ← 接口交易日志
  │
  └─ insur.ins_dictionary          ← 医保字典
```

---

## 配置类表

### insur.ins_system

医保系统配置表，决定加载哪个 DLL。

| 字段 | 说明 |
|------|------|
| `id` | 医保系统 ID（如 "001"、"002"） |
| `name` | 医保系统名称 |
| `interface_name` | DLL 程序集名称（如 `zlchs.BJ.XBYB.insure`） |

### insur.ins_org_vs

机构与医保系统的对照关系。

| 字段 | 说明 |
|------|------|
| `ins_id` | 医保系统 ID |
| `org_id` | 机构 ID |
| `ins_code` | 机构在医保系统中的编码 |

### insur.ins_initial

医保参数配置表，存储接口地址、密钥等。

| 字段 | 说明 |
|------|------|
| `ins_id` | 医保系统 ID |
| `org_id` | 机构 ID |
| `name` | 参数名（如 "接口地址"、"账户编码"、"账户密钥"） |
| `value` | 参数值 |

---

## 患者档案类表

### insur.ins_archive

参保人员档案。

| 字段 | 说明 |
|------|------|
| `ins_id` | 医保系统 ID |
| `ins_card_no` | 医保卡号 |
| `name` | 姓名 |
| `sex_name` | 性别 |
| `id_card_no` | 身份证号 |
| `birthday` | 出生日期 |
| `swap_info` | 扩展信息（JSON，含余额等） |

### insur.ins_archive_vs

患者与医保档案的绑定关系。

| 字段 | 说明 |
|------|------|
| `ins_id` | 医保系统 ID |
| `ins_card_no` | 医保卡号 |
| `pt_id` | 患者 ID（HIS 内部患者标识） |

---

## 就诊结算类表

### insur.ins_visit

就诊记录。

| 字段 | 说明 |
|------|------|
| `ins_id` | 医保系统 ID |
| `visit_id` | 就诊/事件 ID |
| `pt_id` | 患者 ID |
| `ins_card_no` | 医保卡号 |
| `pt_name` | 患者姓名 |
| `pt_sex_name` | 性别 |
| `id_card_no` | 身份证号 |
| `bed_no` | 床位号（住院用） |
| `exinfo` | 扩展信息（JSON） |
| `visit_time` | 就诊时间 |
| `rec_type` | 记录类型：1=门诊，2=住院 |

### insur.ins_balance

结算记录。

| 字段 | 说明 |
|------|------|
| `balance_id` | 结算 ID |
| `ins_id` | 医保系统 ID |
| `org_id` | 机构 ID |
| `pt_id` | 患者 ID |
| `ins_no` | 医保号 |
| `settle_type` | 结算方式（JArray） |
| `swapinfo` | 结算信息（JSON，含医保返回完整数据） |

### insur.ins_balance_info

结算支付方式明细（多条记录）。

| 字段 | 说明 |
|------|------|
| `balance_id` | 结算 ID |
| `balance_name` | 支付方式名称（如 "账户支付"、"个人现金"） |
| `balance_charge` | 支付金额 |

> 冲负场景会插入负数金额记录。

### insur.ins_fee_detail

费用明细提交状态。

| 字段 | 说明 |
|------|------|
| `fee_detail_id` | 费用明细 ID |
| `ins_submit` | 提交状态：0=未提交，1=已提交 |
| `ins_item_code` | 医保项目编码 |
| `ins_info` | 医保相关信息 |

---

## 目录对照类表

### insur.ins_item / insur.ins_item_vs

| 表 | 说明 |
|----|------|
| `insur.ins_item` | 医保项目目录（国家/地区医保局发布的标准目录） |
| `insur.ins_item_vs` | HIS 费用项目与医保目录对照关系 |

### insur.ins_dept_compare

科室对照表。

---

## 日志字典类表

### insur.ins_log

接口交易日志，记录与医保中心的每一次交互。

### insur.ins_dictionary

医保字典（码表）。

---

## HIS 关联表

| 表名 | 说明 |
|------|------|
| `qw_base.b_fee_item` | 费用项目基础数据（code, name） |
| `qw_base.b_drug` | 药品基础数据 |
| `public.pt_balance` | 患者结算主表 |
| `public.outp_fee_detail` | 门诊费用明细（关联 ins_fee_detail） |

---

## 关联关系汇总

```
患者(pt_id) ──┬── ins_archive_vs ── ins_archive (医保档案)
              ├── ins_visit (就诊记录)
              │   ├── rec_type=1 → 门诊
              │   └── rec_type=2 → 住院
              ├── ins_balance (结算记录) ── ins_balance_info (结算明细)
              └── ins_fee_detail (费用明细) ── outp_fee_detail (HIS 费用)
```

## 数据操作模式

### 查询

```csharp
DataTable dt = BaseDataHelper.GetDataTable(
    strJson,           // 原始入参（框架需要的上下文）
    "InitInsure",      // 方法名（日志用）
    "fee",             // 表空间（数据库域）
    sql,               // SQL 语句（@参数占位符）
    param              // Param[] 参数数组
);
```

### 执行

```csharp
BaseDataHelper.ExteSql(strJson, "DetailUpload", "fee", sql, param);
```

### 参数定义

```csharp
Param[] param = new Param[2]
{
    new Param { pname = "orgid",  dbtype = 16, value = org_id },   // 16=varchar
    new Param { pname = "insure", dbtype = 12, value = ins_id }    // 12=bigint
};
```

### 高级封装方法

| 方法 | 说明 |
|------|------|
| `SaveInsureVisit(siv, strJson)` | 保存就诊记录 |
| `SaveInsureVisit(siv, strJson, "2")` | 保存住院就诊记录（类型2） |
| `SaveInsureBalance(sib, strJson)` | 保存结算记录 |
| `SavePreSettleInfo(savePre, strJson)` | 保存预结算信息 |
| `CheckBalanceWay(settletype, strJson, org_id)` | 校验结算方式 |
| `RefondBalance(...)` | 冲负退费 |
