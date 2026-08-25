-- 作者: Keiskei
-- 用途: 创建部署补建的 25 张 insur 表
-- 说明:
-- 1) 本脚本基于项目代码中的 SQL 与 Model 字段反推得到，优先保证本项目运行所需字段可用。
-- 2) 全部使用 CREATE TABLE IF NOT EXISTS，重复执行安全。
-- 3) 如你们生产库存在更完整标准 DDL，请后续以标准 DDL 为准进行字段补齐/类型收敛。

BEGIN;

-- 确保 schema 存在
CREATE SCHEMA IF NOT EXISTS insur;

-- 1) 目录下载信息表
CREATE TABLE IF NOT EXISTS insur.catalog_download_info (
    ins_id          bigint       NOT NULL,
    org_id          varchar(36)  NOT NULL,
    infno           varchar(50)  NOT NULL,
    infno_name      varchar(200),
    ver_name        varchar(100),
    dld_end_time    timestamp,
    create_time     timestamp    DEFAULT CURRENT_TIMESTAMP,
    update_time     timestamp    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_catalog_download_info PRIMARY KEY (ins_id, org_id, infno)
);

-- 2) 日对账主表
CREATE TABLE IF NOT EXISTS insur.daily_reconcile_main (
    id                  varchar(36) PRIMARY KEY,
    org_id              varchar(36) NOT NULL,
    fixmedins_code      varchar(50) NOT NULL,
    fixmedins_name      varchar(200),
    reconcile_date      date NOT NULL,
    reconcile_status    varchar(10),
    reconcile_time      timestamp,
    operator_id         varchar(36),
    operator_name       varchar(50),
    claim_status        varchar(10),
    claim_time          timestamp,
    remark              text,
    create_time         timestamp DEFAULT CURRENT_TIMESTAMP,
    update_time         timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 3) 日对账明细表
CREATE TABLE IF NOT EXISTS insur.daily_reconcile_detail (
    id                  varchar(36) PRIMARY KEY,
    main_id             varchar(36) NOT NULL,
    org_id              varchar(36) NOT NULL,
    reconcile_date      date NOT NULL,
    insure_type         varchar(20),
    med_type            varchar(20),
    clr_type            varchar(20),
    setl_optins         varchar(50),
    medfee_amt          numeric(18,2) DEFAULT 0,
    fund_amt            numeric(18,2) DEFAULT 0,
    acct_amt            numeric(18,2) DEFAULT 0,
    setl_cnt            integer DEFAULT 0,
    center_medfee_amt   numeric(18,2) DEFAULT 0,
    center_fund_amt     numeric(18,2) DEFAULT 0,
    center_acct_amt     numeric(18,2) DEFAULT 0,
    center_setl_cnt     integer DEFAULT 0,
    reconcile_result    varchar(10),
    result_desc         text,
    reconcile_time      timestamp,
    remark              text,
    create_time         timestamp DEFAULT CURRENT_TIMESTAMP,
    update_time         timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_daily_reconcile_detail_main
        FOREIGN KEY (main_id) REFERENCES insur.daily_reconcile_main(id)
);

-- 4) 医保病种类型表
CREATE TABLE IF NOT EXISTS insur.ins_disease_type (
    id              bigserial PRIMARY KEY,
    ins_id          bigint NOT NULL,
    disease_type    varchar(20) NOT NULL,
    code            varchar(100) NOT NULL,
    name            varchar(200) NOT NULL,
    py_code         varchar(100),
    create_time     timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 5) 上海医保目录临时汇总表(不冲突版本)
CREATE TABLE IF NOT EXISTS insur.ins_item_sh_unconflict (
    id                   bigserial PRIMARY KEY,
    ins_id               bigint NOT NULL,
    ins_item_code        varchar(100) NOT NULL,
    name                 varchar(500),
    ins_category         varchar(100),
    fee_type             varchar(100),
    fee_level            varchar(50),
    specification        varchar(200),
    unit                 varchar(50),
    sourceland           varchar(200),
    country_unified_code varchar(200),
    country_unified_name varchar(500),
    out_pay_rate         numeric(10,6),
    start_time           timestamp(6),
    end_time             timestamp(6),
    remarks              varchar(1000),
    create_time          timestamp(6) DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ins_item_sh_unconflict UNIQUE (ins_id, ins_item_code)
);

-- 6) 挂号医保关联记录表
CREATE TABLE IF NOT EXISTS insur.ins_reg_record (
    visit_id        varchar(36) NOT NULL,
    pt_id           varchar(36) NOT NULL,
    org_id          varchar(36) NOT NULL,
    jzdyh           varchar(100),
    dept_id         varchar(36),
    yllb            varchar(50),
    person_spectag  varchar(50),
    person_type     varchar(50),
    dbtype          varchar(50),
    jmbz            varchar(50),
    create_time     timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_ins_reg_record PRIMARY KEY (visit_id, pt_id, org_id)
);

-- 7) 国家标准科室
CREATE TABLE IF NOT EXISTS insur.ins_standard_dept (
    id              varchar(36) PRIMARY KEY,
    parent_id       varchar(36),
    standard_name   varchar(200),
    standard_code   varchar(100)
);

-- 8) 五期标准科室
CREATE TABLE IF NOT EXISTS insur.ins_standard_dept_sh (
    id              varchar(36) PRIMARY KEY,
    parent_id       varchar(36),
    standard_name   varchar(200),
    standard_code   varchar(100)
);

-- 9) 本地科室 -> 国家标准科室映射
CREATE TABLE IF NOT EXISTS insur.ins_standard_dept_vs (
    local_dept_id       varchar(36) NOT NULL,
    standard_dept_id    varchar(36) NOT NULL,
    org_id              varchar(36) NOT NULL,
    create_time         timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_ins_standard_dept_vs PRIMARY KEY (local_dept_id, org_id)
);

-- 10) 本地科室 -> 五期标准科室映射
CREATE TABLE IF NOT EXISTS insur.ins_standard_dept_vs_sh (
    local_dept_id       varchar(36) NOT NULL,
    standard_dept_id    varchar(36) NOT NULL,
    org_id              varchar(36) NOT NULL,
    create_time         timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_ins_standard_dept_vs_sh PRIMARY KEY (local_dept_id, org_id)
);

-- 11) 保险系统映射表(用于 sno/ins_id 映射)
CREATE TABLE IF NOT EXISTS insur.ins_system_mapping (
    id              bigserial PRIMARY KEY,
    ins_id          bigint NOT NULL,
    mapping_sno     smallint NOT NULL,
    mapping_insid   bigint NOT NULL,
    create_time     timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ins_system_mapping UNIQUE (ins_id, mapping_sno)
);

-- 12) 月结对账主记录
CREATE TABLE IF NOT EXISTS insur.month_check_info (
    id                  varchar(36) PRIMARY KEY,
    fixmedins_code      varchar(50),
    fixmedins_name      varchar(200),
    fix_blng_admdvs     varchar(50),
    org_id              varchar(36),
    setl_mon            varchar(20),
    fix_fill_dept       varchar(200),
    fix_fill_psn_id     varchar(50),
    fix_fill_psn        varchar(100),
    upload_time         timestamp,
    stmt_loc            varchar(20),
    upld_btch           varchar(100),
    stmt_status         varchar(20),
    type                varchar(50),
    memo                varchar(1000),
    claim_status        varchar(20),
    create_time         timestamp DEFAULT CURRENT_TIMESTAMP,
    update_time         timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 13) 月结对账基金分组
