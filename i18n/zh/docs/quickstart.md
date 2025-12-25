# 快速入门指南

本指南将帮助你开始使用Spec Kit进行规格驱动开发。

> [!NOTE]
> 所有自动化脚本现在都提供Bash (`.sh`) 和 PowerShell (`.ps1`) 两种版本。`specify` CLI会根据操作系统自动选择，除非你传递 `--script sh|ps`。

## 六步流程

> [!TIP]
> **上下文感知**：Spec Kit命令会根据你当前的Git分支自动检测活动功能（例如 `001-feature-name`）。要在不同的规格之间切换，只需切换Git分支。

### 步骤1：安装Specify

**在你的终端中**，运行`specify` CLI命令来初始化你的项目：

```bash
# 创建新项目目录
uvx --from git+https://github.com/lordking/spec-kit-zh.git specify init <PROJECT_NAME>

# 或在当前目录中初始化
uvx --from git+https://github.com/lordking/spec-kit-zh.git specify init .
```

显式选择脚本类型（可选）：

```bash
uvx --from git+https://github.com/lordking/spec-kit-zh.git specify init <PROJECT_NAME> --script ps  # 强制PowerShell
uvx --from git+https://github.com/lordking/spec-kit-zh.git specify init <PROJECT_NAME> --script sh  # 强制POSIX shell
```

### 步骤2：定义你的宪章

**在你的AI助手的聊天界面中**，使用`/speckit.constitution`斜杠命令为你的项目建立核心规则和原则。你应该提供你的项目的特定原则作为参数。

```markdown
/speckit.constitution 该项目采用"库优先"的方法。所有功能必须首先以独立库的形式实现。我们严格遵循测试驱动开发（TDD），更倾向于使用函数式编程。
```

### 步骤3：创建规格

**在聊天界面中**，使用`/speckit.specify`斜杠命令描述你想要构建的内容。专注于**是什么**和**为什么**，而不是技术栈。

```markdown
/speckit.specify 构建一个应用程序，帮助我将照片整理到不同的相册中。相册按日期分组，并且可以在主页面通过拖放操作重新排列。相册不会存在于其他嵌套的相册中。在每个相册中，照片以拼图式界面进行预览。
```

### 步骤4：完善规格

**在聊天界面中**，使用`/speckit.clarify`斜杠命令识别并解决规格中的歧义。你可以提供特定的重点领域作为参数。

```bash
/speckit.clarify 关注安全和性能要求。
```

### 步骤5：创建技术实施计划

**在聊天界面中**，使用`/speckit.plan`斜杠命令提供你的技术栈和架构选择。

```markdown
/speckit.plan 该应用使用Vite，尽量减少库的数量，使用原生HTML、CSS和JavaScript。图片不会上传到任何地方，元数据存储在本地SQLite数据库中。
```

### 步骤6：分解并实施

**在聊天界面中**，使用`/speckit.tasks`斜杠命令创建可执行任务列表。

```markdown
/speckit.tasks
```

（可选）使用`/speckit.analyze`验证计划：

```markdown
/speckit.analyze
```

然后，使用`/speckit.implement`斜杠命令执行计划。

```markdown
/speckit.implement
```

## 详细示例：构建Taskify

这是一个构建团队生产力平台的完整示例：

### 步骤1：定义宪章

初始化项目宪章以建立基本规则：

```markdown
/speckit.constitution Taskify 是一个“安全优先”的应用程序。所有用户输入必须进行验证。我们使用微服务架构。代码必须进行完整文档记录。
```

### 步骤2：使用`/speckit.specify`定义需求

```text
Develop Taskify，一个团队生产力平台。它应允许用户创建项目，添加团队成员，分配任务，评论，并在看板风格的看板之间移动任务。在这一功能的初始阶段，让我们将其称为“创建Taskify”，让多个用户参与，但用户将在事先声明，为预定义的用户。我想要五个用户，分为两个不同的类别，一个产品经理和四个工程师。让我们创建三个不同的示例项目。每个任务的状态将有标准的看板列，例如“待办”、“进行中”、“审核中”和“已完成”。此应用程序将不涉及登录，因为这仅仅是确保基础功能设置的初步测试。
```

### 步骤3：完善规格

使用`/speckit.clarify`命令交互式地解决规格中的歧义。你也可以提供你希望确保包含的特定细节。

```bash
/speckit.clarify 我想澄清任务卡的细节。对于任务卡中的每个任务，你应该能够在看板工作板的不同列之间更改任务的当前状态。你应该能够为特定卡片留下无限数量的评论。你应该能够从该任务卡中分配一个有效用户。
```

你可以使用更多细节继续完善规格：

```bash
/speckit.clarify 当你第一次启动Taskify时，它会给你一个五个用户的列表供你选择。无需密码。当你点击一个用户时，你进入主视图，显示项目列表。当你点击一个项目时，你打开该项目的看板。你将看到各个列。你可以在不同列之间拖放卡片。你会看到分配给你的卡片（当前登录用户）与其他卡片颜色不同，这样你可以快速识别。你可以编辑你所做的任何评论，但不能编辑其他人做的评论。你可以删除你所做的任何评论，但不能删除其他人做的评论。
```

### 步骤4：验证规格

使用`/speckit.checklist`命令验证规格检查列表：

```bash
/speckit.checklist
```

### 步骤5：使用`/speckit.plan`生成技术计划

对你的技术栈和技术要求要具体：

```bash
/speckit.plan 我们将使用.NET Aspire生成，使用Postgres作为数据库。前端应使用Blazor服务器，具有拖放任务板和实时更新功能。应该创建一个REST API，包括项目API、任务API和通知API。
```

### 步骤6：验证并实施

使用`/speckit.analyze`让你的AI助手审核实施计划：

```bash
/speckit.analyze
```

最后，实施解决方案：

```bash
/speckit.implement
```

## 核心原则

- **明确**你要构建什么以及为什么
- 在规格阶段**不要关注技术栈**
- 在实施前**迭代和完善**你的规格
- 在编码开始前**验证**计划
- **让AI助手处理**实施细节

## 下一步

- 阅读[完整方法论](../spec-driven.md)以获取深入指导
- 查看仓库中的[更多示例](../templates)
- 探索[GitHub上的源代码](https://github.com/lordking/spec-kit-zh)
