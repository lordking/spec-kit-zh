#!/usr/bin/env bash
set -euo pipefail

# update-version.zh.sh
# 更新pyproject.toml中的版本号（仅用于发布产物）
# 使用方法: update-version.zh.sh <版本号>

if [[ $# -ne 1 ]]; then
  echo "使用方法: $0 <版本号>" >&2
  exit 1
fi

VERSION="$1"

# 移除 'zh-v' 前缀用于Python版本号
PYTHON_VERSION=${VERSION#zh-v}

if [ -f "pyproject.toml" ]; then
  sed -i "s/version = \".*\"/version = \"$PYTHON_VERSION\"/" pyproject.toml
  echo "已将 pyproject.toml 版本更新为 $PYTHON_VERSION（仅用于发布产物）"
else
  echo "警告: 未找到 pyproject.toml，跳过版本更新"
fi