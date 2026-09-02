# Joomla 5/6 Common Gotchas & Pitfalls

Hard-won lessons from real Joomla 5/6 extension development. These are easy to get wrong because IDE autocompletion, documentation gaps, or reasonable assumptions lead you astray.

## BaseController vs FormController — Choose the Right Parent

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

## Controller API Differences (Joomla 5)

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

## Event Dispatching (Joomla 5 Compatibility)

Typed event classes (`ContentPrepareEvent`, etc.) with `->getResult()` are **NOT available in Joomla 5**. If your extension must support J5:

```php
// WRONG on Joomla 5 — typed events don't exist
$event = new ContentPrepareEvent('onContentPrepare', ['context' => $context, 'subject' => $item]);
$this->getDispatcher()->dispatch($event->getName(), $event);
$results = $event->getResult();

// CORRECT for J5 compatibility — returns results directly as array
$results = $app->triggerEvent('onContentPrepare', [$context, &$item, &$params, $page]);
```

## Plugin Manifest Naming

Plugin manifest files **must** be named `{element}.xml` (matching the plugin element name) for discover install to work. For example, a plugin with element `example` must have `example.xml`, not `plg_content_example.xml`.

**CRITICAL:** Having both `example.xml` AND `plg_content_example.xml` in the plugin directory causes Joomla's Discover to create duplicate extension records. Only the `{element}.xml` file should exist in the source. The build/packaging process can rename to `plg_{group}_{element}.xml` for the installable ZIP if needed by the installer.

## Plugin Language Files

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

## Task Plugin Language Keys

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

## Plugins Load Under the Console Application

`Joomla\CMS\Application\ConsoleApplication` (the `php cli/joomla.php` runtime) imports the `behaviour`, `system`, and `console` plugin groups on every invocation, and `scheduler:run` additionally imports every **task** plugin just to list the routines they offer. So a system or task plugin's constructor — and any bootstrap file it `require`s — executes under the console, where there is **no document**: `ConsoleApplication` implements `CMSApplicationInterface` but not `CMSWebApplicationInterface`, and `getDocument()` does not exist.

The failure is a fatal `Call to undefined method ConsoleApplication::getDocument()` that kills the whole CLI process before any command runs — including Joomla's own scheduled tasks, on every site that has the extension installed. Nothing on the web ever trips it, so it ships.

```php
// api.php / bootstrap required from a plugin constructor
$app = Factory::getApplication();

// WRONG — fatal under php cli/joomla.php
$wa = $app->getDocument()->getWebAssetManager();

// RIGHT — CMSWebApplicationInterface is what declares getDocument()
if ($app instanceof \Joomla\CMS\Application\CMSWebApplicationInterface) {
    $wa = $app->getDocument()->getWebAssetManager();
    $wa->getRegistry()->addExtensionRegistryFile('com_myext');
}
```

Same guard for `getMenu()`, `getPathway()`, and `getTemplate()` — all web-only. Keep plugin constructors side-effect free and move asset registration into the component's dispatcher or the view. The full list of what differs under the CLI is in [`console-commands.md`](console-commands.md) § What Is Different Under the Console.

## Web Services API Loads Language Files From api/, Not administrator/

Under `ApiApplication`, `JPATH_BASE` is the `api/` directory, and `ComponentDispatcher::loadLanguage()` only looks in `api/language/` and `api/components/com_example/language/`. The admin `.ini` is never loaded. Nothing fails — but every `COM_EXAMPLE_*` string the API touches comes back raw, and the place you notice is a **400 validation error** whose messages are the admin form's language keys (`COM_EXAMPLE_FIELD_TITLE_REQUIRED`) instead of text.

```php
// api/src/Controller/ItemsController.php
public function __construct($config = [], ?MVCFactoryInterface $factory = null, ?CMSWebApplicationInterface $app = null, ?Input $input = null)
{
    parent::__construct($config, $factory, $app, $input);

    // The admin form's validation messages live in the admin language file.
    $this->app->getLanguage()->load('com_example', JPATH_ADMINISTRATOR);
}
```

Full API reference in [`webservices-api.md`](webservices-api.md).

## Always Use AdminModel + Table for CRUD

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

## List-to-Edit Links Must Use task= Routing

Links from list views to edit views **must** use `task={entity}.edit&id=X`, NOT `view={entity}&layout=edit&id=X`:

```php
// WRONG — bypasses FormController, no checkout, broken session state
Route::_('index.php?option=com_mycomponent&view=item&layout=edit&id=' . $item->id)

// CORRECT — routes through FormController::edit()
Route::_('index.php?option=com_mycomponent&task=item.edit&id=' . $item->id)
```

