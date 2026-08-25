# 医保错误码处理手册

> 原始资料：`../../raw/外部接口开发/上海医保项目五期/医保错误码处理手册.md`（+ .pdf）
> 适用项目：`zlchs.SH.GJBYB.insure`（国家医保 CSB + 上海五期 SendRcv4 双通道）
> 定位：联调与日常运维时按通道分类定位错误；完整错误码定义以医保中心下发接口规范 PDF 为准。
> 关联页面：[上海医保五期插件](shanghai-5th.md)、[医院部署前置配置清单](deployment-checklist.md)

## 符号说明

| 符号 | 含义 |
| ---- | ---- |
| 🚨 | 阻塞所有交易，必须先排除 |
| ⚠️ | 影响单笔业务，可重试或换通道 |
| ℹ️ | 信息性提示，无需处置 |

---

## 一、国家医保通道（CSB HTTP）

### 1.1 通用判定逻辑

```
响应 JSON → infcode 字段
├── infcode = "0"  → 业务成功，主响应在 output 字段
└── infcode ≠ "0" → 失败，错误描述在 err_msg / warn_msg 字段
```

接口返回错误时插件**直接把 `err_msg` 弹窗呈现给操作员**，现场看到的文案就是医保中心原始描述。

### 1.2 通用业务错误（infcode ≠ "0"）

| 现象 | 排查方向 |
| --- | --- |
| 🚨 任意接口 `infcode ≠ "0"` | 看 `err_msg` 文案，多数直接说明问题（如「参保人未参保」「医师未备案」） |
| 🚨 含「签名」「验签失败」 | 服务器时间不同步、CSB 签名证书过期或路径错误（见 §1.3） |
| 🚨 含「操作员」「opter」 | 操作员未备案，或 `b_staff.healthcare_code` 与备案号不匹配 |
| ⚠️ 含「参保」「未参保」 | 跨地区参保、刚转入未同步 |
| ⚠️ 含「目录」「医保编码」 | `country_unified_code` 缺失或目录脱节（重新导入医保目录） |
| ⚠️ 含「科室」 | 科室未对码或对码错误 |
| ⚠️ 含「违反」「超限额」 | 医保规则引擎触发：日限额/次限额/重复用药等 |

> **现场处置原则**：先看 `err_msg` 文字，多数是业务前置数据问题（医师/科室/目录），按部署清单反查。

### 1.3 CSB 签名与时间错误

| 错误 | 含义 | 处置 |
| --- | --- | --- |
| 🚨 `9000` 签名超时 | 客户端签名时间戳与中心偏差 > 阈值 | 前置机同步 NTP，时区 `(UTC+08:00) 北京` |
| 🚨 验签失败 | CSB 公私钥不匹配或签名被篡改 | 联系医保中心确认密钥未过期；核查插件签名实现 |
| 🚨 证书已过期 | CSB 接入证书过期 | 联系医保中心更新证书 |

### 1.4 网络与 HTTP 错误（不带 infcode，接口直接抛异常）

| 现象 | 排查方向 |
| --- | --- |
| 🚨 `HttpRequestException` / 连接超时 | ping `insure_config.url`；防火墙放行 CSB 端口；代理配置 |
| 🚨 `404` / `405` | `insure_config.url` 配置错误 |
| 🚨 SSL/TLS 握手失败 | 服务器未启用 TLS 1.2+ |

> 此类错误**不会**写入 `insur.ins_log`（数据库日志只记录已成功发出的请求），需在 `InsureLog/YYYYMMDD.log` 文件日志中找异常堆栈。

### 1.5 签到流程错误（9001 / InitInsure）

`InitInsure` 末尾调用 9001 签到，每天首次启动 HIS 触发，失败阻塞所有后续交易。

| 现象 | 处置 |
| --- | --- |
| 🚨 `签到失败！{output}` | 按 output 文字反查：操作员未备案 → 联系备案；IP/MAC 不匹配 → 查接入设备限制 |
| 🚨 `今天已签退` | 业务上需次日重新签到，**不是配置问题** |
| ⚠️ 签到成功但后续失败 | 签到流水号未正确传递，联系开发 |

---

## 二、上海五期通道（SendRcv4.dll 本地调用）

### 2.1 通用判定逻辑

```
响应 JSON → xxfhm 字段
├── xxfhm = "P001"  → 业务成功
└── xxfhm ≠ "P001"  → 失败
```

响应编码 **GBK**，请求编码 **UTF-8**；编码不一致导致中文乱码（检查 .NET CodePage 936 是否可用）。**五期通道日志不入数据库**，只在 `InsureLog/YYYYMMDD.log`。

