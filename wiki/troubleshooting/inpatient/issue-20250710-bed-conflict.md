# IS-20250710-BED-001 - 住院系统床位分配冲突问题

## 故障概述
- **故障编号**: IS-20250710-BED-001
- **发生时间**: 2025-07-10 14:30
- **发现时间**: 2025-07-10 14:35
- **解决时间**: 2025-07-10 16:45
- **影响范围**: 住院系统床位管理模块
- **影响用户**: 住院处工作人员、护士站
- **严重程度**: P2（影响部分业务）
- **优先级**: 高

## 现象描述

### 用户报告
1. **住院处报告**: 为患者A分配301病区01床位时，系统提示"床位已被占用"，但护士站系统显示该床位为空闲状态
2. **护士站报告**: 在床位管理界面看到301-01床位显示为"空闲"，但无法为患者B分配该床位
3. **系统监控**: 床位状态同步延迟报警，显示床位状态不一致超过5分钟

### 影响范围
- 3个病区（301、302、303）的床位分配功能受影响
- 约15名患者无法正常办理入院手续
- 护士站无法准确掌握床位使用情况

## 排查过程

### 第一阶段：信息收集（14:35-14:50）

#### 1. 查看系统监控
```bash
# 检查床位状态同步服务状态
$ kubectl get pods -n his-prod | grep bed-sync
bed-sync-deployment-7f8c6b9876-abc12   1/1     Running   0          3d
bed-sync-deployment-7f8c6b9876-def34   1/1     Running   0          3d

# 检查服务日志
$ kubectl logs -n his-prod bed-sync-deployment-7f8c6b9876-abc12 --tail=100
2025-07-10 14:30:01 INFO  BedSyncService - 开始同步床位状态
2025-07-10 14:30:01 ERROR BedSyncService - 同步301病区失败: Database connection timeout
2025-07-10 14:30:06 INFO  BedSyncService - 重试同步301病区
2025-07-10 14:30:06 ERROR BedSyncService - 同步301病区失败: Database connection timeout
```

#### 2. 收集错误日志
```sql
-- 查询床位状态异常记录
SELECT * FROM bed_status_exception 
WHERE occur_time >= '2025-07-10 14:30:00'
ORDER BY occur_time DESC
LIMIT 10;

-- 结果
bed_id    | expected_status | actual_status | occur_time          | exception_type
----------|-----------------|---------------|---------------------|---------------
301-01    | OCCUPIED        | AVAILABLE     | 2025-07-10 14:30:05 | STATUS_MISMATCH
301-02    | AVAILABLE       | OCCUPIED      | 2025-07-10 14:30:05 | STATUS_MISMATCH
302-05    | OCCUPIED        | AVAILABLE     | 2025-07-10 14:31:10 | STATUS_MISMATCH
```

#### 3. 检查数据库连接
```bash
# 检查MySQL主库状态
$ mysql -h mysql-master -u monitor -p -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';"
+-------------------+-------+
| Variable_name     | Value |
+-------------------+-------+
| Threads_connected | 215   |
+-------------------+-------+

# 检查连接数限制
$ mysql -h mysql-master -u monitor -p -e "SHOW VARIABLES LIKE 'max_connections';"
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| max_connections | 300   |
+-----------------+-------+
```

### 第二阶段：根因分析（14:50-15:30）

#### 1. 分析日志关键信息
通过分析日志发现：
- 14:30开始，床位状态同步服务频繁出现数据库连接超时
- 连接超时主要发生在301、302、303病区的床位数据同步
- 数据库连接数从正常的150激增到215，接近300的最大连接限制

#### 2. 定位问题代码
```java
// 问题代码：床位状态同步服务中的连接泄漏
public class BedStatusSyncService {
    
    @Scheduled(fixedRate = 5000)  // 每5秒执行一次
    public void syncBedStatus() {
        // 问题：每次执行都创建新连接，但没有正确关闭
        Connection conn = null;
        try {
            conn = dataSource.getConnection();  // 创建连接
            // 同步逻辑...
        } catch (SQLException e) {
            log.error("同步床位状态失败", e);
        }
        // 缺少 conn.close() 调用！
    }
}
```

