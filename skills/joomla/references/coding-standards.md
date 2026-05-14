# Joomla Coding Standards Reference

Joomla code follows PSR-12 (PHP) and a Joomla ESLint config (JavaScript), with specific docblock conventions enforced by `joomla/coding-standards` (PHP_CodeSniffer ruleset). This reference covers PHPDoc layout rules, JS/ESLint conventions, PHPCS setup, and inline-comment rules.

## PHPDoc / DocBlocks

All PHP code must include proper docblocks following Joomla conventions. Whitespace inside docblocks uses **real spaces** (not tabs). The minimum spacing between tag elements (type, variable name, description) is **two spaces**, aligned to the longest element in the block.

**File header (required on every PHP file):**
```php
<?php

/**
 * @package     Vendor.Administrator
 * @subpackage  com_mycomponent
 *
 * @copyright   (C) 2025 Vendor Name. <https://example.com>
 * @license     GNU General Public License version 2 or later; see LICENSE.txt
 */
```

**Class docblock:**
```php
/**
 * Model for a single booking item.
 *
 * @since  1.0.0
 */
class BookingModel extends AdminModel
```

The `@since` tag is **required** on every class and indicates the version when the class was introduced.

**Property docblock:**
```php
/**
 * The prefix to use with controller messages.
 *
 * @var    string
 * @since  1.0.0
 */
protected $text_prefix = 'COM_BOOKINGS';
```

**Method docblock:**
```php
/**
 * Method to get the record form.
 *
 * @param   array    $data      Data for the form.
 * @param   boolean  $loadData  True if the form is to load its own data.
 *
 * @return  Form|boolean  A Form object on success, false on failure.
 *
 * @since   1.0.0
 * @throws  \Exception
 */
public function getForm($data = [], $loadData = true)
```

Key rules for method docblocks:

- `@param` — type, two+ spaces, `$variable`, two+ spaces, description. Align all `@param` entries.
- After the last `@param`, add a blank comment line before `@return`.
- `@return` — type and description. Always required (use `void` for no return).
- After `@return`, add a blank comment line before `@since`.
- `@since` — **required** on every public/protected method. Version when introduced.
- `@throws` — list each exception type the method can throw. No description needed.
- `@deprecated` — include when the method is deprecated, with a `@see` pointing to the replacement.

**Deprecated method example:**
```php
/**
 * Get the database driver.
 *
 * @return  DatabaseInterface
 *
 * @since       1.0.0
 * @deprecated  2.0.0  Use getDatabase() instead.
 * @see         getDatabase()
 */
public function getDbo()
```

**Tags NOT used in Joomla project code:** `@author` (prohibited in Joomla-owned code, allowed in third-party extensions), `@category` (rarely used).

## JavaScript / ESLint

Joomla core uses ESLint flat config (`eslint.config.mjs`) with the Airbnb preset. For extensions, match these conventions:

```javascript
// eslint.config.mjs
import { defineConfig } from 'eslint/config';

export default defineConfig([
    {
        files: ['media/**/*.js', 'build/**/*.js'],
        rules: {
            'no-restricted-globals': 'error',
        },
        languageOptions: {
            globals: {
                Joomla:    'readonly',  // Joomla core JS API
                bootstrap: 'readonly',  // Bootstrap JS (bundled with Joomla)
            },
        },
    },
]);
```

Key JavaScript conventions:

- ES6+ module syntax (`import`/`export`); no `var` (use `const`/`let`).
- The `Joomla` global is available on all frontend/admin pages and provides `Joomla.Text`, `Joomla.submitform`, `Joomla.renderMessages`, etc.
- Source JS goes in `build/media_source/`; compiled output to `media/com_mycomponent/js/`. Modern files use the `.es6.js` extension so Rollup transpiles them; legacy files use `.es5.js` so ESLint skips them.

## JavaScript / JSDoc (recommended extended convention)

