# Contributing to the Joomla Skill

Thanks for considering a contribution. This skill is community-maintained and grows whenever someone shares a hard-won Joomla pattern.

## What this project actually is

Most "code" in this repo isn't code — it's the **prose Claude reads** when you ask it to help with a Joomla extension. The two things that matter most:

- **`skills/joomla/SKILL.md`** — the entry point. Frontmatter (`name`, `description`) controls *when* Claude loads the skill. Body controls *what guidance* Claude follows once loaded.
- **`skills/joomla/references/*.md`** — deeper guides Claude opens on demand for specific extension types (component, module, plugin, library).

Treat changes here like you would technical writing: clarity, accuracy, and correct cross-references matter more than line counts.

## Ways to contribute

- **Bug reports** — Claude gave bad/outdated Joomla advice. Paste the prompt and the bad response.
- **API drift** — Joomla 5 → 6 changed something the skill still teaches the old way.
- **New patterns** — a useful pattern (form fields, event subscribers, WAM, etc.) the skill doesn't cover yet.
- **New reference files** — for a sub-area we don't have yet (e.g. `template.md`, `cli.md`, `webservices.md`).
- **Edits for clarity** — tightening verbose sections, fixing examples, repairing broken links.
- **Build/release tooling** — improvements to `.github/workflows/release.yml`, validation, etc.

If you're not sure whether something belongs, open an issue first and ask.

## Setup

```bash
git clone https://github.com/Joomla-Bible-Study/claude-skill-joomla.git
cd claude-skill-joomla
```

No build step. Edit Markdown, save, test (see below).

## Testing your changes locally

Before opening a PR, install your working copy into Claude and use it on a real prompt.

### Quickest: symlink as a Claude Code skill

```bash
ln -sfn "$PWD/skills/joomla" ~/.claude/skills/joomla
```

Restart Claude Code (or `/reload-plugins` if you also have the plugin installed — and disable the plugin to avoid two copies fighting). Run a prompt that *should* trigger your change, e.g.:

> "Add a new view to my Joomla 6 component"

Check that:
1. The skill activates (Claude mentions it or behaves like it loaded the guidance).
2. Claude follows your new/edited guidance, not the old wording.
3. Cross-references to other reference files still resolve correctly.

### As a plugin (closer to what users get)

```bash
# from the repo root
ln -sfn "$PWD" ~/.claude/plugins/marketplaces/joomla-bible-study
```

Then in Claude Code:

```
/plugin install joomla@joomla-bible-study
/reload-plugins
```

### As a Claude.ai upload

```bash
(cd skills && zip -r /tmp/joomla-skill.zip joomla -x "*.DS_Store")
```

