---
description: 通过处理和执行 tasks.md 中定义的所有任务来执行实施计划
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

1. 从仓库根目录运行 `{SCRIPT}` 并解析 FEATURE_DIR 和 AVAILABLE_DOCS 列表。所有路径必须是绝对路径。对于参数中的单引号，如 "I'm Groot"，使用转义语法：例如 'I'\''m Groot'（尽可能使用双引号："I'm Groot"）。

2. **检查清单状态**（如果 FEATURE_DIR/checklists/ 目录存在）：
   - 扫描 checklists/ 目录下的所有检查清单文件
   - 对于每个清单，统计：
     - 总项数：匹配 `- [ ]` 或 `- [X]` 或 `- [x]` 的所有行
     - 已完成项：匹配 `- [X]` 或 `- [x]` 的行
     - 未完成项：匹配 `- [ ]` 的行
   - 创建状态统计报表：

     ```text
     | 清单 | 总项数 | 已完成 | 未完成 | 状态 |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ 通过 |
     | test.md   | 8     | 5         | 3          | ✗ 失败 |
     | security.md | 6   | 6         | 0          | ✓ 通过 |
     ```

   - 计算总体状态：
     - **通过**：所有检查清单的未完成项均为 0
     - **失败**：一个或多个检查清单存在未完成项。

   - **如果检查清单有任何未完成项**：
     - 显示包含未完成项数量的表格
     - **停止**并询问："部分检查清单未完成。是否仍要继续实施？（是/否）"
     - 等待用户响应后再继续
     - 如果用户回答"否/no"或"等待/wait"或"停止/stop"，则中止执行
     - 如果用户回答"是/yes"或"继续/continue"或"进行/proceed"，则继续到第 3 步

   - **如果所有检查清单均已完成**：
     - 显示表格，用以展现所有检查清单均已通过
     - 自动继续到第 3 步

3. 加载并分析实施上下文：
   - **必需**：读取 tasks.md 以获取完整的任务列表和执行计划
   - **必需**：读取 plan.md 以获取技术栈、架构和文件结构
   - **如果存在**：读取 data-model.md 以获取实体以及它们之间的关系
   - **如果存在**：读取 contracts/ 以获取 API 规格及其测试需求
   - **如果存在**：读取 research.md 以获取技术决策及其约束
   - **如果存在**：读取 quickstart.md 以获取集成场景

