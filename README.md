<div align="center">
    <img src="./media/logo_large.webp" alt="Spec Kit Logo" width="200" height="200"/>
    <h1>🌱 Spec Kit 中文版</h1>
    <h3><em>让你在中文上下文语境中使用Spec Kit</em></h3>
</div>

<p align="center">
    <strong>Spec Kit是Github官方推出的规格驱动开发工具。但它所有的操作以及生成文档都是英文的，这使得中文用户很难理解和使用。因此我汉化了Spec Kit，使其在中文环境中更易于使用。</strong>
</p>

<p align="center">
    <a href="https://github.com/lordking/spec-kit-zh/actions/workflows/release-zh.yml"><img src="https://github.com/lordking/spec-kit-zh/actions/workflows/release-zh.yml/badge.svg" alt="Release"/></a>
    <a href="https://github.com/lordking/spec-kit-zh/stargazers"><img src="https://img.shields.io/github/stars/lordking/spec-kit-zh?style=social" alt="GitHub stars"/></a>
    <a href="https://github.com/lordking/spec-kit-zh/blob/main/LICENSE"><img src="https://img.shields.io/github/license/lordking/spec-kit-zh" alt="License"/></a>
    <a href="https://lordking.github.io/spec-kit-zh/"><img src="https://img.shields.io/badge/docs-GitHub_Pages-blue" alt="文档"/></a>
</p>

---

## 目录

