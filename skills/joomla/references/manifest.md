# Joomla Manifest XML Reference

Every Joomla extension ships a manifest XML at the package root that tells the installer what to copy where, what to register in the database, and how Joomla should later check for updates. The `<extension type="…">` attribute selects the schema; a few elements are universal across types and several are type-specific.

This reference covers the **universal** elements. For complete worked manifests see:

- Components: [`references/component.md` § Manifest XML Template](component.md#manifest-xml-template)
- Modules: [`references/module.md`](module.md)
- Plugins: [`references/plugin.md`](plugin.md)
- Libraries: [`references/library.md`](library.md)

## `<extension>` root attributes

```xml
<extension type="component" method="upgrade">
```

| Attribute | Required | Values |
|-----------|----------|--------|
| `type` | yes | `component`, `module`, `plugin`, `library`, `template`, `package`, `file` |
| `method` | no | `install` (default) or `upgrade`. Use `upgrade` so subsequent installs of the same extension run the update flow instead of failing. |
| `version` | no | The schema version the manifest is written against. Joomla defaults to the current; explicit versions are unusual. |
| `client` | only for modules and templates | `site` or `administrator` |
| `group` | only for plugins | The plugin group (`content`, `system`, `user`, `editors-xtd`, etc.) |

## Universal metadata block

Every extension type starts with the same metadata. Joomla shows these in the Extensions list and the update server.

```xml
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
```

**Notes:**

- `<name>` is the **install element** with the type prefix (`com_*`, `mod_*`, `plg_*`, `lib_*`). Joomla derives the database key, the language file element, and folder names from this.
- `<description>` should be a language key (not literal text), resolved from the `.sys.ini` so the Extensions list is translatable.
- `<namespace path="src">` is required for J5+ extensions. The `path` attribute names the source directory relative to the manifest; the text content is the PSR-4 root namespace. Joomla wires up autoloading from this.
- `<version>` follows SemVer. Joomla compares versions across update servers and `#__schemas` rows using PHP's `version_compare()`.

## `<scriptfile>` — install/update PHP

Optional but recommended for any extension that needs install-time logic:

```xml
<scriptfile>example.script.php</scriptfile>
```

The class inside follows the lifecycle hooks (`preflight` / `install` / `update` / `postflight` / `uninstall`). The class-naming convention varies by extension type (`Com_*InstallerScript`, `Mod_*InstallerScript`, `Plg<Group><Element>InstallerScript`). See [`references/install-script.md`](install-script.md) for the full pattern.

## `<files>` and `<media>`

`<files>` lists what the installer copies into the extension's filesystem location:

```xml
<files folder="site">
    <folder>forms</folder>
    <folder>layouts</folder>
    <folder>src</folder>
    <folder>tmpl</folder>
</files>
```

`<media>` copies asset files into `media/<destination>/`, which Joomla's Web Asset Manager auto-resolves:

```xml
<media destination="com_example" folder="media">
    <filename>joomla.asset.json</filename>
    <folder>css</folder>
    <folder>js</folder>
    <folder>images</folder>
</media>
```

**Both** `<files>` **and** `<media>` are universal across extension types. The `folder=""` attribute is the source directory in your build; the `<folder>`/`<filename>` children are what gets copied. The `destination=""` on `<media>` is the directory under `media/` to create. Don't include `css/` / `js/` subdirectories in `joomla.asset.json` URIs — Joomla auto-resolves them. See `references/gotchas.md` § "WAM URI Auto-Resolution".

## `<languages>`

Tells Joomla which `.ini` files to copy where:

```xml
<!-- component (admin-side strings) -->
<languages folder="admin">
    <language tag="en-GB">language/en-GB/en-GB.com_example.ini</language>
    <language tag="en-GB">language/en-GB/en-GB.com_example.sys.ini</language>
</languages>

<!-- module / plugin (single block, folder relative to manifest) -->
<languages>
    <language tag="en-GB">language/en-GB/en-GB.mod_latestnews.ini</language>
    <language tag="en-GB">language/en-GB/en-GB.mod_latestnews.sys.ini</language>
</languages>
```

The locale prefix (`en-GB.`) in the source-tree filename is required. See [`references/language-files.md`](language-files.md) for naming conventions, key prefixes per extension type, plurals, and `Text::script()` registration.

## `<update>` and `<updateservers>`

Universal across extension types. `<update>` describes schema migrations applied during install/update; `<updateservers>` points the user's site at an XML feed Joomla polls for new versions.

```xml
<update>
    <schemas>
        <schemapath type="mysql">sql/updates/mysql</schemapath>
    </schemas>
</update>

<changelogurl>https://example.com/changelog.xml</changelogurl>
<updateservers>
    <server type="extension" priority="1" name="Example Updates">
        https://example.com/updates.xml
    </server>
</updateservers>
```

**Update server XML** (the file the URL above points at) is the same shape regardless of extension type:

```xml
<?xml version="1.0" encoding="utf-8"?>
<updates>
    <update>
        <name>Example</name>
        <description>COM_EXAMPLE_XML_DESCRIPTION</description>
        <element>com_example</element>
        <type>component</type>
        <version>1.1.0</version>
        <infourl title="Release Notes">https://example.com/release-1.1.0</infourl>
        <downloads>
            <downloadurl type="full" format="zip">https://example.com/downloads/com_example-1.1.0.zip</downloadurl>
        </downloads>
        <tags><tag>stable</tag></tags>
        <targetplatform name="joomla" version="6\.[0-9]+" />
        <php_minimum>8.3.0</php_minimum>
        <sha256>...</sha256>
        <maintainer>Vendor Name</maintainer>
        <maintainerurl>https://example.com</maintainerurl>
    </update>
</updates>
```

`<targetplatform name="joomla" version="…">` takes a regex over Joomla minor versions. `<php_minimum>` should match the Joomla 6.x floor — currently `8.3.0` (see `SKILL.md` for the citation).

The `<changelog>` XML pointed at by `<changelogurl>` follows a parallel schema with `<add>`, `<change>`, `<remove>`, `<note>` blocks — see the changelog example in [`references/component.md` § Manifest XML Template](component.md#manifest-xml-template).

## `<install>` (DDL)

Components (and occasionally plugins / libraries) declare DDL-only SQL files Joomla runs at install/update:

```xml
<install>
    <sql>
        <file driver="mysql" charset="utf8">sql/install.mysql.utf8.sql</file>
    </sql>
</install>
```

Modules rarely need this. For SQL conventions see [`references/component.md` § Database Schema & Migrations](component.md#database-schema--migrations).

## Type-specific blocks (NOT covered here)

Each extension type adds its own elements on top of the universal ones:

- **Component:** `<administration>` with `<menu>`, `<submenu>`, and a second `<files>` block for the admin-side filesystem. See [`references/component.md`](component.md).
- **Module:** `<position>` (default position), `<config>` for params (or a `config.xml` referenced from it). See [`references/module.md`](module.md).
- **Plugin:** `<group="…">` attribute on `<extension>`, `<config>` for plugin params. See [`references/plugin.md`](plugin.md).
- **Library:** `<libraryname>` element matching the install path. See [`references/library.md`](library.md).
- **Template:** `<positions>`, `<inheritable>`, `<parent>`, `<media>` paths under the template namespace.

## Common pitfalls

- **`<namespace path="src">` mismatch.** The text content has to match the namespace your `services/provider.php` passes to `MVCFactory`/`ComponentDispatcherFactory`/etc. Off-by-one (extra trailing `\\`, wrong vendor name) and nothing autoloads.
- **`<files folder="site">` typo.** If `folder` doesn't match the directory in your build output, the installer reports success but no files land.
- **Missing `<scriptfile>` reference path.** The path is **relative to the manifest** and must match exactly — Joomla won't search; it just fails to find the script.
- **`method="upgrade"` forgotten on a re-release.** Without it, installing v1.1 on top of v1.0 fails with "extension already installed".
- **`<targetplatform>` regex too loose.** `5\.[0-9]+` matches J5.0 through J5.99 — fine. `5\..*` matches `5.0.0-beta.thing` and similar; tighten if you care.
- **`<php_minimum>` lagging behind reality.** When Joomla 6.x bumped the minimum to 8.3, manifests still claiming `8.2.0` install fine but pass installs on PHP 8.2 systems where the code may not actually run.
