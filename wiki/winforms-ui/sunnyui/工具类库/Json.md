# Json — 简易 Json 静态类

> raw 原文：`raw/SunnyUI文档/工具类库/Json - 简易的Json静态类.md` ｜ raw 同步：V3.9.7 / 2026-05-21

不依赖 Newtonsoft 的简易 Json 操作。复杂需求仍推荐 Newtonsoft.Json 或 System.Text.Json。

---

## 实现原理

| 框架 | 底层 |
| --- | --- |
| .NET Framework | `System.Web.Script.Serialization.JavaScriptSerializer` |
| .NET Core / .NET 5+ | `System.Text.Json.JsonSerializer` |

## 函数

```csharp
// 反序列化
public static T Deserialize<T>(string input);

// 序列化
public static string Serialize(object obj);

// 从文件读取并反序列化
public static T DeserializeFromFile<T>(string filename, Encoding encoding);

// 序列化并写入文件
public static string SerializeToFile(object obj, string filename, Encoding encoding);
```

## 使用建议

| 场景 | 推荐方案 |
| --- | --- |
| 简单类型/小对象、不想引依赖 | `Sunny.UI.Json` |
| 复杂对象、自定义 Converter、性能要求 | Newtonsoft.Json |
| .NET 5+ 项目 | `System.Text.Json`（性能优秀） |

> HIS 插件项目当前使用 Newtonsoft.Json 12.0.3，配置序列化保持沿用，不要混用此简易类。
