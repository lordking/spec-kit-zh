#!/usr/bin/env bash
set -euo pipefail

# get-next-version.zh.sh
# 计算中文版本的下一个版本号，基于最新的zh-v前缀标签
# 使用方法: get-next-version.zh.sh

# 获取最新的zh-前缀标签，如果没有则使用zh-v0.0.0
LATEST_TAG=$(git describe --tags --abbrev=0 --match "zh-v*" 2>/dev/null || echo "zh-v0.0.0")
echo "latest_tag=$LATEST_TAG" >> "$GITHUB_OUTPUT"

# 提取版本号并递增
VERSION=$(echo $LATEST_TAG | sed 's/^zh-v//')
IFS='.' read -ra VERSION_PARTS <<< "$VERSION"
MAJOR=${VERSION_PARTS[0]:-0}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

# 递增补丁版本号
PATCH=$((PATCH + 1))
NEW_VERSION="zh-v$MAJOR.$MINOR.$PATCH"

echo "new_version=$NEW_VERSION" >> "$GITHUB_OUTPUT"
echo "新中文版本: $NEW_VERSION"