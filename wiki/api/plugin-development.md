# 插件开发模板

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/02-接口模板/插件开发模板.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/api/plugin-development.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

## 适用场景

接口组开发新的对接插件时使用此模板。

## 参考项目

- 插件Demo：`D:\work\his-medical-group\code\QWSB.Plugin.Demo\`
- 检验互认插件：`D:\work\his-medical-group\code\sdp.cpapi\plugins.eb_testrecongnition\`
- 医保插件：`D:\work\his-medical-group\code\sdp.cpapi\Plugins.MedicalInsurance\`
- 规范文档：`D:\work\his-medical-group\上海药事平台 - 原本\dev-docs\元his统一外部接口开发文档.md`

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

                // 模块功能配置方式 —— 从「系统管理→统一事件接口→事件管理」配置
                string moduleCode   = busiParam.Value<string>("module_code");
                string functionCode = busiParam.Value<string>("function_code");

                // 拓展菜单配置方式 —— 从「系统管理→拓展功能设置」配置
                string menuCode  = busiParam.Value<string>("menu_code");
                string funcSign  = busiParam.Value<string>("func_sign");

                // 各模块详细入参（JSON 格式）
                string data = busiParam.Value<string>("data");

                object result = null;

                switch (functionCode ?? funcSign)
                {
                    case "QueryData":
                        result = _helper.QueryData(data, jsonParams);
                        break;
                    case "UploadData":
                        result = _helper.UploadData(data, jsonParams);
                        break;
                    default:
                        return new PluginResult
                        {
                            Code = -1,
                            Message = $"未知的功能标识: {functionCode ?? funcSign}"
                        };
                }

                LogTools.Info($"[EB_MyFeature] {functionCode ?? funcSign} completed");
                return new PluginResult
                {
                    Code = 0,
                    Message = "操作成功",
                    Data = result
                };
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

```json
{
    "currentVersion": "1.0.0",
    "hisClientVersion": "5.0.0",
    "flieList": [
        "Plugins.EB_MyFeature.dll",
        "EB_MyFeature.config"
    ],
    "versionDescribe": "初始版本：实现XX功能对接"
}
```

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

1. 将生成的 DLL 及依赖 DLL，连同 `version.json` 一起打包成 ZIP
2. 进入产品：**系统管理 → 插件版本管理 → 业务插件**
3. 点「上传新版本」；后续更新选中记录点「重传」
4. 上传成功后，进入 **系统管理 → 统一事件接口 → 接口源管理** → 点「新增程序集」
5. 接口名称自定义，程序集名称选择 ZIP 中的主 DLL，序号保证不重复
6. 确定保存

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