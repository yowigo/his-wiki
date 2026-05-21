标准化接口文档

（检查）

V1.0

版本信息：

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| 版本号 | 日期 | 修订内容简述 | 修订人 | 审核人 |
| V1.0 | 2023-10-31 |  |  |  |

**通用说明：**

1. 本章各业务接口说明中的请求参数和返回参数只包含对应服务参数中具体业务参数段的部分。

# 三方PACS接口详情示例

## J1006 查询检查申请列表

|  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- |
| **服务编码** | **J1006** | | | | | |
| **服务名称** | **J1006查询检查申请列表（V1.0）** | | | | | |
| **服务地址** | **instance/publish/yhis/V1/Pacs/GetPacsApplyListByCodes** | | | | | |
| **功能简述** | **查询检查申请列表** | | | | | |
| **详细描述（应用场景、数据处理逻辑描述）** | | | | | | |
| 1. 适用于三方系统查询检查申请列表信息。 | | | | | | |
| **入参示例** | | | | | | |
| {  **"org\_id": "",**  **"start\_time": "",**  **"end\_time": "",**  **"page\_num": 0,**  **"page\_size": 0,**  **"pt\_source\_code": "",**  **"visit\_no": "",**  **"study\_type\_code": ""**  **"visit\_id": "",**  **"pt\_id": ""**  } | | | | | | |
| **节点** | **父节点** | **类型** | **必填** | | **数组** | **说明** |
| org\_id |  | string | **√** | |  | 机构id |
| start\_time |  | string | **√** | |  | 开始时间 |
| end\_time |  | string | **√** | |  | 结束时间 |
| page\_num |  | int | **√** | |  | 第几页 |
| page\_size |  | int | **√** | |  | 数据条数 |
| visit\_no |  | string |  | |  | 就诊号 门诊号、住院号 |
| study\_type\_code |  | string |  | |  | 检查类型编码 |
| pt\_source\_code |  | string |  | |  | 病人来源：1-门诊；2-住院；3-体检;空或-1：-所有；多个用逗号分隔 |
| visit\_id |  | string |  | |  | 就诊ID |
| pt\_id |  | string |  | |  | 患者ID |
| fee\_status |  | int |  | |  | 费用状态 0-未收费；1-已收费 |
| **出参示例** | | | | | | |
| {     **"code"**:**200**,     **"msg"**:**"执行成功!"**,     **"data"**:**{**  **"total": 0,**  **"pageList": [**  **{**  **"id": "string",**  **"apply\_source": 0,**  **"order\_id": 0,**  **"visit\_id": "string",**  **"apply\_order\_no": "string",**  **"pt\_source\_code": 0,**  **"pt\_visit\_no": "string",**  **"baby\_sign": 0,**  **"study\_order\_no": "string",**  **"pt\_id": "string",**  **"pt\_name": "string",**  **"pt\_english": "string",**  **"pt\_sex": "string",**  **"pt\_sex\_name": "string",**  **"pt\_birthday": "2023-10-31T03:30:27.499Z",**  **"pt\_age": "string",**  **"pt\_idcard\_type\_code": "string",**  **"pt\_idcard\_type\_name": "string",**  **"pt\_idcard": "string",**  **"pt\_phone": "string",**  **"pt\_address": "string",**  **"pt\_height": 0,**  **"pt\_weight": 0,**  **"bed\_no": "string",**  **"study\_item\_id": "string",**  **"study\_item\_name": "string",**  **"study\_type\_code": "string",**  **"study\_type\_name": "string",**  **"study\_priority\_level": 0,**  **"apply\_purpose": "string",**  **"clinical\_show": "string",**  **"clinical\_diagnosis": "string",**  **"execute\_dept\_id": "string",**  **"execute\_dept\_name": "string",**  **"apply\_status": 0,**  **"area\_status": 0,**  **"area\_type": 0,**  **"apply\_org\_id": "string",**  **"apply\_org\_name": "string",**  **"apply\_dept\_id": "string",**  **"apply\_dept\_name": "string",**  **"apply\_doctor\_id": "string",**  **"apply\_doctor\_name": "string",**  **"apply\_time": "2023-10-31T03:30:27.499Z"**  **}**  **]**  **}**  } | | | | | | |
| **节点** | **父节点** | **类型** | **数组** | **说明** | | |
| code |  | int |  | 返回结果: 200-成功; 500-失败 | | |
| msg |  | string |  | 返回信息 | | |
| data |  |  |  | 执行结果: | | |
| total |  | int |  | 总数 | | |
| pageList |  |  | √ |  | | |
| id |  | string |  | 申请id | | |
| apply\_source |  | string |  | 申请来源：0-手工申请 1-医嘱申请 2-共享申请【多院区模式】 3-外院申请 | | |
| order\_id |  | long |  | 医嘱ID | | |
| visit\_id |  | string |  | 就诊ID | | |
| apply\_order\_no |  | string |  | 申请单号/医嘱单号 | | |
| pt\_source\_code |  | string |  | 就诊来源（1-门诊；2-住院；3-体检 ） | | |
| pt\_visit\_no |  | string |  | 标识号（门诊号/住院号/体检号） | | |
| baby\_sign |  | int |  | 婴儿标志：是第几个婴儿医嘱产生的申请,普通为0 | | |
| study\_order\_no |  | string |  | 检查单号 | | |
| pt\_id |  | string |  | 患者ID | | |
| pt\_name |  | string |  | 患者姓名 | | |
| pt\_english |  | string |  | 患者英文名 | | |
| pt\_sex |  | string |  | 性别 | | |
| pt\_sex\_name |  | string |  | 性别名称 | | |
| pt\_birthday |  | date |  | 出生日期 | | |
| pt\_age |  | string |  | 年龄信息 | | |
| pt\_idcard\_type\_code |  | string |  | 患者证件类型编码 | | |
| pt\_idcard\_type\_name |  | string |  | 患者证件类型名称 | | |
| pt\_idcard |  | string |  | 身份证号 | | |
| pt\_phone |  | string |  | 联系电话 | | |
| pt\_address |  | string |  | 现地址 | | |
| pt\_height |  | int |  | 身高 | | |
| pt\_weight |  | int |  | 体重 | | |
| bed\_no |  | string |  | 床位号 | | |
| study\_item\_id |  | string |  | 检查项目ID | | |
| study\_item\_name |  | string |  | 检查项目名称 | | |
| study\_type\_code |  | string |  | 检查类型编码 | | |
| study\_type\_name |  | string |  | 检查类型名称 | | |
| study\_priority\_level |  | int |  | 检查优先级（0-正常 1-加急） | | |
| apply\_purpose |  | string |  | 申请目的 | | |
| clinical\_show |  | string |  | 临床表现 | | |
| clinical\_diagnosis |  | string |  | 临床诊断 | | |
| execute\_dept\_id |  | string |  | 执行科室ID | | |
| execute\_dept\_name |  | string |  | 执行科室名称 | | |
| apply\_status |  | int |  | 申请状态：1-未生效数据；0-待登记 1-已预约 2-已登记 3-执行中 4- 已完成 5- 已发报告检查申请状态： | | |
| area\_status |  | int |  | 协同状态( 0- 本地诊断 1- 院内预约检查 2-远程诊断 3-远程审核 4- 远程预约检查 5-共享诊断) | | |
| area\_type |  | int |  | 关联协同状态：( 0- 本地诊断 1- 院内预约检查 2-远程诊断 3-远程审核 4- 远程预约检查 5-共享诊断) | | |
| apply\_org\_id |  | string |  | 申请机构ID | | |
| apply\_org\_name |  | string |  | 申请机构名称 | | |
| apply\_dept\_id |  | string |  | 申请科室ID | | |
| apply\_dept\_name |  | string |  | 申请科室 | | |
| apply\_doctor\_id |  | string |  | 申请医生ID | | |
| apply\_doctor\_name |  | string |  | 申请医生 | | |
| apply\_time |  | date |  | 申请时间 | | |
| FeeStatus |  | int |  | 费用状态 0-未收费(未记账)；1-已收费(已结账)； | | |
| FeeAmounts |  | decimal |  | 费用总金额 | | |