Upload `/tmp/joomla-skill.zip` at [claude.ai/settings/capabilities](https://claude.ai/settings/capabilities) → Skills.

## Authoring guidelines

### SKILL.md frontmatter is load-bearing

Claude only loads the skill when something in your prompt matches the `description`. Be specific and trigger-rich. Don't water it down with vague phrasing. Don't drop trigger keywords (Joomla, components, modules, plugins, MVC, service providers, manifest XML, Joomla 5/6, etc.) without a deliberate reason.

If you change `name` or `description`:
- update `.claude-plugin/plugin.json` to match,
- update the `description` field in `.claude-plugin/marketplace.json` if it diverges,
- mention the change in the PR — it's a behavior change for every existing user.

### Body and references

- **Be concrete.** Show the actual file structure, the actual XML tag, the actual class name. Vague advice ("set up a service provider") is worse than no advice; Claude will pattern-match on it and produce nonsense.
- **Cite [`joomla/joomla-cms`](https://github.com/joomla/joomla-cms) when behavior is non-obvious.** A link to the commit or file that proves the pattern saves future maintenance.
- **Target Joomla 6, backward compatible to 5** unless the section explicitly says otherwise. Note the version a feature appeared in if it matters.
- **PHP 8.2+ syntax** in examples (constructor promotion, readonly, enums, named args where they help).
- **PSR-12 PHP, Joomla ESLint config for JS.** Don't introduce styles that contradict either.
- **Keep examples runnable.** Half-pasted snippets confuse Claude. If the example needs surrounding context (a class declaration, a `use` statement) include it.
- **Cross-reference instead of duplicating.** If component scaffolding belongs in `component.md`, the SKILL.md section should say "see `references/component.md`" and stop.

### Markdown conventions

- GitHub-flavored Markdown.
- Code blocks always have a language tag (`php`, `xml`, `ini`, `bash`, etc.) — Claude uses the tag.
- Headings nest properly (no jumping `##` → `####`).
- One sentence per line in long-form prose helps diffs and reviews — but don't force it where it hurts readability.

### File sizes

Roughly: SKILL.md is the cost-paid-on-every-load file. Keep it focused. If a topic has grown past ~5 KB of body text, consider moving the deep dive into a new `references/<topic>.md` and leaving a short pointer in SKILL.md.

There's no enforced limit, but the smaller and sharper SKILL.md stays, the better the skill performs.

## Branching model

- **`main`** — release branch. Only updated via release PRs from `develop` (or hotfix branches). Every commit on `main` should correspond to a tagged release. The plugin marketplace pins users to a tagged version (see *Versioning and releases* below), so `main` is what version-pinned consumers see.
- **`develop`** — integration branch. All ongoing work lands here. Feature branches are cut from `develop` and merged back into it.
- **Feature branches** — short-lived, one logical change per branch, named `feat/<topic>`, `fix/<topic>`, `docs/<topic>`, or `chore/<topic>`.

## Pull request process

1. **Branch from `develop`.** Use a short, descriptive name (`feat/template-reference`, `fix/joomla6-form-field`, `docs/clarify-wam`).
2. **One logical change per PR.** Mixing a content rewrite with a workflow fix makes review harder than it needs to be.
3. **Target `develop` in your PR**, not `main`.
4. **Update `CHANGELOG.md`.** Move your bullet under `[Unreleased]`. Use Keep-a-Changelog sections (`### Added`, `### Changed`, `### Fixed`, `### Removed`).
5. **Open the PR with**:
   - what changed and why,
   - any prompts you tested with and what Claude did before/after,
   - a note if you changed the frontmatter (since that affects every existing user).
6. **A maintainer will install the branch and test it** against representative prompts before merging.

## Issue guidelines

A good bug report includes:

- the prompt you gave Claude,
- the response that was wrong,
- what you expected,
- which install path you used (Claude Code plugin / manual / Claude.ai upload),
- skill version (`v0.x.y`) and Claude product/version if you have it.

A good feature request describes the **Joomla scenario** you want better support for, not a guess at how the skill should be edited. Examples beat abstractions.

## Versioning and releases

We use [Semantic Versioning](https://semver.org/) where the SKILL.md content is treated as the public surface:

- **Patch (`v0.1.1`)** — typo fixes, broken-link repairs, clarifications that don't change recommended patterns.
- **Minor (`v0.2.0`)** — new guidance, new references, expanded coverage.
- **Major (`v1.0.0`)** — sections removed or restructured in a way that changes how someone uses the skill, or a breaking frontmatter change.

### How a release is cut (maintainers)

1. Open a release PR from `develop` → `main` titled `Release vX.Y.Z`.
2. On the PR branch, in one commit:
   - Move all `[Unreleased]` notes in `CHANGELOG.md` into a new `[X.Y.Z] — YYYY-MM-DD` section.
   - Bump `version` in `.claude-plugin/plugin.json`.
   - Bump `version` and the `source.ref` (`vX.Y.Z`) in `.claude-plugin/marketplace.json`.
3. Merge the PR into `main`.
4. Tag the merge commit: `git tag -a vX.Y.Z -m "vX.Y.Z — <summary>" && git push origin vX.Y.Z`.
5. The release workflow builds `joomla-skill-vX.Y.Z.zip` and attaches it to a GitHub Release with auto-generated notes.

The marketplace pin means existing users only see the new version after step 4 lands — `main` HEAD is the source of truth for "what version is current."

## Code of conduct

This project follows a [Code of Conduct](CODE_OF_CONDUCT.md) based on the Contributor Covenant. The short version: be kind, focused, and professional; critique the work, not the person; disagreements about Joomla patterns are welcome — cite sources.

## License

By contributing, you agree your contribution is licensed under **GPL-2.0-or-later**, matching the Joomla ecosystem.
