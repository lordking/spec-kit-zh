#!/usr/bin/env pwsh
# 创建新功能
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
    Write-Host "  ./create-new-feature.ps1 '添加用户认证系统' -ShortName '用户认证'"
    Write-Host "  ./create-new-feature.ps1 '通过 API 集成 OAuth2'"
    exit 0
}

# 检查是否提供了功能描述
if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "用法: ./create-new-feature.ps1 [-Json] [-ShortName <name>] <feature description>"
    exit 1
}

$featureDesc = ($FeatureDescription -join ' ').Trim()

# 解析存储库根目录。优先使用 git 信息，但可以回退
# 到搜索存储库标记，以便工作流在使用 --no-git 初始化的存储库中仍然有效。
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
            # 已到达文件系统根目录而未找到标记
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
                # 清理分支名称：删除前导标记和远程前缀
                $cleanBranch = $branch.Trim() -replace '^\*?\s+', '' -replace '^remotes/[^/]+/', ''
                
                # 如果分支符合 ###-* 模式，提取功能号
                if ($cleanBranch -match '^(\d+)-') {
                    $num = [int]$matches[1]
                    if ($num -gt $highest) { $highest = $num }
                }
            }
        }
    } catch {
        # 如果 git 命令失败，返回 0
        Write-Verbose "无法检查 Git 分支: $_"
    }
    return $highest
}

function Get-NextBranchNumber {
    param(
        [string]$SpecsDir
    )

    # 获取所有远程以获得最新分支信息（如果没有远程，则忽略错误）
    try {
        git fetch --all --prune 2>$null | Out-Null
    } catch {
        # 忽略获取错误
    }

    # 从所有分支获取最高号码（不仅仅是匹配的短名称）
    $highestBranch = Get-HighestNumberFromBranches

    # 从所有 specs 获取最高号码（不仅仅是匹配的短名称）
    $highestSpec = Get-HighestNumberFromSpecs -SpecsDir $SpecsDir

    # 取两者中的最大值
    $maxNum = [Math]::Max($highestBranch, $highestSpec)

    # 返回下一个号码
    return $maxNum + 1
}

function ConvertTo-CleanBranchName {
    param([string]$Name)
    
    # 分支名称支持任何语言的字符和数字
    return $Name.ToLower() -replace '[^\p{L}\p{N}]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
}
$fallbackRoot = (Find-RepositoryRoot -StartDir $PSScriptRoot)
if (-not $fallbackRoot) {
    Write-Error "错误: 无法确定存储库根目录。请从存储库内运行此脚本。"
    exit 1
}

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        $hasGit = $true
    } else {
        throw "Git 不可用"
    }
} catch {
    $repoRoot = $fallbackRoot
    $hasGit = $false
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot 'specs'
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

# 使用停用词过滤和长度过滤生成分支名称的函数
function Get-BranchName {
    param([string]$Description)
    
    # 要过滤的常见停用词（英文和中文）
    $stopWords = @(
        'i', 'a', 'an', 'the', 'to', 'for', 'of', 'in', 'on', 'at', 'by', 'with', 'from',
        'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
        'do', 'does', 'did', 'will', 'would', 'should', 'could', 'can', 'may', 'might', 'must', 'shall',
        'this', 'that', 'these', 'those', 'my', 'your', 'our', 'their',
        'want', 'need', 'add', 'get', 'set',
        '一个', '的', '在', '和', '是', '我', '有', '这', '了', '为', '到', '与', '将', '可以'
    )
    
    # 提取单词：使用 Unicode 字符类匹配单词字符（支持中文）
    # 将标点和特殊字符替换为空格
    $cleanName = $Description -replace '[^\p{L}\p{N}\s]', ' '
    $words = $cleanName -split '\s+' | Where-Object { $_ }
    
    # 过滤单词：删除停用词和短于 2 个字符的单词
    $meaningfulWords = @()
    foreach ($word in $words) {
        # 跳过停用词（不区分大小写）
        if ($stopWords -contains $word.ToLower()) { continue }
        
        # 保留长度 >= 2 的单词（中文字符通常更短但更有意义）
        if ($word.Length -ge 2) {
            $meaningfulWords += $word
        } elseif ($Description -match "\b$($word.ToUpper())\b") {
            # 如果短单词在原始文本中显示为大写，则保留它（可能是首字母缩略词）
            $meaningfulWords += $word
        }
    }
    
    # 如果有有意义的单词，使用其中前 3-4 个
    if ($meaningfulWords.Count -gt 0) {
        $maxWords = if ($meaningfulWords.Count -eq 4) { 4 } else { 3 }
        $result = ($meaningfulWords | Select-Object -First $maxWords) -join '-'
        return ConvertTo-CleanBranchName -Name $result
    } else {
        # 如果未找到有意义的单词，回退到原始逻辑
        $result = ConvertTo-CleanBranchName -Name $Description
        $fallbackWords = ($result -split '-') | Where-Object { $_ } | Select-Object -First 3
        return [string]::Join('-', $fallbackWords)
    }
}

# 生成分支名称
if ($ShortName) {
    # 使用提供的短名称，只需清理一下
    $branchSuffix = ConvertTo-CleanBranchName -Name $ShortName
} else {
    # 从描述生成，使用智能过滤
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

# GitHub 对分支名称强制实施 244 字节的限制
# 验证并在必要时截断
$maxBranchLength = 244
if ($branchName.Length -gt $maxBranchLength) {
    # 计算需要从后缀中删除多少
    # 占用: 功能号 (3) + 连字符 (1) = 4 个字符
    $maxSuffixLength = $maxBranchLength - 4
    
    # 截断后缀
    $truncatedSuffix = $branchSuffix.Substring(0, [Math]::Min($branchSuffix.Length, $maxSuffixLength))
    # 如果截断创建了尾随连字符，则删除它
    $truncatedSuffix = $truncatedSuffix -replace '-$', ''
    
    $originalBranchName = $branchName
    $branchName = "$featureNum-$truncatedSuffix"
    
    Write-Warning "[specify] 分支名称超过了 GitHub 的 244 字节限制"
    Write-Warning "[specify] 原始: $originalBranchName ($($originalBranchName.Length) 字节)"
    Write-Warning "[specify] 截断至: $branchName ($($branchName.Length) 字节)"
}

if ($hasGit) {
    try {
        git checkout -b $branchName | Out-Null
    } catch {
        Write-Warning "创建 git 分支失败: $branchName"
    }
} else {
    Write-Warning "[specify] 警告: 未检测到 Git 存储库；已跳过创建分支 $branchName"
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
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "SPECIFY_FEATURE 环境变量已设置为: $branchName"
}

