-- 作者: Keiskei
-- 用途: 复制 ins_item_vs 对照项目数据到新 ins_id（分批提交，支持大数据量）
-- 源 ins_id: 5388135717170938973
-- 目标 ins_id: 5380194289529592754

BEGIN;

-- 1. 先创建序列（如果还没有）
CREATE SEQUENCE IF NOT EXISTS insur.ins_item_vs_id_seq
START WITH 984850977156756737
MAXVALUE 9223372036854775807
INCREMENT BY 1;

COMMIT;

-- 2. 分批复制
DO $$
DECLARE
    v_batch_size  INT  := 5000;
    v_total       INT;
    v_offset      INT  := 0;
    v_rows        INT;
BEGIN
    SELECT COUNT(*) INTO v_total FROM insur.ins_item_vs WHERE ins_id = 5388135717170938973;
    RAISE NOTICE '源数据总量: % 条，每批 % 条', v_total, v_batch_size;

    LOOP
        INSERT INTO insur.ins_item_vs
        (id, ins_id, fee_item_id, fee_item_name, ins_item_code, is_ins, is_audit, upload_sign,
         center_serial_no, is_unuse, start_time, end_time, ins_category, org_id,
         country_unified_code, operator_id, operator_name, operator_time, is_single,
         nuser, nuse_time, "name", approval_no, specification, sourceland, exchange_drug_storage)
        SELECT
          nextval('insur.ins_item_vs_id_seq'),
          5380194289529592754,
          fee_item_id, fee_item_name, ins_item_code, is_ins, is_audit, upload_sign,
          center_serial_no, is_unuse, start_time, end_time, ins_category, org_id,
          country_unified_code, operator_id, operator_name, operator_time, is_single,
          nuser, nuse_time, "name", approval_no, specification, sourceland, exchange_drug_storage
        FROM insur.ins_item_vs
        WHERE ins_id = 5388135717170938973
        ORDER BY id
        LIMIT v_batch_size OFFSET v_offset;

        GET DIAGNOSTICS v_rows = ROW_COUNT;
        EXIT WHEN v_rows = 0;

        COMMIT;
        v_offset := v_offset + v_rows;
        RAISE NOTICE '已复制 % / % 条', v_offset, v_total;
    END LOOP;

    RAISE NOTICE '复制完成，共 % 条', v_offset;
END $$;
