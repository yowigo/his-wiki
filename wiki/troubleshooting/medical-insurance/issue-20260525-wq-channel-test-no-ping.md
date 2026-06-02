# 上海五期通道连通性测试：误用 S000/SI91 做 ping

**日期**：2026-05-25
**影响范围**：上海五期医保（sno=11）
**相关交易**：S000（读卡）、SI91（交易查询）

## 现象

`Frm医保参数设置` 中「连接测试」按钮调用 SI91 空入参，前置机返回空或报错；改用 S000 做「读卡测试」，不插卡同样失败。运维无法判断"通道不通"还是"没插卡"。

## 根因

**上海五期协议没有类似国家医保 9001 签到的"无卡心跳"交易。** 所有交易都需要特定前置条件：

| 交易码 | 含义 | 入参门槛 | 能否无卡？ |
|---|---|---|---|
| S000 | 保障卡基本信息读取 | 入参"无" | ❌ 需要物理插卡 |
| SI91 | 交易查询 | cardtype + carddata + jssqxh + totalexpense（4 字段非空） | ❌ 需要卡 + 交易数据 |
| SL01 | 对帐 | daycollate + 8 个金额字段 | ❌ 需要当日结算数据 |
| SM01 | 帐户查询 | cardtype + carddata | ❌ 需要卡 |

S000 入参虽写"无"，但本质是读卡器操作——前置机会调用 SSCardDriver.dll 驱动读卡器，没插卡就返回 P100/P101 等错误码。

## 正确做法

**通道连通性的判断标准不是"返回 P001"，而是"能拿到有效 JSON 响应"。**

```
空响应 / E001              → 通道不通（SendRcv4.dll 未加载 / 前置机未启 / 网络不通）
E002                       → 前置机无响应（SendRcv4 成功调用但返回空）  
有效 JSON（无论返回码）     → 通道正常，返回码说明本次未成功的原因
```

实现：
- 用 S000 做探测（入参门槛最低）
- `SHYBHelper.SHYBBusiness` 在 `JObject.Parse` 前加空响应防御，返回 E002
- UI 按返回码分级提示：
  - E001 → "通道异常"
  - E002 → "通道不通"
  - P001 → "通道正常，读卡成功"
  - 其他 → "通道正常（前置机已响应，返回码 XXX），当前未成功原因：XXX"

## 附带发现：SSCardDriver.dll 加载链

`SendRcv4.dll` 内部依赖 `SSCardDriver.dll`（读卡器驱动），后者又依赖 `SSSE32.dll`。Windows 原生 DLL 搜索顺序优先从 **SendRcv4.dll 所在目录**开始，不走 .NET AssemblyResolve。

实际 shLibs 部署清单（上海五期）：

```
Plugins.WebInsurance\shLibs\
    SendRcv4.dll
    SSCardDriver.dll    ← SendRcv4 运行时依赖
    SSSE32.dll           ← SSCardDriver 依赖
```

DllImport 路径必须与部署位置一致：`@"Plugins.WebInsurance\shLibs\SendRcv4.dll"`。

## 归因

- 设计阶段未区分"通道连通性验证"和"业务功能验证"，将带前置条件的功能交易当 ping 用
- 文档把 HeaSecReadInfo.dll / NationECCode.dll 和 SendRcv4.dll 捆在一起写进 shLibs，实际 C# 代码从未引用前两者（NationECCode 明确属于国家通道 sno=12）
- v1 版 `btn五期连接测试_Click` 传空 {} 给 SI91 的 4 个非空字段，前置机直接丢弃请求，SendRcv4 返回空 buffer → `JObject.Parse("")` 炸

## 修改记录

- `Utils/SHYBHelper.cs`：`JObject.Parse` 前增加空响应防御，返回 E002
- `Tools/Frm医保参数设置.cs`：「连接测试」按钮改为「通道测试」，调 S000，按 E001/E002/P001/其他 四级提示
- `Tools/Frm医保参数设置.Designer.cs`：按钮位置 X 从 210 改 20（删了旧连接测试按钮后的布局修复）