## J1016 检查申请确认服务

|  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- |
| **服务编码** | **J1016** | | | | | |
| **服务名称** | **J1016（V1.0）** | | | | | |
| **服务地址** | **instance/publish/yhis/V1/Pacs/ConfirmRegister** | | | | | |
| **功能简述** | **第三方PACS系统进行检查申请确认登记** | | | | | |
| **详细描述（应用场景、数据处理逻辑描述）** | | | | | | |
| 1. 适用于未上线自建PACS系统，使用第三方PACS系统进行检查申请确认登记。 2. 每例检查申请仅可调用一次【确认登记】服务，若需重新调用，请调用撤销登记【J1017】后再进行调用。 3. 仅可对尚未确认登记的数据进行操作，已处于后续流程的数据调用此接口将会进行错误返回。 | | | | | | |
| **入参示例** | | | | | | |
| {  "order\_id": "string",  "register\_time": "2024-04-08 04:07:56",  "operator\_name": "string"  } | | | | | | |
| **节点** | **父节点** | **类型** | **必填** | | **数组** | **说明** |
| order\_id |  | string | √ | |  | 医嘱ID |
| register\_time |  | date | √ | |  | 登记时间 |
| operator\_name |  | string | √ | |  | 操作员名称 |
| **出参示例** | | | | | | |
| {     **"code"**:**200**,     **"msg"**:**"确认登记成功!"**  } | | | | | | |
| **节点** | **父节点** | **类型** | **数组** | **说明** | | |
| code |  | int |  | 返回结果: 200-成功; 500-失败 | | |
| msg |  | string |  | 返回信息 | | |

## J1017 检查申请取消服务

