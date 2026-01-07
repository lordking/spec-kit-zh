---
description: 根据可用设计工件，将现有任务转换为具有依赖顺序的可操作 GitHub 问题。
tools: ['github/github-mcp-server/issue_write']
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，你必须考虑用户输入（如果不为空）。

## 大纲

1. 从仓库根目录运行 `{SCRIPT}` 并解析 FEATURE_DIR 和 AVAILABLE_DOCS 列表。所有路径必须是绝对的。对于参数中的单引号，如 "I'm Groot"，使用转义语法：例如 'I'\''m Groot'（或者如果可能，也可以使用双引号："I'm Groot"）。
1. 从执行的脚本中提取 **任务** 的路径。
1. 通过运行获取 Git 远程：

```bash
git config --get remote.origin.url
```

**仅当远程是 GITHUB URL 时才继续到下一步**

1. 对于列表中的每个任务，使用 GitHub MCP 服务器在与 Git 远程匹配的仓库中创建一个新问题。

**在任何情况下都不要在与远程 URL 不匹配的仓库中创建问题**
