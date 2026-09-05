# Third-party notices

This repository is licensed **GPL-2.0-or-later** as a whole (see [LICENSE](LICENSE)).

Some material in it derives from third-party work under a different licence. That material keeps its
original copyright notice and permission notice, reproduced below. MIT-licensed material may be
incorporated into a GPL-2.0-or-later work; the combined work is distributed under the GPL, and the
MIT notice travels with the portions it covers.

---

## `pm-skill-demo` — the `audit-*`, `joomla-deprecations`, and `php-conservative` skills

The following skills are adapted from workflows in
[`nikosdion/pm-skill-demo`](https://github.com/nikosdion/pm-skill-demo):

| Skill in this repo | Upstream workflow |
|---|---|
| `skills/audit-authz` | `commands/audit-authz.md` |
| `skills/audit-code-execution` | `commands/audit-code-execution.md` |
| `skills/audit-controller-exposure` | `commands/audit-controller-exposure.md` |
| `skills/audit-file-operations` | `commands/audit-file-operations.md` |
| `skills/audit-jexec` | `commands/audit-jexec.md` |
| `skills/audit-object-access` | `commands/audit-object-access.md` |
| `skills/audit-package-surface` | `commands/audit-package-surface.md` |
| `skills/audit-secrets-crypto` | `commands/audit-secrets-crypto.md` |
| `skills/audit-sensitive-output` | `commands/audit-sensitive-output.md` |
| `skills/audit-sql-filtering` | `commands/audit-sql-filtering.md` |
| `skills/audit-ssrf-redirects` | `commands/audit-ssrf-redirects.md` |
| `skills/audit-xss` | `commands/audit-xss.md` |
| `skills/e2e-tests` | `skills/e2e-tests/SKILL.md` |
| `skills/joomla-deprecations` | `commands/joomla-deprecations.md` |
| `skills/php-conservative` | `commands/php-conservative.md` |
| `skills/php-upcoming` | `commands/php-upcoming.md` |

Not adopted from upstream's nineteen: `plan-and-execute` (generic task orchestration, not Joomla, and
command-shaped rather than skill-shaped), and `en-gb-consistency` / `machine-translation` (house-style
and vendor-specific translation policy).

**What changed in adaptation.** Upstream ships each skill as a stub pointing at a shared
`commands/*.md` file **outside** the skill directory. That layout cannot be distributed as a
standalone skill zip — the target is gone the moment the folder is zipped — so each workflow here is
inlined into its own self-contained `SKILL.md`.

The prose was rewritten for this suite's voice and for a general Joomla 5+/6/7 audience rather than
one vendor's conventions, and Joomla-specific detail was added throughout: `FormController` /
`AdminController` token behaviour, `ParameterType` binding and the `ORDER BY` / `list.fullordering`
cases binding cannot cover, `$this->escape()`'s `ENT_COMPAT` default, per-group Text Filters, the
`PATH` input filter validating syntax rather than containment, `getListQuery()` omitting the access
constraint `getItem()` applies, Joomla's base64 `return` parameter as an open-redirect surface, and
`addScriptOptions()` payloads being page-source-visible.

`joomla-deprecations` was additionally **retargeted** from upstream's Joomla 4.4+ baseline to this
suite's Joomla 5+ support window, and its sourcing section rewritten around the corresponding
`joomla/Manual` version-gap paths.

`e2e-tests` is the one upstream skill whose content lives in its own `SKILL.md` rather than a
`commands/` file; upstream ships no harness code, so what is adopted is the architecture description,
not an implementation. It was **reconciled** with this suite's existing testing guidance, which taught
in-process integration tests that upstream instructed converting away: the three layers are now
presented as complementary, with `references/testing.md` owning unit and in-process integration and
this skill owning the over-HTTP layer. Upstream's mandate that PHPUnit never be a project dependency,
and its exclusion of IIS, are restated as project choices and a coverage gap rather than
requirements. `php-upcoming`'s central step, which upstream hard-codes to that harness's
`run.sh --deprecations` invocation and `.env` variable, is described by capability so the workflow
also applies to a project with an ordinary test suite.

Each adapted `SKILL.md` carries an attribution footer naming the upstream workflow, so the notice
travels with a skill distributed on its own.

### MIT License

```
MIT License

Copyright (c) 2026 Nicholas K. Dionysopoulos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
