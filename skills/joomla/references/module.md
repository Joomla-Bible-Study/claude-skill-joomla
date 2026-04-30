# Joomla 5+ Module Reference

## Table of Contents
1. [Directory Structure](#directory-structure)
2. [Manifest XML](#manifest-xml)
3. [Service Provider](#service-provider)
4. [Dispatcher](#dispatcher)
5. [Helper Class](#helper-class)
6. [Template (Layout)](#template)

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

## Service Provider

**File:** `services/provider.php`

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
