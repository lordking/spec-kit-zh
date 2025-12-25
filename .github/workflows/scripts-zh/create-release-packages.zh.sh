#!/usr/bin/env bash
set -euo pipefail

# create-release-packages.zh.sh (workflow-local)
# 为每个支持的 AI 助手与脚本类型构建 Spec Kit 模板发布归档（中文本地化）。
# 用法: .github/workflows/scripts/create-release-packages.zh.sh <版本>
#   版本参数需包含前缀 'v'。
#   可选地通过环境变量 AGENTS 与/或 SCRIPTS 限定构建子集：
#     AGENTS  : 以空格或逗号分隔的代理子集（默认：全部）：claude gemini copilot cursor-agent qwen opencode windsurf codex kilocode auggie roo codebuddy amp q bob qoder
#     SCRIPTS : 以空格或逗号分隔的脚本类型（默认：两者）：可选值：sh ps
#   示例：
#     AGENTS=claude SCRIPTS=sh $0 v0.2.0
#     AGENTS="copilot,gemini" $0 v0.2.0
#     SCRIPTS=ps $0 v0.2.0

if [[ $# -ne 1 ]]; then
  echo "用法: $0 <version-with-zh-v-prefix>" >&2
  exit 1
fi
NEW_VERSION="$1"
if [[ ! $NEW_VERSION =~ ^zh-v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "版本必须看起来像 zh-v0.0.0" >&2
  exit 1
fi

echo "为 $NEW_VERSION 构建发布包（中文本地化）"

# 使用 .genreleases-zh 目录存放构建产物
GENRELEASES_DIR=".genreleases-zh"
mkdir -p "$GENRELEASES_DIR"
rm -rf "$GENRELEASES_DIR"/* || true

rewrite_paths() {
  sed -E \
    -e 's@(/?)memory/@.specify/memory/@g' \
    -e 's@(/?)scripts/@.specify/scripts/@g' \
    -e 's@(/?)templates/@.specify/templates/@g'
}

generate_commands() {
  local agent=$1 ext=$2 arg_format=$3 output_dir=$4 script_variant=$5
  mkdir -p "$output_dir"
  for template in i18n/zh/templates/commands/*.md; do
    [[ -f "$template" ]] || continue
    local name description script_command agent_script_command body file_content
    name=$(basename "$template" .md)

    # 规范化行尾
    file_content=$(tr -d '\r' < "$template")

    # 从 YAML 前言提取描述与脚本命令
    description=$(printf '%s\n' "$file_content" | awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}')
    script_command=$(printf '%s\n' "$file_content" | awk -v sv="$script_variant" '/^[[:space:]]*'"$script_variant"':[[:space:]]*/ {sub(/^[[:space:]]*'"$script_variant"':[[:space:]]*/, ""); print; exit}')

    if [[ -z $script_command ]]; then
      echo "警告: 在 $template 中未找到 $script_variant 的脚本命令" >&2
      script_command="(缺少 $script_variant 的脚本命令)"
    fi

    # 提取 agent_scripts 中的命令（如存在）
    agent_script_command=$(printf '%s\n' "$file_content" | awk '
      /^agent_scripts:$/ { in_agent_scripts=1; next }
      in_agent_scripts && /^[[:space:]]*'"$script_variant"':[[:space:]]*/ {
        sub(/^[[:space:]]*'"$script_variant"':[[:space:]]*/, "")
        print
        exit
      }
      in_agent_scripts && /^[a-zA-Z]/ { in_agent_scripts=0 }
    ')

    # 将 {SCRIPT} 占位符替换为脚本命令
    body=$(printf '%s\n' "$file_content" | sed "s|{SCRIPT}|${script_command}|g")

    # 若发现 {AGENT_SCRIPT} 占位符，请将其替换为代理脚本命令。
    if [[ -n $agent_script_command ]]; then
      body=$(printf '%s\n' "$body" | sed "s|{AGENT_SCRIPT}|${agent_script_command}|g")
    fi

    # 删除 scripts: 和 agent_scripts: 部分从 frontmatter 中，同时保持 YAML 结构
    body=$(printf '%s\n' "$body" | awk '
      /^---$/ { print; if (++dash_count == 1) in_frontmatter=1; else in_frontmatter=0; next }
      in_frontmatter && /^scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^agent_scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^[a-zA-Z].*:/ && skip_scripts { skip_scripts=0 }
      in_frontmatter && skip_scripts && /^[[:space:]]/ { next }
      { print }
    ')

    # 其他替换与路径重写
    body=$(printf '%s\n' "$body" | sed "s/{ARGS}/$arg_format/g" | sed "s/__AGENT__/$agent/g" | rewrite_paths)

    case $ext in
      toml)
        body=$(printf '%s\n' "$body" | sed 's/\\/\\\\/g')
        { echo "description = \"$description\""; echo; echo "prompt = \"\"\""; echo "$body"; echo "\"\"\""; } > "$output_dir/speckit.$name.$ext" ;;
      md)
        echo "$body" > "$output_dir/speckit.$name.$ext" ;;
      agent.md)
        echo "$body" > "$output_dir/speckit.$name.$ext" ;;
    esac
  done
}

generate_copilot_prompts() {
  local agents_dir=$1 prompts_dir=$2
  mkdir -p "$prompts_dir"

  # 为每个 .agent.md 文件生成一个 .prompt.md 文件
  for agent_file in "$agents_dir"/speckit.*.agent.md; do
    [[ -f "$agent_file" ]] || continue

    local basename=$(basename "$agent_file" .agent.md)
    local prompt_file="$prompts_dir/${basename}.prompt.md"

    # 创建包含代理 frontmatter 的提示文件
    cat > "$prompt_file" <<EOF
---
agent: ${basename}
---
EOF
  done
}

build_variant() {
  local agent=$1 script=$2
  local base_dir="$GENRELEASES_DIR/sdd-${agent}-package-${script}"
  echo "正在构建 $agent ($script) 包..."
  mkdir -p "$base_dir"

  # 复制基础结构（仅复制对应脚本变体），资源来源改为中文本地化目录
  SPEC_DIR="$base_dir/.specify"
  mkdir -p "$SPEC_DIR"

  [[ -d i18n/zh/memory ]] && { cp -r i18n/zh/memory "$SPEC_DIR/"; echo "已复制 i18n/zh/memory -> .specify"; }

  # 仅复制相关脚本目录 + 根级脚本文件
  if [[ -d i18n/zh/scripts ]]; then
    mkdir -p "$SPEC_DIR/scripts"
    case $script in
      sh)
        [[ -d i18n/zh/scripts/bash ]] && { cp -r i18n/zh/scripts/bash "$SPEC_DIR/scripts/"; echo "已复制 i18n/zh/scripts/bash -> .specify/scripts"; }
        # 复制任何不在特定变体目录中的脚本文件
        find i18n/zh/scripts -maxdepth 1 -type f -exec cp {} "$SPEC_DIR/scripts/" \; 2>/dev/null || true 
        ;;
      ps)
        [[ -d i18n/zh/scripts/powershell ]] && { cp -r i18n/zh/scripts/powershell "$SPEC_DIR/scripts/"; echo "已复制 i18n/zh/scripts/powershell -> .specify/scripts"; }
        # 复制任何不在特定变体目录中的脚本文件
        find i18n/zh/scripts -maxdepth 1 -type f -exec cp {} "$SPEC_DIR/scripts/" \; 2>/dev/null || true 
        ;;
    esac
  fi

  [[ -d i18n/zh/templates ]] && {
    mkdir -p "$SPEC_DIR/templates"
      # 按 PowerShell 实现对齐：保留 templates 下的相对路径，排除 commands 与 vscode-settings.json
      # 仅复制 i18n/zh/templates 下的常规文件，排除 commands、VSCode 设置及任何隐藏目录（如 .genreleases-zh）
      while IFS= read -r src; do
        rel=${src#i18n/zh/templates/}
        dest="$SPEC_DIR/templates/$rel"
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
      done < <(find i18n/zh/templates -type f \
                    -not -path "i18n/zh/templates/commands/*" \
                    -not -name "vscode-settings.json" \
                    -not -path "i18n/zh/templates/.*" \
                    -not -path "i18n/zh/templates/.*/**")
      echo "已复制 i18n/zh/templates -> .specify/templates"
  }

  # 占位符约定同英文版：
  #   * Markdown/prompt (claude, copilot, cursor-agent, opencode 等): $ARGUMENTS
  #   * TOML (gemini, qwen): {{args}}
  # 保持格式的可读性，无需额外的抽象。

  case $agent in
    claude)
      mkdir -p "$base_dir/.claude/commands"
      generate_commands claude md "\$ARGUMENTS" "$base_dir/.claude/commands" "$script" ;;
    gemini)
      mkdir -p "$base_dir/.gemini/commands"
      generate_commands gemini toml "{{args}}" "$base_dir/.gemini/commands" "$script"
      [[ -f agent_templates/gemini/GEMINI.md ]] && cp agent_templates/gemini/GEMINI.md "$base_dir/GEMINI.md" ;;
    copilot)
      mkdir -p "$base_dir/.github/agents"
      generate_commands copilot agent.md "\$ARGUMENTS" "$base_dir/.github/agents" "$script"
      # 生成伴随的prompt文件
      generate_copilot_prompts "$base_dir/.github/agents" "$base_dir/.github/prompts"
      # 创建 VSCode 公主裙的设置文件
      mkdir -p "$base_dir/.vscode"
      [[ -f i18n/zh/templates/vscode-settings.json ]] && cp i18n/zh/templates/vscode-settings.json "$base_dir/.vscode/settings.json" 
      ;;
    cursor-agent)
      mkdir -p "$base_dir/.cursor/commands"
      generate_commands cursor-agent md "\$ARGUMENTS" "$base_dir/.cursor/commands" "$script" ;;
    qwen)
      mkdir -p "$base_dir/.qwen/commands"
      generate_commands qwen toml "{{args}}" "$base_dir/.qwen/commands" "$script"
      [[ -f agent_templates/qwen/QWEN.md ]] && cp agent_templates/qwen/QWEN.md "$base_dir/QWEN.md" ;;
    opencode)
      mkdir -p "$base_dir/.opencode/command"
      generate_commands opencode md "\$ARGUMENTS" "$base_dir/.opencode/command" "$script" ;;
    windsurf)
      mkdir -p "$base_dir/.windsurf/workflows"
      generate_commands windsurf md "\$ARGUMENTS" "$base_dir/.windsurf/workflows" "$script" ;;
    codex)
      mkdir -p "$base_dir/.codex/prompts"
      generate_commands codex md "\$ARGUMENTS" "$base_dir/.codex/prompts" "$script" ;;
    kilocode)
      mkdir -p "$base_dir/.kilocode/workflows"
      generate_commands kilocode md "\$ARGUMENTS" "$base_dir/.kilocode/workflows" "$script" ;;
    auggie)
      mkdir -p "$base_dir/.augment/commands"
      generate_commands auggie md "\$ARGUMENTS" "$base_dir/.augment/commands" "$script" ;;
    roo)
      mkdir -p "$base_dir/.roo/commands"
      generate_commands roo md "\$ARGUMENTS" "$base_dir/.roo/commands" "$script" ;;
    codebuddy)
      mkdir -p "$base_dir/.codebuddy/commands"
      generate_commands codebuddy md "\$ARGUMENTS" "$base_dir/.codebuddy/commands" "$script" ;;
    qoder)
      mkdir -p "$base_dir/.qoder/commands"
      generate_commands qoder md "\$ARGUMENTS" "$base_dir/.qoder/commands" "$script" ;;
    amp)
      mkdir -p "$base_dir/.agents/commands"
      generate_commands amp md "\$ARGUMENTS" "$base_dir/.agents/commands" "$script" ;;
    shai)
      mkdir -p "$base_dir/.shai/commands"
      generate_commands shai md "\$ARGUMENTS" "$base_dir/.shai/commands" "$script" ;;
    q)
      mkdir -p "$base_dir/.amazonq/prompts"
      generate_commands q md "\$ARGUMENTS" "$base_dir/.amazonq/prompts" "$script" ;;
    bob)
      mkdir -p "$base_dir/.bob/commands"
      generate_commands bob md "\$ARGUMENTS" "$base_dir/.bob/commands" "$script" ;;
  esac
  ( cd "$base_dir" && zip -r "../spec-kit-template-${agent}-${script}-${NEW_VERSION}.zip" . )
  echo "已创建 $GENRELEASES_DIR/spec-kit-template-${agent}-${script}-${NEW_VERSION}.zip"
}

