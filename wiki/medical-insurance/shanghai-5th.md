# 上海医保五期插件（zlchs.SH.GJBYB.insure）

> 原始资料：raw/外部接口开发/上海医保项目五期/（规范 PDF、医保五期接口升级清单、医保错误码处理手册、医院部署前置配置清单等）
> 实现位置：`D:\work\his-medical-group\code\zlchs.SH.GJBYB.insure\`
> 关联页面：[医保错误码处理手册](error-code-handbook.md)、[医院部署前置配置清单](deployment-checklist.md)、[医保自费分离结算改造方案](self-pay-separation.md)、[程序集依赖/反射加载](assembly-loading.md)、[医保对账（日对账/结算对账）](reconcile.md)

## 项目性质

- `.NET Framework 4.8` 类库（x86），输出 `zlchs.SH.GJBYB.insure.dll`
- 被总控 `sdp.cpapi` 通过 `Assembly.Load(File.ReadAllBytes(...))` + `GetTypes()` **反射加载**
- 实现 `zlchs.Insure.Interface.IInsureInterface`，唯一总线类 `Cls_SHGBYB`；入参/出参都是 JSON 字符串
- 业务：**国家医保信息平台 + 上海五期直连**，门诊/住院全链路
- 无单元测试，验证靠宿主 HIS 客户端联调

## 双通道路由（硬性规则）

宿主传 `ins_id`，落到 `InsSystem` 后取 `sno`：

| insSno | 含义 | **唯一**调用通道 |
|---|---|---|
| `12` | 国家医保 | `BusinessHelper.YBBusiness(...)` — CSB HTTP |
| `11` | 上海五期 | `SHYBHelper.SHYBBusiness(...)` — `SendRcv4.dll` P/Invoke |
| `ins_id=1` 总线 | — | `Identify` 读卡后按 `accountattr` 自动分流 |

**禁止国家分支调 SendRcv4，禁止五期分支调 CSB HTTP。** 路由判定入口 `Cls_SHGBYB.Identify`。

## 业务边界（权威源：`五期医保概况.txt`）

- 规范定义 3 类结算人群：本地职工、互助帮困人员、离休干部特殊人员；**不包含异地**（异地在国家医保平台结）。
- 接口功能：V1.0 基础版 §4.1 消息类型表**除「线上支付」外的 23 个接口**。
- **2026-04-22 院方实际确认**：五期当前只服务 **互助帮困人员 / 离休干部特殊人员**；本地职工、异地、居保均走国家医保平台（`insSno=12`）。
- **🚨 居保通道归属**：居保人员的医保中心是国家医保平台，五期前置机后端没有居保人员数据；任何居保交易走五期通道都调不通，必须走国家通道。`SJC1/SJD1/SJF1/SJH1`（居保门诊转院）虽在五期规范里罗列，也已移入「废止」清单。

### 接口实现进度

- 五期通道总目标 **19 个**（23 − 居保转院 4 个），已实现 **15 个**，2026-04 升级新增 **4 个**（SJ31/SJ41/SJ51/SL01）。
- 不实现：线上支付 SE02–SE07、居保转院 SJC1/SJD1/SJF1/SJH1、SJG1（工伤认定号查询，后续按需立项）。

## 交易码速查

### 在用 15 个五期交易码（`Utils/SHWQBusinessHelper.cs`）

| 交易 | 业务 | 交易 | 业务 |
|---|---|---|---|
| S000 | 保障卡基本信息读取 | SN01 | 明细账单提交 |
| SE01 | 电子凭证解码 | SN02 | 明细账单撤销 |
| SM01 | 帐户查询 | SK01 | 交易退款 |
| SH01 | 门诊挂号 | SJ11 | 登记业务 |
| SH02 | 门诊挂号确认 | SJ21 | 登记撤销 |
| SI11 | 门诊收费 | SI91 | 交易查询 |
| SI12 | 门诊收费确认 | | |
| SI51 | 住院收费 | | |
| SI52 | 住院收费确认 | | |

### 2026-04 新增 4 个五期交易码（V1.0 基础版范围内）

| 交易 | 业务 | 说明 |
|---|---|---|
| SJ31 | 登记查询 | 新增实现 |
| SJ41 | 干保登记查询 | 新增实现，离休干部相关 |
| SJ51 | 民政帮困定点查询 | 新增实现，互助帮困相关 |
| SL01 | 对账 | 新增实现（手工调试式，不产生对账记录） |

> 国家医保交易号常量统一在 `Utils/YBList.cs` 登记（如 门诊挂号=2201A / 门诊结算=2207 / 住院预结算=2303 / 文件下载=9102），**新增交易必须登记，禁止硬编码字符串**；五期交易号分散在 `Utils/SHWQYBList.cs`。

## 升级状态（V1.0 → V1.0.6）

权威文件：`docs/医保五期接口升级清单.md`（AI 执行 + 用户审阅，开发动手的唯一真相源）+ `docs/医保五期文档差异分析-流程日志.md`（审计回溯用）。要点：

- **SN01 明细精度（P0-1，已落地）**：按 V1.0.2 数字格式 D=4 位 / E=6 位：
  - `mxxmdj` → `F6`（单价，格式 E）；`mxxmsl` → `F4`（数量，格式 D）；`mxxmje` → `F2`；`mxxmjyfy` / `mxxmybjsfwfy` → `F4`。
- **字段名对齐（P1-1/2/3，已完成）**：`qfddzhzfs→qfdzhzfs`、`jf_je→jfje`、`curaccountant/hisaccountant→curaccountamt/hisaccountamt`（仅五期通道内）。
- **`cardtype=2` 是出参枚举，不是读卡入参**（P2-1，已完成）——禁止新增身份证件读卡按钮/手工录入/请求分支；仅兼容中心返回 cardtype=2 时 cardid 按身份证号展示。
- **`accountattr` 位串解析（P2-4，已完成）**：按 §7.1.4 补位 12（适用医保办法 A-H）与位 16（B/C、H/I 重复是 PDF 原文如此，不擅自去重）。
- **P0-2（SN01 子类非空字段）**：`mxxmdjzl/mxxmslzl/mxxmjezl` 暂不补，先联调观察。
- **P2-2（保健对象/离休干部闭环）**：BJDX 编码 4 条已确认（`BJDX00000000001`~04），`bxbz/jfbz` 规则已确认（普通=按实/0，高价药=2/0，造口袋=0/0，减负=0/1）；`SJ11 djtype=A` 保健对象门诊登记**未贯通**，待 A.2-Q3（离休干部保健对象当前结算流程）解除后再实现，禁止凭住院登记路径推断。
- **V1.0.6 通知**已下发（2026 年），raw 已补档；差异对照以升级清单 §D「已对齐清单」为准，防止回退。

## 核心文件（改哪看哪）

| 文件 | 职责 |
|---|---|
| `Cls_SHGBYB.cs` | 总线类，所有 `IInsureInterface` 方法入口；双通道路由 |
| `Utils/BusinessHelper.cs` | 国家医保 CSB 封装 + CSB 签名；HttpUtils 经 `ProxyFactory.CreateProxy<HttpUtils>()` 包 Castle 代理，`Filter/DBLoggingInterceptor` 自动写 `insur.ins_log` |
| `Utils/SHYBHelper.cs` | 五期 `SendRcv4.dll` P/Invoke；请求 UTF-8、响应 GBK；返回码 `xxfhm`（`P001` 成功）。**不经 AOP 日志链**，用 `Cls_SHGBYB.log.WriteLog` 写文件日志 |
| `Utils/YBList.cs` / `SHWQYBList.cs` | 国家/五期交易号常量 |
| `Utils/DataHelper.cs` | 数据库访问；dbKey 主用 `"fee"`；Schema `insur.*` / `qw_base.*` |
| `AssemblyResolver.cs` | 反射加载的依赖解析兜底（见 [程序集依赖/反射加载](assembly-loading.md)） |

## 两处易踩坑

1. **`BusinessHelper` / `SHYBHelper` 的全局状态是 `static` 单例**（`HisCode` / `opercode` / `JYQDLSH` / `url` …），由 `InitInsure` 写入，后续所有交易读它。不要在单次请求里「临时改写再还原」，并发下会踩坑。
2. **反射加载时依赖找不到**：宿主 `Assembly.Load(byte[])` 使程序集 `Location` 为空，`NPOI / SharpZipLib / BouncyCastle` 等依赖查找失败 → `TypeLoadException`。兜底由 `AssemblyResolver.cs` 在 `AppDomain.AssemblyResolve` 里从 `libs\` 装载。

## 命名与部署约定

- 窗体/用户控件类名大量中文（`Frm卡类别` / `Frm医保五期退费`）——项目惯例，不要改英文。
- 错误提示统一前缀 `"医保接口提示"`（`BaseTools.ShowMsg`）。
- 运行期依赖：三方 DLL → `libs\`；读卡器 / 五期通讯 DLL（`SendRcv4.dll` / `HeaSecReadInfo.dll` / `NationECCode.dll`）→ `shLibs\`。
- `App.config` 的 appSettings 由宿主进程 `.config` 承载。

## 医保工具（function_no 速查）

| 功能号 | 工具 | 通道 |
|---|---|---|
| 1012 / 1013 | 五期版 / 国家版科别对照 | 五期 / 国家 |
| 1014 | 国家版冲正 | 国家 |
| 1016 | 五期医保结算信息查询（右键退费） | 五期 |
| 1017 | 国家医保撤销工具 | 国家 |
| 1018 | 五期医保登记撤销 | 五期 |
| 1019 | 进销存数据上传 | 国家 |
| 1020 | 国家结算对账（`Frm结算对帐`） | 国家 |
| 1021 | 五期登记查询对账（SJ31/SJ41/SJ51/SL01） | 五期 |
| 1028 | 医保参数设置（`ins_initial` KV，需 `no_init=1`） | 国家/五期 |
| 1029 | 结算清单上传 | 国家 |

> `1015` 已废弃，不要配置。五期退费请用 1016 右键退费。

## 权威参考

- [`../../raw/外部接口开发/上海医保项目五期/`](../../raw/外部接口开发/上海医保项目五期/) — 规范 PDF/md、升级清单、错误码手册、部署清单、对账手册等原始档
- [医保五期接口升级清单](../../raw/外部接口开发/上海医保项目五期/医保五期接口升级清单.md)
- [五期医保概况.txt](../../raw/外部接口开发/上海医保项目五期/五期医保概况.txt) — 业务边界权威源

