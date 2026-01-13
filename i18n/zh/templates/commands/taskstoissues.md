---
description: 基于可利用的设计工件，将现有任务转换为功能上可操作的、具有依赖顺序的 GitHub 问题。
tools: ['github/github-mcp-server/issue_write']
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## 用户输入

```text
$ARGUMENTS
```

（如果不为空）在进行之前，你**必须**考虑用户输入。

## 大纲

1. 从仓库根目录运行 `{SCRIPT}` 并解析 FEATURE_DIR 和 AVAILABLE_DOCS 列表（即可用的设计文档列表）。所有路径必须是绝对路径。对于参数中的单引号，如 "I'm Groot"，使用转义语法：例如 'I'\''m Groot'（尽可能使用双引号："I'm Groot"）。
1. 从已执行的脚本中，提取指向任务清单的路径。
1. 运行以下命令获取 Git 远程仓库地址：

    ```bash
    git config --get remote.origin.url
    ```

    > [!CAUTION]
    > 仅当远程仓库地址是 GitHub URL 时，才继续执行后续步骤。

1. 对于列表中的每个任务，使用 GitHub MCP 服务器在与 Git 远程匹配的仓库中创建一个新问题。

    > [!CAUTION]
    > 无论如何，绝不在与远程仓库 URL 不匹配的代码库中创建问题。
