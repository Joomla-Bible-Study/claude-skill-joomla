---
name: joomla
description: |
  Joomla 5+ extension development skill for building components, modules, plugins, and templates using modern Joomla MVC architecture with PSR-4 namespaces, dependency injection, and service providers. Use this skill whenever the user mentions Joomla extension development, Joomla components, Joomla modules, Joomla plugins, Joomla templates, Joomla MVC, provider.php, Joomla manifest XML, Joomla 5, Joomla 6, or any work involving Joomla CMS extension code. This skill covers scaffolding new extensions, adding views/models/controllers, writing service providers, creating manifest files, database migrations, language files, custom form fields, plugin event subscribers, module dispatchers, and web asset management. Even if the user just says "add a new view" or "create a controller" in a Joomla project context, use this skill. Also trigger for any Joomla-based project regardless of domain — church software, e-commerce, directories, booking systems, or any custom component.
---

# Joomla 5+ Extension Development

This skill guides you through building Joomla 5+ extensions (components, modules, plugins) using modern architecture patterns derived from the [joomla-cms](https://github.com/joomla/joomla-cms) core and real-world production components.

**Target:** Natively Joomla 6, backward compatible with Joomla 5 (no backward compatibility plugin required)
**PHP requirement:** 8.2+ (Joomla 6 minimum), 8.3+ recommended
**Coding standard:** PSR-12 (PHP), Joomla ESLint config (JavaScript)

## Coding Standards

### PHPDoc / DocBlocks

All PHP code must include proper docblocks following Joomla conventions. Whitespace inside docblocks uses **real spaces** (not tabs). The minimum spacing between tag elements (type, variable name, description) is **two spaces**, aligned to the longest element in the block.

**File header (required on every PHP file):**
```php
<?php

/**
 * @package     Vendor.Administrator
 * @subpackage  com_mycomponent
 *
 * @copyright   (C) 2025 Vendor Name. <https://example.com>
 * @license     GNU General Public License version 2 or later; see LICENSE.txt
 */
```

**Class docblock:**
```php
/**
 * Model for a single booking item.
 *
 * @since  1.0.0
 */
class BookingModel extends AdminModel
```

The `@since` tag is **required** on every class and indicates the version when the class was introduced.

**Property docblock:**
```php
/**
 * The prefix to use with controller messages.
 *
 * @var    string
 * @since  1.0.0
 */
protected $text_prefix = 'COM_BOOKINGS';
```

**Method docblock:**
```php
/**
 * Method to get the record form.
 *
 * @param   array    $data      Data for the form.
 * @param   boolean  $loadData  True if the form is to load its own data.
 *
 * @return  Form|boolean  A Form object on success, false on failure.
 *
 * @since   1.0.0
 * @throws  \Exception
 */
public function getForm($data = [], $loadData = true)
```

Key rules for method docblocks:

- `@param` — type, two+ spaces, `$variable`, two+ spaces, description. Align all `@param` entries.
- After the last `@param`, add a blank comment line before `@return`.
- `@return` — type and description. Always required (use `void` for no return).
- After `@return`, add a blank comment line before `@since`.
- `@since` — **required** on every public/protected method. Version when introduced.
- `@throws` — list each exception type the method can throw. No description needed.
- `@deprecated` — include when the method is deprecated, with a `@see` pointing to the replacement.

**Deprecated method example:**
```php
/**
 * Get the database driver.
 *
 * @return  DatabaseInterface
 *
 * @since       1.0.0
 * @deprecated  2.0.0  Use getDatabase() instead.
 * @see         getDatabase()
 */
public function getDbo()
```

**Tags NOT used in Joomla project code:** `@author` (prohibited in Joomla-owned code, allowed in third-party extensions), `@category` (rarely used).

### JavaScript / ESLint

Joomla core uses ESLint flat config (`eslint.config.mjs`). For extensions, match these conventions:

```javascript
// eslint.config.mjs
import { defineConfig } from 'eslint/config';

export default defineConfig([
    {
        files: ['media/**/*.js', 'build/**/*.js'],
        rules: {
            'no-restricted-globals': 'error',
        },
        languageOptions: {
            globals: {
                Joomla: true,        // Joomla core JS API
                bootstrap: true,     // Bootstrap JS (bundled with Joomla)
            },
        },
    },
]);
```

Key JavaScript conventions:

- ES6+ module syntax (`import`/`export`), no `var` (use `const`/`let`)
- `Joomla` global is available in all frontend/admin pages (provides `Joomla.Text`, `Joomla.submitform`, `Joomla.renderMessages`, etc.)
- Source JS goes in `build/media_source/` or a `build/` directory, compiled output goes to `media/com_mycomponent/js/`
- JSDoc comments on exported functions:

```javascript
/**
 * Refresh the items list via AJAX.
 *
 * @param {HTMLElement} container - The list container element.
 * @param {Object}      options   - Configuration options.
 * @param {number}      options.page - Page number to load.
 *
 * @returns {Promise<void>}
 *
 * @since 1.0.0
 */
export async function refreshList(container, options = {}) {
    // ...
}
```

### PHP_CodeSniffer

Joomla provides a custom ruleset via the `joomla/coding-standards` Composer package:

```bash
composer require --dev joomla/coding-standards
```

Run with:
```bash
./vendor/bin/phpcs --standard=Joomla src/
```

Or add a `phpcs.xml` at the project root:
```xml
<?xml version="1.0"?>
<ruleset name="My Component">
    <rule ref="Joomla"/>
    <file>admin/src</file>
    <file>site/src</file>
    <exclude-pattern>*/vendor/*</exclude-pattern>
    <exclude-pattern>*/node_modules/*</exclude-pattern>
</ruleset>
```

### Inline Comments

- Use C++ style (`//`) for code comments, with a space after `//`
- C-style block comments (`/* */`) are **only** for file/class/method docblocks
- Perl/shell style (`#`) comments are **not** allowed in PHP files

## Quick Start: Which Extension Type?

Before writing code, identify the right extension type:

- **Component** — Full application with admin backend + frontend views, database tables, CRUD operations, menus. Use when you need a complete management interface (e.g., a booking system, directory, inventory tracker, content manager).
- **Module** — Small, self-contained display block (sidebar, footer, header widget). Has a dispatcher, optional helper, and template. No admin CRUD — gets data from components or its own parameters.
- **Plugin** — Event-driven code that hooks into Joomla's lifecycle. Types include: content, system, finder (search), task (scheduled), webservices (API), schemaorg, and more.
- **Library** — Shared PHP code used by multiple extensions. Installed to `libraries/` and autoloaded via PSR-4 namespace. Use when you have utility classes, API wrappers, or shared logic consumed by your components, plugins, and modules.
- **Template** — Controls the site's HTML shell and layout overrides.

For detailed patterns of each type, read the appropriate reference file:
- `references/component.md` — Full component architecture
- `references/module.md` — Module structure and dispatcher pattern
- `references/plugin.md` — Plugin event subscriber pattern
- `references/library.md` — Library structure and packaging

## Core Architecture Principles

### 1. PSR-4 Namespaces (Everything Lives in src/)

All PHP classes go under `src/` and use PSR-4 autoloading. Joomla maps namespaces declared in the manifest XML.

**Component namespace declaration (manifest XML):**
```xml
<namespace path="src">Vendor\Component\MyComponent</namespace>
```

Joomla auto-expands this to:
- `Vendor\Component\MyComponent\Administrator\` → `admin/src/`
- `Vendor\Component\MyComponent\Site\` → `site/src/`
- `Vendor\Component\MyComponent\Api\` → `admin/src/Api/` (if present)

**Example:**
```xml
<namespace path="src">Acme\Component\Bookings</namespace>
```
- `Acme\Component\Bookings\Administrator\Model\BookingModel` → `admin/src/Model/BookingModel.php`
- `Acme\Component\Bookings\Site\View\Booking\HtmlView` → `site/src/View/Booking/HtmlView.php`

**Module namespace:**
```xml
<namespace path="src">Vendor\Module\MyModule</namespace>
```

**Plugin namespace:**
```xml
<namespace path="src">Vendor\Plugin\PluginGroup\MyPlugin</namespace>
```

Case sensitivity matters on Linux. Directory names and class names must match exactly.

> **Joomla 5/6 Compatibility Note:** `createQuery()` and `\Joomla\Input\Input` work on both Joomla 5 and 6. Writing code this way means it runs natively on J6 without the backward compatibility plugin, while also working fine on J5.

### 2. Service Provider (The Modern Entry Point)

Every extension has `services/provider.php` — this is how Joomla discovers and bootstraps the extension through its DI container.

**Component service provider pattern:**
```php
<?php
\defined('_JEXEC') or die;

use Vendor\Component\MyComponent\Administrator\Extension\MyComponentComponent;
use Joomla\CMS\Component\Router\RouterFactoryInterface;
use Joomla\CMS\Dispatcher\ComponentDispatcherFactoryInterface;
use Joomla\CMS\Extension\ComponentInterface;
use Joomla\CMS\Extension\Service\Provider\CategoryFactory;
use Joomla\CMS\Extension\Service\Provider\ComponentDispatcherFactory;
use Joomla\CMS\Extension\Service\Provider\MVCFactory;
use Joomla\CMS\Extension\Service\Provider\RouterFactory;
use Joomla\CMS\HTML\Registry;
use Joomla\CMS\MVC\Factory\MVCFactoryInterface;
use Joomla\DI\Container;
use Joomla\DI\ServiceProviderInterface;

return new class () implements ServiceProviderInterface {
    public function register(Container $container): void
    {
        $container->registerServiceProvider(new CategoryFactory('\\Vendor\\Component\\MyComponent'));
        $container->registerServiceProvider(new MVCFactory('\\Vendor\\Component\\MyComponent'));
        $container->registerServiceProvider(new ComponentDispatcherFactory('\\Vendor\\Component\\MyComponent'));
        $container->registerServiceProvider(new RouterFactory('\\Vendor\\Component\\MyComponent'));

        $container->set(
            ComponentInterface::class,
            function (Container $container) {
                $component = new MyComponentComponent(
                    $container->get(ComponentDispatcherFactoryInterface::class)
                );
                $component->setRegistry($container->get(Registry::class));
                $component->setMVCFactory($container->get(MVCFactoryInterface::class));
                $component->setRouterFactory($container->get(RouterFactoryInterface::class));

                return $component;
            }
        );
    }
};
```

The namespace string passed to each factory (e.g., `'\\Vendor\\Component\\MyComponent'`) tells Joomla where to find your Controller, Model, View, and Table classes. Get this wrong and nothing loads.

### 3. Modern Joomla API — What to Use and What to Avoid

This is critical. Code must work natively on Joomla 6 WITHOUT the "Behaviour - Backward Compatibility 6" plugin, and also run on Joomla 5.

**Use these (Joomla 6 native):**
| Task | Modern API |
|------|-----------|
| Database access | `$this->getDatabase()` or inject `DatabaseInterface` |
| Build queries | `$db->createQuery()` (preferred over `$db->getQuery(true)`) |
| Current user | `$this->getCurrentUser()` in models, `$this->getIdentity()` in views/controllers |
| Input handling | `\Joomla\Input\Input` (NOT `\Joomla\CMS\Input`) — CMS\Input is removed in J6 |
| Create model/table | MVCFactory `$this->getMVCFactory()->createModel('Name')` |
| Input in controllers | `$this->input` (already available, uses `\Joomla\Input\Input`) |
| Error handling | Throw exceptions (`\RuntimeException`, `\InvalidArgumentException`) |
| Web assets | `WebAssetManager` via `$wa = $this->getDocument()->getWebAssetManager()` |
| File operations | PHP native functions or Symfony Filesystem (NOT `\Joomla\CMS\Filesystem`) |
| getItem() return | Treat as `stdClass` (NOT `CMSObject`) — no `->get()` or `->set()` magic |

**Never use these (removed or behind compat plugin in Joomla 6):**
| Deprecated | Why | Replacement |
|-----------|-----|-------------|
| `getDbo()` or `$this->_db` | Removed in Joomla 5 | `$this->getDatabase()` |
| `$db->getQuery(true)` | Still works but deprecated pattern | `$db->createQuery()` |
| `\Joomla\CMS\Input` | Removed in Joomla 6 | `\Joomla\Input\Input` |
| `\Joomla\CMS\Filesystem` | Moved to compat plugin in J6, removed J7 | PHP native / Symfony |
| `CMSObject` properties via `->get()` / `->set()` | `getItem()` returns `stdClass` in J6 | Direct property access: `$item->title` |
| `Factory::getUser()` | Deprecated | `$this->getCurrentUser()` or `$this->getIdentity()` |
| `getSession()->get('user')` | Use identity methods | `$this->getIdentity()` |
| `getError()` / `setError()` | Use exceptions | Throw `\RuntimeException` |
| `new ClassName()` for models | Hard-coded dependencies | `$this->getMVCFactory()->createModel()` |
| `jimport()` | Removed | PSR-4 autoloading |
| `CMSObject` class | Deprecated, removed in J7 | `stdClass` or custom classes |
| `getErrorMsg()` | Removed | Throw exceptions |

### 4. Directory Structure

**Component layout:**
```
com_mycomponent/
├── mycomponent.xml              # Manifest
├── mycomponent.script.php       # Install/update script (optional)
├── admin/
│   ├── services/
│   │   └── provider.php         # DI container registration
│   ├── src/
│   │   ├── Extension/
│   │   │   └── MyComponentComponent.php
│   │   ├── Controller/
│   │   │   ├── DisplayController.php
│   │   │   ├── ItemController.php      # FormController (single item)
│   │   │   └── ItemsController.php     # AdminController (list)
│   │   ├── Model/
│   │   │   ├── ItemModel.php           # FormModel (single)
│   │   │   └── ItemsModel.php          # ListModel (list)
│   │   ├── View/
│   │   │   ├── Item/
│   │   │   │   └── HtmlView.php
│   │   │   └── Items/
│   │   │       └── HtmlView.php
│   │   ├── Table/
│   │   │   └── ItemTable.php
│   │   ├── Field/                      # Custom form fields
│   │   ├── Helper/                     # Utility classes
│   │   ├── Dispatcher/
│   │   │   └── Dispatcher.php
│   │   └── Service/
│   │       └── HTML/                   # HTMLHelper services
│   ├── forms/                          # XML form definitions
│   ├── sql/
│   │   ├── install.mysql.utf8.sql
│   │   └── updates/
│   │       └── mysql/
│   │           └── 1.0.0.sql
│   ├── tmpl/                           # Admin templates
│   │   ├── item/
│   │   │   └── edit.php
│   │   └── items/
│   │       └── default.php
│   ├── language/
│   │   └── en-GB/
│   │       ├── com_mycomponent.ini
│   │       └── com_mycomponent.sys.ini
│   ├── access.xml                      # ACL definitions
│   └── config.xml                      # Component options
├── site/
│   ├── src/
│   │   ├── Controller/
│   │   ├── Model/
│   │   ├── View/
│   │   ├── Dispatcher/
│   │   ├── Helper/
│   │   └── Service/
│   │       └── Router.php              # SEF URL routing
│   ├── forms/
│   ├── tmpl/
│   └── layouts/
└── media/
    ├── joomla.asset.json               # Web asset definitions
    ├── css/
    ├── js/
    └── images/
```

### 5. MVC Request Flow

Understanding the request lifecycle helps you know what to create:

```
URL → Router → Dispatcher → Controller → Model → Table (DB) → View → Template → Response
```

1. **Router** parses the URL to determine component, view, and ID
2. **Dispatcher** (admin/src/Dispatcher/) checks access and creates the controller
3. **Controller** handles the action (display, save, delete, publish)
4. **Model** fetches or manipulates data using database queries
5. **Table** maps to a single database row (load, store, delete, check)
6. **View** (HtmlView.php) prepares data for rendering
7. **Template** (tmpl/) outputs the HTML

### Admin URL Routing (task= vs view=)

Admin URLs use two patterns — understanding when to use each is critical:

**`task=` routing** — Triggers a controller action. The task format is `{controller}.{method}`:

```
index.php?option=com_example&task=item.edit&id=5
```

This calls `ItemController::edit()` (FormController), which:
1. Checks out the record (sets `checked_out` to current user)
2. Stores the return URL
3. Redirects to the edit view

**`view=` routing** — Displays a view directly (no controller action):

```
index.php?option=com_example&view=items         → List view
index.php?option=com_example&view=item&id=5     → Detail/edit view (NO checkout)
```

**When to use which:**

| Context | URL Pattern | Why |
|---------|-----------|-----|
| List → edit link | `task=item.edit&id=5` | Checks out the record to prevent concurrent edits |
| Toolbar "New" button | `task=item.add` | Creates a new record context |
| Submenu/menu link | `view=items` | Just display, no action needed |
| After save redirect | `view=items` or `view=item&id=5` | Display only, save already handled |
| Form action (POST) | Task set via hidden field | `<input type="hidden" name="task" value="">` — JS sets this on submit |

**Common mistake:** Using `view=item&layout=edit&id=5` to link from a list — this skips checkout, so two users can open the same record simultaneously and overwrite each other's changes.

**Checked-out handling in list templates:**

```php
<?php
$isCheckedOut = !empty($item->checked_out) && $item->checked_out != $userId;

if ($isCheckedOut) {
    // Show lock icon + plain text (another user is editing)
    echo HTMLHelper::_('jgrid.checkedout', $i, $item->editor, $item->checked_out_time, 'items.', $canCheckin);
    echo $this->escape($item->title);
} elseif ($canEdit) {
    // Editable — link via task routing (triggers checkout)
    echo '<a href="' . Route::_('index.php?option=com_example&task=item.edit&id=' . $item->id) . '">';
    echo $this->escape($item->title) . '</a>';
} else {
    // No permission — plain text
    echo $this->escape($item->title);
}
?>
```

To include the `editor` name in your list query, JOIN the users table:
```php
$query->select($db->quoteName('uc.name', 'editor'))
    ->join('LEFT', $db->quoteName('#__users', 'uc'), $db->quoteName('uc.id') . ' = ' . $db->quoteName('a.checked_out'));
```

### 6. Naming Conventions

Joomla has strict naming that connects everything automatically:

| What | Naming Pattern | Example |
|------|---------------|---------|
| Single-item controller | `{Entity}Controller` | `BookingController` |
| List controller | `{Entity}sController` (plural) | `BookingsController` |
| Single-item model | `{Entity}Model` | `BookingModel` |
| List model | `{Entity}sModel` (plural) | `BookingsModel` |
| Table class | `{Entity}Table` | `BookingTable` |
| Single-item view dir | `View/{Entity}/HtmlView.php` | `View/Booking/HtmlView.php` |
| List view dir | `View/{Entity}s/HtmlView.php` | `View/Bookings/HtmlView.php` |
| Edit template | `tmpl/{entity}/edit.php` | `tmpl/booking/edit.php` |
| List template | `tmpl/{entity}s/default.php` | `tmpl/bookings/default.php` |

Some projects use a prefix on entity names (e.g., `CwmBooking` for CWM components). This is optional but helps avoid naming collisions with other extensions.

The view name in the URL (`&view=cwmmessages`) must match the View directory name (case-insensitive on the URL side, but the directory must match the class namespace).

### 7. Database Patterns

**Install SQL** (`admin/sql/install.mysql.utf8.sql`):
```sql
CREATE TABLE IF NOT EXISTS `#__mycomponent_items` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `title` varchar(255) NOT NULL DEFAULT '',
    `alias` varchar(400) NOT NULL DEFAULT '',
    `published` tinyint NOT NULL DEFAULT 0,
    `access` int unsigned NOT NULL DEFAULT 0,
    `ordering` int NOT NULL DEFAULT 0,
    `checked_out` int unsigned,
    `checked_out_time` datetime,
    `created` datetime NOT NULL,
    `created_by` int unsigned NOT NULL DEFAULT 0,
    `modified` datetime NOT NULL,
    `modified_by` int unsigned NOT NULL DEFAULT 0,
    `params` text NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 DEFAULT COLLATE=utf8mb4_unicode_ci;
```

Use `#__` prefix — Joomla replaces it with the actual table prefix at runtime.

**Update SQL** (`admin/sql/updates/mysql/1.1.0.sql`):
```sql
ALTER TABLE `#__mycomponent_items` ADD COLUMN `description` text NOT NULL DEFAULT '' AFTER `alias`;
```

Version-numbered files are executed sequentially during updates.

### 8. Language Files

**Format:** INI files with `COMPONENT_PREFIX_KEY="Value"` pattern.

```ini
; admin/language/en-GB/com_mycomponent.ini
COM_MYCOMPONENT="My Component"
COM_MYCOMPONENT_ITEMS="Items"
COM_MYCOMPONENT_ITEM_EDIT="Edit Item"
COM_MYCOMPONENT_FIELD_TITLE_LABEL="Title"
COM_MYCOMPONENT_FIELD_TITLE_DESC="Enter the item title"
COM_MYCOMPONENT_N_ITEMS_PUBLISHED="%d items published."
```

**System strings** (`.sys.ini`) are used in the admin menu and during install:
```ini
; admin/language/en-GB/com_mycomponent.sys.ini
COM_MYCOMPONENT="My Component"
COM_MYCOMPONENT_XML_DESCRIPTION="A Joomla component for..."
COM_MYCOMPONENT_MENU_ITEMS="Items"
```

### 9. Web Asset Management (joomla.asset.json)

```json
{
  "$schema": "https://developer.joomla.org/schemas/json-schema/web_assets.json",
  "name": "com_mycomponent",
  "version": "1.0.0",
  "assets": [
    {
      "name": "com_mycomponent.admin",
      "type": "style",
      "uri": "com_mycomponent/admin.css"
    },
    {
      "name": "com_mycomponent.admin.script",
      "type": "script",
      "uri": "com_mycomponent/admin.js",
      "dependencies": ["core"]
    }
  ]
}
```

**Usage in views/templates:**
```php
/** @var Joomla\CMS\WebAsset\WebAssetManager $wa */
$wa = $this->getDocument()->getWebAssetManager();
$wa->useStyle('com_mycomponent.admin');
$wa->useScript('com_mycomponent.admin.script');
```

### 10. Manifest XML

Read `references/component.md` for the full manifest template. Key elements:

```xml
<?xml version="1.0" encoding="utf-8"?>
<extension type="component" method="upgrade">
    <name>com_mycomponent</name>
    <namespace path="src">Vendor\Component\MyComponent</namespace>
    <version>1.0.0</version>
    <!-- ... metadata ... -->

    <files folder="site">
        <folder>src</folder>
        <folder>tmpl</folder>
        <folder>forms</folder>
        <folder>layouts</folder>
    </files>

    <media destination="com_mycomponent" folder="media">
        <filename>joomla.asset.json</filename>
        <folder>css</folder>
        <folder>js</folder>
    </media>

    <administration>
        <menu>COM_MYCOMPONENT</menu>
        <submenu>
            <menu link="option=com_mycomponent&amp;view=items" view="items">
                COM_MYCOMPONENT_MENU_ITEMS
            </menu>
        </submenu>
        <files folder="admin">
            <folder>forms</folder>
            <folder>language</folder>
            <folder>services</folder>
            <folder>sql</folder>
            <folder>src</folder>
            <folder>tmpl</folder>
            <filename>access.xml</filename>
            <filename>config.xml</filename>
        </files>
    </administration>

    <install>
        <sql><file driver="mysql" charset="utf8">sql/install.mysql.utf8.sql</file></sql>
    </install>
    <update>
        <schemas><schemapath type="mysql">sql/updates/mysql</schemapath></schemas>
    </update>

    <changelogurl>https://example.com/changelogs/com_mycomponent/changelog.xml</changelogurl>
    <updateservers>
        <server type="extension" name="My Component Updates">https://example.com/updates/com_mycomponent_update.xml</server>
    </updateservers>
</extension>
```

### 11. Changelog

Joomla displays changelogs in the Extensions → Manage view, linked per version. To enable this, add a `<changelogurl>` tag to your manifest XML (shown above) pointing to an XML file hosted publicly.

**Changelog XML file structure:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<changelogs>
    <changelog>
        <element>com_mycomponent</element>
        <type>component</type>
        <version>1.0.0</version>
        <note>
            <item>Initial release</item>
        </note>
    </changelog>
    <changelog>
        <element>com_mycomponent</element>
        <type>component</type>
        <version>1.1.0</version>
        <security>
            <item>Fixed XSS vulnerability in input fields</item>
            <item><![CDATA[<a href="https://example.com/advisory/001">Advisory 001</a>]]></item>
        </security>
        <fix>
            <item>Fixed pagination on list views</item>
            <item>Corrected date format in export</item>
        </fix>
        <language>
            <item>Added Dutch translation</item>
        </language>
        <addition>
            <item>New dashboard widget</item>
            <item>REST API endpoint for items</item>
        </addition>
        <change>
            <item>Improved search performance</item>
        </change>
        <remove>
            <item>Removed legacy import format</item>
        </remove>
        <note>
            <item>Requires PHP 8.2+</item>
        </note>
    </changelog>
</changelogs>
```

**Required nodes per `<changelog>` entry:** `<element>`, `<type>`, `<version>`.

**Supported change type categories:** `<security>`, `<fix>`, `<language>`, `<addition>`, `<change>`, `<remove>`, `<note>`. Each contains one or more `<item>` elements.

**HTML in items:** Wrap HTML content in CDATA tags: `<item><![CDATA[<strong>Bold text</strong>]]></item>`

**Element and type values by extension type:**

| Extension Type | `<element>` | `<type>` |
|---------------|-------------|----------|
| Component | `com_mycomponent` | `component` |
| Module | `mod_mymodule` | `module` |
| Plugin | `plg_group_name` | `plugin` |
| Template | `tpl_mytemplate` | `template` |
| Library | `lib_mylib` | `library` |
| Package | `pkg_mypackage` | `package` |

The `<changelogurl>` tag must not have spaces or line breaks around the URL. Host the changelog XML on a publicly accessible URL (GitHub raw, your project website, etc.).

### 12. Update Server

The update server tells Joomla where to check for new versions of your extension. Add `<updateservers>` to the manifest (shown above) and host an update XML file:

**Update server XML:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<updates>
    <update>
        <name>My Component</name>
        <description>My Component for Joomla</description>
        <element>com_mycomponent</element>
        <type>component</type>
        <version>1.1.0</version>
        <infourl title="My Component 1.1.0 Release">https://example.com/releases/1.1.0</infourl>
        <downloads>
            <downloadurl type="full" format="zip">https://example.com/downloads/com_mycomponent-1.1.0.zip</downloadurl>
        </downloads>
        <tags>
            <tag>stable</tag>
        </tags>
        <targetplatform name="joomla" version="5\.[0-9]+" />
        <php_minimum>8.2.0</php_minimum>
        <sha256>abc123...</sha256>
        <sha384>def456...</sha384>
        <sha512>ghi789...</sha512>
        <maintainer>Vendor Name</maintainer>
        <maintainerurl>https://example.com</maintainerurl>
        <changelogurl>https://example.com/changelogs/com_mycomponent/changelog.xml</changelogurl>
    </update>
</updates>
```

Key fields: `<targetplatform>` uses regex for version matching (e.g., `5\.[0-9]+` matches all Joomla 5.x). Add multiple `<update>` blocks for different versions. The `<changelogurl>` here links the same changelog XML so Joomla can show changes before updating.

For plugins, add `folder="plugingroup"` and `client="site"` attributes to the `<update>` element. For modules, add `client="site"` or `client="administrator"`.

## Workflow: Adding a New Entity to a Component

When adding a new entity (e.g., "Location" to a component), create these files:

1. **Table** — `admin/src/Table/LocationTable.php`
2. **Model (single)** — `admin/src/Model/LocationModel.php` (extends FormModel)
3. **Model (list)** — `admin/src/Model/LocationsModel.php` (extends ListModel)
4. **Controller (single)** — `admin/src/Controller/LocationController.php` (extends FormController)
5. **Controller (list)** — `admin/src/Controller/LocationsController.php` (extends AdminController)
6. **View (edit)** — `admin/src/View/Location/HtmlView.php`
7. **View (list)** — `admin/src/View/Locations/HtmlView.php`
8. **Templates** — `admin/tmpl/location/edit.php` and `admin/tmpl/locations/default.php`
9. **Form XML** — `admin/forms/location.xml`
10. **SQL** — Add CREATE TABLE to install SQL, add update SQL file
11. **Language strings** — Add to `.ini` files
12. **Menu entry** — Add `<menu>` to manifest XML submenu

For detailed code templates of each file, read `references/component.md`.

## Component Lifecycle & Patterns

This section covers the internal mechanics of how components work — the lifecycle hooks, data flow, and integration points that the directory structure alone doesn't explain.

### Model Lifecycle

When Joomla saves a record, the flow is: **Controller** → `Model::save()` → `Model::prepareTable()` → `Table::bind()` → `Table::check()` → `Table::store()`.

**`prepareTable()`** — Called before `store()`. Use for auto-setting ordering on new records, updating `modified`/`modified_by` timestamps, and generating aliases:

```php
// In AdminModel
protected function prepareTable($table): void
{
    if (empty($table->id)) {
        // Set ordering to last position for new items
        if (empty($table->ordering)) {
            $db    = $this->getDatabase();
            $query = $db->createQuery()
                ->select('MAX(' . $db->quoteName('ordering') . ')')
                ->from($db->quoteName('#__example_items'));
            $db->setQuery($query);
            $table->ordering = (int) $db->loadResult() + 1;
        }

        if (empty($table->created)) {
            $table->created = Factory::getDate()->toSql();
        }

        if (empty($table->created_by)) {
            $table->created_by = Factory::getApplication()->getIdentity()->id;
        }
    } else {
        $table->modified    = Factory::getDate()->toSql();
        $table->modified_by = Factory::getApplication()->getIdentity()->id;
    }

    // Auto-generate alias
    if (empty($table->alias)) {
        $table->alias = $table->title;
    }

    $table->alias = ApplicationHelper::stringURLSafe($table->alias);
}
```

**`getItem()` override** — For loading related data alongside the main record:

```php
public function getItem($pk = null): mixed
{
    $item = parent::getItem($pk);

    if ($item && $item->id) {
        // Load related tags, categories, or junction table data
        $item->tags = new TagsHelper();
        $item->tags->getItemTags('com_example.item', $item->id);
    }

    return $item;
}
```

**`save()` override** — For post-save operations (junction tables, related records, file uploads):

```php
public function save($data): bool
{
    if (!parent::save($data)) {
        return false;
    }

    $id = (int) $this->getState($this->getName() . '.id');

    // Save junction table data (e.g., item-to-tag mappings)
    $this->saveRelatedItems($id, $data['related_ids'] ?? []);

    return true;
}
```

### Table bind() and store()

**`bind()`** — Converts arrays/objects to JSON for storage in `params` or `metadata` columns:

```php
public function bind($src, $ignore = ''): bool
{
    // Convert params array to JSON string
    if (isset($src['params']) && \is_array($src['params'])) {
        $src['params'] = json_encode($src['params']);
    }

    return parent::bind($src, $ignore);
}
```

**`store()`** — Override for computed columns or auto-increment logic beyond what `check()` handles:

```php
public function store($updateNulls = true): bool
{
    $date = Factory::getDate()->toSql();
    $user = Factory::getApplication()->getIdentity();

    if (empty($this->id)) {
        if (empty($this->created)) {
            $this->created = $date;
        }
        if (empty($this->created_by)) {
            $this->created_by = $user->id;
        }
    } else {
        $this->modified    = $date;
        $this->modified_by = $user->id;
    }

    return parent::store($updateNulls);
}
```

> **Note:** Auto-timestamps can go in either `prepareTable()` (model) or `store()` (table). The model approach is more common in Joomla core. Pick one location per project and be consistent.

### Filter Forms (Searchtools)

List views use a filter form XML to power the search/filter toolbar. This is what drives `$this->filterForm` and `$this->activeFilters` in the list view.

**File:** `admin/forms/filter_items.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<form>
    <fields name="filter">
        <field
            name="search"
            type="text"
            inputmode="search"
            label="COM_EXAMPLE_FILTER_SEARCH_LABEL"
            description="COM_EXAMPLE_FILTER_SEARCH_DESC"
            hint="JSEARCH_FILTER"
        />

        <field
            name="published"
            type="status"
            label="JOPTION_SELECT_PUBLISHED"
            onchange="this.form.submit();"
        >
            <option value="">JOPTION_SELECT_PUBLISHED</option>
        </field>

        <field
            name="category_id"
            type="category"
            extension="com_example"
            label="JCATEGORY"
            onchange="this.form.submit();"
        >
            <option value="">JOPTION_SELECT_CATEGORY</option>
        </field>

        <field
            name="access"
            type="accesslevel"
            label="JFIELD_ACCESS_LABEL"
            onchange="this.form.submit();"
        >
            <option value="">JOPTION_SELECT_ACCESS</option>
        </field>
    </fields>

    <fields name="list">
        <field
            name="fullordering"
            type="list"
            label="JGLOBAL_SORT_BY"
            default="a.id DESC"
            onchange="this.form.submit();"
        >
            <option value="">JGLOBAL_SORT_BY</option>
            <option value="a.title ASC">JGLOBAL_TITLE_ASC</option>
            <option value="a.title DESC">JGLOBAL_TITLE_DESC</option>
            <option value="a.published ASC">JSTATUS_ASC</option>
            <option value="a.published DESC">JSTATUS_DESC</option>
            <option value="a.id ASC">JGRID_HEADING_ID_ASC</option>
            <option value="a.id DESC">JGRID_HEADING_ID_DESC</option>
        </field>

        <field
            name="limit"
            type="limitbox"
            label="JGLOBAL_LIST_LIMIT"
            default="25"
            onchange="this.form.submit();"
        />
    </fields>
</form>
```

The file must be named `filter_{view}.xml` (e.g., `filter_items.xml` for the `items` view). Joomla auto-discovers it by convention.

### Install/Update Script

**File:** `mycomponent.script.php`

The script class runs during install, update, and uninstall. Critical for DML operations (INSERT, UPDATE, DELETE) that can't go in SQL update files (which only run DDL).

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Installer\InstallerAdapter;
use Joomla\CMS\Factory;

class Com_MyComponentInstallerScript
{
    protected string $minimumPhp = '8.2.0';
    protected string $minimumJoomla = '5.0.0';

    public function preflight(string $type, InstallerAdapter $adapter): bool
    {
        // Runs BEFORE install/update. Return false to abort.
        if (version_compare(PHP_VERSION, $this->minimumPhp, '<')) {
            $adapter->getParent()->abort(
                "This extension requires PHP {$this->minimumPhp}+"
            );
            return false;
        }

        return true;
    }

    public function install(InstallerAdapter $adapter): bool
    {
        // Runs on fresh install only (not updates)
        return true;
    }

    public function update(InstallerAdapter $adapter): bool
    {
        // Runs on update only (not fresh install)
        // Good place for DML migrations
        return true;
    }

    public function postflight(string $type, InstallerAdapter $adapter): void
    {
        // Runs AFTER install/update. $type is 'install', 'update', or 'discover_install'
        if ($type === 'update') {
            $this->runDataMigrations($adapter);
        }
    }

    public function uninstall(InstallerAdapter $adapter): bool
    {
        // Cleanup: remove related records, files, etc.
        return true;
    }

    private function runDataMigrations(InstallerAdapter $adapter): void
    {
        $db = Factory::getContainer()->get('DatabaseDriver');
        // Run DML migrations that SQL update files can't handle
    }
}
```

**Key rule:** SQL update files (`sql/updates/mysql/`) only execute **DDL** (ALTER TABLE, CREATE INDEX). For **DML** (INSERT, UPDATE, DELETE data), use the install script's `update()` or `postflight()`.

### Component Options (config.xml)

**File:** `admin/config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<config>
    <fieldset name="component"
              label="COM_EXAMPLE_CONFIG_GENERAL"
              description="COM_EXAMPLE_CONFIG_GENERAL_DESC">

        <field
            name="items_per_page"
            type="number"
            label="COM_EXAMPLE_CONFIG_ITEMS_PER_PAGE"
            default="20"
            min="5"
            max="100"
        />

        <field
            name="show_author"
            type="radio"
            label="COM_EXAMPLE_CONFIG_SHOW_AUTHOR"
            default="1"
            class="btn-group"
        >
            <option value="0">JNO</option>
            <option value="1">JYES</option>
        </field>
    </fieldset>

    <fieldset name="permissions"
              label="JCONFIG_PERMISSIONS_LABEL"
              description="JCONFIG_PERMISSIONS_DESC">
        <field
            name="rules"
            type="rules"
            label="JCONFIG_PERMISSIONS_LABEL"
            filter="rules"
            component="com_example"
            section="component"
        />
    </fieldset>
</config>
```

Access options in code: `ComponentHelper::getParams('com_example')->get('items_per_page', 20)`.

### Site-Side Differences

Site (frontend) views differ from admin in several important ways:

**Caching** — Site DisplayController should enable caching:
```php
class DisplayController extends BaseController
{
    public function display($cachable = false, $urlparams = []): static
    {
        $cachable = true; // Enable page caching for site views

        $urlparams = [
            'id'     => 'INT',
            'catid'  => 'INT',
            'limit'  => 'UINT',
            'format' => 'WORD',
        ];

        return parent::display($cachable, $urlparams);
    }
}
```

**Access level filtering** — Site models MUST filter by the user's access levels:
```php
// In site ListModel::getListQuery()
$query->whereIn($db->quoteName('a.access'), $user->getAuthorisedViewLevels());
```

**Menu item parameters** — Site views receive parameters from the menu item:
```php
// In site HtmlView::display()
$app    = Factory::getApplication();
$params = $app->getParams(); // Merged: menu item params + component params
$this->params = $params;

// In the template
$showTitle = $this->params->get('show_title', 1);
```

**Page metadata** — Site views should set page title, description, and breadcrumbs:
```php
protected function prepareDocument(): void
{
    $app = Factory::getApplication();

    // Page title
    $title = $this->item->title;
    $this->getDocument()->setTitle($title);

    // Meta description
    if ($this->item->metadesc) {
        $this->getDocument()->setDescription($this->item->metadesc);
    }

    // Breadcrumbs
    $pathway = $app->getPathway();
    $pathway->addItem($this->item->title);
}
```

### Extension Class: Service Interfaces

The Extension class (`admin/src/Extension/`) can implement interfaces to integrate with Joomla's category, tag, and workflow systems:

```php
use Joomla\CMS\Categories\CategoryServiceInterface;
use Joomla\CMS\Categories\CategoryServiceTrait;
use Joomla\CMS\Extension\BootableExtensionInterface;
use Joomla\CMS\Extension\MVCComponent;
use Joomla\CMS\HTML\HTMLRegistryAwareTrait;
use Joomla\CMS\Tag\TagServiceInterface;
use Joomla\CMS\Tag\TagServiceTrait;

class MyComponentComponent extends MVCComponent
    implements BootableExtensionInterface, CategoryServiceInterface, TagServiceInterface
{
    use HTMLRegistryAwareTrait;
    use CategoryServiceTrait;
    use TagServiceTrait;

    public function boot(ContainerInterface $container): void
    {
        // Register HTML service for rendering in templates
        $this->getRegistry()->register('mycomponent', new AdministratorService\HTML\Mycomponent());
    }

    public function getTableNameForSection(string $section = null): string
    {
        return '#__example_items';
    }

    public function countItems(array $items, string $section): void
    {
        // Count items per category for the category manager
        $db = Factory::getContainer()->get('DatabaseDriver');

        foreach ($items as $item) {
            $query = $db->createQuery()
                ->select('COUNT(*)')
                ->from($db->quoteName('#__example_items'))
                ->where($db->quoteName('catid') . ' = :catid')
                ->bind(':catid', $item->id, ParameterType::INTEGER);
            $db->setQuery($query);
            $item->count_items = (int) $db->loadResult();
        }
    }
}
```

Register the category service in `provider.php`:
```php
$container->registerServiceProvider(new CategoryFactory('\\Vendor\\Component\\MyComponent'));
```

### Custom Controller Tasks & AJAX

For non-CRUD actions (import, export, custom workflows), add methods to your controller:

```php
// In a FormController or BaseController subclass
public function export(): void
{
    $this->checkToken();

    $model = $this->getModel();
    $data  = $model->getExportData();

    $this->app->setHeader('Content-Type', 'text/csv');
    $this->app->setHeader('Content-Disposition', 'attachment; filename="export.csv"');
    $this->app->sendHeaders();

    echo $data;
    $this->app->close();
}
```

**AJAX JSON responses** — For JavaScript-driven interactions:

```php
public function fetchItems(): void
{
    $this->checkToken('get');

    try {
        $model = $this->getModel('Items');
        $items = $model->getItems();

        echo json_encode(['success' => true, 'data' => $items]);
    } catch (\Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }

    $this->app->close();
}
```

Call from JavaScript:
```javascript
const response = await fetch(
    `index.php?option=com_example&task=items.fetchItems&${Joomla.getOptions('csrf.token')}=1`,
    { method: 'POST' }
);
```

### HTMLHelper Services

Register reusable rendering methods as HTMLHelper services to use in templates with `HTMLHelper::_()`:

**File:** `admin/src/Service/HTML/Mycomponent.php`

```php
<?php

namespace Vendor\Component\MyComponent\Administrator\Service\HTML;

use Joomla\CMS\Language\Text;

class Mycomponent
{
    public function statusBadge(int $published): string
    {
        $class = match ($published) {
            1  => 'bg-success',
            0  => 'bg-secondary',
            -2 => 'bg-danger',
            default => 'bg-warning',
        };

        $text = match ($published) {
            1  => 'JPUBLISHED',
            0  => 'JUNPUBLISHED',
            -2 => 'JTRASHED',
            default => 'JARCHIVED',
        };

        return '<span class="badge ' . $class . '">' . Text::_($text) . '</span>';
    }
}
```

Register in the Extension class `boot()` method, then use in templates:
```php
<?php echo HTMLHelper::_('mycomponent.statusBadge', $item->published); ?>
```

### Form XML: Conditional Fields (showon)

Use `showon` to show/hide fields based on other field values:

```xml
<field
    name="link_type"
    type="list"
    label="Link Type"
    default="internal"
>
    <option value="internal">Internal</option>
    <option value="external">External URL</option>
</field>

<!-- Only shown when link_type = external -->
<field
    name="external_url"
    type="url"
    label="External URL"
    showon="link_type:external"
/>

<!-- Multiple conditions: shown when type=advanced AND published=1 -->
<field
    name="advanced_option"
    type="text"
    label="Advanced Option"
    showon="link_type:external[AND]published:1"
/>
```

`showon` supports `[AND]` and `[OR]` operators, and `!:` for negation (e.g., `showon="type!:simple"`).

### Form XML: Fieldset Groups for Tabs

Fieldsets map to tabs in the edit view when you use `HTMLHelper::_('uitab')`:

```xml
<form>
    <fieldset name="details" label="JDETAILS">
        <field name="title" type="text" label="JGLOBAL_TITLE" required="true" />
        <field name="description" type="editor" label="JGLOBAL_DESCRIPTION" />
    </fieldset>

    <fieldset name="publishing" label="JGLOBAL_FIELDSET_PUBLISHING">
        <field name="created" type="calendar" label="JGLOBAL_FIELD_CREATED_LABEL" />
        <field name="created_by" type="user" label="JGLOBAL_FIELD_CREATED_BY_LABEL" />
        <field name="modified" type="calendar" label="JGLOBAL_FIELD_MODIFIED_LABEL" readonly="true" />
    </fieldset>

    <fieldset name="params" label="JGLOBAL_FIELDSET_OPTIONS">
        <field name="show_title" type="radio" label="Show Title" default="1" class="btn-group">
            <option value="0">JNO</option>
            <option value="1">JYES</option>
        </field>
    </fieldset>
</form>
```

Render in the edit template:
```php
<?php echo HTMLHelper::_('uitab.addTab', 'myTab', 'details', Text::_('JDETAILS')); ?>
    <?php echo $this->form->renderFieldset('details'); ?>
<?php echo HTMLHelper::_('uitab.endTab'); ?>

<?php echo HTMLHelper::_('uitab.addTab', 'myTab', 'publishing', Text::_('JGLOBAL_FIELDSET_PUBLISHING')); ?>
    <?php echo $this->form->renderFieldset('publishing'); ?>
<?php echo HTMLHelper::_('uitab.endTab'); ?>
```

## Advanced Component Features

### Toolbar API (Modern Pattern)

Get the toolbar instance via `$this->getDocument()->getToolbar()` (not the deprecated `Toolbar::getInstance()`):

```php
protected function addToolbar(): void
{
    $toolbar = $this->getDocument()->getToolbar();
    $canDo   = ContentHelper::getActions('com_example');

    ToolbarHelper::title(Text::_('COM_EXAMPLE_ITEMS'), 'list');

    if ($canDo->get('core.create')) {
        $toolbar->addNew('item.add');
    }

    if ($canDo->get('core.edit.state') || $canDo->get('core.delete')) {
        // Dropdown groups related actions under one button
        $dropdown = $toolbar->dropdownButton('status-group')
            ->text('JTOOLBAR_CHANGE_STATUS')
            ->toggleSplit(false)
            ->icon('icon-ellipsis-h')
            ->buttonClass('btn btn-action')
            ->listCheck(true);

        $childBar = $dropdown->getChildToolbar();

        if ($canDo->get('core.edit.state')) {
            $childBar->publish('items.publish')->listCheck(true);
            $childBar->unpublish('items.unpublish')->listCheck(true);
            $childBar->archive('items.archive')->listCheck(true);
            $childBar->checkin('items.checkin');
        }

        if ($canDo->get('core.create') && $canDo->get('core.edit')) {
            // Batch popup button
            $childBar->popupButton('batch', 'JTOOLBAR_BATCH')
                ->popupType('inline')
                ->textHeader(Text::_('COM_EXAMPLE_BATCH_OPTIONS'))
                ->url('#joomla-dialog-batch')
                ->modalWidth('800px')
                ->modalHeight('fit-content')
                ->listCheck(true);
        }

        if ($canDo->get('core.delete')) {
            $childBar->trash('items.trash')->listCheck(true);
        }
    }

    if ($canDo->get('core.admin')) {
        $toolbar->preferences('com_example');
    }
}
```

**Edit view toolbar** — use a save dropdown for save variants:

```php
$toolbar->apply('item.apply');

$saveGroup = $toolbar->dropdownButton('save-group');
$saveGroup->configure(function (Toolbar $childBar) use ($viewName) {
    $childBar->save($viewName . '.save');
    $childBar->save2new($viewName . '.save2new');
    $childBar->save2copy($viewName . '.save2copy');
});

$toolbar->cancel('item.cancel', $isNew ? 'JTOOLBAR_CANCEL' : 'JTOOLBAR_CLOSE');
```

**Available toolbar button methods** (from `CoreButtonsTrait`):
`addNew`, `apply`, `save`, `save2new`, `save2copy`, `cancel`, `publish`, `unpublish`, `archive`, `unarchive`, `trash`, `delete`, `checkin`, `preferences`, `help`, `back`, `link`, `versions`, `divider`

### Batch Processing

Batch operations are built into `AdminModel`. The model provides: `batchAccess()`, `batchCopy()`, `batchMove()`, `batchLanguage()`, `batchTag()`.

**Batch form template** — use Joomla's built-in layout renderers:

```php
<!-- In list template, after the table -->
<template id="joomla-dialog-batch">
    <div class="p-3">
        <div class="row">
            <div class="form-group col-md-6">
                <?php echo LayoutHelper::render('joomla.html.batch.access', []); ?>
            </div>
            <div class="form-group col-md-6">
                <?php echo LayoutHelper::render('joomla.html.batch.tag', []); ?>
            </div>
        </div>
        <div class="row">
            <div class="form-group col-md-6">
                <?php echo LayoutHelper::render('joomla.html.batch.item', ['extension' => 'com_example']); ?>
            </div>
        </div>
    </div>
    <div class="btn-toolbar p-3">
        <joomla-toolbar-button task="item.batch" class="ms-auto">
            <button type="button" class="btn btn-success"><?php echo Text::_('JGLOBAL_BATCH_PROCESS'); ?></button>
        </joomla-toolbar-button>
    </div>
</template>
```

**Available batch layouts:** `joomla.html.batch.access`, `joomla.html.batch.language`, `joomla.html.batch.item` (category move/copy), `joomla.html.batch.tag`, `joomla.html.batch.workflowstage`

**Controller:** Override `batch()` in your FormController to specify the model:

```php
public function batch($model = null)
{
    $this->checkToken();
    $model = $this->getModel('Item', 'Administrator', []);
    $this->setRedirect(Route::_('index.php?option=com_example&view=items', false));
    return parent::batch($model);
}
```

### Ordering / Drag-Drop Reordering

Enable drag-drop reordering in admin list views. Requirements: an `ordering` INT column, `AdminController` (inherits `saveOrderAjax()`), and specific template markup.

**List template setup:**

```php
<?php
$listOrder = $this->escape($this->state->get('list.ordering'));
$listDirn  = $this->escape($this->state->get('list.direction'));
$saveOrder = ($listOrder === 'a.ordering');

if ($saveOrder && !empty($this->items)) {
    $saveOrderingUrl = 'index.php?option=com_example&task=items.saveOrderAjax&tmpl=component&'
        . Session::getFormToken() . '=1';
    HTMLHelper::_('draggablelist.draggable');
}
?>
```

**Tbody with drag-drop attributes:**

```php
<tbody<?php if ($saveOrder) : ?>
    class="js-draggable"
    data-url="<?php echo $saveOrderingUrl; ?>"
    data-direction="<?php echo strtolower($listDirn); ?>"
    data-nested="true"
<?php endif; ?>>
```

**Row with group attribute** (for category-scoped ordering):

```php
<tr class="row<?php echo $i % 2; ?>" data-draggable-group="<?php echo $item->catid; ?>">
```

**Ordering column in each row:**

```php
<td class="text-center d-none d-md-table-cell">
    <?php
    $iconClass = '';
    if (!$canChange) {
        $iconClass = ' inactive';
    } elseif (!$saveOrder) {
        $iconClass = ' inactive" title="' . Text::_('JORDERINGDISABLED');
    }
    ?>
    <span class="sortable-handler<?php echo $iconClass; ?>">
        <span class="icon-ellipsis-v" aria-hidden="true"></span>
    </span>
    <?php if ($canChange && $saveOrder) : ?>
        <input type="text" name="order[]" size="5"
               value="<?php echo $item->ordering; ?>"
               class="width-20 text-area-order hidden">
    <?php endif; ?>
</td>
```

**Required HTML attributes summary:**

| Attribute | Element | Purpose |
|-----------|---------|---------|
| `class="js-draggable"` | `<tbody>` | Enables drag-drop |
| `data-url` | `<tbody>` | AJAX save endpoint |
| `data-direction` | `<tbody>` | Sort direction (asc/desc) |
| `data-nested="true"` | `<tbody>` | Group by category |
| `data-draggable-group` | `<tr>` | Category/group ID |
| `class="sortable-handler"` | `<span>` | Drag handle |
| `name="order[]"` | `<input>` | Ordering value |

### Tags Integration

Implement tag support by adding interfaces to your Extension class and Table:

**Extension class:**
```php
use Joomla\CMS\Tag\TagServiceInterface;
use Joomla\CMS\Tag\TagServiceTrait;

class MyComponentComponent extends MVCComponent
    implements BootableExtensionInterface, TagServiceInterface
{
    use TagServiceTrait;

    public function getTableNameForSection(string $section = null): string
    {
        return '#__example_items';
    }
}
```

**Table class** — implement `TaggableTableInterface`:
```php
use Joomla\CMS\Tag\TaggableTableInterface;
use Joomla\CMS\Tag\TaggableTableTrait;

class ItemTable extends Table implements TaggableTableInterface
{
    use TaggableTableTrait;

    public $typeAlias = 'com_example.item';

    public function getTypeAlias(): string
    {
        return $this->typeAlias;
    }
}
```

**Form XML:**
```xml
<field name="tags" type="tag" label="JTAG" mode="ajax" multiple="true" />
```

The `taggable` behaviour plugin automatically handles tag save/load/delete via table events when your table implements `TaggableTableInterface`. Tags are stored in `#__contentitem_tag_map`.

### Content Versioning (History)

Enable version tracking so users can restore previous versions of records.

**Model** — implement `VersionableModelInterface`:
```php
use Joomla\CMS\Versioning\VersionableModelInterface;
use Joomla\CMS\Versioning\VersionableModelTrait;

class ItemModel extends AdminModel implements VersionableModelInterface
{
    use VersionableModelTrait;

    public $typeAlias = 'com_example.item';

    // Fields excluded from change detection hash
    protected $ignoreChanges = ['modified_by', 'modified', 'checked_out', 'checked_out_time'];

    // Fields normalized to int for consistent hashing
    protected $convertToInt = ['publish_up', 'publish_down', 'ordering'];
}
```

**Controller** — add history restore support:
```php
use Joomla\CMS\Versioning\VersionableControllerTrait;

class ItemController extends FormController
{
    use VersionableControllerTrait;
}
```

**Toolbar** — add versions button in edit view:
```php
if ($this->item->id) {
    $toolbar->versions('com_example.item', $this->item->id);
}
```

**Enable via component config** — add to `config.xml`:
```xml
<field name="save_history" type="radio" label="JGLOBAL_SAVE_HISTORY_OPTIONS_LABEL" default="1" class="btn-group">
    <option value="0">JNO</option>
    <option value="1">JYES</option>
</field>
<field name="history_limit" type="number" label="JGLOBAL_HISTORY_LIMIT_OPTIONS_LABEL" default="10" min="0" />
```

**Content type registration** — insert into `#__content_types` during install (in your install script):
```php
$type = new \stdClass();
$type->type_title = 'Example Item';
$type->type_alias = 'com_example.item';
$type->table = json_encode([
    'special' => ['dbtable' => '#__example_items', 'key' => 'id', 'type' => 'ItemTable', 'prefix' => 'Administrator'],
]);
$type->content_history_options = json_encode([
    'ignoreChanges' => ['modified_by', 'modified', 'checked_out', 'checked_out_time'],
    'convertToInt'  => ['publish_up', 'publish_down', 'ordering'],
]);
$db->insertObject('#__content_types', $type);
```

### Workflow Integration

Joomla's Publishing Workflow system lets administrators define custom stages and transitions for content. This is **optional** — most components don't need it.

**Extension class:**
```php
use Joomla\CMS\Workflow\WorkflowServiceInterface;
use Joomla\CMS\Workflow\WorkflowServiceTrait;

class MyComponentComponent extends MVCComponent
    implements WorkflowServiceInterface
{
    use WorkflowServiceTrait;

    // Which workflow functionalities this component supports
    protected $supportedFunctionality = [
        'core.state' => true,
    ];

    public function getWorkflowContexts(): array
    {
        return ['com_example.item'];
    }

    public function getWorkflowTableBySection(?string $section): string
    {
        return '#__example_items';
    }

    public function getModelName(string $context): string
    {
        return 'Item';
    }
}
```

**Model:**
```php
use Joomla\CMS\MVC\Model\WorkflowModelInterface;
use Joomla\CMS\MVC\Model\WorkflowBehaviorTrait;

class ItemModel extends AdminModel implements WorkflowModelInterface
{
    use WorkflowBehaviorTrait;

    public function __construct($config = [])
    {
        parent::__construct($config);
        $this->setUpWorkflow('com_example.item');
    }
}
```

**Database tables used:** `#__workflows`, `#__workflow_stages`, `#__workflow_transitions`, `#__workflow_associations`.

### Webservices API Plugin

Expose component data via Joomla's REST API by creating a webservices plugin.

**Plugin class** (`plugins/webservices/example/src/Extension/Example.php`):
```php
namespace Vendor\Plugin\WebServices\Example\Extension;

use Joomla\CMS\Event\Application\BeforeApiRouteEvent;
use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\Event\SubscriberInterface;

final class Example extends CMSPlugin implements SubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return ['onBeforeApiRoute' => 'onBeforeApiRoute'];
    }

    public function onBeforeApiRoute(BeforeApiRouteEvent $event): void
    {
        $router = $event->getRouter();

        // Creates GET (list + detail), POST, PATCH, DELETE routes automatically
        $router->createCRUDRoutes(
            'v1/example/items',
            'items',
            ['component' => 'com_example']
        );
    }
}
```

**API Controller** (`api/src/Controller/ItemsController.php`):
```php
namespace Vendor\Component\Example\Api\Controller;

use Joomla\CMS\MVC\Controller\ApiController;

class ItemsController extends ApiController
{
    protected $contentType = 'items';
    protected $default_view = 'items';
}
```

**API View** (`api/src/View/Items/JsonapiView.php`):
```php
namespace Vendor\Component\Example\Api\View\Items;

use Joomla\CMS\MVC\View\JsonApiView as BaseApiView;

class JsonapiView extends BaseApiView
{
    protected $fieldsToRenderItem = ['id', 'title', 'alias', 'description', 'published', 'created'];
    protected $fieldsToRenderList = ['id', 'title', 'alias', 'published'];
}
```

**Manifest addition** — add the `api/` directory to your component manifest:
```xml
<api>
    <files folder="api">
        <folder>src</folder>
    </files>
</api>
```

### Mail Templates

Send templated emails using Joomla's mail template system.

**Register template during install** (in install script or SQL):
```sql
INSERT INTO `#__mail_templates` (`template_id`, `extension`, `language`, `subject`, `body`, `htmlbody`, `attachments`, `params`)
VALUES ('com_example.notification', 'com_example', '', 'COM_EXAMPLE_MAIL_NOTIFICATION_SUBJECT', 'COM_EXAMPLE_MAIL_NOTIFICATION_BODY', '', '', '{"tags":["sitename","title","author","url"]}');
```

**Send mail from a model or controller:**
```php
use Joomla\CMS\Mail\MailTemplate;

$mailer = new MailTemplate('com_example.notification', $app->getLanguage()->getTag());
$mailer->addRecipient($recipientEmail, $recipientName);
$mailer->addTemplateData([
    'sitename' => $app->get('sitename'),
    'title'    => $item->title,
    'author'   => $user->name,
    'url'      => $itemUrl,
]);
$mailer->send();
```

Tags in the template subject/body use `{tagname}` placeholders that are replaced by `addTemplateData()` values. Define the tag names in the `params` JSON when registering.

**DI injection** — models/controllers can implement `MailerFactoryAwareInterface` + use `MailerFactoryAwareTrait` to get the mailer factory injected by MVCFactory.

### Dashboard Views

Create an admin dashboard with module positions for your component.

**Manifest:**
```xml
<dashboards>
    <dashboard title="COM_EXAMPLE_DASHBOARD_TITLE" icon="icon-list">example</dashboard>
</dashboards>
```

**Preset file** (`admin/presets/example.xml`) — defines the sidebar menu and quick-links:
```xml
<?xml version="1.0"?>
<menu xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns="urn:joomla.org"
      xsi:schemaLocation="urn:joomla.org menu.xsd">
    <menuitem title="COM_EXAMPLE" type="heading" icon="list" class="class:list">
        <menuitem title="COM_EXAMPLE_MENU_ITEMS"
                  type="component"
                  element="com_example"
                  link="index.php?option=com_example&amp;view=items"
                  quicktask="index.php?option=com_example&amp;task=item.add"
                  quicktask-title="COM_EXAMPLE_NEW_ITEM" />
        <menuitem title="JCATEGORIES"
                  type="component"
                  element="com_categories"
                  link="index.php?option=com_categories&amp;extension=com_example" />
    </menuitem>
</menu>
```

**Module positions:** Dashboard modules are assigned to position `cpanel-example` (pattern: `cpanel-{dashboard_name}`). Quick icon modules use position `icon-example`.

**Menu link** — reference the dashboard in your submenu:
```xml
<submenu>
    <menu link="option=com_example" view="example">
        <params><dashboard>example</dashboard></params>
        COM_EXAMPLE
    </menu>
</submenu>
```

### Custom Form Validation Rules

Create custom validation rules to validate form fields server-side:

**File:** `admin/src/Rule/PhoneRule.php`
```php
namespace Vendor\Component\Example\Administrator\Rule;

use Joomla\CMS\Form\FormRule;

class PhoneRule extends FormRule
{
    // Simple regex validation — return true if matches
    protected $regex = '/^\+?[\d\s\-\(\)]{7,20}$/';
}
```

**For complex validation**, override `test()`:
```php
class UniqueAliasRule extends FormRule
{
    public function test(\SimpleXMLElement $element, $value, $group = null,
        ?Registry $input = null, ?Form $form = null): bool
    {
        $db    = Factory::getContainer()->get('DatabaseDriver');
        $query = $db->createQuery()
            ->select('COUNT(*)')
            ->from($db->quoteName('#__example_items'))
            ->where($db->quoteName('alias') . ' = :alias')
            ->bind(':alias', $value);

        $id = $input->get('id', 0);
        if ($id) {
            $query->where($db->quoteName('id') . ' != :id')
                ->bind(':id', $id, ParameterType::INTEGER);
        }

        $db->setQuery($query);
        return (int) $db->loadResult() === 0;
    }
}
```

**Form XML:**
```xml
<form addruleprefix="Vendor\Component\Example\Administrator\Rule">
    <field name="phone" type="tel" label="Phone" validate="phone" />
    <field name="alias" type="text" label="Alias" validate="uniquealias" />
</form>
```

## Editor API

Joomla's Editor API provides a unified interface for WYSIWYG editors (TinyMCE, CodeMirror, None/textarea) and editor extension buttons (XTD buttons like "Read More", "Article", "Image").

### JavaScript API: Getting and Setting Editor Content

The modern API uses `JoomlaEditor` (imported from `editor-api`). The legacy `Joomla.editors.instances` is deprecated but still works via a Proxy wrapper.

**Get/set content from JavaScript:**

```javascript
// Modern API (preferred)
import { JoomlaEditor } from 'editor-api';

// Get editor by textarea ID
const editor = JoomlaEditor.get('jform_description');

// Get the currently active (focused) editor
const active = JoomlaEditor.getActive();

// Read content
const html = editor.getValue();

// Replace all content
editor.setValue('<p>New content</p>');

// Get selected text
const selection = editor.getSelection();

// Insert at cursor / replace selection
editor.replaceSelection('<hr id="system-readmore">');

// Disable / enable
editor.disable(false);  // disable
editor.disable(true);   // enable

// Get underlying editor instance (e.g., tinymce object)
const raw = editor.getRawInstance();

// Get editor type name
const type = editor.getType(); // 'tinymce', 'codemirror', 'none'
```

**Legacy API (deprecated but functional):**

```javascript
// Still works but logs deprecation warnings
const editor = Joomla.editors.instances['jform_description'];
editor.getValue();
editor.setValue('content');
editor.replaceSelection('inserted text');
```

### Editor Decorator (Implementing a Custom Editor)

All editors must subclass `JoomlaEditorDecorator` and implement the abstract methods:

```javascript
import JoomlaEditorDecorator from 'editor-decorator';
import { JoomlaEditor } from 'editor-api';

class MyEditorDecorator extends JoomlaEditorDecorator {
    getValue() {
        return this.instance.getContent(); // Your editor's get method
    }

    setValue(value) {
        this.instance.setContent(value);
        return this;
    }

    getSelection() {
        return this.instance.getSelectedText();
    }

    replaceSelection(value) {
        this.instance.insertAtCursor(value);
        return this;
    }

    disable(enable) {
        this.instance.setReadOnly(!enable);
        return this;
    }
}

// Register with Joomla
const decorator = new MyEditorDecorator(editorInstance, 'myeditor', textareaId);
JoomlaEditor.register(decorator);
```

**Required methods:** `getValue()`, `setValue()`, `getSelection()`, `replaceSelection()`, `disable()`

### Editor XTD Buttons (Extension Buttons)

XTD buttons appear below the editor (e.g., "Read More", "Article", "Image"). They are plugins in the `editors-xtd` group.

**Creating an XTD button plugin:**

```php
// plugins/editors-xtd/mybutton/src/Extension/MyButton.php
namespace Vendor\Plugin\EditorsXtd\MyButton\Extension;

use Joomla\CMS\Editor\Button\Button;
use Joomla\CMS\Event\Editor\EditorButtonsSetupEvent;
use Joomla\CMS\Language\Text;
use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\Event\SubscriberInterface;

final class MyButton extends CMSPlugin implements SubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return ['onEditorButtonsSetup' => 'onEditorButtonsSetup'];
    }

    public function onEditorButtonsSetup(EditorButtonsSetupEvent $event): void
    {
        $disabled = $event->getDisabledButtons();
        if (\in_array($this->_name, $disabled)) {
            return;
        }

        $wa = $this->getApplication()->getDocument()->getWebAssetManager();
        $wa->registerScript(
            'editor-button.' . $this->_name,
            'plg_editors-xtd_mybutton/button.min.js',
            [],
            ['type' => 'module'],
            ['editors']  // dependency on editor API
        );

        $button = new Button($this->_name, [
            'action'  => 'insert-mywidget',   // Custom action name
            'text'    => Text::_('PLG_MYBUTTON_BUTTON_TEXT'),
            'icon'    => 'star',
            'name'    => $this->_type . '_' . $this->_name,
        ]);

        $event->getButtonsRegistry()->add($button);
    }
}
```

**JavaScript handler for the button action:**

```javascript
// build/media_source/plg_editors-xtd_mybutton/js/button.es6.js
import { JoomlaEditorButton } from 'editor-api';

