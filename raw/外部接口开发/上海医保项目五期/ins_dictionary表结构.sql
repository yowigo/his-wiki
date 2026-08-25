-- =============================================
-- insur.ins_dictionary 医保字典表
-- 写入方：Frm字典表查询.btn更新_Click
-- =============================================

DROP TABLE IF EXISTS insur.ins_dictionary;

CREATE TABLE insur.ins_dictionary (
    id           serial PRIMARY KEY,
    ins_id       bigint NOT NULL,               -- 保险系统ID
    type         varchar(50) NOT NULL,        -- 字典类型代码（如 MED_TYPE）
    type_name    varchar(100),                -- 字典类型名称（如 医疗类别）
    label        varchar(200) NOT NULL,       -- 字典标签（值的名称）
    value        varchar(50) NOT NULL,        -- 字典键值（值的编码）
    parent_value varchar(50),                 -- 父字典键值
    sort         integer,                     -- 排序序号
    vali_flag    varchar(10) DEFAULT '1',     -- 有效标志（1=有效 0=无效）
    create_user  varchar(50),                 -- 创建账户
    create_date  timestamp DEFAULT now(),     -- 创建时间
    version      varchar(20),                 -- 版本号
    object_flag  varchar(50)                  -- 对象标识
);

COMMENT ON TABLE insur.ins_dictionary IS '医保字典表（国家1901接口下载）';
COMMENT ON COLUMN insur.ins_dictionary.ins_id IS '保险系统ID';
COMMENT ON COLUMN insur.ins_dictionary.type IS '字典类型代码（如 MED_TYPE=医疗类别）';
COMMENT ON COLUMN insur.ins_dictionary.type_name IS '字典类型名称（如 医疗类别，1901接口不返回，由客户端写入）';
COMMENT ON COLUMN insur.ins_dictionary.label IS '字典标签（值的名称）';
COMMENT ON COLUMN insur.ins_dictionary.value IS '字典键值（值的编码）';
COMMENT ON COLUMN insur.ins_dictionary.parent_value IS '父字典键值';
COMMENT ON COLUMN insur.ins_dictionary.sort IS '排序序号';
COMMENT ON COLUMN insur.ins_dictionary.vali_flag IS '有效标志（1=有效 0=无效）';
COMMENT ON COLUMN insur.ins_dictionary.create_user IS '创建账户';
COMMENT ON COLUMN insur.ins_dictionary.create_date IS '创建时间';
COMMENT ON COLUMN insur.ins_dictionary.version IS '版本号';
COMMENT ON COLUMN insur.ins_dictionary.object_flag IS '对象标识';

CREATE UNIQUE INDEX IF NOT EXISTS idx_ins_dictionary_uniq ON insur.ins_dictionary(ins_id, type, value);
