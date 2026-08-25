# 医院部署前置配置清单（上海五期 / 国家医保插件）

> 原始资料：`../../raw/外部接口开发/上海医保项目五期/医院部署前置配置清单.md`（+ .pdf）
> 适用：首次部署 `zlchs.SH.GJBYB.insure` 时必须提前准备的数据库配置和 HIS 基础数据。
> **未完成以下配置，门诊结算流程会在对应环节报错中止。**
> 关联页面：[上海医保五期插件](shanghai-5th.md)、[医保错误码处理手册](error-code-handbook.md)

## 一、部署路线图

```
1. 执行 DDL 脚本：insur 25 张表 + 日对账表（第二章）
2. 配置 ins_system + ins_system_mapping（第三章）
3. 配置 ins_org_vs 保险医院对照（第四章，决定 fixmedins_code）
4. 导入医保目录 → 项目对码（ins_item + ins_item_vs，第五、六章）
5. 配置 insure_config（url、xzqh 等，第七章）
6. 配置科室对照（ins_standard_dept* 四张表，第八章）
7. 配置医护人员编码（b_staff.healthcare_code，第九章）
8. HIS 结算方式管理配置三条医保结算方式（第十章）
9. 导入疾病类型字典（按需，第十一章）
10. 联调验证 InitInsure → ItemMarking → 预结算 → 正式结算 → 日对账 全链路
```

> ⚠️ **双通道路由提醒**：涉及 `ins_id` 的配置表（`ins_system_mapping` / `ins_org_vs` / 项目/科室对照等）要为**国家（sno=12）和五期（sno=11）各插一条**，只插一条会导致其中一个通道在结算时报「未对照/未对码」。

## 二、DDL 准备（执行域：fee）

- 🚨 `insur_补表_创建脚本.sql` — 25 张 `insur.*` 业务表（含 `insure_config`、`sign_info`、`ins_log`、`ins_system`、`ins_system_mapping`、`ins_item*`、`ins_archive*`、`ins_visit`、`ins_balance*`、`ins_fee_detail`、`ins_reg_record`、`ins_standard_dept*` 等；`insur.ins_org_vs` 由 HIS 标准 schema 提供）
- 🚨 `日对账记录表结构.sql` — `daily_reconcile_main` / `daily_reconcile_detail`
- ⚠️ `insur.ins_log`（AOP 写日志）与 `insur.sign_info`（9001 签到读/写）必须立即存在，否则插件启动即异常
- 验证：`SELECT count(*) FROM information_schema.tables WHERE table_schema='insur';` 应 ≥ 26

## 三、保险系统映射（第三章）

```sql
INSERT INTO insur.ins_system (id, sno, name, interface_name, is_unuse) VALUES
('5380194289529592754', '11', '上海医保五期', 'zlchs.SH.GJBYB.insure', 0),
('5388135717170938973', '12', '国家医保',     'zlchs.SH.GJBYB.insure', 0);

INSERT INTO insur.ins_system_mapping (ins_id, mapping_sno, mapping_insid) VALUES
('5380194289529592754', 10, '5380194289529592754'),
('5388135717170938973', 10, '5388135717170938973');
```

> 总线医保（sno=10）是虚拟路由层，不需要单独 `ins_system` 记录；`mapping_insid` 指向自身即可。缺表报错：`获取保险系统映射配置失败！`（门诊医生站保存医嘱打标时触发）。

## 四、保险医院对照（第四章）

每机构**两条**（国家+五期各一条）；`ins_code` 即定点医疗机构编码（fixmedins_code），**国家版和五期版通常不同**，需分别向两个中心索取。

```sql
INSERT INTO insur.ins_org_vs (ins_id, org_id, org_name, ins_code) VALUES
('5388135717170938973', '1', '<定点机构名>', '<国家定点医疗机构编码>'),  -- 国家医保
('5380194289529592754', '1', '<定点机构名>', '<五期定点医疗机构编码>'); -- 五期医保
```

缺表报错：`当前机构未进行保险医院对照-国家医保!` / `...-五期医保!`（InitInsure 启动时，查 insure_config 之前）。

## 五、项目对码（第五章）

- 通过 HIS 医保工具 → **项目对码**，逐项建立 `fee_item_id → ins_item_code` 对照。
- 对码后所有费用项目 `is_insure_item=1`；未对码时返回 `is_insure_item=0, special_mark=自费`。

## 六、国家统一编码（第六章）

- `ins_item.country_unified_code` 必须非空，否则报 `下列项目：[xxx] 缺少国家码！`
- 项目对码工具的「对照工具栏」导入医保目录会自动写入；临时可 UPDATE。

## 七、医保配置信息（第七章，仅国家通道）

五期（sno=11）走 SendRcv4.dll 直连前置机，**无需 URL**；国家通道必须有：

```sql
INSERT INTO insur.insure_config (ins_id, org_id, xzqh, url, medinstype, medinslv, znjgEnabled, admvs_area)
VALUES ('5388135717170938973', '1', '<行政区划编码>', '<医保交易URL>', '<机构类型>', '<机构等级>', '0', '<医保区划代码>');
```

缺配置报错：`未查询到当前机构的国家医保配置信息，请联系管理员！`（InitInsure 初始化）。

