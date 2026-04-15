# 原始资料层说明

## 目录概述
原始资料层（raw/）是HIS知识库的原材料仓库，存放所有未经加工的原始文档、参考资料、标准规范等。这一层的内容通常比较杂乱，需要经过知识工程师的整理和提炼后才能进入wiki层。

## 目录结构

```
raw/
├── standards/              # 标准规范
│   ├── hl7/               # HL7相关标准
│   ├── ihe/               # IHE技术框架
│   ├── gb/                # 国家标准
│   └── industry/          # 行业标准
├── references/            # 参考资料
│   ├── books/             # 书籍资料
│   ├── papers/            # 学术论文
│   ├── reports/           # 研究报告
│   └── presentations/     # 演示文稿
├── specifications/        # 需求规格
│   ├── business/          # 业务需求
│   ├── functional/        # 功能需求
│   ├── technical/         # 技术需求
│   └── interface/         # 接口需求
├── designs/               # 设计文档
│   ├── architecture/      # 架构设计
│   ├── database/          # 数据库设计
│   ├── interface/         # 接口设计
│   └── ui-ux/             # 界面设计
├── implementations/       # 实现文档
│   ├── source-code/       # 源代码
│   ├── configurations/    # 配置文件
│   ├── scripts/           # 脚本文件
│   └── deployments/       # 部署文档
├── tests/                 # 测试相关
│   ├── test-cases/        # 测试用例
│   ├── test-reports/      # 测试报告
│   ├── bug-reports/       # 缺陷报告
│   └── performance/       # 性能测试
├── operations/            # 运维相关
│   ├── manuals/           # 操作手册
│   ├── procedures/        # 操作流程
│   ├── logs/              # 系统日志
│   └── incidents/         # 事件记录
└── archives/              # 归档资料
    ├── versions/          # 历史版本
    ├── deprecated/        # 废弃资料
    └── backups/           # 备份文件
```

## 文件命名规范

### 基本规则
1. **小写字母**: 全部使用小写字母
2. **连字符分隔**: 使用连字符（-）分隔单词
3. **日期前缀**: 重要文档使用YYYYMMDD日期前缀
4. **版本后缀**: 有版本的文件添加-v1.0.0后缀

### 命名示例
```
# 标准文档
20250710-hl7-v2.5.1-standard.pdf
gb-t-12345-2020-medical-information-standard.pdf

# 需求文档
business-requirement-inpatient-admission.md
functional-spec-bed-management-v1.2.0.docx

# 设计文档
architecture-design-his-system-v3.0.pdf
database-schema-inpatient-module.sql

# 测试文档
test-case-bed-allocation-20250710.xlsx
performance-test-report-q2-2025.pdf
```

## 文件格式要求

### 支持的文件格式
| 类别 | 推荐格式 | 可选格式 | 不推荐格式 |
|------|----------|----------|------------|
| 文档 | Markdown (.md) | PDF, DOCX | PPT, XLS |
| 代码 | 源代码文件 | 压缩包 | 二进制 |
| 数据 | CSV, JSON | XML, YAML | 专有格式 |
| 图像 | PNG, SVG | JPG, GIF | BMP, TIFF |
| 演示 | PDF | PPTX | KEY, ODP |

### 格式转换要求
1. **Office文档**: 尽量转换为PDF或Markdown格式
2. **扫描文档**: 进行OCR识别，保存文本和原图
3. **专有格式**: 尽量转换为开放格式
4. **大文件**: 超过100MB的文件需要特殊说明

## 入库流程

### 1. 收集阶段
```
原始资料 → 初步分类 → 格式检查 → 去重处理 → 临时存储
```

### 2. 整理阶段
```
临时存储 → 规范命名 → 补充元数据 → 质量检查 → 正式入库
```

### 3. 元数据要求
每个文件应包含以下元数据（在README.md或metadata.json中）：
```yaml
title: "文档标题"
description: "文档描述"
author: "作者/来源"
date: "创建日期"
version: "版本号"
keywords: ["关键词1", "关键词2"]
category: "分类"
status: "状态"  # draft/reviewed/approved/deprecated
related_files: ["相关文件路径"]
```

