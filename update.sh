#!/usr/bin/env bash
# 从 GitHub 拉指定分支的最新内容，不必每次手动下压缩包。
#
# 用法:
#   ./update.sh                  # 默认 arena/01a07a48-fyx-sort
#   ./update.sh 某分支名
#   FYX_REMOTE=https://github.com/其它人/fyx_sort.git ./update.sh
#
# 在 git 克隆里：fetch + fast-forward 到该分支。
# 在解压出来的 fyx_linux_run 里：浅克隆后覆盖头文件和测试脚本。
set -euo pipefail

BRANCH="${1:-arena/01a07a48-fyx-sort}"
REMOTE="${FYX_REMOTE:-https://github.com/CLRV-CLV/fyx_sort.git}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "需要 $1"; exit 1; }; }
need git

here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

if [ -d .git ]; then
  echo "== git 仓库，拉取 $REMOTE  分支 $BRANCH =="
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "$REMOTE"
  git fetch origin "$BRANCH"
  if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git checkout "$BRANCH"
  else
    git checkout -B "$BRANCH" "origin/$BRANCH"
  fi
  git merge --ff-only "origin/$BRANCH"
  echo "当前 $(git rev-parse --short HEAD)  $BRANCH"
  if [ -f fyx_linux_bench.zip ] && [ ! -d fyx_linux_run ]; then
    need unzip
    unzip -o fyx_linux_bench.zip
  fi
  echo "完成。Linux 测试: cd fyx_linux_run && ./build.sh && ./run.sh"
  exit 0
fi

echo "== 非 git 目录（多半是解压的测试包），浅克隆覆盖 =="
need unzip
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 --branch "$BRANCH" "$REMOTE" "$TMP/repo"
# 优先用仓库里的压缩包刷新本目录
if [ -f "$TMP/repo/fyx_linux_bench.zip" ]; then
  unzip -o "$TMP/repo/fyx_linux_bench.zip" -d "$TMP"
  if [ -d "$TMP/fyx_linux_run" ]; then
    cp -a "$TMP/fyx_linux_run/." "$here/"
  fi
fi
# 头文件始终用仓库根上那份（和 zip 内可能差一次 stitch）
if [ -f "$TMP/repo/fyx_sort.hpp" ]; then
  cp -f "$TMP/repo/fyx_sort.hpp" "$here/fyx_sort.hpp"
fi
echo "已用 $BRANCH 覆盖 $here"
echo "接着: ./build.sh && ./run.sh"
