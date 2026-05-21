-  **UICheckBox** 
复选框。

- 默认属性：Checked
- 默认事件：CheckedChanged
- 属性列表

| 属性        | 说明     | 类型     |  默认值   |
|-----------|--------|--------|-------|
| Style | 主题样式  | UIStyle  |  Blue     |
| StyleCustomMode | 获取或设置可以自定义主题风格   | bool  | false |
| Checked|是否选中 | bool| false| 
| Text  |获取或设置显示的文本  | string | -   | 
| AutoSize|自动大小  | bool| true   | 
| ImageSize|图标大小 | int| 16   | 
| ImageInterval|图标与文字之间间隔| int| 3  | 
| ReadOnly|是否只读| bool| false   | 
| ForeColor | 字体颜色   | Color  | -   |
| CheckBoxColor| 填充颜色  | Color  | -   |
| TagString | 获取或设置包含有关控件的数据的对象字符串   | string | -   | 
| Version | 版本  | string  |  -     |

- 事件
  CheckedChanged
  public event EventHandler CheckedChanged;
  参数sender：当前控件

  ValueChanged
  public delegate void OnValueChanged(object sender, bool value);
  参数sender：当前控件
  参数value：选中值，Checked

- 主题风格
 **主题**  https://gitee.com/yhuse/SunnyUI/wikis/pages?sort_id=3739705&doc_id=1022550<br/>

- 主题设置
  设置Style属性调用系统自带主题，如果需要自定义颜色，就是更改颜色属性后，把控件的Style设置为Custom，StyleCustomMode设置为True
  StyleCustomMode就是接受用户自定义颜色的意思。

- 示例
![输入图片说明](https://images.gitee.com/uploads/images/2021/0419/142324_0224b4ba_416720.png "屏幕截图.png")