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
- `references/language-files.md` — extracted from `references/component.md` (where the section had been added in this same release). Cross-cutting: every extension type uses the same `_FIELD_<NAME>_LABEL` / `_DESC` form, the same `Text::plural()` `_0`/`_1`/`_MORE` plural keys, the same `Text::script()` JS-registration model, and the same `.sys.ini` vs `.ini` split. Only the prefix differs (`COM_*` / `MOD_*` / `PLG_*` / `LIB_*` / `TPL_*`). The new reference includes a per-type prefix table, file-naming and -location matrix, full naming conventions, plurals, JS-registration rules, and a "what NOT to do" list. `component.md` keeps a 2-paragraph stub at the same anchor.
- `references/service-provider.md` — extracted the universal `services/provider.php` wrapping pattern out of `references/component.md`. The `ServiceProviderInterface` + anonymous-class `register()` + `Container::registerServiceProvider()` + `Container::set()` shape is identical across components, modules, and plugins; only **which factories** get registered differs. The new reference covers the pattern, the per-type interface-and-factory table, the brittle parts (router 3-part contract, namespace mismatches, bound-class init failures), and DI rules of thumb. `component.md` keeps the worked component example with a one-paragraph cross-link intro at the section head.
- `references/manifest.md` — extracted the **universal** manifest XML elements out of `references/component.md`'s Manifest XML Template. Covers `<extension>` root attributes, the universal metadata block, `<scriptfile>`, `<files>`, `<media>`, `<languages>`, `<update>` / `<updateservers>` / update-server XML format, `<install>` SQL block, and the type-specific blocks (NOT covered here, with cross-links to each type's reference). `component.md` keeps the full component manifest example with a cross-link intro flagging which parts are universal vs component-specific.
- `references/component.md` Table of Contents updated to flag, on each affected line, which content lives in the new shared references.
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
- `references/plugin.md` — Service-provider example updated to the **Joomla 6.1+** `CMSPlugin::__construct($config = [])` signature (single arg, no `DispatcherInterface`). The legacy two-arg form is documented as a J5/J6.0 backward-compat option that emits `E_USER_DEPRECATED` on J6.1 and will be removed in J7.0. Quote of the deprecation message and a permalink to [`libraries/src/Plugin/CMSPlugin.php` on `joomla-cms` `6.1-dev`](https://github.com/joomla/joomla-cms/blob/6.1-dev/libraries/src/Plugin/CMSPlugin.php) included so the citation doesn't drift. Verified against [PR #46683](https://github.com/joomla/joomla-cms/pull/46683) and the migrated `plg_captcha_powcaptcha` provider.
- `references/plugin.md` — Removed the now-dead `use Joomla\Event\DispatcherInterface;` import from the plugin class example (it was only there to satisfy the old constructor's typed parameter).
- `references/service-provider.md` — Plugin row in the "what each extension type registers" table updated: plugins don't use any `Service\Provider\*` factory shorthand; the provider just `new`s the class with `$config`. Added the J6.0 → J6.1+ deprecation note pointing at `references/plugin.md` for the full story.

### Added (issue #3 — `references/module.md` audit)
- `references/module.md` — Table of Contents rebuilt to flag the universal-content references (`manifest.md`, `language-files.md`, `service-provider.md`, `install-script.md`) on each affected line, and to expose the new sections.
- `references/module.md` — Cross-link intros on the Manifest XML and Service Provider sections, deferring universal content to the shared references and keeping module-specific concretizations (`client="site"`/`administrator"`, `<config><fields name="params">`; `ModuleDispatcherFactory` + `HelperFactory` + `Module` factory triple).
- `references/module.md` — New **Language Files** section with `MOD_*` prefix specifics, the no-`folder=""` `<languages>` quirk, and a pointer to [`language-files.md`](references/language-files.md) for the full conventions.
- `references/module.md` — New **Web Asset Manager registration from the dispatcher** subsection inside Dispatcher, showing how to use `useStyle`/`useScript` against `joomla.asset.json`-resolved URIs and where to register `Text::script()` keys. Cross-references `gotchas.md` for URI-auto-resolution and the truthy-key trap.
- `references/module.md` — New **Caching** section explaining default per-instance keying, the two cases that need user attention (URL-dependent output, session-state-dependent output), and the absence of a public dispatcher-level cache-key hook.
- `references/module.md` — New **Install Script (Optional)** section noting that modules rarely need a `<scriptfile>` and pointing to [`install-script.md`](references/install-script.md) for the shared lifecycle pattern.
- `references/module.md` — New **Joomla 6.1 capabilities** section covering [PR #46772 (Versions for Modules / `#__ucm_history`)](https://github.com/joomla/joomla-cms/pull/46772) and [PR #46622 (`#__extensions.custom_data` JSON column)](https://github.com/joomla/joomla-cms/pull/46622). Neither requires existing module code to change; both are additive.

### Verified
- `references/module.md` Dispatcher section now cites [`AbstractModuleDispatcher` on `joomla-cms` `6.1-dev`](https://github.com/joomla/joomla-cms/blob/6.1-dev/libraries/src/Dispatcher/AbstractModuleDispatcher.php) for the constructor and `getLayoutData()` signatures.
- `references/module.md` Service Provider section now cites [`mod_articles_news/services/provider.php` on `joomla-cms` `6.1-dev`](https://github.com/joomla/joomla-cms/blob/6.1-dev/modules/mod_articles_news/services/provider.php) for the factory triple. Both confirm the existing patterns are current as of 6.1.
- `references/plugin.md` `getSubscribedEvents()` shape verified against [`plg_content_pagebreak` on `joomla-cms` `6.1-dev`](https://github.com/joomla/joomla-cms/blob/6.1-dev/plugins/content/pagebreak/src/Extension/PageBreak.php) — core plugins use string event-name keys (`'onContentPrepare' => 'onContentPrepare'`), not class constants. Verified that the abstract `ContentEvent` class on 6.1-dev deliberately does NOT define `ON_*` constants; typed event classes exist (e.g., `ContentPrepareEvent`) but only as handler-parameter types, not as keys for `getSubscribedEvents()`. The skill's existing string-key pattern matches upstream.

### Added (issue #4 — `references/plugin.md` audit)
- `references/plugin.md` Table of Contents rebuilt to flag the universal-content references (`manifest.md`, `language-files.md`, `service-provider.md`, `install-script.md`, `gotchas.md`) on each affected line, and to expose the new sections.
- `references/plugin.md` — Cross-link intro on the Manifest XML section deferring universal `<extension>` content to `manifest.md`. Plugin-specific bits (`group=""`, `<config>`) stay inline.
- `references/plugin.md` — New **Language Files** section with `PLG_<GROUP>_<ELEMENT>_*` prefix specifics, the locale-prefixed source-tree filename rule, the `$autoloadLanguage = true` requirement, the task-plugin `_TITLE` / `_DESC` suffix rule, and cross-links to `language-files.md` + `gotchas.md` for the full conventions.
- `references/plugin.md` — Cross-link intro on the Service Provider section deferring the universal wrapping pattern to `service-provider.md`. Plugin-specific note: plugins use no `Service\Provider\*` factory shorthand. Existing J6.1 dispatcher-constructor callout (from #12) is unchanged.
- `references/plugin.md` — Plugin class example now declares `protected $autoloadLanguage = true;` with a docblock explaining why. Existing event-subscription example expanded with a docblock that calls out the string-keys-vs-typed-event-class distinction (typed events are for handler parameter types, not for `getSubscribedEvents()` keys).
- `references/plugin.md` — New **Install Script (Optional)** section noting that plugins rarely need a `<scriptfile>` and pointing to `install-script.md` for the shared lifecycle pattern with the `Plg<Group><Element>InstallerScript` class-naming convention.
- `references/plugin.md` — New **Common Pitfalls** section covering the seven highest-frequency plugin install/load failure modes: manifest filename = `<element>.xml`, missing `$autoloadLanguage = true`, locale-prefixed source filename, class/namespace/folder mismatch, missing `setApplication()` in the service provider, two-arg constructor on J6.1+, and typed-Event-class confusion (the abstract `ContentEvent` base does not define `ON_*` constants — verified against 6.1-dev).

### Fixed (issue #4)
- `references/plugin.md` Manifest XML — language file path was `en-GB/plg_content_example.ini` (legacy admin-installed naming, would only work for files copied to `administrator/language/en-GB/`). Updated to `en-GB/en-GB.plg_content_example.ini` (locale-prefixed source-tree naming) so it matches `language-files.md` and the J5+ conventions Joomla actually expects from a plugin's own `language/` directory. Added the `.sys.ini` line that was missing — most plugins ship both runtime and `.sys.ini`.

### Fixed
- Removed brand-specific references (CWM / Proclaim / EventBooking) from `SKILL.md` and `references/module.md`. The skill is generic Joomla guidance and shouldn't lean on specific third-party extension code or naming conventions as canonical examples. Replaced with vendor-neutral placeholders (`<Vendor>`, `Acme`, generic `bookings`/`items`) and a generic note about projects shipping admin + site modules in one source tree. The `Joomla-Bible-Study/claude-skill-joomla` GitHub URL stays — that's the skill's own home, not borrowed code.

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