JoomlaEditorButton.registerAction('insert-mywidget', (editor, options) => {
    editor.replaceSelection('<div class="my-widget">Widget content</div>');
});
```

### Button Action Types

| Action | Behavior | Use Case |
|--------|----------|----------|
| `insert` | Inserts `options.content` at cursor | Simple static content insertion |
| `modal` | Opens `JoomlaDialog` iframe, listens for `postMessage` | Content selection (articles, images, contacts) |
| Custom name | Your registered handler | Any custom logic |

### Modal Button Pattern (Content Selection)

For buttons that open a modal to select content (like the "Article" button):

**PHP — define button with `action: 'modal'`:**

```php
$link = 'index.php?option=com_example&view=items&layout=modal&tmpl=component&'
    . Session::getFormToken() . '=1&editor=' . $event->getEditorId();

$button = new Button($this->_name, [
    'action' => 'modal',
    'link'   => $link,
    'text'   => Text::_('PLG_MYBUTTON_SELECT_ITEM'),
    'icon'   => 'list',
    'name'   => $this->_type . '_' . $this->_name,
], [
    'popupType'  => 'iframe',
    'textHeader' => Text::_('PLG_MYBUTTON_MODAL_TITLE'),
    'modalWidth' => '800px',
    'modalHeight' => '400px',
]);
```

**JavaScript in the modal iframe** — send selection back via `postMessage`:

```javascript
// In the modal's layout template
document.querySelectorAll('.select-link').forEach((el) => {
    el.addEventListener('click', (event) => {
        event.preventDefault();
        const title = event.target.dataset.title;
        const url = event.target.dataset.uri;

        window.parent.postMessage({
            messageType: 'joomla:content-select',
            html: `<a href="${url}">${title}</a>`,
        });
    });
});
```

The parent window's `modal` action handler automatically calls `editor.replaceSelection()` with the received `html` (or `text`) and closes the dialog.

### Editor Form Field (PHP)

The `editor` form field type in XML automatically renders the configured WYSIWYG editor:

```xml
<field
    name="description"
    type="editor"
    label="JGLOBAL_DESCRIPTION"
    filter="JComponentHelper::filterText"
    buttons="true"
    height="400"
    width="100%"
