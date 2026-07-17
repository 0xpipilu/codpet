# Codpet - Interactive Pixel Companions / 像素桌面伴侣

[English](#english) | [简体中文](#简体中文)

## Built with OpenAI

CodPet was developed using OpenAI Codex and GPT-5.6.

Codex was used for:
- Building the companion management prototype
- Developing automation workflows
- Debugging compatibility issues
- Iterating product features

GPT-5.6 was used for:
- Product architecture exploration
- Technical problem solving
- Documentation and project storytelling
---

<a name="english"></a>
## English Description

**Codpet** (formerly Codex Pets) is a personal, curated collection of animated companions designed to live in your editor or developer environment. It is maintained as a personal project and does not accept third-party pet submissions.

This repository serves as:
- **Asset Storage**: Every pet is neatly organized in its own folder containing its runtime metadata (`pet.json`) and spritesheet (`spritesheet.webp`).
- **Interactive Showcase**: A high-performance, minimalist static web gallery deployed at [https://cod.pet/](https://cod.pet/).

### Live Preview & Showcase

Browse the library online at: **[https://cod.pet/](https://cod.pet/)**
- **Hover to Preview**: Move your mouse over any pet to see its accelerated interactive animations.
- **One-click Download**: Click `Download` on hover to grab a packaged `.zip` containing the pet's complete assets for easy installation.

### Native macOS App

**CodpetPersonal** is an experimental native macOS companion for browsing installed pets, importing local pet folders, installing pets, and applying a selected pet to Codex.

- Source and build instructions: [`apps/macos-pet-manager/`](apps/macos-pet-manager/)
- Product roadmap: [`docs/roadmap.md`](docs/roadmap.md)
- Architecture notes: [`docs/architecture.md`](docs/architecture.md)
- Asset policy: [`docs/asset-policy.md`](docs/asset-policy.md)
- This is a personal project and is not an official OpenAI product.

![CodpetPersonal preview](apps/macos-pet-manager/screenshots/codpetpersonal-preview.png)

[Watch the CodpetPersonal demo video](apps/macos-pet-manager/screenshots/codpetpersonal-demo.mp4)

### Repository Structure

```text
pets/
  <pet-folder>/
    pet.json          # Pet state mapping and metadata
    spritesheet.webp  # Spritesheet image
    base.png          # Static base thumbnail for documentation
index.json            # Generated catalog data in JSON
catalog.js            # Browser-ready catalog payload
index.html            # Ultra-minimalist showcase page
assets/
  brand/              # Logo, favicon, and social preview assets
  icons/              # Website interface icons
apps/
  macos-pet-manager/  # Native macOS CodpetPersonal prototype
  macos-hybrid-app/   # Experimental hybrid macOS prototype
docs/                 # Product roadmap and project notes
scripts/
  build_index.py      # Script to rebuild catalog index
  generate_thumbnails.py # Script to generate base thumbnails
  generate_favicon.py # Script to generate the browser tab icon
```

### Updating the Catalog
When you add, remove, or rename pets, rebuild the index using:
```bash
python3 scripts/build_index.py
```

### Generating Base Thumbnails
To update documentation thumbnails for all pets from their spritesheets:
```bash
python3 scripts/generate_thumbnails.py
```

### Generating Favicon
To update the high-definition favicon.png browser tab icon from the Blackbird assets:
```bash
python3 scripts/generate_favicon.py
```

---

<a name="简体中文"></a>
## 简体中文说明

**Codpet**（原名 Codex Pets）是一个由我个人持续整理的开发者宠物作品库，面向编辑器和开发环境。项目不接受第三方 pet 提交。

本仓库主要用途：
- **资源存储**：每只宠物拥有独立目录，包含其运行时元数据 (`pet.json`) 及精灵图 (`spritesheet.webp`)。
- **互动展示页**：部署于 [https://cod.pet/](https://cod.pet/) 的极简、高性能展示画廊。

### 原生 macOS App

**CodpetPersonal** 是一个实验性的原生 macOS pet 管理器，用于浏览已安装 pet、导入本地 pet、安装 pet，以及尝试将选中的 pet 应用到 Codex。

- 源码与构建说明：[`apps/macos-pet-manager/`](apps/macos-pet-manager/)
- 产品路线图：[`docs/roadmap.md`](docs/roadmap.md)
- 项目架构说明：[`docs/architecture.md`](docs/architecture.md)
- 素材政策：[`docs/asset-policy.md`](docs/asset-policy.md)
- 这是个人项目，不是 OpenAI 官方产品。

![CodpetPersonal 预览](apps/macos-pet-manager/screenshots/codpetpersonal-preview.png)

[观看 CodpetPersonal 录屏演示](apps/macos-pet-manager/screenshots/codpetpersonal-demo.mp4)

### 线上互动预览

在线浏览地址：**[https://cod.pet/](https://cod.pet/)**
- **悬停预览**：将鼠标悬停在任意宠物上，即可加速循环预览其所有状态的动态效果。
- **一键下载**：悬浮时点击 `Download` 即可一键下载包含该宠物完整元数据与精灵图的 `.zip` 压缩包。

### 目录结构

```text
pets/
  <宠物目录>/
    pet.json          # 宠物元数据及动作状态映射
    spritesheet.webp  # 精灵图
    base.png          # 用于文档的静态基础缩略图
index.json            # 自动生成的整站 JSON 索引
catalog.js            # 浏览器直接加载的 JS 索引
index.html            # 超极简的线上画廊单页面
assets/
  brand/               # Logo、favicon 和社交预览资源
  icons/               # 网站界面图标
apps/
  macos-pet-manager/   # 原生 macOS CodpetPersonal 原型
  macos-hybrid-app/    # 实验性混合 macOS 原型
docs/                  # 产品路线图和项目说明
scripts/
  build_index.py      # 重建整站索引的 Python 脚本
  generate_thumbnails.py # 从精灵图自动裁剪生成静态缩略图的脚本
  generate_favicon.py # 自动裁剪、居中缩放生成浏览器图标的脚本
```

### 更新索引
当您添加、删除或重命名宠物时，运行以下命令重建索引：
```bash
python3 scripts/build_index.py
```

### 生成基础缩略图
需要更新宠物在 README 文档中的静态缩略图时，运行：
```bash
python3 scripts/generate_thumbnails.py
```

### 生成浏览器图标
需要从黑鸟资源更新高清浏览器页签图标时，运行：
```bash
python3 scripts/generate_favicon.py
```

---

## Pets Gallery / 宠物画廊

Here is a visual list of all the **117** interactive pixel pets available in Codpet:

<table align="center">
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/cloudhoof/animated.svg?v=20260601c" width="96" alt="Cloudhoof" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/sporty-plush-puppy/animated.svg?v=20260601c" width="96" alt="Sporty Plush Puppy" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/caddie-pup/animated.svg?v=20260601c" width="96" alt="Caddie Pup" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/momo/animated.svg?v=20260601c" width="96" alt="Momo" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/nori/animated.svg?v=20260601c" width="96" alt="Nori" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/rosie/animated.svg?v=20260601c" width="96" alt="Rosie" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/aster/animated.svg?v=20260601c" width="96" alt="Aster" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/wizz/animated.svg?v=20260601c" width="96" alt="Wizz" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/taffy/animated.svg?v=20260601c" width="96" alt="Taffy" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/nyxo/animated.svg?v=20260601c" width="96" alt="Nyxo" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/nivo/animated.svg?v=20260601c" width="96" alt="Nivo" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/pico/animated.svg?v=20260601c" width="96" alt="Pico" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/mallow/animated.svg?v=20260601c" width="96" alt="Mallow" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/thorn/animated.svg?v=20260601c" width="96" alt="Thorn" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/purl/animated.svg?v=20260601c" width="96" alt="Purl" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/Cinder/animated.svg?v=20260601c" width="96" alt="Cinder" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brim/animated.svg?v=20260601c" width="96" alt="Brim" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/tomo/animated.svg?v=20260601c" width="96" alt="Tomo" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/petal/animated.svg?v=20260601c" width="96" alt="Petal" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/buzz/animated.svg?v=20260601c" width="96" alt="Buzz" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/mochi/animated.svg?v=20260601c" width="96" alt="Mochi" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brik/animated.svg?v=20260601c" width="96" alt="Brik" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/bun/animated.svg?v=20260601c" width="96" alt="Bun" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/mori/animated.svg?v=20260601c" width="96" alt="Mori" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/puff/animated.svg?v=20260601c" width="96" alt="Puff" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/inkbit/animated.svg?v=20260601c" width="96" alt="Inkbit" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/glowtail/animated.svg?v=20260601c" width="96" alt="Glowtail" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/luna/animated.svg?v=20260601c" width="96" alt="Luna" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/grit/animated.svg?v=20260601c" width="96" alt="Grit" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/skiff/animated.svg?v=20260601c" width="96" alt="Skiff" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/floe/animated.svg?v=20260601c" width="96" alt="Floe" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/rex/animated.svg?v=20260601c" width="96" alt="Rex" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/mack/animated.svg?v=20260601c" width="96" alt="Mack" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/moro/animated.svg?v=20260601c" width="96" alt="Moro" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/dusty/animated.svg?v=20260601c" width="96" alt="Dusty" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/pinka/animated.svg?v=20260601c" width="96" alt="Pinka" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/patch/animated.svg?v=20260601c" width="96" alt="Patch" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/miso/animated.svg?v=20260601c" width="96" alt="Miso" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/nib/animated.svg?v=20260601c" width="96" alt="Nib" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/rook/animated.svg?v=20260601c" width="96" alt="Rook" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/bruno/animated.svg?v=20260601c" width="96" alt="Bruno" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/pebb/animated.svg?v=20260601c" width="96" alt="Pebb" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/skipp/animated.svg?v=20260601c" width="96" alt="Skipp" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/pip/animated.svg?v=20260601c" width="96" alt="Pip" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brew/animated.svg?v=20260601c" width="96" alt="Brew" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/spike/animated.svg?v=20260601c" width="96" alt="Spike" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/spot/animated.svg?v=20260601c" width="96" alt="Spot" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/sunny/animated.svg?v=20260601c" width="96" alt="Sunny" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/glint/animated.svg?v=20260601c" width="96" alt="Glint" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/whisk/animated.svg?v=20260601c" width="96" alt="Whisk" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/snoo/animated.svg?v=20260601c" width="96" alt="Snoo" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/tomoo/animated.svg?v=20260601c" width="96" alt="Tomoo" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/jem/animated.svg?v=20260601c" width="96" alt="Jem" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/pinky/animated.svg?v=20260601c" width="96" alt="Pinky" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/dart/animated.svg?v=20260601c" width="96" alt="Dart" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/koi/animated.svg?v=20260601c" width="96" alt="Koi" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/heron/animated.svg?v=20260601c" width="96" alt="Heron" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/stilt/animated.svg?v=20260601c" width="96" alt="Stilt" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/marten/animated.svg?v=20260601c" width="96" alt="Marten" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/scarlet-ibis/animated.svg?v=20260601c" width="96" alt="Scarlet Ibis" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/rosefinch/animated.svg?v=20260601c" width="96" alt="Rosefinch" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/vermora/animated.svg?v=20260601c" width="96" alt="Vermora" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/tsuru/animated.svg?v=20260601c" width="96" alt="tsuru" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/velmour/animated.svg?v=20260601c" width="96" alt="velmour" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/flamingo/animated.svg?v=20260601c" width="96" alt="flamingo" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/white-eye/animated.svg?v=20260601c" width="96" alt="White-Eye" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/turaco/animated.svg?v=20260601c" width="96" alt="Turaco" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/cardinal/animated.svg?v=20260601c" width="96" alt="Cardinal" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/honeybee/animated.svg?v=20260601c" width="96" alt="Honeybee" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/blackbird/animated.svg?v=20260601c" width="96" alt="Blackbird" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/redcheek/animated.svg?v=20260601c" width="96" alt="Redcheek" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/droopy7/animated.svg?v=20260601c" width="96" alt="Droopy-7" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/knight/animated.svg?v=20260601c" width="96" alt="Knight" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/butch-dog/animated.svg?v=20260601c" width="96" alt="Butch Dog" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/rustango/animated.svg?v=20260601c" width="96" alt="Rustango" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/rustveil/animated.svg?v=20260601c" width="96" alt="Rustveil" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/rustbeak/animated.svg?v=20260601c" width="96" alt="RustBeak" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brassbun/animated.svg?v=20260601c" width="96" alt="Brassbun" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/copper-cat-package/animated.svg?v=20260601c" width="96" alt="Copper Cat" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brassprout/animated.svg?v=20260601c" width="96" alt="Brassprout" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/curlcap-pet/animated.svg?v=20260601c" width="96" alt="Curlcap" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/tinward-pet/animated.svg?v=20260601c" width="96" alt="Tinward" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/Budley-pet/animated.svg?v=20260601c" width="96" alt="Budley" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/walle/animated.svg?v=20260601c" width="96" alt="Scrapling" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/wheelbox/animated.svg?v=20260601c" width="96" alt="Wheelbox" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/battle-damaged-idle/animated.svg?v=20260601c" width="96" alt="Battle-Damaged Idle" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/rivet-puff/animated.svg?v=20260601c" width="96" alt="Rivet Puff" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/moss-maw/animated.svg?v=20260601c" width="96" alt="Moss Maw" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/tavern-lampbot/animated.svg?v=20260601c" width="96" alt="Tavern Lampbot" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/mean guard/animated.svg?v=20260601c" width="96" alt="Mean Guard" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/machi-foxy/animated.svg?v=20260601c" width="96" alt="Machi Foxy" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brine-star/animated.svg?v=20260601c" width="96" alt="Brine Star" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brinepaw/animated.svg?v=20260601c" width="96" alt="Brinepaw" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brigbeak/animated.svg?v=20260601c" width="96" alt="Brigbeak" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/dandy-beak/animated.svg?v=20260601c" width="96" alt="Dandy Beak" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/samorost-boxbot/animated.svg?v=20260601c" width="96" alt="Samorost Boxbot" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/wreckling/animated.svg?v=20260601c" width="96" alt="Wreckling" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/springtrap-machi/animated.svg?v=20260601c" width="96" alt="Springtrap Machi" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/freddy-machi/animated.svg?v=20260601c" width="96" alt="Freddy Machi" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/climber-stick/animated.svg?v=20260601c" width="96" alt="Climber" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/vendo/animated.svg?v=20260601c" width="96" alt="Vendo" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/pub-player/animated.svg?v=20260601c" width="96" alt="Pub Player" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/castle-guard/animated.svg?v=20260601c" width="96" alt="Castle Guard" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/pipe-wrench-robot/animated.svg?v=20260601c" width="96" alt="Pipe Wrench Robot" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/machi-cat/animated.svg?v=20260601c" width="96" alt="Machi Cat" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/tin-grin/animated.svg?v=20260601c" width="96" alt="Tin Grin" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/flying robot/animated.svg?v=20260601c" width="96" alt="Rotor Josef" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/scrib-codex-pet/animated.svg?v=20260601c" width="96" alt="Scrib" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/machi-chef/animated.svg?v=20260601c" width="96" alt="Machi Chef" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/machi-dog/animated.svg?v=20260601c" width="96" alt="Machi Dog" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/brass-reed/animated.svg?v=20260601c" width="96" alt="Brass Reed" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/the-drummer/animated.svg?v=20260601c" width="96" alt="The Drummer" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/smoking-robot/animated.svg?v=20260601c" width="96" alt="Smoking Robot" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/fat-robot/animated.svg?v=20260601c" width="96" alt="Fat Robot" /></td>
  </tr>
  <tr>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/machi-owl/animated.svg?v=20260601c" width="96" alt="Machi Owl" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/dog-creak/animated.svg?v=20260601c" width="96" alt="Dog Creak" /></td>
    <td align="center" valign="middle" width="160" height="160"><img src="pets/josef-bot/animated.svg?v=20260601c" width="96" alt="Josef Bot" /></td>
    <td align="center" valign="middle" width="160" height="160">&nbsp;</td>
    <td align="center" valign="middle" width="160" height="160">&nbsp;</td>
    <td align="center" valign="middle" width="160" height="160">&nbsp;</td>
  </tr>
</table>