CREATE TABLE IF NOT EXISTS insur.month_check_fund_group (
    id                  varchar(36) PRIMARY KEY,
    recon_id            varchar(36),
    insure_type         varchar(50),
    psn_type            varchar(50),
    med_type            varchar(50),
    fix_blng_admdvs     varchar(50),
    insu_admdvs         varchar(50),
    psn_times           numeric(18,2),
    psn_cnt             numeric(18,2),
    medfee_sumamt       numeric(18,2),
    inscp_amt           numeric(18,2),
    fund_pay_sumamt     numeric(18,2),
    fund_key            varchar(200),
    create_time         timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 14) 月结对账费用项
CREATE TABLE IF NOT EXISTS insur.month_check_fee_info (
    id                  varchar(36) PRIMARY KEY,
    recon_id            varchar(36),
    fund_key            varchar(200),
    fix_blng_admdvs     varchar(50),
    insu_admdvs         varchar(50),
    fund_code           varchar(100),
    fund_name           varchar(300),
    fund_amt            numeric(18,2),
    memo                varchar(1000),
    create_time         timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 15) 月结对账固化明细
CREATE TABLE IF NOT EXISTS insur.month_check_solidify_info (
    id                   bigserial PRIMARY KEY,
    solidify_id          varchar(36),
    recon_id             varchar(36),
    fixmedins_code       varchar(50),
    fixmedins_name       varchar(200),
    fix_blng_admdvs      varchar(50),
    setl_mon             varchar(20),
    setl_date            varchar(20),
    insure_type          varchar(50),
    psn_type             varchar(50),
    med_type             varchar(50),
    insu_admdvs          varchar(50),
    psn_times            numeric(18,2),
    psn_cnt              numeric(18,2),
    medfee_sumamt        numeric(18,2),
    inscp_amt            numeric(18,2),
    fund_pay_sumamt      numeric(18,2),
    fund_code            varchar(100),
    fund_name            varchar(300),
    fund_amt             numeric(18,2),
    type                 varchar(50),
    memo                 varchar(1000),
    create_time          timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_month_check_solidify UNIQUE (solidify_id, recon_id)
);

-- 16) 进销存上传记录
CREATE TABLE IF NOT EXISTS insur.psi_upload_rec (
    id              varchar(50) PRIMARY KEY,
    infno           varchar(20),
    opter_name      varchar(100),
    inf_time        timestamp,
    no              varchar(100),
    bill_type       varchar(10),
    org_id          varchar(36),
    bill_status     varchar(10),
    create_time     timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 17) 进销存销售明细
CREATE TABLE IF NOT EXISTS insur.psi_sale_details (
    id                      bigserial PRIMARY KEY,
    med_list_codg           varchar(100),
    fixmedins_hilist_id     varchar(100),
    fixmedins_hilist_name   varchar(500),
    fixmedins_bchno         varchar(100),
    prsc_dr_cert_type       varchar(20),
    prsc_dr_certno          varchar(100),
    prsc_dr_name            varchar(100),
    phar_cert_type          varchar(20),
    phar_certno             varchar(100),
    phar_name               varchar(100),
    phar_prac_cert_no       varchar(100),
    hi_feesetl_type         varchar(20),
    setl_id                 varchar(100),
    mdtrt_sn                varchar(100),
    psn_no                  varchar(100),
    psn_cert_type           varchar(20),
    certno                  varchar(100),
    psn_name                varchar(100),
    manu_lotnum             varchar(100),
    manu_date               varchar(50),
    expy_end                varchar(50),
    rx_flag                 varchar(10),
    trdn_flag               varchar(10),
    finl_trns_pric          varchar(50),
    rxno                    varchar(100),
    rx_circ_flag            varchar(10),
    rtal_docno              varchar(100),
    stoout_no               varchar(100),
    bchno                   varchar(100),
    drug_prod_barc          varchar(200),
    shelf_posi              varchar(200),
    sel_retn_cnt            varchar(50),
    sel_retn_time           varchar(50),
    sel_retn_opter_name     varchar(100),
    memo                    varchar(1000),
    mdtrt_setl_type         varchar(20),
    drugtracinfo            jsonb,
    rec_id                  varchar(50),
    drug_id                 varchar(50),
    sno                     varchar(50),
    create_time             timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 18) 结算费用上传记录
CREATE TABLE IF NOT EXISTS insur.sel_fee_upload_info (
    id                  bigserial PRIMARY KEY,
    recon_id            varchar(36),
    fixmedins_code      varchar(50),
    fixmedins_name      varchar(200),
    setl_mon            varchar(20),
    upld_btch           varchar(100),
    create_time         timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 19) 结算清单上传记录
CREATE TABLE IF NOT EXISTS insur.settle_list_upload (
    id              bigserial PRIMARY KEY,
    visit_id        varchar(36) NOT NULL,
    balance_id      bigint NOT NULL,
    pt_id           varchar(36) NOT NULL,
    setl_list_id    varchar(100),
    upload_time     timestamp,
    operater_id     varchar(36),
    operator_name   varchar(100),
    org_id          varchar(36),
    request_data    jsonb,
    stas_type       varchar(20),
    create_time     timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_settle_list_upload UNIQUE (visit_id, balance_id)
);

-- 20) 签到记录
CREATE TABLE IF NOT EXISTS insur.sign_info (
    id              bigint PRIMARY KEY,
    org_id          varchar(36),
    ins_id          bigint,
    operator_id     varchar(36),
    operator_code   varchar(100),
    sign_time       timestamp,
    sign_no         varchar(100),
    status          varchar(10),
    ip              varchar(100),
    mac             varchar(100),
    create_time     timestamp DEFAULT CURRENT_TIMESTAMP
);

-- 22) 中药饮片导入临时表
CREATE TABLE IF NOT EXISTS insur.tcm_medicine_import (
    id              bigserial PRIMARY KEY,
    batch_no        varchar(50) NOT NULL,
    row_number      integer NOT NULL,
    medicine_code   varchar(50),
    medicine_name   varchar(200),
    spec            varchar(100),
    unit            varchar(20),
    price           numeric(10,4),
    category_code   varchar(20),
    category_name   varchar(100),
    effective_flag  varchar(1),
    remarks         varchar(500),
    manufacturer    varchar(200),
    payment_policy  varchar(500),
    source_row      text,
    import_status   varchar(20) NOT NULL DEFAULT 'pending',
    error_message   text,
    created_time    timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 23) 诊疗项目导入临时表