/>
```

**Attributes:**

| Attribute | Values | Purpose |
|-----------|--------|---------|
| `buttons` | `true`, `false`, or comma-separated list | Show/hide XTD buttons. List = show only named buttons |
| `hide` | Comma-separated list | Hide specific XTD buttons |
| `height` | Pixels (e.g., `500`) | Editor height |
| `width` | CSS value (e.g., `100%`) | Editor width |
| `editor` | Pipe-separated list | Force specific editor(s): `tinymce\|codemirror\|none` |
| `filter` | `JComponentHelper::filterText` | Server-side HTML filtering |
| `asset_field` | Field name | Form field containing asset ID (for ACL) |
| `created_by_field` | Field name | Form field containing author ID |
| `syntax` | `html`, `css`, `php`, etc. | Syntax highlighting mode (CodeMirror) |

### Editor Plugin Registration (PHP)

Editor plugins register via the `onEditorSetup` event:

```php
// plugins/editors/myeditor/src/Extension/MyEditor.php
use Joomla\CMS\Event\Editor\EditorSetupEvent;

final class MyEditor extends CMSPlugin implements SubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return ['onEditorSetup' => 'onEditorSetup'];
    }

    public function onEditorSetup(EditorSetupEvent $event): void
    {
        $event->getEditorsRegistry()->add(
            new MyEditorProvider($this->params, $this->getApplication(), $this->getDispatcher())
        );
    }
}
```

The provider extends `AbstractEditorProvider` and implements `display()` (renders the editor HTML) and `getName()` (returns the editor identifier like `'tinymce'`).

## Layouts (LayoutHelper)

Joomla's layout system provides reusable, overridable PHP template fragments. Layouts are used for rendering form fields, toolbars, list items, and any shared HTML across views.

### Rendering a Layout

```php
use Joomla\CMS\Layout\LayoutHelper;

