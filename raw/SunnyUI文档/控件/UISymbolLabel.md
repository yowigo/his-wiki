-  **UISymbolLabel** 
字体图标标签

- 默认属性：Text
- 默认事件：Click
- 属性列表

| 属性        | 说明     | 类型     |  默认值   |
|-----------|--------|--------|-------|
| Style | 主题样式  | UIStyle  |  Blue     |
| StyleCustomMode | 获取或设置可以自定义主题风格   | bool  | false |
| Text  |获取或设置显示的文本  | string | -   | 
| AutoSize| 自动大小  | bool  |  true |
| Symbol| 字体图标  | int  | 61452     |
| SymbolColor | 图标颜色  | Color  | -     |
| SymbolSize| 字体图标大小  | int  | 24     |
| ImageInterval| 图标和文字间间隔 | int  | 2|
| TextAlign | 文字对齐方向  | ContentAlignment  |  MiddleCenter     |
| ForeColor | 字体颜色   | Color  | -   |
| TagString | 获取或设置包含有关控件的数据的对象字符串   | string | -   | 
| Version | 版本  | string  |  -     |

- 字体图标
![输入图片说明](https://images.gitee.com/uploads/images/2021/0416/212642_04b86c8c_416720.png "屏幕截图.png")
 设置Symbol属性
![输入图片说明](https://images.gitee.com/uploads/images/2021/0127/213545_4603d7c9_416720.png "11.png")
点击Symbol右侧的按钮：
![输入图片说明](https://images.gitee.com/uploads/images/2021/0127/213636_ee4259fe_416720.png "12.png")
 [[原创][开源] SunnyUI.Net 字体图标 ](https://www.cnblogs.com/yhuse/p/SunnyUI_FontImage.html)https://www.cnblogs.com/yhuse/p/SunnyUI_FontImage.html<br/>

- 主题风格
 **主题**  https://gitee.com/yhuse/SunnyUI/wikis/pages?sort_id=3739705&doc_id=1022550<br/>

- 主题设置
  设置Style属性调用系统自带主题，如果需要自定义颜色，就是更改颜色属性后，把控件的Style设置为Custom，StyleCustomMode设置为True
  StyleCustomMode就是接受用户自定义颜色的意思。