### 2.2 五期 DLL 加载错误

| 错误 | 处置 |
| --- | --- |
| 🚨 `DllNotFoundException: shLibs\SendRcv4.dll` | `shLibs/` 目录未创建或 DLL 缺失 |
| 🚨 `BadImageFormatException` | DLL 位数与宿主不匹配——宿主 x86 必须用 x86 版 SendRcv4.dll |
| 🚨 `AccessViolationException` | DLL 内部崩溃：前置机服务未启动或被防火墙拦截，重启五期前置机服务 |

### 2.3 前置机通讯错误

| 现象 | 处置 |
| --- | --- |
| 🚨 调用后无响应/挂起 | 前置机服务未启动；前置机 IP 变更 |
| 🚨 响应空字符串 | 前置机内部错误，看前置机日志（通常在前置机软件安装目录 `log/`） |

---

## 三、读卡器错误（`HeaSecReadInfo.dll` / `NationECCode.dll`）

| 错误 | 处置 |
| --- | --- |
| 🚨 `DllNotFoundException: HeaSecReadInfo.dll` | `shLibs/` 缺读卡器 DLL |
| 🚨 读卡器无响应 | USB 连接、驱动、服务「卡读取服务」 |
| ⚠️ 读卡返回部分字段为空 | 卡损坏/接触不良，重新插卡 |
| 🚨 电子凭证解码失败 | SDK 版本与中心不匹配 → 更新 `NationECCode.dll`；二维码过期重新生成 |
| ⚠️ 电子凭证读取空/部分字段为空 | 解码需联网验证，检查前置机网络 |

---

## 四、业务前置错误（项目代码主动 ShowMsg，非中心返回）

99% 指向部署前置数据问题，用部署清单 **第十四章 InitInsure 卡点对照表** / **第十三章 HIS 基础数据排错指南** 直接对上：

| 弹窗文案 | 根因 | 修复章节（部署清单） |
| --- | --- | --- |
| 🚨 `获取保险系统映射配置失败！` | `insur.ins_system_mapping` 未配置 | 六 |
| 🚨 `获取国家医保/五期医保保险系统信息失败！` | `insur.ins_system` 缺 sno=11/12 | 六 |
| 🚨 `当前机构未维护「国家医保」/「上海五期医保」医院对照！` | `insur.ins_org_vs` 缺记录 | 三 |
| 🚨 `未查询到当前机构的国家医保配置信息！` | `insur.insure_config` 缺配置 | 七 |
| 🚨 `下列项目：[xxx] 缺少国家码！` | `ins_item.country_unified_code` 为空 | 五 |
| 🚨 `下列科室：[xxx] 未对照！` | `ins_standard_dept_vs*` 缺记录 | 八 |
| 🚨 `下列医护人员：[xxx] 未对码！` | `b_staff.healthcare_code` 为空 | 九 |
| 🚨 `医保返回的结算方式【xxx】不在【结算方式管理】中` | HIS 结算方式管理缺医保性质 | 十 |
| ℹ️ `今天已签退，请于第二天签到！` | 业务正常，非错误 | —— |
| ⚠️ `五期退费请通过【五期医保结算信息查询】工具操作。` | 走错入口 | 十五 |

---

## 五、日志查阅

### 5.1 数据库日志（仅国家通道）

```sql
SELECT inf_time, infno, opter, result_status, fail_message
FROM insur.ins_log
WHERE inf_time > now() - interval '1 hour'
ORDER BY inf_time DESC LIMIT 50;

SELECT input, output FROM insur.ins_log WHERE msgid = '<报文ID>';
```

### 5.2 文件日志（两个通道都有）

`<HIS 宿主目录>\InsureLog\YYYYMMDD.log`

- 五期通道**所有**日志都在这里
- 国家通道 CSB 调用失败/签名异常堆栈也在这里
- 反射加载问题（TypeLoadException）在日志开头

---

## 六、不在本手册范围

- 医保中心规范定义的全量错误码：见接口规范附录
- HIS 宿主进程层面错误（启动慢、UI 卡顿）：归 HIS 实施
- 数据库连接/性能/备份：归 DBA

---

## 七、向开发反馈错误时必须附带

1. 完整 `err_msg` / 弹窗文案
2. 报错时间（精确到秒）
3. `insur.ins_log.msgid`（国家通道）或 `InsureLog/YYYYMMDD.log` 报错前后 50 行
4. 当前操作员、就诊号、患者参保类型
5. 部署自检脚本（`deploy_healthcheck.sql`）最新结果

