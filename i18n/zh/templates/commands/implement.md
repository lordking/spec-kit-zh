---
description: 通过处理和执行 tasks.md 中定义的所有任务来执行实现计划
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

1. 从仓库根目录运行 `{SCRIPT}` 并解析 FEATURE_DIR 和 AVAILABLE_DOCS 列表。所有路径必须是绝对的。对于参数中的单引号，如 "I'm Groot"，使用转义语法：例如 'I'\''m Groot'（或尽可能使用双引号："I'm Groot"）。

2. **检查清单状态**（如果 FEATURE_DIR/checklists/ 存在）：
   - 扫描 checklists/ 目录中的所有清单文件
   - 对于每个清单，计数：
     - 总行数：匹配 `- [ ]` 或 `- [X]` 或 `- [x]` 的所有行
     - 已完成项目：匹配 `- [X]` 或 `- [x]` 的行
     - 未完成项目：匹配 `- [ ]` 的行
   - 创建状态表：

     ```text
     | 清单 | 总计 | 已完成 | 未完成 | 状态 |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - 计算总体状态：
     - **通过**：所有清单都有 0 个未完成项目
     - **失败**：一个或多个清单有未完成项目

   - **如果任何清单未完成**：
     - 显示含未完成项目数的表格
     - **停止**并询问："一些清单未完成。是否无论如何继续实施？（是/否）"
     - 等待用户响应后再继续
     - 如果用户说"否"或"等待"或"停止"，停止执行
     - 如果用户说"是"或"继续"或"进行"，继续到第 3 步

   - **如果所有清单都完成**：
     - 显示显示所有清单都通过的表格
     - 自动继续到第 3 步

3. 加载并分析实现上下文：
   - **必需**：读取 tasks.md 以获取完整任务列表和执行计划
   - **必需**：读取 plan.md 以获取技术堆栈、架构和文件结构
   - **如果存在**：读取 data-model.md 以获取实体和关系
   - **如果存在**：读取 contracts/ 以获取 API 规格和测试需求
   - **如果存在**：读取 research.md 以获取技术决策和约束
   - **如果存在**：读取 quickstart.md 以获取集成场景

4. **项目设置验证**：
   - **必需**：根据实际项目设置创建/验证忽略文件：

   **检测和创建逻辑**：
   - 检查以下命令是否成功确定仓库是否为 git 仓库（如果是，则创建/验证 .gitignore）：

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - 检查 Dockerfile* 是否存在或 Docker 是否在 plan.md 中 → 创建/验证 .dockerignore
   - 检查 .eslintrc* 是否存在 → 创建/验证 .eslintignore
   - 检查 eslint.config.* 是否存在 → 确保配置的 `ignores` 条目覆盖所需模式
   - 检查 .prettierrc* 是否存在 → 创建/验证 .prettierignore
   - 检查 .npmrc 或 package.json 是否存在 → 创建/验证 .npmignore（如果发布）
   - 检查 terraform 文件 (*.tf) 是否存在 → 创建/验证 .terraformignore
   - 检查是否需要 .helmignore（helm 图表存在）→ 创建/验证 .helmignore

   **如果忽略文件已存在**：验证它包含基本模式，仅追加缺失的关键模式
   **如果忽略文件缺失**：用检测到的技术的完整模式集创建

   **按技术的常见模式**（来自 plan.md 技术堆栈）：
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
   - **任务阶段**：设置、测试、核心、集成、润色
   - **任务依赖关系**：顺序与并行执行规则
   - **任务细节**：ID、描述、文件路径、并行标记 [P]
   - **执行流程**：顺序和依赖要求

6. 按照任务计划执行实施：
   - **阶段执行**：在移动到下一个阶段之前完成每个阶段
   - **尊重依赖关系**：按顺序运行顺序任务，并行任务 [P] 可以一起运行
   - **遵循 TDD 方法**：在执行对应的实现任务之前执行测试任务
   - **基于文件的协调**：影响相同文件的任务必须顺序运行
   - **验证检查点**：在继续之前验证每个阶段完成

7. 实施执行规则：
   - **首先设置**：初始化项目结构、依赖项、配置
   - **代码前的测试**：如果需要为契约、实体和集成场景编写测试
   - **核心开发**：实现模型、服务、CLI 命令、端点
   - **集成工作**：数据库连接、中间件、日志记录、外部服务
   - **润色和验证**：单元测试、性能优化、文档

8. 进度跟踪和错误处理：
   - 在每次完成任务后报告进度
   - 如果任何非并行任务失败，停止执行
   - 对于并行任务 [P]，继续成功任务，报告失败任务
   - 为调试提供清晰的错误消息和上下文
   - 如果实施无法继续，建议下一步
   - **重要** 对于已完成的任务，确保在任务文件中将任务标记为 [X]。

9. 完成验证：
   - 验证所有必需任务都已完成
   - 检查已实现的功能是否与原始规格匹配
   - 验证测试通过且覆盖率符合要求
   - 确认实施遵循技术计划
   - 报告已完成工作的最终状态和摘要

注意：此命令假设 tasks.md 中存在完整的任务分解。如果任务不完整或缺失，建议先运行 `/speckit.tasks` 以重新生成任务列表。
