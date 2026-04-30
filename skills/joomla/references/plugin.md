# Joomla 5+ Plugin Reference

## Table of Contents
1. [Directory Structure](#directory-structure)
2. [Manifest XML](#manifest-xml) — universal elements in [`manifest.md`](manifest.md)
3. [Language Files](#language-files) — full conventions in [`language-files.md`](language-files.md)
4. [Service Provider](#service-provider) — universal pattern in [`service-provider.md`](service-provider.md)
5. [Plugin Class with SubscriberInterface](#plugin-class-with-subscriberinterface)
6. [Common Plugin Groups](#common-plugin-groups)
7. [Event Examples](#event-examples)
8. [Install Script (Optional)](#install-script-optional) — full walkthrough in [`install-script.md`](install-script.md)
9. [Common Pitfalls](#common-pitfalls) — see also [`gotchas.md`](gotchas.md)

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

For the **universal** elements in every extension manifest (`<extension>` root attributes, the metadata block, `<files>`, `<media>`, `<languages>`, `<scriptfile>`, `<update>` / `<updateservers>`) see [`references/manifest.md`](manifest.md). Plugin-specific bits in the example below: the `group="<group>"` attribute on `<extension>`, and the `<config>` block where plugin params are declared.

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
        <language tag="en-GB">en-GB/en-GB.plg_content_example.ini</language>
        <language tag="en-GB">en-GB/en-GB.plg_content_example.sys.ini</language>
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
- Manifest filename **must** be `<element>.xml` (here `example.xml`), not `plg_<group>_<element>.xml`. Discover-install will create duplicate extension records if both exist. See [`gotchas.md`](gotchas.md) § Plugin Manifest Naming.
- Language files in the source tree are **locale-prefixed** (`en-GB.plg_content_example.ini`, not `plg_content_example.ini`); the `<language>` path includes the prefix. See [`language-files.md`](language-files.md) for the full naming/location rules.

---

## Language Files

Plugins use the `PLG_<GROUP>_<ELEMENT>_*` key prefix and ship two `.ini` files: `en-GB.plg_content_example.ini` for runtime strings (event handlers, error messages) and `.sys.ini` for the install-time + Plugins-list strings (description, `<config>` field labels).

The full conventions — file naming, plurals, `_FIELD_<NAME>_LABEL` / `_DESC` form-field pattern, `Text::script()` JS registration — are **shared across all extension types** and live in [`references/language-files.md`](language-files.md). Plugin-specific reminders:

- The plugin class **must** declare `protected $autoloadLanguage = true;` for Joomla to load language files from the plugin's own `language/` directory at runtime. Without it, runtime keys render as raw `PLG_CONTENT_EXAMPLE_*` strings. See [`gotchas.md`](gotchas.md) § Plugin Language Files.
- Plugin language **filenames** in the source tree carry the locale prefix (`en-GB.plg_content_example.ini`); the `.ini` file under `administrator/language/en-GB/` Joomla maintains internally does not. The manifest's `<language>` path points at the source-tree filename.
- **Task plugin language keys** must include the `_TITLE` and `_DESC` suffixes that `TaskPluginTrait` appends to `langConstPrefix`. Missing those and the task-type selector renders the raw key. See [`gotchas.md`](gotchas.md) § Task Plugin Language Keys.

---

## Service Provider

The wrapping pattern (`ServiceProviderInterface` + anonymous class + `register()`) is shared across components, modules, and plugins; the universal pattern lives in [`references/service-provider.md`](service-provider.md). What's specific to plugins is that they don't use any `Service\Provider\*` factory shorthand — the provider just `new`s the plugin class with its `$config` array and binds the result under `PluginInterface`.

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
     * Required for Joomla to load language files from the plugin's own
     * language/ directory at runtime. Without it, PLG_CONTENT_EXAMPLE_*
     * keys render as raw strings.
     *
     * @var  boolean
     */
    protected $autoloadLanguage = true;

    /**
     * Returns an array of events this subscriber will listen to.
     *
     * Event names are strings — core Joomla 6.1 plugins use string keys here too
     * (verified against plg_content_pagebreak on 6.1-dev). Typed event classes
     * like ContentPrepareEvent live in Joomla\CMS\Event\Content\* and are useful
     * for handler method *parameter* types, not for the keys in this array.
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

### Other plugin groups (not covered in depth here)

Joomla 6.1 ships 24 plugin groups in total. Beyond the ten above, the rest serve narrower needs and aren't walked through in this skill — file an issue if you need depth on one. The wrapping pattern (`SubscriberInterface` + `getSubscribedEvents()` + handler methods) is identical; only the events and the trait/interface layer differ.

| Group | What it's for |
|-------|---------------|
| **fields** | Authoring **new custom-field types** that show up in components' field-XML pickers (this is the plugin side; the field-XML *consumption* side is in [`form-fields.md`](form-fields.md)) |
| **quickicon** | Admin dashboard icons + status checks (`onGetIcons`) |
| **workflow** | Content-state transition handlers (`onWorkflowBeforeTransition`, `onWorkflowAfterTransition`) — **component-side** workflow integration is documented in `SKILL.md` |
| **privacy** | GDPR consent + data export/erase requests |
| **multifactorauth** | MFA methods (replaces J4 `twofactorauth`) |
| **api-authentication** | Auth providers for the J4+ Web Services API (Bearer tokens, etc.) |
| **authentication** | Login auth providers (LDAP, OAuth, SSO) |
| **captcha** | Captcha providers (reCAPTCHA, hCaptcha, etc.) |
| **filesystem** | Filesystem adapters for the Media Manager (S3, custom remote stores) |
| **media-action** | Per-image actions inside the Media Manager (crop, resize, etc.) |
| **actionlog** | Custom entries in the User Actions Log |
| **sampledata** | Sample-data installers for distribution work |
| **behaviour** | Mostly home of the **J6 backward-compatibility plugin**; third-party use is rare |
| **extension** | Generic extension lifecycle hooks (rarely needed when `installer` group covers most cases) |

These are out of scope for the v0.x line because they're either niche or framework-internal. CLI / `joomla console` command authoring (commands ship inside components, not as a plugin group) is also out of scope here — file an issue if you want it added.

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

---

## Install Script (Optional)

Plugins **rarely** need a `<scriptfile>`. Add one only when you need an environment check beyond what Joomla enforces, must seed default `<config>` params, or have to clean up custom rows / files on uninstall.

When you do need one, the lifecycle hooks (`preflight`, `install`, `update`, `postflight`, `uninstall`) and the class-naming convention (`Plg<Group><Element>InstallerScript`, e.g., `PlgContentExampleInstallerScript`) are **shared with components and modules**. The full pattern, hook signatures, and example skeletons live in [`references/install-script.md`](install-script.md).

---

## Common Pitfalls

The first three are documented in detail in [`references/gotchas.md`](gotchas.md); they're listed here because they account for the bulk of "plugin installs but does nothing" reports.

- **Manifest filename must be `<element>.xml`** — `example.xml` for `plg_content_example`, NOT `plg_content_example.xml`. Discover-install creates duplicate `#__extensions` rows when both files exist in the source tree. The build step can rename to `plg_<group>_<element>.xml` for the installer ZIP if needed. See [`gotchas.md`](gotchas.md) § Plugin Manifest Naming.
- **Forgot `protected $autoloadLanguage = true;`** — runtime keys render as raw `PLG_*` strings. The `.sys.ini` (loaded by the installer + Plugins listing) still works without it; only the runtime `.ini` is gated.
- **Locale-prefixed source filename** — `language/en-GB/en-GB.plg_content_example.ini` in the source tree, not `language/en-GB/plg_content_example.ini`. Without the prefix Joomla can't resolve runtime keys even with `$autoloadLanguage = true`.
- **Class name / namespace / folder mismatch** — for `plg_content_example`: namespace `Vendor\Plugin\Content\Example`, class file `src/Extension/Example.php`, class name `Example`. All three have to agree or the autoloader silently fails and the plugin never instantiates.
- **Forgot `$plugin->setApplication(Factory::getApplication())` in the service provider** — most plugin code that calls `$this->getApplication()` will then null-dereference at runtime.
- **Two-arg constructor on J6.1+** — passing `DispatcherInterface` first emits `E_USER_DEPRECATED` and breaks in J7.0. See the J6.0/6.1/7.0 callout in the Service Provider section above.
- **Typed Event class confusion** — typed events (`ContentPrepareEvent`, etc.) are useful as handler **parameter types** (e.g., `public function onContentPrepare(ContentPrepareEvent $event): void`), but the **keys** in `getSubscribedEvents()` remain string event names (`'onContentPrepare'`). Core J6.1 plugins (verified: [`plg_content_pagebreak`](https://github.com/joomla/joomla-cms/blob/6.1-dev/plugins/content/pagebreak/src/Extension/PageBreak.php)) follow this same pattern. There's no `ContentEvent::ON_CONTENT_PREPARE` constant to import — the abstract `ContentEvent` base class deliberately doesn't define one.
