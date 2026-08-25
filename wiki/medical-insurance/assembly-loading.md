# 程序集依赖 / 反射加载（AssemblyResolver）

> 原始资料：`../../raw/外部接口开发/上海医保项目五期/程序集依赖加载说明.md`、`AssemblyResolver故障排查.md`、`问题分析与解决方案.md`
> 适用：所有被总控 `sdp.cpapi` 用 `Assembly.Load(byte[])` 反射加载的插件（医保插件 `zlchs.SH.GJBYB.insure` 等）
> 关联页面：[上海医保五期插件](shanghai-5th.md)、[医保原生动态库缺失排查案例](../troubleshooting/medical-insurance/issue-20260606-native-dll-not-found.md)

## 问题背景

主程序反射加载插件 DLL：

```csharp
targetAssembly = Assembly.Load(File.ReadAllBytes(Path.Combine(path, assemblyName + ".dll")));
foreach (Type clsName in targetAssembly.GetTypes()) { ... }
```

该方式导致：

1. **程序集无物理路径**——`Assembly.Load(byte[])` 加载的程序集 `Location` 属性为空；
2. **依赖无法自动定位**——依赖的 DLL（NPOI、SharpZipLib、BouncyCastle 等）找不到，抛 `TypeLoadException`；
3. **无法修改主程序**——不能靠主程序配置或代码解决。

## 解决方案：DLL 内部 AssemblyResolve

在插件 DLL 内部实现 `AppDomain.AssemblyResolve` 事件处理，从**指定子目录**加载依赖。

### 实现文件

| 文件 | 职责 |
| --- | --- |
| `AssemblyResolver.cs` | 静态构造函数自动注册 `AppDomain.AssemblyResolve`；支持从多个路径获取 DLL 目录（含 byte[] 加载场景）；从指定子目录自动加载依赖 |
| `Cls_SHGBYB.cs` | 静态构造函数触发 `ModuleInitializer.EnsureInitialized()`，确保任何方法调用前完成初始化 |
| `Properties/AssemblyInfo.cs` | 添加 `AssemblyInitializer` 强制在程序集加载时初始化 |

### 部署目录结构

```
主程序目录/
├── 主程序.exe
├── zlchs.SH.GJBYB.insure.dll        ← 医保接口 DLL
└── libs/                             ← 依赖 DLL 存放目录（NPOI* / SharpZipLib / Newtonsoft.Json / BouncyCastle / System.* 等）
```

> ⚠️ **libs 目录必须与 DLL 同级**。运行期三方 DLL → `libs\`；读卡器/五期通讯 DLL（`SendRcv4.dll` / `HeaSecReadInfo.dll` / `NationECCode.dll`）→ `shLibs\`。

### 搜索优先级

1. `libs/` 子目录 ⭐ 推荐
2. `dependencies/` 子目录
3. `bin/` 子目录
4. DLL 所在目录（最后）

### DLL 目录获取策略（byte[] 场景）

```
1. RequestingAssembly.Location  ← 最关键（请求加载依赖的程序集）
2. Assembly.Location             ← 标准方式
3. 已加载程序集查找              ← 遍历 AppDomain
4. Assembly.CodeBase             ← 备用方案
```

### 三层初始化机制

`Assembly.Load(byte[])` 后 `GetTypes()` 不一定触发静态构造函数，因此做三层兜底：

1. **AssemblyInitializer**（AssemblyInfo.cs）— 程序集级别，最早
2. **ModuleInitializer**（AssemblyResolver.cs）— 模块级别，次早
3. **Cls_SHGBYB 静态构造函数** — 类型级别，保底

## 部署方式

- **方案 A：手动部署** — 编译后把依赖 DLL 全部复制到 `libs` 子目录。
- **方案 B：后期生成事件（推荐）** — .csproj 添加 `CopyDependenciesToLibs` Target，AfterTargets=Build 排除主 DLL / `zlchs.*` / `ZLSoft.*` / `Oracle.*` 后复制到 `$(OutputPath)libs`。

## 日志与排查

- 加载日志在 `InsureLog/YYYYMMDD.log`：✓ 成功路径 / ✗ 失败程序集与错误 / DLL 目录定位过程 / 搜索路径。
- 排查步骤：
  1. 看日志「尝试解析程序集」条目；
  2. `dir /s *.dll` 确认 libs 存在且依赖齐全；
  3. DLL 文件名与程序集名一致（`NPOI.OOXML.dll` ↔ 程序集 `NPOI.OOXML`）；
  4. 调试时手动触发：`initType?.GetMethod("EnsureInitialized")?.Invoke(null, null)`；
  5. `fuslogvw.exe`（Fusion Log Viewer）查看绑定日志。

## 注意事项

1. libs 与 DLL 同级；
2. 依赖版本与 App.config 的 bindingRedirect 一致，推荐同 .NET Framework 版本；
3. 解析器只在找不到程序集时触发，已加载不重复加载，目录路径缓存；
4. 安全：只从预定义子目录加载，用 `Assembly.LoadFrom` 而非 `Assembly.LoadFile`，保持强命名签名。

