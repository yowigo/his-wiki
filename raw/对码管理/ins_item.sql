/*2026143912  对码工具里添加一个手动添加医保目录的功能*/
ALTER TABLE insur.ins_item
ADD COLUMN IF NOT EXISTS province_code varchar(100),
ADD COLUMN IF NOT EXISTS update_time timestamp;

COMMENT ON COLUMN insur.ins_item.province_code IS '老省码';
COMMENT ON COLUMN insur.ins_item.update_time IS '数据更新时间';

ALTER TABLE insur.ins_item
ALTER COLUMN update_time SET DEFAULT now();