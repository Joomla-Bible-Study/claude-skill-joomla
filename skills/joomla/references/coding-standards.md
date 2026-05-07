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

Joomla core uses ESLint flat config (`eslint.config.mjs`). For extensions, match these conventions:

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
                Joomla: true,        // Joomla core JS API
                bootstrap: true,     // Bootstrap JS (bundled with Joomla)
            },
        },
    },
]);
```

Key JavaScript conventions:

- ES6+ module syntax (`import`/`export`), no `var` (use `const`/`let`)
- `Joomla` global is available in all frontend/admin pages (provides `Joomla.Text`, `Joomla.submitform`, `Joomla.renderMessages`, etc.)
- Source JS goes in `build/media_source/` or a `build/` directory, compiled output goes to `media/com_mycomponent/js/`
- JSDoc comments on exported functions:

```javascript
/**
 * Refresh the items list via AJAX.
 *
 * @param {HTMLElement} container - The list container element.
 * @param {Object}      options   - Configuration options.
 * @param {number}      options.page - Page number to load.
 *
 * @returns {Promise<void>}
 *
 * @since 1.0.0
 */
export async function refreshList(container, options = {}) {
    // ...
}
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
