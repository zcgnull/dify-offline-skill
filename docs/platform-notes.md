# 平台差异详细笔记

## 判断目标平台
- 问用户目标 Dify 服务器的 CPU：`uname -m` 输出 `x86_64` → amd64；`aarch64` → arm64
- 拿不准时两个平台各打一份（成本低）

## arm64 在 x86 宿主机模拟打包
```bash
docker run --rm --privileged tonistiigi/binfmt --install arm64
# 之后 compose 中 platform: linux/arm64 即可
```
注意：QEMU 模拟下 uv/pip 解析明显变慢（整体约为原生 1/10），属正常。

## 产物自检清单
1. `unzip -l xxx.difypkg | grep manylinux` 确认 wheels 架构与目标一致
2. manifest.yaml 的 version/name 与请求一致
3. 约几十个 wheels、体积 10~30MB 属正常范围

## 版本升级
- 改 `.env` 的 `DIFY_PLUGIN_DAEMON_VERSION`，重跑 `fetch-cli.sh <新版本> <arch>`
- daemon 镜像 tag 形如 `0.6.10-local`
