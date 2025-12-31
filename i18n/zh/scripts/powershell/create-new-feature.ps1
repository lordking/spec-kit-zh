#!/usr/bin/env pwsh
# 创建新特性
[CmdletBinding()]
param(
    [switch]$Json,
    [string]$ShortName,
    [int]$Number = 0,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

# 如果请求，显示帮助
if ($Help) {
    Write-Host "用法: ./create-new-feature.ps1 [-Json] [-ShortName <name>] [-Number N] <feature description>"
    Write-Host ""
    Write-Host "选项:"
    Write-Host "  -Json               以 JSON 格式输出"
    Write-Host "  -ShortName <name>   为分支提供自定义短名称（2-4 个单词）"
    Write-Host "  -Number N           手动指定分支号（覆盖自动检测）"
    Write-Host "  -Help               显示此帮助信息"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  ./create-new-feature.ps1 'Add user authentication system' -ShortName 'user-auth'"
    Write-Host "  ./create-new-feature.ps1 'Implement OAuth2 integration for API'"
    exit 0
}

# 检查是否提供了特性描述
if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "用法: ./create-new-feature.ps1 [-Json] [-ShortName <name>] <feature description>"
    exit 1
}

$featureDesc = ($FeatureDescription -join ' ').Trim()

# 解析存储库根目录。首选 git 信息（如果可用），但回退到
# 搜索存储库标记，以便工作流在使用 --no-git 初始化的存储库中仍然有效。
function Find-RepositoryRoot {
    param(
        [string]$StartDir,
        [string[]]$Markers = @('.git', '.specify')
    )
    $current = Resolve-Path $StartDir
    while ($true) {
        foreach ($marker in $Markers) {
            if (Test-Path (Join-Path $current $marker)) {
                return $current
            }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            # 到达文件系统根而未找到标记
            return $null
        }
        $current = $parent
    }
}

function Get-HighestNumberFromSpecs {
    param([string]$SpecsDir)
    
    $highest = 0
    if (Test-Path $SpecsDir) {
        Get-ChildItem -Path $SpecsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d+)') {
                $num = [int]$matches[1]
                if ($num -gt $highest) { $highest = $num }
            }
        }
    }
    return $highest
}

function Get-HighestNumberFromBranches {
    param()
    
    $highest = 0
    try {
        $branches = git branch -a 2>$null
        if ($LASTEXITCODE -eq 0) {
            foreach ($branch in $branches) {
                # 清理分支名：删除前导标记和远程前缀
                $cleanBranch = $branch.Trim() -replace '^\*?\s+', '' -replace '^remotes/[^/]+/', ''
                
                # 如果分支匹配模式 ###-* 则提取特性号
                if ($cleanBranch -match '^(\d+)-') {
                    $num = [int]$matches[1]
                    if ($num -gt $highest) { $highest = $num }
                }
            }
        }
    } catch {
        # 如果 git 命令失败，返回 0
        Write-Verbose "Could not check Git branches: $_"
    }
    return $highest
}

function Get-NextBranchNumber {
    param(
        [string]$SpecsDir
    )

    # 获取所有远程的最新分支信息（如果没有远程则抑制错误）
    try {
        git fetch --all --prune 2>$null | Out-Null
    } catch {
        # 忽略获取错误
    }

    # 从所有分支获取最高编号（不仅仅是匹配的短名称）
    $highestBranch = Get-HighestNumberFromBranches

    # 从所有 specs 获取最高编号（不仅仅是匹配的短名称）
    $highestSpec = Get-HighestNumberFromSpecs -SpecsDir $SpecsDir

    # 取两者的最大值
    $maxNum = [Math]::Max($highestBranch, $highestSpec)

    # 返回下一个编号
    return $maxNum + 1
}

