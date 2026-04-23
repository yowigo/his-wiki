# 基础数据接口（第一部分）

> 原始资料：[raw/HIS接口文档1.0/1-标准文档/1-飞跃智慧系统标准化接口文档（第一部分：基础数据）V1.0.docx](../../raw/HIS接口文档1.0/1-标准文档/1-飞跃智慧系统标准化接口文档（第一部分：基础数据）V1.0.docx)

---

## 部门人员

### B1002 获取部门信息

- **地址**: `instance/publish/yhis/V1/GetDeptByOrg`
- **功能**: 获取指定机构下的部门（科室）信息，支持通过部门id、部门性质等查询
- **入参**: `org_id`(必填), `dept_id`, `props`(性质串), `serviceScopes`(服务范围), `gradeCode`, `dept_id_list`, `unShowParent`, `key_word`
- **出参**: 部门列表，含 `id`, `parent_id`, `code`, `name`, `py_code`, `prop`, `discipline`, `service_scope`, `bed_qty`, `status` 等

### B1003 获取人员信息

- **地址**: `instance/publish/yhis/V1/GetStaffByDept`
- **功能**: 获取指定机构或指定部门下的医护人员信息，可以传入部门列表来获取多个部门下的人员
- **入参**: `org_id`(必填), `dept_id_list`(部门ID列表), `staff_id_list`(人员ID列表), `key_word`
- **出参**: 人员列表，含 `staff_id`, `dept_id`, `staff_name`, `py_code`, `sex_name`, `role_name`, `tel`, `status` 等

---

## 患者档案

### B2001 新建患者档案

- **地址**: `instance/publish/yhis/V1/InsertPatientInfo`
- **功能**: 新建患者基本信息档案
- **入参**: `patient_name`(必填), `id_card_type_code`, `id_card`, `gender_code`, `birth_date`, `tel`, `permanent_addr_detail`, `current_addr_detail`, `contacts`, `contacts_tel`, `nultitude_type_code`, `org_id`
- **出参**: `patient_id`, `medical_record_no`, `org_code`

### B2002 修改患者档案

- **地址**: `instance/publish/yhis/V1/UpdatePatientInfo`
- **功能**: 修改患者基本信息
- **入参**: `patient_id`(必填), 同新建字段

### B2003 查询指定条件的患者档案

- **地址**: `instance/publish/yhis/V1/GetPatientInfoByCondition`
- **功能**: 多条件查询患者档案（姓名、身份证、电话等）
- **入参**: `org_id`, `patient_name`, `id_card`, `tel`, `key_word`
- **出参**: 患者列表

### B2003A 查询指定条件的患者档案【无档案新增档案】

- **地址**: `instance/publish/yhis/V1/GetPatientInfoByConditionOrInsert`
- **功能**: 查询患者档案，如不存在则自动新建
- **入参**: 同 B2003
- **出参**: 患者信息（查询或新建后返回）

### B2004 查询指定的患者信息

- **地址**: `instance/publish/yhis/V1/GetPatientInfoById`
- **功能**: 通过患者ID查询详细信息
- **入参**: `patient_id`(必填)

---

## 系统标签

### B2006 获取所有系统标签

- **地址**: `instance/publish/yhis/V1/GetAllSystemLabel`
- **功能**: 获取系统预定义的标签列表（如慢病标签、老年人标签等）
- **入参**: `org_id`

### B2007 保存患者与系统标签关系

- **地址**: `instance/publish/yhis/V1/SavePatientLabel`
- **功能**: 为患者打标签
- **入参**: `patient_id`(必填), `label_id_list`(标签ID列表)

### B2008 修改系统标签

- **地址**: `instance/publish/yhis/V1/UpdateSystemLabel`
- **功能**: 修改标签信息
- **入参**: `label_id`(必填), `label_name`, `description`

---

## 收费诊疗项目

### B3002 获取收费项目

- **地址**: `instance/publish/yhis/V1/GetChargeItem`
- **功能**: 获取机构下的收费项目（如挂号费、诊查费、治疗费等）
- **入参**: `org_id`(必填), `item_type`(项目类型), `key_word`
- **出参**: 项目列表，含 `item_id`, `item_code`, `item_name`, `price`, `unit`, `specification` 等

### B3001 获取诊疗项目

- **地址**: `instance/publish/yhis/V1/GetTreatItem`
- **功能**: 获取诊疗项目（检查、检验、治疗等项目）
- **入参**: `org_id`(必填), `dept_id`, `item_type`, `key_word`

---

## 标准字典

### UP1022 获取标准字典

- **地址**: `instance/publish/yhis/V1/GetStandardDictionary`
- **功能**: 获取系统标准字典数据（如性别、民族、证件类型、婚姻状况等码表）
- **入参**: `dict_type`(字典类型, 必填), `parent_code`(父级编码)
- **出参**: 字典项列表，含 `code`, `name`, `py_code`, `sort_no`

---

## 使用建议

1. **先调用 UP1022 获取字典**: 在展示下拉选项前，先拉取对应字典数据
2. **患者档案查询优先级**: B2003A > B2003 > B2004，根据场景选择
3. **标签用于公卫筛选**: B2006/B2007 支持为慢病、老年人等群体打标签，便于公卫系统筛选
