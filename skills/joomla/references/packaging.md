# Joomla Extension Packaging Reference

Joomla extensions are distributed as ZIP files that users install through the Joomla admin installer (`System → Install → Extensions`). This reference covers manual packaging, build scripts, package extensions (multi-extension bundles), and what to include vs. exclude from the ZIP.

## Manual Packaging

The simplest approach — zip the extension files according to the manifest structure:

```bash
# For a component
cd /path/to/com_mycomponent
zip -r ../com_mycomponent-1.0.0.zip \
    mycomponent.xml \
    admin/ \
    site/ \
    media/ \
    --exclude "*/node_modules/*" \
    --exclude "*/.git/*" \
    --exclude "*/build/*" \
    --exclude "*/__pycache__/*" \
    --exclude "*.DS_Store"
```

For a plugin:
```bash
cd /path/to/plg_content_myplugin
zip -r ../plg_content_myplugin-1.0.0.zip \
    myplugin.xml \
    services/ \
    src/ \
    language/
```

## Build Script Pattern

Most production extensions use a build script. A typical `build.sh`:

```bash
#!/bin/bash
VERSION=$(grep '<version>' mycomponent.xml | sed 's/.*<version>\(.*\)<\/version>.*/\1/')
PACKAGE="com_mycomponent-${VERSION}.zip"

# Build front-end assets if needed
if [ -f package.json ]; then
    npm ci && npm run build
fi

# Install PHP dependencies (production only)
if [ -f composer.json ]; then
    composer install --no-dev --optimize-autoloader
fi

# Create the ZIP
rm -f "${PACKAGE}"
zip -r "${PACKAGE}" \
    mycomponent.xml \
    admin/ \
    site/ \
    media/ \
    --exclude "*/node_modules/*" \
    --exclude "*/build/*" \
    --exclude "*/.git/*" \
    --exclude "*.map"

echo "Built: ${PACKAGE}"
```

## Package Extensions (Multiple Extensions in One)

For projects that ship a component with associated plugins and modules, use a package manifest:

```xml
<?xml version="1.0" encoding="utf-8"?>
<extension type="package" method="upgrade">
    <name>pkg_mypackage</name>
    <packagename>mypackage</packagename>
    <version>1.0.0</version>
    <description>PKG_MYPACKAGE_XML_DESCRIPTION</description>
    <files>
        <file type="component" id="com_mycomponent">com_mycomponent.zip</file>
        <file type="plugin" id="plg_content_mycomponent" group="content">plg_content_mycomponent.zip</file>
        <file type="plugin" id="plg_finder_mycomponent" group="finder">plg_finder_mycomponent.zip</file>
        <file type="module" id="mod_mycomponent" client="site">mod_mycomponent.zip</file>
    </files>
</extension>
```

Build each extension as its own ZIP first, then package them together:

```bash
# Build individual ZIPs
cd components/com_mycomponent && zip -r ../../dist/com_mycomponent.zip . && cd ../..
cd plugins/content/mycomponent && zip -r ../../../dist/plg_content_mycomponent.zip . && cd ../../..
cd modules/site/mod_mycomponent && zip -r ../../../dist/mod_mycomponent.zip . && cd ../../..

# Build the package ZIP
cd dist
zip pkg_mypackage-1.0.0.zip \
    pkg_mypackage.xml \
    com_mycomponent.zip \
    plg_content_mycomponent.zip \
    mod_mycomponent.zip
```

## What Goes in the ZIP (and What Doesn't)

**Include:**
- Manifest XML (required, at ZIP root)
- `admin/`, `site/`, `media/` directories
- `services/provider.php`
- `src/` with all PHP classes
- `forms/`, `tmpl/`, `sql/`, `language/`
- `libraries/vendor/` if shipping third-party PHP libs (with autoload)
- Compiled CSS/JS in `media/`

**Exclude:**
- `node_modules/`, `build/`, `.git/`, `.github/`
- `tests/`, `phpunit.xml`, `.phpcs.xml`
- `composer.json`, `composer.lock` (dev tooling, not needed at runtime)
- `package.json`, `package-lock.json`
- Source SCSS/TypeScript files
- `.env`, credentials, IDE config (`.idea/`, `.vscode/`)
- `*.map` source map files (unless debugging is needed)
