# Update Server

The update server tells Joomla where to check for new versions of your extension. When a site admin clicks "Check for updates", Joomla fetches the update XML you host and matches it against the installed version. Pair this with a `<changelogurl>` so admins can preview changes before installing — see [`packaging.md`](packaging.md) § Changelog XML for the changelog file format.

## Manifest wiring

Add `<updateservers>` to the extension manifest. The full universal manifest elements are in [`manifest.md`](manifest.md); the relevant block:

```xml
<changelogurl>https://example.com/changelogs/com_mycomponent/changelog.xml</changelogurl>
<updateservers>
    <server type="extension" name="My Component Updates">https://example.com/updates/com_mycomponent_update.xml</server>
</updateservers>
```

## Update server XML

```xml
<?xml version="1.0" encoding="utf-8"?>
<updates>
    <update>
        <name>My Component</name>
        <description>My Component for Joomla</description>
        <element>com_mycomponent</element>
        <type>component</type>
        <version>1.1.0</version>
        <infourl title="My Component 1.1.0 Release">https://example.com/releases/1.1.0</infourl>
        <downloads>
            <downloadurl type="full" format="zip">https://example.com/downloads/com_mycomponent-1.1.0.zip</downloadurl>
        </downloads>
        <tags>
            <tag>stable</tag>
        </tags>
        <targetplatform name="joomla" version="6\.[0-9]+" />
        <php_minimum>8.3.0</php_minimum>
        <sha256>abc123...</sha256>
        <sha384>def456...</sha384>
        <sha512>ghi789...</sha512>
        <maintainer>Vendor Name</maintainer>
        <maintainerurl>https://example.com</maintainerurl>
        <changelogurl>https://example.com/changelogs/com_mycomponent/changelog.xml</changelogurl>
    </update>
</updates>
```

## Key fields

- `<targetplatform>` uses a **regex** for Joomla version matching:
  - `6\.[0-9]+` → all Joomla 6.x
  - `5\.[0-9]+` → all Joomla 5.x
  - `(5|6)\.[0-9]+` → both lines for a J5/J6 dual-support release
- `<php_minimum>` — minimum PHP version required (the install script's `preflight()` should enforce this too).
- `<sha256>` / `<sha384>` / `<sha512>` — integrity hashes of the download. Joomla verifies these after fetching the ZIP. Strongly recommended.
- Add multiple `<update>` blocks for different version tracks (e.g., one for J5 builds, one for J6 builds, distinguished by `<targetplatform>`).
- `<changelogurl>` here links the same changelog XML the manifest references so Joomla can show changes before updating.

## Per-extension-type tweaks

- **Plugins** — add `folder="plugingroup"` and `client="site"` attributes to the `<update>` element.
- **Modules** — add `client="site"` or `client="administrator"` so Joomla matches the right entry.
- **Templates, libraries, packages** — `<type>` should match the manifest's extension type; `<element>` should match the installed name (e.g., `tpl_mytheme`, `lib_mylib`, `pkg_mypackage`).
