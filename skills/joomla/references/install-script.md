# Joomla Install/Update Script Reference

The `<scriptfile>` mechanism is the **PHP half** of Joomla's install system and is shared across components, modules, and plugins. The lifecycle hooks (`preflight` → `install`/`update` → `postflight`, plus `uninstall`) are identical for all three; only the class-name convention and the manifest path differ.

This reference covers:

- The shared lifecycle pattern (when each hook fires, what it gets, what it returns)
- Class-naming conventions for component / module / plugin
- A complete `Com_*InstallerScript` example (the most feature-rich case)
- How install scripts relate to **schema files** (DDL) — short answer: schemas first, script second; don't mix them

For DDL changes (`CREATE TABLE`, `ALTER TABLE`, etc.) ship per-version SQL files instead — see [`references/component.md` § Database Schema & Migrations](component.md#database-schema--migrations).

## Lifecycle Hooks

Joomla calls these methods on your script class in this order:

| Hook | Fires for | Receives | Notes |
|------|-----------|----------|-------|
| `preflight(string $type, InstallerAdapter $adapter): bool` | install, update, discover_install | `$type` distinguishes the path | Return `false` to abort. Use for environment checks (PHP, Joomla version, required extensions). |
| `install(InstallerAdapter $adapter): bool` | fresh install only | adapter | First-time setup: seed data, create directories. **Schema install SQL has already run** when this fires. |
| `update(InstallerAdapter $adapter): bool` | update only | adapter | Runs **after** Joomla has applied any pending `sql/updates/` files. Use for DML migrations and one-off cleanups. |
| `postflight(string $type, InstallerAdapter $adapter): void` | install, update, discover_install | `$type` distinguishes the path | Final wiring (cache clears, message rendering, etc.). Branch on `$type` if you need install-vs-update behavior in one place. |
| `uninstall(InstallerAdapter $adapter): bool` | uninstall | adapter | Reverse anything `install()` did that Joomla doesn't reverse automatically (custom directories, third-party rows). |

**Order of operations on update:**

1. Joomla runs `preflight('update', …)` — environment check.
2. Joomla copies new files into place.
3. Joomla applies pending `sql/updates/<driver>/X.Y.Z.sql` files based on `#__schemas`.
4. Joomla calls `update(…)`.
5. Joomla calls `postflight('update', …)`.

**The schema-vs-script ordering matters:** because schema files run before `update()` / `postflight()`, you can read the new column in a DML migration. The reverse — depending on script PHP to set up a column you'll then `ALTER` in the schema file — does NOT work and races during partial upgrades.

## Class-Naming Convention by Extension Type

| Extension type | Script class name | Manifest reference | Source location |
|----------------|-------------------|--------------------|-----------------|
| Component | `Com_<Element>InstallerScript` (e.g., `Com_ExampleInstallerScript`) | `<scriptfile>example.script.php</scriptfile>` (or whatever filename) | `admin/<element>.script.php` (or wherever you point the manifest) |
| Module | `Mod_<Element>InstallerScript` (e.g., `Mod_LatestNewsInstallerScript`) | `<scriptfile>script.php</scriptfile>` | inside the module directory |
| Plugin | `Plg<Group><Element>InstallerScript` (e.g., `PlgContentExampleInstallerScript`) | `<scriptfile>script.php</scriptfile>` | inside the plugin directory |

The class is **plain** — it does NOT extend any framework base class. Joomla discovers it by name (filename + class lookup) when `<scriptfile>` is present in the manifest.

The constants `_JEXEC` are still required at the top, even though the class itself is unstructured:

```php
\defined('_JEXEC') or die;
```

## Complete Example (Component)

The component case shows every hook plus a typical DML migration helper. Module and plugin scripts use the same hook signatures — change only the class header.

**File:** `admin/<element>.script.php` (referenced in the manifest as `<scriptfile>`)

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Factory;
use Joomla\CMS\Installer\InstallerAdapter;
use Joomla\CMS\Log\Log;

class Com_ExampleInstallerScript
{
    protected string $minimumPhp = '8.3.0';     // Joomla 6.x floor; covers J5.3+ too
    protected string $minimumJoomla = '5.0.0';   // Earliest Joomla version this extension supports

    /**
     * Runs BEFORE install/update. Return false to abort.
     */
    public function preflight(string $type, InstallerAdapter $adapter): bool
    {
        if (version_compare(PHP_VERSION, $this->minimumPhp, '<')) {
            Log::add("PHP {$this->minimumPhp}+ required", Log::ERROR, 'jerror');
            return false;
        }

        return true;
    }

    /**
     * Runs on fresh install only.
     */
    public function install(InstallerAdapter $adapter): bool
    {
        // Insert default data, create directories, etc.
        return true;
    }

    /**
     * Runs on update only. Schema files have already been applied by this point.
     */
    public function update(InstallerAdapter $adapter): bool
    {
        return true;
    }

    /**
     * Runs AFTER install/update.
     * $type is 'install', 'update', or 'discover_install'.
     */
    public function postflight(string $type, InstallerAdapter $adapter): void
    {
        if ($type === 'update') {
            $this->migrateData($adapter);
        }
    }

    /**
     * Runs on uninstall. Clean up related records, files, etc.
     */
    public function uninstall(InstallerAdapter $adapter): bool
    {
        return true;
    }

    /**
     * DML migrations that can't go in SQL update files.
     * For DDL changes (ALTER TABLE etc.) ship a sql/updates/<driver>/X.Y.Z.sql instead —
     * see references/component.md § Database Schema & Migrations.
     */
    private function migrateData(InstallerAdapter $adapter): void
    {
        $db = Factory::getContainer()->get('DatabaseDriver');

        // Example: migrate data from old column to new column
        $query = $db->createQuery()
            ->update($db->quoteName('#__example_items'))
            ->set($db->quoteName('new_column') . ' = ' . $db->quoteName('old_column'))
            ->where($db->quoteName('new_column') . ' = ' . $db->quote(''));
        $db->setQuery($query)->execute();
    }
}
```

## Module Script Skeleton

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Installer\InstallerAdapter;

class Mod_LatestNewsInstallerScript
{
    public function preflight(string $type, InstallerAdapter $adapter): bool
    {
        // Environment checks here
        return true;
    }

    public function install(InstallerAdapter $adapter): bool
    {
        return true;
    }

    public function update(InstallerAdapter $adapter): bool
    {
        return true;
    }

    public function postflight(string $type, InstallerAdapter $adapter): void
    {
        // Cache clears, etc.
    }

    public function uninstall(InstallerAdapter $adapter): bool
    {
        return true;
    }
}
```

## Plugin Script Skeleton

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Installer\InstallerAdapter;

class PlgContentExampleInstallerScript
{
    public function preflight(string $type, InstallerAdapter $adapter): bool
    {
        return true;
    }

    public function install(InstallerAdapter $adapter): bool
    {
        return true;
    }

    public function update(InstallerAdapter $adapter): bool
    {
        return true;
    }

    public function postflight(string $type, InstallerAdapter $adapter): void
    {
    }

    public function uninstall(InstallerAdapter $adapter): bool
    {
        return true;
    }
}
```

## When You Don't Need a Script

Most modules and many simple plugins don't need a script at all. Only ship one when you need at least one of:

- An environment check Joomla wouldn't otherwise enforce (custom PHP extension, third-party library presence).
- A DML migration that can't be expressed in declarative SQL.
- Filesystem work (creating a media subdirectory, seeding a default config file).
- Cleanup on uninstall that Joomla won't do (e.g., rows in `#__custom_table` your extension created at runtime, not at install time).

If your install needs are fully covered by `<files>` / `<media>` / `<install><sql>` in the manifest, leave `<scriptfile>` out.

## Common Pitfalls

- **Don't put `ALTER TABLE` in `postflight()`.** Schema files run first, then the script. Schema mutations belong in `sql/updates/<driver>/X.Y.Z.sql`. A `postflight()` ALTER works on a fresh install but races during a multi-version upgrade.
- **Don't extend `JInstallerAdapter` or anything else.** The script class is intentionally plain. Joomla calls hooks by name.
- **Return type matters.** `preflight`, `install`, `update`, `uninstall` return `bool` (return `false` to signal failure). `postflight` returns `void`.
- **`$type` strings are exact.** `'install'`, `'update'`, `'discover_install'` for components and modules; plugins also see these. Don't compare against `'upgrade'` (that's the manifest's `method` attribute, not the install type).
- **`Log::add(... 'jerror')` surfaces user-facing error messages.** Use it for `preflight` failures so the user sees *why* the install aborted.