#### 3. 验证假设
通过以下测试验证连接泄漏问题：
```bash
# 监控床位同步服务的连接数变化
$ watch -n 1 "mysql -h mysql-master -u monitor -p -e \
  'SELECT COUNT(*) FROM information_schema.processlist \
   WHERE db = \"his_inpatient\" AND command = \"Query\";'"

# 观察结果：每5秒增加2个连接（2个同步服务实例），但不减少
```

### 第三阶段：解决方案（15:30-16:45）

#### 1. 临时缓解措施（15:30-15:45）
```bash
# 步骤1：重启床位状态同步服务，释放泄漏的连接
$ kubectl rollout restart deployment/bed-sync-deployment -n his-prod

# 步骤2：临时增加数据库连接数上限
$ mysql -h mysql-master -u root -p -e "SET GLOBAL max_connections = 500;"

# 步骤3：手动同步受影响床位的状态
$ curl -X POST http://bed-sync-service:8080/api/v1/beds/sync/301
$ curl -X POST http://bed-sync-service:8080/api/v1/beds/sync/302
$ curl -X POST http://bed-sync-service:8080/api/v1/beds/sync/303

# 步骤4：验证床位状态已恢复正常
$ mysql -h mysql-master -u monitor -p -e "
  SELECT bed_id, status, last_update 
  FROM bed_status 
  WHERE ward_id IN ('301', '302', '303') 
  ORDER BY bed_id;"
```

#### 2. 永久修复方案（15:45-16:30）
```java
// 修复后的代码：使用try-with-resources确保连接关闭
public class BedStatusSyncService {
    
    @Scheduled(fixedRate = 5000)
    public void syncBedStatus() {
        // 使用try-with-resources自动关闭连接
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            
            // 同步逻辑...
            String sql = "SELECT * FROM bed_status WHERE last_update < DATE_SUB(NOW(), INTERVAL 5 SECOND)";
            ResultSet rs = stmt.executeQuery(sql);
            
            while (rs.next()) {
                // 处理每张床位...
            }
            
        } catch (SQLException e) {
            log.error("同步床位状态失败", e);
            // 添加重试逻辑
            retrySync();
        }
    }
    
    // 添加连接池监控
    @Scheduled(fixedRate = 60000)  // 每分钟检查一次
    public void monitorConnectionPool() {
        HikariDataSource hikariDataSource = (HikariDataSource) dataSource;
        log.info("连接池状态: 活跃={}, 空闲={}, 等待={}, 总数={}",
            hikariDataSource.getHikariPoolMXBean().getActiveConnections(),
            hikariDataSource.getHikariPoolMXBean().getIdleConnections(),
            hikariDataSource.getHikariPoolMXBean().getThreadsAwaitingConnection(),
            hikariDataSource.getHikariPoolMXBean().getTotalConnections());
    }
}
```

#### 3. 验证修复效果（16:30-16:45）
```bash
# 验证1：检查连接数是否稳定
$ mysql -h mysql-master -u monitor -p -e "
  SELECT 
    COUNT(*) as total_connections,
    COUNT(CASE WHEN db = 'his_inpatient' THEN 1 END) as inpatient_connections,
    COUNT(CASE WHEN command = 'Sleep' THEN 1 END) as sleep_connections
  FROM information_schema.processlist;"

# 验证2：监控床位同步服务日志
$ kubectl logs -n his-prod bed-sync-deployment-7f8c6b9876-abc12 --tail=50 --follow

# 验证3：模拟用户操作测试
$ curl -X POST http://admission-service:8080/api/v1/admission \
  -H "Content-Type: application/json" \
  -d '{"patientId": "TEST001", "wardId": "301", "bedId": "01"}'
```

## 根因分析

### 根本原因
1. **代码缺陷**: 床位状态同步服务中存在数据库连接泄漏，每次执行都创建新连接但未关闭
2. **资源管理不当**: 未使用连接池或未正确配置连接池参数
3. **监控缺失**: 缺乏对数据库连接数的实时监控和告警

