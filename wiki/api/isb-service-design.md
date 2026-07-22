# ISB 服务设计（HESB 流程设计器）数据库操作

**整理时间**: 2026-07-22
**整理者**: Keiskei
**来源项目**: ElectronocInvoice.SHJD（上海金蝶电子票据）

## 涉及的核心表

| 表名                     | 作用                             | 关键约束                          |
| ------------------------ | -------------------------------- | --------------------------------- |
| `ServiceDesigns`         | 流程设计主表（含 designScript）  | `id` 主键，`enable` 控制启停      |
| `business_services`      | 对外发布的 WebApi 服务           | **`id_code` 必须等于 `id`**       |
| `DesignVariables`        | 流程变量（入参/中间变量/出参）   | 通过 `service_design_id` 关联设计 |
| `SqlNodes`               | 数据库脚本节点（SQL 文本）       | 通过 `service_design_id` 关联设计 |
| `SwitchNodes`            | 条件分支节点（表达式）           | 通过 `id` 定位节点                |
| `SetValueItems`          | 赋值节点内的条目                 | 通过 `nodeid` 关联赋值节点        |
| `service_param`          | HTTP 入参（QueryString/Body）    | 通过 `business_service_id` 关联服务 |

---

## 🚨 关键规则

### 1. `business_services.id_code` 必须等于 `id`

新增 `business_services` 时，`id_code` 字段的值必须和 `id` 一致。如果 INSERT 语句缺少 `id_code` 列，会导致该字段为空，HESB 网关路由异常。

```sql
-- ✅ 正确：id_code 与 id 相同
INSERT INTO "business_services" (id, id_code, name, ...) VALUES ('xxx', 'xxx', '服务名', ...);

-- ❌ 错误：缺少 id_code 列
INSERT INTO "business_services" (id, name, ...) VALUES ('xxx', '服务名', ...);
```

### 2. 插入前必须检查重复

**所有表**在插入前必须用 `WHERE NOT EXISTS` 或先查后插，防止重复数据。`ServiceDesigns` 表曾因未检查重复而插入了 3 条相同数据。

```sql
-- ✅ 推荐写法
INSERT INTO "business_services" (id, id_code, name, identifier, ...)
SELECT 'xxx', 'xxx', '服务名', 'B02', ...
WHERE NOT EXISTS (SELECT 1 FROM "business_services" WHERE id = 'xxx');
```

如果发现目标已存在数据（如 `DesignVariables` 中同名变量），应发出警告而非静默跳过。

### 3. `enable` 字段含义

| 值  | 含义   |
| --- | ------ |
| `1` | 启用   |
| `3` | 停用   |

> 注意：不是常见的 `0=停用/1=启用`。`enable=3` 才表示停用。

---

## 各表 INSERT 模板

### ServiceDesigns

```sql
INSERT INTO "ServiceDesigns" (id, id_code, name, designScript, enable, create_time, update_time)
SELECT '新id', '新id', '服务设计名称', '{}', 1, now(), now()
WHERE NOT EXISTS (SELECT 1 FROM "ServiceDesigns" WHERE id = '新id');
```

### business_services（发布 WebApi）

