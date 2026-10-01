---
name: Obsidian Note Organizer
description: 整理 Obsidian 库中已有笔记：审计元数据与标签、目录归档、去重合并、链接与索引、格式清理。默认先做只读审计并给出变更计划，经用户确认后再执行；移动或重命名笔记时会同步更新库内双链。Use when asked to clean up, reorganize, tidy, deduplicate, tag, fix links in, merge, rename, or restructure existing Obsidian notes.
---

# Obsidian 笔记整理

对**已有**笔记做审计与整理。核心原则：**先报告、后执行；未获确认不改动任何文件。**

## 适用场景

- 「整理一下我的 Obsidian 库」「把笔记归类」「清理未命名笔记」
- 「统一标签 / 补 frontmatter」「找出重复笔记并合并」
- 「修复失效双链」「给某个目录建索引页（MOC）」
- 「统一 Markdown 格式」

新建笔记请用 `obsidian-keyword-notes` 技能，本技能只管已有笔记。

## 一、确定库路径

默认库：`C:\Users\twlz9\Documents\Obsidian Vault`。
用 `Test-Path "<vault>\.obsidian"` 校验，不是库就问用户。所有脚本通过 `-Vault` 传入。

## 二、工作流（默认：审计 → 计划 → 确认 → 执行 → 复核）

1. **审计**：运行 `scripts/vault-audit.ps1`，得到只读 JSON（五类问题）。
2. **报告**：按 `references/report-format.md` 的格式汇总给用户，并给出**变更计划**：每项 = 目标文件 / 问题 / 建议动作 / 风险等级。
3. **确认**：让用户批准。用户可整体批准，也可只批准某些类别或条目。**只执行被批准的部分。**
4. **执行**（按 `references/organization-rules.md` 的标准）：
   - 内容 / 属性 / 标签 / 格式：用 `edit` 工具做定点修改；只有需要整体重写时才用 `write`。
   - 移动 / 重命名：优先用 Obsidian CLI（若可用，先 `obsidian help move`、`obsidian help rename` 确认语法，不要猜）；CLI 不可用时用 `scripts/move-note.ps1`，它会同步改写库内双链。
   - 去重 / 合并：以内容最全的一篇为主，把另一篇的可合并内容并入，**不丢信息**；另一篇的去留必须由用户明确（保留为存根 / 移入回收站 / 删除）。
   - 索引 / MOC：新建 `index.md` 或 `<文件夹名>目录.md`，用 wikilink 列出目录内笔记，并加 frontmatter。
5. **复核**：再次运行 `vault-audit.ps1`，对比问题数量是否下降、是否引入新问题（尤其失效双链）。
6. **交付**：列出每一处改动的文件与动作；说明哪些已做、哪些按用户要求跳过。

如果用户明确说「只给报告，不要改」，就停在步骤 2。若用户说「不用确认，直接整理」，也要在执行前列出将改动的文件清单，且仍不得删除文件。

## 三、五类整理任务

详细判定标准见 `references/organization-rules.md`，要点：

| 类别 | 典型动作 | 风险 |
| ---- | -------- | ---- |
| 元数据与标签 | 补 frontmatter、统一/合并标签、规范 aliases | 低 |
| 目录归档 | 移动错放笔记、重命名「未命名」、填充空笔记 | 中 |
| 去重与合并 | 合并同题/高度重叠笔记 | 高 |
| 链接与索引 | 修复失效双链、处理孤儿笔记、建 MOC | 中 |
| 格式清理 | 统一标题层级、空行、代码块、结尾换行 | 低 |

**风险越高，越要逐项确认。** 合并与删除必须逐项确认。

## 四、脚本调用

Windows PowerShell 默认禁用脚本，必须这样调用。`<skill>` 为技能基目录的绝对路径（加载技能时会给出）：

**审计（只读）**：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>\scripts\vault-audit.ps1" -Vault "C:\Users\twlz9\Documents\Obsidian Vault"
```

可选 `-Scope metadata,filing,duplicates,links,format`（逗号分隔）只看某几类；`-StubThreshold 40`、`-MinFolderNotes 3`、`-MaxItems 200` 控制阈值与列表上限。返回 JSON 的 `noteCount`、`brokenCount`、`orphanCount`、各类列表；列表可能被截断，但计数是完整的。

**移动 / 重命名（含链接更新）**：

```powershell
# 先 -DryRun 预览会移动什么、会改哪些链接
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>\scripts\move-note.ps1" -Vault "<vault>" -From "杂记\未命名.md" -To "杂记\日记\2026-10-01.md" -DryRun
```

去掉 `-DryRun` 才实际执行；`-SkipLinkUpdate` 可关闭链接改写（一般不要用）；目标已存在时返回 `reason:"exists"`（退出码 2）。

脚本输出是 UTF-8 JSON，直接读取，**不要管道给 `Out-String`**（会破坏中文编码）。

## 五、安全规则

- 未获用户确认前，**不写、不移动、不删除**任何文件。
- **不删除文件**。需要删除时，优先移动到 `.trash`（Obsidian 回收站），并逐项说明。
- 不修改 `.obsidian`、`.git`、`.claudian`、`.opencode`、`.agents`、`copilot`、插件与技能目录。
- 移动/重命名后必须同步双链：用 `move-note.ps1` 的默认行为，或 Obsidian CLI 的链接感知移动。
- frontmatter 修改保留未知键与原有风格，不擅自重排。
- 合并时保留全部有效信息，宁可冗余也不丢失；对不确定的旧内容加 `> [!warning] 待确认`。
- 批量改动前提醒用户可通过 Obsidian 的本地历史/版本控制回滚。

## 六、不要做的事

- 不要没审计就动手。
- 不要批量删除、清空或大段重写用户内容。
- 不要为了「整齐」擅自合并，合并必须逐项批准。
- 不要把失效链接直接删掉——先尝试指向已有笔记或创建目标，删链需明确同意。
- 不要忽略风险分级，高风险项必须逐项确认。
