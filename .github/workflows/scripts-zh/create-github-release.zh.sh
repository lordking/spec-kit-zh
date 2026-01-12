#!/usr/bin/env bash
set -euo pipefail

# create-github-release.zh.sh
# 使用中文本地化模板产物创建 GitHub Release
# 用法: create-github-release.zh.sh <version>

if [[ $# -ne 1 ]]; then
  echo "用法: $0 <version> (例如 zh-v0.0.7.1)" >&2
  exit 1
fi

VERSION="$1"

# 去掉前缀 zh-v 作为标题展示
VERSION_NO_V=${VERSION#zh-v}

# 中文产物目录与命名约定：.genreleases-zh/spec-kit-template-<agent>-<script>-<version>.zip
GEN_DIR=".genreleases-zh"

if [[ ! -d "$GEN_DIR" ]]; then
  echo "错误: 未找到目录 $GEN_DIR。请先运行 create-release-packages.zh.sh 生成产物。" >&2
  exit 1
fi

# 收集所有匹配当前版本的 zip 产物
shopt -s nullglob
files=("$GEN_DIR"/spec-kit-template-*-"$VERSION".zip)
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
  echo "错误: 未找到任何中文发布包 ($GEN_DIR/spec-kit-template-*-$VERSION.zip)。" >&2
  ls -la "$GEN_DIR" || true
  exit 1
fi

echo "将创建 GitHub Release: $VERSION，包含 ${#files[@]} 个资产"

gh release create "$VERSION" \
  "${files[@]}" \
  --title "Spec Kit 模板 (中文版) - $VERSION_NO_V" \
  --notes-file release_notes_zh.md
