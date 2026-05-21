-  **UISwitch** 
开关。

- 默认属性：Active
- 默认事件：ValueChanged

- 属性列表

| 属性        | 说明     | 类型     |  默认值   |
|-----------|--------|--------|-------|
| Style | 主题样式  | UIStyle  |  Blue     |
| StyleCustomMode | 获取或设置可以自定义主题风格   | bool  | false |
| Active| 是否打开   | bool  | false |
| ActiveText| 打开文字   | string| 开 |
| InActiveText| 关闭文字   | string| 关 |
| ActiveColor| 打开颜色  | Color| - |
| InActiveColor| 关闭颜色  | Color| Silver |
| ButtonColor| 填充颜色  | Color| White |
| SwitchShape| 开关形状   | UISwitchShape| Round   |
| ForeColor | 字体颜色   | Color  | -   |
| TagString | 获取或设置包含有关控件的数据的对象字符串   | string | -   | 
| Version | 版本  | string  |  -     |

- 事件
  ValueChanged
  public delegate void OnValueChanged(object sender, bool value);
  参数sender：当前控件
  参数value：选中值，active

- 主题风格
 **主题**  https://gitee.com/yhuse/SunnyUI/wikis/pages?sort_id=3739705&doc_id=1022550<br/>

- 主题设置
  设置Style属性调用系统自带主题，如果需要自定义颜色，就是更改颜色属性后，把控件的Style设置为Custom，StyleCustomMode设置为True
  StyleCustomMode就是接受用户自定义颜色的意思。

- 开关状态
![输入图片说明](https://images.gitee.com/uploads/images/2021/0128/233007_095707ff_416720.png "1.png")
  设置Active属性，状态切换通过ValueChanged输出

- 开关形状
  SwitchShape：Round为圆角开关，Square为方角开关
  