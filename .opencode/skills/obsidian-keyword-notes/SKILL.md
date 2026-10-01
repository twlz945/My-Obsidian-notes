---
name: Obsidian Keyword Notes
description: 根据一个或多个关键词在 Obsidian 库中自动生成结构化笔记。先扫描库内相关笔记，再规划标题、目录、标签和双链，最后写入带 YAML 属性的富笔记。Use when asked to create, write, or batch-generate Obsidian notes from keywords, topics, or a topic list, when notes should link to related vault notes, or when synthesizing vault content into a new note.
---

# Obsidian 关键词笔记

根据关键词在 Obsidian 库中自动生成笔记：扫描库、规划、写入、建链。

## 适用场景

- 用户给出一组关键词/主题，要求"生成笔记""写笔记""建个笔记"。
- 需要自动决定标题、归档目录、标签。
- 需要链接到库中已有笔记，或把已有内容归纳成新笔记。
- 批量：一次给出多个关键词，生成多篇或合并成一篇。

## 一、确定库路径

1. 用户明确指定了库路径 → 用该路径。
2. 未指定 → 默认库为 `C:\Users\twlz9\Documents\Obsidian Vault`。
3. 用 `Test-Path "<vault>\.obsidian"` 校验；不是库就停下来问用户，不要猜。
4. 库路径在后续所有脚本调用中通过 `-Vault` 传入。

## 二、确定内容来源模式

| 模式 | 含义 |
| ---- | ---- |
| `both` | 默认。先复用/归纳库内已有内容并建链，缺口用模型知识或网络搜索补齐。 |
| `scratch` | 完全新写，只按标题匹配建立双链。 |
| `synthesize` | 只整合库内已有内容，不引入外部知识。 |

选择规则：

- 用户明确指定则遵从。
- 否则用 `both`。
- 若扫描发现同一关键词已有多篇高相关笔记，改用 `synthesize` 并在交付说明里说明原因。

## 三、工作流

1. **收集输入**：关键词列表 + 可选约束（目标目录、标签、语言、单篇/多篇、是否允许联网）。
2. **扫描库**：运行 `scripts/vault-scan.ps1`，拿到相关笔记、目录列表、已有标签。若一次生成多篇，可一次传入全部关键词。
3. **规划**：为每篇确定标题、库内相对路径、标签、别名、要建立的双链，并用一句话概述内容。同时检查是否已存在同名或高度重叠的笔记。
4. **确认**（满足任一条件时，先向用户展示规划再动手）：
   - 一次要新建 4 篇及以上；
   - 需要新建目录；
   - 发现同名笔记或高度重叠笔记；
   - 用户没有说明意图，而模式选择会影响结果。
   否则直接执行，交付时说明即可。
5. **生成内容**：先读 `references/note-format.md`，按其中的富笔记模板与属性/标签/链接规则撰写。
6. **写入**：把内容写到临时文件，再用 `scripts/new-note.ps1 -ContentFile` 写入库内，绝不直接覆盖已有文件。
7. **交付**：列出新建文件路径、归档位置、标签、建立的双链；`synthesize`/`both` 模式说明哪些内容来自库内、哪些是新补充。

## 四、命名与归档规则

- 标题：用关键词的自然语言标题。中文关键词用中文标题；英文关键词保留英文。避免 `未命名`。
- 单关键词 → 一篇；多关键词默认每个一篇。若关键词属于同一主题且用户未要求拆分，可合并成一篇并说明。
- 目录：按 `references/vault-conventions.md` 的路由表选择，**优先复用已有目录，不新建顶层目录**。
- 文件名去掉 `\ / : * ? " < > |` 等非法字符，长度适中。
- 日期型日志按 `2026/MM/DD.md` 归档。

## 五、标签与双链

- 标签优先复用 `vault-scan.ps1` 返回的既有标签，保持中英一致；每篇 1–3 个。
- 正文中首次提到某个已存在的库内笔记时建立 `[[笔记名]]` 或 `[[笔记名|显示文字]]`。
- YAML 中的 wikilink 值必须加引号：`related: ["[[X]]"]`。
- **只链接到扫描结果确认存在的笔记**，不要凭记忆创建链接。有意留占位链接时在交付说明中标注。

## 六、写入安全

- 绝不覆盖已有文件；`new-note.ps1` 默认拒绝写入已存在路径并返回 `reason: "exists"`。
- 需要覆盖时必须先获得用户明确同意，再加 `-Force`。
- 只写入库内路径；不得写入 `.obsidian`、`.trash`、`.claudian`、`.opencode`、`copilot`。
- 统一 UTF-8 无 BOM，避免中文乱码。

## 七、脚本调用

Windows PowerShell 默认禁用脚本执行，必须用下面的方式调用（注意 `-ExecutionPolicy Bypass` 和 `-File`）。下面的 `<skill>` 指技能加载时给出的基目录，调用时替换为该目录的绝对路径，例如 `C:\Users\twlz9\Documents\AI\skills\obsidian-keyword-notes`。

**扫描（只读）**——关键词用逗号分隔的单个字符串传入：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>\scripts\vault-scan.ps1" -Vault "C:\Users\twlz9\Documents\Obsidian Vault" -Keywords "依赖注入,IoC,控制反转" -Limit 20
```

返回 JSON：`ok`、`matches[]`（`path`/`title`/`folder`/`score`/`hits`/`excerpt`）、`folders[]`、`tags[]`、`noteCount`。先判断 `ok` 再使用其它字段。

**新建（防覆盖）**——正文较复杂时先写临时文件，再传 `-ContentFile`：

```powershell
# 先把正文写入临时文件（UTF-8 无 BOM），例如 $env:TEMP\note_body.md
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>\scripts\new-note.ps1" -Vault "<vault>" -Path "知识积累\编程\主题.md" -ContentFile "$env:TEMP\note_body.md"
```

返回 JSON：`ok:true` 表示成功；`ok:false` + `reason:"exists"`（退出码 2）表示目标已存在，需改路径或征得用户同意后加 `-Force`；退出码 3 表示路径非法（绝对路径、`..`、库外路径、缺内容）。可先用 `-DryRun` 只校验不写入。

**注意**：不要把脚本输出再管道给 `Out-String`，会破坏中文编码；直接读原始输出即可。

## 八、不要做的事

- 不要不扫描就直接编造库内链接。
- 不要每次新建顶层目录。
- 不要覆盖同名笔记。
- 不要把纯外部知识伪装成库内既有内容。
- 不要在关键词没有实际含义时硬造笔记；信息不足时先问用户。