4. **项目设置验证**：
   - **必需**：根据实际项目设置创建/验证忽略文件：

   **检测和创建逻辑**：
   - 检查以下命令是否成功执行，以确定仓库是否为 Git 仓库（如果是，则创建/验证 .gitignore）：

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - 检查是否存在 Dockerfile* 或 plan.md 中提及 Docker → 创建/验证 .dockerignore
   - 检查是否存在 .eslintrc*  → 创建/验证 .eslintignore
   - 检查是否存在 eslint.config.*  → 确保配置的 `ignores` 条目覆盖了必要的模式
   - 检查是否存在 .prettierrc*  → 创建/验证 .prettierignore
   - 检查是否存在 .npmrc 或 package.json  → 创建/验证 .npmignore（如果发布包）
   - 检查是否存在 terraform 文件 (*.tf)  → 创建/验证 .terraformignore
   - 检查是否需要 .helmignore（helm 图表存在）→ 创建/验证 .helmignore

   **如果忽略文件已存在**：验证其是否包含基本模式，仅添加缺失的关键模式
   **如果忽略文件缺失**：用已探测到的技术创建包含完整模式集的文件

   **按技术分类的常见模式**（来自 plan.md 定义的技术栈）：
   - **Node.js/JavaScript/TypeScript**：`node_modules/`、`dist/`、`build/`、`*.log`、`.env*`
   - **Python**：`__pycache__/`、`*.pyc`、`.venv/`、`venv/`、`dist/`、`*.egg-info/`
   - **Java**：`target/`、`*.class`、`*.jar`、`.gradle/`、`build/`
   - **C#/.NET**：`bin/`、`obj/`、`*.user`、`*.suo`、`packages/`
   - **Go**：`*.exe`、`*.test`、`vendor/`、`*.out`
   - **Ruby**：`.bundle/`、`log/`、`tmp/`、`*.gem`、`vendor/bundle/`
   - **PHP**：`vendor/`、`*.log`、`*.cache`、`*.env`
   - **Rust**：`target/`、`debug/`、`release/`、`*.rs.bk`、`*.rlib`、`*.prof*`、`.idea/`、`*.log`、`.env*`
   - **Kotlin**：`build/`、`out/`、`.gradle/`、`.idea/`、`*.class`、`*.jar`、`*.iml`、`*.log`、`.env*`
   - **C++**：`build/`、`bin/`、`obj/`、`out/`、`*.o`、`*.so`、`*.a`、`*.exe`、`*.dll`、`.idea/`、`*.log`、`.env*`
   - **C**：`build/`、`bin/`、`obj/`、`out/`、`*.o`、`*.a`、`*.so`、`*.exe`、`Makefile`、`config.log`、`.idea/`、`*.log`、`.env*`
   - **Swift**：`.build/`、`DerivedData/`、`*.swiftpm/`、`Packages/`
   - **R**：`.Rproj.user/`、`.Rhistory`、`.RData`、`.Ruserdata`、`*.Rproj`、`packrat/`、`renv/`
   - **通用**：`.DS_Store`、`Thumbs.db`、`*.tmp`、`*.swp`、`.vscode/`、`.idea/`

   **工具特定模式**：
   - **Docker**：`node_modules/`、`.git/`、`Dockerfile*`、`.dockerignore`、`*.log*`、`.env*`、`coverage/`
   - **ESLint**：`node_modules/`、`dist/`、`build/`、`coverage/`、`*.min.js`
   - **Prettier**：`node_modules/`、`dist/`、`build/`、`coverage/`、`package-lock.json`、`yarn.lock`、`pnpm-lock.yaml`
   - **Terraform**：`.terraform/`、`*.tfstate*`、`*.tfvars`、`.terraform.lock.hcl`
   - **Kubernetes/k8s**：`*.secret.yaml`、`secrets/`、`.kube/`、`kubeconfig*`、`*.key`、`*.crt`

5. 解析 tasks.md 结构并提取：
   - **任务阶段**：设置、测试、核心、集成、优化
   - **任务依赖关系**：串行与并行执行规则
   - **任务详情**：ID、描述、文件路径、并行标记 [P]
   - **执行流程**：顺序和依赖关系要求

6. 按照任务计划执行实施：
   - **分阶段逐步执行**：完成一个阶段后再进入下一阶段
   - **遵循依赖关系**：按顺序运行串行任务，并行任务 [P] 可以同时运行
   - **遵循 TDD 方法**：在执行对应的实施任务之前执行测试任务
   - **基于文件的协调**：影响相同文件的任务必须串行运行
   - **验证检查点**：在继续之前验证每个阶段的完成情况

7. 实施执行规则：
   - **首先设置**：初始化项目结构、依赖项、配置
   - **先测试后编码**：当需要为契约、实体、集成场景编写测试时，请遵循此顺序。
   - **核心开发**：实现模型、服务、CLI 命令、端点
   - **集成工作**：数据库连接、中间件、日志记录、外部服务
   - **优化与验证**：单元测试、性能优化、文档

8. 进度跟踪与错误处理：
   - 在每次完成任务后报告进度
   - 如果任何非并行任务失败，则停止执行
   - 对于并行任务 [P]，继续执行成功的任务，报告失败的任务
   - 为调试提供带有上下文的清晰错误消息
   - 如果实施无法进行，请建议后续步骤
   - **重要** 对于已完成的任务，确保在任务文件中将任务标记为 [X]。

9. 完成验证：
   - 验证所有必需任务均已完成
   - 检查已实现的功能是否与原始规格匹配
   - 验证测试是否通过且测试覆盖率符合要求
   - 确认实施是否遵循了技术计划
   - 报告最终状态和已完成工作的摘要

注意：此命令假设 tasks.md 中存在完整的任务分解。如果任务不完整或缺失，建议先运行 `/speckit.tasks` 以重新生成任务列表。