- [🤔 什么是规格驱动开发？](#-什么是规格驱动开发)
- [⚡ 快速开始](#-快速开始)
- [📽️ 视频概览](#️-视频概览)
- [🤖 支持的 AI 助手](#-支持的-ai-助手)
- [🔧 Specify CLI 参考](#-specify-cli-参考)
- [📚 核心理念](#-核心理念)
- [🌟 开发阶段](#-开发阶段)
- [🎯 实验目标](#-实验目标)
- [🔧 前置条件](#-前置条件)
- [📖 深入了解](#-深入了解)
- [📋 详细流程](#-详细流程)
- [🔍 故障排除](#-故障排除)
- [👥 维护者](#-维护者)
- [💬 支持](#-支持)
- [🙏 致谢](#-致谢)
- [📄 许可证](#-许可证)

## 🤔 什么是规格驱动开发？

规格驱动开发（Spec-Driven Development）**颠覆了**传统软件开发的思路。几十年来，代码一直是核心——规格说明只是我们在"真正工作"（编码）开始之前搭建并丢弃的脚手架。规格驱动开发改变了这一切：**规格说明变得可执行**，直接生成可运行的实现，而不仅仅是指导实现。

## ⚡ 快速开始

### 1. 安装 Specify CLI

选择你偏好的安装方式：

#### 方式一：持久安装（推荐）

一次安装，随处使用：

```bash
uv tool install specify-cli --from git+https://github.com/lordking/spec-kit-zh.git
```

然后直接使用该工具：

```bash
# 创建新项目
specify init <PROJECT_NAME>

# 或在现有项目中初始化
specify init . --ai claude
# 或
specify init --here --ai claude

# 检查已安装工具
specify check
```

如需升级 Specify，请参阅[升级指南](./docs/upgrade.md)。快速升级命令：

```bash
uv tool install specify-cli --force --from git+https://github.com/lordking/spec-kit-zh.git
```

#### 方式二：一次性使用

无需安装，直接运行：

```bash
uvx --from git+https://github.com/lordking/spec-kit-zh.git specify init <PROJECT_NAME>
```

**持久安装的优势：**

- 工具持久安装并在 PATH 中可用
- 无需创建 shell 别名
- 通过 `uv tool list`、`uv tool upgrade`、`uv tool uninstall` 进行更好的工具管理
- 更简洁的 shell 配置

### 2. 建立项目原则

在项目目录中启动你的 AI 助手。助手中将提供 `/speckit.*` 命令。

使用 **`/speckit.constitution`** 命令创建项目的治理原则和开发指南，这将指导后续所有开发工作。

```bash
/speckit.constitution 创建专注于代码质量、测试标准、用户体验一致性和性能要求的原则
```

### 3. 创建规格说明

使用 **`/speckit.specify`** 命令描述你想要构建的内容。专注于**做什么**和**为什么做**，而不是技术栈。

```bash
/speckit.specify 构建一个应用，帮助我将照片整理到不同的相册中。相册按日期分组，可以在主页面通过拖放重新排列。相册不能嵌套在其他相册中。在每个相册内，照片以瓦片式界面预览。
```

### 4. 创建技术实现计划

使用 **`/speckit.plan`** 命令提供你的技术栈和架构选择。

```bash
/speckit.plan 应用使用 Vite，尽量减少库的使用。尽可能使用原生 HTML、CSS 和 JavaScript。图片不上传到任何地方，元数据存储在本地 SQLite 数据库中。
```

### 5. 拆解为任务

使用 **`/speckit.tasks`** 从实现计划中创建可操作的任务列表。

```bash
/speckit.tasks
```

### 6. 执行实现

使用 **`/speckit.implement`** 执行所有任务，按计划构建功能。

```bash
/speckit.implement
```

详细的分步说明，请参阅我们的[完整指南](./spec-driven.md)。

## 📽️ 视频概览

想看 Spec Kit 的实际效果？观看我们的[视频概览](https://www.youtube.com/watch?v=a9eR1xsfvHg&pp=0gcJCckJAYcqIYzv)！

[![Spec Kit 视频封面](/media/spec-kit-video-header.jpg)](https://www.youtube.com/watch?v=a9eR1xsfvHg&pp=0gcJCckJAYcqIYzv)

## 🤖 支持的 AI 助手

| 助手                                                                                    | 支持状态 | 备注                                                                                                                               |
| --------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| [Qoder CLI](https://qoder.com/cli)                                                      | ✅       |                                                                                                                                    |
| [Amazon Q Developer CLI](https://aws.amazon.com/developer/learning/q-developer-cli/)   | ⚠️       | Amazon Q Developer CLI [不支持](https://github.com/aws/amazon-q-developer-cli/issues/3064)斜杠命令的自定义参数。                  |
| [Amp](https://ampcode.com/)                                                             | ✅       |                                                                                                                                    |
| [Auggie CLI](https://docs.augmentcode.com/cli/overview)                                 | ✅       |                                                                                                                                    |
| [Claude Code](https://www.anthropic.com/claude-code)                                    | ✅       |                                                                                                                                    |
| [CodeBuddy CLI](https://www.codebuddy.ai/cli)                                           | ✅       |                                                                                                                                    |
| [Codex CLI](https://github.com/openai/codex)                                            | ✅       |                                                                                                                                    |
| [Cursor](https://cursor.sh/)                                                            | ✅       |                                                                                                                                    |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli)                               | ✅       |                                                                                                                                    |
| [GitHub Copilot](https://code.visualstudio.com/)                                        | ✅       |                                                                                                                                    |
| [IBM Bob](https://www.ibm.com/products/bob)                                             | ✅       | 基于 IDE 的助手，支持斜杠命令                                                                                                      |
| [Jules](https://jules.google.com/)                                                      | ✅       |                                                                                                                                    |
| [Kilo Code](https://github.com/Kilo-Org/kilocode)                                       | ✅       |                                                                                                                                    |
| [opencode](https://opencode.ai/)                                                        | ✅       |                                                                                                                                    |
| [Qwen Code](https://github.com/QwenLM/qwen-code)                                        | ✅       |                                                                                                                                    |
| [Roo Code](https://roocode.com/)                                                        | ✅       |                                                                                                                                    |
| [SHAI (OVHcloud)](https://github.com/ovh/shai)                                          | ✅       |                                                                                                                                    |
| [Windsurf](https://windsurf.com/)                                                       | ✅       |                                                                                                                                    |

## 🔧 Specify CLI 参考

`specify` 命令支持以下选项：

### 命令

| 命令    | 描述                                                                                                                                                      |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `init`  | 从最新模板初始化新的 Specify 项目                                                                                                                          |
| `check` | 检查已安装工具（`git`、`claude`、`gemini`、`code`/`code-insiders`、`cursor-agent`、`windsurf`、`qwen`、`opencode`、`codex`、`shai`、`qoder`）             |

### `specify init` 参数与选项

| 参数/选项              | 类型     | 描述                                                                                                                                                                             |
| ---------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<project-name>`       | 参数     | 新项目目录的名称（使用 `--here` 或 `.` 表示当前目录时可选）                                                                                                                     |
| `--ai`                 | 选项     | 要使用的 AI 助手：`claude`、`gemini`、`copilot`、`cursor-agent`、`qwen`、`opencode`、`codex`、`windsurf`、`kilocode`、`auggie`、`roo`、`codebuddy`、`amp`、`shai`、`q`、`bob` 或 `qoder` |
| `--script`             | 选项     | 使用的脚本变体：`sh`（bash/zsh）或 `ps`（PowerShell）                                                                                                                            |
| `--ignore-agent-tools` | 标志     | 跳过 AI 代理工具（如 Claude Code）的检查                                                                                                                                         |
| `--no-git`             | 标志     | 跳过 git 仓库初始化                                                                                                                                                              |
| `--here`               | 标志     | 在当前目录初始化项目，而非创建新目录                                                                                                                                             |
| `--force`              | 标志     | 在当前目录初始化时强制合并/覆盖（跳过确认）                                                                                                                                      |
| `--skip-tls`           | 标志     | 跳过 SSL/TLS 验证（不推荐）                                                                                                                                                      |
| `--debug`              | 标志     | 启用详细调试输出以便排查问题                                                                                                                                                     |
| `--github-token`       | 选项     | API 请求使用的 GitHub token（或设置 GH_TOKEN/GITHUB_TOKEN 环境变量）                                                                                                             |

### 示例

```bash
# 基本项目初始化
specify init my-project

# 使用特定 AI 助手初始化
specify init my-project --ai claude

# 使用 Cursor 支持初始化
specify init my-project --ai cursor-agent

# 使用 Qoder 支持初始化
specify init my-project --ai qoder

# 使用 Windsurf 支持初始化
specify init my-project --ai windsurf

# 使用 Amp 支持初始化
specify init my-project --ai amp

# 使用 SHAI 支持初始化
specify init my-project --ai shai

# 使用 IBM Bob 支持初始化
specify init my-project --ai bob

# 使用 PowerShell 脚本初始化（Windows/跨平台）
specify init my-project --ai copilot --script ps

# 在当前目录初始化
specify init . --ai copilot
# 或使用 --here 标志
specify init --here --ai copilot

# 无需确认强制合并到当前（非空）目录
specify init . --force --ai copilot
# 或
specify init --here --force --ai copilot

# 跳过 git 初始化
specify init my-project --ai gemini --no-git

# 启用调试输出以排查问题
specify init my-project --ai claude --debug

# 使用 GitHub token 进行 API 请求（在企业环境中很有帮助）
specify init my-project --ai claude --github-token ghp_your_token_here

# 检查系统需求
specify check
```

### 可用的斜杠命令

运行 `specify init` 后，你的 AI 编码助手将可以使用以下斜杠命令进行结构化开发：

#### 核心命令

规格驱动开发工作流的必要命令：

| 命令                    | 描述                                                              |
| ----------------------- | ----------------------------------------------------------------- |
| `/speckit.constitution` | 创建或更新项目治理原则和开发指南                                   |
| `/speckit.specify`      | 定义你想要构建的内容（需求和用户故事）                             |
| `/speckit.plan`         | 根据你选择的技术栈创建技术实现计划                                 |
| `/speckit.tasks`        | 生成可操作的实现任务列表                                           |
| `/speckit.implement`    | 执行所有任务，按计划构建功能                                       |

#### 可选命令

用于增强质量和验证的附加命令：

| 命令                 | 描述                                                                                                                              |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `/speckit.clarify`   | 澄清规格说明中不够清晰的部分（推荐在 `/speckit.plan` 之前使用；原名 `/quizme`）                                                   |
| `/speckit.analyze`   | 跨产物的一致性与覆盖率分析（在 `/speckit.tasks` 之后、`/speckit.implement` 之前运行）                                             |
| `/speckit.checklist` | 生成自定义质量检查清单，验证需求的完整性、清晰度和一致性（类似"英文单元测试"）                                                    |

### 环境变量

| 变量              | 描述                                                                                                                                                                                                                             |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SPECIFY_FEATURE` | 覆盖非 Git 仓库的功能检测。设置为功能目录名称（例如 `001-photo-albums`），在不使用 Git 分支时处理特定功能。<br/>**必须在使用 `/speckit.plan` 或后续命令之前，在你所用代理的上下文中设置。** |

## 📚 核心理念

规格驱动开发是一个结构化的流程，强调：

- **意图驱动开发**：规格说明在"如何做"之前定义"做什么"
- **丰富的规格说明创建**：使用护栏和组织原则
- **多步骤精化**：而非从提示词一次性生成代码
- **深度依赖**先进 AI 模型能力来解读规格说明

## 🌟 开发阶段

| 阶段                              | 关注点           | 主要活动                                                                                                                                                     |
| --------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **0 到 1 开发**（"绿地"项目）     | 从零生成         | <ul><li>从高层需求出发</li><li>生成规格说明</li><li>规划实现步骤</li><li>构建生产就绪的应用</li></ul>                                                        |
| **创意探索**                      | 并行实现         | <ul><li>探索多样化解决方案</li><li>支持多种技术栈和架构</li><li>试验用户体验模式</li></ul>                                                                   |
| **迭代增强**（"棕地"项目）        | 棕地现代化       | <ul><li>迭代添加功能</li><li>现代化遗留系统</li><li>适应流程变化</li></ul>                                                                                   |

## 🎯 实验目标

我们的研究与实验聚焦于：

### 技术独立性

- 使用多样化的技术栈创建应用
- 验证规格驱动开发不依赖于特定技术、编程语言或框架的假设

### 企业约束

- 演示关键任务应用的开发
- 融入组织约束（云提供商、技术栈、工程实践）
- 支持企业设计系统和合规要求

### 以用户为中心的开发

- 为不同用户群体和偏好构建应用
- 支持各种开发方式（从随心所欲编码到 AI 原生开发）

### 创意与迭代流程

- 验证并行实现探索的概念
- 提供健壮的迭代功能开发工作流
- 将流程扩展到处理升级和现代化任务

## 🔧 前置条件

- **Linux/macOS/Windows**
- [支持的](#-支持的-ai-助手) AI 编码助手
- 用于包管理的 [uv](https://docs.astral.sh/uv/)
- [Python 3.11+](https://www.python.org/downloads/)
- [Git](https://git-scm.com/downloads)

如果你遇到某个代理的问题，请提交 issue，我们将完善集成。

## 📖 深入了解

- **[完整规格驱动开发方法论](./spec-driven.md)** - 深入了解完整流程
- **[详细演练](#-详细流程)** - 分步实现指南

---

## 📋 详细流程

<details>
<summary>点击展开详细的分步演练</summary>

你可以使用 Specify CLI 来引导你的项目，它将在你的环境中引入所需的产物。运行：

```bash
specify init <project_name>
```

或在当前目录初始化：

```bash
specify init .
# 或使用 --here 标志
specify init --here
# 目录已有文件时跳过确认
specify init . --force
# 或
specify init --here --force
```

![Specify CLI 在终端中引导新项目](./media/specify_cli.gif)

系统会提示你选择正在使用的 AI 代理。你也可以在终端中直接指定：

```bash
specify init <project_name> --ai claude
specify init <project_name> --ai gemini
specify init <project_name> --ai copilot

# 或在当前目录：
specify init . --ai claude
specify init . --ai codex

# 或使用 --here 标志
specify init --here --ai claude
specify init --here --ai codex

# 强制合并到非空的当前目录
specify init . --force --ai claude

# 或
specify init --here --force --ai claude
```

CLI 将检查你是否已安装 Claude Code、Gemini CLI、Cursor CLI、Qwen CLI、opencode、Codex CLI、Qoder CLI 或 Amazon Q Developer CLI。如果没有安装，或者你希望不检查工具直接获取模板，可在命令中使用 `--ignore-agent-tools`：

```bash
specify init <project_name> --ai claude --ignore-agent-tools
```

### **第一步：** 建立项目原则

进入项目文件夹并运行你的 AI 代理。在我们的示例中，使用 `claude`。

![引导 Claude Code 环境](./media/bootstrap-claude-code.gif)

如果配置正确，你应该能看到 `/speckit.constitution`、`/speckit.specify`、`/speckit.plan`、`/speckit.tasks` 和 `/speckit.implement` 命令可用。

第一步应使用 `/speckit.constitution` 命令建立项目的治理原则。这有助于确保后续所有开发阶段的决策保持一致：

```text
/speckit.constitution 创建专注于代码质量、测试标准、用户体验一致性和性能要求的原则。包括这些原则如何指导技术决策和实现选择的治理规范。
```

此步骤将创建或更新 `.specify/memory/constitution.md` 文件，其中包含 AI 代理在规格说明、规划和实现阶段将参考的项目基础指南。

### **第二步：** 创建项目规格说明

建立项目原则后，你可以创建功能规格说明。使用 `/speckit.specify` 命令，然后提供你想要开发的项目的具体需求。

> [!IMPORTANT]
> 尽可能明确地描述你*想要构建什么*以及*为什么*。**此时不要关注技术栈**。

示例提示词：

```text
开发 Taskify，一个团队生产力平台。它应该允许用户创建项目、添加团队成员、分配任务、评论并在看板之间移动任务。在这个初始阶段（我们称之为"创建 Taskify"），让我们有多个用户，但用户将提前声明，预先定义。我想要两个不同类别的五个用户，一个产品经理和四个工程师。让我们创建三个不同的示例项目。让我们为每个任务的状态使用标准看板列，如"待办"、"进行中"、"审查中"和"已完成"。这个应用程序不需要登录，因为这只是确保基本功能已设置的最初测试。对于 UI 中的每个任务卡，你应该能够在看板工作板的不同列之间更改任务的当前状态。你应该能够为特定卡片留下无限数量的评论。你应该能够从任务卡中分配一个有效用户。当你第一次启动 Taskify 时，它会给你一个五个用户的列表供你选择。不需要密码。当你点击一个用户时，你进入主视图，显示项目列表。当你点击一个项目时，打开该项目的看板。你将看到各列。你将能够在不同列之间拖放卡片。你将看到分配给你（当前登录用户）的卡片以不同颜色显示，这样你可以快速看到你的卡片。你可以编辑你发表的评论，但不能编辑其他人发表的评论。你可以删除你发表的评论，但不能删除其他人发表的评论。
```

输入此提示词后，你应该看到 Claude Code 启动规划和规格草拟流程。Claude Code 还会触发一些内置脚本来设置仓库。

完成此步骤后，你应该会创建一个新分支（例如 `001-create-taskify`），以及 `specs/001-create-taskify` 目录中的新规格说明。

生成的规格说明应包含一组用户故事和功能需求，如模板中定义的那样。

此阶段，你的项目文件夹内容应类似于：

```text
└── .specify
    ├── memory
    │  └── constitution.md
    ├── scripts
    │  ├── check-prerequisites.sh
    │  ├── common.sh
    │  ├── create-new-feature.sh
    │  ├── setup-plan.sh
    │  └── update-claude-md.sh
    ├── specs
    │  └── 001-create-taskify
    │      └── spec.md
    └── templates
        ├── plan-template.md
        ├── spec-template.md
        └── tasks-template.md
```

### **第三步：** 功能规格说明澄清（规划前必须完成）

建立基础规格说明后，你可以继续澄清在第一次尝试中未能正确捕获的任何需求。

在创建技术计划**之前**，你应该运行结构化澄清工作流，以减少后续的返工。

推荐顺序：

1. 使用 `/speckit.clarify`（结构化）——基于覆盖率的顺序提问，并将答案记录在"澄清"部分。
2. 如果仍有模糊之处，可选择性地进行自由形式的临时补充细化。

如果你有意跳过澄清（例如，探索性原型），请明确说明，以免代理在缺失澄清时阻塞。

自由形式细化示例提示词（在 `/speckit.clarify` 之后如果仍需要）：

```text
对于你创建的每个示例项目，任务数量应该在 5 到 15 个之间随机分布到不同的完成状态。确保每个阶段至少有一个任务。
```

你还应该要求 Claude Code 验证**审查与验收检查清单**，勾选已验证/通过需求的项目，未通过的留空。可以使用以下提示词：

```text
阅读审查和验收检查清单，如果功能规格说明符合标准，则勾选每个项目。如果不符合，则留空。
```

重要的是，把与 Claude Code 的互动视为澄清和提问规格说明的机会——**不要把它的第一次尝试当作最终结果**。

### **第四步：** 生成计划

现在你可以具体说明技术栈和其他技术要求。你可以使用项目模板中内置的 `/speckit.plan` 命令，提示词如下：

```text
我们将使用 .NET Aspire 生成此应用，使用 Postgres 作为数据库。前端应使用 Blazor Server，带有拖放任务板、实时更新。应创建一个 REST API，包括项目 API、任务 API 和通知 API。
```

此步骤的输出将包含多个实现细节文档，你的目录树将类似于：

```text
.
├── CLAUDE.md
├── memory
│  └── constitution.md
├── scripts
│  ├── check-prerequisites.sh
│  ├── common.sh
│  ├── create-new-feature.sh
│  ├── setup-plan.sh
│  └── update-claude-md.sh
├── specs
│  └── 001-create-taskify
│      ├── contracts
│      │  ├── api-spec.json
│      │  └── signalr-spec.md
│      ├── data-model.md
│      ├── plan.md
│      ├── quickstart.md
│      ├── research.md
│      └── spec.md
└── templates
    ├── CLAUDE-template.md
    ├── plan-template.md
    ├── spec-template.md
    └── tasks-template.md
```

检查 `research.md` 文档，确保根据你的指令使用了正确的技术栈。如果有任何组件看起来不对，你可以让 Claude Code 进行细化，甚至让它检查你想使用的平台/框架的本地安装版本（例如 .NET）。

此外，如果选择的技术栈是快速变化的（例如 .NET Aspire、JS 框架），你可能希望让 Claude Code 研究相关细节，提示词如下：

```text
我希望你通读实现计划和实现细节，寻找可能从额外研究中受益的领域，因为 .NET Aspire 是一个快速变化的库。对于你确定需要进一步研究的领域，我希望你用有关我们将在此 Taskify 应用中使用的特定版本的额外细节更新研究文档，并启动并行研究任务来通过网络研究澄清任何细节。
```

在此过程中，你可能会发现 Claude Code 陷入研究错误的内容——你可以用如下提示词引导它：

```text
我认为我们需要将其分解为一系列步骤。首先，确定一个你在实现过程中不确定或需要进一步研究的任务列表。写下这些任务的列表。然后对于每一个任务，我希望你启动一个单独的研究任务，这样最终结果是我们并行研究所有这些非常具体的任务。我看到你做的是研究 .NET Aspire 的一般内容，我认为这对我们没什么用。研究太不具体了。研究需要帮助你解决一个具体的、有针对性的问题。
```

> [!NOTE]
> Claude Code 可能过于积极，添加了你没有要求的组件。请它澄清变更的理由和来源。

### **第五步：** 让 Claude Code 验证计划

计划就位后，你应该让 Claude Code 审查它，确保没有遗漏的部分。你可以使用如下提示词：

```text
现在我希望你审计实现计划和实现细节文件。以确定是否有一系列明显的任务需要执行的眼光通读它。因为我不知道这里是否有足够的内容。例如，当我查看核心实现时，在逐步完成核心实现或细化时，引用实现细节中可以找到信息的适当位置会很有用。
```

这有助于细化实现计划，帮助你避免 Claude Code 在规划周期中遗漏的潜在盲点。完成初步细化后，在进入实现之前，再次请 Claude Code 检查清单。

如果你安装了 [GitHub CLI](https://docs.github.com/en/github-cli/github-cli)，你还可以要求 Claude Code 从当前分支向 `main` 创建一个带有详细描述的拉取请求，以确保工作得到适当追踪。

> [!NOTE]
> 在让代理实现之前，还值得提示 Claude Code 交叉检查细节，查看是否有过度设计的部分（记住——它可能过于积极）。如果存在过度设计的组件或决策，你可以让 Claude Code 解决它们。确保 Claude Code 将[原则](base/memory/constitution.md)作为制定计划时必须遵守的基础。

### **第六步：** 使用 /speckit.tasks 生成任务分解

实现计划验证后，你现在可以将计划分解为可以按正确顺序执行的具体、可操作的任务。使用 `/speckit.tasks` 命令从实现计划自动生成详细的任务分解：

```text
/speckit.tasks
```

此步骤在你的功能规格说明目录中创建一个 `tasks.md` 文件，包含：

- **按用户故事组织的任务分解** - 每个用户故事成为一个独立的实现阶段，有其自己的一组任务
- **依赖管理** - 任务按顺序排列以尊重组件间的依赖关系（例如，模型在服务之前，服务在端点之前）
- **并行执行标记** - 可并行运行的任务标记为 `[P]`，以优化开发工作流
- **文件路径规格** - 每个任务包含应在其中实现的确切文件路径
- **测试驱动开发结构** - 如果需要测试，测试任务包含在内并排序为在实现之前编写
- **检查点验证** - 每个用户故事阶段包含检查点以验证独立功能

生成的 tasks.md 为 `/speckit.implement` 命令提供了清晰的路线图，确保系统化实现，维护代码质量，并允许用户故事的增量交付。

### **第七步：** 实现

准备就绪后，使用 `/speckit.implement` 命令执行实现计划：

```text
/speckit.implement
```

`/speckit.implement` 命令将：

- 验证所有先决条件已到位（原则、规格说明、计划和任务）
- 从 `tasks.md` 解析任务分解
- 按正确顺序执行任务，尊重依赖关系和并行执行标记
- 遵循任务计划中定义的 TDD 方法
- 提供进度更新并适当处理错误

> [!IMPORTANT]
> AI 代理将执行本地 CLI 命令（如 `dotnet`、`npm` 等）——确保你的机器上安装了所需工具。

实现完成后，测试应用并解决 CLI 日志中可能不可见的任何运行时错误（例如，浏览器控制台错误）。你可以将此类错误复制粘贴回 AI 代理进行修复。

</details>

---

## 🔍 故障排除

### Linux 上的 Git Credential Manager

如果你在 Linux 上遇到 Git 身份验证问题，可以安装 Git Credential Manager：

```bash
#!/usr/bin/env bash
set -e
echo "正在下载 Git Credential Manager v2.6.1..."
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb
echo "正在安装 Git Credential Manager..."
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
echo "正在配置 Git 使用 GCM..."
git config --global credential.helper manager
echo "正在清理..."
rm gcm-linux_amd64.2.6.1.deb
```

## 👥 维护者

- Den Delimarsky ([@localden](https://github.com/localden))
- John Lam ([@jflam](https://github.com/jflam))

## 💬 支持

如需支持，请提交 [GitHub issue](https://github.com/github/spec-kit/issues/new)。我们欢迎 bug 报告、功能请求以及关于使用规格驱动开发的问题。

## 🙏 致谢

本项目深受 [John Lam](https://github.com/jflam) 的工作和研究影响，并基于其成果构建。

## 📄 许可证

本项目遵循 MIT 开源许可证。请参阅 [LICENSE](./LICENSE) 文件了解完整条款。
