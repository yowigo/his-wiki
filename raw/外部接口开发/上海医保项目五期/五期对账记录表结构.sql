-- 五期日对账记录表
-- 用于记录上海五期 SL01 对账记录（一次对账一天一条，无明细维度）
CREATE TABLE IF NOT EXISTS insur.daily_reconcile_sh5
(
    id varchar(36) PRIMARY KEY,            -- 主键
    org_id varchar(36) NOT NULL,           -- 机构ID
    fixmedins_code varchar(50) NOT NULL,   -- 医疗机构编码
    fixmedins_name varchar(200),           -- 医疗机构名称
    reconcile_date date NOT NULL,          -- 对账日（daycollate）
    daycount integer,                      -- 中心流水号数量
    totalcuraccpay decimal(16,2),          -- 当年账户支付总额
    totalhisaccpay decimal(16,2),          -- 历年账户支付总额
    totalcashpay decimal(16,2),            -- 现金自负总额
    totaltcpay decimal(16,2),              -- 统筹支付总额
    totaldffjpay decimal(16,2),            -- 附加支付总额
    totalflzf decimal(16,2),               -- 分类自负现金总额
    totalzfaccpay decimal(16,2),           -- 自费账户支付总额（自费历年+自费共济）
    totalfybjsfw decimal(16,2),            -- 非医保范围费用总额
    resultcollate varchar(10),             -- 对账结果原始码: 0-金额不符明细未生成, 1-金额不符明细已生成可下载, 2-对账通过, 3-已通过不需再次对账, 4-改账通过
    result_desc varchar(200),              -- 对账结果说明（中文）
    reconcile_status varchar(10),          -- 对账状态: 0-未对账, 1-已对账（resultcollate 2/3/4 视为已对账）
    reconcile_time timestamp,              -- 对账时间
    operator_id varchar(36),               -- 操作员ID
    operator_name varchar(50),             -- 操作员姓名
    remark text,                           -- 备注
    create_time timestamp DEFAULT CURRENT_TIMESTAMP,  -- 创建时间
    update_time timestamp,                 -- 更新时间
    CONSTRAINT uk_sh5_org_date UNIQUE (org_id, reconcile_date)
);

COMMENT ON TABLE insur.daily_reconcile_sh5 IS '五期日对账记录表';
COMMENT ON COLUMN insur.daily_reconcile_sh5.id IS '主键';
COMMENT ON COLUMN insur.daily_reconcile_sh5.org_id IS '机构ID';
COMMENT ON COLUMN insur.daily_reconcile_sh5.fixmedins_code IS '医疗机构编码';
COMMENT ON COLUMN insur.daily_reconcile_sh5.fixmedins_name IS '医疗机构名称';
COMMENT ON COLUMN insur.daily_reconcile_sh5.reconcile_date IS '对账日（daycollate）';
COMMENT ON COLUMN insur.daily_reconcile_sh5.daycount IS '中心流水号数量';
COMMENT ON COLUMN insur.daily_reconcile_sh5.totalcuraccpay IS '当年账户支付总额';
COMMENT ON COLUMN insur.daily_reconcile_sh5.totalhisaccpay IS '历年账户支付总额';
COMMENT ON COLUMN insur.daily_reconcile_sh5.totalcashpay IS '现金自负总额';
COMMENT ON COLUMN insur.daily_reconcile_sh5.totaltcpay IS '统筹支付总额';
COMMENT ON COLUMN insur.daily_reconcile_sh5.totaldffjpay IS '附加支付总额';
COMMENT ON COLUMN insur.daily_reconcile_sh5.totalflzf IS '分类自负现金总额';
COMMENT ON COLUMN insur.daily_reconcile_sh5.totalzfaccpay IS '自费账户支付总额（自费历年+自费共济）';
COMMENT ON COLUMN insur.daily_reconcile_sh5.totalfybjsfw IS '非医保范围费用总额';
COMMENT ON COLUMN insur.daily_reconcile_sh5.resultcollate IS '对账结果原始码: 0-金额不符明细未生成, 1-金额不符明细已生成可下载, 2-对账通过, 3-已通过不需再次对账, 4-改账通过';
COMMENT ON COLUMN insur.daily_reconcile_sh5.result_desc IS '对账结果说明（中文）';
COMMENT ON COLUMN insur.daily_reconcile_sh5.reconcile_status IS '对账状态: 0-未对账, 1-已对账（resultcollate 2/3/4 视为已对账）';
COMMENT ON COLUMN insur.daily_reconcile_sh5.reconcile_time IS '对账时间';
COMMENT ON COLUMN insur.daily_reconcile_sh5.operator_id IS '操作员ID';
COMMENT ON COLUMN insur.daily_reconcile_sh5.operator_name IS '操作员姓名';
COMMENT ON COLUMN insur.daily_reconcile_sh5.remark IS '备注';
COMMENT ON COLUMN insur.daily_reconcile_sh5.create_time IS '创建时间';
COMMENT ON COLUMN insur.daily_reconcile_sh5.update_time IS '更新时间';

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_sh5_date ON insur.daily_reconcile_sh5(reconcile_date);
CREATE INDEX IF NOT EXISTS idx_sh5_org ON insur.daily_reconcile_sh5(org_id);
CREATE INDEX IF NOT EXISTS idx_sh5_status ON insur.daily_reconcile_sh5(reconcile_status);
CREATE INDEX IF NOT EXISTS idx_sh5_result ON insur.daily_reconcile_sh5(resultcollate);
