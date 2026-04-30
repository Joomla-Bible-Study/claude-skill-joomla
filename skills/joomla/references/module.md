# Joomla 5+ Module Reference

## Table of Contents
1. [Directory Structure](#directory-structure)
2. [Manifest XML](#manifest-xml) — universal elements in [`manifest.md`](manifest.md)
3. [Language Files](#language-files) — full conventions in [`language-files.md`](language-files.md)
4. [Service Provider](#service-provider) — universal pattern in [`service-provider.md`](service-provider.md)
5. [Dispatcher](#dispatcher) (incl. Web Asset Manager registration)
6. [Helper Class](#helper-class)
7. [Template (Layout)](#template-layout)
8. [Caching](#caching)
9. [Install Script (Optional)](#install-script-optional) — full walkthrough in [`install-script.md`](install-script.md)
10. [Admin Module](#admin-module)
11. [Joomla 6.1 capabilities](#joomla-61-capabilities)

---

## Directory Structure

```
mod_example/
├── mod_example.xml                # Manifest
├── services/
│   └── provider.php               # DI registration
├── src/
│   ├── Dispatcher/
│   │   └── Dispatcher.php         # Orchestrates module rendering
│   └── Helper/
│       └── ExampleHelper.php      # Data retrieval logic
├── tmpl/
│   └── default.php                # Output template
├── language/
│   └── en-GB/
│       └── mod_example.ini
└── media/                         # Optional
    └── joomla.asset.json
```

---

## Manifest XML

For the **universal** elements that appear in every extension type's manifest (`<extension>` root attributes, the metadata block, `<files>`, `<media>`, `<languages>`, `<scriptfile>`, `<update>` / `<updateservers>`) see [`references/manifest.md`](manifest.md). The example below is module-specific: it adds the `client="site"` (or `"administrator"`) attribute and the `<config><fields name="params">` block where module params are declared.

```xml
<?xml version="1.0" encoding="utf-8"?>
<extension type="module" client="site" method="upgrade">
    <name>mod_example</name>
    <author>Your Name</author>
    <version>1.0.0</version>
    <creationDate>2026-01-01</creationDate>
    <description>MOD_EXAMPLE_XML_DESCRIPTION</description>
    <namespace path="src">Vendor\Module\Example</namespace>

    <files>
        <folder>services</folder>
        <folder>src</folder>
        <folder>tmpl</folder>
        <folder>language</folder>
    </files>

    <languages folder="language">
        <language tag="en-GB">en-GB/mod_example.ini</language>
    </languages>

    <media destination="mod_example" folder="media">
        <filename>joomla.asset.json</filename>
    </media>

    <config>
        <fields name="params">
            <fieldset name="basic">
                <field
                    name="count"
                    type="number"
                    label="MOD_EXAMPLE_COUNT"
                    default="5"
                    min="1"
                    max="100"
                />
                <field
                    name="layout"
                    type="modulelayout"
                    label="JFIELD_ALT_LAYOUT_LABEL"
                />
            </fieldset>
            <fieldset name="advanced">
                <field
                    name="moduleclass_sfx"
                    type="textarea"
                    label="COM_MODULES_FIELD_MODULECLASS_SFX_LABEL"
                    rows="3"
                />
            </fieldset>
        </fields>
    </config>
</extension>
```

Key points:
- `client="site"` for frontend modules, `client="administrator"` for admin modules
- Namespace maps to `src/` directory

---

## Language Files

Modules use the `MOD_<ELEMENT>_*` key prefix and ship two `.ini` files: a runtime file for layout strings (`en-GB.mod_example.ini`) and a `.sys.ini` for the install / Module Manager listing (`en-GB.mod_example.sys.ini`).

The full conventions — file-naming, plurals, `_FIELD_<NAME>_LABEL` / `_DESC` form-field pattern, `Text::script()` JS registration, the dispatcher as the right place to register module JS strings — are **shared across all extension types** and live in [`references/language-files.md`](language-files.md). Module-specific reminders:

- The manifest's `<languages>` block has no `folder=""` attribute (modules ship a single `language/` subtree).
- Field labels in the `<config>` block (e.g., `MOD_EXAMPLE_COUNT` at line 69) only resolve once the runtime `.ini` is loaded by the Module Manager. Set `<description>MOD_EXAMPLE_XML_DESCRIPTION</description>` to a key in the `.sys.ini` so the Modules listing is translatable.

---

## Service Provider

The wrapping pattern (`ServiceProviderInterface` + anonymous class + `register()` + `Container::registerServiceProvider()`) is shared across components, modules, and plugins. The universal pattern, what each extension type registers, and the common DI pitfalls live in [`references/service-provider.md`](service-provider.md). What's specific to modules is **which factories get registered** — `ModuleDispatcherFactory`, `HelperFactory`, and the generic `Module` provider — and the namespace prefixes the first two take.

**File:** `services/provider.php`

(Verified against [`mod_articles_news/services/provider.php` on `joomla-cms` `6.1-dev`](https://github.com/joomla/joomla-cms/blob/6.1-dev/modules/mod_articles_news/services/provider.php) — same factory set, same namespace-prefix shape.)

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Extension\Service\Provider\HelperFactory;
use Joomla\CMS\Extension\Service\Provider\Module;
use Joomla\CMS\Extension\Service\Provider\ModuleDispatcherFactory;
use Joomla\DI\Container;
use Joomla\DI\ServiceProviderInterface;

return new class () implements ServiceProviderInterface {
    public function register(Container $container): void
    {
        $container->registerServiceProvider(new ModuleDispatcherFactory('\\Vendor\\Module\\Example'));
        $container->registerServiceProvider(new HelperFactory('\\Vendor\\Module\\Example\\Site\\Helper'));
        $container->registerServiceProvider(new Module());
    }
};
```

The `ModuleDispatcherFactory` tells Joomla where to find your `Dispatcher` class.
The `HelperFactory` registers your helper so the dispatcher can inject it.

---

## Dispatcher

**File:** `src/Dispatcher/Dispatcher.php`

The dispatcher orchestrates the module's rendering pipeline: load language, gather data, include template.

(Base-class signatures verified against [`AbstractModuleDispatcher` on `joomla-cms` `6.1-dev`](https://github.com/joomla/joomla-cms/blob/6.1-dev/libraries/src/Dispatcher/AbstractModuleDispatcher.php). Constructor takes `(\stdClass $module, CMSApplicationInterface $app, Input $input)`; `getLayoutData()` returns `array|false` with `module`, `app`, `input`, `params`, `template` keys.)

```php
<?php

namespace Vendor\Module\Example\Site\Dispatcher;

\defined('_JEXEC') or die;

use Joomla\CMS\Dispatcher\AbstractModuleDispatcher;
use Joomla\CMS\Helper\HelperFactoryAwareInterface;
use Joomla\CMS\Helper\HelperFactoryAwareTrait;

class Dispatcher extends AbstractModuleDispatcher implements HelperFactoryAwareInterface
{
    use HelperFactoryAwareTrait;

    /**
     * Returns the layout data.
     *
     * The returned array is extracted into variables in the template file.
     * So 'items' becomes $items in default.php.
     */
    protected function getLayoutData(): array
    {
        $data = parent::getLayoutData();

        // Get data from the helper
        $data['items'] = $this->getHelperFactory()
            ->getHelper('ExampleHelper')
            ->getItems($data['params'], $this->getApplication());

        return $data;
    }
}
```

The `getLayoutData()` method is the key override point. The base method provides `$module`, `$app`, `$input`, `$params`, and `$template`. You add your own data on top.

### Web Asset Manager registration from the dispatcher

The dispatcher is the right place to register module-specific scripts and styles, before the template renders. Use the application's document and the Web Asset Manager:

```php
protected function getLayoutData(): array
{
    $data = parent::getLayoutData();

    $wa = $this->getApplication()->getDocument()->getWebAssetManager();
    $wa->useStyle('mod_example.style');
    $wa->useScript('mod_example.script');

    // Register a JS-loadable language string from the dispatcher
    \Joomla\CMS\Language\Text::script('MOD_EXAMPLE_LOADING');

    $data['items'] = $this->getHelperFactory()
        ->getHelper('ExampleHelper')
        ->getItems($data['params'], $this->getApplication());

    return $data;
}
```

The asset names (`mod_example.style`, `mod_example.script`) come from the module's `media/joomla.asset.json`; Joomla auto-resolves the URI to `media/mod_example/css/style.css` and `media/mod_example/js/script.js`. See `references/gotchas.md` § "WAM URI Auto-Resolution" for the path-resolution rules and the `media/vendor/...` exception for non-standard asset paths.

`Text::script()` registration must happen here, before the template loads — otherwise `Joomla.Text._('MOD_EXAMPLE_LOADING')` returns the raw key. See `references/gotchas.md` for the truthy-key trap.

---

## Helper Class

**File:** `src/Helper/ExampleHelper.php`

The helper handles data retrieval and business logic, keeping it separate from display concerns.

```php
<?php

namespace Vendor\Module\Example\Site\Helper;

\defined('_JEXEC') or die;

use Joomla\CMS\Application\CMSApplicationInterface;
use Joomla\Database\DatabaseAwareTrait;
use Joomla\Registry\Registry;

class ExampleHelper
{
    use DatabaseAwareTrait;

    /**
     * Retrieves items to display in the module.
     *
     * @param   Registry                  $params  Module parameters
     * @param   CMSApplicationInterface   $app     Application instance
     *
     * @return  array  List of items
     */
    public function getItems(Registry $params, CMSApplicationInterface $app): array
    {
        $count = (int) $params->get('count', 5);

        $db    = $this->getDatabase();
        $query = $db->createQuery()
            ->select($db->quoteName(['id', 'title', 'alias']))
            ->from($db->quoteName('#__example_items'))
            ->where($db->quoteName('published') . ' = 1')
            ->order($db->quoteName('created') . ' DESC')
            ->setLimit($count);

        $db->setQuery($query);

        return $db->loadObjectList() ?: [];
    }
}
```

---

## Template (Layout)

**File:** `tmpl/default.php`

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Language\Text;

/**
 * Variables available from Dispatcher::getLayoutData():
 *
 * @var \Joomla\Registry\Registry              $params    Module parameters
 * @var \stdClass                               $module    Module object
 * @var \Joomla\CMS\Application\SiteApplication $app       Application
 * @var array                                   $items     Items from helper
 */

if (empty($items)) {
    return;
}

?>
<div class="mod-example <?php echo htmlspecialchars($params->get('moduleclass_sfx', ''), ENT_QUOTES, 'UTF-8'); ?>">
    <ul>
        <?php foreach ($items as $item) : ?>
            <li>
                <a href="<?php echo \Joomla\CMS\Router\Route::_(
                    'index.php?option=com_example&view=item&id=' . $item->id
                ); ?>">
                    <?php echo htmlspecialchars($item->title, ENT_QUOTES, 'UTF-8'); ?>
                </a>
            </li>
        <?php endforeach; ?>
    </ul>
</div>
```

---

## Caching

Joomla caches module output between requests when the **module instance** has caching enabled (admin → Modules → your module → `Advanced` → `Caching` = `Use global` or `Yes`). The cache is keyed per module instance plus a per-module **cache id** that the dispatcher's flow doesn't override unless you ask it to.

For most modules the default keying is fine: same params + same user + same page = same cached output. Two cases you have to handle yourself:

- **Output that depends on the URL beyond `Itemid`** (e.g., the current article's id): pass a custom modifier through the `cache_id` channel, or set `cache_lifetime` to `0` if the output truly can't be cached safely.
- **Output that depends on session state** (per-user data, recently-viewed lists): set the manifest's `<config>` so the user can disable caching, and document that Use global / Yes will produce stale data for them.

There is no current public hook to customize the cache key from the dispatcher; for instance-level cache control, declare the relevant fields in `<config>` and let admins flip the switch.

---

## Install Script (Optional)

Modules **rarely** need a `<scriptfile>` — most ship without one. Add a script only when you need an environment check beyond what Joomla enforces, an asset-directory pre-creation, or any cleanup on uninstall that Joomla won't do automatically (e.g., custom rows your module wrote at runtime).

When you do need one, the lifecycle hooks (`preflight`, `install`, `update`, `postflight`, `uninstall`) and the class-naming convention (`Mod_<Element>InstallerScript`) are **shared with components and plugins**. The full pattern, hook signatures, and example skeletons live in [`references/install-script.md`](install-script.md).

---

## Admin Module

For admin-side modules, the structure is identical but:

- Manifest uses `client="administrator"`
- Namespace typically uses `Administrator` instead of `Site`:
  ```xml
  <namespace path="src">Vendor\Module\Example</namespace>
  ```
  And the Dispatcher lives under the `Administrator` sub-namespace.
- Placed in `administrator/modules/` when installed

In practice, larger Joomla projects often ship modules under both `modules/admin/` and `modules/site/` in the same source tree, so the build can package admin and site variants from one repo.

---

## Joomla 6.1 capabilities

Two module-relevant additions shipped in Joomla 6.1 ([release milestone](https://github.com/joomla/joomla-cms/milestone/148?closed=1), released 2026-04-14):

- **Versions for Modules** ([PR #46772](https://github.com/joomla/joomla-cms/pull/46772)) — modules now participate in the UCM versioning history (`#__ucm_history`), so admins can see and revert past module-instance configurations the same way they can for articles and categories. Nothing in your module's code needs to change; the capability is plumbed at the core Modules administrator level. Worth knowing because user expectations shift: "where's the version history for this module" is now a reasonable question.
- **`#__extensions.custom_data`** ([PR #46622](https://github.com/joomla/joomla-cms/pull/46622)) — components, menus, modules, and template styles all gained a `custom_data` JSON column on `#__extensions`. Use it for arbitrary per-extension metadata that doesn't belong in `params` (which is user-facing) — e.g., post-install bookkeeping, telemetry opt-ins, or feature flags scoped to a single installed instance. Read/write via `Factory::getContainer()->get('DatabaseDriver')` against the `#__extensions` row keyed by your module's `extension_id`.

Neither feature changes the patterns in this reference; both are additive. A future revision can add a worked example for `custom_data` if a clear use case emerges.
