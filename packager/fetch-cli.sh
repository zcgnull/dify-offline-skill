#!/usr/bin/env bash
# 下载指定版本的 dify-plugin-cli 到 bin/（amd64 / arm64）
# 用法: ./fetch-cli.sh <版本> [amd64|arm64]
set -e
VER="${1:?用法: fetch-cli.sh <版本> [amd64|arm64]}"
ARCH="${2:-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')}"
ASSET="dify-plugin-linux-${ARCH}"
OUT="bin/dify-plugin-cli-${VER}-linux-${ARCH}"
cd "$(dirname "$0")"
[ -f "$OUT" ] && { echo "已存在: $OUT"; exit 0; }
BASE="https://github.com/langgenius/dify-plugin-daemon/releases/download/${VER}/${ASSET}"
# 国内网络依次尝试镜像
for u in "$BASE" \
  "https://gh-proxy.com/https://github.com/langgenius/dify-plugin-daemon/releases/download/${VER}/${ASSET}" \
  "https://gh.llkk.cc/https://github.com/langgenius/dify-plugin-daemon/releases/download/${VER}/${ASSET}"; do
  echo "尝试: $u"
  curl -fL --retry 3 --max-time 600 -o "$OUT" "$u" && break
done
[ -f "$OUT" ] || { echo "下载失败"; exit 1; }
chmod +x "$OUT"
"$OUT" version
echo "完成: $OUT"