// Render a built-in Joomla layout
echo LayoutHelper::render('joomla.searchtools.default', ['view' => $this]);

// Render with custom data
echo LayoutHelper::render('joomla.content.info_block', ['item' => $item, 'params' => $params]);

// Render from a component's own layouts/ directory
echo LayoutHelper::render('mycomponent.item.badge', ['status' => $item->published], JPATH_SITE . '/components/com_example/layouts');
```

The first argument is a dot-separated layout ID that maps to a file path: `joomla.form.field.text` → `layouts/joomla/form/field/text.php`.

### Creating Custom Layouts

**File:** `site/layouts/mycomponent/item/card.php`

```php
<?php
// layouts/mycomponent/item/card.php
defined('_JEXEC') or die;

extract($displayData);
// $item, $params are now available as variables
?>
<div class="card">
    <div class="card-body">
        <h5 class="card-title"><?php echo $this->escape($item->title); ?></h5>
        <p class="card-text"><?php echo $item->description; ?></p>
    </div>
</div>
```

**Usage in a template:**
```php
echo LayoutHelper::render('mycomponent.item.card', ['item' => $item, 'params' => $params],
    JPATH_SITE . '/components/com_example/layouts');
```

### Layout Override Priority (highest to lowest)

| Priority | Path | Purpose |
|----------|------|---------|
| 1 | `templates/{template}/html/layouts/{component}/` | Template override (component-specific) |
| 2 | `templates/{parent}/html/layouts/{component}/` | Parent template override |
| 3 | `components/{component}/layouts/` | Component's own layouts |
| 4 | `templates/{template}/html/layouts/` | Template override (global) |
| 5 | `layouts/` | Joomla core layouts |

Users can override any layout by copying it to `templates/{template}/html/layouts/` and modifying it there.

### Sublayouts

Render a child layout relative to the current layout:

```php
// Inside layouts/joomla/editors/buttons.php
<?php foreach ($buttons as $button) : ?>
    <?php echo $this->sublayout('button', $button); ?>
