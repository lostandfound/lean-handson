#!/usr/bin/env bash
# 模範解答を演習に重ね、sorry なしで全体がビルドできることを確かめる。
# 作業ツリーを汚さないよう、一時ディレクトリにコピーしてから上書きする。
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

rsync -a --exclude .git --exclude .lake "$root/" "$tmp/"
if compgen -G "$root/Solutions/*.lean" > /dev/null; then
  cp "$root"/Solutions/*.lean "$tmp/Payroll/"
fi

cd "$tmp"
if ! lake build Payroll PayrollTest > build.log 2>&1; then
  cat build.log
  echo "check-solutions: build failed" >&2
  exit 1
fi
if grep -q "declaration uses 'sorry'" build.log; then
  grep "declaration uses 'sorry'" build.log
  echo "check-solutions: sorry remains" >&2
  exit 1
fi
echo "check-solutions: OK"
