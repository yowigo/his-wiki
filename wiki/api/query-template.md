# 查询接口模板（分页/筛选）

**源文件物理路径**: `/mnt/c/Users/xuyilai/Desktop/knowledge/his-kb/02-接口模板/查询接口模板.md`  
**整理后路径**: `/home/xuyilai/his-wiki/wiki/api/query-template.md`  
**整理时间**: 2026-04-16  
**整理者**: 小柔助手 🌸  

HIS 5.1 分页查询和复杂筛选查询的标准实现模式。

## 分页查询

### 分页入参 Model

```csharp
namespace Xxx.Model.XxxModule
{
    /// <summary>
    /// 业务项目分页查询入参
    /// </summary>
    public class xxx_item_page_s
    {
        /// <summary>
        /// 当前页（从1开始）
        /// </summary>
        public int page_num { get; set; } = 1;

        /// <summary>
        /// 每页条数
        /// </summary>
        public int page_size { get; set; } = 20;

        // --- 筛选条件 ---
        public string keyword { get; set; }

        public int? status { get; set; }

        public string start_date { get; set; }

        public string end_date { get; set; }
    }
}
```

### Logic 层分页查询

#### 方式一：ORM 链式查询分页（简单条件）

```csharp
/// <summary>
/// 分页查询业务项目
/// </summary>
public (bool result, string msg, ListPageModel<xxx_item> data) SelectXxxItemPage(xxx_item_page_s model)
{
    try
    {
        using (DbContext db = new DbContext(tablespace))
        {
            var query = db.Select("public.xxx_item")
                .Columns("*")
                .OrderBy("create_time desc");

            if (!string.IsNullOrEmpty(model.keyword))
                query.WhereLike("name", $"%{model.keyword}%");
            if (model.status.HasValue)
                query.Where("status", model.status);
            if (!string.IsNullOrEmpty(model.start_date))
                query.WhereGte("create_time", model.start_date);
            if (!string.IsNullOrEmpty(model.end_date))
                query.WhereLte("create_time", model.end_date);

            var data = query.Paging(model.page_num, model.page_size)
                            .GetModelList<xxx_item>(out int total);

            return (true, "查询成功", new ListPageModel<xxx_item>
            {
                Total = total,
                PageList = data
            });
        }
    }
    catch (Exception ex)
    {
        Log.Error("分页查询业务项目出错：", ex);
        return (false, ex.Message, null);
    }
}
```

#### 方式二：SQL 文件 + 动态参数分页（复杂条件）

```csharp
/// <summary>
/// 分页查询（SQL文件方式，适合多表关联/复杂筛选）
/// </summary>
public (bool result, string msg, ListPageModel<XxxItemOut> data) SelectXxxItemPageBySql(xxx_item_page_s model)
{
    try
    {
        using (DbContext db = new DbContext(tablespace))
        {
            var parm = new List<string>();
            var sqlBuilder = db.Sql("");

            // 动态拼接查询条件标记
            if (!string.IsNullOrEmpty(model.keyword))
            {
                parm.Add("keyword");
                sqlBuilder.Parameters("keyword", $"%{model.keyword}%");
            }
            if (model.status.HasValue)
            {
                parm.Add("status");
                sqlBuilder.Parameters("status", model.status);
            }
            if (!string.IsNullOrEmpty(model.start_date))
            {
                parm.Add("start_date");
                sqlBuilder.Parameters("start_date", model.start_date);
            }
            if (!string.IsNullOrEmpty(model.end_date))
            {
                parm.Add("end_date");
                sqlBuilder.Parameters("end_date", model.end_date);
            }

            // SQL文件名规范：模块前缀-功能描述，如 "YS-GetXxxItemList"
            string sqlStr = db.GetSql("XX-GetXxxItemList", null, parm.ToArray());

            var data = sqlBuilder.SqlText(sqlStr)
                                 .Paging(model.page_num, model.page_size)
                                 .GetModelList<XxxItemOut>(out int total);

            return (true, "查询成功", new ListPageModel<XxxItemOut>
            {
                Total = total,
                PageList = data
            });
        }
    }
    catch (Exception ex)
    {
        Log.Error("分页查询业务项目出错：", ex);
        return (false, ex.Message, null);
    }
}
```

### 对应 SQL 文件结构（动态条件片段）

SQL 文件通过 `db.GetSql("文件名", null, 激活的条件标记)` 加载，未激活的条件片段自动跳过。

```sql
-- XX-GetXxxItemList.sql
SELECT
    xi.id,
    xi.name,
    xi.status,
    xi.description,
    xi.create_time
FROM public.xxx_item xi
WHERE 1=1
    /*[keyword]*/
    AND xi.name LIKE :keyword
    /*[keyword]*/
    /*[status]*/
    AND xi.status = :status
    /*[status]*/
    /*[start_date]*/
    AND xi.create_time >= :start_date
    /*[start_date]*/
    /*[end_date]*/
    AND xi.create_time <= :end_date
    /*[end_date]*/
ORDER BY xi.create_time DESC
```

### Integrate 层

```csharp
public Task<ResponseModel> SelectXxxItemPage(xxx_item_page_s model)
{
    ResponseModel response = new ResponseModel();
    var result = logic.SelectXxxItemPage(model);
    response.code = result.result ? 200 : 500;
    response.data = result.data;
    response.msg = result.msg;
    return Task.FromResult(response);
}
```

### Controller 层

```csharp
/// <summary>
/// 分页查询业务项目
/// </summary>
[HttpPost]
[UPEncryption("", false, false)]
[RIPAuthority("分页查询业务项目", "分页查询业务项目", "CICT", "2025/01/01")]
[ProducesResponseType(typeof(ResponseModel), 200)]
public async Task<IActionResult> SelectXxxItemPage(xxx_item_page_s model)
{
    var r = await integrate.SelectXxxItemPage(model);
    return Json(r);
}
```

