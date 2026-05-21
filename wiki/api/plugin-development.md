# 插件开发模板

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/02-接口模板/插件开发模板.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/api/plugin-development.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

## 适用场景

接口组开发新的对接插件时使用此模板。

## 场景识别（动手前必读）

外部接口在工程层只有**一套脚手架**（同一个 `Plugins.EB_*` 工程、同一个 `ProcessRequest` 入口），但产品侧有**两条挂载线**，jsonParams 字段、配置位置、触发方式都不同。识别错了后续全错。

### 决策树

```
用户的需求里"谁来触发"是关键判断点：
│
├─ 触发主语 = HIS 系统（"挂号成功后...""收费时...""病人入院就...")
│   → 统一事件型
│   → 配置位置：系统管理 → 统一事件接口 → 事件管理
│   → jsonParams 字段：module_code + function_code
│   → 用户感知：看不到 UI 元素，被动触发
│
├─ 触发主语 = 用户（"在 X 界面加按钮""右键多个菜单项""操作员点了之后...")
│   → 扩展菜单型
│   → 配置位置：系统管理 → 拓展功能设置
│   → jsonParams 字段：menu_code + func_sign
│   → 用户感知：能看到 UI 元素，主动点击
│
└─ 描述里没有明确的触发主语
    → 直接反问用户："这个功能是 HIS 业务流程自动触发，还是用户在界面上点按钮触发？"
    → 不要猜
```

### 共用部分（两条线都一样）

- 工程命名 `Plugins.EB_<Name>`，主类 `EB_<Name>` 继承 `CPAPIPluginBase`
- 五个重写方法：`PluginName` / `Description` / `SettingControl` / `Dispose` / `ProcessRequest`
- jsonParams 里的 `data` 字段（业务详细入参，JSON 格式）
- SDK 三件套：`FrmTopTools.SetTopmost` / `BaseTools.ShowMsg` / `UPTools.GetModel`
- 部署流程：version.json 打包 → 插件版本管理 → 接口源管理新增程序集

### 同一个工程同时挂两条线？

可以。同一个 `Plugins.EB_*` 工程允许同时被「事件管理」和「拓展功能设置」配置调用。`ProcessRequest` 内部需根据 `module_code` / `menu_code` 哪个有值来分流（见后文代码模板）。

## 参考项目

- 插件Demo：`D:\work\his-medical-group\code\QWSB.Plugin.Demo\`
- 检验互认插件：`D:\work\his-medical-group\code\sdp.cpapi\plugins.eb_testrecongnition\`
- 医保插件：`D:\work\his-medical-group\code\sdp.cpapi\Plugins.MedicalInsurance\`
- 规范文档：[`../../raw/外部接口开发/元his统一外部接口开发文档.md`](../../raw/外部接口开发/元his统一外部接口开发文档.md)（his-wiki 内的权威整理版，含 UPTools 完整方法清单 + 截图文字描述）

## 命名规范

- **工程名**：`Plugins.EB_` 前缀，如 `Plugins.EB_DrugPlatform`
- **主类名**：`EB_` 前缀，需与工程名对应，如 `EB_DrugPlatform`

## 依赖引用

- `System.Net.Http.dll`
- `ZLSoft.CHSS.CPAPI.PluginBase.dll`

## 项目结构

```
Plugins.EB_MyFeature/
├── EB_MyFeature.cs              # 插件入口（继承 CPAPIPluginBase）
├── Helper/
│   └── BusinessHelper.cs        # 业务逻辑处理
├── Model/
│   ├── RequestModel.cs          # 请求模型
│   └── ResponseModel.cs         # 响应模型
├── Config/
│   └── EB_MyFeature.config      # 插件配置文件（XML）
├── UI/                          # WinForm 界面（如需要）
│   └── MainForm.cs
├── version.json                 # 版本信息
├── Plugins.EB_MyFeature.csproj  # 项目文件
└── packages.config              # NuGet 依赖
```

## 代码模板

### 1. 插件入口类

```csharp
using Newtonsoft.Json.Linq;
using ZLSoft.CHSS.CPAPI.PluginBase.Base;

