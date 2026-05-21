# 元 HIS 统一外部接口开发文档

> **权威源**：本文件为元 HIS 统一外部接口开发的唯一权威文档。
> **来源**：`元his统一外部接口开发文档.docx`（2022-03-04，Wxl 初步编制）。
> **维护**：Keiskei，2026-05-18 合并自项目内 dev-docs 整理版与 his-wiki 原始转换版。

## 文档更新记录

| 序号 | 调整内容 | 调整时间 | 备注 |
|------|----------|----------|------|
| 1 | 初步编制 | 2022-03-04 | Wxl |
| 2 | 结构化整理（表格 + 代码块），截图占位改文字描述，合并 dev-docs 整理版 | 2026-05-18 | Keiskei |

## 一、接口开发说明

### 命名规范

- **工程名**：`Plugins.EB_` 前缀，如 `Plugins.EB_InterfaceTest`
- **主类名**：`EB_` 前缀，需与工程名对应，如 `EB_InterfaceTest`

### 依赖引用

- `System.Net.Http.dll`
- `ZLSoft.CHSS.CPAPI.PluginBase.dll`

### 主类继承

继承 `ZLSoft.CHSS.CPAPI.PluginBase.CPAPIPluginBase`，实现以下五个重写方法/属性：

| 方法/属性 | 说明 |
|-----------|------|
| `PluginName` | 接口名，显示在插件目录 |
| `Description` | 接口描述 |
| `SettingControl` | 插件参数设置界面，可自定义重写 |
| `Dispose` | 释放资源 |
| `ProcessRequest` | **接口主入口** |

### ProcessRequest 方法

签名：`ProcessRequest(string action, string jsonParams)`

- `action` — 插件需要的，一般可不用管
- `jsonParams` — 传入参数 JSON，包含数据库参数、登录信息和业务参数

关键参数提取：

```csharp
JObject busi_param = JObject.Parse(busiparam);

// 模块功能配置方式 —— 从「系统管理→统一事件接口→事件管理」配置
string module_code   = busi_param.Value<string>("module_code");   // 模块编码
string function_code = busi_param.Value<string>("function_code"); // 功能编码

// 拓展菜单配置方式 —— 从「系统管理→拓展功能设置」配置
string menu_code  = busi_param.Value<string>("menu_code");  // 目录编码
string func_sign  = busi_param.Value<string>("func_sign");  // 功能标识

string data = busi_param.Value<string>("data"); // 各模块详细入参，json 格式
```

### 框架提供的工具函数

| 函数 | 说明 |
|------|------|
| `FrmTopTools.SetTopmost(IntPtr Handle)` | 根据窗口句柄设置窗口置顶 |
| `BaseTools.ShowMsg(string title, string msg)` | 消息弹窗 |
| `UPTools.*` | 数据库帮助类（查询 / 增删改 / 批量），详见下文 |

### UPTools 数据库帮助类

> **权威源**：`sdp.cpapi-origin/ZLSoft.CHSS.CPAPI.PluginBase/Tools/UPTools.cs` — 方法签名以源文件为准，本文仅做用途速查。

#### 主要方法

| 方法 | 用途 | `exec_type` |
|------|------|-----------|
| `GetModel<T>` | 单条 SQL **查询**，返回单实体或集合（按 `T` 自适应：`DataTable` / 实现 `IEnumerable` 的类型 → 列表；其他 → 单条） | 2 |
| `GetModels<T>` | **批量查询**，入参为 `List<SqlsParam>`，一次连发多条 SELECT | 2 |
| `ExteSql` | 单条 SQL **增删改**，返回 `bool`（`true` = 成功且影响行数 > 0） | 1 |
| `ExteSqls` | **批量增删改**，入参为 `List<SqlsParam>` | 1 |
| `ExteSqlReturnModel` | 增删改并返回原始 `LJZBackModel`（保留服务端 `code` / `msg` / `data`，需要拿明细错误时用） | 1 |
| `GetModelYB<T>` / `ExteSqlYB` | 医保业务专用变体，走 `DoInsureBusinessYB` 接口（非医保业务不要用） | — |
| `GetID()` | 生成 16 位 long 型 ID（基于 `Guid`，可作主键 / 单据号） | — |
| `GetTimeStamp()` | 13 位毫秒时间戳 | — |

#### `GetModel` / `ExteSql` 公共参数