Joomla's published JavaScript coding standard is Airbnb-based and does not formally specify a JSDoc layout. In `joomla-cms/build/media_source/` ~85% of source files carry only a minimal `@copyright` / `@license` header at the top, and full JSDoc on classes / methods is the minority (~10–28% of files use `@since` / `@param` / `@returns`). What follows is **not a published Joomla rule** — it is a recommended extended convention for extension authors who want full PHPDoc-style JSDoc throughout their JS for IDE type-hinting and parity with the PHP side. Enforce it via `eslint-plugin-jsdoc` rules.

**File header (recommended on every JS file):**
```javascript
/**
 * @package     Vendor.Administrator
 * @subpackage  com_mycomponent
 *
 * @copyright   (C) 2025 Vendor Name. <https://example.com>
 * @license     GNU General Public License version 2 or later; see LICENSE.txt
 */
```

**Class docblock:**
```javascript
/**
 * Controller for the items list view.
 *
 * @since  1.0.0
 */
export class ItemsListController
```

**Property / field docblock:**
```javascript
/**
 * The container element being controlled.
 *
 * @type   {HTMLElement}
 * @since  1.0.0
 */
container;
```

**Method / function docblock:**
```javascript
/**
 * Refresh the items list via AJAX.
 *
 * @param   {HTMLElement}  container  The list container element.
 * @param   {Object}       [options]  Optional rendering options.
 *
 * @returns {Promise<Object>}  Resolves with the response payload.
 *
 * @since   1.0.0
 * @throws  {Error}  If the request fails.
 */
export async function refreshList(container, options = {})
```

Key rules (mirror the PHPDoc rules above for visual consistency):

- Whitespace inside docblocks uses real spaces, not tabs.
- Minimum spacing between tag elements (type, name, description) is two spaces, aligned to the longest element in the block.
- `@param` — type in `{braces}`, two+ spaces, `paramName`, two+ spaces, description. Align all `@param` entries.
- After the last `@param`, add a blank comment line before `@returns`.
- `@returns` — type and description. Always required (use `{void}` for no return). Use `@returns` (not `@return`) to match the JSDoc spec.
- After `@returns`, add a blank comment line before `@since`.
- `@since` — required on every exported function, class, and method. Version when introduced.
- `@throws` — list each error type the function can throw. Type in `{braces}`.
- `@deprecated` — include when deprecated, with `@see` pointing to the replacement.
- Optional parameters use brackets in the name: `[options]`. Default values: `[options.autoplay=false]`.

**Tags NOT used:** `@author` (matches the PHPDoc rule above — prohibited in Joomla-owned code, allowed in third-party extensions), `@category` (rarely used). Arrow functions used as inline callbacks don't require JSDoc; top-level arrow functions assigned to constants do.

**Deprecated function example:**
```javascript
/**
 * Get the legacy player instance.
 *
 * @returns {Player}
 *
 * @since       1.0.0
 * @deprecated  2.0.0  Use getPlayer() instead.
 * @see         getPlayer()
 */
function getInstance()
```

## PHP_CodeSniffer

Joomla provides a custom ruleset via the `joomla/coding-standards` Composer package:

```bash
composer require --dev joomla/coding-standards
```

Run with:
```bash
./vendor/bin/phpcs --standard=Joomla src/
```

Or add a `phpcs.xml` at the project root:
```xml
<?xml version="1.0"?>
<ruleset name="My Component">
    <rule ref="Joomla"/>
    <file>admin/src</file>
    <file>site/src</file>
    <exclude-pattern>*/vendor/*</exclude-pattern>
    <exclude-pattern>*/node_modules/*</exclude-pattern>
</ruleset>
```

## Inline Comments

- Use C++ style (`//`) for code comments, with a space after `//`
- C-style block comments (`/* */`) are **only** for file/class/method docblocks
- Perl/shell style (`#`) comments are **not** allowed in PHP files
