#!/usr/bin/env pwsh
#requires -Version 7.0

<#
.SYNOPSIS
    为每个支持的AI助手和脚本类型构建Spec Kit模板发布存档。

.DESCRIPTION
    create-release-packages.zh.ps1 (workflow-local)
    为每个支持的AI助手和脚本类型构建Spec Kit模板发布存档。
    从中文本地化模板读取（i18n/zh/）。
    
.PARAMETER Version
    版本字符串，以'zh-v'开头（例如，zh-v0.2.0）

.PARAMETER Agents
    逗号或空格分隔的代理子集（默认：全部）
    有效的代理：claude, gemini, copilot, cursor-agent, qwen, opencode, windsurf, codex, kilocode, auggie, roo, codebuddy, amp, q, bob, qoder

.PARAMETER Scripts
    逗号或空格分隔的脚本类型子集（默认：两者）
    有效的脚本：sh, ps

.EXAMPLE
    .\create-release-packages.zh.ps1 -Version zh-v0.2.0

.EXAMPLE
    .\create-release-packages.zh.ps1 -Version zh-v0.2.0 -Agents claude,copilot -Scripts sh

.EXAMPLE
    .\create-release-packages.zh.ps1 -Version zh-v0.2.0 -Agents claude -Scripts ps
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Agents = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Scripts = ""
)

$ErrorActionPreference = "Stop"

# 保存参数值到本地变量
$InputAgents = $Agents
$InputScripts = $Scripts

# 验证版本格式
if ($Version -notmatch '^zh-v\d+\.\d+\.\d+$') {
    Write-Error "版本必须看起来像 zh-v0.0.0"
    exit 1
}

Write-Host "为 $Version 构建发布包（中文本地化）"

