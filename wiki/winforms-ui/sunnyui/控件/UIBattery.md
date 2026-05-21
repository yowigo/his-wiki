# UIBattery — 电池电量图标

> raw 原文：`raw/SunnyUI文档/控件/UIBattery.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Power` ｜ **默认事件**：无
- 用途：工控面板 / 设备状态展示

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Power` | int | 100 | 电量值（0~100） |
| `MultiColor` | bool | true | 根据电量显示多种颜色 |
| `ForeColor` | Color | - | 默认电量颜色（MultiColor=false 时单色） |
| `ColorEmpty` | Color | - | 电量为空颜色 |
| `ColorDanger` | Color | - | 电量少时颜色 |
| `ColorSafe` | Color | - | 电量安全颜色 |
| `FillColor` | Color | - | 填充颜色 |
| `SymbolSize` | int | 45 | 图标大小 |

## 用法要点

- **MultiColor=false**：电池整体显示同一颜色（用 ForeColor）
- **MultiColor=true**（默认）：低电量红、中电量黄、高电量绿，自动切换
