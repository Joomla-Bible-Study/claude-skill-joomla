# Component Lifecycle & Patterns

Internal mechanics of how Joomla components work — the lifecycle hooks, data flow, and integration points that the directory structure alone doesn't explain. Read after the foundations in `SKILL.md` (PSR-4, service provider, MVC flow) and the per-type walkthrough in [`component.md`](component.md).

## Model Lifecycle

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

## Table bind() and store()

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

## Filter Forms (Searchtools)

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

## Install/Update Script

**File:** `mycomponent.script.php`

The script class runs during install, update, and uninstall. Critical for DML operations (INSERT, UPDATE, DELETE) that can't go in SQL update files (which only run DDL). The lifecycle hooks and class-naming conventions are **shared with modules and plugins** — for the full hook signatures, the class-name table for component/module/plugin, and the DDL-vs-DML rule see [`install-script.md`](install-script.md). The component-flavored example below uses the canonical `Log::add(..., 'jerror')` pattern from that reference for preflight failure surfacing.

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

## Site-Side Differences

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

## Extension Class: Service Interfaces

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

## Custom Controller Tasks & AJAX

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

## HTMLHelper Services

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

## Form XML: Conditional Fields (showon)

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

## Form XML: Fieldset Groups for Tabs

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
