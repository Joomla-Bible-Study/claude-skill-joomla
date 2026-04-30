# Joomla Form Fields Reference

Joomla provides ~90 built-in form field types and a clean extension model for custom field classes. This reference covers the common built-ins, the `subform` repeatable group pattern, the `media` picker, and how to author your own field type.

## Built-in Field Types Reference

The most commonly used built-ins:

**Basic inputs:**

| Type | XML | Notes |
|------|-----|-------|
| `text` | `type="text"` | Single-line text |
| `textarea` | `type="textarea"` | Multi-line, set `rows` and `cols` |
| `email` | `type="email"` | Email validation |
| `url` | `type="url"` | URL validation |
| `tel` | `type="tel"` | Phone number |
| `number` | `type="number"` | Numeric with `min`, `max`, `step` |
| `password` | `type="password"` | Masked input |
| `hidden` | `type="hidden"` | Hidden value |
| `editor` | `type="editor"` | WYSIWYG editor (see `references/editor-api.md`) |
| `color` | `type="color"` | Color picker |
| `calendar` | `type="calendar"` | Date picker with format, `showtime="true"` for datetime |

**Selection fields:**

| Type | XML | Notes |
|------|-----|-------|
| `list` | `type="list"` | Dropdown with `<option>` children |
| `groupedlist` | `type="groupedlist"` | Dropdown with `<group>` → `<option>` hierarchy |
| `radio` | `type="radio"` | Radio buttons, use `class="btn-group"` for toggle style |
| `checkboxes` | `type="checkboxes"` | Multiple checkboxes |
| `checkbox` | `type="checkbox"` | Single checkbox |
| `category` | `type="category"` | Category selector, needs `extension="com_example"` |
| `tag` | `type="tag"` | Tag picker, supports `mode="ajax"` and `multiple="true"` |
| `user` | `type="user"` | User selector |
| `accesslevel` | `type="accesslevel"` | Access level dropdown |
| `contentlanguage` | `type="contentlanguage"` | Language selector |
| `sql` | `type="sql"` | Options from SQL query |
| `status` | `type="status"` | Published/unpublished/trashed/archived |

**File/media fields:**

| Type | XML | Notes |
|------|-----|-------|
| `media` | `type="media"` | Media picker modal, `types="images"` or `"images,videos"` |
| `file` | `type="file"` | File upload input |
| `filelist` | `type="filelist"` | Lists files in a directory |
| `folderlist` | `type="folderlist"` | Lists folders |

**Special fields:**

| Type | XML | Notes |
|------|-----|-------|
| `subform` | `type="subform"` | Repeatable nested form groups |
| `rules` | `type="rules"` | Permissions matrix |
| `ordering` | `type="ordering"` | Ordering position |
| `spacer` | `type="spacer"` | Visual separator, `hr="true"` for line |
| `note` | `type="note"` | Display-only message |
| `componentlayout` | `type="componentlayout"` | Layout selector for a view |

## SubformField (Repeatable Groups)

Creates repeatable sets of fields — useful for things like social media links, phone numbers, or any list of structured items.

**Form XML:**
```xml
<field name="social_links"
       type="subform"
       label="Social Media Links"
       layout="joomla.form.field.subform.repeatable"
       multiple="true"
       min="0"
       max="10"
       buttons="add,remove,move"
       formsource="social_link.xml"
/>
```

**Subform definition** (`admin/forms/social_link.xml`):
```xml
<?xml version="1.0" encoding="utf-8"?>
<form>
    <field name="platform" type="list" label="Platform" default="facebook">
        <option value="facebook">Facebook</option>
        <option value="twitter">X (Twitter)</option>
        <option value="instagram">Instagram</option>
        <option value="youtube">YouTube</option>
    </field>
    <field name="url" type="url" label="URL" />
</form>
```

**Or define inline** (no separate XML file):
```xml
<field name="phones" type="subform" label="Phone Numbers"
       layout="joomla.form.field.subform.repeatable" multiple="true">
    <form>
        <field name="type" type="list" label="Type" default="mobile">
            <option value="mobile">Mobile</option>
            <option value="work">Work</option>
            <option value="home">Home</option>
        </field>
        <field name="number" type="tel" label="Number" />
    </form>
</field>
```

