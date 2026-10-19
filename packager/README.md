# Dify 插件离线打包工具（含跨平台支持）

基于 [xcsf/dify-plugin-repackaging-python](https://github.com/xcsf/dify-plugin-repackaging-python)（fork of kurokobo/dify-plugin-offline-packager）整理，用 `langgenius/dify-plugin-daemon:<ver>-local` 镜像执行打包，产出可在离线 Dify 环境直接安装的 `.difypkg`。

## 一次性准备

```bash
cd packager
cp .env.example .env            # 按需修改版本/平台
./fetch-cli.sh 0.6.10 amd64     # 预下载 amd64 CLI（arm64 同理）
```

> CLI 资产在 release 里名为 `dify-plugin-linux-<arch>`，脚本会自动按约定重命名为
> `dify-plugin-cli-<版本>-linux-<arch>` 供 packager.py 缓存命中。

## 打包命令

```bash
# 从 Dify Marketplace 打包
docker compose run --rm packager --marketplace "langgenius/openai_api_compatible:0.0.68"

# 从 GitHub Release 打包
docker compose run --rm packager --github "owner/repo:tag:asset.difypkg"

# 从本地 .difypkg 重打包（放入 difypkg/ 目录）
docker compose run --rm packager --local "difypkg/my-plugin.difypkg"
```

产物输出在 `difypkg/` 目录，文件名 `<plugin>-offline.difypkg`。

## 切换目标平台

编辑 `.env` 的 `TARGET_PLATFORM`：

- `linux/amd64` —— x86_64 服务器（原生执行，最快）
- `linux/arm64` —— ARM 服务器 / Apple Silicon

首次跑 arm64 前需在 x86 宿主机安装 QEMU 用户态模拟：

```bash
docker run --rm --privileged tonistiigi/binfmt --install arm64
```

## Dify 侧安装离线包的 .env 要求

| 配置项 | 建议值 |
| --- | --- |
| FORCE_VERIFYING_SIGNATURE | false |
| ENFORCE_LANGGENIUS_PLUGIN_SIGNATURES | false |
| PLUGIN_MAX_PACKAGE_SIZE | 524288000 |
| NGINX_CLIENT_MAX_BODY_SIZE | 500M |
