# Joomla Skill for Claude

A skill for building **Joomla 5+ and Joomla 6** extensions — components, modules, plugins, and templates — using modern MVC architecture, PSR-4 namespaces, dependency injection, and service providers.

Works with [Claude Code](https://claude.com/claude-code) (as a plugin) and with [Claude.ai](https://claude.ai) (as an uploadable Skill).

## What this skill covers

- Scaffolding new components, modules, plugins, and templates
- Writing `services/provider.php` service providers
- MVC layer: controllers, models, views, layouts
- Manifest XML files (`<extension>`, install/uninstall scripts)
- Database migrations and schema files
- Language files (INI) and translation patterns
- Custom form fields and form rules
- Plugin event subscribers (`SubscriberInterface`)
- Module dispatchers
- Web Asset Manager (WAM) — registering CSS/JS, dependencies, attributes
- Backward-compatible patterns (Joomla 5 → 6, no compat plugin required)

Reference files in `skills/joomla/references/` provide deep-dive guidance, loaded on demand to keep the per-load token cost low.

**Per extension type:**

- `component.md` — full component scaffolding (frontend + backend)
- `module.md` — module structure with dispatchers
- `plugin.md` — plugin event subscribers (`SubscriberInterface`, `CMSPlugin`)
- `library.md` — shared library packages

**Cross-cutting (shared across extension types):**

- `manifest.md` — universal `<extension>` manifest XML elements
- `install-script.md` — `<scriptfile>` lifecycle hooks (`preflight` / `install` / `update` / `postflight` / `uninstall`)
- `language-files.md` — `.ini` filename / key-prefix / plural / `Text::script()` conventions
- `service-provider.md` — universal `services/provider.php` wrapping pattern + per-type binding table
- `component-router.md` — SEF URL router walkthrough (component-specific)

**Topical deep-dives:**

- `admin-routing.md` — `task=` vs `view=` URL routing and the checkout pattern preventing concurrent overwrites
- `coding-standards.md` — PSR-12 / PHPDoc / ESLint / PHPCS conventions
- `component-advanced.md` — toolbar API, batch, ordering, tags, versioning, workflow, webservices, mail templates, dashboards, custom rules
- `component-lifecycle.md` — model save flow, `prepareTable()`, `Table::bind()`/`store()`, filter forms, install script, config.xml, site-side differences, service interfaces, AJAX, HTMLHelper services, `showon`, fieldset tabs
- `database.md` — install / update SQL, `#__` prefix, DDL-vs-DML rule
- `editor-api.md` — JoomlaEditor JS API + XTD button surface
- `form-fields.md` — built-in field types + custom-field authoring
- `layouts.md` — `LayoutHelper::render()`, override priority, sublayouts, key built-in layouts
- `menu-items.md` — site-view menu item type XML (request fields, params, useglobal, multi-layout)
- `packaging.md` — manual zip, build scripts, package extensions, include/exclude checklist, **changelog XML** for the in-admin changelog viewer
- `testing.md` — PHPUnit + Jest patterns with real-CMS bootstrap
- `update-server.md` — update server XML, `<targetplatform>` regex, SHA hashes, per-type tweaks
- `web-assets.md` — `joomla.asset.json` schema, `useStyle`/`useScript`, dependencies
- `gotchas.md` — hard-won J5/J6 pitfalls (controller parents, routing, WAM, modal cleanup, etc.)

## Requirements

- **Joomla:** 5.x or 6.x (target: native 6, backward compatible with 5)
- **PHP:** 8.3+ minimum and supported, 8.4 recommended (Joomla 6.x — see [manual.joomla.org/docs/get-started/technical-requirements](https://manual.joomla.org/docs/get-started/technical-requirements/))
- **Coding standard:** PSR-12 (PHP), Joomla ESLint config (JavaScript)

## Installation

There are four install paths — three for Claude products, plus a universal package for other AI coding tools.

### Option 1 — Claude Code plugin (recommended for Claude Code users)

Inside Claude Code (CLI, desktop app, or IDE extension):

```
/plugin marketplace add Joomla-Bible-Study/claude-skill-joomla
/plugin install joomla@joomla-bible-study
/reload-plugins
```

The skill becomes available as `joomla:joomla` and updates with `/plugin update`.

### Option 2 — Claude.ai consumer app (web, Mac, Windows desktop)

The Claude.ai chat app does not load Claude Code plugins, but it does support uploading skills as a zip file.

1. Open the [latest release](https://github.com/Joomla-Bible-Study/claude-skill-joomla/releases/latest).
2. Download the `joomla-skill-vX.Y.Z.zip` asset.
3. In Claude.ai, go to [Settings → Capabilities](https://claude.ai/settings/capabilities) (or in the desktop app: profile menu → **Settings** → **Capabilities**).
4. Find the **Skills** section and choose **Create skill** / **Upload skill**.
5. Drop in the zip. Claude reads the `name` and `description` from `SKILL.md`'s frontmatter.
6. Toggle the skill on for any Project (or globally) where you want it active.

To get the most out of the skill in Claude.ai, enable the **Code execution / Analysis** tool for the conversation so Claude can generate scaffolded files as downloadable artifacts. Pair it with a Project that holds your component source for richer context.

### Option 3 — Manual copy into `~/.claude/skills/` (Claude Code, no plugin)

If you'd rather not use the plugin system:

```bash
git clone https://github.com/Joomla-Bible-Study/claude-skill-joomla.git
cp -R claude-skill-joomla/skills/joomla ~/.claude/skills/
```

Or symlink so updates flow in with `git pull`:

```bash
ln -s "$PWD/claude-skill-joomla/skills/joomla" ~/.claude/skills/joomla
```

### Option 4 — Other AI coding tools (Cursor, GitHub Copilot, Windsurf, Cline, Aider, Codex)

Each release also ships a `joomla-skill-universal-vX.Y.Z.zip` artifact containing the same Joomla guidance repackaged as project-root rule files for non-Claude tools. One source, one shared `references/` directory.

1. Open the [latest release](https://github.com/Joomla-Bible-Study/claude-skill-joomla/releases/latest).
2. Download `joomla-skill-universal-vX.Y.Z.zip` and unzip into your Joomla project's root.
3. Keep only the file(s) for the tool(s) you use (you can delete the rest); leave `references/` in place.

| Your tool                | Files to keep                                       |
|--------------------------|-----------------------------------------------------|
| OpenAI Codex / generic   | `AGENTS.md` + `references/`                         |
| Cursor                   | `.cursor/rules/joomla.mdc` + `references/`          |
| GitHub Copilot           | `.github/copilot-instructions.md` + `references/`   |
| Windsurf                 | `.windsurfrules` + `references/`                    |
| Cline                    | `.clinerules` + `references/`                       |
| Aider                    | `CONVENTIONS.md` + `references/` (then `aider --read CONVENTIONS.md`) |

Multiple tools can coexist in the same repo — each reads its own file and ignores the others. To rebuild the package locally from a clone of this repo, run `bash scripts/build-universal.sh`; output lands in `dist/universal/`.

## Usage

Once installed, the skill activates automatically whenever you mention Joomla extension development. Trigger phrases include:

- "Add a new view to my Joomla component"
- "Create a Joomla 5 plugin that listens for `onContentAfterSave`"
- "Scaffold a module that displays..."
- "Set up a service provider for..."
- "Register web assets via `joomla.asset.json`"
- "Write an install script for my J6 component"
- "Override a layout in my template"

The skill also matches the `J5` / `J6` / `J7` shorthands and specific minor versions (`Joomla 5.4`, `Joomla 6.1`, `Joomla 6.2`, `Joomla 7`).

You can also invoke it explicitly: ask Claude to "use the joomla skill" for any Joomla-based project.

## Project context

This skill is maintained by [Christian Web Ministries](https://christianwebministries.org) (org currently published as `Joomla-Bible-Study` on GitHub) and was developed alongside production Joomla extensions including:

- [Proclaim](https://github.com/Joomla-Bible-Study/Proclaim) — Bible study management
- [CWMScriptureLinks](https://github.com/bcordis/CWMScriptureLinks) — auto-link Scripture references
- Other CWM extensions

Patterns are derived from the [joomla-cms](https://github.com/joomla/joomla-cms) core and real-world production components. The skill's `## Canonical sources` section in [`skills/joomla/SKILL.md`](skills/joomla/SKILL.md) lists every upstream reference (joomla-cms, manual.joomla.org + its [`joomla/Manual`](https://github.com/joomla/Manual) source repo, api.joomla.org, framework.joomla.org) Claude consults when verifying patterns — and the fallback order when WebFetch is unavailable.

## Contributing

Issues and PRs welcome. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for:

- what kinds of contributions are most useful (bug reports, API drift, new patterns/references)
- how to test changes locally before opening a PR (symlink as a skill, install as a plugin, or upload zip to Claude.ai)
- authoring guidelines for `SKILL.md` and references (frontmatter is load-bearing — be deliberate)
- versioning, CHANGELOG expectations, and the release flow

Quick rule of thumb: if you spot a Joomla 6 API change or an outdated pattern, file an issue with the prompt + the bad response and we'll work from there.

## License

GPL-2.0-or-later — matching the Joomla ecosystem.
