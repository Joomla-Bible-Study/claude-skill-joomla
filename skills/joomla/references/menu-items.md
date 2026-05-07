# Joomla Menu Item Types Reference

Menu item types define what appears in the Joomla Menu Manager when administrators create menu items. Each site view can have one or more menu item types. This reference covers discovery, XML structure, single-item types, key XML elements, and multi-layout views.

## How Menu Item Types Are Discovered

Joomla scans `components/{component}/tmpl/{view}/` for XML files. Each `.xml` file becomes a selectable menu item type. The file name matches the layout name (e.g., `default.xml` → default layout, `blog.xml` → blog layout).

## Menu Item XML Structure

**File:** `site/tmpl/items/default.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<metadata>
    <layout title="COM_EXAMPLE_VIEW_ITEMS_TITLE"
            option="COM_EXAMPLE_VIEW_ITEMS_OPTION">
        <help key="Menu_Item:_Example_Items" />
        <message><![CDATA[COM_EXAMPLE_VIEW_ITEMS_DESC]]></message>
    </layout>

    <!-- Request fields — map to URL query parameters (required settings) -->
    <fields name="request">
        <fieldset name="request"
                  addfieldprefix="Vendor\Component\Example\Administrator\Field">
            <field name="id"
                   type="category"
                   extension="com_example"
                   label="COM_EXAMPLE_FIELD_SELECT_CATEGORY"
                   required="true" />
        </fieldset>
    </fields>

    <!-- Menu item parameters — optional display settings -->
    <fields name="params">
        <fieldset name="basic" label="JGLOBAL_FIELDSET_DISPLAY_OPTIONS">
            <field name="show_title"
                   type="list"
                   label="JGLOBAL_SHOW_TITLE_LABEL"
                   useglobal="true"
                   class="form-select-color-state"
                   validate="options">
                <option value="1">JSHOW</option>
                <option value="0">JHIDE</option>
            </field>

            <field name="items_per_page"
                   type="number"
                   label="COM_EXAMPLE_ITEMS_PER_PAGE"
                   useglobal="true"
                   min="1"
                   max="100" />

            <field name="orderby"
                   type="list"
                   label="JGLOBAL_ORDERING"
                   useglobal="true">
                <option value="a.title">JGLOBAL_TITLE</option>
                <option value="a.created">JDATE</option>
                <option value="a.ordering">JORDERING</option>
            </field>
        </fieldset>
    </fields>
</metadata>
```

## Single-Item Menu Item Type

**File:** `site/tmpl/item/default.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<metadata>
    <layout title="COM_EXAMPLE_VIEW_ITEM_TITLE">
        <message><![CDATA[COM_EXAMPLE_VIEW_ITEM_DESC]]></message>
    </layout>

    <fields name="request">
        <fieldset name="request"
                  addfieldprefix="Vendor\Component\Example\Administrator\Field">
            <field name="id"
                   type="modal_example"
                   label="COM_EXAMPLE_FIELD_SELECT_ITEM"
                   required="true"
                   select="true"
                   new="true"
                   edit="true"
                   clear="true" />
        </fieldset>
    </fields>

    <fields name="params">
        <fieldset name="basic" label="JGLOBAL_FIELDSET_DISPLAY_OPTIONS">
            <field name="show_author"
                   type="list"
                   label="COM_EXAMPLE_SHOW_AUTHOR"
                   useglobal="true">
                <option value="1">JSHOW</option>
                <option value="0">JHIDE</option>
            </field>
        </fieldset>
    </fields>
</metadata>
```

## Key Elements

**`<layout>`** — defines the menu item type name and description:
- `title` — language constant shown in Menu Manager type selector
- `option` — secondary description (optional)
- `<message>` — longer description displayed when creating the menu item

**`<fields name="request">`** — URL parameters that identify what content to display:
- These become the `&id=X` or `&catid=Y` in the URL
- Shown in the "Required Settings" section of the menu item editor
- Common: `type="category"` for list views, `type="modal_article"` / custom modal for single items

**`<fields name="params">`** — display options that customize rendering:
- Organized into fieldsets that appear as tabs
- `useglobal="true"` adds a "Use Global" option that falls back to `config.xml` component settings
- Accessed in site code via `$app->getParams()->get('show_title', 1)`

**`useglobal="true"`** — critical attribute. When set, the field gets an extra "Use Global" option that inherits from the component's `config.xml` settings. This is how Joomla's cascading parameter system works: Global config → Menu item params → merged result.

## Multiple Layouts Per View

A view can offer multiple layout variants. Each gets its own XML file:

```
site/tmpl/items/
├── default.php       ← Default list layout
├── default.xml       ← Menu item type: "Items - Default"
├── blog.php          ← Blog-style layout
├── blog.xml          ← Menu item type: "Items - Blog"
└── compact.php       ← Compact layout (no menu item type — not linkable from menus)
```

Only layouts with a matching `.xml` file appear in the Menu Manager. Layouts without XML can still be used via `&layout=compact` in URLs but aren't selectable as menu item types.