# 确定代理列表
ALL_AGENTS=(claude gemini copilot cursor-agent qwen opencode windsurf codex kilocode auggie roo codebuddy amp q bob qoder shai)
ALL_SCRIPTS=(sh ps)

norm_list() {
  # 逗号/换行 转为空格，再去重并保持首次出现顺序
  tr ',\n' '  ' | awk '{for(i=1;i<=NF;i++){if(!seen[$i]++){printf((out?"\n":"") $i);out=1}}}END{printf("\n")}'
}

validate_subset() {
  local type=$1; shift; local -n allowed=$1; shift; local items=("$@")
  local invalid=0
  for it in "${items[@]}"; do
    local found=0
    for a in "${allowed[@]}"; do [[ $it == "$a" ]] && { found=1; break; }; done
    if [[ $found -eq 0 ]]; then
      echo "错误: 未知的 $type '$it'（允许值: ${allowed[*]}）" >&2
      invalid=1
    fi
  done
  return $invalid
}

if [[ -n ${AGENTS:-} ]]; then
  mapfile -t AGENT_LIST < <(printf '%s' "$AGENTS" | norm_list)
  validate_subset agent ALL_AGENTS "${AGENT_LIST[@]}" || exit 1
else
  AGENT_LIST=("${ALL_AGENTS[@]}")
fi

if [[ -n ${SCRIPTS:-} ]]; then
  mapfile -t SCRIPT_LIST < <(printf '%s' "$SCRIPTS" | norm_list)
  validate_subset script ALL_SCRIPTS "${SCRIPT_LIST[@]}" || exit 1
else
  SCRIPT_LIST=("${ALL_SCRIPTS[@]}")
fi

echo "代理: ${AGENT_LIST[*]}"
echo "脚本: ${SCRIPT_LIST[*]}"

for agent in "${AGENT_LIST[@]}"; do
  for script in "${SCRIPT_LIST[@]}"; do
    build_variant "$agent" "$script"
  done
done

echo "${GENRELEASES_DIR} 中的中文存档："
ls -1 "$GENRELEASES_DIR"/spec-kit-template-*"-${NEW_VERSION}".zip
