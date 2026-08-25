-- ============================================================================
-- 医保插件部署自检脚本
-- ============================================================================
-- 著作权人：Keiskei
-- 用途：首次部署或排错时，一次性检查所有部署前置项是否齐全
-- 用法：
--   1. 修改下方三个 \set 变量为本机构实际值
--   2. 连接到 fee 域数据库执行（psql -d <fee_域库名> -f deploy_healthcheck.sql）
--   3. 看输出列：status (✅ 通过 / ❌ 阻塞 / ⚠️ 警告)
--      所有 ❌ 必须在联调前解决，⚠️ 可酌情处理
-- 配套文档：医院部署前置配置清单.md
-- ============================================================================

\set v_org_id          '1'
\set v_national_ins_id '5388135717170938973'
\set v_fifth_ins_id    '5380194289529592754'

\echo '================================================================'
\echo '医保插件部署自检 - 开始'
\echo '================================================================'
\echo ''

-- ----------------------------------------------------------------------------
-- 一、参数确认 + DDL 准备
-- ----------------------------------------------------------------------------
SELECT '【0】参数确认' AS check_item,
       '✅' AS status,
       format('org_id=%s | national_ins_id=%s | fifth_ins_id=%s',
              :'v_org_id', :'v_national_ins_id', :'v_fifth_ins_id') AS detail
UNION ALL
SELECT '【1.1】insur schema 表数量',
       CASE WHEN count(*) >= 26 THEN '✅' ELSE '❌' END,
       format('实际 %s 张（期望 ≥26 = 本脚本 25 张 + HIS 标准的 ins_org_vs，参考 docs/insur_补表_创建脚本.sql）', count(*))
FROM information_schema.tables WHERE table_schema = 'insur'
UNION ALL
SELECT '【1.2】insur.ins_log 表存在',
       CASE WHEN to_regclass('insur.ins_log') IS NOT NULL THEN '✅' ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_log') IS NOT NULL
            THEN 'AOP 日志表存在，国家医保 CSB 交易可正常写日志'
            ELSE '❌ 缺表！每一笔国家医保交易都会异常（参考部署清单第二章）' END
UNION ALL
SELECT '【1.3】insur.sign_info 表存在',
       CASE WHEN to_regclass('insur.sign_info') IS NOT NULL THEN '✅' ELSE '❌' END,
       CASE WHEN to_regclass('insur.sign_info') IS NOT NULL
            THEN '签到记录表存在'
            ELSE '❌ 缺表！InitInsure 签到流程会失败（参考部署清单第二章）' END
UNION ALL
SELECT '【1.4】insur.daily_reconcile_main / detail 表存在',
       CASE WHEN to_regclass('insur.daily_reconcile_main') IS NOT NULL
                 AND to_regclass('insur.daily_reconcile_detail') IS NOT NULL THEN '✅'
            ELSE '⚠️' END,
       CASE WHEN to_regclass('insur.daily_reconcile_main') IS NOT NULL
                 AND to_regclass('insur.daily_reconcile_detail') IS NOT NULL
            THEN '对账表齐全'
            ELSE '⚠️ 缺表，对账工具（function_no=1020）无法使用（参考部署清单第十二章）' END

-- ----------------------------------------------------------------------------
-- 二、保险系统映射 ins_system / ins_system_mapping
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【2.1】ins_system 国家+五期通道',
       CASE WHEN to_regclass('insur.ins_system') IS NULL THEN '❌'
            WHEN (SELECT count(DISTINCT sno) FROM insur.ins_system WHERE sno IN ('11', '12')) = 2 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_system') IS NULL THEN '❌ insur.ins_system 表不存在'
            ELSE format('找到 sno=11/12 不同通道数: %s（期望 2）',
                        (SELECT count(DISTINCT sno) FROM insur.ins_system WHERE sno IN ('11', '12'))) END
UNION ALL
SELECT '【2.2】ins_system_mapping 双通道 → mapping_sno=10',
       CASE WHEN to_regclass('insur.ins_system_mapping') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_system_mapping
                  WHERE mapping_sno = 10
                    AND ins_id IN (:'v_national_ins_id', :'v_fifth_ins_id')
                    AND ins_id = mapping_insid) = 2 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_system_mapping') IS NULL THEN '❌ 表不存在'
            ELSE format('国家+五期到总线(sno=10)且 mapping_insid 指向自身 的记录数: %s（期望 2）',
                        (SELECT count(*) FROM insur.ins_system_mapping
                         WHERE mapping_sno = 10
                           AND ins_id IN (:'v_national_ins_id', :'v_fifth_ins_id')
                           AND ins_id = mapping_insid)) END