namespace Plugins.EB_MyFeature
{
    /// <summary>
    /// 插件入口，负责请求路由
    /// </summary>
    public class EB_MyFeature : CPAPIPluginBase
    {
        public override string PluginName => "我的功能插件";
        public override string Description => "对接XX平台的功能描述";

        /// <summary>
        /// 插件参数设置界面，可自定义重写
        /// </summary>
        public override System.Windows.Forms.Control SettingControl => null;

        private readonly BusinessHelper _helper = new BusinessHelper();

        /// <summary>
        /// 接口主入口
        /// </summary>
        /// <param name="action">插件动作标识，一般可不用</param>
        /// <param name="jsonParams">传入参数 JSON，包含数据库参数、登录信息和业务参数</param>
        public override PluginResult ProcessRequest(string action, string jsonParams)
        {
            LogTools.Info($"[EB_MyFeature] ProcessRequest: action={action}");

            try
            {
                JObject busiParam = JObject.Parse(jsonParams);

                // 统一事件入口字段（系统管理→统一事件接口→事件管理 配置后下发）
                string moduleCode   = busiParam.Value<string>("module_code");
                string functionCode = busiParam.Value<string>("function_code");

                // 扩展菜单入口字段（系统管理→拓展功能设置 配置后下发）
                string menuCode = busiParam.Value<string>("menu_code");
                string funcSign = busiParam.Value<string>("func_sign");

                // 各业务详细入参（JSON 字符串）
                string data = busiParam.Value<string>("data");

                object result;

                // 优先按入口字段分流：两条线的 code 命名空间相互独立，不可共用 switch
                if (!string.IsNullOrEmpty(moduleCode))
                {
                    result = DispatchEvent(moduleCode, functionCode, data, jsonParams);
                }
                else if (!string.IsNullOrEmpty(menuCode))
                {
                    result = DispatchMenu(menuCode, funcSign, data, jsonParams);
                }
                else
                {
                    return new PluginResult
                    {
                        Code = -1,
                        Message = "无法识别调用场景：module_code 与 menu_code 均为空"
                    };
                }

                LogTools.Info($"[EB_MyFeature] dispatch completed");
                return new PluginResult { Code = 0, Message = "操作成功", Data = result };
            }
            catch (Exception ex)
            {
                LogTools.Error($"[EB_MyFeature] ProcessRequest failed: {ex.Message}", ex);
                return new PluginResult
                {
                    Code = -1,
                    Message = $"执行失败：{ex.Message}"
                };
            }
        }

        /// <summary>
        /// 统一事件型路由：按 function_code 分发到具体业务
        /// </summary>
        private object DispatchEvent(string moduleCode, string functionCode, string data, string jsonParams)
        {
            switch (functionCode)
            {
                case "QueryData":
                    return _helper.QueryData(data, jsonParams);
                default:
                    throw new NotSupportedException($"未知 function_code: {functionCode}（module_code={moduleCode}）");
            }
        }

        /// <summary>
        /// 扩展菜单型路由：按 func_sign 分发到具体业务
        /// </summary>
        private object DispatchMenu(string menuCode, string funcSign, string data, string jsonParams)
        {
            switch (funcSign)
            {
                case "UploadData":
                    return _helper.UploadData(data, jsonParams);
                default:
                    throw new NotSupportedException($"未知 func_sign: {funcSign}（menu_code={menuCode}）");
            }
        }

        public override void Dispose()
        {
            base.Dispose();
        }
    }
}
```

### 2. 业务逻辑类

```csharp
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ZLSoft.CHSS.CPAPI.PluginBase.Base;

namespace Plugins.EB_MyFeature.Helper
{
    /// <summary>
    /// 业务逻辑处理
    /// </summary>
    public class BusinessHelper
    {
        /// <summary>
        /// 从 HIS 数据库查询数据
        /// </summary>
        /// <param name="data">业务入参 JSON</param>
        /// <param name="jsonParams">原始 jsonParams，透传给 UPTools</param>
        public object QueryData(string data, string jsonParams)
        {
            var param = JObject.Parse(data);
            var patientId = param.Value<string>("patientId");
            LogTools.Info($"[QueryData] patientId={patientId}");

