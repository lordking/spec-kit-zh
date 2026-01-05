---
description: 使用计划模板执行计划工作流，以生成设计工件。
handoffs:
  - label: 创建任务
    agent: speckit.tasks
    prompt: 将计划分解为任务
    send: true
  - label: 创建清单
    agent: speckit.checklist
    prompt: 为以下领域创建清单...
scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，你必须考虑用户输入（如果不为空）。

## 大纲

1. **设置**：从仓库根目录运行 `{SCRIPT}` 并解析 FEATURE_SPEC、IMPL_PLAN、SPECS_DIR、BRANCH 的 JSON。对于参数中的单引号，如 "I'm Groot"，使用转义语法：例如 'I'\''m Groot'（或尽可能使用双引号："I'm Groot"）。

2. **加载上下文**：读取 FEATURE_SPEC 和 `/memory/constitution.md`，加载 IMPL_PLAN 模板（已复制）。

3. **执行计划工作流**：遵循 IMPL_PLAN 模板的结构：
   - 填写技术上下文（将未知项标记为"需要澄清"）
   - 从宪章文件填写宪章检查章节
   - 评估门禁（如果违规且没有合理说明的项标记为ERROR）
   - 阶段 0：生成 research.md（解决所有需要澄清的项）
   - 阶段 1：生成 data-model.md、contracts/、quickstart.md
   - 阶段 1：通过运行代理脚本更新代理上下文
   - 设计完成后重新评估“宪章检查”

4. **停止并报告**：命令在阶段 2 计划结束后停止。报告分支、IMPL_PLAN 路径和生成的工件。

## 阶段

### 阶段 0：大纲和研究

1. **从技术上下文中提取未知项**：
   - 每个"需要澄清"项 → 研究任务
   - 每个依赖项 → 最佳实践任务
   - 每个集成 → 模式任务

2. **生成并分派研究代理**：

   ```text
   技术上下文中的每个未知项：
     任务："为{功能上下文}研究{未知项}"
   每个技术选择：
     任务："为{领域}的{技术}查找最佳实践"
   ```

3. 在`research.md` 中整合发现，使用如下格式：
   - 决策：[选择了什么]
   - 理由：[为什么选择]
   - 考虑的备选方案：[还需要评估哪些]

**输出**：包含所有“需要澄清”项已解决的 research.md

### 阶段 1：设计和契约

**先决条件**：`research.md` 已完成

1. **从功能规格提取实体** → `data-model.md`：
   - 实体名称、字段、关系
   - 来自需求的验证规则
   - 状态转换（如需要）

2. **从功能需求生成 API 契约**：
   - 对于每个用户行动 → 端点
   - 使用标准 REST/GraphQL 模式
   - 输出 OpenAPI/GraphQL 模式的定义到 `/contracts/`

3. **代理上下文更新**：
   - 运行 `{AGENT_SCRIPT}`
   - 这些脚本检测正在使用哪个 AI 代理
   - 更新代理指定的上下文文件
   - 仅从当前计划添加新技术
   - 保留标记之间手工添加的内容

**输出**：data-model.md、/contracts/*、quickstart.md、代理指定的上下文文件

## 关键规则

- 使用绝对路径
- 门禁失败或未解决的澄清时出错
