# 广东深圳市直医保插件（Plugins.insure.GD.SZSZ）

> 原始资料：`../../raw/外部接口开发/广东深圳医保/`（接口规范 docx、代码审计报告、落实清单、改造指引）
> 实现位置：`D:\work\his-medical-group\code\Plugins.insure.GD.SZSZ\`
> 审计日期：2026-07-15（基准：附件1-医疗机构接口改造指引 V1.0）
> 关联页面：[医保总控架构](architecture.md)、[IInsureInterface 接口契约](iinsure-interface.md)

## 一、项目概况

- 广东省**市直**医保插件（省直走独立插件，不受本插件影响），通过 `HttpHelper.YBBusiness` 调医保中心。
- 改造范围：改造指引共列 **76 个** function_id；本仓库实际调用 **32 个**，其中 **29 个**在改造范围内（bizh190002 / bizh200900 / sys0001 不在指引中）。
- **核心结论：插件侧代码改动很小（2 处）**——改造字段值绝大多数来自 HIS 数据库，插件只做 `ToString()` 透传；JSONB 数据由医保响应回落写入，`SavePatientArchives` 为 UPSERT，患者每次就诊重新身份验证后自动覆盖为新码。

## 二、代码改动（2 处，已完成）

1. **🚨 修复 insureOrgCode 覆盖问题** — `Cls_GDSZSZ.cs:73` 注释 `insureOrgCode = userid;`

   ```csharp
   insureOrgCode = dtOrg.Rows[0]["医院编码"].ToString();  // 67 行：取到真正的医院编码
   userid = dtOrg.Rows[0]["登录账号"].ToString();
   // insureOrgCode = userid;  // 73 行：立即被覆盖为登录账号 → 已注释
   ```

   **影响**：修复前所有用 `insureOrgCode` 拼装 XML 的地方，`<akb020>` 实际发送的是登录账号（如 `SA0003`）而非真正的 H/P 码（如 `H44010400356`）——涉及门诊 + 住院 + 交易补偿约 20 个 function_id（bizh110001/102/104/105/106、bizh120002/003/004/102/103/104/105/106/107/108/109、bizh120205）。病案首页不受影响（`getybxx()` SQL 直查 `insur.ins_org_vs.ins_code`）。

2. **身份验证窗口下拉码值更新** — `Forms/Frm身份验证.cs` `Frm身份验证_Load`：

   | 行号 | 改前 | 改后 |
   | --- | --- | --- |
   | 63 | `610-普通门诊` | `110-普通门诊` |
   | 65 | `61-门诊` | `11-门诊` |
   | 82 | `620-普通住院` | `210-普通住院` |
   | 83 | `62-住院` | `21-住院` |

## 三、数据来源三分类（决定改代码还是刷库）

| 类型 | 写入者 | 存储位置 | 改造后如何更新 | 插件改代码？ |
| --- | --- | --- | --- | --- |
| A-插件硬编码 | 插件源码写死 | 源码 | 改代码 | ✅ 已改完 |
| B-HIS普通表 | HIS业务模块/DBA | `qw_base.b_staff` 等 varchar 列 | DBA 刷库 | ✅ 无需改 |
| C-医保响应回落 | 医保返回→插件解析→写 JSONB | `insur.ins_archive.swap_info` 等 JSONB 列 | 每次就诊必经身份验证(bizh110001)→返回新码→`SavePatientArchives` 写回，自动覆盖 | ✅ 无需改 |

> 类型 C 前提：`SavePatientArchives` 对已存在档案 UPDATE 而非仅 INSERT（该方法在 `zlchs.Common.Base`，已确认为 UPSERT）。

## 四、数据库确认（4 个普通表列，列宽全部够）

| 字段 | 表.列 | 当前类型 | 要求 | 判定 |
| --- | --- | --- | --- | --- |
| akb020 | `insur.ins_org_vs.ins_code` | varchar(36) | H/P码 ≥30 | ✅ |
| aka120 | `qw_base.b_disease.country_code` | varchar(100) | ≥30 | ✅ |
| bka074 | `qw_base.b_staff.healthcare_code` | varchar(100) | ≥30 | ✅ |
| akc196 | `public.pt_diagnosis.code` | varchar(50) | ≥30 | ✅ |

其余字段（aka130/bka006/akc193/aac001/aaz217/akf001/bkz101/bkz102）在 JSONB 或已确认列宽够。

## 五、DB 侧动作清单（DBA 执行）

| # | 动作 | 表.列 | 说明 |
| --- | --- | --- | --- |
| 1 | 更新为 D 码 | `qw_base.b_staff.healthcare_code` | bka074 医师编号 |
| 2 | 更新为 ICD-10 2.0 | `public.pt_diagnosis.code` | akc196/akc193 诊断编码 |
| 3 | 更新为医保2.0国标码 | `qw_base.b_disease.country_code` | aka120 诊断国标编码 |
| 4 | 更新为贯标科室编码 | `public.inp_visit.dept_id` 及相关科室表 | akf001 科室编码 |
| 5 | 确认 H/P 码格式 | `insur.ins_org_vs.ins_code` | akb020 医院编码 |

> JSONB 数据由医保响应回落写入，患者每次就诊身份验证后自动覆盖，无需 DBA 批量刷。

## 六、验证链路（测试医院账号 SA0003~SA0009）

| # | 场景 | 覆盖 function_id |
| --- | --- | --- |
| 1 | 门诊结算 | 110001→110104→110102→110105 |
| 2 | 门诊退费 | 110102→110105(退费) |
| 3 | 住院入院 | 110001→120103→120002→120003 |
| 4 | 住院结算 | 120102→120105→120106 |
| 5 | 住院退费 | 120004→120108→120109 |
| 6 | 病案首页 | 200101→200102→200103→200106 |
| 7 | 交易补偿 | 120102→120107/120109 |
| 8 | 码表查询 | 120205 |

## 七、本次不改（后续按需）

- 门特门诊（bizh110404/405/406/402/403）、门特住院（bizh120303/304/302/332/334/312/333/305/306/307/308/309）、外配处方（wpcf001-003）
- 基础信息维护 bizh100xxx（科室/病区/床位/医师上传删除，共 8 个）
- 移动支付（改造指引明确「直接复用国标2.0接口」，不归本插件）
- bizh110004 无感支付、bizh120112 住院费用明细提取、病案分娩/肿瘤（bizh200104/105/204/205/604/605）、信息查询下载、其他信息接口
- 共 **47 个** function_id 在指引列出但本插件未实现

