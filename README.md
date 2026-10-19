# Dify 离线打包工具集（Packager + Skill）

为离线/内网环境下的 Dify 平台制作插件离线安装包（`.difypkg`），支持 **x86_64 (amd64)** 与 **ARM64 (arm64)** 双平台。

基于 [xcsf/dify-plugin-repackaging-python](https://github.com/xcsf/dify-plugin-repackaging-python)（fork of kurokobo/dify-plugin-offline-packager）整理封装。

## 仓库结构

```
dify-offline-skill/
├── README.md                 # 本文件
├── SKILL.md                  # Agent Skill：让 AI 助手自动完成离线打包
├── docs/
│   └── platform-notes.md     # 平台差异详细笔记（amd64 vs arm64）
└── packager/                 # 打包工具本体
    ├── README.md             # 详细使用文档
    ├── docker-compose.yml    # 打包容器编排（dify-plugin-daemon:<ver>-local）
    ├── .env.example          # 配置模板（版本/平台/镜像源）
    ├── fetch-cli.sh          # dify-plugin-cli 下载脚本（含国内镜像回退）
    ├── scripts/packager.py   # 打包主脚本
    ├── bin/                  # CLI 缓存（不入库，fetch-cli.sh 下载）
    └── difypkg/              # 源包与产物目录
```

## 快速开始

```bash
cd packager
cp .env.example .env                  # ① 配置版本与目标平台
./fetch-cli.sh 0.6.10 amd64           # ② 下载对应平台 CLI
docker compose run --rm packager \
  --marketplace "langgenius/openai_api_compatible:0.0.68"   # ③ 打包
# 产物 → difypkg/langgenius-openai_api_compatible_0.0.68-offline.difypkg
```

## 三种打包来源

| 来源 | 命令 |
| --- | --- |
| Dify Marketplace | `--marketplace "author/name:version"` |
| GitHub Release | `--github "owner/repo:tag:asset.difypkg"` |
| 本地 .difypkg | `--local "difypkg/my-plugin.difypkg"` |

## 平台区别一览

| | amd64 | arm64 |
| --- | --- | --- |
| 目标机 | 常规 x86_64 服务器 | ARM 云主机 / 树莓派 / Apple Silicon |
| `.env` 配置 | `TARGET_PLATFORM=linux/amd64` | `TARGET_PLATFORM=linux/arm64` |
| CLI 文件名 | `dify-plugin-cli-<ver>-linux-amd64` | `dify-plugin-cli-<ver>-linux-arm64` |
| wheels 特征 | `manylinux_x86_64` | `manylinux_aarch64` |
| 在 x86 宿主机打包 | 原生执行 | 需 QEMU（见下） |

在 x86 宿主机上打 arm64 包，需先启用 binfmt 模拟（一次性）：

```bash
docker run --rm --privileged tonistiigi/binfmt --install arm64
```

> ⚠️ 离线包与 CPU 架构强绑定：打包容器的平台决定 wheels 架构，装错了平台插件无法启动。
> 交付前自检：`unzip -l <产物>.difypkg | grep manylinux`，确认标签与目标一致。

## 作为 Agent Skill 使用

把本仓库（或 SKILL.md 所在目录）挂给 AI 助手，即可用自然语言驱动打包，例如：
- "帮我打包 arm 版的 langgenius/openai_api_compatible:0.0.68"
- "再打一个 x86 的 yzddmr6/chatflow_invoker:0.0.6"

Skill 内置了执行流程、平台决策表和常见坑（pypi 镜像、QEMU、GitHub 镜像回退等），详见 `SKILL.md`。

## 安装离线包（Dify 侧）

在 Dify `.env` 中配置后重启：

| 配置项 | 建议值 |
| --- | --- |
| FORCE_VERIFYING_SIGNATURE | false |
| ENFORCE_LANGGENIUS_PLUGIN_SIGNATURES | false |
| PLUGIN_MAX_PACKAGE_SIZE | 524288000 |
| NGINX_CLIENT_MAX_BODY_SIZE | 500M |

然后在 Dify 后台「插件 → 安装离线包」上传 `.difypkg` 即可。

## 常见问题

- **`uv lock` 超时**：pypi.org 不可达，确认 `.env` 已配置 `UV_DEFAULT_INDEX=https://mirrors.aliyun.com/pypi/simple`
- **`exec format error`**：打 arm64 包但没装 QEMU/binfmt
- **CLI 下载失败**：fetch-cli.sh 已内置 gh-proxy.com / gh.llkk.cc 镜像回退，均失败可手动下载 release 资产 `dify-plugin-linux-<arch>` 重命名放入 `bin/`
- **Docker 拉镜像断流**：daemon 镜像 2GB+，重试几次或配置 registry mirror
