# Joomla Component Router Reference

Joomla's SEF router converts between internal URLs (`index.php?option=com_example&view=item&id=5`) and human-readable URLs (`/example/my-article-title`). The router uses a rule-based middleware chain.

This reference covers the J5+ `RouterView` pattern: how rules execute, view configuration, callback method naming, a simple (no categories) router, a nested-categories router, URL examples, and the `RouterViewConfiguration` quick reference.

For the **3-part contract** that's required to make the router work at all (router class + `RouterServiceInterface` + `RouterFactory` registration in `services/provider.php`) and the related SEF gotchas (hidden menu items, callback naming, rule order), see `references/gotchas.md`.

## How It Works

**Building** (internal URL → SEF segments): Rules process the query in order, removing matched parameters and appending URL segments.

**Parsing** (SEF segments → internal URL): Rules process segments in order, consuming them and populating query variables.

**Rule execution order matters:**
1. `MenuRules` — finds the matching menu item (Itemid), establishes base context
2. `StandardRules` — builds/parses segments relative to the menu item's view
3. `NomenuRules` — fallback when no menu item matches (adds view name as first segment)

## View Configuration

Each site view is registered with a `RouterViewConfiguration` that defines:
- **`setKey('id')`** — the query parameter that identifies this view's record
- **`setParent($parent, 'catid')`** — parent-child relationship (e.g., item belongs to category)
- **`setNestable()`** — view supports hierarchical nesting (e.g., nested categories)
- **`addLayout('blog')`** — registers additional layout for menu item matching

## Callback Methods

The router calls methods on your Router class to convert between IDs and URL segments:

- **`get{View}Segment($id, $query)`** — converts a database ID to a URL-safe segment (alias)
- **`get{View}Id($segment, $query)`** — converts a URL segment back to a database ID

Method names are derived from the view name in title case: view `item` → `getItemSegment()` / `getItemId()`.

## Simple Router (No Categories)

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

## Router with Categories (Nested)

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

## URL Examples

Given menu item "Items" pointing to `view=items`:

| Internal URL | SEF URL | Why |
|-------------|---------|-----|
| `view=items` | `/items` | Menu item match — no extra segments |
| `view=item&id=5` | `/items/my-article` | Child of items, alias segment |
| `view=category&id=3` | `/items/news` | Category alias from tree |
| `view=item&id=5&catid=3` | `/items/news/my-article` | Category + item path |
| `view=item&id=5` (no menu) | `/component/example/item/my-article` | NomenuRules fallback |

## RouterViewConfiguration Quick Reference

| Method | Purpose | Example |
|--------|---------|---------|
| `setKey('id')` | Query param identifying this view's record | `setKey('id')`, `setKey('catid')` |
| `setParent($parent, 'catid')` | Parent view + key linking to parent | Item belongs to category |
| `setNestable()` | Allows hierarchical paths (categories) | `/cat/subcat/subsubcat` |
| `addLayout('blog')` | Register layout for menu matching | Category blog vs. list |
