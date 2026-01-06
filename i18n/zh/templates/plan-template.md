# 实现计划：[功能名称]

**分支**：`[###-feature-name]` | **日期**：[日期] | **规格**：[链接]
**输入**：来自 `/specs/[###-feature-name]/spec.md` 的功能规格

**注意**：此模板由 `/speckit.plan` 命令填写。有关执行工作流，请参见 `.specify/templates/commands/plan.md`。

## 摘要

[从功能规格中提取：主要需求 + 来自研究的技术方案]

## 技术上下文

<!--
  需要行动：用项目的技术细节替换本节中的内容
  此处的结构以顾问身份呈现，以指导迭代过程。
-->

**语言/版本**：[例如，Python 3.11、Swift 5.9、Rust 1.75 或需要澄清]
**主要依赖项**：[例如，FastAPI、UIKit、LLVM 或需要澄清]
**存储**：[如果适用，例如，PostgreSQL、CoreData、文件或 N/A]
**测试**：[例如，pytest、XCTest、cargo test 或需要澄清]
**目标平台**：[例如，Linux 服务器、iOS 15+、WASM 或需要澄清]
**项目类型**：[单项目/网页/移动 - 确定源结构]
**性能目标**：[特定于领域，例如，1000 req/s、10k 行/秒、60 fps 或需要澄清]
**约束**：[特定于领域，例如，<200ms p95、<100MB 内存、支持离线或需要澄清]
**规模/范围**：[特定于领域，例如，10k 用户、1M LOC、50 屏幕或需要澄清]

## 宪章检查

*门禁：必须在阶段 0 研究前通过，阶段 1 设计后重新检查。*

[根据宪章文件确定的门禁]

## 项目结构

### 文档（此功能）

```text
specs/[###-feature]/
├── plan.md              # 此文件（/speckit.plan 命令输出）
├── research.md          # 阶段 0 输出（/speckit.plan 命令）
├── data-model.md        # 阶段 1 输出（/speckit.plan 命令）
├── quickstart.md        # 阶段 1 输出（/speckit.plan 命令）
├── contracts/           # 阶段 1 输出（/speckit.plan 命令）
└── tasks.md             # 阶段 2 输出（/speckit.tasks 命令 - 不是由 /speckit.plan 创建）
```

### 源代码（仓库根目录）

<!--
  需要行动：用此功能的具体布局替换下面的占位符树。删除未使用的选项，
  并用真实路径展开所选结构（例如，apps/admin、packages/something）。
  交付的计划不得包含选项标签。
-->

```text
# [如未使用则删除] 选项 1：单体项目（默认）
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [如未使用则删除] 选项 2：Web 应用程序（当检测到“前端”+“后端”）
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [如未使用则删除] 选项 3：移动应用 + API 服务（当检测到“iOS/Android”）
api/
└── [与以上提到的后端结构相同]

ios/ 或 android/
└── [平台特定结构：功能模块、UI 流程、平台测试]
```

**项目结构决策**：[记录所选结构并引用上面捕获的真实目录]

## 复杂性跟踪

> **仅在宪法检查有违规时填写，必须说明原因**

| 违规 | 为什么需要 | 更简单的替代方案被拒绝的原因 |
|-----------|------------|-------------------------------------|
| [例如，第 4 个项目] | [当前需求] | [为什么 3 个项目不够] |
| [例如，仓库模式] | [具体问题] | [为什么不能直接访问数据库] |
