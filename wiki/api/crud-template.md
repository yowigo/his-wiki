# CRUD 接口模板（HIS 5.1）

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/02-接口模板/CRUD模板.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/api/crud-template.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

适用于 HIS 5.1（.NET 8.0）新增业务模块时，快速搭建标准 CRUD 接口。

## 分层说明

```
*.WebApi       → Controller：HTTP 入口，权限校验，返回 Json
*.Logic    → Logic：编排层，封装 ResponseModel
*.Interface    → Interface：服务契约，定义方法签名
*.Logic        → Logic：业务逻辑，操作数据库
*.Model        → Model：实体 + 各操作入参模型
```

## Model 命名规范

| 后缀 | 含义 | 用途 |
|------|------|------|
| 无后缀 | 主实体 | 对应数据库表，增/改时使用 |
| `_s` | search 入参 | 查询筛选条件 |
| `_d` | delete 入参 | 删除时的最小参数（id + operator） |
| `_us` | update status 入参 | 仅更新启用状态 |
| `_dto` | 传输对象 | 带关联子集合的查询出参或新增入参 |
| `_in` | 新增入参 | 新增时需要额外字段（如密码）时用 |

---

## 模板示例：`xxx_item`（业务项目管理）

### 1. Model 层

#### 主实体（`xxx_item.cs`）

```csharp
using Newtonsoft.Json;
using SDP.Models;
using SDP.WebBasics;
using System;

namespace Xxx.Model.XxxModule
{
    /// <summary>
    /// 业务项目
    /// </summary>
    [Table("public.xxx_item")]
    public class xxx_item
    {
        [JsonConverter(typeof(NumberConverter), NumberConverterShip.Int64)]
        public long? id { get; set; }

        /// <summary>
        /// 所属系统/模块ID
        /// </summary>
        [JsonConverter(typeof(NumberConverter), NumberConverterShip.Int64)]
        public long? parent_id { get; set; }

        /// <summary>
        /// 名称
        /// </summary>
        public string name { get; set; }

        /// <summary>
        /// 启用状态：1启用 0禁用
        /// </summary>
        public int status { get; set; }

        /// <summary>
        /// 描述
        /// </summary>
        public string description { get; set; }

        /// <summary>
        /// 创建人
        /// </summary>
        public string creator { get; set; }

        public DateTime? create_time { get; set; } = DateTime.Now;

        /// <summary>
        /// 更新人
        /// </summary>
        public string updator { get; set; }

        public DateTime? update_time { get; set; }
    }
}
```

#### 查询入参（`xxx_item_s.cs`）

```csharp
using Newtonsoft.Json;
using SDP.WebBasics;

namespace Xxx.Model.XxxModule
{
    /// <summary>
    /// 查询业务项目入参
    /// </summary>
    public class xxx_item_s
    {
        [JsonConverter(typeof(NumberConverter), NumberConverterShip.Int64)]
        public long? id { get; set; }

        [JsonConverter(typeof(NumberConverter), NumberConverterShip.Int64)]
        public long? parent_id { get; set; }

        public string name { get; set; }

        public int? status { get; set; }
    }
}
```

#### 删除入参（`xxx_item_d.cs`）

```csharp
using Newtonsoft.Json;
using SDP.WebBasics;

namespace Xxx.Model.XxxModule
{
    /// <summary>
    /// 删除业务项目入参
    /// </summary>
    public class xxx_item_d
    {
        [JsonConverter(typeof(NumberConverter), NumberConverterShip.Int64)]
        public long id { get; set; }

        /// <summary>
        /// 操作人
        /// </summary>
        public string operator_name { get; set; }
    }
}
```

#### 更新状态入参（`xxx_item_us.cs`）

```csharp
using Newtonsoft.Json;
using SDP.WebBasics;

namespace Xxx.Model.XxxModule
{
    /// <summary>
    /// 更新业务项目启用状态入参
    /// </summary>
    public class xxx_item_us
    {
        [JsonConverter(typeof(NumberConverter), NumberConverterShip.Int64)]
        public long id { get; set; }

        /// <summary>
        /// 1启用 0禁用
        /// </summary>
        public int status { get; set; }
    }
}
```

---

### 2. Interface 层（`IXxxItemManage.cs`）

```csharp
using SDP.WebBasics;
using System.Collections.Generic;
using System.Threading.Tasks;
using Xxx.Model.XxxModule;

namespace Xxx.Interface.XxxModule
{
    public interface IXxxItemManage
    {
        Task<List<xxx_item>> SelectXxxItem(xxx_item_s model);
        Task<ResponseModel> AddXxxItem(xxx_item model);
        Task<ResponseModel> UpdateXxxItem(xxx_item model);
        Task<ResponseModel> UpdateXxxItemStatus(xxx_item_us model);
        Task<ResponseModel> DeleteXxxItem(xxx_item_d model);
    }
}
```

---

### 3. Logic 层（`XxxItemManageLogic.cs`）