`FormController::edit()` handles setting the layout, checking out the record, and managing the user state.

## Load form.validate for Form Views

Any view that renders a form with `class="form-validate"` **must** load the `form.validate` web asset, or `Joomla.submitbutton()` will throw an `isValid` error:

```php
// In HtmlView::display()
$this->getDocument()->getWebAssetManager()->useScript('form.validate');
```

## Table::check() and DatabaseModel::fix()

- In `Table::check()`, throw `\UnexpectedValueException` with `Text::_()` language keys for validation errors
- `DatabaseModel::fix()` only executes **DDL** (ALTER TABLE, CREATE INDEX, etc.) — use PHP migration steps for **DML** (INSERT, UPDATE, DELETE data changes)

## HTTP Client Class

`Joomla\CMS\Http\HttpFactory::getHttp()` is the correct way to get an HTTP client. **`Joomla\Http\HttpFactory` does NOT exist** — IDE autocompletion may suggest the wrong namespace. Don't let the linter "fix" this import.

```php
// CORRECT
use Joomla\CMS\Http\HttpFactory;
$http = HttpFactory::getHttp();

// WRONG — this class does not exist
use Joomla\Http\HttpFactory;
```

## Registry::get() Defaults

`$params->get('key')` returns `null` when the key is missing from the stored JSON (common with component/module params). **Always provide a default:**

```php
// Dangerous — returns null if 'items_per_page' was never saved
$limit = $params->get('items_per_page');

// Safe — explicit default
$limit = $params->get('items_per_page', 10);
```

## Text::script() Registration Location

JavaScript language strings via `Joomla.Text._('KEY')` only work if the key was registered server-side with `Text::script()`. Register in the right place:

- **Components**: Register in `HtmlView::display()` before the template renders
- **Modules**: Register in `Dispatcher::dispatch()` before the module template loads

```php
// In HtmlView::display() or Dispatcher::dispatch()
Text::script('COM_MYCOMPONENT_CONFIRM_DELETE');
Text::script('COM_MYCOMPONENT_SAVING');
```

## Joomla.Text._() Returns Raw Key When Unregistered

`Joomla.Text._('SOME_KEY')` returns the raw key string (e.g., `"SOME_KEY"`) when the key was never registered — this is **truthy**, so a fallback pattern like `Joomla.Text._('KEY') || 'fallback'` will never fire the fallback. Compare against the key itself:

```javascript
// WRONG — fallback never fires because unregistered keys return the key string (truthy)
const msg = Joomla.Text._('COM_MYCOMP_LABEL') || 'Default Label';

// CORRECT — detect missing registration
const key = 'COM_MYCOMP_LABEL';
const translated = Joomla.Text._(key);
const msg = (translated !== key) ? translated : 'Default Label';
```

## joomla-field-fancy-select: setValue Replaces, setChoiceByValue Appends

The `joomla-field-fancy-select` web component wraps Choices.js. Get the wrapper from `field.choicesInstance` (where `field = element.closest('joomla-field-fancy-select')`). The library exposes two selection APIs that look interchangeable but behave very differently on multi-selects:

- `choices.setValue([{value, label}])` — **replaces** the entire current selection with the array
- `choices.setChoiceByValue(value)` — **appends** to the current selection

Looping over checked checkboxes and calling `setValue([...])` per iteration leaves only the last entry visible (or none, if value matching silently fails). Use `setChoiceByValue` for batch additions. The failure mode is silent — no console error, click handler completes cleanly.

```javascript
// WRONG — each iteration replaces the prior selection, only the last item survives
checked.forEach((cb) => {
    choices.setValue([{ value: cb.value, label: cb.dataset.label }]);
});

// CORRECT — append per item
checked.forEach((cb) => {
    choices.setChoiceByValue(cb.value);
});
```

To diagnose: in DevTools console call `choices.setChoiceByValue('some-value')` directly. If the selection grows by one, the loop site is using the wrong API.

## Batch Task Routing

`AdminController` (the plural list controller) does **NOT** have a `batch()` method. Only `FormController` (the singular edit controller) has it. If batch operations aren't working, check that your form controller exists and is being routed correctly.

## Router Registration (CRITICAL — 3 Parts Required)

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

## Hidden Menu Items for SEF Routing

`Route::_()` uses `SiteMenu::getItems()` which filters by the current user's access levels. For components that require login, the routing menu items **must** have access level `1` (Public) — not `2` (Registered).

With `access=2`, guests can't resolve SEF URLs, so `Route::_()` fails and appends `?view=xxx` to the wrong base URL. The component's controller still enforces login — Public access on the menu item only affects URL resolution.

