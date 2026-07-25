# Joomla Component Advanced Features Reference

Advanced component-level features beyond core MVC: toolbar API, batch processing, drag-drop ordering, tags, content versioning, workflow integration, the webservices API plugin, mail templates, dashboard views, and custom form validation rules.

## Toolbar API (Modern Pattern)

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

## Batch Processing

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

## Ordering / Drag-Drop Reordering

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

## Tags Integration

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

## Content Versioning (History)

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

## Workflow Integration

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

## Webservices API Plugin

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

`ComponentAdapter` reads `$manifest->api->files` and installs it to
`JPATH_API/components/com_example`. Without this element the classes are never
copied there, and since Joomla resolves `Vendor\Component\Example\Api\` to that
path, **every route 404s even though the plugin registered it**. Core components
are no help as a reference here — they ship their api files with the CMS rather
than through the installer, so none of them carry an `<api>` element.

Note also that the API application has **no document**. A bootstrap file that
calls `$app->getDocument()` (for the web asset manager, say) cannot run there, so
anything it sets up — including logger registration — is absent from API requests.

### API access is gated TWICE — both default to Super Users

The most common cause of "my token is valid but every call returns 401". Both
gates must pass, and they live in different screens:

| gate | where | default |
|---|---|---|
| Allowed User Groups | *Plugins → User - Joomla API Token* | Super Users |
| `core.login.api` | *Global Configuration → Permissions* | Super Users (`{"8":1}` on the root asset) |

The auth plugin reads the first via
`getPluginParameter('user', 'token', 'allowedUserGroups', [8])`. Note that an
**empty** value means *allow all groups*, not *allow none*.

Adding a group in the plugin is necessary but not sufficient — `core.login.api`
is a separate ACL grant, and nothing in the UI hints that it is the thing
refusing the request. A least-privilege integration needs three steps:

1. Add the group in the User - Joomla API Token plugin
2. Grant `core.login.api` to that group in Global Configuration
3. Scope that group's component permissions — otherwise the key is a Super User

Consequence worth knowing when testing: on a stock install everyone who *can*
authenticate is a Super User, so the per-verb checks below always pass and never
get exercised.

### Permission required per operation

| operation | requires |
|---|---|
| authenticate at all | `core.login.api` **and** an allowed user group |
| `GET` | nothing extra when routes are registered `public`; otherwise a token |
| `POST` | `core.create` |
| `PATCH` | `core.edit` |
| `DELETE` | `core.delete` |

`ApiController` throws `Joomla\CMS\Access\Exception\NotAllowed` (403) for the
write checks — catchable if you want to record refused attempts.

### Read-side ACL is YOUR job

`ApiController` enforces nothing on reads. The list model is what stands between
an anonymous caller and restricted rows, so every model backing an API route
needs the view-level filter:

```php
$user = $this->getCurrentUser();

if (!$user->authorise('core.admin')) {
    $query->whereIn($db->quoteName('a.access'), $user->getAuthorisedViewLevels());
}
```

Miss it on one model and that resource publishes rows the caller could not see in
the site itself. Audit **every** model you expose, not just the new ones — a model
written for admin-only use has never needed this.

Equally, `fieldsToRenderItem` / `fieldsToRenderList` are the only thing
withholding columns the query already selected. If a table keeps credentials or
personal data in a `params` blob or an email column, omitting it from those arrays
is the control — the item query typically loads the whole row.

### Testing an API locally

Token format is `base64("<algo>:<userId>:<hmac>")` where the HMAC is
`hash_hmac($algo, base64_decode($storedSeed), $app->get('secret'))`. The seed
lives in `#__user_profiles` under `joomlatoken.token`, stored **raw** — not
JSON-encoded — alongside `joomlatoken.enabled`.

Apache/CGI setups (MAMP included) commonly strip the `Authorization` header
before PHP sees it. The token plugin also accepts `X-Joomla-Token`, which avoids
the problem entirely:

```bash
curl -H "X-Joomla-Token: $TOKEN" https://site.local/api/index.php/v1/example/items
```

### Failed API auth is not logged by core

`ApiApplication` authenticates with `login(['username' => ''])` — token auth has
no username. `plg_actionlog_joomla::onUserLoginFailure` looks the user up *by
username* and returns when it finds none, so a bad token produces a 401 and **no
action-log entry**. If you need a record of refused API calls you must add it
yourself; the web server access log is otherwise the only trace.

## Mail Templates

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

## Dashboard Views

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

## Custom Form Validation Rules

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
