# Layouts (LayoutHelper)

Joomla's layout system provides reusable, overridable PHP template fragments. Layouts are used for rendering form fields, toolbars, list items, and any shared HTML across views.

## Rendering a Layout

```php
use Joomla\CMS\Layout\LayoutHelper;

// Render a built-in Joomla layout
echo LayoutHelper::render('joomla.searchtools.default', ['view' => $this]);

// Render with custom data
echo LayoutHelper::render('joomla.content.info_block', ['item' => $item, 'params' => $params]);

// Render from a component's own layouts/ directory
echo LayoutHelper::render('mycomponent.item.badge', ['status' => $item->published], JPATH_SITE . '/components/com_example/layouts');
```

The first argument is a dot-separated layout ID that maps to a file path: `joomla.form.field.text` → `layouts/joomla/form/field/text.php`.

## Creating Custom Layouts

**File:** `site/layouts/mycomponent/item/card.php`

```php
<?php
// layouts/mycomponent/item/card.php
defined('_JEXEC') or die;

extract($displayData);
// $item, $params are now available as variables
?>
<div class="card">
    <div class="card-body">
        <h5 class="card-title"><?php echo $this->escape($item->title); ?></h5>
        <p class="card-text"><?php echo $item->description; ?></p>
    </div>
</div>
```

**Usage in a template:**
```php
echo LayoutHelper::render('mycomponent.item.card', ['item' => $item, 'params' => $params],
    JPATH_SITE . '/components/com_example/layouts');
```

## Layout Override Priority (highest to lowest)

| Priority | Path | Purpose |
|----------|------|---------|
| 1 | `templates/{template}/html/layouts/{component}/` | Template override (component-specific) |
| 2 | `templates/{parent}/html/layouts/{component}/` | Parent template override |
| 3 | `components/{component}/layouts/` | Component's own layouts |
| 4 | `templates/{template}/html/layouts/` | Template override (global) |
| 5 | `layouts/` | Joomla core layouts |

Users can override any layout by copying it to `templates/{template}/html/layouts/` and modifying it there.

## Sublayouts

Render a child layout relative to the current layout:

```php
// Inside layouts/joomla/editors/buttons.php
<?php foreach ($buttons as $button) : ?>
    <?php echo $this->sublayout('button', $button); ?>
<?php endforeach; ?>
```

`$this->sublayout('button', $button)` looks for `layouts/joomla/editors/buttons/button.php` — a file named `button.php` inside a directory matching the parent layout name.

## Key Built-in Layouts

| Layout ID | Purpose |
|-----------|---------|
| `joomla.searchtools.default` | Search/filter toolbar for list views |
| `joomla.edit.title_alias` | Title + alias fields in edit views |
| `joomla.edit.global` | Published, access, language sidebar |
| `joomla.html.batch.access` | Batch access level selector |
| `joomla.html.batch.language` | Batch language selector |
| `joomla.html.batch.tag` | Batch tag selector |
| `joomla.html.batch.item` | Batch category move/copy |
| `joomla.content.info_block` | Article info (author, date, hits) |
| `joomla.form.renderfield` | Field wrapper (label + input + description) |
| `joomla.form.renderlabel` | Field label element |
| `joomla.form.field.text` | Text input field |
| `joomla.form.field.subform.repeatable` | Repeatable subform rows |
| `joomla.pagination.default` | Pagination controls |
