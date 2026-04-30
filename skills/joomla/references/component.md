# Joomla 5+ Component Reference

## Table of Contents
1. [Manifest XML Template](#manifest-xml-template) — universal elements in [`manifest.md`](manifest.md)
2. [Language Files](#language-files) — full conventions in [`language-files.md`](language-files.md) (shared)
3. [Service Provider](#service-provider) — universal pattern in [`service-provider.md`](service-provider.md) (shared)
4. [Extension Class](#extension-class)
5. [Controller Patterns](#controller-patterns)
6. [Model Patterns](#model-patterns)
7. [Table Class](#table-class)
8. [View Patterns](#view-patterns) (incl. Other View Types: Json/Raw/Feed)
9. [Template Files](#template-files)
10. [Form XML](#form-xml)
11. [Custom Form Fields](#custom-form-fields)
12. [Router (SEF URLs)](#router-sef-urls) — full walkthrough in [`component-router.md`](component-router.md)
13. [Dispatcher](#dispatcher)
14. [Install/Update Script](#installupdate-script) — full walkthrough in [`install-script.md`](install-script.md) (shared with module/plugin)
15. [Database Schema & Migrations](#database-schema--migrations)
16. [Component Options (config.xml)](#component-options-configxml)
17. [Filter Form (Searchtools)](#filter-form-searchtools)
18. [Site Views](#site-views)
19. [Access Control (ACL)](#access-control)
20. [Webservices API Plugin](#webservices-api-plugin)

---

## Manifest XML Template

For the **universal** elements that appear in every extension type's manifest — `<extension>` root attributes, the metadata block, `<scriptfile>`, `<files>`, `<media>`, `<languages>`, `<update>`, `<updateservers>`, the update-server XML format — see [`references/manifest.md`](manifest.md). The example below is component-specific: it adds the `<install>` SQL block, `<update><schemas>` for migration paths, and the `<administration>` block with `<menu>` / `<submenu>` / a second `<files>` for the admin-side filesystem.

```xml
<?xml version="1.0" encoding="utf-8"?>
<extension type="component" method="upgrade">
    <name>com_example</name>
    <author>Your Name</author>
    <authorEmail>email@example.com</authorEmail>
    <authorUrl>www.example.com</authorUrl>
    <copyright>(C) 2026 Your Name. All rights reserved.</copyright>
    <version>1.0.0</version>
    <creationDate>Jan 1, 2026</creationDate>
    <license>GNU General Public License version 2 or later; see LICENSE.txt</license>
    <description>COM_EXAMPLE_XML_DESCRIPTION</description>
    <namespace path="src">Vendor\Component\Example</namespace>

    <scriptfile>example.script.php</scriptfile>

    <languages folder="admin">
        <language tag="en-GB">language/en-GB/en-GB.com_example.ini</language>
        <language tag="en-GB">language/en-GB/en-GB.com_example.sys.ini</language>
    </languages>

    <install>
        <sql>
            <file driver="mysql" charset="utf8">sql/install.mysql.utf8.sql</file>
        </sql>
    </install>

    <update>
        <schemas>
            <schemapath type="mysql">sql/updates/mysql</schemapath>
        </schemas>
    </update>

    <files folder="site">
        <folder>forms</folder>
        <folder>layouts</folder>
        <folder>src</folder>
        <folder>tmpl</folder>
    </files>

    <media destination="com_example" folder="media">
        <filename>joomla.asset.json</filename>
        <folder>css</folder>
        <folder>js</folder>
        <folder>images</folder>
    </media>

    <administration>
        <menu>COM_EXAMPLE</menu>
        <submenu>
            <menu link="option=com_example&amp;view=items"
                  view="items"
                  alt="Example/Items">
                COM_EXAMPLE_MENU_ITEMS
            </menu>
        </submenu>

        <files folder="admin">
            <filename>access.xml</filename>
            <filename>config.xml</filename>
            <folder>forms</folder>
            <folder>language</folder>
            <folder>services</folder>
            <folder>sql</folder>
            <folder>src</folder>
            <folder>tmpl</folder>
        </files>
    </administration>

    <changelogurl>https://example.com/changelog.xml</changelogurl>
    <updateservers>
        <server type="extension" priority="1" name="Example Updates">
            https://example.com/updates.xml
        </server>
    </updateservers>
</extension>
```

---

## Language Files

The component's `<languages folder="admin">` block declares which `.ini` files Joomla copies at install time. Components use the `COM_<ELEMENT>_*` key prefix and ship two files (`en-GB.com_example.ini` for runtime strings, `en-GB.com_example.sys.ini` for install / Extension-Manager strings).

The conventions for filenames, key prefixes, plurals, `Text::script()` registration, and the `_FIELD_<NAME>_LABEL` / `_DESC` form-field pattern are **shared across all extension types** and live in [`references/language-files.md`](language-files.md). Read that for the full picture; what's specific to components is just the prefix (`COM_`) and the dual-`<languages folder="…">` setup (admin and site each get their own block in the manifest).

---

## Service Provider

The wrapping pattern (`ServiceProviderInterface` + anonymous class + `register()` + `Container::registerServiceProvider()` / `Container::set()`) is shared across components, modules, and plugins. The universal pattern, what each extension type registers, and the common DI pitfalls live in [`references/service-provider.md`](service-provider.md). What's specific to components is **which factories get registered** — `MVCFactory`, `ComponentDispatcherFactory`, `RouterFactory`, and `CategoryFactory` (when the component has categories) — and the binding of `ComponentInterface` to the component class with its dependencies wired via the corresponding `…Interface` lookups.

**File:** `admin/services/provider.php`

```php
<?php

\defined('_JEXEC') or die;

use Vendor\Component\Example\Administrator\Extension\ExampleComponent;
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
        $container->registerServiceProvider(new CategoryFactory('\\Vendor\\Component\\Example'));
        $container->registerServiceProvider(new MVCFactory('\\Vendor\\Component\\Example'));
        $container->registerServiceProvider(new ComponentDispatcherFactory('\\Vendor\\Component\\Example'));
        $container->registerServiceProvider(new RouterFactory('\\Vendor\\Component\\Example'));

        $container->set(
            ComponentInterface::class,
            function (Container $container) {
                $component = new ExampleComponent(
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

---

## Extension Class

**File:** `admin/src/Extension/ExampleComponent.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Extension;

\defined('_JEXEC') or die;

use Joomla\CMS\Extension\BootableExtensionInterface;
use Joomla\CMS\Extension\MVCComponent;
use Joomla\CMS\HTML\HTMLRegistryAwareTrait;
use Psr\Container\ContainerInterface;

class ExampleComponent extends MVCComponent implements BootableExtensionInterface
{
    use HTMLRegistryAwareTrait;

    public function boot(ContainerInterface $container): void
    {
        // Register HTMLHelper services, event listeners, etc.
    }
}
```

---

## Controller Patterns

### Display Controller (default)

**File:** `admin/src/Controller/DisplayController.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Controller;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\Controller\BaseController;

class DisplayController extends BaseController
{
    protected $default_view = 'items';

    public function display($cachable = false, $urlparams = []): static
    {
        return parent::display($cachable, $urlparams);
    }
}
```

### Form Controller (single item CRUD)

**File:** `admin/src/Controller/ItemController.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Controller;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\Controller\FormController;

class ItemController extends FormController
{
    // FormController handles edit, save, cancel, apply automatically.
    // Override only if you need custom behavior:

    protected function allowAdd($data = []): bool
    {
        return $this->app->getIdentity()->authorise('core.create', 'com_example');
    }

    protected function allowEdit($data = [], $key = 'id'): bool
    {
        $id = (int) ($data[$key] ?? 0);

        return $this->app->getIdentity()->authorise('core.edit', 'com_example.item.' . $id);
    }
}
```

### Admin Controller (list operations)

**File:** `admin/src/Controller/ItemsController.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Controller;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\Controller\AdminController;

class ItemsController extends AdminController
{
    public function getModel($name = 'Item', $prefix = 'Administrator', $config = ['ignore_request' => true])
    {
        return parent::getModel($name, $prefix, $config);
    }
}
```

---

## Model Patterns

### Form Model (single item)

**File:** `admin/src/Model/ItemModel.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Model;

\defined('_JEXEC') or die;

use Joomla\CMS\Factory;
use Joomla\CMS\Form\Form;
use Joomla\CMS\MVC\Model\AdminModel;
use Joomla\CMS\Table\Table;

class ItemModel extends AdminModel
{
    public $typeAlias = 'com_example.item';

    public function getTable($name = 'Item', $prefix = 'Administrator', $options = []): Table
    {
        return parent::getTable($name, $prefix, $options);
    }

    public function getForm($data = [], $loadData = true): Form|false
    {
        $form = $this->loadForm(
            'com_example.item',
            'item',
            ['control' => 'jform', 'load_data' => $loadData]
        );

        if (empty($form)) {
            return false;
        }

        return $form;
    }

    protected function loadFormData(): mixed
    {
        $data = Factory::getApplication()->getUserState('com_example.edit.item.data', []);

        if (empty($data)) {
            $data = $this->getItem();
        }

        return $data;
    }
}
```

### List Model

**File:** `admin/src/Model/ItemsModel.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Model;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\Model\ListModel;
use Joomla\Database\QueryInterface;

class ItemsModel extends ListModel
{
    public function __construct($config = [])
    {
        if (empty($config['filter_fields'])) {
            $config['filter_fields'] = [
                'id', 'a.id',
                'title', 'a.title',
                'published', 'a.published',
                'ordering', 'a.ordering',
                'created', 'a.created',
            ];
        }

        parent::__construct($config);
    }

    protected function getListQuery(): QueryInterface
    {
        $db    = $this->getDatabase();
        $query = $db->createQuery();

        $query->select($db->quoteName([
            'a.id',
            'a.title',
            'a.alias',
            'a.published',
            'a.ordering',
            'a.created',
            'a.checked_out',
            'a.checked_out_time',
        ]))
            ->from($db->quoteName('#__example_items', 'a'));

        // Filter by published state
        $published = $this->getState('filter.published');

        if (is_numeric($published)) {
            $query->where($db->quoteName('a.published') . ' = :published')
                ->bind(':published', $published, \Joomla\Database\ParameterType::INTEGER);
        }

        // Filter by search
        $search = $this->getState('filter.search');

        if (!empty($search)) {
            $search = '%' . trim($search) . '%';
            $query->where($db->quoteName('a.title') . ' LIKE :search')
                ->bind(':search', $search);
        }

        // Ordering
        $orderCol  = $this->getState('list.ordering', 'a.id');
        $orderDirn = $this->getState('list.direction', 'DESC');
        $query->order($db->escape($orderCol) . ' ' . $db->escape($orderDirn));

        return $query;
    }

    protected function populateState($ordering = 'a.id', $direction = 'DESC'): void
    {
        parent::populateState($ordering, $direction);
    }
}
```

---

## Table Class

**File:** `admin/src/Table/ItemTable.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Table;

\defined('_JEXEC') or die;

use Joomla\CMS\Table\Table;
use Joomla\Database\DatabaseDriver;

class ItemTable extends Table
{
    public function __construct(DatabaseDriver $db)
    {
        parent::__construct('#__example_items', 'id', $db);

        $this->setColumnAlias('published', 'published');
    }

    public function check(): bool
    {
        try {
            parent::check();
        } catch (\Exception $e) {
            $this->setError($e->getMessage());
            return false;
        }

        // Auto-generate alias from title
        if (empty($this->alias)) {
            $this->alias = $this->title;
        }

        $this->alias = $this->stringURLSafe($this->alias);

        return true;
    }
}
```

---

## View Patterns

### List View (Admin)

**File:** `admin/src/View/Items/HtmlView.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\View\Items;

\defined('_JEXEC') or die;

use Joomla\CMS\Form\Form;
use Joomla\CMS\Helper\ContentHelper;
use Joomla\CMS\MVC\View\HtmlView as BaseHtmlView;
use Joomla\CMS\Pagination\Pagination;
use Joomla\CMS\Toolbar\ToolbarHelper;

class HtmlView extends BaseHtmlView
{
    protected array $items            = [];
    protected ?Pagination $pagination = null;
    public ?Form $filterForm          = null;
    public array $activeFilters       = [];

    public function display($tpl = null): void
    {
        // Joomla 5+: call model methods directly, NOT deprecated $this->get() proxy
        /** @var \Vendor\Component\Example\Administrator\Model\ItemsModel $model */
        $model = $this->getModel();

        $this->items         = $model->getItems();
        $this->pagination    = $model->getPagination();
        $this->filterForm    = $model->getFilterForm();
        $this->activeFilters = $model->getActiveFilters();

        $this->addToolbar();

        parent::display($tpl);
    }

    protected function addToolbar(): void
    {
        $canDo = ContentHelper::getActions('com_example');

        ToolbarHelper::title('Items', 'list');

        if ($canDo->get('core.create')) {
            ToolbarHelper::addNew('item.add');
        }

        if ($canDo->get('core.edit.state')) {
            ToolbarHelper::publish('items.publish', 'JTOOLBAR_PUBLISH', true);
            ToolbarHelper::unpublish('items.unpublish', 'JTOOLBAR_UNPUBLISH', true);
        }

        if ($canDo->get('core.delete')) {
            ToolbarHelper::deleteList('JGLOBAL_CONFIRM_DELETE', 'items.delete', 'JTOOLBAR_DELETE');
        }

        if ($canDo->get('core.admin')) {
            ToolbarHelper::preferences('com_example');
        }
    }
}
```

### Edit View (Admin)

**File:** `admin/src/View/Item/HtmlView.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\View\Item;

\defined('_JEXEC') or die;

use Joomla\CMS\Factory;
use Joomla\CMS\MVC\View\GenericDataException;
use Joomla\CMS\MVC\View\HtmlView as BaseHtmlView;
use Joomla\CMS\Toolbar\ToolbarHelper;

class HtmlView extends BaseHtmlView
{
    protected ?Form $form = null;
    protected ?object $item = null;

    public function display($tpl = null): void
    {
        // Joomla 5+: call model methods directly
        /** @var \Vendor\Component\Example\Administrator\Model\ItemModel $model */
        $model = $this->getModel();

        $this->form = $model->getForm();
        $this->item = $model->getItem();

        $this->addToolbar();

        parent::display($tpl);
    }

    protected function addToolbar(): void
    {
        Factory::getApplication()->getInput()->set('hidemainmenu', true);

        $isNew = ($this->item->id == 0);

        ToolbarHelper::title($isNew ? 'New Item' : 'Edit Item', 'pencil-alt');
        ToolbarHelper::apply('item.apply');
        ToolbarHelper::save('item.save');
        ToolbarHelper::cancel('item.cancel', $isNew ? 'JTOOLBAR_CANCEL' : 'JTOOLBAR_CLOSE');
    }
}
```

### Other View Types: Json, Raw, Feed

The examples above use `HtmlView` because it's by far the most common. Joomla also ships three other view base classes for non-HTML output. Pick by the `format` URL parameter (`?format=json` etc.) — Joomla resolves the `<format><view-name>View` class automatically.

**`JsonView` — JSON without the JSON:API envelope.** For ad-hoc AJAX endpoints used by your own admin JS:

```php
namespace Vendor\Component\Example\Site\View\Items;

use Joomla\CMS\MVC\View\JsonView;

class JsonView extends JsonView
{
    public function display($tpl = null): void
    {
        $items = $this->getModel()->getItems();
        // Echo JSON directly — JsonView sets the Content-Type header for you.
        echo json_encode(['items' => $items], JSON_THROW_ON_ERROR);
    }
}
```

URL: `index.php?option=com_example&view=items&format=json`.

**`RawView` — write the response body yourself.** Use for binary output (PDF, ICS, image proxy) or any non-HTML, non-JSON format. Set the response headers via the document or the application:

```php
use Joomla\CMS\MVC\View\GenericDataException;
use Joomla\CMS\MVC\View\HtmlView;

// Yes — RawView is implemented as `format=raw` HtmlView in J5+. The template file
// is `admin/tmpl/items/default.raw.php` and Joomla strips the chrome.
```

For a single component view, the simpler path is to keep using `HtmlView` and add a `default.raw.php` template alongside `default.php`.

**`FeedView` — RSS/Atom output.** Populate `$this->document` (a `FeedDocument`) with `FeedItem` instances:

```php
namespace Vendor\Component\Example\Site\View\Items;

use Joomla\CMS\Document\Feed\FeedItem;
use Joomla\CMS\MVC\View\HtmlView;
use Joomla\CMS\Router\Route;

class FeedView extends HtmlView
{
    public function display($tpl = null): void
    {
        $this->document->title = 'Latest Items';
        $this->document->link  = Route::_('index.php?option=com_example&view=items');

        foreach ($this->getModel()->getItems() as $row) {
            $item = new FeedItem();
            $item->title       = $row->title;
            $item->link        = Route::_('index.php?option=com_example&view=item&id=' . $row->id);
            $item->description = $row->summary;
            $item->date        = $row->created;
            $this->document->addItem($item);
        }
    }
}
```

URL: `index.php?option=com_example&view=items&format=feed&type=rss` (or `&type=atom`).

**JSON:API for the REST web service** is a different surface: it lives under `api/components/com_example/...` and uses `BaseApiView` / `JsonapiView`, not `JsonView`. See the [Webservices API Plugin](#webservices-api-plugin) section below.

---

## Template Files

### List Template

**File:** `admin/tmpl/items/default.php`

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\HTML\HTMLHelper;
use Joomla\CMS\Language\Text;
use Joomla\CMS\Layout\LayoutHelper;
use Joomla\CMS\Router\Route;

/** @var \Vendor\Component\Example\Administrator\View\Items\HtmlView $this */

// Joomla 5+: get state from the model, not from the deprecated $this->state property
$model     = $this->getModel();
$state     = $model->getState();
$listOrder = $this->escape($state->get('list.ordering'));
$listDirn  = $this->escape($state->get('list.direction'));
?>

<form action="<?php echo Route::_('index.php?option=com_example&view=items'); ?>"
      method="post" name="adminForm" id="adminForm">

    <?php echo LayoutHelper::render('joomla.searchtools.default', ['view' => $this]); ?>

    <?php if (empty($this->items)) : ?>
        <div class="alert alert-info">
            <span class="icon-info-circle" aria-hidden="true"></span>
            <?php echo Text::_('JGLOBAL_NO_MATCHING_RESULTS'); ?>
        </div>
    <?php else : ?>
        <table class="table" id="itemList">
            <caption class="visually-hidden">
                <?php echo Text::_('COM_EXAMPLE_TABLE_CAPTION'); ?>
            </caption>
            <thead>
                <tr>
                    <td class="w-1 text-center">
                        <?php echo HTMLHelper::_('grid.checkall'); ?>
                    </td>
                    <th scope="col" class="w-1 text-center">
                        <?php echo HTMLHelper::_('searchtools.sort', 'JSTATUS', 'a.published', $listDirn, $listOrder); ?>
                    </th>
                    <th scope="col">
                        <?php echo HTMLHelper::_('searchtools.sort', 'JGLOBAL_TITLE', 'a.title', $listDirn, $listOrder); ?>
                    </th>
                    <th scope="col" class="w-5 text-center">
                        <?php echo HTMLHelper::_('searchtools.sort', 'JGRID_HEADING_ID', 'a.id', $listDirn, $listOrder); ?>
                    </th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($this->items as $i => $item) :
                $canEdit    = $user->authorise('core.edit', 'com_example.item.' . $item->id);
                $canCheckin = $user->authorise('core.manage', 'com_checkin')
                    || $item->checked_out == $user->id || empty($item->checked_out);
                $isCheckedOut = !empty($item->checked_out) && $item->checked_out != $user->id;
            ?>
                <tr class="row<?php echo $i % 2; ?>">
                    <td class="text-center">
                        <?php echo HTMLHelper::_('grid.id', $i, $item->id, false, 'cid', 'cb', $item->title); ?>
                    </td>
                    <td class="text-center">
                        <?php echo HTMLHelper::_('jgrid.published', $item->published, $i, 'items.', true); ?>
                    </td>
                    <td>
                        <?php if ($isCheckedOut) : ?>
                            <?php // Checked out by another user — show icon + plain text ?>
                            <?php echo HTMLHelper::_('jgrid.checkedout', $i, $item->editor ?? '', $item->checked_out_time, 'items.', $canCheckin); ?>
                            <?php echo $this->escape($item->title); ?>
                        <?php elseif ($canEdit) : ?>
                            <?php // Editable — link to edit view via task routing ?>
                            <a href="<?php echo Route::_('index.php?option=com_example&task=item.edit&id=' . $item->id); ?>">
                                <?php echo $this->escape($item->title); ?>
                            </a>
                        <?php else : ?>
                            <?php // No edit permission — plain text ?>
                            <?php echo $this->escape($item->title); ?>
                        <?php endif; ?>
                        <?php if (!empty($item->alias)) : ?>
                            <div class="small text-body-secondary"><?php echo $this->escape($item->alias); ?></div>
                        <?php endif; ?>
                    </td>
                    <td class="text-center">
                        <?php echo (int) $item->id; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>

        <?php echo $this->pagination->getListFooter(); ?>
    <?php endif; ?>

    <input type="hidden" name="task" value="">
    <input type="hidden" name="boxchecked" value="0">
    <?php echo HTMLHelper::_('form.token'); ?>
</form>
```

### Edit Template

**File:** `admin/tmpl/item/edit.php`

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\HTML\HTMLHelper;
use Joomla\CMS\Language\Text;
use Joomla\CMS\Layout\LayoutHelper;
use Joomla\CMS\Router\Route;

/** @var \Vendor\Component\Example\Administrator\View\Item\HtmlView $this */

?>

<form action="<?php echo Route::_('index.php?option=com_example&layout=edit&id=' . (int) $this->item->id); ?>"
      method="post" name="adminForm" id="item-form" class="form-validate">

    <?php echo LayoutHelper::render('joomla.edit.title_alias', $this); ?>

    <div class="main-card">
        <?php echo HTMLHelper::_('uitab.startTabSet', 'myTab', ['active' => 'details', 'recall' => true]); ?>

        <?php echo HTMLHelper::_('uitab.addTab', 'myTab', 'details', Text::_('JDETAILS')); ?>
        <div class="row">
            <div class="col-lg-9">
                <?php echo $this->form->renderField('description'); ?>
            </div>
            <div class="col-lg-3">
                <?php echo LayoutHelper::render('joomla.edit.global', $this); ?>
            </div>
        </div>
        <?php echo HTMLHelper::_('uitab.endTab'); ?>

        <?php echo HTMLHelper::_('uitab.endTabSet'); ?>
    </div>

    <input type="hidden" name="task" value="">
    <?php echo HTMLHelper::_('form.token'); ?>
</form>
```

---

## Form XML

**File:** `admin/forms/item.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<form>
    <fieldset addfieldprefix="Vendor\Component\Example\Administrator\Field">
        <field
            name="id"
            type="hidden"
            default="0"
        />

        <field
            name="title"
            type="text"
            label="JGLOBAL_TITLE"
            required="true"
            maxlength="255"
            class="w-100"
        />

        <field
            name="alias"
            type="text"
            label="JFIELD_ALIAS_LABEL"
            description="JFIELD_ALIAS_DESC"
            maxlength="400"
            class="w-100"
        />

        <field
            name="published"
            type="list"
            label="JSTATUS"
            default="1"
        >
            <option value="1">JPUBLISHED</option>
            <option value="0">JUNPUBLISHED</option>
            <option value="2">JARCHIVED</option>
            <option value="-2">JTRASHED</option>
        </field>

        <field
            name="description"
            type="editor"
            label="JGLOBAL_DESCRIPTION"
            filter="\Joomla\CMS\Component\ComponentHelper::filterText"
            buttons="true"
        />

        <field
            name="access"
            type="accesslevel"
            label="JFIELD_ACCESS_LABEL"
            default="1"
        />

        <field
            name="ordering"
            type="ordering"
            label="JFIELD_ORDERING_LABEL"
        />
    </fieldset>
</form>
```

---

## Custom Form Fields

**File:** `admin/src/Field/CustomlistField.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Field;

\defined('_JEXEC') or die;

use Joomla\CMS\Form\Field\ListField;
use Joomla\CMS\HTML\HTMLHelper;
use Joomla\Database\DatabaseAwareTrait;

class CustomlistField extends ListField
{
    use DatabaseAwareTrait;

    protected $type = 'Customlist';

    protected function getOptions(): array
    {
        $db    = $this->getDatabase();
        $query = $db->createQuery()
            ->select($db->quoteName(['id', 'title']))
            ->from($db->quoteName('#__example_items'))
            ->where($db->quoteName('published') . ' = 1')
            ->order($db->quoteName('title'));

        $db->setQuery($query);
        $items = $db->loadObjectList();

        $options = [];

        foreach ($items as $item) {
            $options[] = HTMLHelper::_('select.option', $item->id, $item->title);
        }

        return array_merge(parent::getOptions(), $options);
    }
}
```

Reference field in form XML:
```xml
<field addfieldprefix="Vendor\Component\Example\Administrator\Field"
       name="item_id"
       type="customlist"
       label="COM_EXAMPLE_FIELD_ITEM"
/>
```

---

## Router (SEF URLs)

Joomla's SEF router converts internal URLs (`index.php?option=com_example&view=item&id=5`) into human-readable paths (`/items/news/my-article-title`) and back, using a rule-based middleware chain (`MenuRules` → `StandardRules` → `NomenuRules`).

This file used to inline the full router walkthrough; it has been moved to its own reference because the section was 300+ lines and has its own pitfalls. **Read [`references/component-router.md`](component-router.md)** for:

- How build/parse work and why rule order matters
- `RouterViewConfiguration` (`setKey`, `setParent`, `setNestable`, `addLayout`)
- `get{View}Segment()` / `get{View}Id()` callback naming
- A simple (no categories) router and a nested-categories router
- URL examples and a `RouterViewConfiguration` quick reference

For the **3-part router contract** (router class + `RouterServiceInterface` on the extension + `RouterFactory` registration in `services/provider.php`) — without all three, every `Route::_()` call falls back to `?view=` URLs — see `references/gotchas.md`.

---

## Dispatcher

**File:** `admin/src/Dispatcher/Dispatcher.php`

```php
<?php

namespace Vendor\Component\Example\Administrator\Dispatcher;

\defined('_JEXEC') or die;

use Joomla\CMS\Dispatcher\ComponentDispatcher;

class Dispatcher extends ComponentDispatcher
{
    protected $defaultController = 'display';

    protected function checkAccess(): void
    {
        $user = $this->app->getIdentity();

        if (!$user->authorise('core.manage', 'com_example')) {
            throw new \RuntimeException('Access Denied', 403);
        }
    }
}
```

---

## Install/Update Script

The `<scriptfile>` PHP class is the **PHP half** of the install system: lifecycle hooks (`preflight`, `install`, `update`, `postflight`, `uninstall`) for environment checks, DML data migrations, filesystem work, and uninstall cleanup. The **same lifecycle is shared by modules and plugins** — only the script-class name and manifest path differ. The full pattern, hook signatures, class-naming table for component / module / plugin, complete example, and skeletons live in [`references/install-script.md`](install-script.md).

For DDL changes (`CREATE TABLE`, `ALTER TABLE`, `CREATE INDEX`) — the **other half** of the install system — see the next section.

---

## Database Schema & Migrations

This is the **DDL half** of the install system. The PHP half — environment checks and DML data migrations — lives in [`references/install-script.md`](install-script.md) (cross-extension reference shared by component, module, and plugin). Schema files run *before* the install script's `update()` / `postflight()` hooks, so don't depend on data the script will set later.

Joomla components ship two kinds of database files:

1. **Install SQL** — the full schema, executed once on first install. Referenced by `<install><sql><file driver="mysql" charset="utf8">sql/install.mysql.utf8.sql</file></sql></install>` in the manifest.
2. **Update SQL** — one file per version, executed in order during an upgrade. Referenced by `<update><schemas><schemapath type="mysql">sql/updates/mysql</schemapath></schemas></update>`. Joomla picks files whose name compares greater than the row in `#__schemas` for this extension.

### Install file

**File:** `admin/sql/install.mysql.utf8.sql`

```sql
CREATE TABLE IF NOT EXISTS `#__example_items` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `asset_id`     INT UNSIGNED NOT NULL DEFAULT 0,
    `title`        VARCHAR(255) NOT NULL DEFAULT '',
    `alias`        VARCHAR(255) NOT NULL DEFAULT '',
    `catid`        INT UNSIGNED NOT NULL DEFAULT 0,
    `description`  MEDIUMTEXT NULL,
    `state`        TINYINT     NOT NULL DEFAULT 0,
    `access`       INT UNSIGNED NOT NULL DEFAULT 1,
    `language`     CHAR(7)     NOT NULL DEFAULT '*',
    `ordering`     INT          NOT NULL DEFAULT 0,
    `checked_out`  INT UNSIGNED NULL,
    `checked_out_time` DATETIME NULL,
    `created`      DATETIME    NOT NULL,
    `created_by`   INT UNSIGNED NOT NULL DEFAULT 0,
    `modified`     DATETIME    NOT NULL,
    `modified_by`  INT UNSIGNED NOT NULL DEFAULT 0,
    `params`       MEDIUMTEXT NULL,
    `metadata`     TEXT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_alias` (`alias`),
    KEY `idx_catid_state` (`catid`, `state`),
    KEY `idx_access` (`access`),
    KEY `idx_language` (`language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Conventions:**

- Use `#__` as the table prefix placeholder; Joomla replaces it at runtime with the configured prefix.
- `id` is `INT UNSIGNED AUTO_INCREMENT PRIMARY KEY`.
- Standard columns (`asset_id`, `state`, `access`, `language`, `ordering`, `checked_out`, `checked_out_time`, `created`, `created_by`, `modified`, `modified_by`, `params`, `metadata`) follow core conventions so list models, the workflow, and ACL "just work".
- `CREATE TABLE IF NOT EXISTS` so reinstall is idempotent. Index every column you'll filter on.
- Charset `utf8mb4` + collation `utf8mb4_unicode_ci` — match core. Filename ends `.mysql.utf8.sql` even though the actual charset is `utf8mb4` (legacy filename convention).

If you target PostgreSQL too, ship a parallel `sql/install.postgresql.utf8.sql` and add a second `<file driver="postgresql">…</file>` entry.

### Update files

**Directory:** `admin/sql/updates/mysql/` (one file per version, named `X.Y.Z.sql`)

```
admin/sql/updates/mysql/
├── 1.0.1.sql
├── 1.1.0.sql
└── 2.0.0.sql
```

**`admin/sql/updates/mysql/1.1.0.sql`** — only the delta from 1.0.x:

```sql
ALTER TABLE `#__example_items`
    ADD COLUMN `summary` VARCHAR(500) NOT NULL DEFAULT '' AFTER `description`,
    ADD COLUMN `featured` TINYINT(1) NOT NULL DEFAULT 0 AFTER `state`;

CREATE INDEX `idx_featured_state` ON `#__example_items` (`featured`, `state`);
```

**Conventions and pitfalls:**

- **DDL only.** Update SQL files are for `ALTER TABLE`, `CREATE INDEX`, `CREATE TABLE`, and similar schema mutations. They are NOT the place for `INSERT`/`UPDATE`/`DELETE` against existing rows — that belongs in the install script's `update()` / `postflight()` PHP, where you can branch on `$type` and read the previous version.
- **Idempotent statements only.** A user might be on 1.0.5 upgrading to 2.0.0; Joomla executes 1.1.0.sql, 2.0.0.sql in order. Make each statement safe to re-run: prefer `ALTER TABLE … ADD COLUMN IF NOT EXISTS …` (MySQL 8+) or guard with the install-script PHP. The bare `ADD COLUMN` form will throw on a column that already exists.
- **One file per release tag.** The filename must equal the version number you'll set in the `<version>` tag of the manifest at the time you ship that file. Joomla compares using PHP's `version_compare()`.
- **Don't edit shipped files.** Once a file has gone out the door (someone has 1.1.0.sql in their database under `#__schemas`), do not change it — ship a 1.1.1.sql with the additional change.
- **No rollback.** Joomla has no built-in `down` migration. If you need to revert, ship a forward-only fix in the next version.

### Schema tracking

Joomla records the latest applied schema version per extension in `#__schemas` (a `version_id`/`extension_id` pair pointing at `#__extensions`). On every install/update, Joomla reads this row, runs every update SQL file with a name `>` than the row, and writes back the highest version applied. You don't manage this table yourself — keep update filenames and `<version>` in sync and Joomla handles the rest.

For data migrations (UPDATE/INSERT on existing rows), use the `update()` and `postflight()` hooks of the install script — see the [Install/Update Script](#installupdate-script) section above for the full pattern.

---

## Component Options (config.xml)

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

        <field
            name="date_format"
            type="list"
            label="COM_EXAMPLE_CONFIG_DATE_FORMAT"
            default="Y-m-d"
        >
            <option value="Y-m-d">2026-01-15</option>
            <option value="d/m/Y">15/01/2026</option>
            <option value="M j, Y">Jan 15, 2026</option>
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

Access in code:
```php
use Joomla\CMS\Component\ComponentHelper;

$params = ComponentHelper::getParams('com_example');
$perPage = $params->get('items_per_page', 20);
```

---

## Filter Form (Searchtools)

**File:** `admin/forms/filter_items.xml`

Must be named `filter_{view}.xml` — Joomla auto-discovers it for the matching list view.

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

---

## Site Views

### Site Display Controller

**File:** `site/src/Controller/DisplayController.php`

```php
<?php

namespace Vendor\Component\Example\Site\Controller;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\Controller\BaseController;

class DisplayController extends BaseController
{
    protected $default_view = 'items';

    public function display($cachable = false, $urlparams = []): static
    {
        $cachable = true;

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

### Site List Model

**File:** `site/src/Model/ItemsModel.php`

```php
<?php

namespace Vendor\Component\Example\Site\Model;

\defined('_JEXEC') or die;

use Joomla\CMS\Factory;
use Joomla\CMS\MVC\Model\ListModel;
use Joomla\Database\QueryInterface;

class ItemsModel extends ListModel
{
    protected function getListQuery(): QueryInterface
    {
        $db    = $this->getDatabase();
        $query = $db->createQuery();
        $user  = Factory::getApplication()->getIdentity();

        $query->select($db->quoteName([
            'a.id', 'a.title', 'a.alias', 'a.description',
            'a.published', 'a.created', 'a.created_by', 'a.access',
        ]))
            ->from($db->quoteName('#__example_items', 'a'))
            ->where($db->quoteName('a.published') . ' = 1')
            ->whereIn($db->quoteName('a.access'), $user->getAuthorisedViewLevels());

        // Apply component/menu params
        $params = Factory::getApplication()->getParams();
        $orderCol = $params->get('orderby', 'a.created');
        $orderDir = $params->get('orderby_direction', 'DESC');

        $query->order($db->escape($orderCol) . ' ' . $db->escape($orderDir));

        return $query;
    }
}
```

### Site Detail View

**File:** `site/src/View/Item/HtmlView.php`

```php
<?php

namespace Vendor\Component\Example\Site\View\Item;

\defined('_JEXEC') or die;

use Joomla\CMS\Factory;
use Joomla\CMS\MVC\View\GenericDataException;
use Joomla\CMS\MVC\View\HtmlView as BaseHtmlView;

class HtmlView extends BaseHtmlView
{
    protected ?object $item = null;
    protected $params;

    public function display($tpl = null): void
    {
        // Joomla 5+: call model methods directly
        $model      = $this->getModel();
        $this->item = $model->getItem();

        $this->params = Factory::getApplication()->getParams();

        // Check access
        $user = Factory::getApplication()->getIdentity();
        if (!\in_array($this->item->access, $user->getAuthorisedViewLevels())) {
            throw new \RuntimeException('Access Denied', 403);
        }

        $this->prepareDocument();
        parent::display($tpl);
    }

    protected function prepareDocument(): void
    {
        $app = Factory::getApplication();

        // Page title
        $title = $this->item->title;
        if ($app->get('sitename_pagetitles', 0) == 1) {
            $title = $app->get('sitename') . ' - ' . $title;
        }
        $this->getDocument()->setTitle($title);

        // Meta description
        if (!empty($this->item->metadesc)) {
            $this->getDocument()->setDescription($this->item->metadesc);
        }

        // Breadcrumbs
        $pathway = $app->getPathway();
        $pathway->addItem($this->item->title);
    }
}
```

### Site Detail Template

**File:** `site/tmpl/item/default.php`

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\HTML\HTMLHelper;
use Joomla\CMS\Language\Text;

/** @var \Vendor\Component\Example\Site\View\Item\HtmlView $this */
?>

<div class="com-example-item" itemscope itemtype="https://schema.org/Article">
    <h1 itemprop="name"><?php echo $this->escape($this->item->title); ?></h1>

    <?php if ($this->params->get('show_author', 1)) : ?>
        <div class="text-body-secondary mb-3">
            <?php echo Text::sprintf('COM_EXAMPLE_WRITTEN_BY', $this->item->author_name); ?>
            <time datetime="<?php echo HTMLHelper::_('date', $this->item->created, 'c'); ?>" itemprop="datePublished">
                <?php echo HTMLHelper::_('date', $this->item->created, Text::_('DATE_FORMAT_LC3')); ?>
            </time>
        </div>
    <?php endif; ?>

    <div itemprop="articleBody">
        <?php echo $this->item->description; ?>
    </div>
</div>
```

---

## Access Control

**File:** `admin/access.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<access component="com_example">
    <section name="component">
        <action name="core.admin" title="JACTION_ADMIN" />
        <action name="core.options" title="JACTION_OPTIONS" />
        <action name="core.manage" title="JACTION_MANAGE" />
        <action name="core.create" title="JACTION_CREATE" />
        <action name="core.delete" title="JACTION_DELETE" />
        <action name="core.edit" title="JACTION_EDIT" />
        <action name="core.edit.state" title="JACTION_EDITSTATE" />
        <action name="core.edit.own" title="JACTION_EDITOWN" />
    </section>
    <section name="item">
        <action name="core.delete" title="JACTION_DELETE" />
        <action name="core.edit" title="JACTION_EDIT" />
        <action name="core.edit.state" title="JACTION_EDITSTATE" />
        <action name="core.edit.own" title="JACTION_EDITOWN" />
    </section>
</access>
```

---

## Webservices API Plugin

Expose component data via Joomla's JSON:API-compliant REST endpoints. Requires a webservices plugin, API controller(s), and API view(s).

### Plugin

**File:** `plugins/webservices/example/src/Extension/Example.php`

```php
<?php

namespace Vendor\Plugin\WebServices\Example\Extension;

\defined('_JEXEC') or die;

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

        $router->createCRUDRoutes(
            'v1/example/items',
            'items',
            ['component' => 'com_example']
        );
    }
}
```

### Plugin Service Provider

**File:** `plugins/webservices/example/services/provider.php`

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Extension\PluginInterface;
use Joomla\CMS\Factory;
use Joomla\CMS\Plugin\PluginHelper;
use Joomla\DI\Container;
use Joomla\DI\ServiceProviderInterface;
use Vendor\Plugin\WebServices\Example\Extension\Example;

return new class () implements ServiceProviderInterface {
    public function register(Container $container): void
    {
        $container->set(
            PluginInterface::class,
            function (Container $container) {
                $plugin = new Example(
                    (array) PluginHelper::getPlugin('webservices', 'example')
                );
                $plugin->setApplication(Factory::getApplication());

                return $plugin;
            }
        );
    }
};
```

### API Controller

**File:** `api/src/Controller/ItemsController.php`

```php
<?php

namespace Vendor\Component\Example\Api\Controller;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\Controller\ApiController;

class ItemsController extends ApiController
{
    protected $contentType = 'items';
    protected $default_view = 'items';
}
```

### API View (JSON:API)

**File:** `api/src/View/Items/JsonapiView.php`

```php
<?php

namespace Vendor\Component\Example\Api\View\Items;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\View\JsonApiView as BaseApiView;

class JsonapiView extends BaseApiView
{
    protected $fieldsToRenderItem = [
        'id', 'title', 'alias', 'description', 'published',
        'access', 'created', 'created_by', 'modified',
    ];

    protected $fieldsToRenderList = [
        'id', 'title', 'alias', 'published', 'created',
    ];
}
```

### Component Manifest Addition

```xml
<api>
    <files folder="api">
        <folder>src</folder>
    </files>
</api>
```

### API Endpoints (from createCRUDRoutes)

| Method | URL | Action |
|--------|-----|--------|
| GET | `/api/index.php/v1/example/items` | List all items |
| GET | `/api/index.php/v1/example/items/{id}` | Get single item |
| POST | `/api/index.php/v1/example/items` | Create new item |
| PATCH | `/api/index.php/v1/example/items/{id}` | Update item |
| DELETE | `/api/index.php/v1/example/items/{id}` | Delete item |

Authentication: Joomla API uses token-based auth (API token from user profile) or session-based for logged-in users.
