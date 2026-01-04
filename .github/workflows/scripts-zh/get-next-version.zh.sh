#!/usr/bin/env bash
set -euo pipefail

# get-next-version.zh.sh
# 计算中文版本的版本号，基于最新的英文版本标签
# 使用方法: get-next-version.zh.sh

# 获取最新的英文版本标签，如果没有则默认为 v0.0.0
LATEST_TAG=$(git describe --tags --abbrev=0 --match "v*" 2>/dev/null || echo "v0.0.0")
echo "latest_tag=$LATEST_TAG" >> "$GITHUB_OUTPUT"

# 加上中文前缀
NEW_VERSION="zh-$LATEST_TAG"

echo "new_version=$NEW_VERSION" >> "$GITHUB_OUTPUT"
echo "新中文版本: $NEW_VERSION"