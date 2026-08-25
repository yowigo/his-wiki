---
title: MI-20260824-INS-002 - 追溯码上传重复问题分析（GZ/SH/BJ 判重缺陷）
date: 2026-08-24
author: Keiskei
tags:
  - troubleshooting
  - medical-insurance
  - traceability-code
  - dedup
  - concurrency
aliases:
  - 追溯码重复上传
  - ins_traceability_code_record 判重
status: analysis
---

# MI-20260824-INS-002 - 追溯码上传重复问题分析（GZ/SH/BJ 判重缺陷）

> 分析日期：2026-08-24
> 分析对象：`Plugins.EB_traceability_code_GZ` / `Plugins.EB_traceability_code_SH` / `Plugins.EB_traceability_code_BJ`
> 源分析文档：工作区 `D:\work\his-medical-group\code\追溯码上传重复问题分析.md`
> 关联页面：[追溯码流通环节](../../medical-insurance/traceability-code-flow.md)、[追溯码上传查询模块](../../medical-insurance/traceability-code-upload.md)

## 版本定位（用户约定）

- **GZ 是基础版本**，功能与判重机制最完整，作为基准。
- SH / BJ 要么是不完善副本，要么是项目特别分化版，判重能力弱于 GZ（**BJ 完全无判重**）。

## 一、结论摘要

重复上传的根因是**判重逻辑缺失或不原子**：

1. **北京版（BJ）完全没有判重**——同一张发药/退药单的事件重复触发即重复调用平台接口。
2. **广州门诊版、上海版是「先判重、再上传、后记账」的 check-then-act 模式**——判重通过到本地记账完成之间存在时间窗口，并发/重入事件可同时通过判重，各自上传一次。
3. **广州住院版防御最完整**（批次标记 + 明细判重 + 进程内锁），但锁只覆盖单进程；且门诊/退药与 SH/BJ 相同，未做先占坑记账。

## 二、三版本判重能力对比

| 版本 | 定位 | 门诊发药 | 门诊退药 | 住院结账/作废 | 判重方式 |
| --- | --- | --- | --- | --- | --- |
| GZ（基础版） | ✅ 基准版本 | 有 | 有 | 有（3505A/3506A） | 门诊：查 `ins_traceability_code_record`；住院：批次标记 + 明细级判重 + 进程内锁 `InpUploadLock` |
| SH（分化版） | 不完善/项目分化 | 有 | 有 | 无 | 查 `ins_traceability_code_record`（同 GZ 门诊） |
| BJ（分化版） | 不完善/项目分化 | **无** | **无** | 无 | **无任何判重** |

判重查询（GZ/SH 门诊、退药共用）：

```sql
select 1 from public.ins_traceability_code_record t
where t.org_id=@org_id and t.business_code=@business_code
  and t.no=@no and t.drug_id=@drug_id and t.drug_detail_id=@drug_detail_id
  and t.upload_status=1 limit 1
```

## 三、重复上传的根因路径

### 3.1 触发源：事件重复（所有版本共同前提）

HIS 通过插件 `ProcessRequest` 分发事件（`after_gvdrug` 发药 / `after_rtdrug` 退药 / `after_blnc` 结账），以下情况会重复触发同一业务单：

- 操作员重复点击、断网重试、HIS 事件机制重投；
- MessageBox 弹框泵消息导致事件重入（GZ 已有 `ShowMessageBoxSafe` 防御，证明该场景真实存在）；
- 批量发药 details 循环中对同一 `no` 的多次调用；
- 多进程/多实例部署时同一事件被多个进程消费。

### 3.2 路径 A：BJ 版——无判重，事件重复 = 上传重复

BJ 的 BusinessHelper 只有 GiveGrug（0205）和 ReturnGrug（0206），全程不查询「是否已上传」。事件触发两次 → 调用平台两次 → 平台侧同一追溯码重复。

### 3.3 路径 B：GZ 门诊/SH——check-then-act 竞态窗口

