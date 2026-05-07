---
name: joomla
description: Joomla 5+ / 6 / 7 extension development for components, modules, plugins, libraries, and templates using modern MVC with PSR-4 namespaces, DI, and service providers. Trigger on Joomla 5, 5.4, 6, 6.1, 6.2, 7, J5/J6/J7, Joomla CMS, provider.php, manifest XML, install script, scriptfile, or any Joomla extension code. Covers scaffolding extensions; views/models/controllers; service providers; manifests; install/uninstall scripts; database migrations; language files; custom form fields; layout and template overrides; plugin event subscribers (SubscriberInterface, CMSPlugin); module dispatchers; Web Asset Manager (joomla.asset.json, useScript, useStyle); task plugins / scheduled tasks; webservices and Joomla JSON:API endpoints; finder / search adapters; schemaorg plugins; SEF router contracts (RouterServiceInterface, RouterFactory). Trigger for prompts like "add a view", "create a controller", "register web assets", "write an install script", "override a layout" in any Joomla project regardless of domain.
---

# Joomla 5+ Extension Development

This skill guides you through building Joomla 5+ extensions (components, modules, plugins) using modern architecture patterns derived from the [joomla-cms](https://github.com/joomla/joomla-cms) core and real-world production components.

**Target:** Natively Joomla 6, backward compatible with Joomla 5 (no backward compatibility plugin required)
**PHP requirement (Joomla 6.x):** 8.3+ minimum and supported, 8.4 recommended ([source](https://manual.joomla.org/docs/get-started/technical-requirements/))
**Coding standard:** PSR-12 (PHP), Joomla ESLint config (JavaScript)

## Canonical sources

When a Joomla pattern is non-obvious, ambiguous, or might have drifted between versions, verify against upstream before answering. Prefer fetching directly with WebFetch; if the fetch is blocked, fails, or the user is offline, fall back in this order: (1) cite the canonical URL so the user can open it, (2) rely on the patterns documented in this skill and `references/*.md`, (3) ask the user to paste the relevant snippet rather than guess.

**Primary — source of truth for runtime behavior:**

- [`github.com/joomla/joomla-cms`](https://github.com/joomla/joomla-cms) — core CMS. **Active dev branches** (verified 2026-04-30, after J6.1 release):
  - `6.1-dev` — current released J6 line, in patch maintenance. **Default reference for new J6 code.**
  - `6.2-dev` — next J6 minor in development.
  - `5.4-dev` — current released J5 line.
  - `7.0-dev` — next major in development. Where deprecations land for removal (e.g., the `CMSPlugin::__construct(DispatcherInterface, …)` deprecation slated for removal here — see `references/plugin.md`).
  
  Pick the branch matching the target Joomla version for the code you're verifying. Re-check [`/branches`](https://github.com/joomla/joomla-cms/branches) periodically — Joomla cuts new minor branches frequently and the names above will drift.
  - Frontend component examples: [`components/`](https://github.com/joomla/joomla-cms/tree/6.1-dev/components)
  - Backend component examples: [`administrator/components/`](https://github.com/joomla/joomla-cms/tree/6.1-dev/administrator/components)
  - Core plugins: [`plugins/`](https://github.com/joomla/joomla-cms/tree/6.1-dev/plugins)
  - Core modules: [`modules/`](https://github.com/joomla/joomla-cms/tree/6.1-dev/modules) and [`administrator/modules/`](https://github.com/joomla/joomla-cms/tree/6.1-dev/administrator/modules)
  - Framework libraries shipped with the CMS: [`libraries/src/`](https://github.com/joomla/joomla-cms/tree/6.1-dev/libraries/src)
- [`github.com/joomla-framework`](https://github.com/joomla-framework) — standalone Framework packages (DI, Event, Filesystem, etc.) reused by the CMS.

**Documentation:**

- [manual.joomla.org](https://manual.joomla.org/) — current Developer Manual (Joomla 5+). Preferred prose reference.
  - Source repo: [`github.com/joomla/Manual`](https://github.com/joomla/Manual) (default branch `main`) — the Markdown backing the rendered site. Useful when you need to grep, fetch raw, or cite a permalink to a specific page; manual edits / corrections also go here as PRs.
- [api.joomla.org](https://api.joomla.org/) — generated API reference (classes, methods, signatures).
- [framework.joomla.org](https://framework.joomla.org/) — Joomla Framework package docs.
- [docs.joomla.org](https://docs.joomla.org/) — **legacy wiki**. Useful for historical context (J3/J4) but often stale for J5/J6; cross-check against `joomla-cms` HEAD before quoting.

**When citing in generated code or replies:** prefer a permalink to a specific file/line in `joomla-cms` (right-click → "Copy permalink" produces a commit-pinned URL) over a branch link, so the reference does not silently drift.

**Update cadence:** if a WebFetch reveals the upstream pattern differs from what this skill teaches, flag it to the user and recommend opening an issue on `Joomla-Bible-Study/claude-skill-joomla` so the skill can be corrected.

## Coding Standards

**Standards:** PSR-12 for PHP, Joomla ESLint flat config for JavaScript, `joomla/coding-standards` PHPCS ruleset, C++ style (`//`) for inline comments. Every PHP file ships a `@package` / `@copyright` / `@license` header, every class/property/method gets a docblock with `@since`, `@param` blocks align to two-space minimum spacing, and `@return` is always required. JS sources live in `build/media_source/` and compile to `media/<extension>/js/`; the `Joomla` and `bootstrap` globals are pre-registered. For full docblock examples (file header, class, property, method, deprecated), JS conventions and JSDoc patterns, the PHPCS install / `phpcs.xml` template, and the inline-comment style rules, read [`references/coding-standards.md`](references/coding-standards.md).

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

Cross-cutting references (loaded on demand):
- `references/coding-standards.md` — PSR-12 / PHPDoc / ESLint / PHPCS conventions
- `references/component-advanced.md` — Toolbar API, batch, ordering, tags, versioning, workflow, webservices, mail templates, dashboards, custom rules
- `references/editor-api.md` — WYSIWYG editor JS/PHP API + XTD buttons
- `references/form-fields.md` — Built-in field types + custom field authoring
- `references/menu-items.md` — Site-view menu item type XML (request fields, params, useglobal, multi-layout)
- `references/packaging.md` — Manual zip, build scripts, package extensions, include/exclude checklist
- `references/testing.md` — PHPUnit + Jest patterns with real Joomla CMS classes
- `references/gotchas.md` — Hard-won J5/J6 pitfalls (controllers, routing, WAM, dark mode, etc.)

Shared cross-extension references (linked from the per-type files above):
- `references/manifest.md` — Universal manifest elements (`<extension>` root, metadata, `<files>`, `<media>`, `<languages>`, `<scriptfile>`, `<update>` / `<updateservers>`)
- `references/install-script.md` — Lifecycle hooks (`preflight`/`install`/`update`/`postflight`/`uninstall`) shared by component/module/plugin/library
- `references/language-files.md` — Filename conventions, key prefixes per type, plurals, `Text::script()` JS registration
- `references/service-provider.md` — `ServiceProviderInterface` pattern + per-type binding table (component/module/plugin)
- `references/component-router.md` — Router class + `RouterServiceInterface` + `RouterFactory` 3-part contract and SEF rules

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

Every extension has `services/provider.php` — this is how Joomla discovers and bootstraps the extension through its DI container. The wrapping pattern (`ServiceProviderInterface` + anonymous class + `register()`) is shared across components, modules, and plugins; for the universal pattern, the per-type binding table, and the common DI pitfalls see [`references/service-provider.md`](references/service-provider.md). The example below is the **component** flavor — it registers `MVCFactory`, `ComponentDispatcherFactory`, `RouterFactory`, and (when applicable) `CategoryFactory`, then binds `ComponentInterface`.

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
| `getError()` / `setError()` on **models** (`BaseDatabaseModel`) | Use exceptions | Throw `\RuntimeException` |
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

Some projects use a vendor prefix on entity names (e.g., `AcmeBooking` instead of plain `Booking`). This is optional but helps avoid naming collisions with other extensions.

The view name in the URL (e.g., `&view=bookings`) must match the View directory name (case-insensitive on the URL side, but the directory must match the class namespace).

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

The filename / key-prefix / plural / `Text::script()` JS-registration conventions are **shared across every extension type** (component / module / plugin / library); the full reference lives in [`references/language-files.md`](references/language-files.md). The example below uses the **component** prefix (`COM_`); modules use `MOD_`, plugins `PLG_<GROUP>_<ELEMENT>_`, libraries `LIB_`.

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

For the **universal** manifest elements (`<extension>` root attributes, metadata, `<files>`, `<media>`, `<languages>`, `<scriptfile>`, `<update>` / `<updateservers>`) read [`references/manifest.md`](references/manifest.md). For the **component-specific** template (the `<install>` SQL block, `<update><schemas>`, the `<administration>` block with `<menu>` / `<submenu>`) read [`references/component.md`](references/component.md). Key elements:

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
            <item>Requires PHP 8.3+</item>
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
        <targetplatform name="joomla" version="6\.[0-9]+" />
        <php_minimum>8.3.0</php_minimum>
        <sha256>abc123...</sha256>
        <sha384>def456...</sha384>
        <sha512>ghi789...</sha512>
        <maintainer>Vendor Name</maintainer>
        <maintainerurl>https://example.com</maintainerurl>
        <changelogurl>https://example.com/changelogs/com_mycomponent/changelog.xml</changelogurl>
    </update>
</updates>
```

Key fields: `<targetplatform>` uses regex for version matching: `6\.[0-9]+` matches all Joomla 6.x, `5\.[0-9]+` matches all J5.x, `(5|6)\.[0-9]+` covers both lines for a J5/J6 dual-support release. Add multiple `<update>` blocks for different versions. The `<changelogurl>` here links the same changelog XML so Joomla can show changes before updating.

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

The script class runs during install, update, and uninstall. Critical for DML operations (INSERT, UPDATE, DELETE) that can't go in SQL update files (which only run DDL). The lifecycle hooks and class-naming conventions are **shared with modules and plugins** — for the full hook signatures, the class-name table for component/module/plugin, and the DDL-vs-DML rule see [`references/install-script.md`](references/install-script.md). The component-flavored example below uses the canonical `Log::add(..., 'jerror')` pattern from that reference for preflight failure surfacing.

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Factory;
use Joomla\CMS\Installer\InstallerAdapter;
use Joomla\CMS\Log\Log;

class Com_MyComponentInstallerScript
{
    protected string $minimumPhp = '8.3.0';     // Joomla 6.x floor; covers J5.3+ too
    protected string $minimumJoomla = '5.0.0';   // Earliest Joomla version this extension supports

    public function preflight(string $type, InstallerAdapter $adapter): bool
    {
        // Runs BEFORE install/update. Return false to abort.
        if (version_compare(PHP_VERSION, $this->minimumPhp, '<')) {
            Log::add("PHP {$this->minimumPhp}+ required", Log::ERROR, 'jerror');
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

Component-level features beyond core MVC: the toolbar API (`getDocument()->getToolbar()`, dropdown groups, save dropdowns), batch processing (`AdminModel` batch methods, dialog template, controller `batch()` override), drag-drop ordering (the `ordering` column, `js-draggable` markup, AJAX save), tags integration (`TagServiceInterface`, `TaggableTableInterface`), content versioning (`VersionableModelInterface`, `#__content_types` registration, `save_history` config), workflow integration (`WorkflowServiceInterface`), the webservices API plugin (`onBeforeApiRoute`, `createCRUDRoutes`, JSON:API view), mail templates (`MailTemplate`, `#__mail_templates`), dashboard views (manifest `<dashboards>`, presets, `cpanel-*` positions), and custom form validation rules (`FormRule`, `addruleprefix`). For full code examples and the toolbar method list, read [`references/component-advanced.md`](references/component-advanced.md).

## Editor API

Joomla's Editor API provides a unified interface for WYSIWYG editors (TinyMCE, CodeMirror, None) and editor extension buttons. Coverage: the modern `JoomlaEditor` JS API (`get`, `getActive`, `getValue`, `setValue`, `getSelection`, `replaceSelection`, `disable`, `getRawInstance`, `getType`); the legacy `Joomla.editors.instances` proxy; the `JoomlaEditorDecorator` pattern for implementing a custom editor; XTD button plugins (`onEditorButtonsSetup`, `Button` class, `JoomlaEditorButton.registerAction`); the modal-button content-selection flow with `postMessage` and `joomla:content-select`; the `editor` form field type with all attributes (`buttons`, `hide`, `height`, `width`, `editor`, `filter`, `asset_field`, `created_by_field`, `syntax`); and editor plugin registration via `onEditorSetup` with `AbstractEditorProvider`.

For full code examples and the button-action behavior table, read [`references/editor-api.md`](references/editor-api.md).

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

Joomla ships ~90 built-in form field types and a clean extension model for custom field classes. Coverage: built-in field reference (basic inputs, selection fields, file/media fields, special fields including `subform`, `rules`, `ordering`, `note`, `componentlayout`), the `subform` repeatable-group pattern with external/inline form sources, the `media` picker (`types`, `preview`, `directory` attributes), authoring custom fields by extending `ListField` / `GroupedlistField` / `FormField` / `TextField` / `PredefinedlistField`, the `addfieldprefix` form attribute, and modern layout-based field rendering with `getLayoutData()`.

For the full type reference, custom-field examples, and layout overrides, read [`references/form-fields.md`](references/form-fields.md).

## Menu Item Types (Site Views)

Menu item types define what appears in Joomla's Menu Manager. Joomla scans `components/{component}/tmpl/{view}/` for XML files: each `.xml` matching a layout name (`default.xml`, `blog.xml`, etc.) becomes a selectable menu item type. For the full XML structure (list and single-item variants), `<layout>` / `<fields name="request">` / `<fields name="params">` semantics, the `useglobal="true"` cascade rule, and the multi-layout-per-view convention, read [`references/menu-items.md`](references/menu-items.md).

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
        "php": ">=8.3",
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

Joomla extensions ship as ZIP files installed through the admin installer (`System → Install → Extensions`). For manual packaging, the build-script pattern, package manifests (multiple extensions bundled), and the include/exclude checklist for what belongs in the ZIP, read [`references/packaging.md`](references/packaging.md).

## Real-World Reference: Production Components

When working on a Joomla project, check whether the project has its own `CLAUDE.md` or `CONTRIBUTING.md` at the repo root — these often define project-specific naming conventions, build commands, and coding standards that should take precedence over this skill's generic patterns.

Common patterns seen in production Joomla 5+ components:

- **Entity prefixes** — Some projects prefix entity names to avoid collisions (e.g., a `<Vendor>` prefix on every Model/View/Table class). Follow the project's existing convention.
- **Plugin groups** — Real components typically ship with several plugin types: content, finder (Smart Search), schemaorg (structured data), system, task (scheduled jobs), and webservices (REST API).
- **Module variants** — Both admin-side and site-side modules in `modules/admin/` and `modules/site/`.
- **Build tooling** — Composer for PHP dependencies + npm for JS/CSS asset compilation. Look for `composer.json` and `package.json` at the project root.
- **Testing** — PHPUnit for PHP (unit + integration tests in `tests/`), Jest for JavaScript. See the **Testing** section below for patterns.
- **Non-standard vendor paths** — Some projects place Composer's `vendor/` directory in a custom location (e.g., `libraries/vendor/`). Check `composer.json` for the `vendor-dir` config.
- **Media asset pipeline** — Source JS/CSS in a build directory (e.g., `build/media_source/`) compiled to `media/` via npm scripts. The `media/` directory may be gitignored.

## Testing

PHPUnit (PHP) and Jest (JavaScript) patterns for Joomla 5+ extensions, anchored on the principle Joomla core uses for its own tests: **load real CMS classes, don't stub them.** Topics covered: `tests/Unit/` + `tests/Integration/` directory layout, `phpunit.xml` configuration, the bootstrap that loads Joomla's vendor autoloader plus your component's PSR-4 autoloader, the `getQueryStub()` helper for a real `DatabaseQuery` with only 2 abstract methods stubbed, model/table/helper test patterns, Jest with jsdom for JavaScript with mocked `Joomla` globals, and four high-stakes testing gotchas (`DatabaseInterface` lacks `createQuery()`, `CMSApplicationInterface` lacks `getSession()`, the bootstrap-must-load-`libraries/vendor/autoload.php` rule, `createMock()` vs `createStub()` for expectations).

For full setup, code patterns, and gotcha details, read [`references/testing.md`](references/testing.md).

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

Hard-won lessons from real Joomla 5/6 extension development — easy to get wrong because IDE autocompletion, documentation gaps, or reasonable assumptions lead you astray. Topics covered: `BaseController` vs `FormController`, J5 controller API differences (`$this->input` not `getInput()`), event dispatching for J5 compatibility, plugin manifest naming, plugin language file conventions, task plugin language keys, `AdminModel`/`Table` save workflow, `task=` routing, `form.validate` asset, `Table::check()`, HTTP client class, `Registry::get()` defaults, `Text::script()` registration, `Joomla.Text._()` truthy-key trap, batch routing, **the 3-part SEF router contract** (router class + `RouterServiceInterface` + `RouterFactory`), hidden menu items for SEF, router callback naming, **WAM URI auto-resolution / non-standard paths / inline assets**, Bootstrap 5.3 dark mode classes, dynamic modal cleanup, and `getStoreId()` in `ListModel`.

For full details and code examples, read [`references/gotchas.md`](references/gotchas.md).

