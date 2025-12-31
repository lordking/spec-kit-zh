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
                echo '错误: --short-name 需要一个值' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            # 检查下一个参数是否是另一个选项（以 -- 开头）
            if [[ "$next_arg" == --* ]]; then
                echo '错误: --short-name 需要一个值' >&2
                exit 1
            fi
            SHORT_NAME="$next_arg"
            ;;
        --number)
            if [ $((i + 1)) -gt $# ]; then
                echo '错误: --number 需要一个值' >&2
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                echo '错误: --number 需要一个值' >&2
                exit 1
            fi
            BRANCH_NUMBER="$next_arg"
            ;;
        --help|-h)
            echo "用法: $0 [--json] [--short-name <name>] [--number N] <feature_description>"
            echo ""
            echo "选项:"
            echo "  --json              以 JSON 格式输出"
            echo "  --short-name <name> 为分支提供自定义短名称（2-4 个单词）"
            echo "  --number N          手动指定分支号（覆盖自动检测）"
            echo "  --help, -h          显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 '添加用户认证系统' --short-name 'user-auth'"
            echo "  $0 '实现 OAuth2 应用程序接入' --number 5"
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
    i=$((i + 1))
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "用法: $0 [--json] [--short-name <name>] [--number N] <feature_description>" >&2
    exit 1
fi

# 函数通过搜索现有项目标记来找到仓库根目录
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

# 函数从 specs 目录获取最高号码
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

# 函数从 git 分支获取最高号码
get_highest_from_branches() {
    local highest=0

    # 获取所有分支（本地和远程）
    branches=$(git branch -a 2>/dev/null || echo "")

    if [ -n "$branches" ]; then
        while IFS= read -r branch; do
            # 清理分支名称: 删除前导标记和远程前缀
            clean_branch=$(echo "$branch" | sed 's/^[* ]*//; s|^remotes/[^/]*/||')

            # 如果分支符合 ###-* 模式，提取功能号
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

# 函数检查现有分支（本地和远程）并返回下一个可用的号码
check_existing_branches() {
    local specs_dir="$1"

    # 获取所有远程以获得最新分支信息（如果没有远程，则忽略错误）
    git fetch --all --prune 2>/dev/null || true

    # 从所有分支获取最高号码（不仅是匹配的短名称）
    local highest_branch=$(get_highest_from_branches)

    # 从所有 specs 获取最高号码（不仅是匹配的短名称）
    local highest_spec=$(get_highest_from_specs "$specs_dir")

    # 取两者中的最大值
    local max_num=$highest_branch
    if [ "$highest_spec" -gt "$max_num" ]; then
        max_num=$highest_spec
    fi

    # 返回下一个号码
    echo $((max_num + 1))
}

# 函数用于清理和格式化分支名称（支持中文和其他 Unicode 字符）
clean_branch_name() {
    local name="$1"
    # 转换为小写并将任何非字母/非数字字符替换为连字符
    # 使用 LC_ALL=C.UTF-8 确保正确处理 Unicode
    echo "$name" | LC_ALL=C.UTF-8 awk '{
        gsub(/[^[:alnum:]]/, "-");  # 将非字母数字字符替换为连字符
        gsub(/-+/, "-");             # 合并多个连字符
        gsub(/^-/, "");              # 删除前导连字符
        gsub(/-$/, "");              # 删除尾随连字符
        print tolower($0);           # 转换为小写
    }'
}

# 解析仓库根目录。优先使用 git 信息（如果可用），但回退到搜索仓库标记，
# 以便工作流在使用 --no-git 初始化的仓库中仍然可以正常工作。
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
    if [ -z "$REPO_ROOT" ]; then
        echo "错误: 无法确定仓库根目录。请从仓库内运行此脚本。" >&2
        exit 1
    fi
    HAS_GIT=false
fi

cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

