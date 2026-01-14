#!/usr/bin/env bash

set -e

JSON_MODE=false
SHORT_NAME=""
BRANCH_NUMBER=""
ARGS=()
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json) 
            JSON_MODE=true 
            ;;
        --short-name)
            if [ $((i + 1)) -gt $# ]; then
                echo '错误：--short-name 需要一个值' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            # Check if the next argument is another option (starts with --)
            if [[ "$next_arg" == --* ]]; then
                echo '错误：--short-name 需要一个值' >&2
                exit 1
            fi
            SHORT_NAME="$next_arg"
            ;;
        --number)
            if [ $((i + 1)) -gt $# ]; then
                echo '错误：--number 需要一个值' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo '错误：--number 需要一个值' >&2
                exit 1
            fi
            BRANCH_NUMBER="$next_arg"
            ;;
        --help|-h) 
            echo "用法：$0 [--json] --short-name <name> [--number N] <feature_description>"
            echo ""
            echo "选项："
            echo "  --json              以 JSON 格式输出"
            echo "  --short-name <name> 为分支提供自定义短名称（2-4 个单词）"
            echo "  --number N          手动指定分支号（覆盖自动检测）"
            echo "  --help, -h          显示此帮助信息"
            echo ""
            echo "示例："
            echo "  $0 --short-name 'user-auth' '添加用户身份验证系统'"
            echo "  $0 --short-name 'oauth2-api' --number 5 '实现 OAuth2 API 集成'"
            exit 0
            ;;
        *) 
            ARGS+=("$arg") 
            ;;
    esac
    i=$((i + 1))
done

# 检查是否提供了功能描述
FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "用法：$0 [--json] --short-name <name> [--number N] <feature_description>" >&2
    exit 1
fi

# 检查是否提供了短名称  
if [ -z "$SHORT_NAME" ]; then
    echo "错误：--short-name 为必填" >&2
    exit 1
fi

# 函数：通过搜索现有项目标记来找到仓库根目录
find_repo_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# 函数：从 specs 目录获取最高编号
get_highest_from_specs() {
    local specs_dir="$1"
    local highest=0
    
    if [ -d "$specs_dir" ]; then
        for dir in "$specs_dir"/*; do
            [ -d "$dir" ] || continue
            dirname=$(basename "$dir")
            number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
            number=$((10#$number))
            if [ "$number" -gt "$highest" ]; then
                highest=$number
            fi
        done
    fi
    
    echo "$highest"
}

# 函数：从 git 分支获取最高编号
get_highest_from_branches() {
    local highest=0
    
    # Get all branches (local and remote)
    branches=$(git branch -a 2>/dev/null || echo "")
    
    if [ -n "$branches" ]; then
        while IFS= read -r branch; do
            # Clean branch name: remove leading markers and remote prefixes
            clean_branch=$(echo "$branch" | sed 's/^[* ]*//; s|^remotes/[^/]*/||')
            
            # 如果分支匹配模式 ###-* 则提取特性号
            if echo "$clean_branch" | grep -q '^[0-9]\{3\}-'; then
                number=$(echo "$clean_branch" | grep -o '^[0-9]\{3\}' || echo "0")
                number=$((10#$number))
                if [ "$number" -gt "$highest" ]; then
                    highest=$number
                fi
            fi
        done <<< "$branches"
    fi
    
    echo "$highest"
}

# 函数：检查现有分支（本地和远程）并返回下一个可用号
check_existing_branches() {
    local specs_dir="$1"

    # 获取所有远程的最新分支信息（如果没有远程则抑制错误）
    git fetch --all --prune 2>/dev/null || true

    # 从所有分支获取最高编号（不仅仅是匹配的短名称）
    local highest_branch=$(get_highest_from_branches)

    # 从所有 specs 获取最高编号（不仅仅是匹配的短名称）
    local highest_spec=$(get_highest_from_specs "$specs_dir")

    # 取两者的最大值
    local max_num=$highest_branch
    if [ "$highest_spec" -gt "$max_num" ]; then
        max_num=$highest_spec
    fi

    # 返回下一个号
    echo $((max_num + 1))
}

# 函数：清理和格式化分支名
clean_branch_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

# 解析仓库根目录。首选使用 git 信息，但如果不可用则回退到
# 搜索仓库标记，以便在使用 --no-git 初始化的仓库中工作流仍然有效。
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
    if [ -z "$REPO_ROOT" ]; then
        echo "错误：无法确定仓库根目录。请从仓库内运行此脚本。" >&2
        exit 1
    fi
    HAS_GIT=false
fi

cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

# 生成分支名（短名称必填）
BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")

# 确定分支号
if [ -z "$BRANCH_NUMBER" ]; then
    if [ "$HAS_GIT" = true ]; then
        # 检查远程上的现有分支
        BRANCH_NUMBER=$(check_existing_branches "$SPECS_DIR")
    else
        # 回退到本地目录检查
        HIGHEST=$(get_highest_from_specs "$SPECS_DIR")
        BRANCH_NUMBER=$((HIGHEST + 1))
    fi
fi

# 强制使用十进制解释以防止八进制转换（例如，010 在八进制中是 8，但应该是 10）
FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"

# GitHub 对分支名称强制执行 244 字节的限制
# 验证和截断（如果必要）
MAX_BRANCH_LENGTH=244
if [ ${#BRANCH_NAME} -gt $MAX_BRANCH_LENGTH ]; then
    # 计算需要从后缀中修剪多少
    # 说明：特性号（3）+ 连字符（1）= 4 个字符
    MAX_SUFFIX_LENGTH=$((MAX_BRANCH_LENGTH - 4))
    
    # 如果可能，在单词边界处截断后缀
    TRUNCATED_SUFFIX=$(echo "$BRANCH_SUFFIX" | cut -c1-$MAX_SUFFIX_LENGTH)
    # 如果截断产生了尾部连字符则移除
    TRUNCATED_SUFFIX=$(echo "$TRUNCATED_SUFFIX" | sed 's/-$//')
    
    ORIGINAL_BRANCH_NAME="$BRANCH_NAME"
    BRANCH_NAME="${FEATURE_NUM}-${TRUNCATED_SUFFIX}"
    
    >&2 echo "[specify] 警告：分支名称超过了 GitHub 的 244 字节限制"
    >&2 echo "[specify] 原始：$ORIGINAL_BRANCH_NAME (${#ORIGINAL_BRANCH_NAME} 字节)"
    >&2 echo "[specify] 截断为：$BRANCH_NAME (${#BRANCH_NAME} 字节)"
fi

if [ "$HAS_GIT" = true ]; then
    git checkout -b "$BRANCH_NAME"
else
    >&2 echo "[specify] 警告：未检测到 Git 仓库；跳过了对 $BRANCH_NAME 的分支创建"
fi

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
mkdir -p "$FEATURE_DIR"

TEMPLATE="$REPO_ROOT/.specify/templates/spec-template.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
if [ -f "$TEMPLATE" ]; then cp "$TEMPLATE" "$SPEC_FILE"; else touch "$SPEC_FILE"; fi

# 为当前会话设置 SPECIFY_FEATURE 环境变量
export SPECIFY_FEATURE="$BRANCH_NAME"

if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s"}\n' "$BRANCH_NAME" "$SPEC_FILE" "$FEATURE_NUM"
else
    echo "分支名称：$BRANCH_NAME"
    echo "规格文件：$SPEC_FILE"
    echo "特性号：$FEATURE_NUM"
    echo "SPECIFY_FEATURE 环境变量已设置为：$BRANCH_NAME"
fi