CREATE TABLE IF NOT EXISTS insur.treat_item_import (
    id                   bigserial PRIMARY KEY,
    batch_no             varchar(50) NOT NULL,
    row_number           integer NOT NULL,
    ins_code             varchar(50),
    status               varchar(50),
    info_effective_date  varchar(50),
    info_expire_date     varchar(50),
    item_code            varchar(50),
    pay_method           varchar(200),
    item_name            varchar(200),
    item_connotation     varchar(1000),
    exclusion_content    varchar(1000),
    pricing_unit         varchar(50),
    fee_standard         varchar(50),
    remarks              varchar(500),
    limit_content        varchar(500),
    fee_category         varchar(100),
    tech_classification  varchar(200),
    pay_category         varchar(100),
    self_burden_rate     varchar(50),
    limit_pay_scope      varchar(500),
    is_trial             varchar(20),
    country_unified_code varchar(50),
    source_row           text,
    import_status        varchar(20) NOT NULL DEFAULT 'pending',
    error_message        text,
    created_time         timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 25) 医保接入配置表（按机构 + 保险系统定位医保对接参数）
-- 字段来源（每个字段都有代码引用，不是猜的）：
--   - Cls_SHGBYB.cs:110  xzqh         → BusinessHelper.mdtrtareaAdmvs（就医地医保区划）
--   - Cls_SHGBYB.cs:111  url          → BusinessHelper.url（国家医保 CSB HTTP 交易地址）
--   - Cls_SHGBYB.cs:112  medinstype   → BusinessHelper.medinsType（医保智能监管医疗服务机构类型）
--   - Cls_SHGBYB.cs:113  medinslv     → BusinessHelper.medinsLv（医保智能监管医疗机构等级）
--   - Cls_SHGBYB.cs:114  znjgEnabled  → BusinessHelper.znjgEnabled（智能监管启用标志）
--   - DataHelper.cs 多处 c.admvs_area → 拼对账唯一键
-- 主键 (ins_id, org_id) 复合唯一 —— 一个机构在一个保险系统下一条配置
CREATE TABLE IF NOT EXISTS insur.insure_config (
    ins_id          varchar(36) NOT NULL,
    org_id          varchar(36) NOT NULL,
    xzqh            varchar(20),
    url             varchar(500),
    medinstype      varchar(20),
    medinslv        varchar(20),
    znjgEnabled     varchar(10),
    admvs_area      varchar(20),
    CONSTRAINT pk_insure_config PRIMARY KEY (ins_id, org_id)
);

-- 26) 国家医保接口交易审计日志（DBLoggingInterceptor AOP 自动写入）
-- 字段来源：DataHelper.cs:5874 InsertInsLog 的 INSERT 列表（msgid/infno/admvs/opter/inf_time/...）
-- 写入触发：Filter/DBLoggingInterceptor 拦截 BusinessHelper.YBBusiness → HttpUtils.Post，交易完成后自动落库
CREATE TABLE insur.ins_log (
	id varchar(36) NOT NULL,
	org_id varchar(36) NULL, -- 机构ID
	operator_id varchar(36) NULL, -- 操作员ID
	operator_name varchar(50) NULL, -- 操作员项目
	visit_id varchar(36) NULL, -- 就诊ID
	balance_id varchar(36) NULL, -- 结帐ID
	patient_id varchar(36) NULL, -- 病人ID
	business_name varchar(50) NULL, -- 交易名称
	sendermsg_id varchar(50) NULL, -- 交易流水号
	interfaceurl varchar(200) NULL, -- 接口地址
	in_time timestamp(0) NULL, -- 入参时间
	in_log text NULL, -- 入参
	out_time timestamp(0) NULL, -- 出参时间
	out_type varchar(20) NULL, -- 交易状态
	out_log text NULL, -- 出参
	CONSTRAINT ins_log_pkey PRIMARY KEY (id)
);