时序：

1. 判重查询（无 `upload_status=1` 记录）→ 通过；
2. 组装参数、调用 3505A/0205 上传平台（网络往返，窗口期最大）；
3. 成功后写入 `ins_traceability_code_record`（`upload_status=1`）并 update `drug_traceability_code.upload_status=1`。

若第 1 步与第 3 步之间进入第二个请求（重入/并发），判重查询同样查不到记录 → 重复上传。**判重、上传、记账三步骤无锁、无唯一约束、非事务**。

### 3.4 路径 C：记账失败导致的重试重复

上传平台成功后，若本地保存记录失败（返回 0），下次事件重触发时判重查不到成功记录 → 再次上传。GZ 住院版用「先保存批次标记（drug_id/drug_detail_id='-1'）再存明细」规避；GZ 门诊、SH、BJ 均未处理。

### 3.5 路径 D：多进程穿透进程内锁

GZ 住院版的 `InpUploadLock`/InpUploadingBalances 是 static 进程内 HashSet，只防单进程内并发。HIS 网关/服务多进程或多实例部署时，两个进程可同时对同一 balance_id 判重通过。

## 四、判重设计缺陷汇总

| # | 缺陷 | 影响 | 涉及版本 |
| --- | --- | --- | --- |
| 1 | 无判重 | 事件重复即上传重复 | BJ |
| 2 | check-then-act 竞态窗口 | 并发/重入时双上传 | GZ 门诊、SH |
| 3 | 记账在平台上送之后，无占坑 | 记账失败→重试重复；窗口期放大 | GZ 门诊、SH、BJ |
| 4 | 无数据库唯一约束兜底 | 第二写无法被 DB 拒绝 | 全部 |
| 5 | 进程内锁不跨进程 | 多实例下住院也重复 | GZ 住院 |
| 6 | 判重 key 不含 balance_id | 门诊场景一般够用；住院若沿用会跨结账误判（GZ 住院已改用 balance_id+business_code，正确） | 门诊/退药逻辑 |

## 五、修复建议（按优先级）

1. **BJ 补齐判重**：照抄 GZ/SH 的 `IsTraceabilityCodeUploaded`，在组装/上传前按 (org_id, business_code, no, drug_id, drug_detail_id) 判重。
2. **改为「先占坑记账、后上传、再更新状态」**（推荐，三个版本统一）：
   - 上传前先写入 `ins_traceability_code_record`（`upload_status=0` / 「上传中」），
   - 再调平台，成功后 update `upload_status=1`、失败 update `-1` 并写错误信息；
   - 并发第二次请求判重时看到「上传中/已成功」记录即跳过，窗口期消失。
3. **数据库唯一约束兜底**：

   ```sql
   -- 建议（按业务确认唯一键，销售/退货用 business_code 区分）
   create unique index ux_trace_record_uniq
   on public.ins_traceability_code_record (org_id, business_code, no, drug_id, drug_detail_id);
   ```

   保存用「存在则跳过/更新、不存在则插入」（PostgreSQL `ON CONFLICT DO NOTHING` 或先查后插 + 唯一约束）。
4. **住院锁升级为跨进程**：事务内用 PostgreSQL 咨询锁（如 `pg_advisory_xact_lock(hashtext(org_id||balance_id))`）替代进程内 HashSet。
5. **判重查询异常时禁止上传**（现有实现 return true，保持）。
6. 上线后核对平台侧重复数据：按 3505A/3506A 的 drugtracinfo 追溯码 + 业务单号去重清理，再启新逻辑。

## 六、需要业务确认的点

- `ins_traceability_code_record` 唯一键是否可含「同单同药品多次发药/退药」场景（退药多次、部分退）——若允许，唯一键需加业务单号/退药流水区分，或由业务方确认「同一 drug_detail_id 只允许一条成功记录」。
- 平台对同一追溯码重复上传的报错语义（拒绝还是覆盖），决定是否需要查询平台侧回执来判重。

