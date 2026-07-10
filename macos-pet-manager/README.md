# CodpetPersonal

CodpetPersonal 是 Codpet 项目中的原生 macOS pet 管理器原型。它和 `cod.pet` 网站共用同一套 pet 目录格式，但不是网站套壳，也不是 OpenAI 官方产品。

它的定位是个人使用的桌面工具：

- 浏览本机已经安装到 Codex 的 pet
- 预览 spritesheet 动画
- 从 Codpet 目录发现 pet
- 导入本地 pet 文件夹
- 安装、卸载和恢复 pet
- 将选中的 pet 写入 Codex 配置，并尽力尝试即时应用

CodpetPersonal 不接受第三方 pet 提交。未来的可视化 pet 设计器会作为单独的 `Codpet Studio` 方向规划，不与当前管理器混在一起。

## 目录隔离

这个实现只在当前目录下：

- `macos-pet-manager/`

不会依赖或改写：

- `macos-app/`
- `macos-hybrid-app/`

## 构建

```bash
cd macos-pet-manager
./script/build_and_run.sh
```

只构建不启动：

```bash
cd macos-pet-manager
./script/build_and_run.sh --build-only
```

## 当前实现状态

- 已实现：本地 pet 浏览、动态预览、导入、安装、卸载和回收站恢复
- 已实现：连接 Codpet 仓库目录并浏览发现 pet
- 已实现：写入 `~/.codex/config.toml`
- 实验性：通过多种兼容策略尝试让正在运行的 Codex 即时刷新

## 已知限制

- 即时应用依赖当前 Codex 运行状态和兼容桥接，不能视为稳定的官方公共接口。
- 当前管理器的数据模型主要围绕 8×9 标准 atlas；面向新版 v2 pet 的 8×11 atlas 和 16 个方向还需要单独升级。
- 生成式 pet 设计、视觉风格选择、动画生成和自动安装不属于当前版本，记录在仓库的 [`docs/roadmap.md`](../docs/roadmap.md)。

## 隐私和授权边界

- 本 App 不要求用户提供 ChatGPT 密码，也不读取浏览器 Cookie 或 ChatGPT 会话凭据。
- 本地安装需要用户主动选择或允许访问 pet 目录。
- 未来如果加入 AI 生成，需要单独设计用户自己的 API 凭据存储和图片素材权利确认。
