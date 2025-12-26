# 升级指南

> 你已经安装了Spec Kit，想要升级到最新版本以获取新功能、错误修复或更新的斜杠命令。本指南涵盖CLI工具和项目文件的升级。

---

## 快速参考

| 升级内容 | 命令 | 使用时机 |
|----------------|---------|-------------|
| **仅CLI工具** | `uv tool install specify-cli --force --from git+https://github.com/lordking/spec-kit-zh.git` | 获取最新CLI功能而不触及项目文件 |
| **项目文件** | `specify init --here --force --ai <your-agent>` | 更新斜杠命令、模板和脚本 |
| **两者** | 运行CLI升级，然后项目更新 | 建议用于主要版本升级 |

---

## 第一部分：升级CLI工具

CLI工具（`specify`）与你的项目文件是分开的。升级它以获取最新功能和错误修复。

### 如果你使用`uv tool install`安装的

```bash
uv tool install specify-cli --force --from git+https://github.com/lordking/spec-kit-zh.git
```

### 如果你使用一次性`uvx`命令

无需升级——`uvx`总是获取最新版本。只需正常运行你的命令：

```bash
uvx --from git+https://github.com/lordking/spec-kit-zh.git specify init --here --ai copilot
```

### 验证升级

```bash
specify check
```

这显示已安装的工具并确认CLI正常工作。

---

## 第二部分：更新项目文件

当Spec Kit发布新功能（如新斜杠命令或更新的模板）时，你需要刷新项目的Spec Kit文件。

### 更新内容

运行`specify init --here --force`将更新：

- ✅ **斜杠命令文件**（`.claude/commands/`、`.github/prompts/`等）
- ✅ **脚本文件**（`.specify/scripts/`）
- ✅ **模板文件**（`.specify/templates/`）
- ✅ **共享记忆文件**（`.specify/memory/`）- **⚠️ 参见下面的警告**

### 升级安全

这些文件**永远不会被**升级触及——模板包甚至不包含它们：

- ✅ **你的规格**（`specs/001-my-feature/spec.md`等）- **已确认安全**
- ✅ **你的实施计划**（`specs/001-my-feature/plan.md`、`tasks.md`等）- **已确认安全**
- ✅ **你的源代码** - **已确认安全**
- ✅ **你的git历史** - **已确认安全**

`specs/`目录完全排除在模板包之外，在升级过程中永远不会被修改。

### 更新命令

在项目目录内运行此命令：

```bash
specify init --here --force --ai <your-agent>
```

