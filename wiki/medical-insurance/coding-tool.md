# 医保对码工具（Plugins.MedicalMatch / Plugins.InsureTools）

> 原始资料：`../../raw/对码管理/`（对码管理使用手册.html、2026-08-18 对码数据与 insurlog、ins_item.sql、已对照目录不显示数据分析.md）
> 实现位置：`D:\work\his-medical-group\code\CodingToolTranslation\`
> 关联页面：[医保数据库表结构](database-schema.md)、[医院部署前置配置清单](deployment-checklist.md)（第五章项目对码）

## 一、工程概览

`CodingToolTranslation\Plugins.MedicalMatch.sln` 包含两个插件工程：

| 工程 | 插件名 | 功能 |
| --- | --- | --- |
| `Plugins.MedicalMatch` | 项目对码（MedicalMatch） | 左侧收费目录 ↔ 右侧医保目录对照；已对照目录展示；时间选择 |
| `Plugins.InsureTools` | 医保工具（InsureTools） | 医保对码、医保对帐等工具入口（action 反射分发到 `InsureToolsHelper`） |

### InsureTools 路由机制

`InsureTools : CPAPIPluginBase`，`ProcessRequest` 按 `action`（`InsureToolsEnum` 枚举）校验后，**反射**从当前程序集找 `InsureToolsHelper` 类型并调用同名方法；方法有参数时自动注入 `CPAPIUSERPARAMS` 用户自定义参数。

```csharp
if (!Enum.IsDefined(typeof(InsureToolsEnum), action))  // action 未定义 → PreconditionFailed
Assembly assembly = Assembly.GetExecutingAssembly();   // 反射找 InsureToolsHelper → methodInfo.Invoke
```

## 二、已对照目录不显示数据问题（2026-08 分析）

### 现象

左侧收费目录中项目状态显示「已对码」，但底部「已对照目录」显示 **0 条记录**。

### 原因

已对照目录数据来自 `ins_item_vs`（对照关系表）与 `ins_item`（医保目录表）的 JOIN，**当前 JOIN 要求以下 9 个字段全部一致**才能显示：

| # | 字段 | 匹配规则 |
| --- | --- | --- |
| 1 | `ins_item_code` | 完全一致 |
| 2 | `ins_id` | 完全一致 |
| 3 | `start_time` / 4 `end_time` | 精确到秒一致，或同时为 null |
| 5 | `country_unified_code` | 一致，或同时为空 |
| 6 | `specification` | 一致，或同时为空 |
| 7 | `approval_no` | 一致，或同时为空 |
| 8 | `name` | 完全一致 |
| 9 | `sourceland` | 一致，或同时为空 |

**任意一个字段不一致（时间差一秒、规格多空格、产地不同）→ 已对照目录不显示该条。**

### 建议修改方案

JOIN 条件简化为仅匹配核心字段：`ins_item_code` + `ins_id`（国码对上即显示），其余字段仅作展示。

- 涉及：`MedicalMatchHelper.cs` → `GetInsItemVSList`（查询 SQL 和计数 SQL 的 JOIN 条件）
- 风险：`ins_item` 中同一 `ins_item_code + ins_id` 存在多条记录时可能一对多，需先确认数据。

> 状态：**待组长确认后修改**（尚未落地）。

## 三、ins_item.sql（对码脚本）

`脚本/ins_item.sql` 提供医保目录（`insur.ins_item`）相关对码操作脚本，已补档至 raw/对码管理/。对码完成后需确认 `ins_item.country_unified_code`（国家统一编码）有值，否则预结算报「缺少国家码」（见[医院部署前置配置清单](deployment-checklist.md)第六章）。

## 四、注意事项

- 对码表（`ins_item_vs` 等）涉及 `ins_id` 分流：国家（sno=12）与五期（sno=11）双通道各需一条对照记录，只插一条会导致其中一个通道报「未对照」。
- `insur` schema 表的主键列一般无默认值，手写 INSERT 必须显式 `gen_random_uuid()::varchar`。

