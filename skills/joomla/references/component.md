# Joomla 5+ Component Reference

## Table of Contents
1. [Manifest XML Template](#manifest-xml-template)
2. [Service Provider](#service-provider)
3. [Extension Class](#extension-class)
4. [Controller Patterns](#controller-patterns)
5. [Model Patterns](#model-patterns)
6. [Table Class](#table-class)
7. [View Patterns](#view-patterns)
8. [Template Files](#template-files)
9. [Form XML](#form-xml)
10. [Custom Form Fields](#custom-form-fields)
11. [Router (SEF URLs)](#router)
12. [Dispatcher](#dispatcher)
13. [Install/Update Script](#installupdate-script)
14. [Component Options (config.xml)](#component-options-configxml)
15. [Filter Form (Searchtools)](#filter-form-searchtools)
16. [Site Views](#site-views)
17. [Access Control (ACL)](#access-control)
18. [Webservices API Plugin](#webservices-api-plugin)

---

## Manifest XML Template

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

## Service Provider

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
        /** @var \Namespace\Component\Example\Administrator\Model\ItemsModel $model */
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
        /** @var \Namespace\Component\Example\Administrator\Model\ItemModel $model */
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
            filter="JComponentHelper::filterText"
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

Joomla's SEF router converts between internal URLs (`index.php?option=com_example&view=item&id=5`) and human-readable URLs (`/example/my-article-title`). The router uses a rule-based middleware chain.

### How It Works

**Building** (internal URL → SEF segments): Rules process the query in order, removing matched parameters and appending URL segments.

**Parsing** (SEF segments → internal URL): Rules process segments in order, consuming them and populating query variables.

**Rule execution order matters:**
1. `MenuRules` — finds the matching menu item (Itemid), establishes base context
2. `StandardRules` — builds/parses segments relative to the menu item's view
3. `NomenuRules` — fallback when no menu item matches (adds view name as first segment)

### View Configuration

Each site view is registered with a `RouterViewConfiguration` that defines:
- **`setKey('id')`** — the query parameter that identifies this view's record
- **`setParent($parent, 'catid')`** — parent-child relationship (e.g., item belongs to category)
- **`setNestable()`** — view supports hierarchical nesting (e.g., nested categories)
- **`addLayout('blog')`** — registers additional layout for menu item matching

### Callback Methods

The router calls methods on your Router class to convert between IDs and URL segments:

- **`get{View}Segment($id, $query)`** — converts a database ID to a URL-safe segment (alias)
- **`get{View}Id($segment, $query)`** — converts a URL segment back to a database ID

Method names are derived from the view name in title case: view `item` → `getItemSegment()` / `getItemId()`.

### Simple Router (No Categories)

**File:** `site/src/Service/Router.php`

```php
<?php

namespace Vendor\Component\Example\Site\Service;

\defined('_JEXEC') or die;

use Joomla\CMS\Application\SiteApplication;
use Joomla\CMS\Component\Router\RouterView;
use Joomla\CMS\Component\Router\RouterViewConfiguration;
use Joomla\CMS\Component\Router\Rules\MenuRules;
use Joomla\CMS\Component\Router\Rules\NomenuRules;
use Joomla\CMS\Component\Router\Rules\StandardRules;
use Joomla\CMS\Menu\AbstractMenu;
use Joomla\Database\DatabaseInterface;
use Joomla\Database\ParameterType;

class Router extends RouterView
{
    private DatabaseInterface $db;

    public function __construct(SiteApplication $app, AbstractMenu $menu, DatabaseInterface $db)
    {
        $this->db = $db;

        // List view (no key needed — shows all items)
        $items = new RouterViewConfiguration('items');
        $this->registerView($items);

        // Detail view (keyed by 'id', child of list)
        $item = new RouterViewConfiguration('item');
        $item->setKey('id')->setParent($items);
        $this->registerView($item);

        parent::__construct($app, $menu);

        $this->attachRule(new MenuRules($this));
        $this->attachRule(new StandardRules($this));
        $this->attachRule(new NomenuRules($this));
    }

    /**
     * Build: convert item ID to URL segment (alias).
     * Called during URL building. Returns [id => alias].
     */
    public function getItemSegment(string $id, array $query): array
    {
        // $id may be "5:my-alias" (id:alias format) or just "5"
        if (str_contains($id, ':')) {
            [$numericId, $alias] = explode(':', $id, 2);
            return [(int) $numericId => $alias];
        }

        // Look up alias from database
        $dbQuery = $this->db->createQuery()
            ->select($this->db->quoteName('alias'))
            ->from($this->db->quoteName('#__example_items'))
            ->where($this->db->quoteName('id') . ' = :id')
            ->bind(':id', $id, ParameterType::INTEGER);
        $this->db->setQuery($dbQuery);
        $alias = $this->db->loadResult();

        return [(int) $id => $alias ?: $id];
    }

    /**
     * Parse: convert URL segment (alias) back to item ID.
     * Called during URL parsing. Returns the database ID.
     */
    public function getItemId(string $segment, array $query): int|false
    {
        $dbQuery = $this->db->createQuery()
            ->select($this->db->quoteName('id'))
            ->from($this->db->quoteName('#__example_items'))
            ->where($this->db->quoteName('alias') . ' = :alias')
            ->bind(':alias', $segment);
        $this->db->setQuery($dbQuery);

        return (int) $this->db->loadResult() ?: false;
    }
}
```

### Router with Categories (Nested)

For components using Joomla's category system, inject `CategoryFactoryInterface` and use `setNestable()`:

```php
<?php

namespace Vendor\Component\Example\Site\Service;

\defined('_JEXEC') or die;

use Joomla\CMS\Application\SiteApplication;
use Joomla\CMS\Categories\CategoryFactoryInterface;
use Joomla\CMS\Categories\CategoryInterface;
use Joomla\CMS\Component\Router\RouterView;
use Joomla\CMS\Component\Router\RouterViewConfiguration;
use Joomla\CMS\Component\Router\Rules\MenuRules;
use Joomla\CMS\Component\Router\Rules\NomenuRules;
use Joomla\CMS\Component\Router\Rules\StandardRules;
use Joomla\CMS\Menu\AbstractMenu;
use Joomla\Database\DatabaseInterface;
use Joomla\Database\ParameterType;

class Router extends RouterView
{
    private DatabaseInterface $db;
    private CategoryFactoryInterface $categoryFactory;

    public function __construct(
        SiteApplication $app,
        AbstractMenu $menu,
        CategoryFactoryInterface $categoryFactory,
        DatabaseInterface $db
    ) {
        $this->db = $db;
        $this->categoryFactory = $categoryFactory;

        // Categories list (top-level)
        $categories = new RouterViewConfiguration('categories');
        $categories->setKey('id');
        $this->registerView($categories);

        // Single category (nestable — supports /parent/child/grandchild paths)
        $category = new RouterViewConfiguration('category');
        $category->setKey('id')->setParent($categories, 'catid')->setNestable()->addLayout('blog');
        $this->registerView($category);

        // Single item (child of category)
        $item = new RouterViewConfiguration('item');
        $item->setKey('id')->setParent($category, 'catid');
        $this->registerView($item);

        parent::__construct($app, $menu);

        $this->attachRule(new MenuRules($this));
        $this->attachRule(new StandardRules($this));
        $this->attachRule(new NomenuRules($this));
    }

    /**
     * Build: category ID → nested path segments.
     * Returns [id => alias, ...] for each level of the category tree.
     */
    public function getCategorySegment(string $id, array $query): array
    {
        $category = $this->getCategories()->get((int) $id);

        if (!$category) {
            return [(int) $id => $id];
        }

        $path    = array_reverse($category->getPath(), true);
        $path[0] = '1:root'; // Remove root from path

        $segments = [];
        foreach ($path as $pathId => $pathSegment) {
            if ($pathId === 0) {
                continue; // Skip root
            }
            $segments[(int) $pathId] = $pathSegment;
        }

        return $segments;
    }

    /**
     * Parse: category alias segment → category ID.
     * Uses parent category context from $query to find the right child.
     */
    public function getCategoryId(string $segment, array $query): int|false
    {
        $parent = $this->getCategories(['access' => false]);

        if (isset($query['id'])) {
            $parent = $parent->get((int) $query['id']);
        }

        if (!$parent) {
            return false;
        }

        foreach ($parent->getChildren() as $child) {
            if ($child->alias === $segment) {
                return (int) $child->id;
            }
        }

        return false;
    }

    /**
     * Build: item ID → alias segment.
     */
    public function getItemSegment(string $id, array $query): array
    {
        if (str_contains($id, ':')) {
            [$numericId, $alias] = explode(':', $id, 2);
            return [(int) $numericId => $alias];
        }

        $dbQuery = $this->db->createQuery()
            ->select($this->db->quoteName('alias'))
            ->from($this->db->quoteName('#__example_items'))
            ->where($this->db->quoteName('id') . ' = :id')
            ->bind(':id', $id, ParameterType::INTEGER);
        $this->db->setQuery($dbQuery);

        return [(int) $id => $this->db->loadResult() ?: $id];
    }

    /**
     * Parse: item alias → item ID.
     * Scoped by category (catid) from query for disambiguation.
     */
    public function getItemId(string $segment, array $query): int|false
    {
        $dbQuery = $this->db->createQuery()
            ->select($this->db->quoteName('id'))
            ->from($this->db->quoteName('#__example_items'))
            ->where($this->db->quoteName('alias') . ' = :alias')
            ->bind(':alias', $segment);

        // Scope by category if available
        if (!empty($query['catid'])) {
            $catid = (int) $query['catid'];
            $dbQuery->where($this->db->quoteName('catid') . ' = :catid')
                ->bind(':catid', $catid, ParameterType::INTEGER);
        }

        $this->db->setQuery($dbQuery);

        return (int) $this->db->loadResult() ?: false;
    }

    /**
     * Get category tree with caching.
     */
    private function getCategories(array $options = []): CategoryInterface
    {
        return $this->categoryFactory->createCategory($options);
    }
}
```

### URL Examples

Given menu item "Items" pointing to `view=items`:

| Internal URL | SEF URL | Why |
|-------------|---------|-----|
| `view=items` | `/items` | Menu item match — no extra segments |
| `view=item&id=5` | `/items/my-article` | Child of items, alias segment |
| `view=category&id=3` | `/items/news` | Category alias from tree |
| `view=item&id=5&catid=3` | `/items/news/my-article` | Category + item path |
| `view=item&id=5` (no menu) | `/component/example/item/my-article` | NomenuRules fallback |

### RouterViewConfiguration Quick Reference

| Method | Purpose | Example |
|--------|---------|---------|
| `setKey('id')` | Query param identifying this view's record | `setKey('id')`, `setKey('catid')` |
| `setParent($parent, 'catid')` | Parent view + key linking to parent | Item belongs to category |
| `setNestable()` | Allows hierarchical paths (categories) | `/cat/subcat/subsubcat` |
| `addLayout('blog')` | Register layout for menu matching | Category blog vs. list |

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

**File:** `mycomponent.script.php` (referenced in manifest as `<scriptfile>`)

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Factory;
use Joomla\CMS\Installer\InstallerAdapter;
use Joomla\CMS\Log\Log;

class Com_ExampleInstallerScript
{
    protected string $minimumPhp = '8.2.0';
    protected string $minimumJoomla = '5.0.0';

    /**
     * Runs BEFORE install/update. Return false to abort.
     */
    public function preflight(string $type, InstallerAdapter $adapter): bool
    {
        if (version_compare(PHP_VERSION, $this->minimumPhp, '<')) {
            Log::add("PHP {$this->minimumPhp}+ required", Log::ERROR, 'jerror');
            return false;
        }

        return true;
    }

    /**
     * Runs on fresh install only.
     */
    public function install(InstallerAdapter $adapter): bool
    {
        // Insert default data, create directories, etc.
        return true;
    }

    /**
     * Runs on update only.
     */
    public function update(InstallerAdapter $adapter): bool
    {
        return true;
    }

    /**
     * Runs AFTER install/update.
     * $type is 'install', 'update', or 'discover_install'.
     */
    public function postflight(string $type, InstallerAdapter $adapter): void
    {
        if ($type === 'update') {
            $this->migrateData($adapter);
        }
    }

    /**
     * Runs on uninstall. Clean up related records, files, etc.
     */
    public function uninstall(InstallerAdapter $adapter): bool
    {
        return true;
    }

    /**
     * DML migrations that can't go in SQL update files.
     */
    private function migrateData(InstallerAdapter $adapter): void
    {
        $db = Factory::getContainer()->get('DatabaseDriver');

        // Example: migrate data from old column to new column
        $query = $db->createQuery()
            ->update($db->quoteName('#__example_items'))
            ->set($db->quoteName('new_column') . ' = ' . $db->quoteName('old_column'))
            ->where($db->quoteName('new_column') . ' = ' . $db->quote(''));
        $db->setQuery($query)->execute();
    }
}
```

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
