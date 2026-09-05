# Contributing to the Joomla Skills

Thanks for considering a contribution. These skills are community-maintained and grow whenever someone shares a hard-won Joomla pattern.

## What this project actually is

Most "code" in this repo isn't code — it's the **prose Claude reads** when you ask it to help with a Joomla extension. Every directory under `skills/` is an independent skill with its own `SKILL.md`, released as its own zip. They come in two shapes, and the shape decides how you edit one:

**Reference — `skills/joomla/`.** Loads automatically whenever you mention Joomla work, and opens deep-dive files on demand.

- **`SKILL.md`** — the entry point. Frontmatter (`name`, `description`) controls *when* Claude loads it. Body controls *what guidance* Claude follows once loaded.
- **`references/*.md`** — deeper guides opened on demand for specific areas (component, module, plugin, library, testing, …).

**Workflow — `skills/audit-*/`, `skills/e2e-tests/`, `skills/php-*/`, `skills/joomla-deprecations/`.** Procedural, invoked deliberately, self-contained in one `SKILL.md` with no `references/`. They share a three-step contract: **report** findings by severity with file and line references, **stop** for the user's feedback, then **plan** fixes into a `.gitignore`'d `.plans` directory. Preserve that shape when editing one — the stop-for-feedback step is the point, not ceremony.

The twelve `audit-*` skills are also a **closed cross-reference set**: each names its siblings to say what it does *not* cover. If you add or remove one, fix the boundary sections that name it, or the model goes looking for a skill that isn't there.

Treat changes here like you would technical writing: clarity, accuracy, and correct cross-references matter more than line counts.

## Ways to contribute