# 为所有构建成品创建并使用 .genreleases-zh 目录
$GenReleasesDir = ".genreleases-zh"
if (Test-Path $GenReleasesDir) {
    Remove-Item -Path $GenReleasesDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $GenReleasesDir -Force | Out-Null

function Rewrite-Paths {
    param([string]$Content)
    
    $Content = $Content -replace '(/?)\bmemory/', '.specify/memory/'
    $Content = $Content -replace '(/?)\bscripts/', '.specify/scripts/'
    $Content = $Content -replace '(/?)\btemplates/', '.specify/templates/'
    return $Content
}

function Generate-Commands {
    param(
        [string]$Agent,
        [string]$Extension,
        [string]$ArgFormat,
        [string]$OutputDir,
        [string]$ScriptVariant
    )
    
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    
    # 从中文本地化模板读取
    $templates = Get-ChildItem -Path "i18n/zh/templates/commands/*.md" -File -ErrorAction SilentlyContinue
    
    foreach ($template in $templates) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($template.Name)
        
        # 读取文件内容并规范化行尾
        $fileContent = (Get-Content -Path $template.FullName -Raw) -replace "`r`n", "`n"
        
        # 从YAML前言中提取描述
        $description = ""
        if ($fileContent -match '(?m)^description:\s*(.+)$') {
            $description = $matches[1]
        }
        
        # 从YAML前言中提取脚本命令
        $scriptCommand = ""
        if ($fileContent -match "(?m)^\s*${ScriptVariant}:\s*(.+)$") {
            $scriptCommand = $matches[1]
        }
        
        if ([string]::IsNullOrEmpty($scriptCommand)) {
            Write-Warning "在 $($template.Name) 中找不到 $ScriptVariant 的脚本命令"
            $scriptCommand = "(缺少 $ScriptVariant 的脚本命令)"
        }
        
        # 如果存在，从YAML前言中提取代理脚本命令
        $agentScriptCommand = ""
        if ($fileContent -match "(?ms)agent_scripts:.*?^\s*${ScriptVariant}:\s*(.+?)$") {
            $agentScriptCommand = $matches[1].Trim()
        }
        
        # 用脚本命令替换 {SCRIPT} 占位符
        $body = $fileContent -replace '\{SCRIPT\}', $scriptCommand
        
        # 如果找到代理脚本命令，用其替换 {AGENT_SCRIPT} 占位符
        if (-not [string]::IsNullOrEmpty($agentScriptCommand)) {
            $body = $body -replace '\{AGENT_SCRIPT\}', $agentScriptCommand
        }
        
        # 从前言中删除 scripts: 和 agent_scripts: 部分
        $lines = $body -split "`n"
        $outputLines = @()
        $inFrontmatter = $false
        $skipScripts = $false
        $dashCount = 0
        
        foreach ($line in $lines) {
            if ($line -match '^---$') {
                $outputLines += $line
                $dashCount++
                if ($dashCount -eq 1) {
                    $inFrontmatter = $true
                } else {
                    $inFrontmatter = $false
                }
                continue
            }
            
            if ($inFrontmatter) {
                if ($line -match '^(scripts|agent_scripts):$') {
                    $skipScripts = $true
                    continue
                }
                if ($line -match '^[a-zA-Z].*:' -and $skipScripts) {
                    $skipScripts = $false
                }
                if ($skipScripts -and $line -match '^\s+') {
                    continue
                }
            }
            
            $outputLines += $line
        }
        
        $body = $outputLines -join "`n"
        
        # 应用其他替换
        $body = $body -replace '\{ARGS\}', $ArgFormat
        $body = $body -replace '__AGENT__', $Agent
        $body = Rewrite-Paths -Content $body
        
        # 根据扩展名生成输出文件
        $outputFile = Join-Path $OutputDir "speckit.$name.$Extension"
        
        switch ($Extension) {
            'toml' {
                $body = $body -replace '\\', '\\'
                $output = "description = `"$description`"`n`nprompt = `"`"`"`n$body`n`"`"`""
                Set-Content -Path $outputFile -Value $output -NoNewline
            }
            'md' {
                Set-Content -Path $outputFile -Value $body -NoNewline
            }
            'agent.md' {
                Set-Content -Path $outputFile -Value $body -NoNewline
            }
        }
    }
}

function Generate-CopilotPrompts {
    param(
        [string]$AgentsDir,
        [string]$PromptsDir
    )
    
    New-Item -ItemType Directory -Path $PromptsDir -Force | Out-Null
    
    $agentFiles = Get-ChildItem -Path "$AgentsDir/speckit.*.agent.md" -File -ErrorAction SilentlyContinue
    
    foreach ($agentFile in $agentFiles) {
        $basename = $agentFile.Name -replace '\.agent\.md$', ''
        $promptFile = Join-Path $PromptsDir "$basename.prompt.md"
        
        $content = @"
---
agent: $basename
---
"@
        Set-Content -Path $promptFile -Value $content
    }
}

function Build-Variant {
    param(
        [string]$Agent,
        [string]$Script
    )
    
    $baseDir = Join-Path $GenReleasesDir "sdd-${Agent}-package-${Script}"
    Write-Host "正在构建 $Agent ($Script) 包..."
    New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
    
    # 复制基础结构，但按变体过滤脚本
    $specDir = Join-Path $baseDir ".specify"
    New-Item -ItemType Directory -Path $specDir -Force | Out-Null
    
    # 从中文本地化复制内存目录
    if (Test-Path "i18n/zh/memory") {
        Copy-Item -Path "i18n/zh/memory" -Destination $specDir -Recurse -Force
        Write-Host "已复制 i18n/zh/memory -> .specify"
    }
    
    # 仅复制相关的脚本变体目录
    if (Test-Path "i18n/zh/scripts") {
        $scriptsDestDir = Join-Path $specDir "scripts"
        New-Item -ItemType Directory -Path $scriptsDestDir -Force | Out-Null
        
        switch ($Script) {
            'sh' {
                if (Test-Path "i18n/zh/scripts/bash") {
                    Copy-Item -Path "i18n/zh/scripts/bash" -Destination $scriptsDestDir -Recurse -Force
                    Write-Host "已复制 i18n/zh/scripts/bash -> .specify/scripts"
                }
            }
            'ps' {
                if (Test-Path "i18n/zh/scripts/powershell") {
                    Copy-Item -Path "i18n/zh/scripts/powershell" -Destination $scriptsDestDir -Recurse -Force
                    Write-Host "已复制 i18n/zh/scripts/powershell -> .specify/scripts"
                }
            }
        }
        
        # 复制不在变体特定目录中的任何脚本文件
        Get-ChildItem -Path "i18n/zh/scripts" -File -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $scriptsDestDir -Force
        }
    }
    
    # 从中文本地化复制模板（不含commands目录和vscode-settings.json）
    if (Test-Path "i18n/zh/templates") {
        $templatesDestDir = Join-Path $specDir "templates"
        New-Item -ItemType Directory -Path $templatesDestDir -Force | Out-Null
        
        Get-ChildItem -Path "i18n/zh/templates" -Recurse -File | Where-Object {
            $_.FullName -notmatch 'templates[/\\]commands[/\\]' -and $_.Name -ne 'vscode-settings.json'
        } | ForEach-Object {
            $relativePath = $_.FullName.Substring((Resolve-Path "i18n/zh/templates").Path.Length + 1)
            $destFile = Join-Path $templatesDestDir $relativePath
            $destFileDir = Split-Path $destFile -Parent
            New-Item -ItemType Directory -Path $destFileDir -Force | Out-Null
            Copy-Item -Path $_.FullName -Destination $destFile -Force
        }
        Write-Host "已复制 i18n/zh/templates -> .specify/templates"
    }
    
    # 生成代理特定的命令文件
    switch ($Agent) {
        'claude' {
            $cmdDir = Join-Path $baseDir ".claude/commands"
            Generate-Commands -Agent 'claude' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'gemini' {
            $cmdDir = Join-Path $baseDir ".gemini/commands"
            Generate-Commands -Agent 'gemini' -Extension 'toml' -ArgFormat '{{args}}' -OutputDir $cmdDir -ScriptVariant $Script
            if (Test-Path "agent_templates/gemini/GEMINI.md") {
                Copy-Item -Path "agent_templates/gemini/GEMINI.md" -Destination (Join-Path $baseDir "GEMINI.md")
            }
        }
        'copilot' {
            $agentsDir = Join-Path $baseDir ".github/agents"
            Generate-Commands -Agent 'copilot' -Extension 'agent.md' -ArgFormat '$ARGUMENTS' -OutputDir $agentsDir -ScriptVariant $Script
            
            # 生成配套提示文件
            $promptsDir = Join-Path $baseDir ".github/prompts"
            Generate-CopilotPrompts -AgentsDir $agentsDir -PromptsDir $promptsDir
            
            # 创建 VS Code 工作空间设置
            $vscodeDir = Join-Path $baseDir ".vscode"
            New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
            if (Test-Path "i18n/zh/templates/vscode-settings.json") {
                Copy-Item -Path "i18n/zh/templates/vscode-settings.json" -Destination (Join-Path $vscodeDir "settings.json")
            }
        }
        'cursor-agent' {
            $cmdDir = Join-Path $baseDir ".cursor/commands"
            Generate-Commands -Agent 'cursor-agent' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'qwen' {
            $cmdDir = Join-Path $baseDir ".qwen/commands"
            Generate-Commands -Agent 'qwen' -Extension 'toml' -ArgFormat '{{args}}' -OutputDir $cmdDir -ScriptVariant $Script
            if (Test-Path "agent_templates/qwen/QWEN.md") {
                Copy-Item -Path "agent_templates/qwen/QWEN.md" -Destination (Join-Path $baseDir "QWEN.md")
            }
        }
        'opencode' {
            $cmdDir = Join-Path $baseDir ".opencode/command"
            Generate-Commands -Agent 'opencode' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'windsurf' {
            $cmdDir = Join-Path $baseDir ".windsurf/workflows"
            Generate-Commands -Agent 'windsurf' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'codex' {
            $cmdDir = Join-Path $baseDir ".codex/prompts"
            Generate-Commands -Agent 'codex' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'kilocode' {
            $cmdDir = Join-Path $baseDir ".kilocode/workflows"
            Generate-Commands -Agent 'kilocode' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'auggie' {
            $cmdDir = Join-Path $baseDir ".augment/commands"
            Generate-Commands -Agent 'auggie' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'roo' {
            $cmdDir = Join-Path $baseDir ".roo/commands"
            Generate-Commands -Agent 'roo' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'codebuddy' {
            $cmdDir = Join-Path $baseDir ".codebuddy/commands"
            Generate-Commands -Agent 'codebuddy' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'amp' {
            $cmdDir = Join-Path $baseDir ".agents/commands"
            Generate-Commands -Agent 'amp' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'q' {
            $cmdDir = Join-Path $baseDir ".amazonq/prompts"
            Generate-Commands -Agent 'q' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'bob' {
            $cmdDir = Join-Path $baseDir ".bob/commands"
            Generate-Commands -Agent 'bob' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
        'qoder' {
            $cmdDir = Join-Path $baseDir ".qoder/commands"
            Generate-Commands -Agent 'qoder' -Extension 'md' -ArgFormat '$ARGUMENTS' -OutputDir $cmdDir -ScriptVariant $Script
        }
    }
    
    # 创建 zip 存档
    $zipFile = Join-Path $GenReleasesDir "spec-kit-${Agent}-${Script}-${Version}.zip"
    Compress-Archive -Path "$baseDir/*" -DestinationPath $zipFile -Force
    Write-Host "已创建 $zipFile"
}

# 定义所有代理和脚本
$AllAgents = @('claude', 'gemini', 'copilot', 'cursor-agent', 'qwen', 'opencode', 'windsurf', 'codex', 'kilocode', 'auggie', 'roo', 'codebuddy', 'amp', 'q', 'bob', 'qoder')
$AllScripts = @('sh', 'ps')

function Normalize-List {
    param([string]$ListString)
    
    if ([string]::IsNullOrEmpty($ListString)) {
        return @()
    }
    
    # 按逗号或空格分割，删除重复项并保留顺序
    $items = $ListString -split '[,\s]+' | Where-Object { $_ } | Select-Object -Unique
    return $items
}

function Validate-Subset {
    param(
        [string]$Type,
        [string[]]$Allowed,
        [string[]]$Items
    )
    
    $ok = $true
    foreach ($item in $Items) {
        if ($item -notin $Allowed) {
            Write-Error "未知的 $Type '$item'（允许的值：$($Allowed -join ', ')）"
            $ok = $false
        }
    }
    return @($ok)
}

# 确定代理列表
if (-not [string]::IsNullOrEmpty($InputAgents)) {
    [string[]]$AgentList = @(Normalize-List -ListString $InputAgents)
    if (-not (Validate-Subset -Type 'agent' -Allowed $AllAgents -Items $AgentList)) {
        exit 1
    }
} else {
    [string[]]$AgentList = @($AllAgents)
}

# 确定脚本列表
if (-not [string]::IsNullOrEmpty($InputScripts)) {
    [string[]]$ScriptList = @(Normalize-List -ListString $InputScripts)
    if (-not (Validate-Subset -Type 'script' -Allowed $AllScripts -Items $ScriptList)) {
        exit 1
    }
} else {
    [string[]]$ScriptList = @($AllScripts)
}

Write-Host "代理：$($AgentList -join ', ')"
Write-Host "脚本：$($ScriptList -join ', ')"

# 构建所有变体
foreach ($agent in $AgentList) {
    foreach ($script in $ScriptList) {
        Build-Variant -Agent $agent -Script $script
    }
}

Write-Host "`n${GenReleasesDir} 中的中文存档："
Get-ChildItem -Path $GenReleasesDir -Filter "spec-kit-template-*-${Version}.zip" | ForEach-Object {
    Write-Host "  $($_.Name)"
}