|  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- |
| **服务编码** | **J1017** | | | | | |
| **服务名称** | **J1017（V1.0）** | | | | | |
| **服务地址** | **instance/publish/yhis/V1/Pacs/** **CancelRegister** | | | | | |
| **功能简述** | **第三方PACS系统进行检查申请取消登记** | | | | | |
| **详细描述（应用场景、数据处理逻辑描述）** | | | | | | |
| 1. 适用于未上线自建PACS系统，使用第三方PACS系统进行检查申请取消登记。 2. 仅可对已调用【J1016】确认登记的数据进行操作，且当前数据尚未进行后续流程操作。 | | | | | | |
| **入参示例** | | | | | | |
| {  "order\_id": "string"  } | | | | | | |
| **节点** | **父节点** | **类型** | **必填** | | **数组** | **说明** |
| order\_id |  | string | √ | |  | 医嘱ID |
| **出参示例** | | | | | | |
| {     **"code"**:**200**,     **"msg"**:**"取消登记成功!"**  } | | | | | | |
| **节点** | **父节点** | **类型** | **数组** | **说明** | | |
| code |  | int |  | 返回结果: 200-成功; 500-失败 | | |
| msg |  | string |  | 返回信息 | | |

## J1018 检查报告完成服务

|  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- |
| **服务编码** | **J1018** | | | | |
| **服务名称** | **J1018（V1.0）** | | | | |
| **服务地址** | **instance/publish/yhis/V1/Pacs/CompleteReport** | | | | |
| **功能简述** | **第三方PACS系统进行检查申请完成报告** | | | | |
| **详细描述（应用场景、数据处理逻辑描述）** | | | | | |
| 1. 适用于未上线自建PACS系统，使用第三方PACS系统进行患检查申请完成报告，并回传报告内容、报告预览地址。 2. 本接口参数【report\_outline\_id】需采用本系统内置提纲ID，具体参数值请联系文档提供方,并进行对码传输。 3. 第三方报告预览地址务必保证永久有效，暂不支持具有时效性的预览地址。 | | | | | |
| **入参示例** | | | | | |
| {  "order\_id": "string",  "diagnose\_doctor\_id": "string",  "diagnose\_doctor\_name": "string",  "diagnose\_time": "2024-04-08 04:08:29",  "audit\_doctor\_id": "string",  "audit\_doctor\_name": "string",  "audit\_time": "2024-04-08 04:08:29",  "positive\_code": 0,  "report\_link": "string",  "outline\_list": [  {  "report\_outline\_id": "string",  "report\_outline\_name": "string",  "report\_outline\_value": "string"  }  ]  } | | | | | |
| **节点** | **父节点** | **类型** | **必填** | **数组** | **说明** |
| order\_id |  | string | √ |  | 医嘱ID |
| diagnose\_doctor\_id |  | string |  |  | 报告诊断人ID |
| diagnose\_doctor\_name |  | string |  |  | 报告诊断人名称 |
| diagnose\_time |  | date | √ |  | 报告诊断时间 |
| audit\_doctor\_id |  | string |  |  | 报告审核人ID |
| audit\_doctor\_name |  | string |  |  | 报告审核人名称 |
| audit\_time |  | date | √ |  | 报告审核时间 |
| positive\_code |  | string |  |  | 阴阳性 0-阴性1-阳性 |
| report\_link |  | string |  |  | 报告链接地址（网页） |
| outline\_list |  |  |  | √ |  |
| report\_outline\_id |  | string |  |  | 本系统中的报告提纲ID，由本系统提供 |
| report\_outline\_name |  | string |  |  | 本系统报告提纲名称/第三方提纲名称 |
| report\_outline\_value |  | string |  |  | 提纲内容（检查所见/检查诊断内容值） |
| **出参示例** | | | | | |
| {     **"code"**:**200**,     **"msg"**:**"完成报告成功!"**  } | | | | | |
| **节点** | **父节点** | **类型** | **数组** | **说明** | |
| code |  | int |  | 返回结果: 200-成功; 500-失败 | |
| msg |  | string |  | 返回信息 | |

## J1019 检查报告撤销服务

|  |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- |
| **服务编码** | **J1019** | | | | | |
| **服务名称** | **J1019（V1.0）** | | | | | |
| **服务地址** | **instance/publish/yhis/V1/Pacs/** **RevokeReport** | | | | | |
| **功能简述** | **第三方PACS系统进行检查申请报告撤销功能** | | | | | |
| **详细描述（应用场景、数据处理逻辑描述）** | | | | | | |
| 1. 适用于未上线自建PACS系统，使用第三方PACS系统进行报告撤销功能。 | | | | | | |
| **入参示例** | | | | | | |
| {  "order\_id": "string"  } | | | | | | |
| **节点** | **父节点** | **类型** | **必填** | | **数组** | **说明** |
| order\_id |  | string | √ | |  | 医嘱ID |
| **出参示例** | | | | | | |
| {     **"code"**:**200**,     **"msg"**:**"撤销报告成功!"**  } | | | | | | |
| **节点** | **父节点** | **类型** | **数组** | **说明** | | |
| code |  | int |  | 返回结果: 200-成功; 500-失败 | | |
| msg |  | string |  | 返回信息 | | |