-- ----------------------------------------------------------------------------
-- 三、保险医院对照 ins_org_vs
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【3.1】ins_org_vs 国家医保对照',
       CASE WHEN to_regclass('insur.ins_org_vs') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_org_vs
                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id') > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_org_vs') IS NULL THEN '❌ insur.ins_org_vs 表不存在（参考部署清单第四章）'
            ELSE format('当前机构国家医保对照记录数: %s | ins_code: %s',
                        (SELECT count(*) FROM insur.ins_org_vs
                         WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id'),
                        COALESCE((SELECT ins_code FROM insur.ins_org_vs
                                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id' LIMIT 1), '(空)')) END
UNION ALL
SELECT '【3.2】ins_org_vs 上海五期对照',
       CASE WHEN to_regclass('insur.ins_org_vs') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_org_vs
                  WHERE ins_id = :'v_fifth_ins_id' AND org_id = :'v_org_id') > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_org_vs') IS NULL THEN '❌ 表不存在'
            ELSE format('当前机构五期医保对照记录数: %s | ins_code: %s',
                        (SELECT count(*) FROM insur.ins_org_vs
                         WHERE ins_id = :'v_fifth_ins_id' AND org_id = :'v_org_id'),
                        COALESCE((SELECT ins_code FROM insur.ins_org_vs
                                  WHERE ins_id = :'v_fifth_ins_id' AND org_id = :'v_org_id' LIMIT 1), '(空)')) END

-- ----------------------------------------------------------------------------
-- 四、医保配置信息 insure_config
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【4.1】insure_config 国家通道记录存在',
       CASE WHEN to_regclass('insur.insure_config') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.insure_config
                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id') > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.insure_config') IS NULL THEN '❌ 表不存在（参考部署清单第七章）'
            ELSE format('当前机构国家通道配置记录数: %s',
                        (SELECT count(*) FROM insur.insure_config
                         WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id')) END
UNION ALL
SELECT '【4.2】insure_config 关键字段非空',
       CASE WHEN to_regclass('insur.insure_config') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.insure_config
                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id'
                    AND COALESCE(url, '') <> ''
                    AND COALESCE(xzqh, '') <> ''
                    AND COALESCE(medinstype, '') <> ''
                    AND COALESCE(medinslv, '') <> ''
                    AND COALESCE(admvs_area, '') <> '') > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.insure_config') IS NULL THEN '❌ 表不存在'
            ELSE format('url=%s | xzqh=%s | medinstype=%s | medinslv=%s | admvs_area=%s',
                        COALESCE((SELECT url FROM insur.insure_config
                                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id' LIMIT 1), '(空)'),
                        COALESCE((SELECT xzqh FROM insur.insure_config
                                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id' LIMIT 1), '(空)'),
                        COALESCE((SELECT medinstype FROM insur.insure_config
                                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id' LIMIT 1), '(空)'),
                        COALESCE((SELECT medinslv FROM insur.insure_config
                                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id' LIMIT 1), '(空)'),
                        COALESCE((SELECT admvs_area FROM insur.insure_config
                                  WHERE ins_id = :'v_national_ins_id' AND org_id = :'v_org_id' LIMIT 1), '(空)')) END

-- ----------------------------------------------------------------------------
-- 五、项目对码 ins_item / ins_item_vs
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【5.1】ins_item 字典表有数据',
       CASE WHEN to_regclass('insur.ins_item') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_item) > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_item') IS NULL THEN '❌ insur.ins_item 表不存在'
            ELSE format('ins_item 总记录数: %s（期望 >0，目录未导入会卡在打标阶段）',
                        (SELECT count(*) FROM insur.ins_item)) END
UNION ALL
SELECT '【5.2】ins_item_vs 当前机构有对码',
       CASE WHEN to_regclass('insur.ins_item_vs') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_item_vs WHERE org_id = :'v_org_id') > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_item_vs') IS NULL THEN '❌ 表不存在'
            ELSE format('当前机构对码记录数: %s（=0 则所有费用项目走自费）',
                        (SELECT count(*) FROM insur.ins_item_vs WHERE org_id = :'v_org_id')) END

-- ----------------------------------------------------------------------------
-- 六、国家统一编码
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【6.1】ins_item.country_unified_code 缺失统计',
       CASE WHEN to_regclass('insur.ins_item') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_item
                  WHERE COALESCE(country_unified_code, '') = '') = 0 THEN '✅'
            ELSE '⚠️' END,
       CASE WHEN to_regclass('insur.ins_item') IS NULL THEN '❌ 表不存在'
            ELSE format('缺国家码记录数: %s（>0 则预结算会报"缺少国家码"，参考部署清单第六章）',
                        (SELECT count(*) FROM insur.ins_item
                         WHERE COALESCE(country_unified_code, '') = '')) END

-- ----------------------------------------------------------------------------
-- 七、科室对照
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【7.1】ins_standard_dept_vs 国家版科别对照',
       CASE WHEN to_regclass('insur.ins_standard_dept_vs') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_standard_dept_vs WHERE org_id = :'v_org_id') > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_standard_dept_vs') IS NULL THEN '❌ 表不存在'
            ELSE format('当前机构国家版科室对照记录数: %s',
                        (SELECT count(*) FROM insur.ins_standard_dept_vs WHERE org_id = :'v_org_id')) END
UNION ALL
SELECT '【7.2】ins_standard_dept_vs_sh 五期版科别对照',
       CASE WHEN to_regclass('insur.ins_standard_dept_vs_sh') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_standard_dept_vs_sh WHERE org_id = :'v_org_id') > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('insur.ins_standard_dept_vs_sh') IS NULL THEN '❌ 表不存在'
            ELSE format('当前机构五期版科室对照记录数: %s',
                        (SELECT count(*) FROM insur.ins_standard_dept_vs_sh WHERE org_id = :'v_org_id')) END

-- ----------------------------------------------------------------------------
-- 八、医护人员编码（fee 域 qw_base.b_staff）
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【8.1】qw_base.b_staff (fee 域) 表存在',
       CASE WHEN to_regclass('qw_base.b_staff') IS NOT NULL THEN '✅' ELSE '⚠️' END,
       CASE WHEN to_regclass('qw_base.b_staff') IS NOT NULL THEN 'fee 域已同步 qw_base.b_staff'
            ELSE '⚠️ fee 域未同步 b_staff，PreSettle 等费用明细查询会失败（联系 HIS 实施补同步）' END
UNION ALL
SELECT '【8.2】医生缺 healthcare_code 人数',
       CASE WHEN to_regclass('qw_base.b_staff') IS NULL THEN '⚠️'
            WHEN (SELECT count(*) FROM qw_base.b_staff
                  WHERE COALESCE(prop, '') LIKE '%A%'
                    AND COALESCE(healthcare_code, '') = '') = 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('qw_base.b_staff') IS NULL THEN '⚠️ 跳过（表不存在）'
            ELSE format('缺医保编码的医生人数: %s（>0 则预结算会报"医护人员未对码"）',
                        (SELECT count(*) FROM qw_base.b_staff
                         WHERE COALESCE(prop, '') LIKE '%A%'
                           AND COALESCE(healthcare_code, '') = '')) END

-- ----------------------------------------------------------------------------
-- 九、疾病类型字典（按需）
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【9.1】ins_disease_type 字典数据（⚠️ 按需）',
       CASE WHEN to_regclass('insur.ins_disease_type') IS NULL THEN '❌'
            WHEN (SELECT count(*) FROM insur.ins_disease_type WHERE ins_id = :'v_national_ins_id') > 0 THEN '✅'
            ELSE '⚠️' END,
       CASE WHEN to_regclass('insur.ins_disease_type') IS NULL THEN '❌ 表不存在'
            ELSE format('国家通道疾病字典记录数: %s（=0 则慢病/特殊病登记接口无字典，按需补齐）',
                        (SELECT count(*) FROM insur.ins_disease_type WHERE ins_id = :'v_national_ins_id')) END

-- ----------------------------------------------------------------------------
-- 十、HIS 基础数据（qw_base.b_org、b_pt_type）
-- ----------------------------------------------------------------------------
UNION ALL
SELECT '【10.1】qw_base.b_org (fee 域) 表存在',
       CASE WHEN to_regclass('qw_base.b_org') IS NOT NULL THEN '✅' ELSE '⚠️' END,
       CASE WHEN to_regclass('qw_base.b_org') IS NOT NULL THEN 'fee 域已同步 qw_base.b_org'
            ELSE '⚠️ fee 域未同步 b_org，InitInsure 获取机构属性会失败（联系 HIS 实施补同步）' END
UNION ALL
SELECT '【10.2】b_org.property 非空（医疗机构属性）',
       CASE WHEN to_regclass('qw_base.b_org') IS NULL THEN '⚠️'
            WHEN (SELECT count(*) FROM qw_base.b_org
                  WHERE id = :'v_org_id' AND COALESCE(property, '') <> '') > 0 THEN '✅'
            ELSE '❌' END,
       CASE WHEN to_regclass('qw_base.b_org') IS NULL THEN '⚠️ 跳过（表不存在）'
            ELSE format('property = %s（参考部署清单 13.2）',
                        COALESCE((SELECT property FROM qw_base.b_org WHERE id = :'v_org_id' LIMIT 1), '(空)')) END
UNION ALL
SELECT '【10.3】qw_base.b_pt_type (fee 域) 表存在',
       CASE WHEN to_regclass('qw_base.b_pt_type') IS NOT NULL THEN '✅' ELSE '⚠️' END,
       CASE WHEN to_regclass('qw_base.b_pt_type') IS NOT NULL
            THEN format('fee 域已同步 b_pt_type，含医保类别记录数: %s',
                        (SELECT count(*) FROM qw_base.b_pt_type WHERE name LIKE '%医保%'))
            ELSE '⚠️ fee 域未同步 b_pt_type，DataHelper.GetPtTypeId 会失败（联系 HIS 实施）' END

;

\echo ''
\echo '================================================================'
\echo '医保插件部署自检 - 完成'
\echo '================================================================'
\echo '红色 ❌ 项必须在联调前修复，黄色 ⚠️ 项按业务场景酌情处理'
\echo '详细修复步骤请查阅: docs/医院部署前置配置清单.md'
\echo ''