<?php endforeach; ?>
```

`$this->sublayout('button', $button)` looks for `layouts/joomla/editors/buttons/button.php` — a file named `button.php` inside a directory matching the parent layout name.

### Key Built-in Layouts

| Layout ID | Purpose |
|-----------|---------|
| `joomla.searchtools.default` | Search/filter toolbar for list views |
| `joomla.edit.title_alias` | Title + alias fields in edit views |
| `joomla.edit.global` | Published, access, language sidebar |
| `joomla.html.batch.access` | Batch access level selector |
| `joomla.html.batch.language` | Batch language selector |
| `joomla.html.batch.tag` | Batch tag selector |
| `joomla.html.batch.item` | Batch category move/copy |
| `joomla.content.info_block` | Article info (author, date, hits) |
| `joomla.form.renderfield` | Field wrapper (label + input + description) |
| `joomla.form.renderlabel` | Field label element |
| `joomla.form.field.text` | Text input field |
| `joomla.form.field.subform.repeatable` | Repeatable subform rows |
| `joomla.pagination.default` | Pagination controls |

## Form Fields

### Built-in Field Types Reference

Joomla provides ~90 built-in field types. The most commonly used:

**Basic inputs:**

| Type | XML | Notes |
|------|-----|-------|
| `text` | `type="text"` | Single-line text |
| `textarea` | `type="textarea"` | Multi-line, set `rows` and `cols` |
| `email` | `type="email"` | Email validation |
| `url` | `type="url"` | URL validation |
| `tel` | `type="tel"` | Phone number |
| `number` | `type="number"` | Numeric with `min`, `max`, `step` |
| `password` | `type="password"` | Masked input |
| `hidden` | `type="hidden"` | Hidden value |
| `editor` | `type="editor"` | WYSIWYG editor (see Editor API section) |
| `color` | `type="color"` | Color picker |
| `calendar` | `type="calendar"` | Date picker with format, `showtime="true"` for datetime |

**Selection fields:**

| Type | XML | Notes |
|------|-----|-------|
| `list` | `type="list"` | Dropdown with `<option>` children |
| `groupedlist` | `type="groupedlist"` | Dropdown with `<group>` → `<option>` hierarchy |
| `radio` | `type="radio"` | Radio buttons, use `class="btn-group"` for toggle style |
| `checkboxes` | `type="checkboxes"` | Multiple checkboxes |
| `checkbox` | `type="checkbox"` | Single checkbox |
| `category` | `type="category"` | Category selector, needs `extension="com_example"` |
| `tag` | `type="tag"` | Tag picker, supports `mode="ajax"` and `multiple="true"` |
| `user` | `type="user"` | User selector |
| `accesslevel` | `type="accesslevel"` | Access level dropdown |
| `contentlanguage` | `type="contentlanguage"` | Language selector |
| `sql` | `type="sql"` | Options from SQL query |
| `status` | `type="status"` | Published/unpublished/trashed/archived |

**File/media fields:**

| Type | XML | Notes |
|------|-----|-------|
| `media` | `type="media"` | Media picker modal, `types="images"` or `"images,videos"` |
| `file` | `type="file"` | File upload input |
| `filelist` | `type="filelist"` | Lists files in a directory |
| `folderlist` | `type="folderlist"` | Lists folders |

**Special fields:**

| Type | XML | Notes |
|------|-----|-------|
| `subform` | `type="subform"` | Repeatable nested form groups |
| `rules` | `type="rules"` | Permissions matrix |
| `ordering` | `type="ordering"` | Ordering position |
| `spacer` | `type="spacer"` | Visual separator, `hr="true"` for line |
| `note` | `type="note"` | Display-only message |
| `componentlayout` | `type="componentlayout"` | Layout selector for a view |

### SubformField (Repeatable Groups)

Creates repeatable sets of fields — useful for things like social media links, phone numbers, or any list of structured items.

**Form XML:**
```xml
<field name="social_links"
       type="subform"
       label="Social Media Links"
       layout="joomla.form.field.subform.repeatable"
       multiple="true"
       min="0"
       max="10"
       buttons="add,remove,move"
       formsource="social_link.xml"
