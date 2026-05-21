---
title: MI-20260506-TOOL-002 - 医保工具窗口长时间挂机后 Token 过期
date: 2026-05-06
author: Keiskei
tags:
  - troubleshooting
  - medical-insurance
  - authentication
  - token-expiry
aliases:
  - 登陆信息不匹配身份认证信息不合法
  - 保险工具挂机后点其他工具报错
status: pending-fix
---

# MI-20260506-TOOL-002 - 医保工具窗口长时间挂机后 Token 过期

## 故障概述

- **故障编号**: MI-20260506-TOOL-002
- **排查日期**: 2026-05-06
- **影响范围**: HIS 保险相关工具窗口（`Frm保险相关工具`）
- **影响用户**: 长时间打开工具窗口未操作后双击某个工具的操作员
- **表现形式**: 弹窗提示"登陆信息不匹配!身份认证信息不合法"
- **处理状态**: 已定位根因

## 现象描述

操作员打开"保险相关工具"窗口（`Frm保险相关工具`）后长时间未操作（挂机约 80 分钟以上），窗口保持打开状态。此后双击某个工具时，弹出错误：

> 登陆信息不匹配!身份认证信息不合法

HIS 客户端日志：

```
[Info]调用业务总控方法前，入参{...token...}
[Info]当前调用医保总控DLL路径为：D:\Program Files\CPAPI\CPAPIClient\Plugins.BusinessControl\zlchs.Interface.Control.dll-Plugins.WebInsurance-Plugins.WebInsurance
[Info]调用业务总控方法后，出参{"code":"0","message":"初始化失败!","data":null}
```

## 根因分析

### Token 生命周期

HIS 客户端使用的 JWT token 有效期约为 80 分钟（`exp - iat = 4800s`）：

```json
{
  "iat": 1778030148,
  "exp": 1778034948,
  "nbf": 1778030148
}
```

### 数据流

```
窗口打开 → 构造函数注入 strJson（含 token）→ 字段存储，永不刷新
     ↓
80分钟后 token 过期
     ↓
双击工具 → DataIn = JObject.Parse(旧strJson)
     ↓
BaseTools.GetLoginUserInfo(DataIn) → ExeHttp("GetUserAuthInfo", 过期token)
     ↓
服务端返回 code ≠ 200 → 弹窗 "登陆信息不匹配!{msg}"
```

### 关键代码位置

| 步骤 | 文件 | 行号 |
|------|------|------|
| strJson 一次性注入 | `zlchs.Interface.Control/Frm保险相关工具.cs` | 27 |
| 窗口内存储 strJson 字段 | 同上 | 22 |
| 双击时使用过期 strJson | 同上 | 262-266 |
| 调身份认证 API | `sdp.cpapi/.../Base/BaseTools.cs` | 1975 |
| 返回非 200 抛错误 | 同上 | 1977-1984 |

### 涉及 DLL

- `zlchs.Interface.Control.dll` — UI 逻辑，持有过期 token
- `ZLSoft.CHSS.CPAPI.PluginBase.dll` — `BaseTools.GetLoginUserInfo`，实际调 HTTP
- `Plugins.WebInsurance.dll` — `InsureBusiness.InitInsure`，token 透传

## 修复思路（3 个方案）

### 方案一（推荐）：双击时从宿主获取最新 token

在 `dgv工具列表_CellDoubleClick` 中，调用 `GetLoginUserInfo` 之前，通过宿主进程刷新 token。HIS 主进程（CPAPIClient）通常在内存中维护有效 token，可通过 IPC（WebSocket / NamedPipe）或共享配置获取。

### 方案二：GetLoginUserInfo 失败时自动重登录

在 `BaseTools.GetLoginUserInfo` 中捕获 token 过期错误，自动调用 `Identity/UserAuth` 重新获取 token，成功后重试原请求。

### 方案三：窗口加定时器提前刷新

`Frm保险相关工具` 加 `System.Windows.Forms.Timer`，每 30 分钟检查 token 剩余有效期，到期前 5 分钟自动刷新。

## 预防措施

- 所有需要长时间保持打开状态的 HIS 窗口（弹窗、工具栏等），不应在构造函数中一次性固化 token，应每次操作前从宿主获取最新 token
- `strJson` 参数中的 `token` 应视为"使用时的快照值"，而非"打开时的快照值"