```csharp
using SDP.DataIntface;
using SDP.IService;
using SDP.SystemLibrary.Utils;
using SDP.WebBasics;
using System;
using System.Collections.Generic;
using Xxx.Model.XxxModule;

namespace Xxx.Logic.XxxModule
{
    public class XxxItemManageLogic : BaseLogic
    {
        static Logger Log = Logger.Instance;
        string tablespace = "com"; // 根据实际域修改：inp/outpatient/fee/lab/pacs等

        /// <summary>
        /// 查询业务项目
        /// </summary>
        public List<xxx_item> SelectXxxItem(xxx_item_s model)
        {
            try
            {
                using (DbContext db = new DbContext(tablespace))
                {
                    var query = db.Select("public.xxx_item")
                        .Columns("*");

                    if (model.id.HasValue)
                        query.Where("id", model.id);
                    if (model.parent_id.HasValue)
                        query.Where("parent_id", model.parent_id);
                    if (!string.IsNullOrEmpty(model.name))
                        query.WhereLike("name", $"%{model.name}%");
                    if (model.status.HasValue)
                        query.Where("status", model.status);

                    return query.GetModelList<xxx_item>();
                }
            }
            catch (Exception ex)
            {
                Log.Error("查询业务项目出错：", ex);
                return null;
            }
        }

        /// <summary>
        /// 新增业务项目
        /// </summary>
        public (int isSuccess, string msg) AddXxxItem(xxx_item model)
        {
            try
            {
                using (DbContext db = new DbContext(tablespace))
                {
                    // 重名校验
                    int num = db.Select("public.xxx_item")
                        .Columns("count(1)")
                        .Where("name", model.name)
                        .Select<int>();
                    if (num > 0)
                    {
                        Log.Warn($"[AddXxxItem] name already exists: {model.name}");
                        return (-1, "名称已存在");
                    }

                    if (model.id == null || model.id == 0)
                        model.id = Strings.GuidToLongID();
                    model.create_time = DateTime.Now;

                    int a = db.Insert(model).Execute();
                    if (a <= 0)
                    {
                        Log.Warn("[AddXxxItem] insert failed");
                        return (-1, "写入失败");
                    }
                }
                return (1, model.id.ToString());
            }
            catch (Exception ex)
            {
                Log.Error("新增业务项目出错：", ex);
                return (-1, ex.Message);
            }
        }

        /// <summary>
        /// 修改业务项目
        /// </summary>
        public (int isSuccess, string msg) UpdateXxxItem(xxx_item model)
        {
            try
            {
                using (DbContext db = new DbContext(tablespace))
                {
                    model.update_time = DateTime.Now;
                    int a = db.Update(model)
                        .Where("id", model.id)
                        .Execute();
                    if (a <= 0)
                    {
                        Log.Warn($"[UpdateXxxItem] update failed, id={model.id}");
                        return (-1, "更新失败");
                    }
                }
                return (1, "");
            }
            catch (Exception ex)
            {
                Log.Error("修改业务项目出错：", ex);
                return (-1, ex.Message);
            }
        }

        /// <summary>
        /// 更新启用状态
        /// </summary>
        public int UpdateXxxItemStatus(xxx_item_us model)
        {
            try
            {
                using (DbContext db = new DbContext(tablespace))
                {
                    int a = db.Update("public.xxx_item")
                        .Set("status", model.status)
                        .Where("id", model.id)
                        .Execute();
                    return a > 0 ? 1 : -1;
                }
            }
            catch (Exception ex)
            {
                Log.Error("更新业务项目状态出错：", ex);
                return -1;
            }
        }

        /// <summary>
        /// 删除业务项目
        /// </summary>
        public int DeleteXxxItem(xxx_item_d model)
        {
            try
            {
                using (DbContext db = new DbContext(tablespace))
                {
                    int a = db.Delete("public.xxx_item")
                        .Where("id", model.id)
                        .Execute();
                    if (a <= 0)
                    {
                        Log.Warn($"[DeleteXxxItem] delete failed, id={model.id}");
                        return -1;
                    }
                }
                return 1;
            }
            catch (Exception ex)
            {
                Log.Error("删除业务项目出错：", ex);
                return -1;
            }
        }
    }
}
```

---

### 4. Logic 层（`XxxItemManageLogic.cs`）

