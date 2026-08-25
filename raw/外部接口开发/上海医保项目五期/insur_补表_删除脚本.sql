-- 作者: Keiskei
-- 用途: 删除部署补建的 insur 表
-- 注意: 使用 CASCADE 会同时删除依赖对象，请确认环境后执行

BEGIN;

DROP TABLE IF EXISTS
    insur.psi_sale_details,
    insur.psi_upload_rec,
    insur.daily_reconcile_detail,
    insur.daily_reconcile_main,
    insur.catalog_download_info,
    insur.ins_disease_type,
    insur.ins_item_sh_unconflict,
    insur.ins_reg_record,
    insur.ins_standard_dept_vs_sh,
    insur.ins_standard_dept_vs,
    insur.ins_standard_dept_sh,
    insur.ins_standard_dept,
    insur.ins_system_mapping,
    insur.month_check_fee_info,
    insur.month_check_fund_group,
    insur.month_check_info,
    insur.month_check_solidify_info,
    insur.sel_fee_upload_info,
    insur.settle_list_upload,
    insur.sign_info,
    insur.tcm_medicine_import,
    insur.treat_item_import,
    insur.wm_medicine_import
CASCADE;

COMMIT;
