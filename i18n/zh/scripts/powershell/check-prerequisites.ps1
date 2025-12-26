#!/usr/bin/env pwsh

# 统一的先决条件检查脚本 (PowerShell)
#
# 此脚本为规格驱动开发工作流程提供统一的先决条件检查。
# 它替代了之前分散在多个脚本中的功能。
#
# 用法: ./check-prerequisites.ps1 [选项]
#
# 选项:
#   -Json               以 JSON 格式输出
#   -RequireTasks       要求 tasks.md 存在（用于实现阶段）
#   -IncludeTasks       在 AVAILABLE_DOCS 列表中包含 tasks.md
#   -PathsOnly          仅输出路径变量（无验证）
#   -Help, -h           显示帮助信息

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$IncludeTasks,
    [switch]$PathsOnly,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
用法: check-prerequisites.ps1 [选项]

为规格驱动开发工作流程进行统一的先决条件检查。

选项:
  -Json               以 JSON 格式输出
  -RequireTasks       要求 tasks.md 存在（用于实现阶段）
  -IncludeTasks       在 AVAILABLE_DOCS 列表中包含 tasks.md
  -PathsOnly          仅输出路径变量（无先决条件验证）
  -Help, -h           显示此帮助信息

示例:
  # 检查任务先决条件（需要 plan.md）
  .\check-prerequisites.ps1 -Json
  
  # 检查实现先决条件（需要 plan.md + tasks.md）
  .\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
  
  # 仅获取功能路径（无验证）
  .\check-prerequisites.ps1 -PathsOnly

"@
    exit 0
}

# 引入通用函数
. "$PSScriptRoot/common.ps1"

# 获取功能路径并验证分支
$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) { 
    exit 1 
}

# 如果仅路径模式，输出路径并退出（支持组合 -Json -PathsOnly）
if ($PathsOnly) {
    if ($Json) {
        [PSCustomObject]@{
            REPO_ROOT    = $paths.REPO_ROOT
            BRANCH       = $paths.CURRENT_BRANCH
            FEATURE_DIR  = $paths.FEATURE_DIR
            FEATURE_SPEC = $paths.FEATURE_SPEC
            IMPL_PLAN    = $paths.IMPL_PLAN
            TASKS        = $paths.TASKS
        } | ConvertTo-Json -Compress
    } else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
        Write-Output "TASKS: $($paths.TASKS)"
    }
    exit 0
}

# 验证必需的目录和文件
if (-not (Test-Path $paths.FEATURE_DIR -PathType Container)) {
    Write-Output "错误: 找不到功能目录: $($paths.FEATURE_DIR)"
    Write-Output "首先运行 /speckit.specify 来创建功能结构。"
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Output "错误: 在 $($paths.FEATURE_DIR) 中找不到 plan.md"
    Write-Output "首先运行 /speckit.plan 来创建实现计划。"
    exit 1
}

# 如果需要，检查 tasks.md
if ($RequireTasks -and -not (Test-Path $paths.TASKS -PathType Leaf)) {
    Write-Output "错误: 在 $($paths.FEATURE_DIR) 中找不到 tasks.md"
    Write-Output "首先运行 /speckit.tasks 来创建任务列表。"
    exit 1
}

# 构建可用文档列表
$docs = @()

# 始终检查这些可选文档
if (Test-Path $paths.RESEARCH) { $docs += 'research.md' }
if (Test-Path $paths.DATA_MODEL) { $docs += 'data-model.md' }

# 检查合同目录（仅在存在且有文件时）
if ((Test-Path $paths.CONTRACTS_DIR) -and (Get-ChildItem -Path $paths.CONTRACTS_DIR -ErrorAction SilentlyContinue | Select-Object -First 1)) { 
    $docs += 'contracts/' 
}

if (Test-Path $paths.QUICKSTART) { $docs += 'quickstart.md' }

# 如果请求并且存在，包含 tasks.md
if ($IncludeTasks -and (Test-Path $paths.TASKS)) { 
    $docs += 'tasks.md' 
}

# 输出结果
if ($Json) {
    # JSON 输出
    [PSCustomObject]@{ 
        FEATURE_DIR = $paths.FEATURE_DIR
        AVAILABLE_DOCS = $docs 
    } | ConvertTo-Json -Compress
} else {
    # 文本输出
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output "AVAILABLE_DOCS:"
    
    # 显示每个潜在文档的状态
    Test-FileExists -Path $paths.RESEARCH -Description 'research.md' | Out-Null
    Test-FileExists -Path $paths.DATA_MODEL -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path $paths.CONTRACTS_DIR -Description 'contracts/' | Out-Null
    Test-FileExists -Path $paths.QUICKSTART -Description 'quickstart.md' | Out-Null
    
    if ($IncludeTasks) {
        Test-FileExists -Path $paths.TASKS -Description 'tasks.md' | Out-Null
    }
}
