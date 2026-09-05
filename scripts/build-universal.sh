#!/usr/bin/env bash
# Build a "universal" package of the Joomla skill content for AI coding tools
# other than Claude Code (Cursor, GitHub Copilot, Windsurf, Cline, Aider, and any
# tool that reads the emerging AGENTS.md standard).
#
# Source of truth: skills/$UNIVERSAL_SKILL/SKILL.md + its references/*.md
# Output:         dist/universal/
#
# Run locally:    bash scripts/build-universal.sh
# CI uses it from .github/workflows/release.yml to produce a second release ZIP.
#
# ---------------------------------------------------------------------------
# Only ONE skill ships in the universal package, and that is deliberate.
#
# This build flattens a skill into always-loaded rule files (AGENTS.md, Cursor
# rules, Copilot instructions…). That format suits reference material the tool
# should have in context whenever it touches Joomla code — which is what the
# `joomla` skill is.
#
# It is the wrong format for the audit-* skills. Those are procedural workflows
# that discover findings, stop, and wait for the user before touching code. As
# an always-on rule file, that instruction either fires when nobody asked for an
# audit or is ignored entirely. They ship to Claude Code and as individual skill
# zips instead; see the channel matrix in README.md.
#
# So if you add a skill, do NOT add it here unless it is reference material of
# the same shape as `joomla`.
# ---------------------------------------------------------------------------

set -euo pipefail

cd "$(dirname "$0")/.."

UNIVERSAL_SKILL="joomla"

SRC_SKILL="skills/${UNIVERSAL_SKILL}/SKILL.md"
SRC_REFS="skills/${UNIVERSAL_SKILL}/references"
OUT="dist/universal"

if [ ! -f "$SRC_SKILL" ]; then
  echo "::error::$SRC_SKILL not found" >&2
  exit 1
fi
if [ ! -d "$SRC_REFS" ]; then
  echo "::error::$SRC_REFS not found" >&2
  exit 1
fi

echo "Building universal package -> $OUT"
rm -rf "$OUT"
mkdir -p "$OUT" "$OUT/.github" "$OUT/.cursor/rules" "$OUT/references"

# 1. Extract SKILL.md body (everything after the closing '---' of the YAML
#    frontmatter). The frontmatter is Claude-skill-specific activation metadata
#    that does not apply to always-loaded IDE rule files.
BODY_TMP="$(mktemp)"
awk '
  BEGIN { in_fm = 0; past_fm = 0 }
  NR == 1 && /^---$/ { in_fm = 1; next }
  in_fm && /^---$/   { in_fm = 0; past_fm = 1; next }
  in_fm              { next }
  past_fm            { print }
' "$SRC_SKILL" > "$BODY_TMP"

if [ ! -s "$BODY_TMP" ]; then
  echo "::error::failed to strip frontmatter from $SRC_SKILL" >&2
  rm -f "$BODY_TMP"
  exit 1
fi

# 2. Copy references/ verbatim. All targets share one references/ directory at
#    the package root; per-target files use the right relative depth to find it.
cp "$SRC_REFS"/*.md "$OUT/references/"

# 3. Helper: emit a target file with `references/...` rewritten to a given
#    relative prefix. Usage: emit_target <output-path> <ref-prefix> [header-file]
emit_target() {
  local out_path="$1"
  local prefix="$2"
  local header="${3:-}"
  mkdir -p "$(dirname "$out_path")"
  {
    if [ -n "$header" ] && [ -f "$header" ]; then
      cat "$header"
      echo
    fi
    # Rewrite every `references/foo.md` link to `<prefix>references/foo.md`.
    sed "s|\(](\)references/|\1${prefix}references/|g" "$BODY_TMP"
  } > "$out_path"
}

# 4. Per-tool headers. Kept tiny on purpose — the bulk of the content is the
#    shared body. These notes tell the tool/user how to interpret the file.

HEADER_AGENTS="$(mktemp)"
cat > "$HEADER_AGENTS" <<'EOF'
<!--
AGENTS.md — universal AI coding agent guidance (https://agents.md)
Read by Cursor 1.0+, Aider, Zed, Jules, and a growing list of tools. Drop this
file at your project root alongside the references/ directory.
Codex users: prefer the repo's own plugin (all 17 skills) over this file.
-->
EOF

HEADER_COPILOT="$(mktemp)"
cat > "$HEADER_COPILOT" <<'EOF'
<!--
GitHub Copilot custom instructions for Joomla 5+ / 6 / 7 projects.
Place at .github/copilot-instructions.md and ship references/ at the repo root.
Docs: https://docs.github.com/copilot/customizing-copilot/about-customizing-github-copilot-chat-responses
-->
EOF

HEADER_CURSOR="$(mktemp)"
# Cursor's docs document `globs:` as a comma-separated string, not a YAML
# array (https://cursor.com/docs/context/rules). Both forms work in practice
# but the documented form is safer if Cursor tightens its parser.
cat > "$HEADER_CURSOR" <<'EOF'
---
description: Joomla 5+ / 6 / 7 extension development conventions (components, modules, plugins, libraries, templates)
globs: **/*.php, **/manifest*.xml, **/joomla.asset.json, **/provider.php, **/services/provider.php
alwaysApply: false
---
EOF