**Available subform layouts:**
- `joomla.form.field.subform.default` — single group (not repeatable)
- `joomla.form.field.subform.repeatable` — vertical repeatable rows with add/remove/move buttons
- `joomla.form.field.subform.repeatable-table` — table layout for repeatable rows

**Reading subform data in PHP:**
```php
$socialLinks = json_decode($item->social_links, true) ?? [];
foreach ($socialLinks as $link) {
    echo $link['platform'] . ': ' . $link['url'];
}
```

## MediaField

The media picker opens Joomla's Media Manager modal for selecting images, videos, and documents.

```xml
<field name="image"
       type="media"
       label="COM_EXAMPLE_FIELD_IMAGE"
       types="images"
       preview="true"
       previewWidth="200"
       previewHeight="200"
       directory="example"
/>
```

**Attributes:**
- `types` — comma-separated: `images`, `audios`, `videos`, `documents`
- `preview` — show thumbnail preview (`true`/`false`)
- `previewWidth` / `previewHeight` — preview dimensions in pixels
- `directory` — restrict to a subdirectory of the media root

## Creating Custom Form Fields

Custom fields extend a base field class and live in `admin/src/Field/`:

**Simple list field (database-backed options):**
```php
namespace Vendor\Component\Example\Administrator\Field;

use Joomla\CMS\Form\Field\ListField;
use Joomla\CMS\HTML\HTMLHelper;
use Joomla\Database\DatabaseAwareTrait;

class TeacherlistField extends ListField
{
    use DatabaseAwareTrait;

    protected $type = 'Teacherlist';

    protected function getOptions(): array
    {
        $db    = $this->getDatabase();
        $query = $db->createQuery()
            ->select($db->quoteName(['id', 'name']))
            ->from($db->quoteName('#__example_teachers'))
            ->where($db->quoteName('published') . ' = 1')
            ->order($db->quoteName('name'));

        $db->setQuery($query);
        $items = $db->loadObjectList();

        $options = [];
        foreach ($items as $item) {
            $options[] = HTMLHelper::_('select.option', $item->id, $item->name);
        }

        return array_merge(parent::getOptions(), $options);
    }
}
```

**Fully custom field (own rendering):**
```php
namespace Vendor\Component\Example\Administrator\Field;

use Joomla\CMS\Form\FormField;

class StarratingField extends FormField
{
    protected $type = 'Starrating';

    // Option 1: Layout-based rendering (preferred, allows template overrides)
    protected $layout = 'mycomponent.field.starrating';

    // Option 2: Override getInput() for inline HTML
    protected function getInput(): string
    {
        $html = '<div class="star-rating">';
        for ($i = 1; $i <= 5; $i++) {
            $checked = ($i <= (int) $this->value) ? ' checked' : '';
            $html .= '<input type="radio" name="' . $this->name . '" value="' . $i . '"' . $checked . '>';
        }
        $html .= '</div>';

        return $html;
    }
}
```

**Reference in form XML:**
```xml
<form addfieldprefix="Vendor\Component\Example\Administrator\Field">
    <field name="teacher_id" type="teacherlist" label="Teacher" />
    <field name="rating" type="starrating" label="Rating" />
</form>
```

**Key base classes to extend:**
- `ListField` — dropdown with dynamic options (`getOptions()`)
- `GroupedlistField` — grouped dropdown (`getGroups()`)
- `FormField` — fully custom rendering (`getInput()`)
- `TextField` — text input with extra logic
- `PredefinedlistField` — list with hardcoded options (`$predefinedOptions`)

## Field Layout Rendering

Modern fields use layouts for rendering, making them template-overridable:

```php
class MyField extends FormField
{
    // Layout file: layouts/joomla/form/field/myfield.php
    protected $layout = 'joomla.form.field.myfield';

    // collectLayoutData() is called automatically — override getLayoutData() to add custom data
    protected function getLayoutData(): array
    {
        $data = parent::getLayoutData();
        $data['customProp'] = $this->element['customprop'] ?? 'default';
        return $data;
    }
}
```

The layout file receives `$displayData` with all field metadata (`id`, `name`, `value`, `label`, `class`, `disabled`, `required`, `hint`, `description`, `field` object, etc.).
