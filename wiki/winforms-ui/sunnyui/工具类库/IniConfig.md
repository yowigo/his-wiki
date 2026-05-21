# IniConfig — Ini 配置文件类

> raw 原文：`raw/SunnyUI文档/工具类库/IniConfig - ini配置文件类.md` ｜ raw 同步：V3.9.7 / 2026-05-21

底层基于 [IniFile](IniFile.md)，**用反射把配置文件映射成类的属性**——免去字符串 section/name 的繁琐。

---

## 适用场景

写 IniFile 时需要：

```csharp
IniFile ini = new IniFile("D:\\setup.ini");
string ip = ini.ReadString("Setup", "ServerIP", "");
int port = ini.ReadInt("Setup", "ServerPort", 0);
```

用 IniConfig 可改写为：

```csharp
Setting.Current.Load();
TcpClient client = new TcpClient();
client.Connect(Setting.Current.ServerIP, Setting.Current.ServerPort);
```

---

## 完整示例

### 1. 定义配置类

```csharp
[ConfigFile("Config\\Setting.ini")]
public class Setting : IniConfig<Setting>
{
    [ConfigSection("Hello")]
    public string SoftName { get; set; }

    public string ServerIP { get; set; }
    public int ServerPort { get; set; }
    public string City { get; set; }

    public override void SetDefault()
    {
        base.SetDefault();
        SoftName = "XX软件";
        ServerIP = "192.168.1.2";
        ServerPort = 9090;
        City = "南京";
    }
}
```

### 2. Attribute 说明

| 特性 | 作用 |
| --- | --- |
| `[ConfigFile("Config\\Setting.ini")]` | 配置文件路径（程序目录下相对路径）；**目录不存在会自动创建** |
| `[ConfigSection("Hello")]` | 属性所在 Section 名（默认 `Setup`） |

### 3. SetDefault()

第一次运行**配置文件不存在**时调用——把默认值写入文件。

### 4. 读取

```csharp
Setting.Current.Load();
// 此时 Setting.Current.ServerIP 等于配置文件里的值
```

### 5. 修改并保存

```csharp
Setting.Current.City = "重庆";
Setting.Current.Save();
```

---

## ⚠️ 关键陷阱

- **使用 `Setting.Current`，不是 `Setting`**——所有读写操作都在 `.Current` 单例上
- **不要手动创建 ini 文件**——先让程序自动生成，再修改；避免编码不统一
- **支持的属性类型**：和 [IniFile](IniFile.md) 一致（bool/byte/byte[]/char/Color/Datetime/decimal/double/float/int/long/Point/PointF/sbyte/short/Size/SizeF/uint/ulong/ushort/Struct*）
