# Changelog

All notable changes to the Joomla skill are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html) where the SKILL.md content is treated as the public surface:

- **Major** — sections removed or restructured in a way that changes how the skill is used
- **Minor** — new guidance, new reference files, expanded coverage
- **Patch** — fixes, typos, clarifications, broken-link repairs

## [Unreleased]

### Added
- `## Canonical sources` section in `SKILL.md` listing the upstream references the skill is built from (joomla-cms repo, manual.joomla.org, api.joomla.org, framework.joomla.org, docs.joomla.org wiki) with WebFetch-first / fallback guidance and a preference for commit-pinned permalinks. Mirrored in `CONTRIBUTING.md` and `README.md`.
- `CONTRIBUTING.md` covering testing flow, authoring guidelines, PR process, issue guidelines, and versioning.
- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1, summarized + linked).
- Issue forms: `.github/ISSUE_TEMPLATE/bug_report.yml` and `feature_request.yml`, plus `config.yml` redirecting Joomla-CMS questions to upstream.
- `scripts/validate.sh` — structural lints for SKILL.md frontmatter, reference resolution, and `marketplace.json` source paths.
- `.github/workflows/validate.yml` — runs the validation script on every push to `main` and every PR.
- `develop` branch as the integration target; `main` is now release-only.

### Changed
- `marketplace.json` now uses an explicit GitHub object source pinned to `v0.1.0` (`{"source":"github","repo":"...","ref":"v0.1.0"}`) instead of a relative `./` path. This means `/plugin update` only delivers a new version once the `ref` is bumped on `main`, so audit work in progress on `develop` doesn't reach end users prematurely.

## [0.1.0] — 2026-04-29

### Added
- Initial release of the Joomla 5+/6 skill packaged as a Claude Code plugin.
- `SKILL.md` covering coding standards, modern Joomla MVC architecture, PSR-4 namespaces, dependency injection, service providers, and the Web Asset Manager.
- `references/component.md` — full component scaffolding (frontend + backend).
- `references/module.md` — module structure with dispatchers.
- `references/plugin.md` — plugin event subscribers (`SubscriberInterface`).
- `references/library.md` — shared library packages.
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` so users can install via `/plugin marketplace add Joomla-Bible-Study/claude-skill-joomla`.
- GitHub Actions workflow that builds and attaches a `joomla-skill-vX.Y.Z.zip` to each release for upload into the Claude.ai consumer app.

[Unreleased]: https://github.com/Joomla-Bible-Study/claude-skill-joomla/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Joomla-Bible-Study/claude-skill-joomla/releases/tag/v0.1.0
