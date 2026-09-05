# Joomla Skills

A suite of 17 skills for **Joomla 5+ / 6 / 7** extension work — one broad skill for *building*
extensions, twelve security audits for *reviewing* them, and four workflows for *maintaining* them.

Runs in [Claude Code](https://claude.com/claude-code), [Claude.ai](https://claude.ai) and Claude
Desktop, [Codex](https://developers.openai.com/codex), and Qwen Code — all of which get the full
suite. Cursor, GitHub Copilot, Windsurf, Cline, and Aider get the extension-development guidance via
a generated rule-file package. See [Installation](#installation) for the channel matrix.

## What's in the suite

**Building** — `joomla`, the reference skill: components, modules, plugins, libraries, templates, with 25 on-demand reference files.

**Reviewing** — twelve security audits, each scoped so they don't overlap, cross-referencing each other rather than duplicating analysis:

| Audit | Finds |
|---|---|
| `audit-authz` | Controllers missing anti-CSRF, authentication, or authorisation checks — *is there a check at all?* |
| `audit-controller-exposure` | Checks that exist but target the wrong permission or asset; backend-only tasks reachable from site/api; unsafe uploads — *is it the right check?* |
| `audit-object-access` | IDOR/BOLA — *was the right check applied to the right record?* List queries leaking what detail views refuse, bulk ops authorising only the first ID, mass-assigned ownership. |
| `audit-sql-filtering` | Filter, user-state, and user-input values reaching SQL unparameterised, including the `ORDER BY` cases binding can't cover. |
| `audit-xss` | Reflected, stored, and DOM-based cross-site scripting in output paths. |
| `audit-sensitive-output` | Non-HTML sinks: response headers, CSV formula injection, log forging, error disclosure, mail header injection, cache isolation. |
| `audit-file-operations` | Path traversal, Zip Slip, symlink escape, arbitrary read/write/delete. |
| `audit-code-execution` | Shell injection, `eval`/dynamic include, unsafe deserialisation, PHAR, attacker-selected callables. |
| `audit-ssrf-redirects` | SSRF including cloud-metadata reachability, and open redirects via the `return` parameter. |
| `audit-secrets-crypto` | Committed credentials, predictable tokens, timing-unsafe comparison, weak or misused crypto. |
| `audit-package-surface` | What the build actually ships vs what's in git — stray files, reachable entry points, unsafe installers, vulnerable production deps. |
| `audit-jexec` | PHP files missing the `_JEXEC` direct-access guard. |

**Maintaining** — four upkeep workflows:

| Skill | Does |
|---|---|
| `joomla-deprecations` | Finds deprecated/removed core APIs from the official Joomla Manual lists, preserving your whole supported range via capability checks. |
| `php-conservative` | PHPCompatibility sweep over the PHP range `composer.json` actually declares — including why a clean report can be a lie. |
| `php-upcoming` | The next, unreleased PHP: runs the suite on it with `E_ALL`, because sniffs have no data for a version that hasn't shipped. |
| `e2e-tests` | Sets up host-side PHPUnit driving a disposable Docker stack over real HTTP — the layer that sees template output, headers, redirects, and session behaviour. |

The two shapes work differently and install differently. The **reference** skill activates on its own
whenever you mention Joomla work and loads deep-dive files as needed. The **workflow** skills are
procedural: they scan, report findings by severity, and stop for your feedback before touching any
code — so you invoke them deliberately, on a repository you want reviewed.

The audits and the four maintenance workflows are adapted from
[`nikosdion/pm-skill-demo`](https://github.com/nikosdion/pm-skill-demo) under MIT — see
[THIRD-PARTY.md](THIRD-PARTY.md).

## What the `joomla` skill covers

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
- Web Services REST API (JSON:API) — webservices plugin routes, `ApiController` / `JsonapiView`, API tokens, consuming the API
- Console commands (`php cli/joomla.php`) via console plugins and `AbstractCommand`
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
- `console-commands.md` — CLI commands for `php cli/joomla.php`: console plugin, `AbstractCommand`, container-loader registration, what breaks under the console
- `database.md` — install / update SQL, `#__` prefix, DDL-vs-DML rule
- `editor-api.md` — JoomlaEditor JS API + XTD button surface
- `form-fields.md` — built-in field types + custom-field authoring
- `layouts.md` — `LayoutHelper::render()`, override priority, sublayouts, key built-in layouts
- `menu-items.md` — site-view menu item type XML (request fields, params, useglobal, multi-layout)
- `packaging.md` — manual zip, build scripts, package extensions, include/exclude checklist, **changelog XML** for the in-admin changelog viewer
- `testing.md` — the three test layers, then PHPUnit + Jest patterns with real-CMS bootstrap for the two in-process ones (the E2E layer is the `e2e-tests` skill)
- `update-server.md` — update server XML, `<targetplatform>` regex, SHA hashes, per-type tweaks
- `web-assets.md` — `joomla.asset.json` schema, `useStyle`/`useScript`, dependencies
- `webservices-api.md` — Joomla JSON:API REST layer: route registration, `ApiController` / `JsonapiView`, API tokens, errors, CORS, consuming from PHP / JS / curl
- `gotchas.md` — hard-won J5/J6 pitfalls (controller parents, routing, WAM, modal cleanup, etc.)

## Requirements

- **Joomla:** 5.x, 6.x, or 7.x (target: native 6, backward compatible with 5)
- **PHP:** 8.3+ minimum and supported, 8.4 recommended (Joomla 6.x — see [manual.joomla.org/docs/get-started/technical-requirements](https://manual.joomla.org/docs/get-started/technical-requirements/))
- **Coding standard:** PSR-12 (PHP), Joomla ESLint config (JavaScript)

## Installation

Not every skill reaches every channel. This matrix is the short version; the options below have the detail.

| Channel | `joomla` | The 16 workflows | How |
|---|:--:|:--:|---|
| Claude Code plugin | ✅ | ✅ | One install, whole suite (Option 1) |
| Claude.ai / Claude Desktop | ✅ | ✅ | One zip upload **per skill** (Option 2) |
| Manual `~/.claude/skills/` | ✅ | ✅ | Copy or symlink each folder (Option 3) |
| Codex / Qwen Code | ✅ | ✅ | Plugin manifests in this repo (Option 4) |
| Cursor / Copilot / Windsurf / Cline / Aider | ✅ | ❌ | Universal package (Option 5) |

The workflow skills are deliberately absent from the universal package. That format flattens a skill into an always-loaded rule file, and a procedural audit that reports findings then waits for you is exactly wrong as an always-on rule — it would either fire when nobody asked or be ignored. This is a channel limitation, not a defect.

### Option 1 — Claude Code plugin (recommended for Claude Code users)

Inside Claude Code (CLI, desktop app, or IDE extension):

```
/plugin marketplace add Joomla-Bible-Study/joomla-skills
/plugin install joomla@joomla-bible-study
/reload-plugins
```

One install brings the whole suite. The skills become available as `joomla:joomla`, `joomla:audit-authz`, and so on, and update with `/plugin update`.

This is the best channel for the audit skills specifically — they need file access across a repository and can hand fix plans to parallel subagents.

### Option 2 — Claude.ai consumer app (web, Mac, Windows desktop)

The Claude.ai chat app does not load Claude Code plugins, but it does support uploading skills as a zip file. **One skill per zip** — so each release ships a separate asset per skill, and you upload only the ones you want.

1. In Claude.ai, open **Settings → Capabilities** and make sure **code execution** is enabled. The Skills menu does not appear until it is — its absence, not your plan, is the usual reason people can't find Skills.
2. Go to **Customize → Skills**, click the **+** button, then **Create skill**.
3. Open the [latest release](https://github.com/Joomla-Bible-Study/joomla-skills/releases/latest) and download the asset(s) you want:
   - `joomla-skill-vX.Y.Z.zip` — the extension-building skill
   - `audit-authz-skill-vX.Y.Z.zip`, `audit-xss-skill-vX.Y.Z.zip`, … — one per security audit (twelve)
   - `joomla-deprecations-skill-vX.Y.Z.zip`, `php-conservative-skill-vX.Y.Z.zip`, `php-upcoming-skill-vX.Y.Z.zip`, `e2e-tests-skill-vX.Y.Z.zip` — the four maintenance workflows
4. Drop in the zip. Claude reads the `name` and `description` from `SKILL.md`'s frontmatter.
5. Repeat for each additional skill.
6. Toggle each skill on for any Project (or globally) where you want it active.

To get the most out of the `joomla` skill here, keep the **Code execution / Analysis** tool on so Claude can generate scaffolded files as downloadable artifacts. Pair it with a Project that holds your component source for richer context.

The `audit-*` skills work in Claude.ai but are less effective than in Claude Code — they can only reason about files you have put in the conversation or the Project, not walk a repository.

### Option 3 — Manual copy into `~/.claude/skills/` (Claude Code, no plugin)

If you'd rather not use the plugin system:

```bash
git clone https://github.com/Joomla-Bible-Study/joomla-skills.git

# One skill…
cp -R joomla-skills/skills/joomla ~/.claude/skills/

# …or all of them
cp -R joomla-skills/skills/* ~/.claude/skills/
```

Or symlink so updates flow in with `git pull`:

```bash
ln -s "$PWD/joomla-skills/skills/joomla" ~/.claude/skills/joomla
```

### Option 4 — Codex and Qwen Code

Both read the same `skills/<name>/SKILL.md` layout Claude Code uses, so this repo carries their manifests directly and they get **all 17 skills** — not just the `joomla` one.

**Codex** — `.codex-plugin/plugin.json` declares the plugin and points at `./skills/`. Installation mirrors the Claude Code flow:

```
/plugin marketplace add Joomla-Bible-Study/joomla-skills
/plugin install joomla@joomla-bible-study
/reload-plugins
```

**Qwen Code** — `qwen-extension.json` plus the `QWEN.md` context file. Clone the repo and link it:

```bash
git clone https://github.com/Joomla-Bible-Study/joomla-skills.git
qwen extensions link "$PWD/joomla-skills"
```

Restart Qwen Code to load it.

> **Untested.** The Codex manifest is written against OpenAI's published `plugin.json` spec, and the layout requirement (`skills/<name>/SKILL.md`) matches what this repo already had. But neither CLI was available to verify an end-to-end install, so treat these two channels as best-effort. If either fails for you, an issue with the error is genuinely useful.

### Option 5 — Other AI coding tools (Cursor, GitHub Copilot, Windsurf, Cline, Aider)

Each release also ships a `joomla-skill-universal-vX.Y.Z.zip` artifact containing the `joomla` skill's guidance repackaged as project-root rule files for tools without a plugin system. One source, one shared `references/` directory. The workflow skills are not included — see the note under the matrix above.

1. Open the [latest release](https://github.com/Joomla-Bible-Study/joomla-skills/releases/latest).
2. Download `joomla-skill-universal-vX.Y.Z.zip` and unzip into your Joomla project's root.
3. Keep only the file(s) for the tool(s) you use (you can delete the rest); leave `references/` in place.

| Your tool                | Files to keep                                       |
|--------------------------|-----------------------------------------------------|
| Generic / AGENTS.md      | `AGENTS.md` + `references/`                         |
| Cursor                   | `.cursor/rules/joomla.mdc` + `references/`          |
| GitHub Copilot           | `.github/copilot-instructions.md` + `references/`   |
| Windsurf                 | `.windsurfrules` + `references/`                    |
| Cline                    | `.clinerules` + `references/`                       |
| Aider                    | `CONVENTIONS.md` + `references/` (then `aider --read CONVENTIONS.md`) |

Multiple tools can coexist in the same repo — each reads its own file and ignores the others. To rebuild the package locally from a clone of this repo, run `bash scripts/build-universal.sh`; output lands in `dist/universal/`.

## Usage

### The `joomla` skill

Once installed, it activates automatically whenever you mention Joomla extension development. Trigger phrases include:

- "Add a new view to my Joomla component"
- "Create a Joomla 5 plugin that listens for `onContentAfterSave`"
- "Scaffold a module that displays..."
- "Set up a service provider for..."
- "Register web assets via `joomla.asset.json`"
- "Write an install script for my J6 component"
- "Override a layout in my template"

The skill also matches the `J5` / `J6` / `J7` shorthands and specific minor versions (`Joomla 5.4`, `Joomla 6.1`, `Joomla 6.2`, `Joomla 7`).

You can also invoke it explicitly: ask Claude to "use the joomla skill" for any Joomla-based project.

### The workflow skills

These are deliberate, not ambient. Open Claude Code in the extension repository you want reviewed and ask for one by name:

- "Run the audit-authz skill on this component"
- "Audit this repo for SQL injection in filter values" → `audit-sql-filtering`
- "Check every PHP file for the `_JEXEC` guard" → `audit-jexec`
- "Are we clean on the PHP versions we claim to support?" → `php-conservative`

Each follows the same three steps: **report** findings ordered by severity with file and line references, **stop** for your feedback, then **plan** fixes as small independent units written to a `.gitignore`'d `.plans` directory for parallel execution. Nothing is changed before you have seen and accepted the findings.

The audits are scoped not to overlap, and they cross-reference each other rather than duplicating analysis. Three of them form a natural progression on controller access, and they answer different questions:

| Run | To ask |
|---|---|
| `audit-authz` | Is there a check at all? |
| `audit-controller-exposure` | Is it the *right* check? |
| `audit-object-access` | Was it applied to the *right record*? |

A component can pass the first two and still hand back a row the user may not see, which is why the third exists. For a full security pass, run all twelve — they are cheap individually, and each will tell you when a finding belongs to a sibling.

## Project context

This suite is maintained by [Christian Web Ministries](https://christianwebministries.org) (org currently published as `Joomla-Bible-Study` on GitHub) and was developed alongside production Joomla extensions including:

- [Proclaim](https://github.com/Joomla-Bible-Study/Proclaim) — Bible study management
- [CWMScriptureLinks](https://github.com/bcordis/CWMScriptureLinks) — auto-link Scripture references
- Other CWM extensions

Patterns are derived from the [joomla-cms](https://github.com/joomla/joomla-cms) core and real-world production components. The skill's `## Canonical sources` section in [`skills/joomla/SKILL.md`](skills/joomla/SKILL.md) lists every upstream reference (joomla-cms, manual.joomla.org + its [`joomla/Manual`](https://github.com/joomla/Manual) source repo, api.joomla.org, framework.joomla.org) Claude consults when verifying patterns — and the fallback order when WebFetch is unavailable.

## Contributing

Issues and PRs welcome. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for:

- what kinds of contributions are most useful (bug reports, API drift, new patterns/references)
- how to test changes locally before opening a PR (symlink a skill, install as a plugin, or upload a zip to Claude.ai) — including checking that the *right* skill activates, now that seventeen descriptions compete
- authoring guidelines for `SKILL.md` and references (frontmatter is load-bearing — be deliberate)
- versioning, CHANGELOG expectations, and the release flow

Quick rule of thumb: if you spot a Joomla 6 API change or an outdated pattern, file an issue with the prompt + the bad response and we'll work from there.

### Adding a skill to the suite

The build tooling discovers skills — it does not carry a list — so adding one is mostly a matter of putting it in the right shape:

1. Create `skills/<name>/SKILL.md` with YAML frontmatter carrying `name:` and `description:`. **`name:` must equal the directory name**; validation enforces it, because the release asset is named from the directory while Claude activates on the frontmatter name.
2. Keep the skill **self-contained**. Every link must resolve inside its own directory — a `../` link is rejected, because each skill is distributed as a standalone zip rooted at its own folder and anything outside it is gone once unzipped.
3. Put deep-dive material in `skills/<name>/references/*.md` and link to it from `SKILL.md`. Validation checks that every referenced file exists.
4. Run `bash scripts/validate.sh`. Nothing else needs editing — the release workflow builds a zip per skill and generates the release notes table from each skill's own description.

The one exception is `scripts/build-universal.sh`, which is pinned to a single skill on purpose. Only add a skill there if it is reference material of the same shape as `joomla`; the script's header comment explains why.

## License

GPL-2.0-or-later — matching the Joomla ecosystem.

The `audit-*` skills are adapted from MIT-licensed work by Nicholas K. Dionysopoulos and keep their original notice — see **[THIRD-PARTY.md](THIRD-PARTY.md)**.
