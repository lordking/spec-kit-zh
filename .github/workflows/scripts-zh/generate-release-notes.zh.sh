#!/usr/bin/env bash
set -euo pipefail

# generate-release-notes.zh.sh
# 从 git 历史生成中文发布说明
# 用法: generate-release-notes.zh.sh <新版本> <上一个标签>

if [[ $# -ne 2 ]]; then
  echo "用法: $0 <新版本> <上一个标签>" >&2
  exit 1
fi

NEW_VERSION="$1"
LAST_TAG="$2"

# 获取自上一个标签以来的提交记录
if [ "$LAST_TAG" = "zh-v0.0.0" ]; then
  # 检查提交数量并以此为限制
  COMMIT_COUNT=$(git rev-list --count HEAD)
  if [ "$COMMIT_COUNT" -gt 10 ]; then
    COMMITS=$(git log --oneline --pretty=format:"- %s" HEAD~10..HEAD)
  else
    COMMITS=$(git log --oneline --pretty=format:"- %s" HEAD~$COMMIT_COUNT..HEAD 2>/dev/null || git log --oneline --pretty=format:"- %s")
  fi
else
  COMMITS=$(git log --oneline --pretty=format:"- %s" $LAST_TAG..HEAD)
fi

# 创建中文发布说明
cat > release_notes_zh.md << EOF
这是最新版本的发布包，可与您选择的 AI 助手一起使用。我们建议使用 Specify CLI 来搭建您的项目，但您也可以单独下载这些模板并自行管理。

## 更新日志

$COMMITS

EOF

echo "已生成发布说明："
cat release_notes_zh.md