/>
```

**Subform definition** (`admin/forms/social_link.xml`):
```xml
<?xml version="1.0" encoding="utf-8"?>
<form>
    <field name="platform" type="list" label="Platform" default="facebook">
        <option value="facebook">Facebook</option>
        <option value="twitter">X (Twitter)</option>
        <option value="instagram">Instagram</option>
        <option value="youtube">YouTube</option>
    </field>
    <field name="url" type="url" label="URL" />
</form>
```

**Or define inline** (no separate XML file):
```xml
<field name="phones" type="subform" label="Phone Numbers"
       layout="joomla.form.field.subform.repeatable" multiple="true">
    <form>
        <field name="type" type="list" label="Type" default="mobile">
            <option value="mobile">Mobile</option>
            <option value="work">Work</option>
            <option value="home">Home</option>
        </field>
        <field name="number" type="tel" label="Number" />
    </form>
</field>
```

**Available subform layouts:**
- `joomla.form.field.subform.default` — single group (not repeatable)
- `joomla.form.field.subform.repeatable` — vertical repeatable rows with add/remove/move buttons
- `joomla.form.field.subform.repeatable-table` — table layout for repeatable rows

**Reading subform data in PHP:**
```php
$socialLinks = json_decode($item->social_links, true) ?? [];
foreach ($socialLinks as $link) {
    echo $link['platform'] . ': ' . $link['url'];
}
```

### MediaField

The media picker opens Joomla's Media Manager modal for selecting images, videos, and documents.

```xml
<field name="image"
       type="media"
       label="COM_EXAMPLE_FIELD_IMAGE"
       types="images"
       preview="true"
       previewWidth="200"
       previewHeight="200"
       directory="example"
/>
```

**Attributes:**
- `types` — comma-separated: `images`, `audios`, `videos`, `documents`
- `preview` — show thumbnail preview (`true`/`false`)
- `previewWidth` / `previewHeight` — preview dimensions in pixels
- `directory` — restrict to a subdirectory of the media root

### Creating Custom Form Fields

Custom fields extend a base field class and live in `admin/src/Field/`:

**Simple list field (database-backed options):**
```php
namespace Vendor\Component\Example\Administrator\Field;

use Joomla\CMS\Form\Field\ListField;
use Joomla\CMS\HTML\HTMLHelper;
use Joomla\Database\DatabaseAwareTrait;

class TeacherlistField extends ListField
{
    use DatabaseAwareTrait;

    protected $type = 'Teacherlist';

    protected function getOptions(): array
    {
        $db    = $this->getDatabase();
        $query = $db->createQuery()
            ->select($db->quoteName(['id', 'name']))
            ->from($db->quoteName('#__example_teachers'))
            ->where($db->quoteName('published') . ' = 1')
            ->order($db->quoteName('name'));

        $db->setQuery($query);
        $items = $db->loadObjectList();

        $options = [];
        foreach ($items as $item) {
            $options[] = HTMLHelper::_('select.option', $item->id, $item->name);
        }

        return array_merge(parent::getOptions(), $options);
    }
}
```

**Fully custom field (own rendering):**
```php
namespace Vendor\Component\Example\Administrator\Field;

use Joomla\CMS\Form\FormField;

class StarratingField extends FormField
{
    protected $type = 'Starrating';

    // Option 1: Layout-based rendering (preferred, allows template overrides)
    protected $layout = 'mycomponent.field.starrating';

    // Option 2: Override getInput() for inline HTML
    protected function getInput(): string
    {
        $html = '<div class="star-rating">';
        for ($i = 1; $i <= 5; $i++) {
            $checked = ($i <= (int) $this->value) ? ' checked' : '';
            $html .= '<input type="radio" name="' . $this->name . '" value="' . $i . '"' . $checked . '>';
        }
        $html .= '</div>';

        return $html;
    }
}
```

**Reference in form XML:**
```xml
<form addfieldprefix="Vendor\Component\Example\Administrator\Field">
    <field name="teacher_id" type="teacherlist" label="Teacher" />
    <field name="rating" type="starrating" label="Rating" />
</form>
```

**Key base classes to extend:**
- `ListField` — dropdown with dynamic options (`getOptions()`)
- `GroupedlistField` — grouped dropdown (`getGroups()`)
- `FormField` — fully custom rendering (`getInput()`)
- `TextField` — text input with extra logic
- `PredefinedlistField` — list with hardcoded options (`$predefinedOptions`)

### Field Layout Rendering

Modern fields use layouts for rendering, making them template-overridable:

```php
class MyField extends FormField
{
    // Layout file: layouts/joomla/form/field/myfield.php
    protected $layout = 'joomla.form.field.myfield';

    // collectLayoutData() is called automatically — override getLayoutData() to add custom data
    protected function getLayoutData(): array
    {
        $data = parent::getLayoutData();
        $data['customProp'] = $this->element['customprop'] ?? 'default';
        return $data;
    }
}
```

The layout file receives `$displayData` with all field metadata (`id`, `name`, `value`, `label`, `class`, `disabled`, `required`, `hint`, `description`, `field` object, etc.).

## Menu Item Types (Site Views)

Menu item types define what appears in the Joomla Menu Manager when administrators create menu items. Each site view can have one or more menu item types.

### How Menu Item Types Are Discovered

Joomla scans `components/{component}/tmpl/{view}/` for XML files. Each `.xml` file becomes a selectable menu item type. The file name matches the layout name (e.g., `default.xml` → default layout, `blog.xml` → blog layout).

### Menu Item XML Structure

**File:** `site/tmpl/items/default.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<metadata>
    <layout title="COM_EXAMPLE_VIEW_ITEMS_TITLE"
            option="COM_EXAMPLE_VIEW_ITEMS_OPTION">
        <help key="Menu_Item:_Example_Items" />
        <message><![CDATA[COM_EXAMPLE_VIEW_ITEMS_DESC]]></message>
    </layout>

    <!-- Request fields — map to URL query parameters (required settings) -->
    <fields name="request">
        <fieldset name="request"
                  addfieldprefix="Vendor\Component\Example\Administrator\Field">
            <field name="id"
                   type="category"
                   extension="com_example"
                   label="COM_EXAMPLE_FIELD_SELECT_CATEGORY"
                   required="true" />
        </fieldset>
    </fields>

    <!-- Menu item parameters — optional display settings -->
    <fields name="params">
        <fieldset name="basic" label="JGLOBAL_FIELDSET_DISPLAY_OPTIONS">
            <field name="show_title"
                   type="list"
                   label="JGLOBAL_SHOW_TITLE_LABEL"
                   useglobal="true"
                   class="form-select-color-state"
                   validate="options">
                <option value="1">JSHOW</option>
                <option value="0">JHIDE</option>
            </field>

            <field name="items_per_page"
                   type="number"
                   label="COM_EXAMPLE_ITEMS_PER_PAGE"
                   useglobal="true"
                   min="1"
                   max="100" />

            <field name="orderby"
                   type="list"
                   label="JGLOBAL_ORDERING"
                   useglobal="true">
                <option value="a.title">JGLOBAL_TITLE</option>
                <option value="a.created">JDATE</option>
                <option value="a.ordering">JORDERING</option>
            </field>
        </fieldset>
    </fields>
</metadata>
```

### Single-Item Menu Item Type

**File:** `site/tmpl/item/default.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<metadata>
    <layout title="COM_EXAMPLE_VIEW_ITEM_TITLE">
        <message><![CDATA[COM_EXAMPLE_VIEW_ITEM_DESC]]></message>
    </layout>

    <fields name="request">
        <fieldset name="request"
                  addfieldprefix="Vendor\Component\Example\Administrator\Field">
            <field name="id"
                   type="modal_example"
                   label="COM_EXAMPLE_FIELD_SELECT_ITEM"
                   required="true"
                   select="true"
                   new="true"
                   edit="true"
                   clear="true" />
        </fieldset>
    </fields>

    <fields name="params">
        <fieldset name="basic" label="JGLOBAL_FIELDSET_DISPLAY_OPTIONS">
            <field name="show_author"
                   type="list"
                   label="COM_EXAMPLE_SHOW_AUTHOR"
                   useglobal="true">
                <option value="1">JSHOW</option>
                <option value="0">JHIDE</option>
            </field>
        </fieldset>
    </fields>
</metadata>
```

### Key Elements

**`<layout>`** — defines the menu item type name and description:
- `title` — language constant shown in Menu Manager type selector
- `option` — secondary description (optional)
- `<message>` — longer description displayed when creating the menu item

**`<fields name="request">`** — URL parameters that identify what content to display:
- These become the `&id=X` or `&catid=Y` in the URL
- Shown in the "Required Settings" section of the menu item editor
- Common: `type="category"` for list views, `type="modal_article"` / custom modal for single items

**`<fields name="params">`** — display options that customize rendering:
- Organized into fieldsets that appear as tabs
- `useglobal="true"` adds a "Use Global" option that falls back to `config.xml` component settings
- Accessed in site code via `$app->getParams()->get('show_title', 1)`

**`useglobal="true"`** — critical attribute. When set, the field gets an extra "Use Global" option that inherits from the component's `config.xml` settings. This is how Joomla's cascading parameter system works: Global config → Menu item params → merged result.

### Multiple Layouts Per View

A view can offer multiple layout variants. Each gets its own XML file:

```
site/tmpl/items/
├── default.php       ← Default list layout
├── default.xml       ← Menu item type: "Items - Default"
├── blog.php          ← Blog-style layout
├── blog.xml          ← Menu item type: "Items - Blog"
└── compact.php       ← Compact layout (no menu item type — not linkable from menus)
```

Only layouts with a matching `.xml` file appear in the Menu Manager. Layouts without XML can still be used via `&layout=compact` in URLs but aren't selectable as menu item types.

## Libraries and Composer

### composer.json for Extensions

Joomla extensions that need third-party PHP libraries use Composer. The `composer.json` goes at the extension's project root (not inside `admin/` or `site/`).

```json
{
    "name": "vendor/com_mycomponent",
    "description": "My Joomla Component",
    "type": "joomla-component",
    "license": "GPL-2.0-or-later",
    "minimum-stability": "stable",
    "require": {
        "php": ">=8.2",
        "joomla/framework": "^3.0"
    },
    "require-dev": {
        "phpunit/phpunit": "^10.0",
        "squizlabs/php_codesniffer": "^3.7"
    },
    "autoload": {
        "psr-4": {
            "Vendor\\Component\\MyComponent\\Administrator\\": "admin/src/",
            "Vendor\\Component\\MyComponent\\Site\\": "site/src/"
        }
    },
    "config": {
        "vendor-dir": "libraries/vendor"
    }
}
```

Key points:

- `type: "joomla-component"` (or `joomla-plugin`, `joomla-module`) enables Joomla-aware Composer installers.
- `vendor-dir` — Many Joomla projects put vendor in `libraries/vendor/` rather than the default `vendor/`. This keeps Composer's autoloader inside the extension's library path so it gets included in the installable package. Check the project's existing convention.
- The PSR-4 autoload block in `composer.json` is for **development tooling** (PHPUnit, static analysis). At runtime, Joomla handles autoloading via the namespace declared in the manifest XML — Composer's autoloader is not loaded by Joomla itself unless you explicitly require it.

### Including Libraries in the Extension

If your extension ships third-party libraries, include them in the package and load the autoloader:

```php
// In services/provider.php or your Extension class boot() method
$vendorPath = JPATH_ADMINISTRATOR . '/components/com_mycomponent/libraries/vendor/autoload.php';
if (file_exists($vendorPath)) {
    require_once $vendorPath;
}
```

Add the `libraries/` folder to your manifest XML so it gets installed:

```xml
<administration>
    <files folder="admin">
        <folder>libraries</folder>
        <folder>services</folder>
        <folder>src</folder>
        <!-- ... -->
    </files>
</administration>
```

### Common Libraries Used in Joomla Extensions

- **Joomla Framework packages** (`joomla/database`, `joomla/event`, `joomla/input`) — Already provided by Joomla core. Do NOT bundle these; just use them.
- **League packages** (CSV, OAuth2, Flysystem) — Popular for data import/export and auth.
- **Symfony components** (Filesystem, HttpClient, Mailer) — Some already in Joomla core; check before bundling duplicates.
- **GuzzleHttp** — For API integrations. Joomla core includes `joomla/http` but Guzzle is common in extensions needing advanced HTTP features.

### npm and Front-End Assets

Extensions with custom JavaScript or CSS often use npm for build tooling:

```json
{
    "name": "com_mycomponent",
    "scripts": {
        "build:css": "sass build/scss/:media/css/",
        "build:js": "rollup -c",
        "build": "npm run build:css && npm run build:js",
        "watch": "npm run build:css -- --watch & npm run build:js -- --watch"
    },
    "devDependencies": {
        "sass": "^1.60",
        "rollup": "^4.0"
    }
}
```

Compiled assets go into `media/com_mycomponent/` and are registered in `joomla.asset.json`. Source files typically live in a `build/` directory and are NOT included in the installable package.

## Extension Packaging (Building the Installable ZIP)

Joomla extensions are distributed as ZIP files that users install through the Joomla admin installer (`System → Install → Extensions`).

### Manual Packaging

The simplest approach — zip the extension files according to the manifest structure:

```bash
# For a component
cd /path/to/com_mycomponent
zip -r ../com_mycomponent-1.0.0.zip \
    mycomponent.xml \
    admin/ \
    site/ \
    media/ \
    --exclude "*/node_modules/*" \
    --exclude "*/.git/*" \
    --exclude "*/build/*" \
    --exclude "*/__pycache__/*" \
    --exclude "*.DS_Store"
```

For a plugin:
```bash
cd /path/to/plg_content_myplugin
zip -r ../plg_content_myplugin-1.0.0.zip \
    myplugin.xml \
    services/ \
    src/ \
    language/
```

### Build Script Pattern

Most production extensions use a build script. A typical `build.sh`:

```bash
#!/bin/bash
VERSION=$(grep '<version>' mycomponent.xml | sed 's/.*<version>\(.*\)<\/version>.*/\1/')
PACKAGE="com_mycomponent-${VERSION}.zip"

# Build front-end assets if needed
if [ -f package.json ]; then
    npm ci && npm run build
fi

# Install PHP dependencies (production only)
if [ -f composer.json ]; then
    composer install --no-dev --optimize-autoloader
fi

# Create the ZIP
rm -f "${PACKAGE}"
zip -r "${PACKAGE}" \
    mycomponent.xml \
    admin/ \
    site/ \
    media/ \
    --exclude "*/node_modules/*" \
    --exclude "*/build/*" \
    --exclude "*/.git/*" \
    --exclude "*.map"