            var sql = @"SELECT pt_id, pt_name, id_card
                        FROM public.patient_info
                        WHERE pt_id = @ptId";

            // UPTools.GetModel 五参数签名：
            // Fun_name    — 方法名，用于服务端日志记录和定位
            // tableSpace  — 域名，指定执行 SQL 的库
            // sql         — SQL 语句
            // Param[]     — 参数列表
            // DataIn      — 产品传入参数，直接传 jsonParams
            var result = UPTools.GetModel<PatientModel>(
                "QueryData",
                "patient",
                sql,
                new[] { new SqlParam("ptId", patientId) },
                jsonParams
            );

            return result;
        }

        /// <summary>
        /// 上传数据到第三方平台
        /// </summary>
        /// <param name="data">业务入参 JSON</param>
        /// <param name="jsonParams">原始 jsonParams，透传给 UPTools</param>
        public object UploadData(string data, string jsonParams)
        {
            // 1. 从 HIS 查询需要上传的数据
            var localData = QueryLocalData(data, jsonParams);

            // 2. 组装请求
            var requestBody = JsonConvert.SerializeObject(localData);

            // 3. 调用第三方接口
            var platformUrl = Common.GetFromConfig("platform_url");
            var response = HttpPost(platformUrl, requestBody);

            // 4. 解析响应
            var result = JsonConvert.DeserializeObject<PlatformResponse>(response);

            // 5. 记录到本地数据库
            SaveUploadRecord(data, result, jsonParams);

            return result;
        }

        /// <summary>
        /// HTTP POST 封装
        /// </summary>
        private string HttpPost(string url, string body)
        {
            using (var client = new System.Net.Http.HttpClient())
            {
                client.Timeout = TimeSpan.FromSeconds(30);
                var content = new System.Net.Http.StringContent(
                    body, System.Text.Encoding.UTF8, "application/json");
                var response = client.PostAsync(url, content).Result;
                return response.Content.ReadAsStringAsync().Result;
            }
        }

    }
}
```

### 3. 配置文件模板

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <!-- 平台接口地址 -->
    <platform_url>https://api.example.com/v1</platform_url>
    <!-- 认证凭据 -->
    <app_id>YOUR_APP_ID</app_id>
    <app_secret>YOUR_APP_SECRET</app_secret>
    <!-- 医院代码 -->
    <hospital_code>H001</hospital_code>
    <!-- 区域代码 -->
    <region_code>310000</region_code>
</configuration>
```

### 4. version.json 模板

> 🚨 **HIS 字段命名两处故意拼错**（不是文档错），照抄即可：
> - `assimbelyName`（少一个 `e`，正确英文应为 `assemblyName`）
> - `flieList`（`i` 在 `e` 前，正确英文应为 `fileList`）
>
> Copilot / IDE 自动补全 / 格式化工具 / Prettier 都倾向"善意纠正"成正确拼写——一改 HIS 立刻加载失败。提交前必须 `grep -n 'assemblyName\|fileList' version.json`，命中即说明被改坏了。

```json
{
  "assimbelyName": "Plugins.EB_MyFeature.dll",
  "isClient": false,
  "currentVersion": "2.0.0.1",
  "hisClientVersion": "2.0.0.1",
  "versionDescribe": [
    { "sort": 1, "text": "初始版本：实现XX功能对接" }
  ],
  "flieList": [
    { "sort": 1, "fileName": "Plugins.EB_MyFeature.dll", "fileVersion": "2.0.0.1" }
  ],
  "versionNote": [
    { "sort": 1, "text": "务必进行影响的业务插件更新、测试" }
  ]
}
```

**字段说明**：

