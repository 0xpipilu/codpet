# Codpet Roadmap

Codpet is a personal Codex Pet ecosystem. The repository currently combines the public gallery and the experimental native macOS manager so one project link can show the complete direction.

## Current surfaces

### `cod.pet`

The public gallery for browsing and previewing the curated pet collection.

### `macos-pet-manager/`

CodpetPersonal, an experimental native macOS manager for browsing installed pets, importing local folders, installing pets, and applying a selected pet to Codex.

## Next: CodpetPersonal cleanup

- Publish the manager source as a clearly labeled experimental prototype.
- Keep the website at the repository root so the existing cod.pet deployment remains stable.
- Add screenshots and a short architecture explanation.
- Separate generated build products, logs, and local test output from the source tree.
- Verify install and config-only apply before relying on live apply.

## Future: Codpet Studio

Codpet Studio is a separate planned macOS app for visual pet creation:

1. Import a user-provided reference image.
2. Show several visual style directions.
3. Let the user approve a canonical base look.
4. Generate and validate the animation rows.
5. Assemble a Codex-compatible pet package.
6. Ask for explicit confirmation before installing it locally.

The designer should treat local installation permission and AI-generation credentials as separate concerns. It should never ask for a ChatGPT password or read browser session data.

## Product boundaries

- Codpet is a personal curated project and does not accept third-party pet submissions.
- CodpetPersonal manages existing pets; Codpet Studio will create new pets.
- The website, manager, and future designer share the pet format but remain separate product surfaces.
- Codpet is not an official OpenAI product.
