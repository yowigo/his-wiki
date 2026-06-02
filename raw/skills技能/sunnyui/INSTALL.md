# sunnyui skill 安装说明

本目录是团队共享的 `sunnyui` skill **源仓库**——同事拉取 his-wiki 后，需要手动拷贝到本机 `~/.claude/skills/sunnyui/`，Claude Code 才能识别并加载。

---

## 适用人群

团队成员中使用 Claude Code 编写 / 修改 SunnyUI WinForms 界面代码的同事。

## 安装步骤（首次）

1. **拉取 his-wiki**（如已拉过跳过）

   ```powershell
   git clone <his-wiki 仓库地址> C:\Users\<你的用户名>\Desktop\his-wiki
   ```

2. **确认本机有 ~/.claude/skills/ 目录**

   Windows 默认路径：`C:\Users\<你的用户名>\.claude\skills\`

   不存在则手动创建。

3. **拷贝 skill 目录**

   把 `his-wiki/raw/skills技能/sunnyui/` 整个目录拷贝到 `~/.claude/skills/sunnyui/`，即：

   - 源：`C:\Users\<你的用户名>\Desktop\his-wiki\raw\skills技能\sunnyui\`
   - 目标：`C:\Users\<你的用户名>\.claude\skills\sunnyui\`

   拷贝后 `~/.claude/skills/sunnyui/` 下应该有 `SKILL.md` 和 `INSTALL.md`。

4. **验证安装**

   重启 Claude Code 会话（或新开一个），在 Claude Code 里输入 `/sunnyui` 应该能列出 skill；
   或让 AI 写一个 SunnyUI 窗体，看它是否会主动走 Step 0 → Step 8 检查。

## 升级步骤（当 his-wiki 仓库里 skill 有更新）

1. 在 his-wiki 目录 `git pull`
2. 重新拷贝 `his-wiki/raw/skills技能/sunnyui/` 到 `~/.claude/skills/sunnyui/`，**覆盖**
3. 重启 Claude Code 会话

## 维护规则

| 行为 | 允许？ | 备注 |
| --- | --- | --- |
| 修改 `his-wiki/raw/skills技能/sunnyui/SKILL.md` | ✅ 由 Keiskei 统一维护，团队成员提建议 | 走 his-wiki git 流程 |
| 直接修改本机 `~/.claude/skills/sunnyui/SKILL.md` | ❌ | 修改不会同步到团队，且会被下次升级覆盖 |
| 同事新增自己专用的 skill | ✅ | 放到自己的 `~/.claude/skills/<自定义名>/`，**不放到** his-wiki/raw/skills技能/ |
| 提议把 skill 改动合并到团队版 | ✅ | 在 his-wiki 提 issue 或直接告诉 Keiskei |

## 同步状态判断

判断本机 skill 是否落后于团队版：

```powershell
# 比对两份 SKILL.md
fc /b "C:\Users\<用户名>\.claude\skills\sunnyui\SKILL.md" `
     "C:\Users\<用户名>\Desktop\his-wiki\raw\skills技能\sunnyui\SKILL.md"
```

输出 "FC: 找不到差异" = 已同步；有差异 = 需要重新拷贝。

---

## FAQ

**Q：为什么不直接做符号链接（symlink）让 ~/.claude/skills/sunnyui/ 指向 his-wiki/raw/skills技能/sunnyui/？**

A：Windows 下创建 symlink 需要管理员权限，且部分公司机器禁用；按"拷贝 + 手动升级"的方式最普适。若你自己机器允许 symlink，自行操作即可。

**Q：Claude Code 不在 Windows 上（比如 Mac/Linux 同事），路径怎么调？**

A：把 `C:\Users\<用户名>\` 换成 `~`：源 `~/Desktop/his-wiki/raw/skills技能/sunnyui/`，目标 `~/.claude/skills/sunnyui/`。

**Q：我们想给同事自动化同步，该怎么做？**

A：可以后续在 his-wiki 根目录加一个 `sync-skills.ps1` 脚本（一键拷贝所有团队 skill）。目前先手动拷贝。

**Q：skill 不生效，AI 还是凭脑补写代码？**

A：排查清单：

1. `~/.claude/skills/sunnyui/SKILL.md` 真实存在且有内容
2. SKILL.md 顶部 frontmatter 完整（`name` / `description`）
3. 重启 Claude Code 会话（skill 加载在会话启动时）
4. 用户消息中是否含触发关键词（见 SKILL.md frontmatter description）
5. 如仍不生效，主动 `/sunnyui` 强制调用

---

**维护者**：Keiskei
**首次发布**：2026-05-21
