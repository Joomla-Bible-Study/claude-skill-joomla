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
- `references/editor-api.md` — extracted from `SKILL.md` so the editor JS/PHP API surface is loaded only when needed.
- `references/form-fields.md` — extracted built-in field reference and custom-field authoring guide.
- `references/testing.md` — extracted PHPUnit + Jest patterns including real-CMS bootstrap and four high-stakes test gotchas.
- `references/gotchas.md` — extracted hard-won J5/J6 pitfalls (controller parents, routing, WAM, Bootstrap 5.3 dark mode, modal cleanup, `getStoreId()`, etc.).
- Quick Start now lists the four new cross-cutting references alongside the existing `component.md` / `module.md` / `plugin.md` / `library.md` set.
- `references/component-router.md` — extracted the 304-line Router (SEF URLs) walkthrough from `references/component.md` so it loads on demand. `component.md` keeps a short stub at the same anchor.
- `references/install-script.md` — extracted the install/update lifecycle PHP pattern out of `references/component.md` because it is **cross-cutting**: components, modules, and plugins all use the same `preflight` / `install` / `update` / `postflight` / `uninstall` hooks via `<scriptfile>`, with only the script-class name (`Com_*`, `Mod_*`, `Plg<Group><Element>*`) and manifest path differing. The new reference includes the hook table, the per-extension class-naming convention, a full component example, and short module + plugin skeletons. `component.md` keeps a stub pointing here. `references/module.md` and `references/plugin.md` still need cross-references; that's noted as follow-up for #3 and #4.
- `references/component.md` — new **Language Files** section with `en-GB.com_<element>.ini` / `.sys.ini` examples, key-naming conventions, and a note on plural/script-registered strings. Closes the gap flagged in #2 where the manifest declared `<languages>` but no `.ini` content was ever shown.
- `references/component.md` — new **Database Schema & Migrations** section with `sql/install.mysql.utf8.sql` example (standard core columns, indexes, charset), `sql/updates/mysql/X.Y.Z.sql` per-version delta example, the DDL-only / idempotent / no-rollback rules, and the `#__schemas` tracking explanation.
- `references/component.md` — new **Other View Types** subsection at the end of View Patterns covering `JsonView`, `RawView` (via `format=raw`), and `FeedView`, with a cross-link to the Webservices API section for JSON:API.

### Changed
- `marketplace.json` now uses an explicit GitHub object source pinned to `v0.1.0` (`{"source":"github","repo":"...","ref":"v0.1.0"}`) instead of a relative `./` path. This means `/plugin update` only delivers a new version once the `ref` is bumped on `main`, so audit work in progress on `develop` doesn't reach end users prematurely.
- `SKILL.md` PHP requirement headline updated from "8.2+ (Joomla 6 minimum), 8.3+ recommended" to "8.3+ minimum and supported, 8.4 recommended" for Joomla 6.x, with a citation to [manual.joomla.org/docs/get-started/technical-requirements](https://manual.joomla.org/docs/get-started/technical-requirements/). The previous wording understated the J6.x minimum.
- All four in-file PHP-version code examples bumped from 8.2 → 8.3 to match the J6.x floor (changelog `<note>`, update-server `<php_minimum>`, install-script `$minimumPhp`, `composer.json` `php` constraint). The `$minimumJoomla` example value is unchanged because it declares which Joomla versions the extension supports — independent of PHP — and a J6-native extension that also supports J5.x must still pin PHP to 8.3.0 (the highest supported-Joomla floor).
- `SKILL.md` shrunk from 3594 to ~1180 fewer lines by replacing the in-file Editor API, Form Fields, Testing, and Common Gotchas sections with short pointer stubs that name the topics covered. Reduces the per-load token cost without losing any content (full text preserved in the new `references/*.md` files).
- `references/component.md` Table of Contents updated to reflect the new sections (Language Files, Database Schema & Migrations, Other View Types) and the Router stub pointing at `component-router.md`.

### Fixed
- `references/component.md` — `\Namespace\Component\Example\…` typos in two `@var` type-hint comments (List and Edit views) replaced with `\Vendor\…` so IDEs resolve the model class correctly.
- `references/component.md` — `CustomlistField` example was calling `HTMLHelper::_('select.option', …)` without importing `Joomla\CMS\HTML\HTMLHelper`. Added the missing `use` statement so the example runs as-is.
- `references/component.md` — Install/Update Script section now opens with an explicit scope split: PHP lifecycle hooks here, DDL in the new Database Schema & Migrations section. Adds a forward cross-link to the schema section, a reverse note in the migrations section, and a one-line guard against the common mistake of putting `ALTER TABLE` in `postflight()` (races during partial upgrades because schema files run first). Bumped the install-script `$minimumPhp` example from `'8.2.0'` to `'8.3.0'` to match the J6.x floor; the previous value was missed in the SKILL.md PHP audit because it lives in the reference, not the SKILL itself.

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
