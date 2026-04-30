# Joomla 5+ Plugin Reference

## Table of Contents
1. [Directory Structure](#directory-structure)
2. [Manifest XML](#manifest-xml)
3. [Service Provider](#service-provider)
4. [Plugin Class with SubscriberInterface](#plugin-class)
5. [Common Plugin Groups](#common-plugin-groups)
6. [Event Examples](#event-examples)

---

## Directory Structure

```
plg_content_example/
├── example.xml                    # Manifest (named after plugin, not group)
├── services/
│   └── provider.php               # DI container registration
├── src/
│   └── Extension/
│       └── Example.php            # Plugin class
├── language/
│   └── en-GB/
│       └── plg_content_example.ini
└── media/                         # Optional
    └── joomla.asset.json
```

---

## Manifest XML

```xml
<?xml version="1.0" encoding="utf-8"?>
<extension type="plugin" group="content" method="upgrade">
    <name>plg_content_example</name>
    <author>Your Name</author>
    <version>1.0.0</version>
    <creationDate>2026-01-01</creationDate>
    <description>PLG_CONTENT_EXAMPLE_XML_DESCRIPTION</description>
    <namespace path="src">Vendor\Plugin\Content\Example</namespace>

    <files>
        <folder>services</folder>
        <folder>src</folder>
        <folder>language</folder>
    </files>

    <languages folder="language">
        <language tag="en-GB">en-GB/plg_content_example.ini</language>
    </languages>

    <media destination="plg_content_example" folder="media">
        <filename>joomla.asset.json</filename>
    </media>

    <config>
        <fields name="params">
            <fieldset name="basic">
                <field
                    name="show_title"
                    type="radio"
                    label="PLG_CONTENT_EXAMPLE_SHOW_TITLE"
                    default="1"
                    class="btn-group"
                >
                    <option value="0">JNO</option>
                    <option value="1">JYES</option>
                </field>
            </fieldset>
        </fields>
    </config>
</extension>
```

Key points:
- `type="plugin"` and `group="content"` in the extension tag
- Namespace includes the group: `Vendor\Plugin\Content\Example`
- Manifest filename matches the plugin name (not the group)

---

## Service Provider

**File:** `services/provider.php`

The Joomla 6.1+ pattern: instantiate the plugin with **just** `(array) PluginHelper::getPlugin($group, $element)`. Don't pass a dispatcher — `CMSPlugin::__construct()` no longer accepts one (see the J6.0 → J6.1 callout below).

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Extension\PluginInterface;
use Joomla\CMS\Factory;
use Joomla\CMS\Plugin\PluginHelper;
use Joomla\DI\Container;
use Joomla\DI\ServiceProviderInterface;
use Vendor\Plugin\Content\Example\Extension\Example;

return new class () implements ServiceProviderInterface {
    public function register(Container $container): void
    {
        $container->set(
            PluginInterface::class,
            function (Container $container) {
                $plugin = new Example(
                    (array) PluginHelper::getPlugin('content', 'example')
                );
                $plugin->setApplication(Factory::getApplication());

                return $plugin;
            }
        );
    }
};
```

### Joomla 6.0 / 6.1 / 7.0 — dispatcher constructor change

**Before (J5 and J6.0):** `CMSPlugin::__construct(DispatcherInterface $dispatcher, array $config = [])`. Service providers had to fetch the application dispatcher and pass it as the first argument:

```php
// Legacy two-arg form — works on J5 and J6.0, deprecated on J6.1+, removed in J7.0
$dispatcher = $container->get(DispatcherInterface::class);
$plugin     = new Example($dispatcher, (array) PluginHelper::getPlugin('content', 'example'));
```

**After (J6.1+):** `CMSPlugin::__construct($config = [])`. The dispatcher is no longer a constructor concern — `SubscriberInterface` plugins register their listeners on the application's main dispatcher via `getSubscribedEvents()`, no per-plugin dispatcher reference required.

If you call the legacy two-arg form on J6.1, `CMSPlugin` still accepts it but emits `E_USER_DEPRECATED`:

> Passing an instance of `Joomla\Event\DispatcherInterface` to `Joomla\CMS\Plugin\CMSPlugin::__construct()` will not be supported in 7.0.

(verified against [`libraries/src/Plugin/CMSPlugin.php` on `joomla-cms` `6.1-dev`](https://github.com/joomla/joomla-cms/blob/6.1-dev/libraries/src/Plugin/CMSPlugin.php))

**If your plugin needs to dispatch its own events** (rare — the typical `SubscriberInterface` flow doesn't need this), implement `Joomla\Event\DispatcherAwareInterface` on the plugin class directly and inject the dispatcher with `$plugin->setDispatcher($container->get(DispatcherInterface::class))` from the service provider. Don't rely on `CMSPlugin` providing it; that wiring is being removed in 7.0.

**Backward-compat with J5 / J6.0:** if your extension must support pre-6.1, keep the legacy two-arg form and accept the deprecation warning on J6.1. There is no single call form that works cleanly across 5.x, 6.0, and 6.1+. Pick the floor your extension targets.

---

## Plugin Class with SubscriberInterface

**File:** `src/Extension/Example.php`

The modern Joomla 5 pattern uses `SubscriberInterface` for explicit event subscription:

```php
<?php

namespace Vendor\Plugin\Content\Example\Extension;

\defined('_JEXEC') or die;

use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\Event\SubscriberInterface;

final class Example extends CMSPlugin implements SubscriberInterface
{
    /**
     * Returns an array of events this subscriber will listen to.
     *
     * @return array<string, string>
     */
    public static function getSubscribedEvents(): array
    {
        return [
            'onContentPrepare'      => 'onContentPrepare',
            'onContentAfterTitle'   => 'onContentAfterTitle',
            'onContentAfterSave'    => 'onContentAfterSave',
            'onContentBeforeDelete' => 'onContentBeforeDelete',
        ];
    }

    /**
     * Fires when content is being prepared for display.
     */
    public function onContentPrepare(string $context, object &$article, object &$params, int $page = 0): void
    {
        // Only process com_content articles
        if ($context !== 'com_content.article') {
            return;
        }

        // Modify article text
        $article->text = str_replace('{example}', $this->getRenderedOutput(), $article->text);
    }

    public function onContentAfterTitle(string $context, object &$article, object &$params, int $page = 0): string
    {
        if ($context !== 'com_content.article') {
            return '';
        }

        return '<div class="example-after-title">Custom content after title</div>';
    }

    public function onContentAfterSave(string $context, object $article, bool $isNew): void
    {
        if ($context !== 'com_content.article') {
            return;
        }

        // Perform actions after content is saved
        // e.g., update search index, send notification
    }

    public function onContentBeforeDelete(string $context, object $article): void
    {
        if ($context !== 'com_content.article') {
            return;
        }

        // Clean up related data before deletion
    }

    private function getRenderedOutput(): string
    {
        $showTitle = (bool) $this->params->get('show_title', true);

        return '<div class="example-plugin">'
            . ($showTitle ? '<h3>Example</h3>' : '')
            . '</div>';
    }
}
```

---

## Common Plugin Groups

| Group | Purpose | Common Events |
|-------|---------|--------------|
| **content** | Modify/process content | `onContentPrepare`, `onContentAfterSave`, `onContentBeforeDelete` |
| **system** | System-wide hooks | `onAfterInitialise`, `onAfterRoute`, `onBeforeRender`, `onAfterRender` |
| **finder** | Smart Search indexing | `onFinderAfterSave`, `onFinderAfterDelete`, `onFinderCategoryChangeState` |
| **task** | Scheduled tasks (cron) | `onTaskOptionsList`, `onExecuteTask` |
| **webservices** | API route registration | `onBeforeApiRoute` |
| **schemaorg** | Structured data | `onSchemaPrepare` |
| **user** | User lifecycle | `onUserAfterSave`, `onUserAfterDelete`, `onUserLogin`, `onUserLogout` |
| **installer** | Extension install events | `onInstallerBeforeInstallation`, `onInstallerAfterInstaller` |
| **editors** | WYSIWYG editors | `onInit`, `onSave`, `onGetContent` |
| **editors-xtd** | Editor buttons | `onDisplay` |

---

## Event Examples

### Finder Plugin (Smart Search)

```php
public static function getSubscribedEvents(): array
{
    return [
        'onFinderAfterSave'            => 'onFinderAfterSave',
        'onFinderAfterDelete'          => 'onFinderAfterDelete',
        'onFinderCategoryChangeState'  => 'onFinderCategoryChangeState',
    ];
}
```

### Task Plugin (Scheduled Jobs)

```php
use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\Component\Scheduler\Administrator\Event\ExecuteTaskEvent;
use Joomla\Component\Scheduler\Administrator\Task\Status as TaskStatus;
use Joomla\Component\Scheduler\Administrator\Traits\TaskPluginTrait;
use Joomla\Event\SubscriberInterface;

final class MyTask extends CMSPlugin implements SubscriberInterface
{
    use TaskPluginTrait;

    protected const TASKS_MAP = [
        'my_task.cleanup' => [
            'langConstPrefix' => 'PLG_TASK_MYTASK_CLEANUP',
            'method'          => 'doCleanup',
            'form'            => 'cleanup_params',  // Optional: form XML for task params
        ],
    ];

    // TaskPluginTrait uses langConstPrefix to build:
    //   {langConstPrefix}_TITLE  — displayed as the task type name
    //   {langConstPrefix}_DESC   — displayed as the task type description
    // So the .ini file must contain:
    //   PLG_TASK_MYTASK_CLEANUP_TITLE="Database Cleanup"
    //   PLG_TASK_MYTASK_CLEANUP_DESC="Removes expired records from the database"

    public static function getSubscribedEvents(): array
    {
        return [
            'onTaskOptionsList'    => 'advertiseRoutines',
            'onExecuteTask'        => 'standardRoutineHandler',
        ];
    }

    private function doCleanup(ExecuteTaskEvent $event): int
    {
        // Perform cleanup logic
        return TaskStatus::OK;
    }
}
```

### Webservices Plugin (API Routes)

```php
use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\CMS\Router\ApiRouter;
use Joomla\Event\SubscriberInterface;

final class MyApi extends CMSPlugin implements SubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            'onBeforeApiRoute' => 'onBeforeApiRoute',
        ];
    }

    public function onBeforeApiRoute(&$router): void
    {
        /** @var ApiRouter $router */
        $router->createCRUDRoutes(
            'v1/example/items',
            'items',
            ['component' => 'com_example']
        );
    }
}
```
