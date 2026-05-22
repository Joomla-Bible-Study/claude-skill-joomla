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

## Integrating a third-party vendor library

A repeatable workflow for adding a vendor JS/CSS library (Fancybox, Choices.js, etc.) into a Joomla extension's WAM-managed assets:

1. **Add the package to `package.json`** as a devDependency at the repository root, so the version is pinned and reproducible.
2. **Copy the dist files to `media/vendor/<libname>/`** via a build step (npm script, Phing target, etc.). Vendor assets do not live under `media/com_*/` — keeping them in `media/vendor/` allows reuse across extensions.
3. **Register in `joomla.asset.json` with a full literal path.** Vendor paths cannot use WAM's auto-resolution (see "WAM Non-Standard Paths" in [`gotchas.md`](gotchas.md)) — supply the full `media/vendor/<libname>/<file>` URI.
4. **Wrap the vendor asset with your own thin asset entries** that declare the vendor as a dependency. Your extension's view code activates the wrapper, not the vendor library directly:
   ```json
   { "name": "vendor.fancybox", "type": "script", "uri": "media/vendor/fancybox/fancybox.umd.js" },
   { "name": "com_mycomponent.fancybox", "type": "script", "uri": "com_mycomponent/fancybox-init.js",
     "dependencies": ["vendor.fancybox"] }
   ```
5. **Use `"attributes": {"defer": true}`** on non-critical JS so it doesn't block render. Most vendor UI libraries (carousels, lightboxes, datepickers) qualify.

```php
// In the view that needs it:
$wa->useScript('com_mycomponent.fancybox');
// WAM also pulls in vendor.fancybox automatically via the dependency.
```

## Gotchas

WAM has a few sharp edges around URI resolution, inline assets, and non-standard paths that have bitten many extension developers. The full pitfall list lives in [`gotchas.md`](gotchas.md) under the "WAM" headings — read it before debugging "why isn't my asset loading?"

## Manifest packaging

For the `<media>` block in the manifest XML that ships `joomla.asset.json` and the `css/` / `js/` folders alongside the extension, see [`manifest.md`](manifest.md).
