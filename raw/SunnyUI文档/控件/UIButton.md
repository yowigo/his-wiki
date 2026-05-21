-  **UIButton** 
常用的操作按钮。

- 默认属性：Text
- 默认事件：Click
- 属性列表

| 属性        | 说明     | 类型     |  默认值   |
|-----------|--------|--------|-------|
| Style | 主题样式  | UIStyle  |  Blue     |
| StyleCustomMode | 获取或设置可以自定义主题风格   | bool  | false |
| Text  |获取或设置显示的文本  | string | -   | 
| RadiusSides | 圆角显示位置  | UICornerRadiusSides  |  All     |
| Radius | 圆角角度  | int  | 5     |
| RectSides | 边框显示位置  | ToolStripStatusLabelBorderSides  |  All     |
| TextAlign | 文字对齐方向  | ContentAlignment  |  MiddleCenter     |
| Selected  | 是否选中   | bool   |  false |
| FillColor | 填充颜色   | Color  | -     |
| RectColor | 边框颜色   | Color  | -   |
| ForeColor | 字体颜色   | Color  | -   |
| FillDisableColor | 不可用时填充颜色   | Color  | -   | 
| RectDisableColor | 不可用时边框颜色   | Color  | -   | 
| ForeDisableColor | 不可用时字体颜色   | Color  | -   | 
| FillHoverColor | 鼠标移上时填充颜色   | Color  | -   | 
| RectHoverColor | 鼠标移上时边框颜色   | Color  | -   | 
| ForeHoverColor | 鼠标移上时字体颜色   | Color  | -   | 
| FillPressColor | 鼠标按下时填充颜色   | Color  | -   | 
| RectPressColor | 鼠标按下时边框颜色   | Color  | -   | 
| ForePressColor | 鼠标按下时字体颜色   | Color  | -   | 
| FillSelectedColor | 选中时填充颜色   | Color  | -   | 
| ForeSelectedColor | 选中时字体颜色   | Color  | -   | 
| RectSelectedColor | 选中时边框颜色   | Color  | -   | 
| DialogResult | 指定标识符以指示对话框的返回值   | DialogResult  |  None     |
| ShowFocusLine | 显示激活时边框线   | bool  | false    |
| ShowTips  | 是否显示角标 | bool   |  false |
| TipsText  | 角标文字   | string | -   | 
| TipsFont  | 角标文字字体 | Font   | -   | 
| TipsColor | 角标文字颜色 | Color  | Red   |
| TagString | 获取或设置包含有关控件的数据的对象字符串   | string | -   | 
| Version | 版本  | string  |  -     |
| UseDoubleClick | 是否启用双击事件  | bool  |false     |

- 主题风格
 **主题**  https://gitee.com/yhuse/SunnyUI/wikis/pages?sort_id=3739705&doc_id=1022550<br/>

- 主题设置
![输入图片说明](https://images.gitee.com/uploads/images/2021/0127/210431_9babaaa5_416720.png "1.png")
  设置Style属性调用系统自带主题，如果需要自定义颜色，就是更改颜色属性后，把控件的Style设置为Custom，StyleCustomMode设置为True
  StyleCustomMode就是接受用户自定义颜色的意思。

- 圆角按钮
![输入图片说明](https://images.gitee.com/uploads/images/2021/0127/210532_8b597bd0_416720.png "2.png")
  设置Radius和高度一样，例如Size:100,35  Radius:35
