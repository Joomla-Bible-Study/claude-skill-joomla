# Joomla Library Extension Reference

Libraries are shared PHP code packages installed under `libraries/` that any other extension can use. They're ideal for utility classes, API wrappers, data processing logic, or any code shared across your component, plugins, and modules.

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

Library language files follow the same INI format as other extensions:

```ini
; language/en-GB/lib_mylib.sys.ini
LIB_MYLIB="My Library"
LIB_MYLIB_XML_DESCRIPTION="Shared utility library for My Project extensions."
```

Library language files are typically `.sys.ini` only (shown in the admin extensions list), unless the library provides frontend UI elements.

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