| 参数 | 说明 |
|------|------|
| `Fun_name` | 方法名，用于服务端日志记录和定位 |
| `tableSpace` | 域名，指定执行 SQL 的库（如 `inp` / `outpatient` / `updb`） |
| `sql` | 详细 SQL 语句（服务端会做 base64 + DES 包装后下发） |
| `Param[] prarm` | 参数列表，单元素含 `pname` / `value` / `dbtype` |
| `strJson`（原 docx 写作 `DataIn`） | 产品传入参数，可直接传 `ProcessRequest` 的 `jsonParams` |

#### 批量方法的入参结构

`SqlsParam` 用于 `GetModels` / `ExteSqls`，每条 SQL 独立携带自己的库和参数：

| 字段 | 说明 |
|------|------|
| `sql` | 单条 SQL |
| `tableSpace` | 该 SQL 执行的库 |
| `prarm` | 该 SQL 的参数列表 |

> ℹ️ **加密**：当 `isencrypt=1` 时启用 AES + RSA + Token 三层加密，调用方透明无感（`UPTools` 内部完成）。本地开发常规配置即可。

> ℹ️ **服务端路径**（仅供排障）：普通查询/增删改走 `api/TS/MedicalInsurance/DoInsureBusiness`；批量走 `DoInsureBusinessSqls`；医保 YB 变体走 `DoInsureBusinessYB`。

## 二、接口配置说明

### 1. 基础配置（插件部署）

#### 插件 1.0 版本

1. 将生成的 DLL（包含引用的第三方 DLL、工程下所有 DLL）压缩成 ZIP（压缩前不需要建文件夹）
2. 进入产品：**系统管理 → 插件升级**
3. 点上传 → 选择插件更新包 → 选择 ZIP 文件 → 确认

> 📷 *界面说明*：插件升级页面顶部有「上传」按钮，下方为已上传的插件列表。点击「上传」后弹出文件选择对话框，选 ZIP 包并确认即可。

#### 插件 2.0 版本

1. 将生成的 DLL 及相关 DLL，加上 `version.json` 文件，一起打包成 ZIP

   > 📷 *version.json 内容说明*：JSON 格式，记录插件版本元数据，主要字段为版本号（形如 `"version": "1.0.0.1"`）、主 DLL 名等，与压缩包内 DLL 对应。

2. 进入产品：**系统管理 → 插件版本管理 → 业务插件**

   > 📷 *界面说明*：业务插件列表页，左上方有「上传新版本」按钮；已上传记录每行右侧有「重传」操作按钮。

3. 在对应界面点「上传新版本」（后续更新选中记录点右边「重传」）

   > 📷 *界面说明*：弹出 ZIP 上传对话框，选中包后开始上传，上传成功后插件列表会刷新出新版本记录。

4. 上传成功后，进入 **系统管理 → 统一事件接口 → 接口源管理** → 点「新增程序集」

   > 📷 *界面说明*：接口源管理列表页，右上方有「新增程序集」按钮。

5. 在弹出的窗口中填写：
   - 接口名称：自定义
   - 程序集名称：选择刚上传的 ZIP 中的主 DLL
   - 序号：保证不重复

   > 📷 *界面说明*：新增程序集弹窗，含「接口名称」、「程序集名称」（下拉选择）、「序号」三个必填项，下方有「确定」/「取消」按钮。

6. 配置完成后点「确定」保存

### 2. 接口功能配置

1. 打开界面：**系统管理 → 统一事件接口 → 事件管理**
2. 选择对应的模块功能 → 点右边「新增」→ 弹出新增界面 → 选择对应配置 → 「确定」

   > 📷 *界面说明*：事件管理左侧为模块功能树，右侧为该功能已绑定的接口列表，右上「新增」按钮弹出配置窗口，配置项含模块编码、功能编码、对应程序集与方法等。

3. 配置好后，对应功能处即可调用到该接口

### 3. 拓展功能配置

1. 打开界面：**系统管理 → 拓展功能设置**
2. 选择对应界面 → 点「新增」→ 填写配置 → 「确定」

   > 📷 *界面说明*：拓展功能设置左侧为界面（菜单）树，右侧为该界面已挂的拓展菜单列表。「新增」弹窗配置项包括目录编码、功能标识、显示名称、对应接口等。

3. 在对应界面即可看到配置的拓展菜单

   > 📷 *效果说明*：返回业务界面（拓展菜单挂载位置），新增的拓展菜单与原有菜单并列显示，点击触发对应的 `ProcessRequest`，按 `menu_code` + `func_sign` 路由。
