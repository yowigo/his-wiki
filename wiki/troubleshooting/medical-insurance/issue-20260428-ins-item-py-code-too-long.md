---
title: DB-20260428-INS-001 - 导入医保目录时 py_code 字段长度不足
date: 2026-04-28
author: Keiskei
tags:
  - troubleshooting
  - medical-insurance
  - database
  - import
aliases:
  - ins_item py_code varchar(20) 超长
  - 导入医保目录 22001 错误
status: pending-fix
---

# DB-20260428-INS-001 - 导入医保目录时 py_code 字段长度不足

## 故障概述

- **故障编号**: DB-20260428-INS-001
- **排查日期**: 2026-04-28
- **影响范围**: 医保目录导入功能（`Plugins.MedicalMatch`）
- **影响用户**: 使用"导入医保目录"功能的操作员
- **表现形式**: 导入 Excel 医保目录时报错，部分行写入失败
- **处理状态**: 已定位根因，待 DBA 执行 DDL 扩容

## 现象描述

在 `Plugins.MedicalMatch` 的导入医保目录功能中，点击导入按钮后，控制台报错：

```
[Info]查询异常:22001: value too long for type character varying(20)
```

## 根因分析

`insur.ins_item.py_code` 字段定义为 `varchar(20)`，但导入的 Excel 数据中存在拼音码长度超过 20 字符的记录，触发 PostgreSQL 22001 错误（string_data_right_truncation），导致该行 INSERT 失败。

**代码位置**：`Plugins.MedicalMatch/ImportFrm.cs` 第 85-86 行，INSERT 写入 `insur.ins_item` 表。

## 修复方案

由 DBA 执行以下 DDL 扩容：

```sql
ALTER TABLE insur.ins_item ALTER COLUMN py_code TYPE varchar(50);
```

扩容幅度可根据实际数据中 `py_code` 最大长度决定，建议至少改为 `varchar(50)`。

## 预防措施

导入前可在应用层对 `py_code` 做截断或预校验，超长时给出明确提示，而不是直接报数据库异常。