## 质量要求

### 内容质量
1. **完整性**: 文档内容完整，无缺失章节
2. **准确性**: 技术细节准确，数据真实可靠
3. **时效性**: 标注有效期限，定期更新
4. **权威性**: 注明来源，确保权威可信

### 格式质量
1. **可读性**: 格式规范，便于阅读
2. **可检索**: 包含关键词，便于搜索
3. **可维护**: 结构清晰，便于更新
4. **兼容性**: 使用通用格式，便于工具处理

## 维护管理

### 定期检查
| 检查项 | 频率 | 检查内容 |
|--------|------|----------|
| 链接有效性 | 每月 | 检查外部链接是否有效 |
| 格式兼容性 | 每季度 | 检查文件格式是否过时 |
| 内容时效性 | 每半年 | 检查内容是否需要更新 |
| 存储完整性 | 每年 | 检查文件是否损坏 |

### 清理策略
1. **临时文件**: 超过30天未处理的临时文件自动清理
2. **重复文件**: 定期检查并删除重复内容
3. **过时文件**: 标记为deprecated，1年后归档
4. **损坏文件**: 无法修复的损坏文件移至隔离区

## 安全要求

### 访问控制
1. **分级权限**: 根据文档敏感程度设置访问权限
2. **操作日志**: 记录所有文件的访问和修改记录
3. **版本控制**: 重要文档使用Git进行版本管理
4. **备份策略**: 定期备份，异地容灾

### 敏感信息处理
1. **脱敏处理**: 个人隐私、商业机密等敏感信息必须脱敏
2. **加密存储**: 高度敏感文档需要加密存储
3. **访问审批**: 敏感文档访问需要审批流程
4. **水印保护**: 重要文档添加数字水印

## 工具支持

### 推荐工具
| 任务 | 推荐工具 | 用途 |
|------|----------|------|
| 文档转换 | Pandoc | 格式转换 |
| 文本提取 | Tika | 从各种格式提取文本 |
| OCR识别 | Tesseract | 图像文字识别 |
| 文件管理 | rclone | 云存储同步 |
| 版本控制 | Git LFS | 大文件版本管理 |

### 自动化脚本
```bash
#!/bin/bash
# 原始资料入库自动化脚本

# 1. 检查文件格式
check_format() {
    file="$1"
    extension="${file##*.}"
    
    case "$extension" in
        pdf|md|docx|txt|csv|json|sql|py|java)
            return 0
            ;;
        *)
            echo "不支持的格式: $file"
            return 1
            ;;
    esac
}

# 2. 生成元数据
generate_metadata() {
    file="$1"
    metadata_file="${file%.*}.metadata.json"
    
    cat > "$metadata_file" << EOF
{
  "filename": "$(basename "$file")",
  "path": "$(dirname "$file")",
  "size": $(stat -c%s "$file"),
  "modified": "$(date -r "$file" "+%Y-%m-%d %H:%M:%S")",
  "md5": "$(md5sum "$file" | cut -d' ' -f1)",
  "imported": "$(date "+%Y-%m-%d %H:%M:%S")"
}
EOF
}

# 3. 主处理流程
process_file() {
    file="$1"
    
    if check_format "$file"; then
        echo "处理文件: $file"
        generate_metadata "$file"
        # 更多处理逻辑...
    fi
}

# 遍历处理所有文件
find ./raw -type f -name "*" | while read file; do
    process_file "$file"
done
```

## 相关链接
- [知识库索引](/wiki/index.md) - 返回知识库主页
- [模式定义](/schema/CLAUDE.md) - 查看文档规范
- [操作日志](/wiki/log.md) - 查看入库记录

---

**维护团队**: 知识工程部  
**创建时间**: 2025-04-15  
**最后更新**: 2025-04-15  
**版本**: 1.0.0  

> 注意：原始资料层是知识生产的源头，请确保所有资料的准确性和完整性。