-- 24) 西药中成药导入临时表
CREATE TABLE IF NOT EXISTS insur.wm_medicine_import (
    id                  bigserial PRIMARY KEY,
    batch_no            varchar(50) NOT NULL,
    row_number          integer NOT NULL,
    medicine_code       varchar(50),
    medicine_name       varchar(200),
    product_name        varchar(200),
    spec                varchar(100),
    unit                varchar(20),
    manufacturer        varchar(200),
    payment_policy      varchar(500),
    ab_flag             varchar(20),
    catalog_order_code  varchar(50),
    remarks             varchar(500),
    medicine_type       varchar(20),
    fee_type            varchar(50),
    status              varchar(50),
    source_row          text,
    import_status       varchar(20) NOT NULL DEFAULT 'pending',
    error_message       text,
    created_time        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- 注释（字段注释优先来自 Model/现有代码语义；无法确认字段语义则留空）
COMMENT ON TABLE insur.catalog_download_info IS '目录下载信息表';
COMMENT ON COLUMN insur.catalog_download_info.ins_id IS '保险系统ID';
COMMENT ON COLUMN insur.catalog_download_info.org_id IS '机构ID';
COMMENT ON COLUMN insur.catalog_download_info.infno IS '目录交易编码';
COMMENT ON COLUMN insur.catalog_download_info.infno_name IS '目录名称';
COMMENT ON COLUMN insur.catalog_download_info.ver_name IS '版本名称';
COMMENT ON COLUMN insur.catalog_download_info.dld_end_time IS '下载结束时间';
COMMENT ON COLUMN insur.catalog_download_info.create_time IS '创建时间';
COMMENT ON COLUMN insur.catalog_download_info.update_time IS '更新时间';

COMMENT ON TABLE insur.daily_reconcile_main IS '日对账主表';
COMMENT ON COLUMN insur.daily_reconcile_main.id IS '主记录ID';
COMMENT ON COLUMN insur.daily_reconcile_main.org_id IS '机构ID';
COMMENT ON COLUMN insur.daily_reconcile_main.fixmedins_code IS '医药机构编号';
COMMENT ON COLUMN insur.daily_reconcile_main.fixmedins_name IS '医药机构名称';
COMMENT ON COLUMN insur.daily_reconcile_main.reconcile_date IS '对账日期';
COMMENT ON COLUMN insur.daily_reconcile_main.reconcile_status IS '对账状态';
COMMENT ON COLUMN insur.daily_reconcile_main.reconcile_time IS '对账时间';
COMMENT ON COLUMN insur.daily_reconcile_main.operator_id IS '操作员ID';
COMMENT ON COLUMN insur.daily_reconcile_main.operator_name IS '操作员名称';
COMMENT ON COLUMN insur.daily_reconcile_main.claim_status IS '申报状态';
COMMENT ON COLUMN insur.daily_reconcile_main.claim_time IS '申报时间';
COMMENT ON COLUMN insur.daily_reconcile_main.remark IS '备注';
COMMENT ON COLUMN insur.daily_reconcile_main.create_time IS '创建时间';
COMMENT ON COLUMN insur.daily_reconcile_main.update_time IS '更新时间';

COMMENT ON TABLE insur.daily_reconcile_detail IS '日对账明细表';
COMMENT ON COLUMN insur.daily_reconcile_detail.id IS '明细记录ID';
COMMENT ON COLUMN insur.daily_reconcile_detail.main_id IS '主记录ID';
COMMENT ON COLUMN insur.daily_reconcile_detail.org_id IS '机构ID';
COMMENT ON COLUMN insur.daily_reconcile_detail.reconcile_date IS '对账日期';
COMMENT ON COLUMN insur.daily_reconcile_detail.insure_type IS '险种类型';
COMMENT ON COLUMN insur.daily_reconcile_detail.med_type IS '医疗类别';
COMMENT ON COLUMN insur.daily_reconcile_detail.clr_type IS '清算类别';
COMMENT ON COLUMN insur.daily_reconcile_detail.setl_optins IS '结算操作信息';
COMMENT ON COLUMN insur.daily_reconcile_detail.medfee_amt IS '本地医疗费总额';
COMMENT ON COLUMN insur.daily_reconcile_detail.fund_amt IS '本地基金支付金额';
COMMENT ON COLUMN insur.daily_reconcile_detail.acct_amt IS '本地个人账户金额';
COMMENT ON COLUMN insur.daily_reconcile_detail.setl_cnt IS '本地结算人次';
COMMENT ON COLUMN insur.daily_reconcile_detail.center_medfee_amt IS '中心医疗费总额';
COMMENT ON COLUMN insur.daily_reconcile_detail.center_fund_amt IS '中心基金支付金额';
COMMENT ON COLUMN insur.daily_reconcile_detail.center_acct_amt IS '中心个人账户金额';
COMMENT ON COLUMN insur.daily_reconcile_detail.center_setl_cnt IS '中心结算人次';
COMMENT ON COLUMN insur.daily_reconcile_detail.reconcile_result IS '对账结果';
COMMENT ON COLUMN insur.daily_reconcile_detail.result_desc IS '结果说明';
COMMENT ON COLUMN insur.daily_reconcile_detail.reconcile_time IS '对账时间';
COMMENT ON COLUMN insur.daily_reconcile_detail.remark IS '备注';
COMMENT ON COLUMN insur.daily_reconcile_detail.create_time IS '创建时间';
COMMENT ON COLUMN insur.daily_reconcile_detail.update_time IS '更新时间';
COMMENT ON TABLE insur.ins_disease_type IS '医保病种类型表';
COMMENT ON COLUMN insur.ins_disease_type.id IS '主键ID';
COMMENT ON COLUMN insur.ins_disease_type.ins_id IS '保险系统ID';
COMMENT ON COLUMN insur.ins_disease_type.disease_type IS '病种类型';
COMMENT ON COLUMN insur.ins_disease_type.code IS '病种编码';
COMMENT ON COLUMN insur.ins_disease_type.name IS '病种名称';
COMMENT ON COLUMN insur.ins_disease_type.py_code IS '拼音码';
COMMENT ON COLUMN insur.ins_disease_type.create_time IS '创建时间';

COMMENT ON TABLE insur.ins_item_sh_unconflict IS '上海医保目录临时汇总表（不冲突）';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.id IS '主键ID';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.ins_id IS '保险系统ID';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.ins_item_code IS '医保项目编码';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.name IS '项目名称';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.ins_category IS '医保目录类别';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.fee_type IS '费用类型';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.fee_level IS '费用等级';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.specification IS '规格';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.unit IS '单位';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.sourceland IS '来源地/生产企业';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.country_unified_code IS '国家统一编码';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.country_unified_name IS '国家统一名称';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.out_pay_rate IS '自付比例';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.start_time IS '生效时间';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.end_time IS '失效时间';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.remarks IS '备注';
COMMENT ON COLUMN insur.ins_item_sh_unconflict.create_time IS '创建时间';


COMMENT ON TABLE insur.ins_reg_record IS '挂号医保关联记录表';
COMMENT ON COLUMN insur.ins_reg_record.visit_id IS '就诊事件ID';
COMMENT ON COLUMN insur.ins_reg_record.pt_id IS '患者ID';
COMMENT ON COLUMN insur.ins_reg_record.org_id IS '机构ID';
COMMENT ON COLUMN insur.ins_reg_record.jzdyh IS '就诊单元号';
COMMENT ON COLUMN insur.ins_reg_record.dept_id IS '科室ID';
COMMENT ON COLUMN insur.ins_reg_record.yllb IS '医疗类别';
COMMENT ON COLUMN insur.ins_reg_record.person_spectag IS '人员特殊标识';
COMMENT ON COLUMN insur.ins_reg_record.person_type IS '人员类别';
COMMENT ON COLUMN insur.ins_reg_record.dbtype IS '大病类型';
COMMENT ON COLUMN insur.ins_reg_record.jmbz IS '减免标志';
COMMENT ON COLUMN insur.ins_reg_record.create_time IS '创建时间';

COMMENT ON TABLE insur.ins_standard_dept IS '国家标准科室表';
COMMENT ON COLUMN insur.ins_standard_dept.id IS '标准科室ID';
COMMENT ON COLUMN insur.ins_standard_dept.parent_id IS '上级标准科室ID';
COMMENT ON COLUMN insur.ins_standard_dept.standard_name IS '标准科室名称';
COMMENT ON COLUMN insur.ins_standard_dept.standard_code IS '标准科室编码';

COMMENT ON TABLE insur.ins_standard_dept_sh IS '五期标准科室表';
COMMENT ON COLUMN insur.ins_standard_dept_sh.id IS '标准科室ID';
COMMENT ON COLUMN insur.ins_standard_dept_sh.parent_id IS '上级标准科室ID';
COMMENT ON COLUMN insur.ins_standard_dept_sh.standard_name IS '标准科室名称';
COMMENT ON COLUMN insur.ins_standard_dept_sh.standard_code IS '标准科室编码';

COMMENT ON TABLE insur.ins_standard_dept_vs IS '本地科室与国家标准科室映射表';
COMMENT ON COLUMN insur.ins_standard_dept_vs.local_dept_id IS '本地科室ID';
COMMENT ON COLUMN insur.ins_standard_dept_vs.standard_dept_id IS '标准科室ID';
COMMENT ON COLUMN insur.ins_standard_dept_vs.org_id IS '机构ID';
COMMENT ON COLUMN insur.ins_standard_dept_vs.create_time IS '创建时间';

COMMENT ON TABLE insur.ins_standard_dept_vs_sh IS '本地科室与五期标准科室映射表';
COMMENT ON COLUMN insur.ins_standard_dept_vs_sh.local_dept_id IS '本地科室ID';
COMMENT ON COLUMN insur.ins_standard_dept_vs_sh.standard_dept_id IS '标准科室ID';
COMMENT ON COLUMN insur.ins_standard_dept_vs_sh.org_id IS '机构ID';
COMMENT ON COLUMN insur.ins_standard_dept_vs_sh.create_time IS '创建时间';

COMMENT ON TABLE insur.ins_system_mapping IS '保险系统映射表';
COMMENT ON COLUMN insur.ins_system_mapping.id IS '主键ID';
COMMENT ON COLUMN insur.ins_system_mapping.ins_id IS '原保险系统ID';
COMMENT ON COLUMN insur.ins_system_mapping.mapping_sno IS '映射序号';
COMMENT ON COLUMN insur.ins_system_mapping.mapping_insid IS '映射后保险系统ID';
COMMENT ON COLUMN insur.ins_system_mapping.create_time IS '创建时间';

COMMENT ON TABLE insur.month_check_info IS '月结对账主记录表';
COMMENT ON COLUMN insur.month_check_info.id IS '对账记录ID';
COMMENT ON COLUMN insur.month_check_info.fixmedins_code IS '医药机构编号';
COMMENT ON COLUMN insur.month_check_info.fixmedins_name IS '医药机构名称';
COMMENT ON COLUMN insur.month_check_info.fix_blng_admdvs IS '医药机构医保区划';
COMMENT ON COLUMN insur.month_check_info.org_id IS '机构ID';
COMMENT ON COLUMN insur.month_check_info.setl_mon IS '结算月份';
COMMENT ON COLUMN insur.month_check_info.fix_fill_dept IS '医疗机构填报部门';
COMMENT ON COLUMN insur.month_check_info.fix_fill_psn_id IS '医疗机构填报人ID';
COMMENT ON COLUMN insur.month_check_info.fix_fill_psn IS '医疗机构填报人';
COMMENT ON COLUMN insur.month_check_info.upload_time IS '上传时间';
COMMENT ON COLUMN insur.month_check_info.stmt_loc IS '对账地点类别';
COMMENT ON COLUMN insur.month_check_info.upld_btch IS '上传批次';
COMMENT ON COLUMN insur.month_check_info.stmt_status IS '对账状态';
COMMENT ON COLUMN insur.month_check_info.type IS '类别';
COMMENT ON COLUMN insur.month_check_info.memo IS '备注';
COMMENT ON COLUMN insur.month_check_info.claim_status IS '申报状态';
COMMENT ON COLUMN insur.month_check_info.create_time IS '创建时间';
COMMENT ON COLUMN insur.month_check_info.update_time IS '更新时间';

COMMENT ON TABLE insur.month_check_fund_group IS '月结对账基金分组表';
COMMENT ON COLUMN insur.month_check_fund_group.id IS '基金分组记录ID';
COMMENT ON COLUMN insur.month_check_fund_group.recon_id IS '对账记录ID';
COMMENT ON COLUMN insur.month_check_fund_group.insure_type IS '险种类型';
COMMENT ON COLUMN insur.month_check_fund_group.psn_type IS '人员类别';
COMMENT ON COLUMN insur.month_check_fund_group.med_type IS '医疗类别';
COMMENT ON COLUMN insur.month_check_fund_group.fix_blng_admdvs IS '医药机构医保区划';
COMMENT ON COLUMN insur.month_check_fund_group.insu_admdvs IS '参保地医保区划';
COMMENT ON COLUMN insur.month_check_fund_group.psn_times IS '人次';
COMMENT ON COLUMN insur.month_check_fund_group.psn_cnt IS '人数';
COMMENT ON COLUMN insur.month_check_fund_group.medfee_sumamt IS '医疗费总额';
COMMENT ON COLUMN insur.month_check_fund_group.inscp_amt IS '符合范围金额';
COMMENT ON COLUMN insur.month_check_fund_group.fund_pay_sumamt IS '费用支付总额';
COMMENT ON COLUMN insur.month_check_fund_group.fund_key IS '唯一键';
COMMENT ON COLUMN insur.month_check_fund_group.create_time IS '创建时间';

COMMENT ON TABLE insur.month_check_fee_info IS '月结对账费用项表';
COMMENT ON COLUMN insur.month_check_fee_info.id IS '费用项记录ID';
COMMENT ON COLUMN insur.month_check_fee_info.recon_id IS '对账记录ID';
COMMENT ON COLUMN insur.month_check_fee_info.fund_key IS '唯一键';
COMMENT ON COLUMN insur.month_check_fee_info.fix_blng_admdvs IS '医药机构医保区划';
COMMENT ON COLUMN insur.month_check_fee_info.insu_admdvs IS '参保地医保区划';
COMMENT ON COLUMN insur.month_check_fee_info.fund_code IS '费用编码';
COMMENT ON COLUMN insur.month_check_fee_info.fund_name IS '费用名称';
COMMENT ON COLUMN insur.month_check_fee_info.fund_amt IS '费用金额';
COMMENT ON COLUMN insur.month_check_fee_info.memo IS '备注';
COMMENT ON COLUMN insur.month_check_fee_info.create_time IS '创建时间';

COMMENT ON TABLE insur.month_check_solidify_info IS '月结对账固化明细表';
COMMENT ON COLUMN insur.month_check_solidify_info.id IS '主键ID';
COMMENT ON COLUMN insur.month_check_solidify_info.solidify_id IS '固化ID';
COMMENT ON COLUMN insur.month_check_solidify_info.recon_id IS '对账记录ID';
COMMENT ON COLUMN insur.month_check_solidify_info.fixmedins_code IS '医药机构编号';
COMMENT ON COLUMN insur.month_check_solidify_info.fixmedins_name IS '医药机构名称';
COMMENT ON COLUMN insur.month_check_solidify_info.fix_blng_admdvs IS '医药机构医保区划';
COMMENT ON COLUMN insur.month_check_solidify_info.setl_mon IS '结算月份';
COMMENT ON COLUMN insur.month_check_solidify_info.setl_date IS '结算日期';
COMMENT ON COLUMN insur.month_check_solidify_info.insure_type IS '险种类型';
COMMENT ON COLUMN insur.month_check_solidify_info.psn_type IS '人员类别';
COMMENT ON COLUMN insur.month_check_solidify_info.med_type IS '医疗类别';
COMMENT ON COLUMN insur.month_check_solidify_info.insu_admdvs IS '参保地医保区划';
COMMENT ON COLUMN insur.month_check_solidify_info.psn_times IS '人次';
COMMENT ON COLUMN insur.month_check_solidify_info.psn_cnt IS '人数';
COMMENT ON COLUMN insur.month_check_solidify_info.medfee_sumamt IS '医疗费总额';
COMMENT ON COLUMN insur.month_check_solidify_info.inscp_amt IS '符合范围金额';
COMMENT ON COLUMN insur.month_check_solidify_info.fund_pay_sumamt IS '费用支付总额';
COMMENT ON COLUMN insur.month_check_solidify_info.fund_code IS '费用编码';
COMMENT ON COLUMN insur.month_check_solidify_info.fund_name IS '费用名称';
COMMENT ON COLUMN insur.month_check_solidify_info.fund_amt IS '费用金额';
COMMENT ON COLUMN insur.month_check_solidify_info.type IS '类别';
COMMENT ON COLUMN insur.month_check_solidify_info.memo IS '备注';
COMMENT ON COLUMN insur.month_check_solidify_info.create_time IS '创建时间';

COMMENT ON TABLE insur.psi_upload_rec IS '进销存上传记录表';
COMMENT ON COLUMN insur.psi_upload_rec.id IS '上传记录ID';
COMMENT ON COLUMN insur.psi_upload_rec.infno IS '交易编码';
COMMENT ON COLUMN insur.psi_upload_rec.opter_name IS '经办人名称';
COMMENT ON COLUMN insur.psi_upload_rec.inf_time IS '交易时间';
COMMENT ON COLUMN insur.psi_upload_rec.no IS '单据号';
COMMENT ON COLUMN insur.psi_upload_rec.bill_type IS '单据类型';
COMMENT ON COLUMN insur.psi_upload_rec.org_id IS '机构ID';
COMMENT ON COLUMN insur.psi_upload_rec.bill_status IS '单据状态';
COMMENT ON COLUMN insur.psi_upload_rec.create_time IS '创建时间';

ALTER TABLE insur.psi_sale_details OWNER TO cict;

COMMENT ON TABLE insur.psi_sale_details IS '进销存销售明细表（3505/3505A 上传记录）';
COMMENT ON COLUMN insur.psi_sale_details.id IS '主键ID';
COMMENT ON COLUMN insur.psi_sale_details.med_list_codg IS '医疗目录编码';
COMMENT ON COLUMN insur.psi_sale_details.fixmedins_hilist_id IS '定点医药机构目录编号';
COMMENT ON COLUMN insur.psi_sale_details.fixmedins_hilist_name IS '定点医药机构目录名称';
COMMENT ON COLUMN insur.psi_sale_details.fixmedins_bchno IS '定点医药机构批次流水号';
COMMENT ON COLUMN insur.psi_sale_details.prsc_dr_cert_type IS '开方医师证件类型';
COMMENT ON COLUMN insur.psi_sale_details.prsc_dr_certno IS '开方医师证件号码';
COMMENT ON COLUMN insur.psi_sale_details.prsc_dr_name IS '开方医师姓名';
COMMENT ON COLUMN insur.psi_sale_details.phar_cert_type IS '药师证件类型';
COMMENT ON COLUMN insur.psi_sale_details.phar_certno IS '药师证件号码';
COMMENT ON COLUMN insur.psi_sale_details.phar_name IS '药师姓名';
COMMENT ON COLUMN insur.psi_sale_details.phar_prac_cert_no IS '药师执业资格证号';
COMMENT ON COLUMN insur.psi_sale_details.hi_feesetl_type IS '医保费用结算类型';
COMMENT ON COLUMN insur.psi_sale_details.setl_id IS '结算ID';
COMMENT ON COLUMN insur.psi_sale_details.mdtrt_sn IS '就医流水号';
COMMENT ON COLUMN insur.psi_sale_details.psn_no IS '人员编号';
COMMENT ON COLUMN insur.psi_sale_details.psn_cert_type IS '人员证件类型';
COMMENT ON COLUMN insur.psi_sale_details.certno IS '证件号码';
COMMENT ON COLUMN insur.psi_sale_details.psn_name IS '人员姓名';
COMMENT ON COLUMN insur.psi_sale_details.manu_lotnum IS '生产批号';
COMMENT ON COLUMN insur.psi_sale_details.manu_date IS '生产日期';
COMMENT ON COLUMN insur.psi_sale_details.expy_end IS '有效期止';
COMMENT ON COLUMN insur.psi_sale_details.rx_flag IS '处方药标志';
COMMENT ON COLUMN insur.psi_sale_details.trdn_flag IS '拆零标志';
COMMENT ON COLUMN insur.psi_sale_details.finl_trns_pric IS '最终成交单价';
COMMENT ON COLUMN insur.psi_sale_details.rxno IS '处方号';
COMMENT ON COLUMN insur.psi_sale_details.rx_circ_flag IS '外购处方标志';
COMMENT ON COLUMN insur.psi_sale_details.rtal_docno IS '零售单据号';
COMMENT ON COLUMN insur.psi_sale_details.stoout_no IS '销售出库单据号';
COMMENT ON COLUMN insur.psi_sale_details.bchno IS '批次号';
COMMENT ON COLUMN insur.psi_sale_details.drug_prod_barc IS '药品条形码';
COMMENT ON COLUMN insur.psi_sale_details.shelf_posi IS '货架位';
COMMENT ON COLUMN insur.psi_sale_details.sel_retn_cnt IS '销售/退货数量';
COMMENT ON COLUMN insur.psi_sale_details.sel_retn_time IS '销售/退货时间';
COMMENT ON COLUMN insur.psi_sale_details.sel_retn_opter_name IS '销售/退货经办人姓名';
COMMENT ON COLUMN insur.psi_sale_details.memo IS '备注';
COMMENT ON COLUMN insur.psi_sale_details.mdtrt_setl_type IS '就诊结算类型（1-医保结算 2-自费结算）';
COMMENT ON COLUMN insur.psi_sale_details.drugtracinfo IS '溯源码节点信息（jsonb）';
COMMENT ON COLUMN insur.psi_sale_details.rec_id IS '上传记录ID（关联 psi_upload_rec.id）';
COMMENT ON COLUMN insur.psi_sale_details.drug_id IS '药品ID';
COMMENT ON COLUMN insur.psi_sale_details.sno IS '发药次序';
COMMENT ON COLUMN insur.psi_sale_details.create_time IS '创建时间';

COMMENT ON TABLE insur.sel_fee_upload_info IS '结算费用申报记录表';
COMMENT ON COLUMN insur.sel_fee_upload_info.id IS '主键ID';
COMMENT ON COLUMN insur.sel_fee_upload_info.recon_id IS '对账记录ID';
COMMENT ON COLUMN insur.sel_fee_upload_info.fixmedins_code IS '医药机构编号';
COMMENT ON COLUMN insur.sel_fee_upload_info.fixmedins_name IS '医药机构名称';
COMMENT ON COLUMN insur.sel_fee_upload_info.setl_mon IS '结算月份';
COMMENT ON COLUMN insur.sel_fee_upload_info.upld_btch IS '上传批次';
COMMENT ON COLUMN insur.sel_fee_upload_info.create_time IS '创建时间';

COMMENT ON TABLE insur.settle_list_upload IS '结算清单上传记录表';
COMMENT ON COLUMN insur.settle_list_upload.id IS '主键ID';
COMMENT ON COLUMN insur.settle_list_upload.visit_id IS '就诊事件ID';
COMMENT ON COLUMN insur.settle_list_upload.balance_id IS '结算ID';
COMMENT ON COLUMN insur.settle_list_upload.pt_id IS '患者ID';
COMMENT ON COLUMN insur.settle_list_upload.setl_list_id IS '结算清单号';
COMMENT ON COLUMN insur.settle_list_upload.upload_time IS '上传时间';
COMMENT ON COLUMN insur.settle_list_upload.operater_id IS '操作员ID';
COMMENT ON COLUMN insur.settle_list_upload.operator_name IS '操作员名称';
COMMENT ON COLUMN insur.settle_list_upload.org_id IS '机构ID';
COMMENT ON COLUMN insur.settle_list_upload.request_data IS '请求报文';
COMMENT ON COLUMN insur.settle_list_upload.stas_type IS '清单状态';
COMMENT ON COLUMN insur.settle_list_upload.create_time IS '创建时间';

COMMENT ON TABLE insur.sign_info IS '签到记录表';
COMMENT ON COLUMN insur.sign_info.id IS '主键ID';
COMMENT ON COLUMN insur.sign_info.org_id IS '机构ID';
COMMENT ON COLUMN insur.sign_info.ins_id IS '保险系统ID';
COMMENT ON COLUMN insur.sign_info.operator_id IS '操作员ID';
COMMENT ON COLUMN insur.sign_info.operator_code IS '操作员编码';
COMMENT ON COLUMN insur.sign_info.sign_time IS '签到时间';
COMMENT ON COLUMN insur.sign_info.sign_no IS '签到流水号';
COMMENT ON COLUMN insur.sign_info.status IS '状态';
COMMENT ON COLUMN insur.sign_info.ip IS '终端IP';
COMMENT ON COLUMN insur.sign_info.mac IS '终端MAC';
COMMENT ON COLUMN insur.sign_info.create_time IS '创建时间';


COMMENT ON TABLE insur.insure_config IS '医保接入配置表';
COMMENT ON COLUMN insur.insure_config.ins_id IS '保险系统ID（varchar，与 ins_balance.ins_id 通过 cast 关联）';
COMMENT ON COLUMN insur.insure_config.org_id IS '机构ID';
COMMENT ON COLUMN insur.insure_config.xzqh IS '就医地医保区划编码（6位行政区划）';
COMMENT ON COLUMN insur.insure_config.url IS '国家医保交易地址（CSB HTTP 接口）';
COMMENT ON COLUMN insur.insure_config.medinstype IS '医保智能监管医疗服务机构类型';
COMMENT ON COLUMN insur.insure_config.medinslv IS '医保智能监管医疗机构等级';
COMMENT ON COLUMN insur.insure_config.znjgEnabled IS '智能监管启用标志（0=关闭，1=启用）';
COMMENT ON COLUMN insur.insure_config.admvs_area IS '医保区划代码（用于拼接对账唯一键）';

COMMENT ON TABLE insur.ins_log IS '自定义_医保日志表';
COMMENT ON COLUMN insur.ins_log.id IS '主键ID';
COMMENT ON COLUMN insur.ins_log.org_id IS '机构ID';
COMMENT ON COLUMN insur.ins_log.operator_id IS '操作员ID';
COMMENT ON COLUMN insur.ins_log.operator_name IS '操作员名称';
COMMENT ON COLUMN insur.ins_log.visit_id IS '就诊ID';
COMMENT ON COLUMN insur.ins_log.balance_id IS '结帐ID';
COMMENT ON COLUMN insur.ins_log.patient_id IS '病人ID';
COMMENT ON COLUMN insur.ins_log.business_name IS '交易名称';
COMMENT ON COLUMN insur.ins_log.sendermsg_id IS '交易流水号';
COMMENT ON COLUMN insur.ins_log.interfaceurl IS '接口地址';
COMMENT ON COLUMN insur.ins_log.in_time IS '入参时间';
COMMENT ON COLUMN insur.ins_log.in_log IS '入参';
COMMENT ON COLUMN insur.ins_log.out_time IS '出参时间';
COMMENT ON COLUMN insur.ins_log.out_type IS '交易状态';
COMMENT ON COLUMN insur.ins_log.out_log IS '出参';

COMMENT ON TABLE insur.tcm_medicine_import IS '中药饮片导入临时表';
COMMENT ON COLUMN insur.tcm_medicine_import.id IS '主键ID';
COMMENT ON COLUMN insur.tcm_medicine_import.batch_no IS '导入批次号';
COMMENT ON COLUMN insur.tcm_medicine_import.row_number IS 'Excel行号';
COMMENT ON COLUMN insur.tcm_medicine_import.medicine_code IS '医保编码';
COMMENT ON COLUMN insur.tcm_medicine_import.medicine_name IS '药品名称';
COMMENT ON COLUMN insur.tcm_medicine_import.spec IS '规格';
COMMENT ON COLUMN insur.tcm_medicine_import.unit IS '单位';
COMMENT ON COLUMN insur.tcm_medicine_import.price IS '单价';
COMMENT ON COLUMN insur.tcm_medicine_import.category_code IS '分类编码';
COMMENT ON COLUMN insur.tcm_medicine_import.category_name IS '分类名称';
COMMENT ON COLUMN insur.tcm_medicine_import.effective_flag IS '有效标志';
COMMENT ON COLUMN insur.tcm_medicine_import.remarks IS '备注';
COMMENT ON COLUMN insur.tcm_medicine_import.manufacturer IS '生产厂家';
COMMENT ON COLUMN insur.tcm_medicine_import.payment_policy IS '医保支付政策';
COMMENT ON COLUMN insur.tcm_medicine_import.source_row IS '源数据JSON';
COMMENT ON COLUMN insur.tcm_medicine_import.import_status IS '导入状态';
COMMENT ON COLUMN insur.tcm_medicine_import.error_message IS '错误信息';
COMMENT ON COLUMN insur.tcm_medicine_import.created_time IS '创建时间';

COMMENT ON TABLE insur.treat_item_import IS '诊疗项目导入临时表';
COMMENT ON COLUMN insur.treat_item_import.id IS '主键ID';
COMMENT ON COLUMN insur.treat_item_import.batch_no IS '导入批次号';
COMMENT ON COLUMN insur.treat_item_import.row_number IS 'Excel行号';
COMMENT ON COLUMN insur.treat_item_import.ins_code IS '医保编码';
COMMENT ON COLUMN insur.treat_item_import.status IS '状态';
COMMENT ON COLUMN insur.treat_item_import.info_effective_date IS '信息生效日期';
COMMENT ON COLUMN insur.treat_item_import.info_expire_date IS '信息失效日期';
COMMENT ON COLUMN insur.treat_item_import.item_code IS '项目编码';
COMMENT ON COLUMN insur.treat_item_import.pay_method IS '支付方式';
COMMENT ON COLUMN insur.treat_item_import.item_name IS '项目名称';
COMMENT ON COLUMN insur.treat_item_import.item_connotation IS '项目内涵';
COMMENT ON COLUMN insur.treat_item_import.exclusion_content IS '除外内容';
COMMENT ON COLUMN insur.treat_item_import.pricing_unit IS '计价单位';
COMMENT ON COLUMN insur.treat_item_import.fee_standard IS '费用标准';
COMMENT ON COLUMN insur.treat_item_import.remarks IS '备注';
COMMENT ON COLUMN insur.treat_item_import.limit_content IS '限制内容';
COMMENT ON COLUMN insur.treat_item_import.fee_category IS '费用类别';
COMMENT ON COLUMN insur.treat_item_import.tech_classification IS '技术分类';
COMMENT ON COLUMN insur.treat_item_import.pay_category IS '支付类别';
COMMENT ON COLUMN insur.treat_item_import.self_burden_rate IS '自付比例';
COMMENT ON COLUMN insur.treat_item_import.limit_pay_scope IS '限付范围';
COMMENT ON COLUMN insur.treat_item_import.is_trial IS '试行标志';
COMMENT ON COLUMN insur.treat_item_import.country_unified_code IS '国家统一编码';
COMMENT ON COLUMN insur.treat_item_import.source_row IS '源数据JSON';
COMMENT ON COLUMN insur.treat_item_import.import_status IS '导入状态';
COMMENT ON COLUMN insur.treat_item_import.error_message IS '错误信息';
COMMENT ON COLUMN insur.treat_item_import.created_time IS '创建时间';

COMMENT ON TABLE insur.wm_medicine_import IS '西药中成药导入临时表';
COMMENT ON COLUMN insur.wm_medicine_import.id IS '主键ID';
COMMENT ON COLUMN insur.wm_medicine_import.batch_no IS '导入批次号';
COMMENT ON COLUMN insur.wm_medicine_import.row_number IS 'Excel行号';
COMMENT ON COLUMN insur.wm_medicine_import.medicine_code IS '医保编码';
COMMENT ON COLUMN insur.wm_medicine_import.medicine_name IS '药品名称';
COMMENT ON COLUMN insur.wm_medicine_import.product_name IS '产品名称';
COMMENT ON COLUMN insur.wm_medicine_import.spec IS '规格';
COMMENT ON COLUMN insur.wm_medicine_import.unit IS '单位';
COMMENT ON COLUMN insur.wm_medicine_import.manufacturer IS '生产厂家';
COMMENT ON COLUMN insur.wm_medicine_import.payment_policy IS '医保支付政策';
COMMENT ON COLUMN insur.wm_medicine_import.ab_flag IS '甲乙标识';
COMMENT ON COLUMN insur.wm_medicine_import.catalog_order_code IS '目录序号';
COMMENT ON COLUMN insur.wm_medicine_import.remarks IS '备注';
COMMENT ON COLUMN insur.wm_medicine_import.medicine_type IS '药品类型';
COMMENT ON COLUMN insur.wm_medicine_import.fee_type IS '费用类型';
COMMENT ON COLUMN insur.wm_medicine_import.status IS '状态';
COMMENT ON COLUMN insur.wm_medicine_import.source_row IS '源数据JSON';
COMMENT ON COLUMN insur.wm_medicine_import.import_status IS '导入状态';
COMMENT ON COLUMN insur.wm_medicine_import.error_message IS '错误信息';
COMMENT ON COLUMN insur.wm_medicine_import.created_time IS '创建时间';

-- 索引(按代码查询条件补充)
CREATE INDEX IF NOT EXISTS idx_daily_reconcile_main_org_date ON insur.daily_reconcile_main(org_id, reconcile_date);
CREATE INDEX IF NOT EXISTS idx_daily_reconcile_detail_main ON insur.daily_reconcile_detail(main_id);
CREATE INDEX IF NOT EXISTS idx_ins_reg_record_pt ON insur.ins_reg_record(pt_id, org_id);
CREATE INDEX IF NOT EXISTS idx_ins_system_mapping_ins_sno ON insur.ins_system_mapping(ins_id, mapping_sno);
CREATE INDEX IF NOT EXISTS idx_month_check_info_org_mon ON insur.month_check_info(org_id, setl_mon);
CREATE INDEX IF NOT EXISTS idx_month_check_fund_group_recon ON insur.month_check_fund_group(recon_id);
CREATE INDEX IF NOT EXISTS idx_month_check_fee_info_recon ON insur.month_check_fee_info(recon_id);
CREATE INDEX IF NOT EXISTS idx_month_check_solidify_recon ON insur.month_check_solidify_info(recon_id);
CREATE INDEX IF NOT EXISTS idx_psi_upload_rec_no_type_org ON insur.psi_upload_rec(no, bill_type, org_id);
CREATE INDEX IF NOT EXISTS idx_psi_sale_details_rec ON insur.psi_sale_details(rec_id);
CREATE INDEX IF NOT EXISTS idx_sel_fee_upload_info_recon ON insur.sel_fee_upload_info(recon_id);
CREATE INDEX IF NOT EXISTS idx_settle_list_upload_balance ON insur.settle_list_upload(balance_id);
CREATE INDEX IF NOT EXISTS idx_sign_info_key ON insur.sign_info(operator_code, ins_id, sign_time);
CREATE INDEX IF NOT EXISTS idx_temp_tcm_batch_no ON insur.tcm_medicine_import(batch_no);
CREATE INDEX IF NOT EXISTS idx_temp_tcm_medicine_code ON insur.tcm_medicine_import(medicine_code);
CREATE INDEX IF NOT EXISTS idx_temp_tcm_batch_status ON insur.tcm_medicine_import(batch_no, import_status);
CREATE INDEX IF NOT EXISTS idx_temp_treat_batch_no ON insur.treat_item_import(batch_no);
CREATE INDEX IF NOT EXISTS idx_temp_treat_item_code ON insur.treat_item_import(item_code);
CREATE INDEX IF NOT EXISTS idx_temp_treat_ins_code ON insur.treat_item_import(ins_code);
CREATE INDEX IF NOT EXISTS idx_temp_treat_country_code ON insur.treat_item_import(country_unified_code);
CREATE INDEX IF NOT EXISTS idx_temp_treat_batch_status ON insur.treat_item_import(batch_no, import_status);
CREATE INDEX IF NOT EXISTS idx_temp_wm_batch_no ON insur.wm_medicine_import(batch_no);
CREATE INDEX IF NOT EXISTS idx_temp_wm_code ON insur.wm_medicine_import(medicine_code);
CREATE INDEX IF NOT EXISTS idx_temp_wm_batch_status ON insur.wm_medicine_import(batch_no, import_status);
CREATE INDEX IF NOT EXISTS "ix_ins_log$balance_id" ON insur.ins_log USING btree (balance_id);
CREATE INDEX IF NOT EXISTS "ix_ins_log$in_time" ON insur.ins_log USING btree (org_id, in_time);
CREATE INDEX IF NOT EXISTS "ix_ins_log$out_time" ON insur.ins_log USING btree (org_id, out_time);
CREATE INDEX IF NOT EXISTS "ix_ins_log$patient_id" ON insur.ins_log USING btree (patient_id);
CREATE INDEX IF NOT EXISTS "ix_ins_log$visit_id" ON insur.ins_log USING btree (visit_id);

-- 21) ins_balance — 补充 swap_info 冗余字段
-- ins_balance 基础表由 HIS 部署时创建，本段只补充国家医保插件需要的 5 个 cq_* 冗余列

ALTER TABLE insur.ins_balance ADD COLUMN IF NOT EXISTS cq_insutype varchar(50);
ALTER TABLE insur.ins_balance ADD COLUMN IF NOT EXISTS cq_psn_type varchar(50);
ALTER TABLE insur.ins_balance ADD COLUMN IF NOT EXISTS cq_med_type varchar(50);
ALTER TABLE insur.ins_balance ADD COLUMN IF NOT EXISTS cq_clr_optins varchar(50);
ALTER TABLE insur.ins_balance ADD COLUMN IF NOT EXISTS cq_insuplc_admdvs varchar(50);

COMMENT ON COLUMN insur.ins_balance.cq_insutype IS 'swap_info 冗余: 选择险种类型';
COMMENT ON COLUMN insur.ins_balance.cq_psn_type IS 'swap_info 冗余: 人员类别';
COMMENT ON COLUMN insur.ins_balance.cq_med_type IS 'swap_info 冗余: 医疗类别';
COMMENT ON COLUMN insur.ins_balance.cq_clr_optins IS 'swap_info 冗余: 清算经办机构';
COMMENT ON COLUMN insur.ins_balance.cq_insuplc_admdvs IS 'swap_info 冗余: 参保地医保区划';

COMMIT;