echo "Built: ${PACKAGE}"
```

### Package Extensions (Multiple Extensions in One)

For projects that ship a component with associated plugins and modules, use a package manifest:

```xml
<?xml version="1.0" encoding="utf-8"?>
<extension type="package" method="upgrade">
    <name>pkg_mypackage</name>
    <packagename>mypackage</packagename>
    <version>1.0.0</version>
    <description>PKG_MYPACKAGE_XML_DESCRIPTION</description>
    <files>
        <file type="component" id="com_mycomponent">com_mycomponent.zip</file>
        <file type="plugin" id="plg_content_mycomponent" group="content">plg_content_mycomponent.zip</file>
        <file type="plugin" id="plg_finder_mycomponent" group="finder">plg_finder_mycomponent.zip</file>
        <file type="module" id="mod_mycomponent" client="site">mod_mycomponent.zip</file>
    </files>
</extension>
```

Build each extension as its own ZIP first, then package them together:

```bash
# Build individual ZIPs
cd components/com_mycomponent && zip -r ../../dist/com_mycomponent.zip . && cd ../..
cd plugins/content/mycomponent && zip -r ../../../dist/plg_content_mycomponent.zip . && cd ../../..
cd modules/site/mod_mycomponent && zip -r ../../../dist/mod_mycomponent.zip . && cd ../../..

# Build the package ZIP
cd dist
zip pkg_mypackage-1.0.0.zip \
    pkg_mypackage.xml \
    com_mycomponent.zip \
    plg_content_mycomponent.zip \
    mod_mycomponent.zip
```

### What Goes in the ZIP (and What Doesn't)

**Include:**
- Manifest XML (required, at ZIP root)
- `admin/`, `site/`, `media/` directories
- `services/provider.php`
- `src/` with all PHP classes
- `forms/`, `tmpl/`, `sql/`, `language/`
- `libraries/vendor/` if shipping third-party PHP libs (with autoload)
- Compiled CSS/JS in `media/`

**Exclude:**
- `node_modules/`, `build/`, `.git/`, `.github/`
- `tests/`, `phpunit.xml`, `.phpcs.xml`
- `composer.json`, `composer.lock` (dev tooling, not needed at runtime)
- `package.json`, `package-lock.json`
- Source SCSS/TypeScript files
- `.env`, credentials, IDE config (`.idea/`, `.vscode/`)
- `*.map` source map files (unless debugging is needed)

## Real-World Reference: Production Components

When working on a Joomla project, check whether the project has its own `CLAUDE.md` or `CONTRIBUTING.md` at the repo root — these often define project-specific naming conventions, build commands, and coding standards that should take precedence over this skill's generic patterns.

Common patterns seen in production Joomla 5+ components:

- **Entity prefixes** — Some projects prefix entity names to avoid collisions (e.g., `Cwm` prefix in CWM components, `Eb` in EventBooking). Follow the project's existing convention.
- **Plugin groups** — Real components typically ship with several plugin types: content, finder (Smart Search), schemaorg (structured data), system, task (scheduled jobs), and webservices (REST API).
- **Module variants** — Both admin-side and site-side modules in `modules/admin/` and `modules/site/`.
- **Build tooling** — Composer for PHP dependencies + npm for JS/CSS asset compilation. Look for `composer.json` and `package.json` at the project root.
- **Testing** — PHPUnit for PHP (unit + integration tests in `tests/`), Jest for JavaScript. See the **Testing** section below for patterns.
- **Non-standard vendor paths** — Some projects place Composer's `vendor/` directory in a custom location (e.g., `libraries/vendor/`). Check `composer.json` for the `vendor-dir` config.
- **Media asset pipeline** — Source JS/CSS in a build directory (e.g., `build/media_source/`) compiled to `media/` via npm scripts. The `media/` directory may be gitignored.

## Testing

### Directory Structure

```
tests/
├── Unit/
│   ├── bootstrap.php          # Loads real Joomla CMS classes
│   ├── Admin/
│   │   ├── Helper/            # Admin helper tests
│   │   ├── Model/             # Admin model tests
│   │   └── Table/             # Table class tests
│   └── Site/
│       ├── Helper/            # Site helper tests
│       └── Model/             # Site model tests
├── Integration/
│   └── ...                    # Tests that require a database
└── js/
    └── *.test.js              # Jest tests for JavaScript
```

Mirror the `admin/src/` and `site/src/` structure inside `tests/Unit/` so test locations are predictable.

### PHPUnit Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="tests/Unit/bootstrap.php"
         colors="true"
         cacheDirectory="build/.phpunit.cache">
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Integration">
            <directory>tests/Integration</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory suffix=".php">admin/src</directory>
            <directory suffix=".php">site/src</directory>
        </include>
    </source>
</phpunit>
```

Define granular test suites (e.g., "Admin Helper Tests", "Site Model Tests") when you have enough tests to benefit from selective runs.

### Bootstrap: Load Real Joomla CMS

The key insight from Joomla core's own test infrastructure: **load the real CMS classes, don't stub them.** This validates your code against actual Joomla signatures, catching J5→J6 breaking changes automatically.

```php
<?php
// tests/Unit/bootstrap.php

// Point to a Joomla installation (configure via build.properties or env var)
$joomlaPath = getenv('JOOMLA_PATH') ?: '/path/to/joomla';

if (!is_dir($joomlaPath . '/libraries')) {
    throw new RuntimeException(
        'Joomla installation not found. Set JOOMLA_PATH environment variable.'
    );
}

// Define Joomla constants
define('JPATH_ROOT', $joomlaPath);
define('JPATH_BASE', JPATH_ROOT);
define('JPATH_SITE', JPATH_ROOT);
define('JPATH_ADMINISTRATOR', JPATH_ROOT . '/administrator');
define('JPATH_LIBRARIES', JPATH_ROOT . '/libraries');

// Load the REAL Joomla autoloader
require_once JPATH_LIBRARIES . '/loader.php';
require_once JPATH_LIBRARIES . '/vendor/autoload.php';

// Register the component's own autoloader
require_once dirname(__DIR__, 2) . '/vendor/autoload.php';
```

**Why real CMS, not stubs?** Stubs drift from the actual API. When Joomla 6 removes a method or changes a return type, tests using real classes catch it immediately. Stubs silently pass.

### Base Test Case with Query Stub

Joomla core's `UnitTestCase` provides a `getQueryStub()` helper — a minimal concrete `DatabaseQuery` that only needs 2 abstract methods. This is far simpler than stubbing the entire `DatabaseInterface`:

```php
<?php

namespace Vendor\Component\MyComponent\Tests;

use Joomla\Database\DatabaseInterface;
use Joomla\Database\DatabaseQuery;
use Joomla\Database\QueryInterface;
use PHPUnit\Framework\TestCase;

abstract class MyComponentTestCase extends TestCase
{
    /**
     * Create a real DatabaseQuery with only 2 abstract methods stubbed.
     * Gives you a working query builder with proper __toString().
     */
    protected function getQueryStub(DatabaseInterface $db): QueryInterface
    {
        return new class ($db) extends DatabaseQuery {
            public function groupConcat($expression, $separator = ','): string
            {
                return '';
            }

            public function processLimit($query, $limit, $offset = 0): string
            {
                return (string) $query;
            }
        };
    }
}
```

### Model Test Pattern

Use `createStub(DatabaseDriver::class)` for the database (see gotcha below about `DatabaseInterface` vs `DatabaseDriver`), wire up `getQueryStub()` for the query builder, and pass the stub via the model's config array:

```php
<?php

use Joomla\Database\DatabaseDriver;
use Joomla\CMS\MVC\Factory\MVCFactoryInterface;

class MyModelTest extends MyComponentTestCase
{
    public function testGetListQueryFilters(): void
    {
        $db = $this->createStub(DatabaseDriver::class);
        $db->method('createQuery')->willReturn($this->getQueryStub($db));
        $db->method('getPrefix')->willReturn('jos_');

        $model = new MyItemModel(
            ['dbo' => $db],
            $this->createStub(MVCFactoryInterface::class)
        );

        // Test the model behavior
        $this->assertInstanceOf(MyItemModel::class, $model);
    }
}
```

**Key points:**
- Models accept `['dbo' => $db]` in their config array — no need to mock the full DI container
- `getQueryStub()` gives you a real query builder, so `$query->select()`, `$query->where()`, and `$query->__toString()` all work correctly
- Stub additional methods as needed: `loadObject()`, `loadObjectList()`, `execute()`, `quoteName()`, etc.
- **Always stub `DatabaseDriver`**, not `DatabaseInterface`, when your code calls `createQuery()` (see Testing Gotchas below)

### Table Test Pattern

```php
$db = $this->createStub(DatabaseDriver::class);
$db->method('createQuery')->willReturn($this->getQueryStub($db));
$db->method('getPrefix')->willReturn('jos_');

$dispatcher = $this->createStub(DispatcherInterface::class);
$table = new MyTable($db, $dispatcher);

// Test check() validation
$table->title = '';
$this->expectException(\UnexpectedValueException::class);
$table->check();
```

### Helper / Utility Test Pattern

Pure functions and helpers are the simplest to test — no database stubs needed:

```php
class MyHelperTest extends MyComponentTestCase
{
    public function testFormatDuration(): void
    {
        $this->assertSame('1:30:00', MyHelper::formatDuration(5400));
        $this->assertSame('0:05:30', MyHelper::formatDuration(330));
    }
}
```

### JavaScript Tests (Jest)

Use Jest with jsdom for testing frontend JavaScript. Configure in `package.json`:

```json
{
  "jest": {
    "testEnvironment": "jsdom",
    "testMatch": ["<rootDir>/tests/js/**/*.test.js"],
    "coverageDirectory": "build/reports/coverage-js"
  }
}
```

For code that depends on `Joomla.Text._()` or other Joomla globals, mock them in a setup file or per-test:

```javascript
// Mock Joomla globals
beforeEach(() => {
    window.Joomla = {
        Text: {
            _: jest.fn((key) => key),
            strings: {}
        },
        getOptions: jest.fn(() => ({})),
        renderMessages: jest.fn()
    };
});
```

### What to Test (and What Not To)

**Do test:**
- Helper/utility methods (pure logic, formatting, calculations)
- Model query construction and filtering logic
- Table `check()` validation rules
- Custom form field logic
- JavaScript UI helpers and data transformations

**Don't test:**
- Joomla framework internals (MVC routing, form binding, ACL checks)
- Simple getters/setters with no logic
- Template HTML output (use E2E tests for that)

### Testing Gotchas

**`DatabaseInterface` does NOT have `createQuery()`** — `createQuery()` lives on the abstract `DatabaseDriver` class, not on `DatabaseInterface`. When stubbing the database for tests that call `createQuery()`, you **must** use `createStub(DatabaseDriver::class)`, not `createStub(DatabaseInterface::class)`. PHPUnit will throw `MethodCannotBeConfiguredException` if you try to configure `createQuery()` on a `DatabaseInterface` stub.

```php
// WRONG — createQuery() is not on DatabaseInterface
$db = $this->createStub(DatabaseInterface::class);
$db->method('createQuery')->willReturn(...); // Throws!

// CORRECT — DatabaseDriver has createQuery()
$db = $this->createStub(DatabaseDriver::class);
$db->method('createQuery')->willReturn($this->getQueryStub($db)); // Works
```

**`CMSApplicationInterface` does NOT have `getSession()`** — `getSession()` is defined on `SessionAwareWebApplicationInterface` (from the framework) and mixed in via `SessionAwareWebApplicationTrait`. To stub an application with `getSession()`, use the concrete `CMSApplication` class:

```php
// WRONG — getSession() is not on CMSApplicationInterface
$app = $this->createStub(CMSApplicationInterface::class);
$app->method('getSession')->willReturn($session); // Throws!

// CORRECT — CMSApplication inherits getSession() via trait
$app = $this->createStub(CMSApplication::class);
$app->method('getSession')->willReturn($session); // Works
```

**Bootstrap must load Joomla's vendor autoloader** — A PSR-4 autoloader for `Joomla\CMS\*` classes (from `libraries/src/`) is not enough. Framework packages (`Joomla\Database\*`, `Joomla\Event\*`, `Joomla\Session\*`, etc.) live in `libraries/vendor/` and require loading `libraries/vendor/autoload.php`. Without this, any test stubbing framework interfaces will fail with "Class or interface does not exist".

```php
// In bootstrap.php — load BOTH autoloaders
require_once $joomlaCmsPath . '/libraries/vendor/autoload.php'; // Framework packages
// Then register your own PSR-4 autoloader for Joomla\CMS\* from libraries/src/
```

**`createMock()` vs `createStub()` for expectations** — PHPUnit's `createStub()` does not support `expects()`. If you need to assert that a method is (or isn't) called, use `createMock()` instead:

```php
// WRONG — expects() on a stub triggers a deprecation warning
$db = $this->createStub(DatabaseDriver::class);
$db->expects($this->never())->method('loadObject'); // Deprecated!

// CORRECT — use createMock() for expectations
$db = $this->createMock(DatabaseDriver::class);
$db->expects($this->never())->method('loadObject'); // Clean
```

### Composer Scripts

Add test commands to `composer.json`:

```json
{
  "scripts": {
    "test": "@test:unit",
    "test:unit": "phpunit --testsuite Unit",
    "test:integration": "phpunit --testsuite Integration",
    "check": ["@lint", "@test"]
  }
}
```

## Version Migration: Joomla 5 → 6 (and Beyond)

When migrating an extension from Joomla 5 to Joomla 6 (or writing code that supports both), apply these changes systematically:

### Step 1: Query Builder
Find all instances of `$db->getQuery(true)` and replace with `$db->createQuery()`. Both work on Joomla 5, but only `createQuery()` is guaranteed going forward.

### Step 2: Input Classes
Replace any `use Joomla\CMS\Input\Input` with `use Joomla\Input\Input`. The CMS wrapper is removed in Joomla 6. Note: `$this->input` in controllers already works correctly on both versions.

### Step 3: CMSObject → stdClass
If code uses `$item->get('property')` or `$item->set('property', $value)` on objects returned by `getItem()`, replace with direct property access: `$item->property` and `$item->property = $value`. In Joomla 6, `getItem()` returns `stdClass`, not `CMSObject`.

### Step 4: Filesystem Classes
Replace `use Joomla\CMS\Filesystem\File` / `Folder` / `Path` with PHP native functions (`file_put_contents`, `mkdir`, `is_dir`, etc.) or Symfony Filesystem. The CMS Filesystem classes move behind the compat plugin in J6 and are removed in J7.

### Step 5: Factory Methods
Search for and replace:
- `Factory::getUser()` → `$this->getCurrentUser()` (in models) or `$this->getIdentity()` (in controllers/views)
- `Factory::getApplication()` → Inject via constructor or use `$this->getApplication()`
- `Factory::getDbo()` → `$this->getDatabase()` or inject `DatabaseInterface`

### Step 6: Error Handling
Replace `$model->getError()` / `$model->setError()` patterns with try/catch and thrown exceptions (`\RuntimeException`, `\InvalidArgumentException`).

### Step 7: Test
After migration, test with the "Behaviour - Backward Compatibility 6" plugin **disabled** to confirm the extension runs natively on Joomla 6 without compatibility shims.

### Future Versions
This skill targets Joomla 6 native patterns that also work on Joomla 5. As Joomla 7+ introduces additional changes, this migration checklist will expand. The core principle remains: use the modern API from the framework layer (`Joomla\Database`, `Joomla\Input`) rather than the CMS convenience wrappers.