function ConvertTo-CleanBranchName {
    param([string]$Name)
    
    return $Name.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
}
$fallbackRoot = (Find-RepositoryRoot -StartDir $PSScriptRoot)
if (-not $fallbackRoot) {
    Write-Error "错误：无法确定存储库根目录。请在存储库内运行此脚本。"
    exit 1
}

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        $hasGit = $true
    } else {
        throw "Git not available"
    }
} catch {
    $repoRoot = $fallbackRoot
    $hasGit = $false
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot 'specs'
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

# 通过停用词过滤和长度过滤生成分支名
function Get-BranchName {
    param([string]$Description)
    
    # 常见的停用词要过滤掉
    $stopWords = @(
        'i', 'a', 'an', 'the', 'to', 'for', 'of', 'in', 'on', 'at', 'by', 'with', 'from',
        'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
        'do', 'does', 'did', 'will', 'would', 'should', 'could', 'can', 'may', 'might', 'must', 'shall',
        'this', 'that', 'these', 'those', 'my', 'your', 'our', 'their',
        'want', 'need', 'add', 'get', 'set'
    )
    
    # 转换为小写并提取单词（仅字母数字）
    $cleanName = $Description.ToLower() -replace '[^a-z0-9\s]', ' '
    $words = $cleanName -split '\s+' | Where-Object { $_ }
    
    # 过滤单词：移除停用词和少于 3 个字符的单词（除非它们是原文中的大写首字母缩写）
    $meaningfulWords = @()
    foreach ($word in $words) {
        # 跳过停用词
        if ($stopWords -contains $word) { continue }
        
        # 保留长度 >= 3 或在原文中以大写出现的单词（可能是首字母缩写）
        if ($word.Length -ge 3) {
            $meaningfulWords += $word
        } elseif ($Description -match "\b$($word.ToUpper())\b") {
            # 如果短单词在原文中以大写形式出现则保留（可能是首字母缩写）
            $meaningfulWords += $word
        }
    }
    
    # 如果有有意义的单词，使用前 3-4 个
    if ($meaningfulWords.Count -gt 0) {
        $maxWords = if ($meaningfulWords.Count -eq 4) { 4 } else { 3 }
        $result = ($meaningfulWords | Select-Object -First $maxWords) -join '-'
        return $result
    } else {
        # 如果未找到有意义的单词则回退到原始逻辑
        $result = ConvertTo-CleanBranchName -Name $Description
        $fallbackWords = ($result -split '-') | Where-Object { $_ } | Select-Object -First 3
        return [string]::Join('-', $fallbackWords)
    }
}

# 生成分支名
if ($ShortName) {
    # 使用提供的短名称，只需清理它
    $branchSuffix = ConvertTo-CleanBranchName -Name $ShortName
} else {
    # 使用智能过滤从描述生成
    $branchSuffix = Get-BranchName -Description $featureDesc
}

# 确定分支号
if ($Number -eq 0) {
    if ($hasGit) {
        # 检查远程上的现有分支
        $Number = Get-NextBranchNumber -SpecsDir $specsDir
    } else {
        # 回退到本地目录检查
        $Number = (Get-HighestNumberFromSpecs -SpecsDir $specsDir) + 1
    }
}

$featureNum = ('{0:000}' -f $Number)
$branchName = "$featureNum-$branchSuffix"

# GitHub 强制执行分支名称的 244 字节限制
# 验证并在必要时截断
$maxBranchLength = 244
if ($branchName.Length -gt $maxBranchLength) {
    # 计算需要从后缀中修剪多少
    # 说明：特性号 (3) + 连字符 (1) = 4 个字符
    $maxSuffixLength = $maxBranchLength - 4
    
    # 截断后缀
    $truncatedSuffix = $branchSuffix.Substring(0, [Math]::Min($branchSuffix.Length, $maxSuffixLength))
    # 删除截断产生的尾部连字符
    $truncatedSuffix = $truncatedSuffix -replace '-$', ''
    
    $originalBranchName = $branchName
    $branchName = "$featureNum-$truncatedSuffix"
    
    Write-Warning "[specify] 分支名称超过了 GitHub 的 244 字节限制"
    Write-Warning "[specify] 原始：$originalBranchName ($($originalBranchName.Length) 字节)"
    Write-Warning "[specify] 截断为：$branchName ($($branchName.Length) 字节)"
}

if ($hasGit) {
    try {
        git checkout -b $branchName | Out-Null
    } catch {
        Write-Warning "未能创建 git 分支：$branchName"
    }
} else {
    Write-Warning "[specify] 警告：未检测到 Git 存储库；跳过了对 $branchName 的分支创建"
}

$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

$template = Join-Path $repoRoot '.specify/templates/spec-template.md'
$specFile = Join-Path $featureDir 'spec.md'
if (Test-Path $template) { 
    Copy-Item $template $specFile -Force 
} else { 
    New-Item -ItemType File -Path $specFile | Out-Null 
}

# 为当前会话设置 SPECIFY_FEATURE 环境变量
$env:SPECIFY_FEATURE = $branchName

if ($Json) {
    $obj = [PSCustomObject]@{ 
        BRANCH_NAME = $branchName
        SPEC_FILE = $specFile
        FEATURE_NUM = $featureNum
        HAS_GIT = $hasGit
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "分支名称：$branchName"
    Write-Output "规格文件：$specFile"
    Write-Output "特性号：$featureNum"
    Write-Output "包含 Git：$hasGit"
    Write-Output "SPECIFY_FEATURE 环境变量已设置为：$branchName"
}