Components should create a hidden menu type during install with menu items for each site view:
- Menu type is not assigned to any module (invisible to visitors)
- Each view gets a published menu item with `access=1`
- `Route::_('index.php?option=com_mycomponent&view=items')` resolves to `/items` via the hidden menu item

## SEF Router Callback Naming

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

## WAM URI Auto-Resolution

In `joomla.asset.json`, do **NOT** include `css/` or `js/` subdirectories in asset URIs. Joomla auto-resolves them:

```json
{
  "name": "com_mycomponent.admin",
  "type": "style",
  "uri": "com_mycomponent/admin.css"
}
```

Joomla maps `com_mycomponent/admin.css` → `media/com_mycomponent/css/admin.css` automatically. Including the subdirectory (`com_mycomponent/css/admin.css`) causes a 404.

## WAM Asset Naming Collisions

Asset `name:` values in `joomla.asset.json` are the lookup key for `$wa->useStyle()` / `$wa->useScript()`. The Joomla convention is `com_<extension>.<variant>` (or `mod_*` / `plg_*.*` / `vendor.*`):

```json
{
  "name": "com_mycomponent.admin",
  "type": "style",
  "uri": "com_mycomponent/admin.css"
}
```

```php
$wa->useStyle('com_mycomponent.admin');  // must match name: exactly
```

If the name doesn't exist, `useStyle()` / `useScript()` throw `UnknownAssetException` — loud and fatal, easy to spot.

The silent failure mode is **name collisions**. Asset names are scoped per type (`script`, `style`) and shared across the whole Joomla install — no per-extension namespace. If two `joomla.asset.json` files (or a layout / template registry) both register a `style` named `vendor.fancybox`, `WebAssetRegistry::add()` overwrites the first registration with the second (`libraries/src/WebAsset/WebAssetRegistry.php:171`) and dispatches a `WebAssetRegistry::ASSET_CHANGED` event of type `override`. No exception, no log entry by default. To avoid: prefix vendor / shared assets with the extension name (e.g., `com_mycomponent.fancybox`) to scope them.

## WAM Non-Standard Paths

Vendor assets stored outside the standard `media/com_*/` structure (e.g., `media/fancybox/`, `media/vendor/`) **cannot use auto-resolution**. Use a full literal path instead:

```php
$wa->registerAndUseScript('vendor.fancybox', 'media/fancybox/fancybox.umd.js');
$wa->registerAndUseStyle('vendor.fancybox', 'media/fancybox/fancybox.css');
```

## WAM Inline Assets

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

## Dark Mode (Bootstrap 5.3)

Joomla 5+ admin uses Bootstrap 5.3 dark mode via `data-bs-theme="dark"` on `<html>`. When writing admin templates:

- **NEVER** use `bg-light` — it stays white in dark mode
- **NEVER** use `btn-outline-*` — very low contrast against dark backgrounds. Use solid `btn-*` variants instead (e.g., `btn-primary` not `btn-outline-primary`)
- Use color-adaptive classes: `bg-body-secondary`, `bg-body-tertiary`, `border rounded`
- Replace `text-muted` with `text-body-secondary`
- Test your templates with both light and dark modes enabled

## Bootstrap 5 Dynamic Modal Cleanup

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

## Cross-Browser Popup Windows

When an extension needs to open content in a new window (print views, share previews, generated documents), neither `data:` URIs nor `URL.createObjectURL()` is portable:

- **Chrome blocks `data:` URIs** in `window.open()` as a phishing-mitigation measure
- **Safari has historically lacked / restricted `createObjectURL()`** for opened-window contexts

The portable pattern is to open an empty window and inject server-rendered HTML from a `<template>` element on the source page via DOM (avoid `document.write` — modern browsers warn on it):

```php
// In your HtmlView, render the popup content into a template:
?>
<template id="popup-content">
    <?php echo $this->loadTemplate('popup'); ?>
</template>
```

```javascript
// On the trigger (button, link), open empty and inject via DOM:
document.getElementById('open-popup').addEventListener('click', () => {
    const popup = window.open('', '_blank', 'width=800,height=600');
    if (!popup) return; // popup blocker

    const template = document.getElementById('popup-content');
    popup.document.documentElement.innerHTML = template.innerHTML;
});
```

The `<template>` should contain a complete `<html>...<head>...<body>...</body></html>` structure so the popup receives full markup. This works in Chrome, Safari, and Firefox without `data:` URIs, blob URLs, or server-side popup endpoints.

## getStoreId() in ListModel

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
