# his-wiki skill 安装说明

本目录是团队共享的 `his-wiki` skill **源仓库**——同事拉取 his-wiki 后，需要手动拷贝到本机 `~/.claude/skills/his-wiki/`，Claude Code 才能识别并加载。

---

## 适用人群

团队成员中使用 Claude Code 做以下任一类工作的同事：

- 开发 HIS 外部接口插件（`Plugins.EB_*`、上海药事平台 / 北京医保 / 苏州医保等）
- 开发 HIS 5.x 后端业务（门诊 / 住院 / 收费 / 检验 / 药品 / 患者）
- 开发 SunnyUI WinForms 界面（同步配套 `sunnyui` skill 一起装效果更好）
- 调试 HIS / 医保线上故障

## 适用场景

Claude Code 会话中输入 `/his-wiki <query>` 时，skill 自动接管查询流程：

- `/his-wiki 配送点档案对接` → 命中 wiki/api/third-party-integration 等
- `/his-wiki drug.category 字典含义` → 提醒不能凭计数推断，去 schema/ 拿真实定义
- `/his-wiki YY009 报文字段` → 命中 plugin-development + 医保插件模板
- `/his-wiki SunnyUI 多行 textbox 滚动条` → 命中 winforms-ui/sunnyui/控件
- `/his-wiki 9000 签名超时` → 命中 troubleshooting/medical-insurance

---

## 安装步骤（首次）

1. **拉取 his-wiki**（如已拉过跳过）

   ```powershell
   git clone <his-wiki 仓库地址> C:\Users\<你的用户名>\Desktop\his-wiki
   ```

2. **确认本机有 ~/.claude/skills/ 目录**

   Windows 默认路径：`C:\Users\<你的用户名>\.claude\skills\`

   不存在则手动创建。

3. **拷贝 skill 目录**

   把 `his-wiki/raw/skills技能/his-wiki/` 整个目录拷贝到 `~/.claude/skills/his-wiki/`，即：

   - 源：`C:\Users\<你的用户名>\Desktop\his-wiki\raw\skills技能\his-wiki\`
   - 目标：`C:\Users\<你的用户名>\.claude\skills\his-wiki\`

   拷贝后 `~/.claude/skills/his-wiki/` 下应该有 `SKILL.md` 和 `INSTALL.md`。

4. **确认 his-wiki 知识库路径与 skill 默认值一致**

   SKILL.md 内**硬编码**了知识库根目录为 `C:\Users\xuyilai\Desktop\his-wiki\`。如果你的 his-wiki 不在 `Desktop/`，需要打开 `~/.claude/skills/his-wiki/SKILL.md` 把 10 个分诊路径里出现的根路径全局替换为你的真实路径。

5. **验证安装**

   重启 Claude Code 会话（或新开一个），输入 `/his-wiki 配送点档案` 应该能列出命中文档；或在 `/help` 里看到 `his-wiki` 出现在 skill 列表。

## 升级步骤（当 his-wiki 仓库里 skill 有更新）

1. 在 his-wiki 目录 `git pull`
2. 重新拷贝 `his-wiki/raw/skills技能/his-wiki/` 到 `~/.claude/skills/his-wiki/`，**覆盖**
3. 重启 Claude Code 会话

## 维护规则

| 行为 | 允许？ | 备注 |
| --- | --- | --- |
| 修改 `his-wiki/raw/skills技能/his-wiki/SKILL.md` | ✅ 由 Keiskei 统一维护，团队成员提建议 | 走 his-wiki git 流程 |
| 直接修改本机 `~/.claude/skills/his-wiki/SKILL.md` | ❌ | 修改不会同步到团队，且会被下次升级覆盖 |
| 团队成员新增分诊路径（如发现某类查询走偏） | ✅ | 提 issue 或告诉 Keiskei，由维护者编辑后统一发布 |
| 同事新增自己专用的 skill | ✅ | 放到自己的 `~/.claude/skills/<自定义名>/`，**不放到** his-wiki/raw/skills技能/ |

## 同步状态判断

判断本机 skill 是否落后于团队版：

```powershell
# 比对两份 SKILL.md
fc /b "C:\Users\<用户名>\.claude\skills\his-wiki\SKILL.md" `
     "C:\Users\<用户名>\Desktop\his-wiki\raw\skills技能\his-wiki\SKILL.md"
```

输出 "FC: 找不到差异" = 已同步；有差异 = 需要重新拷贝。

---

## FAQ

**Q：skill 装好了但 `/his-wiki` 不识别？**

A：排查清单：
1. `~/.claude/skills/his-wiki/SKILL.md` 真实存在且有内容
2. SKILL.md 顶部 frontmatter 完整（`name: his-wiki` / `description`）
3. 重启 Claude Code 会话（skill 加载在会话启动时）
4. 在 `/help` 列表里搜索 his-wiki 是否出现；没出现说明扫描失败
5. 如仍不生效，主动 `/his-wiki <query>` 强制调用看是否报错

**Q：skill 触发后没去查知识库、还是凭脑补回答？**

A：当前 skill 设计只在用户**显式** `/his-wiki` 调用时生效，不嗅探信号词自动接管。如果不输 `/his-wiki`，AI 会按主代理常规流程回答（可能凭印象、可能 Read 知识库——但**不保证**走 his-wiki 路径）。如需自动接管，向 Keiskei 提议改成 A+C 双入口（参考 SKILL.md 顶部 frontmatter）。

**Q：知识库路径不是 `C:\Users\xuyilai\Desktop\his-wiki\` 怎么办？**

A：见上方"安装步骤 4"——手动把 SKILL.md 里 10 个分诊路径的根路径全局替换为你的真实路径。未来若需要支持动态路径，会在 SKILL.md 里改成从环境变量 `HIS_WIKI_ROOT` 读取。

**Q：为什么这个 skill 不能写入 his-wiki？**

A：本 skill 是**消费侧**——只读 + 路由查询，不维护知识库内容本身。维护知识库（新增文档、整理资料）是 Keiskei 的工作流，单独走 git。让 skill 既读又写会让"知识库一致性"和"AI 即兴判断"耦合，风险大。

**Q：跟 `sunnyui` skill 有重叠吗？**

A：有，但角色不同：
- `sunnyui` 是 **行为护栏**——AI 写 SunnyUI 代码时强制 Step 0-8 检查表 + 反问清单（不让 AI 凭印象写）
- `his-wiki` 是 **知识库总管家**——AI 查 his-wiki 的任何内容（包括 SunnyUI 文档）时统一的路由入口

两者并存，触发场景不冲突：写 SunnyUI 代码 → `sunnyui` 起作用；查 SunnyUI 文档 → `/his-wiki SunnyUI <topic>`。

**Q：Mac/Linux 同事路径怎么调？**

A：把 `C:\Users\<用户名>\` 换成 `~`：源 `~/Desktop/his-wiki/raw/skills技能/his-wiki/`，目标 `~/.claude/skills/his-wiki/`。SKILL.md 内 10 个分诊路径里的 Windows 风格根路径也需要替换。

**Q：能否做成自动同步脚本？**

A：可以后续在 his-wiki 根目录加 `sync-skills.ps1`（一键拷贝所有团队 skill：sunnyui + his-wiki + ...）。目前先手动拷贝。

---

**维护者**：Keiskei
**首次发布**：2026-05-21
