# UILoginForm — 登录窗体基类

> raw 原文：`raw/SunnyUI文档/窗体/UILoginForm.md` ｜ raw 同步：V3.9.7 / 2026-05-21

## 速查

- **默认属性**：`Text` ｜ **默认事件**：`OnLogin`
- 用途：开箱即用的登录窗体，含用户名/密码/确定/取消，可挂登录逻辑

## 特有属性

| 属性 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `Title` | string | - | 顶部标题 |
| `SubText` | string | - | 底部文字描述（如版本号） |
| `LoginImage` | UILoginImage | - | 背景图片（内置几张可选） |
| `UserName` | string | - | 用户名（运行期读取） |
| `Password` | string | - | 密码（运行期读取） |
| `IsLogin` | bool | - | 登录是否成功（外部设置） |

## 事件

| 事件 | 触发时机 | 说明 |
| --- | --- | --- |
| `ButtonLoginClick` | 点击"确定" | **有此事件时不触发 OnLogin**；需手动给 IsLogin 赋值 |
| `ButtonCancelClick` | 点击"取消" | - |
| `OnLogin` | 点击"确定" | 仅当 ButtonLoginClick 为空时触发；返回值赋给 IsLogin |

## 使用方式 1：继承

新建窗体继承 UILoginForm，重写 `OnLogin` 验证逻辑。继承窗体的"登录按钮有小锁"是正常的——SunnyUI 把事件封装在父类，到**事件面板**找已有事件即可。

## 使用方式 2：代码创建

```csharp
UILoginForm frm = new UILoginForm();
frm.ShowInTaskbar = true;
frm.Text = "Login";
frm.Title = "SunnyUI.Net Login Form";
frm.SubText = Version;
frm.OnLogin += Frm_OnLogin;
frm.LoginImage = UILoginForm.UILoginImage.Login2;
frm.ShowDialog();

if (frm.IsLogin)
{
    UIMessageTip.ShowOk("登录成功");
}
frm.Dispose();

// 验证回调
private bool Frm_OnLogin(string userName, string password)
{
    return userName == "admin" && password == "admin";
}
```

`OnLogin` 返回值决定 `IsLogin`。返回 true 时窗体自动关闭并 `IsLogin = true`。

## 自定义背景图（V3.9.1+）

V3.9.1 起 LoginImage 支持自定义背景图——传 `UILoginImage.Custom` 并设自己的图片资源。

## 配置 AutoScaleMode

**和 UIForm 一样必须 `AutoScaleMode = None`**——否则在高分辨率下变形。
