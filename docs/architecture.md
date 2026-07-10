# Codpet Architecture / 项目架构

Codpet is a personal, curated Codex Pet project. This document explains how the public website, native macOS prototypes, and future product direction are separated inside one repository.

## Public website

The repository root is the deployment root for the static site at [cod.pet](https://cod.pet/). Keeping the site at the root avoids changing the existing Cloudflare Pages configuration.

```text
src/                 # Editable HTML, CSS, and JavaScript source
index.html           # Generated production page
index.json           # Generated pet catalog
catalog.js           # Browser-ready catalog payload
pets/<slug>/         # Public pet packages and preview assets
assets/brand/        # Website logo, favicon, and social preview image
assets/icons/        # Website UI icons
scripts/             # Catalog, thumbnail, README, and site build tools
```

The normal website build flow is:

```bash
python3 scripts/build_index.py
python3 scripts/build_readme.py
python3 scripts/build.py
```

The website is static. It does not require a project database or an application server.

## Native macOS apps

```text
apps/macos-pet-manager/  # CodpetPersonal manager prototype
apps/macos-hybrid-app/   # Experimental compatibility prototype
```

CodpetPersonal is for personal pet browsing, local import, installation, and configuration experiments. It is not an official OpenAI product and does not require a ChatGPT password, browser cookies, or ChatGPT session credentials.

The macOS prototypes share the pet package format, but they are not part of the website runtime. Their build products stay in ignored `dist/` and `.build/` directories.

## Local-only material

The following paths are intentionally ignored and are not part of the public repository:

```text
apps/_experiments/       # Unpublished local app experiments
apps/_local-assets/      # Local fonts and app assets with unverified redistribution rights
assets/source/           # Design source files and reference exports
scripts/local/           # Local diagnostics and one-off utilities
archives/                # Historical local archives
```

This separation keeps the public repository reviewable without deleting or hiding local work from the developer workspace.

## Future Codpet Studio

Codpet Studio is planned as a separate macOS surface for visual pet creation. It may share the package format and validation tools, but it should remain separate from CodpetPersonal's management responsibilities:

1. Import a user-provided reference image.
2. Let the user choose a visual direction.
3. Generate and review a canonical base look.
4. Assemble and validate the animated pet package.
5. Ask for explicit confirmation before local installation.

Local installation permission and AI-generation credentials must remain separate concerns.
