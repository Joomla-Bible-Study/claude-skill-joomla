# Web Asset Management (`joomla.asset.json`)

Joomla's Web Asset Manager (WAM) replaces the older `JHtml::stylesheet()` / `JHtml::script()` pattern. Assets are declared once in `joomla.asset.json` with dependencies, then activated per-view via `useStyle()` / `useScript()`. Joomla resolves dependency order and emits the right `<link>` / `<script>` tags.

## Asset declaration

**File:** `media/com_mycomponent/joomla.asset.json`

```json
{
  "$schema": "https://developer.joomla.org/schemas/json-schema/web_assets.json",
  "name": "com_mycomponent",
  "version": "1.0.0",
  "assets": [
    {
      "name": "com_mycomponent.admin",
      "type": "style",
      "uri": "com_mycomponent/admin.css"
    },
    {
      "name": "com_mycomponent.admin.script",
      "type": "script",
      "uri": "com_mycomponent/admin.js",
      "dependencies": ["core"]
    }
  ]
}
```

The `uri` is resolved against the `media/` directory at runtime. Asset names use dot notation by convention (`{extension}.{purpose}` or `{extension}.{purpose}.{variant}`).

## Activating assets in a view

```php
/** @var Joomla\CMS\WebAsset\WebAssetManager $wa */
$wa = $this->getDocument()->getWebAssetManager();
$wa->useStyle('com_mycomponent.admin');
$wa->useScript('com_mycomponent.admin.script');
```

WAM automatically pulls in any declared dependencies, so registering `useScript('com_mycomponent.admin.script')` also loads `core` (Joomla's core JS).

## Common asset attributes

- `dependencies` — array of other asset names that must load first (`["core", "bootstrap.es5"]`).
- `attributes` — object of HTML attributes to add to the emitted tag (e.g., `"defer": true`, `"type": "module"`).
- `version` — busts CDN/browser caches; the WAM appends it as a query string.

## Gotchas

WAM has a few sharp edges around URI resolution, inline assets, and non-standard paths that have bitten many extension developers. The full pitfall list lives in [`gotchas.md`](gotchas.md) under the "WAM" headings — read it before debugging "why isn't my asset loading?"

## Manifest packaging

For the `<media>` block in the manifest XML that ships `joomla.asset.json` and the `css/` / `js/` folders alongside the extension, see [`manifest.md`](manifest.md).