| 字段 | 含义 |
|------|------|
| `assimbelyName` | 应用程序集名称，**必须等于主 DLL 文件名**（包含 `.dll` 后缀） |
| `isClient` | 是否 HIS 客户端（业务插件填 `false`） |
| `currentVersion` | 升级包版本号，**不能与历史版本重复**，重复则上传失败 |
| `hisClientVersion` | 依赖的 HIS 客户端版本号 |
| `versionDescribe[]` | 版本描述列表（数组，每项含 `sort` + `text`） |
| `flieList[]` | 文件清单（数组，每项含 `sort` + `fileName` + `fileVersion`） |
| `versionNote[]` | 版本注意事项（数组，每项含 `sort` + `text`） |

## 开发步骤

1. 工程名用 `Plugins.EB_` 前缀命名
2. 引用 `ZLSoft.CHSS.CPAPI.PluginBase.dll` 和 `System.Net.Http.dll`
3. 创建插件入口类，命名 `EB_` 前缀，继承 `CPAPIPluginBase`
4. 实现 `PluginName`、`Description`、`SettingControl`、`ProcessRequest`、`Dispose`
5. 在 `ProcessRequest` 中用 `JObject.Parse(jsonParams)` 提取标准参数
6. 创建 Helper 类实现具体业务逻辑，`UPTools.GetModel` 使用五参数签名
7. 创建配置文件和 `version.json`
8. 将工程添加到解决方案的 Plugins 文件夹

## 调试方式

1. Visual Studio 中设置 `CPAPI.Client.new` 为启动项目
2. 在插件代码中设置断点
3. 选择 x86 + Debug 配置
4. F5 启动，插件通过 PluginHandle 动态加载

## 部署方式

> ⚠️ **插件 1.0 部署方式已过时**，仅供参考，新开发一律使用 2.0 方式。

> ~~1.0 方式：将 DLL 压缩成 ZIP → 系统管理 → 插件升级 → 上传~~

### 插件 2.0 部署流程

1. 将生成的 DLL 及依赖 DLL，连同 `version.json` 一起打包成 ZIP（压缩前不要建文件夹，所有文件平铺在 ZIP 根）
2. 进入产品：**系统管理 → 插件版本管理 → 业务插件**
3. 点「上传新版本」；后续更新选中对应记录点右边的「重传」
4. 上传成功后，进入 **系统管理 → 统一事件接口 → 接口源管理** → 点「新增程序集」
5. 接口名称自定义，程序集名称选择 ZIP 中的主 DLL，序号保证不重复
6. 确定保存

> 🚨 **强约束：三个名称必须完全一致**（含大小写、含 `.dll` 后缀）
> 1. `version.json` 里的 `assimbelyName`
> 2. ZIP 包里实际的主 DLL 文件名
> 3. 「接口源管理 → 新增程序集」时下拉选中的程序集名称
>
> 任一不一致 HIS 都加载不到插件，且报错信息往往不直接指向命名问题（常见症状：插件在事件管理列表里看不到、或出现"程序集未注册"类错误）。重命名工程时务必同步检查这三处。

## 接口配置方式

### 方式一：模块功能配置

适用于挂载到 HIS 模块内部事件触发的场景。

1. 打开：**系统管理 → 统一事件接口 → 事件管理**
2. 选择对应模块功能 → 点右边「新增」→ 选择配置 → 确定
3. 配置完成后，对应功能处即可触发该接口
4. `ProcessRequest` 中通过 `module_code` / `function_code` 区分逻辑

### 方式二：拓展菜单配置

适用于在 HIS 界面上新增自定义菜单按钮的场景。

1. 打开：**系统管理 → 拓展功能设置**
2. 选择对应界面 → 点「新增」→ 填写配置 → 确定
3. 在对应界面即可看到配置的拓展菜单
4. `ProcessRequest` 中通过 `menu_code` / `func_sign` 区分逻辑

---
**文档来源**: Keiskei 整理的HIS知识库  
**整理说明**: 从Windows桌面知识库整理到his-wiki统一管理  
**模板类型**: 插件开发  
**适用项目**: .NET Framework 接口组插件开发  
**核心内容**: 项目结构、代码模板、配置模板、部署流程