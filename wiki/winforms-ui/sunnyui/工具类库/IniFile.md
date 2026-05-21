# IniFile — Ini 文件读写类

> raw 原文：`raw/SunnyUI文档/工具类库/IniFile -  Ini文件读写类.md` ｜ raw 同步：V3.9.7 / 2026-05-21

基类 `IniBase`，已处理中文读写。

> **建议**：读写的 Ini 文件优先用 IniFile 生成的——避免文件编码不统一。

---

## Ini 文件结构

```ini
;<!--配置文件-->         ← 注释（分号开头）
[Setup]                 ← Section
Name=Sunny              ← parameter (name=value)
Age=18
```

**注释规则**：以 `;` 开头，独占一行直到结束。

## 支持的数据类型

Windows API 原生只支持 string；IniFile 类型转换扩展到：

`bool, byte, byte[], char, Color, Datetime, decimal, double, float, int, long, Point, PointF, sbyte, short, Size, SizeF, uint, ulong, ushort, Struct*`

## 写文件

```csharp
IniFile ini = new IniFile("D:\\setup.ini");
ini.Write("Setup", "Name", "Sunny");
ini.Write("Setup", "Age", 18);
ini.UpdateFile();   // 必须调用，否则不落盘
```

**陷阱**：文件名必须是**完全路径**，不能用相对路径。生成到程序目录：

```csharp
IniFile ini = new IniFile(DirEx.CurrentDir() + "Setup.ini");
```

**权限提醒**：写 C 盘文件（Win7 以上）需运行程序有相应权限。

## 读文件

```csharp
IniFile ini = new IniFile("D:\\setup.ini");
string name = ini.ReadString("Setup", "Name", "");   // default = ""
int age = ini.ReadInt("Setup", "Age", 0);            // default = 0
```

Read 函数三个参数：section、name、default（值不存在时返回 default）。

## 其他函数

| 函数 | 用途 |
| --- | --- |
| `string[] GetKeys(string section)` | 获取指定 Section 的所有 Key |
| `string[] Sections` | 所有 Section 名称 |
| `void GetSectionValues(string section, NameValueCollection)` | 读取指定 Section 所有 Value 到列表 |
| `void EraseSection(string section)` | 清除某个 Section |
| `void DeleteKey(string section, string key)` | 删除某个键 |
| `bool KeyExists(string section, string key)` | 检查键是否存在 |

## 进阶：用类映射配置

需要把整个配置文件映射到一个类（按字段读写而不是按字符串）？用 [IniConfig](IniConfig.md)。
