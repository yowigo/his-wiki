-  **UIMarkLabel** 
带颜色标签。

- 默认属性：Text
- 默认事件：Click
- 属性列表

| 属性        | 说明     | 类型     |  默认值   |
|-----------|--------|--------|-------|
| Style | 主题样式  | UIStyle  |  Blue     |
| StyleCustomMode | 获取或设置可以自定义主题风格   | bool  | false |
| Text  |获取或设置显示的文本  | string | -   |
| AutoSize| 自动大小  | bool  |  true |
| ForeColor | 字体颜色   | Color  | -   |
| MarkSize | 标签大小  | int  | 3 |
| MarkPos | 标签位置  | UIMarkPos | Left |
| MarkColor | 标签颜色   | Color  | -   |
| TagString | 获取或设置包含有关控件的数据的对象字符串   | string | -   | 
| Version | 版本  | string  |  -     |

- 主题风格
 **主题**  https://gitee.com/yhuse/SunnyUI/wikis/pages?sort_id=3739705&doc_id=1022550<br/>

- 主题设置
  设置Style属性调用系统自带主题，如果需要自定义颜色，就是更改颜色属性后，把控件的Style设置为Custom，StyleCustomMode设置为True
  StyleCustomMode就是接受用户自定义颜色的意思。

- 标签位置
  标签有四个显示位置，左、右、下、上，见下图：
![输入图片说明](https://images.gitee.com/uploads/images/2021/0416/214220_cbd9f247_416720.png "屏幕截图.png")