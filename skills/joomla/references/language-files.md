# Joomla Language Files Reference

Joomla extensions ship strings as `.ini` files that get copied into Joomla's `language/<tag>/` and `administrator/language/<tag>/` directories at install time. PHP resolves keys via `Text::_()` and `Text::plural()`; JavaScript reads them through `Joomla.Text._()` after server-side registration with `Text::script()`.

This is **cross-cutting** — every extension type (component, module, plugin, library) follows the same key conventions and the same registration model. Only the **prefix** and **file location** differ.

## Prefix by extension type

| Type | Key prefix | Example |
|------|-----------|---------|
| Component | `COM_<ELEMENT>_` | `COM_EXAMPLE_NEW_ITEM` |
| Module | `MOD_<ELEMENT>_` | `MOD_LATESTNEWS_NEW_ITEM` |
| Plugin | `PLG_<GROUP>_<ELEMENT>_` | `PLG_CONTENT_EXAMPLE_TITLE` |
| Library | `LIB_<ELEMENT>_` | `LIB_MYLIB_LOAD_FAILED` |
| Template | `TPL_<ELEMENT>_` | `TPL_MYTEMPLATE_HEADER_TAGLINE` |

`<ELEMENT>` is the manifest's `<name>` value (without the `com_`/`mod_`/`lib_` prefix), upper-cased. `<GROUP>` for plugins is the plugin group (`content`, `system`, `user`, etc.), upper-cased.

## File naming and location

The locale prefix in the **filename** distinguishes the source-tree layout from the legacy admin-installed layout:

```
# Source tree (recommended for new extensions, J5+):
admin/language/en-GB/en-GB.com_example.ini       # Component admin strings
admin/language/en-GB/en-GB.com_example.sys.ini   # Component install/extension-list strings
site/language/en-GB/en-GB.com_example.ini        # Component site strings

mod_latestnews/language/en-GB/en-GB.mod_latestnews.ini
mod_latestnews/language/en-GB/en-GB.mod_latestnews.sys.ini

plg_content_example/language/en-GB/en-GB.plg_content_example.ini
plg_content_example/language/en-GB/en-GB.plg_content_example.sys.ini

# Legacy admin-installed (still works on J5/J6, NOT recommended for new extensions):
administrator/language/en-GB/com_example.ini
```

The `<languages folder="…">` block in the manifest tells Joomla where to find them in the source tree:

```xml
<!-- component (admin-side strings) -->
<languages folder="admin">
    <language tag="en-GB">language/en-GB/en-GB.com_example.ini</language>
    <language tag="en-GB">language/en-GB/en-GB.com_example.sys.ini</language>
</languages>

<!-- module / plugin (one languages block; folder relative to manifest) -->
<languages>
    <language tag="en-GB">language/en-GB/en-GB.mod_latestnews.ini</language>
    <language tag="en-GB">language/en-GB/en-GB.mod_latestnews.sys.ini</language>
</languages>
```

**The `<languages>` element does not gate runtime loading for components.** Joomla auto-discovers `{admin,site}/language/{locale}/{locale}.com_*.ini` whenever the user's site language matches a present locale, regardless of manifest declarations. The element is primarily about (a) telling the package installer which files to copy from the install zip into the destination tree, and (b) ensuring `.sys.ini` strings render correctly in the Extension Manager dialog at install time. For modules and plugins, Joomla likewise auto-discovers `{module,plugin}/language/{locale}/` files at runtime. So shipping translations under `admin/language/cs-CZ/`, `de-DE/`, `es-ES/` etc. without listing each in `<languages>` is fine — those locales still load when a user's site language matches.

## `.sys.ini` vs `.ini`

`.sys.ini` is **loaded during install** and by the Extension Manager / Plugin Manager listings. Keep it small — only strings the installer or admin extension-listing UI shows:

```ini
COM_EXAMPLE="Example"
COM_EXAMPLE_XML_DESCRIPTION="Example component for Joomla 5+/6 — manages a list of items."
COM_EXAMPLE_MENU_ITEMS="Items"
COM_EXAMPLE_MENU_OPTIONS="Options"
```

For plugins, the `.sys.ini` is also where `<config>` field labels and the plugin description shown on the Plugins page live. Plugins **must** set `$autoloadLanguage = true` on the plugin class for Joomla to load the regular `.ini` from the plugin directory at runtime — without it, runtime keys appear as raw strings.

