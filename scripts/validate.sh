#!/usr/bin/env bash
# Validate the skill repo structure.
# Run locally with: bash scripts/validate.sh
# Exit non-zero on any structural problem.
#
# This repo ships a suite: every directory under skills/ is an independent skill
# that gets released as its own zip. Each one is validated on its own terms —
# frontmatter, name/directory agreement, and links resolved against that skill's
# own directory — because that is the only context it has once unzipped.

set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
err()  { printf '::error::%s\n' "$*" >&2; fail=1; }
ok()   { printf '  ok  %s\n' "$*"; }
note() { printf '  --  %s\n' "$*"; }

# The one skill that also ships as the universal (non-Claude tool) package.
# See scripts/build-universal.sh for why only this one qualifies.
UNIVERSAL_SKILL="joomla"

echo "Validating skill structure…"

# ---------- skills/*/ ----------
if [ ! -d skills ] || [ -z "$(find skills -mindepth 1 -maxdepth 1 -type d -print -quit)" ]; then
  err "skills/ contains no skill directories"
fi

seen_names=""

for dir in skills/*/; do
  [ -d "$dir" ] || continue
  slug="$(basename "$dir")"
  SKILL="${dir}SKILL.md"

  echo
  echo "skills/$slug"

  if [ ! -f "$SKILL" ]; then
    err "$SKILL missing"
    continue
  fi
  ok "$SKILL exists"

  if ! head -1 "$SKILL" | grep -q '^---$'; then
    err "$SKILL must start with YAML frontmatter delimiter '---'"
    continue
  fi
  ok "frontmatter opener present"

  # name: and description: must be in the frontmatter (first 50 lines).
  name="$(head -50 "$SKILL" | grep -m1 -E '^name:[[:space:]]*[A-Za-z0-9_-]+' | sed -E 's/^name:[[:space:]]*//' | tr -d '\r' || true)"
  if [ -z "$name" ]; then
    err "$SKILL frontmatter missing or malformed 'name:'"
  fi
  head -50 "$SKILL" | grep -qE '^description:' \
    || err "$SKILL frontmatter missing 'description:'"
  [ -n "$name" ] && ok "frontmatter has name ($name) and description"

  # The release asset and the installed skill are both named from the directory,
  # while Claude activates on the frontmatter name. A mismatch silently misnames
  # one of the two, so require they agree.
  if [ -n "$name" ] && [ "$name" != "$slug" ]; then
    err "$SKILL declares 'name: $name' but lives in skills/$slug/ — these must match"
  elif [ -n "$name" ]; then
    ok "name matches directory"
  fi

  # Duplicate names shadow each other once installed.
  if [ -n "$name" ]; then
    case " $seen_names " in
      *" $name "*) err "duplicate skill name '$name' — names must be unique across the suite" ;;
      *)           seen_names="$seen_names $name" ;;
    esac
  fi

  # Links must resolve inside this skill's own directory. A skill is distributed
  # as a standalone zip rooted at its own folder, so anything reached through
  # '../' is gone the moment it is unzipped — which is exactly how a stub that
  # points at a shared file elsewhere in the repo breaks for Claude.ai users.
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    if [ -f "${dir}${ref}" ]; then
      ok "reference resolves: $ref"
    else
      err "skills/$slug/SKILL.md references missing file: $ref"
    fi
  done < <(grep -oE 'references/[A-Za-z0-9_/.-]+\.md' "$SKILL" | sort -u)

  if grep -qE '\]\(\.\./' "$SKILL"; then
    err "skills/$slug/SKILL.md links outside its own directory ('../') — it would break in the standalone skill zip"
  else
    ok "no links escape the skill directory"
  fi
done

echo

# ---------- the universal skill must exist ----------
if [ -d "skills/$UNIVERSAL_SKILL" ]; then
  ok "universal skill present (skills/$UNIVERSAL_SKILL)"
else
  err "skills/$UNIVERSAL_SKILL missing — scripts/build-universal.sh depends on it"
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

# ---------- .codex-plugin/plugin.json ----------
# Codex reads skills/<name>/SKILL.md directly, the same layout Claude Code uses,
# so this manifest is the only Codex-specific file. Its required fields are
# name/version/description/author.name plus a fully-populated interface block —
# a missing interface field makes the plugin unlistable rather than erroring.
CODEX=.codex-plugin/plugin.json
if [ -f "$CODEX" ]; then
  if jq -e . "$CODEX" >/dev/null 2>&1; then
    ok "$CODEX parses as JSON"
    for f in name version description; do
      jq -e --arg f "$f" 'has($f)' "$CODEX" >/dev/null 2>&1 || err "$CODEX missing '$f'"
    done
    jq -e '.author.name' "$CODEX" >/dev/null 2>&1 || err "$CODEX missing 'author.name'"
    for f in displayName shortDescription longDescription developerName category capabilities; do
      jq -e --arg f "$f" '.interface | has($f)' "$CODEX" >/dev/null 2>&1 \
        || err "$CODEX missing required 'interface.$f'"
    done
    # Codex caps defaultPrompt at 3 entries of 128 characters.
    if jq -e '.interface | has("defaultPrompt")' "$CODEX" >/dev/null 2>&1; then
      jq -e '.interface.defaultPrompt | length <= 3' "$CODEX" >/dev/null \
        || err "$CODEX interface.defaultPrompt takes at most 3 entries"
      jq -e '[.interface.defaultPrompt[] | length] | max <= 128' "$CODEX" >/dev/null \
        || err "$CODEX interface.defaultPrompt entries must be 128 characters or fewer"
    fi
    # The skills pointer must actually point at the skill tree.
    SKILLS_PTR=$(jq -r '.skills // empty' "$CODEX")
    case "$SKILLS_PTR" in
      ""|./skills/|skills/) ok "$CODEX skills pointer ok" ;;
      *) err "$CODEX 'skills' should be './skills/' (got '$SKILLS_PTR')" ;;
    esac
  else
    err "$CODEX is not valid JSON"
  fi
