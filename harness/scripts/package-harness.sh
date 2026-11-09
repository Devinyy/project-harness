#!/bin/bash
# Build the explicit, deterministic Harness distribution archive.
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
HARNESS_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)

usage() {
  cat <<'USAGE'
用法：
  bash scripts/package-harness.sh --output DIR

选项：
  --output DIR  写入 project-harness-2.0.0.tar.gz 及其 .sha256 的目录
  -h, --help    显示此帮助，不写入任何文件

归档只包含 distribution/MANIFEST.txt 明确列出的工具资产；构建需要 Python 3
标准库，不安装额外依赖。归档顶层目录为 project-harness-2.0.0。
USAGE
}

error() {
  printf '❌ %s\n' "$*" >&2
}

die() {
  error "$1"
  exit "${2:-2}"
}

if [ "$#" -eq 0 ]; then
  usage >&2
  exit 2
fi

OUTPUT_DIR=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output)
      [ "$#" -ge 2 ] || die "--output 缺少目录参数"
      case "$2" in
        -*) die "--output 目录不能以 - 开头" ;;
      esac
      [ -n "$2" ] || die "--output 目录不能为空"
      [ -z "$OUTPUT_DIR" ] || die "--output 只能指定一次"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "未知参数：$1；请使用 --help 查看用法"
      ;;
  esac
done

[ -n "$OUTPUT_DIR" ] || die "缺少 --output；请使用 --help 查看用法"
command -v python3 >/dev/null 2>&1 || die "找不到 Python 3；构建只依赖 Python 3 标准库" 1

exec python3 "$SCRIPT_DIR/lib/package_harness.py" \
  --root "$HARNESS_ROOT" \
  --output "$OUTPUT_DIR"