## Common Gotchas & Pitfalls

Hard-won lessons from real Joomla 5/6 extension development. These are easy to get wrong because IDE autocompletion, documentation gaps, or reasonable assumptions lead you astray.

### BaseController vs FormController — Choose the Right Parent

**Never extend `BaseController` for controllers that handle form submissions.** `BaseController` only supports `display()` — it has no form handling, no checkin/checkout, no save/cancel/apply workflow, and no CSRF token validation for POST requests.

| Controller Parent | Use When |
|-------------------|----------|
| `BaseController` | Display-only controllers (list views, read-only pages, AJAX endpoints) |
| `FormController` | Single-item CRUD (edit, save, apply, cancel) — handles checkout, redirect, form validation |
| `AdminController` | List operations (publish, unpublish, delete, reorder, checkin, batch) |

```php
// WRONG — no save(), apply(), cancel(), or form handling
class ItemController extends BaseController { }

// CORRECT — full form lifecycle with checkout, redirect, CSRF
class ItemController extends FormController { }

// CORRECT — list operations with batch, publish, ordering
class ItemsController extends AdminController { }
```

If you need a custom action on a form controller (e.g., `export`), extend `FormController` and add your method — don't drop down to `BaseController` just because you want a simpler class.

### Controller API Differences (Joomla 5)

`BaseController` in Joomla 5 does **NOT** have `getInput()` or `getApplication()` methods. Use the properties directly:

```php
// WRONG — throws "method not found" on Joomla 5
$input = $this->getInput();
$app   = $this->getApplication();

// CORRECT — works on both Joomla 5 and 6
$input = $this->input;
$app   = $this->app;
```

Only `CMSApplication::getInput()` exists in J5 (so `$app->getInput()` is fine, but `$this->getInput()` on a controller is NOT).

### Event Dispatching (Joomla 5 Compatibility)

Typed event classes (`ContentPrepareEvent`, etc.) with `->getResult()` are **NOT available in Joomla 5**. If your extension must support J5:

```php
// WRONG on Joomla 5 — typed events don't exist
$event = new ContentPrepareEvent('onContentPrepare', ['context' => $context, 'subject' => $item]);
$this->getDispatcher()->dispatch($event->getName(), $event);
$results = $event->getResult();

// CORRECT for J5 compatibility — returns results directly as array
$results = $app->triggerEvent('onContentPrepare', [$context, &$item, &$params, $page]);
```

### Plugin Manifest Naming

Plugin manifest files **must** be named `{element}.xml` (matching the plugin element name) for discover install to work. For example, a plugin with element `example` must have `example.xml`, not `plg_content_example.xml`.

**CRITICAL:** Having both `example.xml` AND `plg_content_example.xml` in the plugin directory causes Joomla's Discover to create duplicate extension records. Only the `{element}.xml` file should exist in the source. The build/packaging process can rename to `plg_{group}_{element}.xml` for the installable ZIP if needed by the installer.

### Plugin Language Files

Plugin language files must use the **locale prefix naming convention** when stored in the plugin's own `language/` directory:

```
language/en-GB/en-GB.plg_content_example.ini
language/en-GB/en-GB.plg_content_example.sys.ini
```

**NOT** `plg_content_example.ini` (without the `en-GB.` prefix) — that format only works when files are in `administrator/language/en-GB/`.

The plugin class **must** set `$autoloadLanguage = true` for Joomla to load language files from the plugin directory:

```php
class Example extends CMSPlugin implements SubscriberInterface
{
    protected $autoloadLanguage = true;
    // ...
}
```

Without this property, language strings will show as raw keys (e.g., `PLG_CONTENT_EXAMPLE_TITLE`).

### Task Plugin Language Keys

`TaskPluginTrait` appends `_TITLE` and `_DESC` to the `langConstPrefix` defined in `TASKS_MAP`. Language keys **must** include these suffixes:

```php
protected const TASKS_MAP = [
    'myplugin.my_task' => [
        'langConstPrefix' => 'PLG_TASK_MYPLUGIN_TASK_MYTASK',
        'method'          => 'doMyTask',
    ],
];
```

```ini
; Language file must have _TITLE and _DESC suffixed keys:
PLG_TASK_MYPLUGIN_TASK_MYTASK_TITLE="My Task Name"
PLG_TASK_MYPLUGIN_TASK_MYTASK_DESC="Description of what this task does."
```

Using just `PLG_TASK_MYPLUGIN_TASK_MYTASK` (without `_TITLE`) will NOT work — the task type selector will show the raw key.

### Always Use AdminModel + Table for CRUD

**Never bypass Joomla's Table save workflow** with direct `$db->insertObject()` / `$db->updateObject()` in model `save()` methods. The `AdminModel::save()` → `Table::bind()` → `Table::check()` → `Table::store()` chain handles:

- Setting `$this->setState('item.id', $newId)` for redirect after save
- Checkout/checkin management
- Session state cleanup
- Event dispatching

```php
// WRONG — breaks FormController redirects, ID tracking, checkout
public function save($data): bool
{
    $db = $this->getDatabase();
    $db->insertObject('#__mytable', (object) $data);
    return true;
}

// CORRECT — delegates to Table class
public function save($data): bool
{
    $data['modified'] = Factory::getDate()->toSql();
    return parent::save($data);
}
```

### List-to-Edit Links Must Use task= Routing

Links from list views to edit views **must** use `task={entity}.edit&id=X`, NOT `view={entity}&layout=edit&id=X`:

```php
// WRONG — bypasses FormController, no checkout, broken session state
Route::_('index.php?option=com_mycomponent&view=item&layout=edit&id=' . $item->id)

// CORRECT — routes through FormController::edit()
Route::_('index.php?option=com_mycomponent&task=item.edit&id=' . $item->id)
```

`FormController::edit()` handles setting the layout, checking out the record, and managing the user state.

### Load form.validate for Form Views

Any view that renders a form with `class="form-validate"` **must** load the `form.validate` web asset, or `Joomla.submitbutton()` will throw an `isValid` error:

```php
// In HtmlView::display()
$this->getDocument()->getWebAssetManager()->useScript('form.validate');
```

### Table::check() and DatabaseModel::fix()

- In `Table::check()`, throw `\UnexpectedValueException` with `Text::_()` language keys for validation errors
- `DatabaseModel::fix()` only executes **DDL** (ALTER TABLE, CREATE INDEX, etc.) — use PHP migration steps for **DML** (INSERT, UPDATE, DELETE data changes)

### HTTP Client Class

`Joomla\CMS\Http\HttpFactory::getHttp()` is the correct way to get an HTTP client. **`Joomla\Http\HttpFactory` does NOT exist** — IDE autocompletion may suggest the wrong namespace. Don't let the linter "fix" this import.

```php
// CORRECT
use Joomla\CMS\Http\HttpFactory;
$http = HttpFactory::getHttp();

// WRONG — this class does not exist
use Joomla\Http\HttpFactory;
```

### Registry::get() Defaults

`$params->get('key')` returns `null` when the key is missing from the stored JSON (common with component/module params). **Always provide a default:**

```php
// Dangerous — returns null if 'items_per_page' was never saved
$limit = $params->get('items_per_page');

// Safe — explicit default
$limit = $params->get('items_per_page', 10);
```

### Text::script() Registration Location

JavaScript language strings via `Joomla.Text._('KEY')` only work if the key was registered server-side with `Text::script()`. Register in the right place:

- **Components**: Register in `HtmlView::display()` before the template renders
- **Modules**: Register in `Dispatcher::dispatch()` before the module template loads

```php
// In HtmlView::display() or Dispatcher::dispatch()
Text::script('COM_MYCOMPONENT_CONFIRM_DELETE');
Text::script('COM_MYCOMPONENT_SAVING');
```

### Joomla.Text._() Returns Raw Key When Unregistered

`Joomla.Text._('SOME_KEY')` returns the raw key string (e.g., `"SOME_KEY"`) when the key was never registered — this is **truthy**, so a fallback pattern like `Joomla.Text._('KEY') || 'fallback'` will never fire the fallback. Compare against the key itself:

```javascript
// WRONG — fallback never fires because unregistered keys return the key string (truthy)
const msg = Joomla.Text._('COM_MYCOMP_LABEL') || 'Default Label';

// CORRECT — detect missing registration
const key = 'COM_MYCOMP_LABEL';
const translated = Joomla.Text._(key);
const msg = (translated !== key) ? translated : 'Default Label';
```

### Batch Task Routing

`AdminController` (the plural list controller) does **NOT** have a `batch()` method. Only `FormController` (the singular edit controller) has it. If batch operations aren't working, check that your form controller exists and is being routed correctly.

### Router Registration (CRITICAL — 3 Parts Required)

The SEF Router **will not work at all** unless all three parts are in place. Missing any one causes `Route::_()` to fall back to raw query parameters (`?view=xxx`) instead of clean SEF URLs.

**Part 1: Router class** (`site/src/Service/Router.php`):
```php
class Router extends RouterView
{
    public function __construct(SiteApplication $app, AbstractMenu $menu)
    {
        $this->registerView(new RouterViewConfiguration('items'));
        // ... register all views ...

        parent::__construct($app, $menu);

        $this->attachRule(new MenuRules($this));
        $this->attachRule(new StandardRules($this));
        $this->attachRule(new NomenuRules($this));
    }
}
```

**Part 2: Extension class must implement `RouterServiceInterface`:**
```php
use Joomla\CMS\Component\Router\RouterServiceInterface;
use Joomla\CMS\Component\Router\RouterServiceTrait;

class MyComponent extends MVCComponent implements RouterServiceInterface
{
    use RouterServiceTrait;
    // ...
}
```

Without `RouterServiceInterface`, `setRouterFactory()` doesn't exist and the component silently has no router.

**Part 3: Service provider must register `RouterFactory`:**
```php
// In services/provider.php
$container->registerServiceProvider(new RouterFactory('\\Vendor\\Component\\MyComponent'));

// In the ComponentInterface factory:
$component->setRouterFactory($container->get(RouterFactoryInterface::class));
```

Without the `RouterFactory` registration, Joomla can't instantiate the Router class, and ALL `Route::_()` calls for the component produce non-SEF URLs.

### Hidden Menu Items for SEF Routing

`Route::_()` uses `SiteMenu::getItems()` which filters by the current user's access levels. For components that require login, the routing menu items **must** have access level `1` (Public) — not `2` (Registered).

With `access=2`, guests can't resolve SEF URLs, so `Route::_()` fails and appends `?view=xxx` to the wrong base URL. The component's controller still enforces login — Public access on the menu item only affects URL resolution.

Components should create a hidden menu type during install with menu items for each site view:
- Menu type is not assigned to any module (invisible to visitors)
- Each view gets a published menu item with `access=1`
- `Route::_('index.php?option=com_mycomponent&view=items')` resolves to `/items` via the hidden menu item

### SEF Router Callback Naming

Router callback methods follow a strict naming convention derived from the view name. Get it wrong and Joomla silently skips your callback, producing broken URLs:

```php
// View name: 'item' → methods must be:
public function getItemSegment($id, $query): array    // Build: ID → alias
public function getItemId($segment, $query): int|false // Parse: alias → ID

// View name: 'category' → methods must be:
public function getCategorySegment($id, $query): array
public function getCategoryId($segment, $query): int|false
```

The method name is `get` + `ucfirst(viewName)` + `Segment` or `Id`. Case must match exactly.

**Common mistakes:**
- Missing callback → SEF URLs fall back to numeric IDs or break entirely
- `getSegment()` returning wrong format → must return `[id => alias]` associative array
- `getId()` not scoping by category → ambiguous aliases across categories resolve to wrong record
- Rule order wrong → `MenuRules` must come before `StandardRules` before `NomenuRules`

### WAM URI Auto-Resolution

In `joomla.asset.json`, do **NOT** include `css/` or `js/` subdirectories in asset URIs. Joomla auto-resolves them:

```json
{
  "name": "com_mycomponent.admin",
  "type": "style",
  "uri": "com_mycomponent/admin.css"
}
```

Joomla maps `com_mycomponent/admin.css` → `media/com_mycomponent/css/admin.css` automatically. Including the subdirectory (`com_mycomponent/css/admin.css`) causes a 404.

### WAM Non-Standard Paths

Vendor assets stored outside the standard `media/com_*/` structure (e.g., `media/fancybox/`, `media/vendor/`) **cannot use auto-resolution**. Use a full literal path instead:

```php
$wa->registerAndUseScript('vendor.fancybox', 'media/fancybox/fancybox.umd.js');
$wa->registerAndUseStyle('vendor.fancybox', 'media/fancybox/fancybox.css');
```

### WAM Inline Assets

For dynamic CSS (e.g., CSS custom properties from PHP) or scripts that need PHP data, use inline asset methods:

```php
// Dynamic CSS variables
$wa->addInlineStyle(":root { --brand-color: {$brandColor}; }");

// Script with PHP data (heredoc keeps it readable)
$wa->addInlineScript(<<<JS
    const MyConfig = {
        baseUrl: '{$baseUrl}',
        itemId: {$itemId},
        token: '{$token}'
    };
JS);
```

### Dark Mode (Bootstrap 5.3)

Joomla 5+ admin uses Bootstrap 5.3 dark mode via `data-bs-theme="dark"` on `<html>`. When writing admin templates:

- **NEVER** use `bg-light` — it stays white in dark mode
- **NEVER** use `btn-outline-*` — very low contrast against dark backgrounds. Use solid `btn-*` variants instead (e.g., `btn-primary` not `btn-outline-primary`)
- Use color-adaptive classes: `bg-body-secondary`, `bg-body-tertiary`, `border rounded`
- Replace `text-muted` with `text-body-secondary`
- Test your templates with both light and dark modes enabled

### Bootstrap 5 Dynamic Modal Cleanup

When creating modals programmatically with `new bootstrap.Modal()`, do **NOT** rely on `bsModal.hide()` for teardown — it doesn't reliably clean up the backdrop, `aria-hidden`, and body scroll-lock. Use full manual cleanup:

```javascript
const cleanup = () => {
    bsModal.dispose();
    modalEl.remove();
    document.querySelectorAll('.modal-backdrop').forEach(n => n.remove());
    document.body.classList.remove('modal-open');
    document.body.style.removeProperty('overflow');
    document.body.style.removeProperty('padding-right');
};
```

This affects any Joomla extension that creates confirmation dialogs, AJAX editors, or wizard modals via JavaScript rather than static HTML markup.

### getStoreId() in ListModel

`ListModel::getStoreId()` generates a hash key to distinguish cached data sets. If you add custom filters or state to your list model, you **must** override this method or the model will return stale cached results when filters change:

```php
protected function getStoreId($id = ''): string
{
    $id .= ':' . $this->getState('filter.search');
    $id .= ':' . $this->getState('filter.published');
    $id .= ':' . $this->getState('filter.category_id');
    $id .= ':' . serialize($this->getState('filter.access'));

    return parent::getStoreId($id);
}
```

Every `filter.*` state your `getListQuery()` uses must appear in `getStoreId()`. Miss one and you get the previous filter's results from cache.