### 根本原因链
```
代码缺陷（连接泄漏）
    ↓
数据库连接数持续增长
    ↓
达到最大连接数限制（300）
    ↓
新连接请求被拒绝或超时
    ↓
床位状态同步失败
    ↓
系统间状态不一致
    ↓
业务操作失败
```

### 相关因素
1. **高峰期压力**: 故障发生在下午入院高峰期，系统负载较高
2. **配置限制**: 数据库最大连接数配置较低（300）
3. **缺乏熔断**: 同步服务没有熔断机制，持续重试加剧问题

## 解决方案

### 临时措施
1. **重启服务**: 重启床位状态同步服务，释放泄漏的连接
2. **调整配置**: 临时增加数据库最大连接数到500
3. **手动同步**: 手动触发受影响病区的床位状态同步

### 永久修复
1. **代码修复**: 使用try-with-resources确保数据库连接正确关闭
2. **连接池优化**: 配置合理的连接池参数（最大连接数、超时时间等）
3. **监控增强**: 添加数据库连接数监控和告警
4. **熔断机制**: 为同步服务添加熔断器，避免级联故障

### 配置变更
```yaml
# application.yml 连接池配置
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      leak-detection-threshold: 60000  # 60秒泄漏检测
```

## 预防措施

### 1. 监控改进
- **新增监控项**: 数据库连接数、连接池状态、SQL执行时间
- **告警阈值**: 连接数超过80%时预警，超过90%时告警
- **监控面板**: 在Grafana中创建数据库连接监控专用面板

### 2. 代码审查
- **审查重点**: 所有数据库操作代码，确保资源正确释放
- **代码规范**: 强制使用try-with-resources处理数据库连接
- **静态分析**: 在CI/CD流水线中添加连接泄漏检测

### 3. 测试覆盖
- **单元测试**: 添加数据库连接管理的单元测试
- **集成测试**: 模拟高并发场景测试连接池表现
- **压力测试**: 定期进行数据库连接压力测试

### 4. 运维流程
- **变更管理**: 数据库配置变更需要经过评审和测试
- **容量规划**: 定期评估数据库连接需求，提前扩容
- **应急预案**: 完善数据库连接故障的应急预案

## 经验总结

### 技术层面
1. **资源管理**: 数据库连接是宝贵资源，必须谨慎管理
2. **连接池使用**: 始终使用连接池，并合理配置参数
3. **监控重要性**: 没有监控的系统就像盲人摸象，问题难以及时发现

### 流程层面
1. **代码审查**: 必须包含资源管理相关的审查项
2. **测试覆盖**: 高并发和异常场景的测试不可或缺
3. **告警响应**: 建立快速响应的告警处理流程

### 工具层面
1. **监控工具**: 完善APM和数据库监控工具链
2. **诊断工具**: 配备数据库连接分析工具
3. **部署工具**: 使用蓝绿部署减少故障影响

## 后续行动项

| 任务 | 负责人 | 截止日期 | 状态 |
|------|--------|----------|------|
| 修复所有数据库连接泄漏代码 | 张开发 | 2025-07-12 | 进行中 |
| 部署数据库连接监控告警 | 李运维 | 2025-07-11 | 已完成 |
| 更新数据库连接管理规范 | 王架构 | 2025-07-13 | 待开始 |
| 进行数据库连接压力测试 | 赵测试 | 2025-07-15 | 计划中 |
| 评审和更新应急预案 | 孙经理 | 2025-07-14 | 计划中 |

## 相关链接
- [住院子系统](/wiki/subsystems/inpatient/) `#subsystem` `#inpatient`
- [床位管理模块](/wiki/subsystems/inpatient/index.md#床位管理) `#bed` `#management`
- [数据库连接池配置规范](/wiki/patterns/pattern-database-connection.md) `#pattern` `#database` (待创建)

---

**故障处理人**: 王运维、张开发  
**报告时间**: 2025-07-10 17:00  
**审核状态**: `#reviewed` `#approved`  
**文档标签**: `#troubleshooting` `#bed` `#database` `#connection-leak` `#p2`