```sql
INSERT INTO "business_services" (
    id, id_code, name, identifier, service_category_id, service_site_id,
    service_design_id, business_system_config_id, http_method, service_type,
    service_source, gateway_address, security_policy, return_variable_id,
    response_content, request_example, direct_address, is_direct_jump,
    visit_max_val, run_status, enable, create_time, update_time,
    is_allow_anonymous_visit, author_policy, encrypt_policy,
    request_charset, response_charset, is_debug
)
SELECT
    gen_random_uuid(),  -- id
    NULL,               -- id_code（⚠️ 必须随后 UPDATE 为与 id 相同！gen_random_uuid() 无法在 SELECT 中引用两次同一值）
    'B02验光数据查询',   -- name
    'B02',              -- identifier（对外 URL 路径）
    '7b686eba-5057-435f-a471-e6b19122ef89',  -- service_category_id
    '5a658edc-f751-401c-83a5-06d8b5dca561',  -- service_site_id
    '9bfb3834-d47e-4d4b-ba19-97ce5295e802',  -- service_design_id
    '1cc91ffb-c44b-4a8d-8591-6e9a2984beeb',  -- business_system_config_id
    1,    -- http_method (1=GET, 2=POST)
    0,    -- service_type
    1,    -- service_source
    'B02',-- gateway_address
    0,    -- security_policy
    'e862b3ce-f9c7-435b-bd95-c41ee094fc56',  -- return_variable_id
    '', '', '', false, 1, 1, 1,
    now(), now(),
    false, 0, 0, 0, 0, false
WHERE NOT EXISTS (SELECT 1 FROM "business_services" WHERE identifier = 'B02' AND service_design_id = '9bfb3834-d47e-4d4b-ba19-97ce5295e802');

-- ⚠️ 补充 id_code：因为 gen_random_uuid() 每次调用返回不同值，
--    所以 INSERT 后必须 UPDATE id_code 与 id 一致
UPDATE "business_services" SET id_code = id
WHERE identifier = 'B02' AND service_design_id = '9bfb3834-d47e-4d4b-ba19-97ce5295e802' AND id_code IS NULL;
```

### DesignVariables

```sql
INSERT INTO "DesignVariables" (id, name, type, source, service_design_id, create_time, update_time)
SELECT gen_random_uuid(), '变量名', 0, 0, 'service_design_id值', now(), now()
WHERE NOT EXISTS (
    SELECT 1 FROM "DesignVariables"
    WHERE name = '变量名' AND service_design_id = 'service_design_id值'
);
```

### service_param（QueryString 入参）

```sql
INSERT INTO "service_param" (id, name, variable, type, sort, enable, business_service_id, design_variable_id, create_time, update_time)
SELECT gen_random_uuid(), 'RowCnt', 'RowCnt', 0, 1, 1,
       (SELECT id FROM "business_services" WHERE identifier = 'B02' LIMIT 1),
       (SELECT id FROM "DesignVariables" WHERE name = 'RowCnt' AND service_design_id = 'xxx' LIMIT 1),
       now(), now()
WHERE NOT EXISTS (
    SELECT 1 FROM "service_param"
    WHERE business_service_id = (SELECT id FROM "business_services" WHERE identifier = 'B02' LIMIT 1)
      AND variable = 'RowCnt'
);
```

---

## 参考案例

### A01 患者基本信息查询（改造）

**文件**: `scripts/hesb/01_A01改造.sql`

改造内容：
1. SQL 文本更新（`SqlNodes.sql_txt`）— 增加 card_no 联查、年龄计算
2. 条件节点表达式更新（`SwitchNodes.expression`）— 空入参校验
3. 入参提取清理重建（`SetValueItems`）— 删除旧项、插入新响应格式
4. 入参声明重建（`service_param`）— 改为 QueryString 方式
5. 设计脚本更新（`ServiceDesigns.designScript`）— 补充"否"连线

### B02 验光数据查询（新建）

**文件**: `scripts/hesb/02_B02创建.sql`

新建内容：
1. 创建入参变量（`DesignVariables`：RowCnt, TxtLen, Txt）
2. 创建出参变量（card_no, channel_type）
3. 发布 WebApi（`business_services`）
4. 配置 QueryString 入参（`service_param`）
5. 清理旧测试数据

---

## 常见错误

| 现象                               | 原因                           | 修复                                     |
| ---------------------------------- | ------------------------------ | ---------------------------------------- |
| ISB 网关路由不到新服务             | `id_code` 为空或与 `id` 不一致 | `UPDATE business_services SET id_code = id WHERE id_code IS NULL` |
| 保存设计时报错/覆盖了别人的设计    | `ServiceDesigns` 存在重复行    | 查重删重，后续插入用 `WHERE NOT EXISTS`  |
| 同一个接口被重复发布               | `business_services` 重复插入   | 插入前用 `WHERE NOT EXISTS` 防重         |
| 接口不显示（HIS 里看不到）         | `enable` 不是 `1`              | 检查 `enable` 字段，`3` 是停用           |
