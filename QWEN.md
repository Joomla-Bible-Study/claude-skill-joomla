# Joomla Skills

Guidance for Joomla 5+ / 6 / 7 extension work. This repository is a suite of 17 skills; each lives in
`skills/<name>/SKILL.md` and is self-contained.

## Building extensions

For components, modules, plugins, libraries, and templates — modern MVC with PSR-4 namespaces,
dependency injection, and service providers — read **`skills/joomla/SKILL.md`** and follow its
pointers into `skills/joomla/references/*.md`. Those reference files are opened on demand; do not
load all 25 at once.

Covers scaffolding, `services/provider.php`, manifests and install scripts, database migrations,
language files, form fields, layout overrides, plugin event subscribers, module dispatchers, the Web
Asset Manager, the JSON:API web services layer, console commands, and the accumulated J5/J6 gotchas.

## Reviewing existing code

Twelve security audits, each scoped so they do not overlap. Read the one that matches the question
and follow it; each names its siblings for the ground it does not cover.

Controller access splits three ways:

- `skills/audit-authz/` — is there a check at all? (missing CSRF, authentication, authorisation)
- `skills/audit-controller-exposure/` — is it the right check? (wrong permission or asset,
  backend-only tasks reachable from site/api, unsafe uploads)
- `skills/audit-object-access/` — was it applied to the right record? (IDOR/BOLA)

The rest are organised by sink: `audit-sql-filtering` (SQL injection), `audit-xss` (browser
execution), `audit-sensitive-output` (headers, CSV, logs, mail, cache isolation),
`audit-file-operations` (traversal, Zip Slip, symlinks), `audit-code-execution` (shell, eval,
deserialisation), `audit-ssrf-redirects` (outbound URLs, open redirects), `audit-secrets-crypto`
(credentials, tokens, crypto), `audit-package-surface` (what the build ships), `audit-jexec` (the
`_JEXEC` direct-access guard).

## Maintaining

- `skills/joomla-deprecations/` — deprecated and removed core APIs, preserving the supported range.
- `skills/php-conservative/` — PHP compatibility across the range `composer.json` declares.
- `skills/php-upcoming/` — the next, unreleased PHP, which static analysis cannot check.
- `skills/e2e-tests/` — host-side PHPUnit driving a disposable Docker stack over real HTTP.

## How the workflow skills behave

Every skill except `joomla` is procedural and follows the same contract: **report** findings ordered
by severity with file and line references, **stop** and wait for the user's feedback, then **plan**
fixes as small independent units in a `.gitignore`'d `.plans` directory.

Do not change code before the user has seen and accepted the findings. Reporting and waiting is the
designed behaviour, not an intermediate step to skip.

## Scope

Joomla 5 and later. Do not apply Joomla 3 or 4 patterns. Where a fix would break a supported version,
prefer a capability check (`method_exists`, `class_exists`) over a version check, with a comment
naming the version that forced the branch.
