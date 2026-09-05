# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

A suite of **17 skills** for Joomla 5+/6/7 work. Almost nothing here is code — it is the prose Claude
reads. Every directory under `skills/` is an independent skill released as its own zip.

Two shapes, and the shape decides how you edit one:

- **Reference** — `skills/joomla/`. Loads automatically on Joomla work; opens `references/*.md` on
  demand. Generative: "how do I write this correctly."
- **Workflow** — everything else. Invoked deliberately. Procedural: "is this existing code wrong."
  All 16 share a three-step contract — **report** findings by severity with file/line references,
  **stop** for the user, then **plan** fixes into a `.gitignore`'d `.plans` directory. The
  stop-for-feedback step is the point, not ceremony. Do not "streamline" it into auto-fixing.

## Invariants — enforced by `scripts/validate.sh`

Run `bash scripts/validate.sh` after any structural change. Read the script for the full set; these
are the ones whose *reasons* are not obvious from the code:

- **`name:` in frontmatter must equal the directory name.** The release asset is named from the
  directory while Claude activates on the frontmatter name; a mismatch silently misnames one.
- **Skill names must be unique** across the suite — duplicates shadow each other once installed.
- **No `../` links in a `SKILL.md`.** Each skill ships as a standalone zip rooted at its own folder,
  so anything outside it is gone once unzipped. This is the exact defect that makes upstream's
  stub-plus-shared-`commands/` layout unshippable, and why every workflow here is self-contained.
- **Every `references/…` path resolves** inside that skill's own directory.
- **All four manifests agree on `version`**, and `marketplace.json`'s `source.ref` matches it. Each
  host reads its own manifest, so a stale one keeps serving the previous release *to that host
  alone*; and the ref decides which tree `/plugin install` actually fetches, so bumping versions but
  not the ref serves the previous release to everyone.
- **The Codex manifest's `interface` block is complete.** A missing field there makes the plugin
  unlistable rather than raising an error, so it is validated field by field.

## Scope boundaries — preserve these

The twelve audits are a **closed cross-reference set**: each names its siblings to say what it does
*not* cover, and every name resolves. This is load-bearing. The tempting refactor — "twelve audits is
silly, merge them into one security skill" — destroys the property that makes them useful, because a
single generic input-validation audit reports shallowly on everything and thoroughly on nothing.

Controller access splits three ways, and the distinction is the whole design:

| Skill | Owns |
|---|---|
| `audit-authz` | Is there a check **at all**? (missing CSRF / authn / authz) |
| `audit-controller-exposure` | Is it the **right** check? (wrong permission or asset, backend-only tasks reachable from site/api, upload acceptance) |
| `audit-object-access` | Was it applied to the **right record**? (IDOR/BOLA, per-object isolation) |

The rest are organised by **sink family**: `audit-xss` owns browser execution contexts;
`audit-sensitive-output` owns non-HTML sinks and cache isolation; `audit-sql-filtering` owns SQL;
`audit-file-operations` owns filesystem and archive paths *after* upload acceptance;
`audit-code-execution` owns server-side execution; `audit-ssrf-redirects` owns outbound URLs and
redirects; `audit-secrets-crypto` owns secret and cryptographic properties; `audit-package-surface`
owns the released artifact; `audit-jexec` owns the direct-access guard.

`php-conservative` and `php-upcoming` split the PHP range: the former owns everything the
PHPCompatibility sniffs have data for, the latter everything above that ceiling, which only a real
test run can cover. Three details must stay consistent in both — the sweep is read-only (`phpcs`,
never `phpcbf`), its `testVersion` derives from `require.php` rather than being hand-written, and it
must be clamped to the installed release's data ceiling **with a warning**, because a sniff run
against a version it has no data for reports nothing and that reads exactly like a pass.

`e2e-tests` owns the over-HTTP layer only. `references/testing.md` owns unit and in-process
integration and must keep doing so — upstream told users to convert those away, and this suite
deliberately does not. If you touch one, check the other still agrees.

If you change any scope, fix the cross-references in **both** directions.

## Distribution channels

| Channel | Gets | Mechanism |
|---|---|---|
| Claude Code | all 17 | `.claude-plugin/` marketplace, pinned by `source.ref` |
| Claude.ai / Desktop | all 17 | one zip per skill from the release |
| Codex | all 17 † | `.codex-plugin/plugin.json`; `skills/` layout is already what Codex expects |
| Qwen Code | all 17 † | `qwen-extension.json` + `QWEN.md` |
| Cursor / Copilot / Windsurf / Cline / Aider | **`joomla` only** | universal package |

† **Untested.** The Codex manifest follows OpenAI's published `plugin.json` spec, but neither CLI was
available when it was written, so no end-to-end install was verified. Do not describe these two as
working; if a user reports a failure there, believe them over the manifest.

**The universal package ships one skill on purpose.** It flattens a skill into an always-loaded rule
file; a procedural audit that reports and waits either fires when nobody asked or is ignored. Do not
add workflow skills to `scripts/build-universal.sh`.

## Releasing

Order matters, and only some of it is checkable:

1. **Rename the repo on GitHub to `joomla-skills` first** — the tree already says `joomla-skills`,
   and GitHub redirects only work old→new, so until then the install commands point at nothing.
   *(Pending as of 2026-09-04.)*
2. Merge to `main`.
3. Bump `version` in all four manifests, and date the `## [Unreleased]` CHANGELOG heading.
4. Bump `marketplace.json`'s `source.ref` to the new tag.
5. Tag; the workflow builds one zip per skill plus the universal package.

Steps 3–4 are validated. Step 1 is not — nothing can check it.

Note that `validate.sh` printing `ok CHANGELOG.md documents <version>` refers to whatever heading
exists; pending work under `## [Unreleased]` is not covered by that line.

## What does not belong here

- **House style specific to one vendor's extensions** — key prefixes, spelling conventions, product
  vocabulary. This repo is public and generic; CWM's own conventions live in a CWM plugin.
- **Content for Joomla versions outside the declared support window** (currently 5+). No J3/J4
  patterns, triggers, or keywords.
- **Third-party material without its notice.** Sixteen workflow skills are adapted from MIT-licensed
  work and carry an attribution footer plus a row in `THIRD-PARTY.md`. The repo is GPL-2.0-or-later
  as a whole; keep the footers.