### 返回结构

```json
{
    "code": 200,
    "msg": "查询成功",
    "data": {
        "Total": 100,
        "PageList": [
            { "id": "...", "name": "...", "status": 1, ... }
        ]
    }
}
```

---

## 不分页查询（列表/下拉）

适合数据量小、不需要分页的场景（如下拉选项、树形数据）。

```csharp
/// <summary>
/// 查询业务项目列表（不分页）
/// </summary>
public List<xxx_item> SelectXxxItemList(xxx_item_s model)
{
    try
    {
        using (DbContext db = new DbContext(tablespace))
        {
            var query = db.Select("public.xxx_item")
                .Columns("id, name, status")
                .Where("status", 1); // 默认只查启用的

            if (model.parent_id.HasValue)
                query.Where("parent_id", model.parent_id);

            return query.OrderBy("sno asc").GetModelList<xxx_item>();
        }
    }
    catch (Exception ex)
    {
        Log.Error("查询业务项目列表出错：", ex);
        return null;
    }
}
```

---

## 单条详情查询

```csharp
/// <summary>
/// 查询单条业务项目详情
/// </summary>
public xxx_item GetXxxItemById(long id)
{
    try
    {
        using (DbContext db = new DbContext(tablespace))
        {
            return db.Select("public.xxx_item")
                .Columns("*")
                .Where("id", id)
                .GetModel<xxx_item>();
        }
    }
    catch (Exception ex)
    {
        Log.Error($"查询业务项目详情出错, id={id}：", ex);
        return null;
    }
}
```

---

## 关联查询（多表）

多表关联推荐使用 SQL 文件方式，出参用独立的 DTO 类。

```csharp
// 出参 DTO（不对应数据库表，不加 [Table] 特性）
public class XxxItemOut
{
    public long id { get; set; }
    public string name { get; set; }
    public string parent_name { get; set; }  // 关联表字段
    public int status { get; set; }
    public string creator_display { get; set; } // 格式化后的字段
}
```

```csharp
// Logic 中使用原生 SQL
public List<XxxItemOut> SelectXxxItemWithRelation(xxx_item_s model)
{
    try
    {
        using (DbContext db = new DbContext(tablespace))
        {
            var sql = @"
                SELECT
                    xi.id,
                    xi.name,
                    xp.name AS parent_name,
                    xi.status
                FROM public.xxx_item xi
                LEFT JOIN public.xxx_parent xp ON xi.parent_id = xp.id
                WHERE xi.status = :status";

            return db.Sql(sql)
                .Parameters("status", model.status ?? 1)
                .GetModelList<XxxItemOut>();
        }
    }
    catch (Exception ex)
    {
        Log.Error("关联查询业务项目出错：", ex);
        return null;
    }
}
```

---

## 统计/汇总查询

```csharp
// 入参
public class xxx_stat_s
{
    public string start_date { get; set; }
    public string end_date { get; set; }
    public int? group_type { get; set; }
}

// 出参
public class xxx_stat_out
{
    public string group_key { get; set; }
    public int total_count { get; set; }
    public decimal total_amount { get; set; }
}

// Logic
public List<xxx_stat_out> SelectXxxStat(xxx_stat_s model)
{
    try
    {
        using (DbContext db = new DbContext(tablespace))
        {
            var sql = @"
                SELECT
                    DATE(create_time) AS group_key,
                    COUNT(1) AS total_count
                FROM public.xxx_item
                WHERE create_time BETWEEN :start_date AND :end_date
                GROUP BY DATE(create_time)
                ORDER BY group_key";

            return db.Sql(sql)
                .Parameters("start_date", model.start_date)
                .Parameters("end_date", model.end_date)
                .GetModelList<xxx_stat_out>();
        }
    }
    catch (Exception ex)
    {
        Log.Error("汇总查询业务项目出错：", ex);
        return null;
    }
}
```

---

## 查询规范速查

| 场景 | 推荐方式 |
|------|---------|
| 单表简单筛选 | ORM 链式 `.Where().GetModelList<T>()` |
| 复杂多条件 + 分页 | SQL 文件 + `.Paging().GetModelList<T>(out total)` |
| 多表关联 | 内联 SQL + DTO 出参 |
| 下拉/树形（少量数据） | 不分页，加 `.Where("status", 1)` 过滤禁用 |
| 统计汇总 | 内联 SQL，GROUP BY |

## DbContext 常用方法

```csharp
// 条件
.Where("field", value)          // field = value
.WhereLike("field", "%kw%")     // LIKE
.WhereGte("field", value)       // >=
.WhereLte("field", value)       // <=
.WhereIn("field", list)         // IN (...)
.WhereNotNull("field")          // IS NOT NULL

// 排序
.OrderBy("create_time desc")

// 分页
.Paging(page_num, page_size).GetModelList<T>(out int total)

// 不分页
.GetModelList<T>()

// 单条
.GetModel<T>()

// 聚合（count/sum等）
.Columns("count(1)").Select<int>()
.Columns("sum(amount)").Select<decimal>()
```

---
**文档来源**: Keiskei 整理的HIS知识库  
**整理说明**: 从Windows桌面知识库整理到his-wiki统一管理  
**模板类型**: 查询接口开发  
**适用项目**: .NET 8.0 HIS 5.1  
**核心内容**: 分页查询、动态SQL、关联查询、统计查询  
**相关文档**: [CRUD接口模板](crud-template.md)、[插件开发模板](plugin-development.md)