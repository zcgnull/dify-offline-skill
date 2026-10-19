---
name: dify-offline-packager
version: 1.0.0
description: 为 Dify 平台打包插件离线安装包（.difypkg）。当用户要求"打包某个 Dify 插件的离线包"、"制作 arm/x86 版本的 difypkg"、"离线安装 Dify 插件"时使用。支持 Marketplace、GitHub Release、本地包三种来源，支持 amd64/arm64 双平台。
---

# Dify 插件离线打包 Skill

## 何时使用

- 用户给出 `author/name:version` 形式的插件，要求离线包
- 用户的 Dify 部署在内网/离线环境，无法在线安装插件
- 需要特定 CPU 架构（amd64 / arm64）的离线包

## 核心原理

Dify 插件（Python 类）在线安装时会从 PyPI 拉依赖；离线包则把**目标平台的 wheels 预先打进 .difypkg**。
因此**离线包与 CPU 架构强绑定**：打包容器的平台决定了 wheels 的架构，必须在目标平台环境（真实或 QEMU 模拟）中执行打包。

## 平台区别（重点）

| | linux/amd64 | linux/arm64 |
| --- | --- | --- |
| 适用目标机 | 常见 x86_64 服务器 | ARM 云主机、树莓派、Apple Silicon |
| CLI 二进制 | `dify-plugin-cli-<ver>-linux-amd64` | `dify-plugin-cli-<ver>-linux-arm64` |
| wheels 特征 | manylinux_x86_64 | manylinux_aarch64 |
| 在 x86 宿主机执行 | 原生，最快 | 需先 `docker run --rm --privileged tonistiigi/binfmt --install arm64` 启用 QEMU，速度约为原生 1/10 |
| daemon 镜像 | `dify-plugin-daemon:<ver>-local`（pull --platform linux/amd64） | 同名镜像（pull --platform linux/arm64） |
| compose 配置 | `TARGET_PLATFORM=linux/amd64` | `TARGET_PLATFORM=linux/arm64` |

**验证产物架构**：解包检查 wheels 文件名是否含 `manylinux_x86_64`（amd64）或 `manylinux_aarch64`（arm64）。

## 执行流程

1. `cd packager && cp .env.example .env`，按用户需求设置 `DIFY_PLUGIN_DAEMON_VERSION` 与 `TARGET_PLATFORM`
2. `./fetch-cli.sh <版本> <amd64|arm64>` 预下载 CLI（国内网络会自动尝试镜像）
3. 打包：
   ```bash
   docker compose run --rm packager --marketplace "author/name:version"
   ```
4. 产物在 `packager/difypkg/`，交付给用户前用 unzip 抽查 wheels 架构

## 常见坑

1. **pypi.org 国内不可达** → `.env` 必须配 `UV_DEFAULT_INDEX`/`PIP_INDEX_URL` 为国内镜像，否则 `uv lock` 超时失败
2. **arm64 在 x86 机器打包** → 忘记装 binfmt/QEMU 会报 `exec format error`
3. **GitHub 直连慢/被重置** → fetch-cli.sh 内置 gh-proxy.com / gh.llkk.cc 镜像回退；raw 文件可用 ghproxy.net
4. **Docker Hub 拉取断流** → daemon 镜像 2GB+，失败重跑几次；或配置 registry mirror
5. **离线包安装被拒** → Dify `.env` 需要 FORCE_VERIFYING_SIGNATURE=false 等四项（见 packager/README.md）
6. **marketplace 下载探测** → 用 GET 探测（HEAD 会 404），版本是否存在可查 `/api/v1/plugins/<author>/<name>/versions`

## 文件清单

```
├── SKILL.md                  # 本文件（agent 用法说明）
├── packager/
│   ├── README.md             # 人类可读使用文档 + 平台差异说明
│   ├── .env.example          # 版本/平台/镜像源配置
│   ├── docker-compose.yml    # 打包容器编排（platform 由 TARGET_PLATFORM 决定）
│   ├── fetch-cli.sh          # CLI 二进制下载（含国内镜像回退）
│   ├── scripts/packager.py   # 打包主脚本
│   ├── bin/                  # CLI 缓存目录（git 不入库，见 .gitignore）
│   └── difypkg/              # 源包与产物目录
└── docs/
    └── platform-notes.md     # 平台差异详细笔记
```