将`<your-agent>`替换为你的AI助手。参考[支持的AI助手](../README.md#-supported-ai-agents)列表

**示例：**

```bash
specify init --here --force --ai copilot
```

### 理解`--force`标志

没有`--force`，CLI会警告你并要求确认：

```text
Warning: Current directory is not empty (25 items)
Template files will be merged with existing content and may overwrite existing files
Proceed? [y/N]
```

使用`--force`，它会跳过确认并立即继续。

**重要：你的`specs/`目录总是安全的。** `--force`标志只影响模板文件（命令、脚本、模板、记忆）。你在`specs/`中的功能规格、计划和任务永远不会包含在升级包中，不能被覆盖。

---

## ⚠️ 重要警告

### 1. 宪章文件将被覆盖

**已知问题：** `specify init --here --force`当前会覆盖`.specify/memory/constitution.md`与默认模板，擦除你所做的任何自定义。

**解决方法：**

```bash
# 1. 升级前备份你的宪章
cp .specify/memory/constitution.md .specify/memory/constitution-backup.md

# 2. 运行升级
specify init --here --force --ai copilot

# 3. 恢复你自定义的宪章
mv .specify/memory/constitution-backup.md .specify/memory/constitution.md
```

或使用git恢复它：

```bash
# 升级后，从git历史恢复
git restore .specify/memory/constitution.md
```

### 2. 自定义模板修改

如果你自定义了`.specify/templates/`中的任何模板，升级会覆盖它们。首先备份：

```bash
# 备份自定义模板
cp -r .specify/templates .specify/templates-backup

# 升级后，手动合并你的更改
```

### 3. 重复斜杠命令（基于IDE的助手）

一些基于IDE的助手（如Kilo Code、Windsurf）在升级后可能会显示**重复的斜杠命令**——旧版本和新版本都会出现。

**解决方案：** 手动从助手的文件夹中删除旧的命令文件。

**Kilo Code示例：**

```bash
# 导航到助手的命令文件夹
cd .kilocode/rules/

# 列出文件并识别重复项
ls -la

# 删除旧版本（示例文件名——你的可能不同）
rm speckit.specify-old.md
rm speckit.plan-v1.md
```

重启你的IDE以刷新命令列表。

---

## 常见场景

### 场景1："我只需要新的斜杠命令"

```bash
# 升级CLI（如果使用持久安装）
uv tool install specify-cli --force --from git+https://github.com/lordking/spec-kit-zh.git

# 更新项目文件以获取新命令
specify init --here --force --ai copilot

# 如果自定义，恢复你的宪章
git restore .specify/memory/constitution.md
```

### 场景2："我自定义了模板和宪章"

```bash
# 1. 备份自定义
cp .specify/memory/constitution.md /tmp/constitution-backup.md
cp -r .specify/templates /tmp/templates-backup

# 2. 升级CLI
uv tool install specify-cli --force --from git+https://github.com/lordking/spec-kit-zh.git

# 3. 更新项目
specify init --here --force --ai copilot

# 4. 恢复自定义
mv /tmp/constitution-backup.md .specify/memory/constitution.md
# 如果需要，手动合并模板更改
```

### 场景3："我在IDE中看到重复的斜杠命令"

这发生在基于IDE的助手（Kilo Code、Windsurf、Roo Code等）。

```bash
# 找到助手文件夹（示例：.kilocode/rules/）
cd .kilocode/rules/

# 列出所有文件
ls -la

# 删除旧命令文件
rm speckit.old-command-name.md

# 重启你的IDE
```

### 场景4："我在没有Git的项目上工作"

如果你使用`--no-git`初始化项目，你仍然可以升级：

```bash
# 手动备份你自定义的文件
cp .specify/memory/constitution.md /tmp/constitution-backup.md

# 运行升级
specify init --here --force --ai copilot --no-git

# 恢复自定义
mv /tmp/constitution-backup.md .specify/memory/constitution.md
```

`--no-git`标志跳过git初始化，但不影响文件更新。

---

## 使用`--no-git`标志

`--no-git`标志告诉Spec Kit**跳过git仓库初始化**。这在以下情况下有用：

- 你以不同方式管理版本控制（Mercurial、SVN等）
- 你的项目是具有现有git设置的大型monorepo的一部分
- 你在实验，不想使用版本控制

**在初始设置期间：**

```bash
specify init my-project --ai copilot --no-git
```

**在升级期间：**

```bash
specify init --here --force --ai copilot --no-git
```

### `--no-git`不做什么

❌ 不防止文件更新
❌ 不跳过斜杠命令安装
❌ 不影响模板合并

它**只**跳过运行`git init`和创建初始提交。

### 在没有Git的情况下工作

如果你使用`--no-git`，你需要手动管理功能目录：

**在使用规划命令之前设置`SPECIFY_FEATURE`环境变量：**

```bash
# Bash/Zsh
export SPECIFY_FEATURE="001-my-feature"

# PowerShell
$env:SPECIFY_FEATURE = "001-my-feature"
```

这告诉Spec Kit在创建规格、计划和任务时使用哪个功能目录。

**为什么这很重要：** 没有git，Spec Kit无法检测你当前的分支名称来确定活动功能。环境变量手动提供该上下文。

---

## 故障排除

### "升级后斜杠命令未显示"

**原因：** 助手没有重新加载命令文件。

**修复：**

1. **完全重启你的IDE/编辑器**（而不仅仅是重新加载窗口）
2. **对于基于CLI的助手**，验证文件存在：

   ```bash
   ls -la .claude/commands/      # Claude Code
   ls -la .gemini/commands/       # Gemini
   ls -la .cursor/commands/       # Cursor
   ```

3. **检查助手特定设置：**
   - Codex需要`CODEX_HOME`环境变量
   - 一些助手需要工作区重启或清除缓存

### "我丢失了宪章自定义"

**修复：** 从git或备份恢复：

```bash
# 如果你在升级前提交了
git restore .specify/memory/constitution.md

# 如果你手动备份了
cp /tmp/constitution-backup.md .specify/memory/constitution.md
```

**预防：** 升级前总是提交或备份`constitution.md`。

### "警告：当前目录不为空"

**完整警告消息：**

```text
Warning: Current directory is not empty (25 items)
Template files will be merged with existing content and may overwrite existing files
Do you want to continue? [y/N]
```

**这意味着什么：**

当你运行`specify init --here`（或`specify init .`）在已有文件的目录中时，会出现此警告。它告诉你：

1. **目录有现有内容** - 在示例中，25个文件/文件夹
2. **文件将被合并** - 新的模板文件将与你现有文件一起添加
3. **某些文件可能被覆盖** - 如果你已经有Spec Kit文件（`.claude/`、`.specify/`等），它们将被新版本替换

**被覆盖的内容：**

只有Spec Kit基础设施文件：

- 助手命令文件（`.claude/commands/`、`.github/prompts/`等）
- `.specify/scripts/`中的脚本
- `.specify/templates/`中的模板
- `.specify/memory/`中的记忆文件（包括宪章）

**保持不变的内容：**

- 你的`specs/`目录（规格、计划、任务）
- 你的源代码文件
- 你的`.git/`目录和git历史
- 不属于Spec Kit模板的任何其他文件

**如何响应：**

- **输入`y`并按Enter** - 继续合并（如果升级，建议这样做）
- **输入`n`并按Enter** - 取消操作
- **使用`--force`标志** - 完全跳过此确认：

  ```bash
  specify init --here --force --ai copilot
  ```

**何时看到此警告：**

- ✅ **预期**当升级现有Spec Kit项目时
- ✅ **预期**当将Spec Kit添加到现有代码库时
- ⚠️ **意外**如果你认为你在空目录中创建新项目

**预防提示：** 升级前，如果你自定义了，提交或备份你的`.specify/memory/constitution.md`。

### "CLI升级似乎不起作用"

验证安装：

```bash
# 检查已安装的工具
uv tool list

# 应该显示specify-cli

# 验证路径
which specify

# 应该指向uv工具安装目录
```

如果未找到，重新安装：

```bash
uv tool uninstall specify-cli
uv tool install specify-cli --from git+https://github.com/lordking/spec-kit-zh.git
```

### "我需要每次打开项目时都运行specify吗？"

**简短答案：** 不，你每个项目只需要运行一次`specify init`（或在升级时）。

**解释：**

`specify` CLI工具用于：

- **初始设置：** `specify init`在你的项目中引导Spec Kit
- **升级：** `specify init --here --force`更新模板和命令
- **诊断：** `specify check`验证工具安装

一旦你运行了`specify init`，斜杠命令（如`/speckit.specify`、`/speckit.plan`等）就**永久安装**在你项目的助手文件夹（`.claude/`、`.github/prompts/`等）中。你的AI助手直接读取这些命令文件——无需再次运行`specify`。

**如果你的助手不识别斜杠命令：**

1. **验证命令文件存在：**

   ```bash
   # 对于GitHub Copilot
   ls -la .github/prompts/

   # 对于Claude
   ls -la .claude/commands/
   ```

2. **完全重启你的IDE/编辑器**（而不仅仅是重新加载窗口）

3. **检查你在正确的目录中**你运行了`specify init`

4. **对于一些助手**，你可能需要重新加载工作区或清除缓存

**相关问题：** 如果Copilot无法打开本地文件或意外使用PowerShell命令，这通常是IDE上下文问题，与`specify`无关。尝试：

- 重启VS Code
- 检查文件权限
- 确保工作区文件夹正确打开

---

## 版本兼容性

Spec Kit遵循主要版本的语义版本控制。CLI和项目文件设计为在同一主要版本内兼容。

**最佳实践：** 在主要版本更改期间，通过一起升级CLI和项目文件来保持同步。

---

## 下一步

升级后：

- **测试新的斜杠命令：** 运行`/speckit.constitution`或另一个命令验证一切正常
- **查看发布说明：** 查看[GitHub Releases](https://github.com/lordking/spec-kit-zh/releases)了解新功能和破坏性更改
- **更新工作流：** 如果添加了新命令，更新你团队的开发工作流
- **检查文档：** 访问[github.io/spec-kit-zh](https://lordking.github.io/spec-kit-zh/)查看更新的指南