`.ini` (no `.sys`) holds the rest: view labels, toolbar text, form fields, errors, messages.

```ini
; Toolbar / list view
COM_EXAMPLE_NEW_ITEM="New Item"
COM_EXAMPLE_EDIT_ITEM="Edit Item"
COM_EXAMPLE_N_ITEMS_PUBLISHED="%d items published."
COM_EXAMPLE_N_ITEMS_UNPUBLISHED="%d items unpublished."

; Form fields
COM_EXAMPLE_FIELD_TITLE_LABEL="Title"
COM_EXAMPLE_FIELD_TITLE_DESC="The display title shown to site visitors."
COM_EXAMPLE_FIELD_ALIAS_LABEL="Alias"
COM_EXAMPLE_FIELD_PUBLISHED_LABEL="Status"

; Filter form (searchtools)
COM_EXAMPLE_FILTER_SEARCH_LABEL="Search"
COM_EXAMPLE_FILTER_SEARCH_DESC="Search by title or alias."

; Errors / messages
COM_EXAMPLE_ERROR_UNIQUE_ALIAS="The alias %s is already in use."
COM_EXAMPLE_SAVE_SUCCESS="Item saved successfully."
```

## Naming conventions

- **All keys uppercase**, prefix-namespaced (`COM_<ELEMENT>_…`), `_` as separator. Never use spaces or hyphens.
- **Form field labels and descriptions** follow `_FIELD_<NAME>_LABEL` / `_FIELD_<NAME>_DESC`. The `<field label="...">` attribute should reference the `_LABEL` key directly (Joomla appends nothing).
- **Toolbar buttons:** `<PREFIX>_NEW_<ENTITY>`, `<PREFIX>_EDIT_<ENTITY>`, `<PREFIX>_DELETE_<ENTITY>`, `<PREFIX>_PUBLISH_<ENTITY>`, etc.
- **Filter form (searchtools):** `<PREFIX>_FILTER_<NAME>_LABEL` / `_DESC`.
- **Errors:** `<PREFIX>_ERROR_<NAME>` (often paired with `sprintf` placeholders).
- **Plugin XML description:** must be `PLG_<GROUP>_<ELEMENT>_XML_DESCRIPTION`.
- **Task plugin keys:** the `langConstPrefix` defined in `TASKS_MAP` is appended with `_TITLE` and `_DESC` by `TaskPluginTrait` — both keys must exist or the task selector shows raw keys. See `references/gotchas.md`.

## Plurals

Joomla picks the right form based on `$count`:

```php
echo Text::plural('COM_EXAMPLE_N_ITEMS', $count);
```

```ini
COM_EXAMPLE_N_ITEMS_0="No items"
COM_EXAMPLE_N_ITEMS_1="One item"
COM_EXAMPLE_N_ITEMS_MORE="%d items"
```

The `_0`, `_1`, `_MORE` suffixes are required. Missing one falls through to the base key, which Joomla then renders as the raw key string.

## Loading strings into JavaScript

`Joomla.Text._('KEY')` only finds keys that have been registered server-side with `Text::script()`. Register them where the strings are first needed:

- **Components:** in `HtmlView::display()`, before the template renders.
- **Modules:** in the dispatcher's `dispatch()` method, before `parent::dispatch()` includes the layout.
- **Plugins:** in the event handler that injects the script (typically the same handler that calls `$wa->registerScript`).

```php
// In HtmlView::display() or Dispatcher::dispatch()
Text::script('COM_EXAMPLE_CONFIRM_DELETE');
Text::script('COM_EXAMPLE_SAVING');
```

**Pitfall:** unregistered keys return the **raw key string** (which is truthy), so `Joomla.Text._('KEY') || 'fallback'` never falls back. Compare against the key itself — see `references/gotchas.md` for the pattern.

## What NOT to do

- **Don't ship strings the extension never uses.** Extra keys bloat the `.ini` file and slow `Joomla.Text._()` lookups when registered with `Text::script()`.
- **Don't put PHP-only strings in `.sys.ini`.** That file is parsed during install on every extension list refresh; keep it minimal.
- **Don't omit the locale prefix in source-tree filenames.** `language/en-GB/com_example.ini` is the legacy admin-installed name; new extensions use `language/en-GB/en-GB.com_example.ini`.
- **Don't hardcode language strings in PHP.** Always go through `Text::_()` so translations work.