```csharp
using SDP.WebBasics;
using System.Threading.Tasks;
using Xxx.Logic.XxxModule;
using Xxx.Model.XxxModule;

namespace Xxx.Logic.XxxModule
{
    public class XxxItemManageLogic
    {
        XxxItemManageLogic logic = new XxxItemManageLogic();

        public Task<ResponseModel> SelectXxxItem(xxx_item_s model)
        {
            ResponseModel response = new ResponseModel();
            var result = logic.SelectXxxItem(model);
            response.code = result == null ? 500 : 200;
            response.data = result;
            response.msg = result == null ? "查询失败" : "查询成功";
            return Task.FromResult(response);
        }

        public Task<ResponseModel> AddXxxItem(xxx_item model)
        {
            ResponseModel response = new ResponseModel();
            var result = logic.AddXxxItem(model);
            response.code = result.isSuccess == 1 ? 200 : 500;
            response.msg = "新增业务项目" + (result.isSuccess == 1 ? "成功" : $"失败：{result.msg}");
            response.data = result.isSuccess == 1 ? result.msg : null; // 返回新增ID
            return Task.FromResult(response);
        }

        public Task<ResponseModel> UpdateXxxItem(xxx_item model)
        {
            ResponseModel response = new ResponseModel();
            var result = logic.UpdateXxxItem(model);
            response.code = result.isSuccess == 1 ? 200 : 500;
            response.msg = "修改业务项目" + (result.isSuccess == 1 ? "成功" : $"失败：{result.msg}");
            return Task.FromResult(response);
        }

        public Task<ResponseModel> UpdateXxxItemStatus(xxx_item_us model)
        {
            ResponseModel response = new ResponseModel();
            var result = logic.UpdateXxxItemStatus(model);
            response.code = result == 1 ? 200 : 500;
            response.msg = "更新业务项目状态" + (result == 1 ? "成功" : "失败");
            return Task.FromResult(response);
        }

        public Task<ResponseModel> DeleteXxxItem(xxx_item_d model)
        {
            ResponseModel response = new ResponseModel();
            var result = logic.DeleteXxxItem(model);
            response.code = result == 1 ? 200 : 500;
            response.msg = "删除业务项目" + (result == 1 ? "成功" : "失败");
            return Task.FromResult(response);
        }
    }
}
```

---

### 5. WebApi Controller 层（`XxxItemManageController.cs`）

```csharp
using Microsoft.AspNetCore.Mvc;
using SDP.WebBasics;
using System.Threading.Tasks;
using Xxx.Logic.XxxModule;
using Xxx.Model.XxxModule;

namespace Xxx.WebApi.Controllers.XxxModule
{
    public class XxxItemManageController : XxxBasicsController
    {
        private XxxItemManageLogic Logic = new XxxItemManageLogic();

        /// <summary>
        /// 查询业务项目
        /// </summary>
        [HttpPost]
        [UPEncryption("", false, false)]
        [RIPAuthority("查询业务项目", "查询业务项目", "CICT", "2025/01/01")]
        [ProducesResponseType(typeof(ResponseModel), 200)]
        public async Task<IActionResult> SelectXxxItem(xxx_item_s model)
        {
            var r = await Logic.SelectXxxItem(model);
            return Json(r);
        }

        /// <summary>
        /// 新增业务项目
        /// </summary>
        [HttpPost]
        [UPEncryption("", false, false)]
        [RIPAuthority("新增业务项目", "新增业务项目", "CICT", "2025/01/01")]
        [ProducesResponseType(typeof(ResponseModel), 200)]
        public async Task<IActionResult> AddXxxItem(xxx_item model)
        {
            var r = await Logic.AddXxxItem(model);
            return Json(r);
        }

        /// <summary>
        /// 修改业务项目
        /// </summary>
        [HttpPost]
        [UPEncryption("", false, false)]
        [RIPAuthority("修改业务项目", "修改业务项目", "CICT", "2025/01/01")]
        [ProducesResponseType(typeof(ResponseModel), 200)]
        public async Task<IActionResult> UpdateXxxItem(xxx_item model)
        {
            var r = await Logic.UpdateXxxItem(model);
            return Json(r);
        }

        /// <summary>
        /// 更新业务项目启用状态
        /// </summary>
        [HttpPost]
        [UPEncryption("", false, false)]
        [RIPAuthority("更新业务项目状态", "更新业务项目状态", "CICT", "2025/01/01")]
        [ProducesResponseType(typeof(ResponseModel), 200)]
        public async Task<IActionResult> UpdateXxxItemStatus(xxx_item_us model)
        {
            var r = await Logic.UpdateXxxItemStatus(model);
            return Json(r);
        }

        /// <summary>
        /// 删除业务项目
        /// </summary>
        [HttpPost]
        [UPEncryption("", false, false)]
        [RIPAuthority("删除业务项目", "删除业务项目", "CICT", "2025/01/01")]
        [ProducesResponseType(typeof(ResponseModel), 200)]
        public async Task<IActionResult> DeleteXxxItem(xxx_item_d model)
        {
            var r = await Logic.DeleteXxxItem(model);
            return Json(r);
        }
    }
}
```

---
**文档来源**: Keiskei 整理的HIS知识库  
**整理说明**: 从Windows桌面知识库整理到his-wiki统一管理  
**模板类型**: CRUD接口开发  
**适用项目**: .NET 8.0 HIS 5.1  
**核心内容**: 分层架构、命名规范、完整代码模板  
**相关文档**: [插件开发模板](plugin-development.md)、[查询接口模板](query-template.md)