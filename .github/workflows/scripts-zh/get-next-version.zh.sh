#!/usr/bin/env bash
set -euo pipefail

# get-next-version.zh.sh
# 计算中文版本号：基于最新英文标签并追加中文累计更新次数
# 使用方法: get-next-version.zh.sh

# 获取最新的英文版本标签，如果没有则默认为 v0.0.0
LATEST_TAG=$(git describe --tags --abbrev=0 --match "v*" 2>/dev/null || echo "v0.0.0")
echo "latest_tag=$LATEST_TAG" >> "$GITHUB_OUTPUT"

PREFIX="zh-$LATEST_TAG"
HIGHEST_COUNT=0

# 查找当前英文版本下已有的中文标签，旧格式 zh-vX.Y.Z 视为第一次发布
while IFS= read -r TAG; do
	[[ -z "$TAG" ]] && continue

	if [[ "$TAG" == "$PREFIX" ]]; then
		COUNT=1
	elif [[ "$TAG" == "$PREFIX".* ]]; then
		SUFFIX=${TAG#${PREFIX}.}
		if [[ "$SUFFIX" =~ ^[0-9]+$ ]]; then
			COUNT=$SUFFIX
		else
			continue
		fi
	else
		continue
	fi

	(( COUNT > HIGHEST_COUNT )) && HIGHEST_COUNT=$COUNT
done < <(git tag -l "$PREFIX*")

NEXT_COUNT=$((HIGHEST_COUNT + 1))
NEW_VERSION="$PREFIX.$NEXT_COUNT"

echo "new_version=$NEW_VERSION" >> "$GITHUB_OUTPUT"
echo "新中文版本: $NEW_VERSION"