## 八、科室对照（第八章，四张表）

`insur.ins_standard_dept` / `ins_standard_dept_vs`（国家）+ `ins_standard_dept_sh` / `ins_standard_dept_vs_sh`（五期）。

- 推荐走工具：国家版科别对照（function_no=1013）、五期版科别对照（function_no=1012）；界面支持直接新增标准科室节点。
- 手动 SQL（不推荐）注意 **id 列无默认值，必须 `gen_random_uuid()::varchar`** 显式生成。
- 缺对照报错：`下列科室：[xxx] 未对照！`

## 九、医护人员编码（第九章）

- `qw_base.b_staff.healthcare_code`（卫健委分配，通常 D 开头）为空 → 报 `下列医护人员：[xxx] 未对码！`
- 排查：`SELECT id, code, name, healthcare_code FROM qw_base.b_staff WHERE prop LIKE '%A%' AND (healthcare_code IS NULL OR healthcare_code = '');`（执行域：patient）

## 十、结算方式（第十章）

HIS 费用管理系统 → 结算方式管理，配置三条（性质=医保各类统筹，勾选适用本机构）：

| 名称 | 触发条件 |
| --- | --- |
| `个人账户` | 个人账户各段支付之和 > 0 |
| `优惠减免` | 现金自付各段之和 > 0（SH01 通道） |
| `医保基金` | 统筹+附加支付之和 > 0 |

> ⚠️ 已知不一致：SI11 通道现金段 `balance_name` 写死 `"现金"`，SH01 通道写的是空字符串，待确认后统一修复。

## 十一、疾病类型字典（第十一章，按需）

- `insur.ins_disease_type`（ins_id + disease_type 维度）——慢病/特殊病登记、病种结算、传染病上报前必须导入。
- 普通门诊结算非硬阻塞。

## 十二、日对账表结构（第十二章）

- `insur.daily_reconcile_main` / `daily_reconcile_detail` —— 结算对账工具（function_no=1020）依赖。
- 只有通过系统执行的对账才会保存记录；保存的是对账时刻的数据快照。

## 十三、HIS 基础数据排错指南（不属于医保插件部署范围）

| 字段 | 症状 | 补救 |
| --- | --- | --- |
| `qw_base.b_pt_type` 人员类别 | 读卡/登记/参保类型切换报「人员类别未配置」 | HIS 实施在人员类别管理补齐（名称与插件传入 `instypename` 完全一致） |
| `qw_base.b_org.property` 机构属性 | `orgProperty` 空 → 综合/专科/中医分支走错路径 | HIS 机构管理填属性编码；改后重启客户端重走 InitInsure |
| `qw_base.b_staff.healthcare_code` | 见第九章 | —— |

> **原则**：这是「排错索引」不是「数据建立指南」——医保实施遇到这些报错应立即转交 HIS 实施团队，不要在插件侧硬塞数据或改代码绕过。

## 十四、InitInsure 卡点对照表（代码位置 `Cls_SHGBYB.cs:48-179`）

| 步骤 | 报错文案 | 缺失项 | 修复章节 |
| --- | --- | --- | --- |
| 1 | `获取国家医保/五期医保保险系统信息失败！` | `ins_system` 缺 sno=11/12 | 三 |
| 2 | `当前机构未进行保险医院对照-国家医保!` / `...-五期医保!` | `ins_org_vs` 缺对照 | 四 |
| 3 | `未查询到当前机构的国家医保配置信息！` | `insure_config` 缺国家配置 | 七 |
| 4 | `今天已签退，请于第二天签到！` | `sign_info.status='1'`，业务正常 | —— |
| 5 | `签到失败！{output}` | 9001 失败：url 不通 / xzqh 错 / fixmedins_code 错 / opter_no 未备案 | 四、七、九 |

## 十五、医保工具操作指南（节选）

| 功能号 | 工具 | 通道 |
| --- | --- | --- |
| 1012 / 1013 | 五期版 / 国家版科别对照 | 五期 / 国家 |
| 1014 | 国家版冲正 | 国家 |
| 1016 | 五期医保结算信息查询（右键退费） | 五期 |
| 1017 | 国家医保撤销工具 | 国家 |
| 1018 | 五期医保登记撤销 | 五期 |
| 1019 | 进销存数据上传 | 国家 |
| 1020 | 国家结算对账 | 国家 |
| 1021 | 五期登记查询对账（SJ31/SJ41/SJ51/SL01） | 五期 |
| 1028 | 医保参数设置 | 国家/五期 |
| 1029 | 结算清单上传 | 国家 |

**1028 医保参数设置的「鸡生蛋」问题**：InitInsure 通过的前提是 `ins_initial` 已有数据，而 `ins_initial` 靠本工具填写。打破方法：`insur.ins_tools` 插入入口记录时 **`no_init='1'` 必填**，让菜单第一次打开跳过 InitInsure → 填齐参数保存 → 之后再走正式业务路径。

> 工具菜单通过 HIS 宿主**统一事件管理**配置，jsonParams 传 `function_no / ins_id / org_id / operator_id / operator_name / dept_id`。`1015` 已废弃不要配置。