HEADER_WINDSURF="$(mktemp)"
cat > "$HEADER_WINDSURF" <<'EOF'
<!-- Windsurf project rules for Joomla 5+ / 6 / 7 extension development. -->
EOF

HEADER_CLINE="$(mktemp)"
cat > "$HEADER_CLINE" <<'EOF'
<!-- Cline project rules for Joomla 5+ / 6 / 7 extension development. -->
EOF

HEADER_AIDER="$(mktemp)"
cat > "$HEADER_AIDER" <<'EOF'
<!--
Aider convention file for Joomla 5+ / 6 / 7 projects.
Load with: aider --read CONVENTIONS.md
Docs: https://aider.chat/docs/usage/conventions.html
-->
EOF

# 5. Emit each target with the correct prefix to references/.
emit_target "$OUT/AGENTS.md"                       ""        "$HEADER_AGENTS"
emit_target "$OUT/.github/copilot-instructions.md" "../"     "$HEADER_COPILOT"
emit_target "$OUT/.cursor/rules/joomla.mdc"        "../../"  "$HEADER_CURSOR"
emit_target "$OUT/.windsurfrules"                  ""        "$HEADER_WINDSURF"
emit_target "$OUT/.clinerules"                     ""        "$HEADER_CLINE"
emit_target "$OUT/CONVENTIONS.md"                  ""        "$HEADER_AIDER"

# 6. Top-level README explaining how to install each variant.
cat > "$OUT/README.md" <<'EOF'
# Joomla Skills — Universal AI Coding Package (extension-development guidance)

Generated from [`Joomla-Bible-Study/joomla-skills`](https://github.com/Joomla-Bible-Study/joomla-skills),
a suite of 17 skills. This package carries only the `joomla` extension-development
skill, flattened into rule files for tools without a plugin system — the twelve
security audits and the maintenance workflows are interactive and do not
translate to always-on rules.

## What's in this package

```
AGENTS.md                          Universal agent guidance (Cursor 1.0+, Zed, Aider, …)
.github/copilot-instructions.md    GitHub Copilot custom instructions
.cursor/rules/joomla.mdc           Cursor project rule (auto-attaches on PHP / manifest XML)
.windsurfrules                     Windsurf project rules
.clinerules                        Cline project rules
CONVENTIONS.md                     Aider conventions
references/                        Deep-dive docs linked from every variant above
```

## How to install (pick the file(s) for your tool)

Copy the file(s) for the AI tool you use into your **Joomla project's root**,
along with the entire `references/` directory. The relative links inside each
file are pre-wired to find `references/` from its own location.

| Tool                    | Copy these                                          |
|-------------------------|-----------------------------------------------------|
| Generic / AGENTS.md     | `AGENTS.md` + `references/`                         |
| Cursor                  | `.cursor/rules/joomla.mdc` + `references/`          |
| GitHub Copilot          | `.github/copilot-instructions.md` + `references/`   |
| Windsurf                | `.windsurfrules` + `references/`                    |
| Cline                   | `.clinerules` + `references/`                       |
| Aider                   | `CONVENTIONS.md` + `references/` (then `aider --read CONVENTIONS.md`) |

Multiple tools can coexist — each reads its own file and ignores the others.

## On Codex and Qwen Code

Both have a plugin system that reads the upstream repo's skills directly, so they
get all 17 skills rather than just the extension-development guidance in this
package. Use the repo's manifests instead of these rule files — see Option 4 in
the upstream README.

## Using Claude Code instead?

This universal package is for tools without a plugin system. If you're on Claude
Code, install the proper plugin instead — you'll get progressive disclosure,
automatic skill activation on Joomla keywords, the twelve security audits, and
faster context use:

```
/plugin marketplace add Joomla-Bible-Study/joomla-skills
/plugin install joomla@joomla-bible-study
/reload-plugins
```

## License & contributing

GPL-2.0-or-later. Issues, corrections, and PRs welcome at the upstream repo:
https://github.com/Joomla-Bible-Study/joomla-skills
EOF

# 7. Cleanup
rm -f "$BODY_TMP" "$HEADER_AGENTS" "$HEADER_COPILOT" "$HEADER_CURSOR" \
      "$HEADER_WINDSURF" "$HEADER_CLINE" "$HEADER_AIDER"

echo
echo "Generated files:"
find "$OUT" -type f | sort | sed 's/^/  /'
echo
echo "Universal package built at $OUT"