else
  note "$CODEX missing — Codex users would not get this plugin"
fi

# ---------- qwen-extension.json ----------
QWEN=qwen-extension.json
if [ -f "$QWEN" ]; then
  if jq -e . "$QWEN" >/dev/null 2>&1; then
    ok "$QWEN parses as JSON"
    CTX=$(jq -r '.contextFileName // empty' "$QWEN")
    if [ -z "$CTX" ]; then
      err "$QWEN missing 'contextFileName'"
    elif [ -f "$CTX" ]; then
      ok "$QWEN context file exists ($CTX)"
    else
      err "$QWEN names contextFileName '$CTX' but that file does not exist"
    fi
  else
    err "$QWEN is not valid JSON"
  fi
else
  note "$QWEN missing — Qwen Code users would not get this extension"
fi

# ---------- version consistency ----------
# The plugin version lives in FOUR manifests now and a release has to bump every
# one. Each is validated above in isolation, so a release that bumps some and
# forgets another passed validation cleanly — which is exactly what happened
# preparing v1.1.0 with only two of them. Compared here since no one file owns
# the set. A host whose manifest did not change keeps serving the old version.
if [ -f "$PLUGIN" ] && [ -f "$MARKET" ] \
   && jq -e . "$PLUGIN" >/dev/null 2>&1 && jq -e . "$MARKET" >/dev/null 2>&1; then
  PLUGIN_NAME=$(jq -r '.name // empty' "$PLUGIN")
  PV=$(jq -r '.version // empty' "$PLUGIN")

  # Match the marketplace entry by name so this keeps working if more plugins
  # are added; fall back to the sole entry when there is exactly one.
  MV=$(jq -r --arg n "$PLUGIN_NAME" '
    (.plugins[] | select(.name == $n) | .version)
    // (if (.plugins | length) == 1 then .plugins[0].version else empty end)
    // empty' "$MARKET")

  if [ -z "$PV" ] || [ -z "$MV" ]; then
    note "could not compare versions (plugin.json='$PV' marketplace.json='$MV') — check manually"
  elif [ "$PV" != "$MV" ]; then
    err "version mismatch: plugin.json='$PV' but marketplace.json='$MV' — a release must bump both"
  else
    ok "plugin version consistent ($PV)"

    # The other two hosts read their own manifests; a stale one silently keeps
    # serving the previous release to that host only, which is the hardest kind
    # of drift to notice.
    for extra in "$CODEX" "$QWEN"; do
      [ -f "$extra" ] || continue
      jq -e . "$extra" >/dev/null 2>&1 || continue
      XV=$(jq -r '.version // empty' "$extra")
      if [ -z "$XV" ]; then
        note "$extra has no 'version' — cannot compare"
      elif [ "$XV" != "$PV" ]; then
        err "version mismatch: $extra='$XV' but plugin.json='$PV' — every manifest must bump together"
      else
        ok "$extra version consistent ($XV)"
      fi
    done

    # The marketplace source ref decides which tree `/plugin install` actually
    # fetches, and nothing above looks at it. Bump both versions but not the ref
    # and installs silently keep serving the previous release — the same class of
    # miss as the version mismatch this block was added for, one field over.
    REF=$(jq -r --arg n "$PLUGIN_NAME" '
      (.plugins[] | select(.name == $n) | .source.ref)
      // (if (.plugins | length) == 1 then .plugins[0].source.ref else empty end)
      // empty' "$MARKET")

    case "$REF" in
      "")      note "marketplace.json has no source.ref — installs track the default branch" ;;
      v[0-9]*) if [ "$REF" != "v$PV" ]; then
                 err "marketplace.json source.ref='$REF' but version='$PV' — a release must bump both (installs would serve $REF)"
               else
                 ok "marketplace source.ref matches version ($REF)"
               fi ;;
      *)       note "marketplace.json source.ref='$REF' is not a version tag — verify intentional" ;;
    esac

    # A version with no changelog entry is a release nobody can read. Warn rather
    # than fail: the heading is normally added in the same commit, but a
    # work-in-progress bump is a legitimate intermediate state.
    if [ -f CHANGELOG.md ]; then
      if grep -qE "^## \[$PV\]" CHANGELOG.md; then
        ok "CHANGELOG.md documents $PV"
      else
        note "CHANGELOG.md has no '## [$PV]' heading yet — add one before releasing"
      fi
    fi
  fi
fi

# ---------- README references the install commands ----------
# Repo name deliberately not matched here, so a repo rename doesn't trip this.
if [ -f README.md ]; then
  grep -q 'plugin marketplace add Joomla-Bible-Study/' README.md \
    || note "README.md no longer contains the marketplace add command — verify intentional"
fi

# ---------- result ----------
echo
if [ $fail -eq 1 ]; then
  echo "Validation FAILED" >&2
  exit 1
fi
echo "Validation passed."
