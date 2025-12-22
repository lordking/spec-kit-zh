#!/usr/bin/env pwsh
# 为功能设置实现计划

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# 如果请求，显示帮助
if ($Help) {
    Write-Output "用法: ./setup-plan.ps1 [-Json] [-Help]"
    Write-Output "  -Json     以 JSON 格式输出结果"
    Write-Output "  -Help     显示此帮助信息"
    exit 0
}

# 加载通用函数
. "$PSScriptRoot/common.ps1"

# 从通用函数获取所有路径和变量
$paths = Get-FeaturePathsEnv

# 检查我们是否在正确的功能分支上（仅对 git 仓库）
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) { 
    exit 1 
}

# 确保功能目录存在
New-Item -ItemType Directory -Path $paths.FEATURE_DIR -Force | Out-Null

# 如果存在，复制计划模板，否则记录或创建空文件
$template = Join-Path $paths.REPO_ROOT '.specify/templates/plan-template.md'
if (Test-Path $template) { 
    Copy-Item $template $paths.IMPL_PLAN -Force
    Write-Output "已将计划模板复制到 $($paths.IMPL_PLAN)"
} else {
    Write-Warning "在 $template 未找到计划模板"
    # 如果模板不存在，创建基本计划文件
    New-Item -ItemType File -Path $paths.IMPL_PLAN -Force | Out-Null
}

# 输出结果
if ($Json) {
    $result = [PSCustomObject]@{ 
        FEATURE_SPEC = $paths.FEATURE_SPEC
        IMPL_PLAN = $paths.IMPL_PLAN
        SPECS_DIR = $paths.FEATURE_DIR
        BRANCH = $paths.CURRENT_BRANCH
        HAS_GIT = $paths.HAS_GIT
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
    Write-Output "SPECS_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
}
