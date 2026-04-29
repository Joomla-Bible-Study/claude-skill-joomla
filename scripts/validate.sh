#!/usr/bin/env bash
# Validate the skill repo structure.
# Run locally with: bash scripts/validate.sh
# Exit non-zero on any structural problem.

set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
err()  { printf '::error::%s\n' "$*" >&2; fail=1; }
ok()   { printf '  ok  %s\n' "$*"; }
note() { printf '  --  %s\n' "$*"; }

echo "Validating skill structure…"

# ---------- skills/joomla/SKILL.md ----------
SKILL=skills/joomla/SKILL.md
if [ ! -f "$SKILL" ]; then
  err "$SKILL missing"
else
  ok "$SKILL exists"
  if ! head -1 "$SKILL" | grep -q '^---$'; then
    err "$SKILL must start with YAML frontmatter delimiter '---'"
  else
    ok "frontmatter opener present"
  fi
  # Must contain name: and description: in the first 50 lines (frontmatter)
  head -50 "$SKILL" | grep -qE '^name:[[:space:]]*[A-Za-z0-9_-]+' \
    || err "$SKILL frontmatter missing or malformed 'name:'"
  head -50 "$SKILL" | grep -qE '^description:' \
    || err "$SKILL frontmatter missing 'description:'"
  ok "frontmatter has name and description"
fi

# ---------- references referenced by SKILL.md must exist ----------
if [ -f "$SKILL" ]; then
  while IFS= read -r ref; do
    path="skills/joomla/$ref"
    if [ -f "$path" ]; then
      ok "reference resolves: $ref"
    else
      err "SKILL.md references missing file: $ref"
    fi
  done < <(grep -oE 'references/[A-Za-z0-9_/.-]+\.md' "$SKILL" | sort -u)
fi

# ---------- .claude-plugin/plugin.json ----------
PLUGIN=.claude-plugin/plugin.json
if [ ! -f "$PLUGIN" ]; then
  err "$PLUGIN missing"
else
  if jq -e . "$PLUGIN" >/dev/null 2>&1; then
    ok "$PLUGIN parses as JSON"
    jq -e '.name' "$PLUGIN" >/dev/null 2>&1 || err "$PLUGIN missing 'name'"
    jq -e '.version' "$PLUGIN" >/dev/null 2>&1 || err "$PLUGIN missing 'version'"
    jq -e '.description' "$PLUGIN" >/dev/null 2>&1 || err "$PLUGIN missing 'description'"
  else
    err "$PLUGIN is not valid JSON"
  fi
fi

# ---------- .claude-plugin/marketplace.json ----------
MARKET=.claude-plugin/marketplace.json
if [ ! -f "$MARKET" ]; then
  err "$MARKET missing"
else
  if jq -e . "$MARKET" >/dev/null 2>&1; then
    ok "$MARKET parses as JSON"
    jq -e '.plugins | type == "array" and length > 0' "$MARKET" >/dev/null \
      || err "$MARKET must have a non-empty plugins array"

    # Every string source must start with './' (per Claude Code schema)
    while IFS= read -r entry; do
      name=$(printf '%s' "$entry" | jq -r '.name // "?"')
      src=$(printf '%s' "$entry" | jq -r '.source // empty')
      src_type=$(printf '%s' "$entry" | jq -r '.source | type')
      if [ "$src_type" = "string" ]; then
        case "$src" in
          ./*) ok "marketplace plugin '$name' source ok ('$src')" ;;
          *)   err "marketplace plugin '$name' source must start with './' (got '$src')" ;;
        esac
      elif [ "$src_type" = "object" ]; then
        ok "marketplace plugin '$name' uses object source"
      else
        err "marketplace plugin '$name' missing 'source'"
      fi
    done < <(jq -c '.plugins[]' "$MARKET")
  else
    err "$MARKET is not valid JSON"
  fi
fi

# ---------- README references the install commands ----------
if [ -f README.md ]; then
  grep -q 'plugin marketplace add Joomla-Bible-Study/claude-skill-joomla' README.md \
    || note "README.md no longer contains the marketplace add command — verify intentional"
fi

# ---------- result ----------
echo
if [ $fail -eq 1 ]; then
  echo "Validation FAILED" >&2
  exit 1
fi
echo "Validation passed."
