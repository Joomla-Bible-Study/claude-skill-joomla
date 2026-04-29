# Joomla Skill for Claude Code

A [Claude Code](https://claude.com/claude-code) skill for building **Joomla 5+ and Joomla 6** extensions — components, modules, plugins, and templates — using modern MVC architecture, PSR-4 namespaces, dependency injection, and service providers.

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

Reference files in `skills/joomla/references/` provide deep-dive guidance for each extension type:

- `component.md` — full component scaffolding (frontend + backend)
- `module.md` — module structure with dispatchers
- `plugin.md` — plugin event subscribers
- `library.md` — shared library packages

## Requirements

- **Joomla:** 5.x or 6.x (target: native 6, backward compatible with 5)
- **PHP:** 8.2+ (Joomla 6 minimum), 8.3+ recommended
- **Coding standard:** PSR-12 (PHP), Joomla ESLint config (JavaScript)

## Installation

### Option 1 — Install as a Claude Code plugin (recommended)

In Claude Code:

```
/plugin marketplace add Joomla-Bible-Study/claude-skill-joomla
/plugin install joomla@joomla-bible-study
```

### Option 2 — Manual install

Clone the repo and copy the skill into your Claude Code skills directory:

```bash
git clone https://github.com/Joomla-Bible-Study/claude-skill-joomla.git
cp -R claude-skill-joomla/skills/joomla ~/.claude/skills/
```

Or symlink so you can pull updates with `git pull`:

```bash
ln -s "$PWD/claude-skill-joomla/skills/joomla" ~/.claude/skills/joomla
```

## Usage

Once installed, the skill activates automatically whenever you mention Joomla extension development. Trigger phrases include:

- "Add a new view to my Joomla component"
- "Create a Joomla 5 plugin that listens for `onContentAfterSave`"
- "Scaffold a module that displays..."
- "Set up a service provider for..."

You can also invoke it explicitly: ask Claude to "use the joomla skill" for any Joomla-based project.

## Project context

This skill is maintained by [Christian Web Ministries](https://christianwebministries.org) (org currently published as `Joomla-Bible-Study` on GitHub) and was developed alongside production Joomla extensions including:

- [Proclaim](https://github.com/Joomla-Bible-Study/Proclaim) — Bible study management
- [CWMScriptureLinks](https://github.com/bcordis/CWMScriptureLinks) — auto-link Scripture references
- Other CWM extensions

Patterns are derived from the [joomla-cms](https://github.com/joomla/joomla-cms) core and real-world production components.

## Contributing

Issues and PRs welcome. If you spot a Joomla 6 API change, an outdated pattern, or have an additional reference to contribute, open an issue first to discuss.

## License

GPL-2.0-or-later — matching the Joomla ecosystem.
