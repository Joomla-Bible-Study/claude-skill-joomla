# Joomla Library Extension Reference

Libraries are shared PHP code packages installed under `libraries/` that any other extension can use. They're ideal for utility classes, API wrappers, data processing logic, or any code shared across your component, plugins, and modules.

## Table of Contents
1. [When to Use a Library](#when-to-use-a-library)
2. [Directory Structure](#directory-structure)
3. [Manifest XML](#manifest-xml) — universal elements in [`manifest.md`](manifest.md)
4. [Library PHP Classes](#library-php-classes)
5. [Using Library Classes in Other Extensions](#using-library-classes-in-other-extensions)
6. [Language Files](#language-files) — full conventions in [`language-files.md`](language-files.md)
7. [Versioning & Updates](#versioning--updates)
8. [Install Script (Optional)](#install-script-optional) — full walkthrough in [`install-script.md`](install-script.md)
9. [Packaging a Library](#packaging-a-library)
10. [Including Libraries in a Package Extension](#including-libraries-in-a-package-extension)
11. [Multiple Libraries Under a Vendor](#multiple-libraries-under-a-vendor)

## When to Use a Library

- Shared code consumed by multiple extensions (e.g., a helper used by both your component and your plugins)
- Third-party PHP library wrappers you want to install/update via Joomla's extension manager
- Reusable logic that doesn't belong to any single component

**Do NOT use a library when:**
- The code is only used by one component — put it in that component's `Helper/` or `Service/` namespace instead
- You just need Composer packages — bundle them in `libraries/vendor/` inside your component (see Libraries and Composer section in SKILL.md)

## Directory Structure

```
lib_mylib/
├── mylib.xml                    # Manifest (at package root)
└── libraries/
    └── mylib/
        ├── src/
        │   ├── MyClass.php
        │   ├── AnotherClass.php
        │   └── SubNamespace/
        │       └── Helper.php
        └── language/
            └── en-GB/
                └── lib_mylib.sys.ini
```

When installed, Joomla copies the contents of `libraries/mylib/` to `<joomla_root>/libraries/mylib/` and places the manifest at `<joomla_root>/administrator/manifests/libraries/mylib.xml`.

**Important:** Never use `libraries/vendor/` as your library directory — that path is reserved by Joomla's core Composer autoloader.

## Manifest XML

For the **universal** manifest elements (`<extension>` root attributes, the metadata block, `<files>`, `<media>`, `<languages>`, `<scriptfile>`, `<update>` / `<updateservers>`) see [`references/manifest.md`](manifest.md). What's specific to libraries is the `<libraryname>` element (the install-path key under `libraries/`) and the `<files folder="libraries/<libraryname>">` mapping. Library manifests rarely use `<media>` (libraries are PHP, not assets) or `<install><sql>` (libraries usually have no schema).

(Element-handling verified against [`LibraryAdapter` on `joomla-cms` `6.1-dev`](https://github.com/joomla/joomla-cms/blob/6.1-dev/libraries/src/Installer/Adapter/LibraryAdapter.php) — it parses `<libraryname>`, `<files>`, `<languages>`, `<media>`, and the `<scriptfile>`-driven `manifest_script`.)

```xml
<?xml version="1.0" encoding="utf-8"?>
<extension type="library" method="upgrade">
    <name>lib_mylib</name>
    <libraryname>mylib</libraryname>
    <version>1.0.0</version>
    <creationDate>2025-01</creationDate>
    <author>Vendor Name</author>
    <authorEmail>dev@example.com</authorEmail>
    <authorUrl>https://example.com</authorUrl>
    <copyright>(C) 2025 Vendor Name</copyright>
    <license>GPL-2.0-or-later</license>
    <description>LIB_MYLIB_XML_DESCRIPTION</description>
    <namespace path="src">Vendor\Library\MyLib</namespace>
    <files folder="libraries/mylib">
        <folder>src</folder>
        <folder>language</folder>
    </files>
</extension>
```

### Key Elements

- **`<libraryname>`** — The subdirectory name under `libraries/` where files are installed. Must match the folder name inside your package.
- **`<namespace path="src">`** — Enables PSR-4 autoloading. The `path` attribute is relative to the library root (`libraries/mylib/`). So `path="src"` maps the namespace to `libraries/mylib/src/`.
- **`<files folder="...">`** — The `folder` attribute is relative to the ZIP root and tells the installer where to find the library files.

### Namespace Mapping

Given this manifest:
```xml
<namespace path="src">Vendor\Library\MyLib</namespace>
```

Joomla maps:
- `Vendor\Library\MyLib\MyClass` → `libraries/mylib/src/MyClass.php`
- `Vendor\Library\MyLib\SubNamespace\Helper` → `libraries/mylib/src/SubNamespace/Helper.php`

**Without the `<namespace>` tag, Joomla will NOT autoload your library classes.** You would have to provide your own autoloader or manually `require` files — avoid this.

## Library PHP Classes

Library classes are plain PHP — no base class to extend. Just follow PSR-4 and PSR-12:

```php
<?php

declare(strict_types=1);

namespace Vendor\Library\MyLib;

/**
 * Example utility class in a Joomla library.
 */
class MyClass
{
    /**
     * Do something useful.
     *
     * @param   string  $input  The input value
     *
     * @return  string  The processed result
     */
    public function process(string $input): string
    {
        return strtoupper(trim($input));
    }
}
```

### Using Database in a Library

Libraries don't extend Joomla MVC classes, so they don't have `$this->getDatabase()`. Instead, accept `DatabaseInterface` via constructor injection or get it from the application:

```php
<?php

declare(strict_types=1);

namespace Vendor\Library\MyLib;

use Joomla\Database\DatabaseInterface;

class DataHelper
{
    public function __construct(private readonly DatabaseInterface $db)
    {
    }

    public function getItemCount(string $tableName): int
    {
        $query = $this->db->createQuery()
            ->select('COUNT(*)')
            ->from($this->db->quoteName($tableName));

        $this->db->setQuery($query);

        return (int) $this->db->loadResult();
    }
}
```

To instantiate from a component or plugin:
```php
use Vendor\Library\MyLib\DataHelper;

$db = $this->getDatabase(); // or Factory::getContainer()->get(DatabaseInterface::class)
$helper = new DataHelper($db);
$count = $helper->getItemCount('#__mycomponent_items');
```

## Using Library Classes in Other Extensions

Once installed with a proper namespace, library classes are automatically available anywhere in Joomla:

**In a component model:**
```php
use Vendor\Library\MyLib\MyClass;

class ItemModel extends AdminModel
{
    public function processTitle(string $title): string
    {
        $util = new MyClass();
        return $util->process($title);
    }
}
```

**In a plugin:**
```php
use Vendor\Library\MyLib\MyClass;

class MyPlugin extends CMSPlugin implements SubscriberInterface
{
    // Just use the class — autoloading handles the rest
}
```

**In form XML (custom field from a library):**
```xml
<field
    name="myfield"
    type="mylib.customfield"
    addfieldprefix="Vendor\Library\MyLib\Field"
    label="My Field"
/>
```

The `addfieldprefix` attribute tells Joomla where to look for the custom field class. This avoids needing a system plugin to register field prefixes.

## Language Files

Libraries use the `LIB_<ELEMENT>_*` key prefix. The full naming, file-location, and JS-registration conventions are **shared across all extension types** — see [`references/language-files.md`](language-files.md). Library-specific reminders:

- Most libraries ship **only `.sys.ini`** (loaded by the installer + Extensions list), because libraries are pure PHP code with no UI of their own. Add a runtime `.ini` only if your library actually emits user-facing strings (e.g., from an exception message that surfaces in another extension's view).
- Source-tree filename uses the locale prefix: `library_root/language/en-GB/en-GB.lib_mylib.sys.ini`. Example minimal contents:

```ini
LIB_MYLIB="My Library"
LIB_MYLIB_XML_DESCRIPTION="Shared utility library for My Project extensions."
```

## Versioning & Updates

Libraries follow the same `<version>` + `<updateservers>` flow as other extension types — see [`manifest.md`](manifest.md) § "`<update>` and `<updateservers>`" for the universal update-XML schema and the `<targetplatform>` regex.

Library-specific notes:

- **No `<schemas>` for libraries.** The `<update><schemas>` block (per-version `sql/updates/<driver>/X.Y.Z.sql`) is a component pattern; libraries don't carry a `#__schemas` row and have nothing to migrate at the SQL layer. If your library wraps a service that needs schema state, register the schemas on the **consuming component**, not the library.
- **PHP-level migrations** (e.g., a constant rename across versions of your library API) belong in the consuming extension's install script, not the library itself. Libraries are best treated as immutable code drops keyed by `<version>`; semver-bump changes to the library's public surface and let dependents `composer update`-style move forward.
- **`<targetplatform>` regex** — pick the Joomla version range your library supports. For Joomla 6.x-only code use `version="6\.[0-9]+"`; for J5+J6 dual-support use `version="(5|6)\.[0-9]+"`.

## Install Script (Optional)

Libraries **rarely** need a `<scriptfile>`. The default flow — copy files to `libraries/<libraryname>/`, register the namespace, done — covers most cases. Add a script only when you need to:

- Pre-create a runtime data directory the library will write to.
- Verify a system-level dependency Joomla doesn't enforce (e.g., a PHP extension your library binds against).
- Clean up persistent state on uninstall (rare; libraries usually have none).

The lifecycle hooks (`preflight` / `install` / `update` / `postflight` / `uninstall`) and the script-class naming convention (`Lib<Element>InstallerScript`, e.g., `LibMyLibInstallerScript`) follow the **shared** pattern documented in [`references/install-script.md`](install-script.md). Libraries pass the same `InstallerAdapter` to each hook; the only difference from the component case is that there's no MVC scaffolding or schema runner to coordinate with.

## Packaging a Library

```bash
cd /path/to/lib_mylib
zip -r ../lib_mylib-1.0.0.zip \
    mylib.xml \
    libraries/
```

The ZIP structure should be:
```
lib_mylib-1.0.0.zip
├── mylib.xml
└── libraries/
    └── mylib/
        ├── src/
        └── language/
```

## Including Libraries in a Package Extension

If your project ships a component + library together, include the library in the package manifest:

```xml
<extension type="package" method="upgrade">
    <name>pkg_myproject</name>
    <packagename>myproject</packagename>
    <version>1.0.0</version>
    <files>
        <file type="library" id="lib_mylib">lib_mylib.zip</file>
        <file type="component" id="com_mycomponent">com_mycomponent.zip</file>
        <file type="plugin" id="plg_content_mycomponent" group="content">plg_content_mycomponent.zip</file>
    </files>
</extension>
```

**Important:** List the library **before** the component and plugins in the package manifest. Joomla installs files in order, so the library needs to be available before extensions that depend on it.

## Multiple Libraries Under a Vendor

If you have multiple independent libraries (e.g., `lib_mylib_core`, `lib_mylib_api`, `lib_mylib_sync`), each needs:

- Its own manifest XML
- Its own directory under `libraries/` (e.g., `libraries/mylib_core/`, `libraries/mylib_api/`)
- Its own namespace declaration
- Its own ZIP if distributed via a package

You cannot nest multiple independent libraries under a single `<libraryname>`. Each is a separate installable extension.

However, you CAN have a single library with multiple sub-namespaces:
```
libraries/mylib/src/
├── Core/
│   └── BaseClass.php      → Vendor\Library\MyLib\Core\BaseClass
├── Api/
│   └── Client.php         → Vendor\Library\MyLib\Api\Client
└── Sync/
    └── SyncService.php    → Vendor\Library\MyLib\Sync\SyncService
```

This is simpler if the code always ships together and versions together.