# 函数用于生成分支名称，带有停用词过滤和长度过滤（支持中文）
generate_branch_name() {
    local description="$1"

    # 要过滤的常见停用词（英文和中文）
    local stop_words="i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set|一个|的|在|和|是|我|有|这|了|为|到|与|将|可以"

    local meaningful_words=()

    # 提取单词，使用 Unicode 支持的字符类，并保留原始大小写以便后续判断
    while IFS= read -r word; do
        # 跳过空单词
        [ -z "$word" ] && continue

        # 小写化用于停用词匹配（支持 Unicode）
        local lower_word
        lower_word=$(printf '%s\n' "$word" | LC_ALL=C.UTF-8 awk '{print tolower($0)}')

        # 如果是停用词则跳过
        if printf '%s\n' "$lower_word" | LC_ALL=C.UTF-8 awk -v re="^(${stop_words})$" 'tolower($0) ~ re {exit 0} END {exit 1}'; then
            continue
        fi

        # 保留长度 >= 2 的单词；否则仅当原文中出现大写形式（可能是缩写）时保留
        if [ ${#word} -ge 2 ]; then
            meaningful_words+=("$word")
        elif echo "$description" | grep -q "\b${word^^}\b"; then
            meaningful_words+=("$word")
        fi
    done < <(printf '%s\n' "$description" | LC_ALL=C.UTF-8 awk '{ line=$0; gsub(/[^[:alnum:][:space:]]/, " ", line); n=split(line, a, /[[:space:]]+/); for(i=1;i<=n;i++) if(a[i] != "") print a[i]; }')

    # 如果有有意义的单词，使用前 3-4 个
    if [ ${#meaningful_words[@]} -gt 0 ]; then
        local max_words=3
        if [ ${#meaningful_words[@]} -eq 4 ]; then max_words=4; fi

        local result=""
        local count=0
        for word in "${meaningful_words[@]}"; do
            if [ $count -ge $max_words ]; then break; fi
            if [ -n "$result" ]; then result="$result-"; fi
            result="$result$word"
            count=$((count + 1))
        done
        clean_branch_name "$result"
    else
        # 如果没有找到有意义的单词，回退到原始逻辑
        local cleaned
        cleaned=$(clean_branch_name "$description")
        printf '%s\n' "$cleaned" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

# 生成分支名称
if [ -n "$SHORT_NAME" ]; then
    # 使用提供的短名称，只需清理一下
    BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
else
    # 从描述生成，使用智能过滤
    BRANCH_SUFFIX=$(generate_branch_name "$FEATURE_DESCRIPTION")
fi

# 确定分支号码
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

# 强制使用十进制解释以防止八进制转换（例如 010 在八进制中为 8，但应该是十进制的 10）
FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"

# GitHub 强制限制分支名称为 244 字节
# 验证并在必要时截断
MAX_BRANCH_LENGTH=244
if [ ${#BRANCH_NAME} -gt $MAX_BRANCH_LENGTH ]; then
    # 计算需要从后缀修剪多少
    # 考虑：功能号码 (3) + 连字符 (1) = 4 个字符
    MAX_SUFFIX_LENGTH=$((MAX_BRANCH_LENGTH - 4))

    # 如果可能，在单词边界处截断后缀
    TRUNCATED_SUFFIX=$(echo "$BRANCH_SUFFIX" | cut -c1-$MAX_SUFFIX_LENGTH)
    # 如果截断创建了尾随连字符，则删除它
    TRUNCATED_SUFFIX=$(echo "$TRUNCATED_SUFFIX" | sed 's/-$//')

    ORIGINAL_BRANCH_NAME="$BRANCH_NAME"
    BRANCH_NAME="${FEATURE_NUM}-${TRUNCATED_SUFFIX}"

    >&2 echo "[specify] 警告: 分支名称超过了 GitHub 的 244 字节限制"
    >&2 echo "[specify] 原始: $ORIGINAL_BRANCH_NAME (${#ORIGINAL_BRANCH_NAME} 字节)"
    >&2 echo "[specify] 截断至: $BRANCH_NAME (${#BRANCH_NAME} 字节)"
fi

if [ "$HAS_GIT" = true ]; then
    git checkout -b "$BRANCH_NAME"
else
    >&2 echo "[specify] 警告: 未检测到 Git 仓库；已跳过创建分支 $BRANCH_NAME"
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
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "SPEC_FILE: $SPEC_FILE"
    echo "FEATURE_NUM: $FEATURE_NUM"
    echo "SPECIFY_FEATURE 环境变量已设置为: $BRANCH_NAME"
fi