- **Bug reports** — Claude gave bad/outdated Joomla advice. Paste the prompt and the bad response.
- **API drift** — Joomla 5 → 6 changed something a skill still teaches the old way.
- **New patterns** — a useful pattern (form fields, event subscribers, WAM, etc.) the `joomla` skill doesn't cover yet.
- **New reference files** — for a sub-area of the `joomla` skill we don't have yet.
- **New skills** — a distinct procedural workflow. See [Adding a new skill](#adding-a-new-skill) below.
- **Audit accuracy** — a workflow that misses a real class of bug, or reports false positives on correct Joomla code. Both are worth an issue.
- **Edits for clarity** — tightening verbose sections, fixing examples, repairing broken links.
- **Build/release tooling** — improvements to `.github/workflows/release.yml`, validation, etc.

If you're not sure whether something belongs, open an issue first and ask.

Two things that deliberately **don't** belong here: house-style rules specific to one vendor's extensions (key prefixes, spelling conventions, product vocabulary), and content for Joomla versions outside the declared support window. Both make the skills wrong for everyone else.

## Setup

```bash
git clone https://github.com/Joomla-Bible-Study/joomla-skills.git
cd joomla-skills
```

No build step. Edit Markdown, save, test (see below).

## Testing your changes locally

Before opening a PR, install your working copy into Claude and use it on a real prompt.

First, run the validator — it catches the structural mistakes before Claude ever sees them:

```bash
bash scripts/validate.sh
```

### Quickest: symlink as a Claude Code skill

```bash
# the skill you changed
ln -sfn "$PWD/skills/joomla" ~/.claude/skills/joomla

# …or all of them
for d in "$PWD"/skills/*/; do ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"; done
```

Restart Claude Code (or `/reload-plugins` if you also have the plugin installed — and disable the plugin to avoid two copies fighting). Run a prompt that *should* trigger your change, e.g.:

> "Add a new view to my Joomla 6 component"

Check that:
1. The skill activates (Claude mentions it or behaves like it loaded the guidance).
2. **The right one activates.** With seventeen skills installed, a prompt that should reach `audit-sql-filtering` can be caught by `joomla` instead, or vice versa. Test the prompt you'd expect to route to the skill you edited, and one that shouldn't.
3. Claude follows your new/edited guidance, not the old wording.
4. Cross-references to other reference files and sibling skills still resolve correctly.

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

One skill per zip, with the skill folder as the archive root — the same shape the release workflow builds:

```bash
(cd skills && zip -r /tmp/joomla-skill.zip joomla -x "*.DS_Store")
```

In Claude.ai, enable code execution under **Settings → Capabilities** first (the Skills menu doesn't appear until you do), then go to **Customize → Skills**, click **+**, and choose **Create skill**.

## Adding a new skill

The tooling discovers skills rather than carrying a list, so adding one is mostly a matter of shape:

1. Create `skills/<name>/SKILL.md` with frontmatter carrying `name:` and `description:`. **`name:` must equal the directory name** — validation enforces it, because the release asset is named from the directory while Claude activates on the frontmatter name.
2. Keep it **self-contained**. Every link must resolve inside its own directory; a `../` link is rejected, because each skill ships as a standalone zip rooted at its own folder and anything outside it is gone once unzipped.
3. Put deep-dive material in `skills/<name>/references/*.md` and link to it. Validation checks every referenced file exists.
4. If it's an audit, add the boundary cross-references to and from its siblings so the set stays closed.
5. Run `bash scripts/validate.sh`. Nothing else needs editing — the release workflow builds a zip per skill and generates its notes table from each skill's own description, and Codex and Qwen Code discover `skills/*/` on their own.

The one exception is `scripts/build-universal.sh`, pinned to a single skill on purpose. Only add a skill there if it's reference material of the same shape as `joomla`; the script's header comment explains why a procedural workflow can't work as an always-on rule file.

## Authoring guidelines

### SKILL.md frontmatter is load-bearing

Claude only loads a skill when something in your prompt matches its `description`. Be specific and trigger-rich. Don't water it down with vague phrasing. Don't drop trigger keywords (Joomla, components, modules, plugins, MVC, service providers, manifest XML, Joomla 5/6, etc.) without a deliberate reason.

With seventeen skills installed, descriptions also compete. A workflow skill's description should say what it *finds* and, where it's easily confused with a sibling, what it *doesn't* cover — that last clause is what keeps `audit-authz` and `audit-controller-exposure` from both firing on the same prompt.

If you change `name` or `description`:
- **`name` must still match the directory** — validation fails otherwise,
- keep the four manifests describing what the suite actually contains — `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, and `qwen-extension.json` (they describe the plugin as a whole, not one skill),
- mention the change in the PR — it's a behavior change for every existing user.

Note that the release notes table is generated from each skill's `description`, cut at the first sentence or em-dash clause. A description whose lead clause doesn't stand alone produces an odd-looking release page; the workflow prints the table to the job log so you can check.

### Body and references

- **Be concrete.** Show the actual file structure, the actual XML tag, the actual class name. Vague advice ("set up a service provider") is worse than no advice; Claude will pattern-match on it and produce nonsense.
- **Cite [`joomla/joomla-cms`](https://github.com/joomla/joomla-cms) when behavior is non-obvious.** A link to the commit or file that proves the pattern saves future maintenance. The `joomla` skill's `## Canonical sources` section lists the upstream references it is built from — verify changes against them, and prefer **commit-pinned permalinks** to `joomla-cms` over branch links so the citation does not silently drift.
- **Target Joomla 6, backward compatible to 5** unless the section explicitly says otherwise. Note the version a feature appeared in if it matters.
- **PHP 8.2+ syntax** in examples (constructor promotion, readonly, enums, named args where they help).
- **PSR-12 PHP, Joomla ESLint config for JS.** Don't introduce styles that contradict either.
- **Keep examples runnable.** Half-pasted snippets confuse Claude. If the example needs surrounding context (a class declaration, a `use` statement) include it.
- **Cross-reference instead of duplicating.** If component scaffolding belongs in `component.md`, the SKILL.md section should say "see `references/component.md`" and stop. The same applies across skills: an audit that notices a finding belonging to a sibling should name the sibling in one line, not re-derive the analysis.
- **Never link outside your own skill directory.** A `../` link is rejected by validation — each skill ships as a standalone zip, so a path that escapes its folder points at nothing for anyone who installed it that way.
- **Third-party material keeps its notice.** Several workflow skills are adapted from MIT-licensed work and carry an attribution footer plus a row in [THIRD-PARTY.md](THIRD-PARTY.md). If you edit one substantially, leave the footer; if you add material from elsewhere, add the notice.

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

The suite ships as one versioned plugin — every skill releases together at the same version. We use [Semantic Versioning](https://semver.org/) where skill content is treated as the public surface:

- **Patch (`v0.1.1`)** — typo fixes, broken-link repairs, clarifications that don't change recommended patterns.
- **Minor (`v0.2.0`)** — new guidance, new references, expanded coverage.
- **Major (`v1.0.0`)** — sections removed or restructured in a way that changes how someone uses the skill, or a breaking frontmatter change.

### How a release is cut (maintainers)

1. Open a release PR from `develop` → `main` titled `Release vX.Y.Z`.
2. On the PR branch, in one commit:
   - Move all `[Unreleased]` notes in `CHANGELOG.md` into a new `[X.Y.Z] — YYYY-MM-DD` section.
   - Bump `version` in **all four** manifests: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `qwen-extension.json`.
   - Bump the `source.ref` (`vX.Y.Z`) in `.claude-plugin/marketplace.json`.
3. Merge the PR into `main`.
4. Tag the merge commit: `git tag -a vX.Y.Z -m "vX.Y.Z — <summary>" && git push origin vX.Y.Z`.
5. The release workflow builds **one zip per skill** — `joomla-skill-vX.Y.Z.zip` plus `<skill>-skill-vX.Y.Z.zip` for each of the others — along with `joomla-skill-universal-vX.Y.Z.zip`, and attaches them to a GitHub Release. The notes table is generated from each skill's own `description`; check it in the job log.

Steps 2 and 3 are both enforced: `scripts/validate.sh` fails if any of the four manifests disagree on `version`, or if `source.ref` doesn't match that version. Those checks exist because each host reads its own manifest — a stale one silently keeps serving the previous release *to that host only*, which is the hardest kind of drift to notice, and leaving `source.ref` behind installs the previous release for everyone.

The marketplace pin means existing users only see the new version after step 4 lands — `main` HEAD is the source of truth for "what version is current."

## Code of conduct

This project follows a [Code of Conduct](CODE_OF_CONDUCT.md) based on the Contributor Covenant. The short version: be kind, focused, and professional; critique the work, not the person; disagreements about Joomla patterns are welcome — cite sources.

## License

By contributing, you agree your contribution is licensed under **GPL-2.0-or-later**, matching the Joomla ecosystem.
