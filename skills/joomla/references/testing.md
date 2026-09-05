# Joomla Extension Testing Reference

PHPUnit (PHP) and Jest (JavaScript) patterns for Joomla 5+ extension testing. The core insight from Joomla's own test infrastructure: **load real CMS classes, don't stub them.** This validates your code against actual Joomla signatures and catches J5→J6 breaking changes automatically.

## Test Layers

Three layers, each answering a question the others cannot. **This reference covers the first two.**

| Layer | Mechanism | Answers |
|---|---|---|
| **Unit** | In-process, stubs and doubles | Does this class's logic work? |
| **Integration** | In-process, real CMS classes from a Joomla checkout | Does it work against Joomla's actual signatures? |
| **E2E** | PHPUnit on the host, over HTTP, against a disposable Docker stack | Does the running site behave correctly for a real request? |

The in-process layers are fast — they catch signature drift across Joomla versions in seconds, which no container run will match. Keep them.

What they cannot observe is anything that only exists in a real request: rendered template HTML, response headers and status codes, redirects, session and cookie behaviour, ACL as the actual dispatcher enforces it, `.htaccess` rules, and whether a refused request actually failed to change state. That is the third layer's job, and it is a separate skill in this suite — **`e2e-tests`**.

## Directory Structure

```
tests/
├── Unit/
│   ├── bootstrap.php          # Loads real Joomla CMS classes
│   ├── Admin/
│   │   ├── Helper/            # Admin helper tests
│   │   ├── Model/             # Admin model tests
│   │   └── Table/             # Table class tests
│   └── Site/
│       ├── Helper/            # Site helper tests
│       └── Model/             # Site model tests
├── Integration/
│   └── ...                    # Tests that require a database
└── js/
    └── *.test.js              # Jest tests for JavaScript
```

Mirror the `admin/src/` and `site/src/` structure inside `tests/Unit/` so test locations are predictable.

## PHPUnit Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="tests/Unit/bootstrap.php"
         colors="true"
         cacheDirectory="build/.phpunit.cache">
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Integration">
            <directory>tests/Integration</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory suffix=".php">admin/src</directory>
            <directory suffix=".php">site/src</directory>
        </include>
    </source>
</phpunit>
```

Define granular test suites (e.g., "Admin Helper Tests", "Site Model Tests") when you have enough tests to benefit from selective runs.

## Bootstrap: Load Real Joomla CMS

The key insight from Joomla core's own test infrastructure: **load the real CMS classes, don't stub them.** This validates your code against actual Joomla signatures, catching J5→J6 breaking changes automatically.

```php
<?php
// tests/Unit/bootstrap.php

// Point to a Joomla installation (configure via build.properties or env var)
$joomlaPath = getenv('JOOMLA_PATH') ?: '/path/to/joomla';

if (!is_dir($joomlaPath . '/libraries')) {
    throw new RuntimeException(
        'Joomla installation not found. Set JOOMLA_PATH environment variable.'
    );
}

// Define Joomla constants
define('JPATH_ROOT', $joomlaPath);
define('JPATH_BASE', JPATH_ROOT);
define('JPATH_SITE', JPATH_ROOT);
define('JPATH_ADMINISTRATOR', JPATH_ROOT . '/administrator');
define('JPATH_LIBRARIES', JPATH_ROOT . '/libraries');

// Load the REAL Joomla autoloader
require_once JPATH_LIBRARIES . '/loader.php';
require_once JPATH_LIBRARIES . '/vendor/autoload.php';

// Register the component's own autoloader
require_once dirname(__DIR__, 2) . '/vendor/autoload.php';
```

**Why real CMS, not stubs?** Stubs drift from the actual API. When Joomla 6 removes a method or changes a return type, tests using real classes catch it immediately. Stubs silently pass.

## Base Test Case with Query Stub

Joomla core's `UnitTestCase` provides a `getQueryStub()` helper — a minimal concrete `DatabaseQuery` that only needs 2 abstract methods. This is far simpler than stubbing the entire `DatabaseInterface`:

```php
<?php

namespace Vendor\Component\MyComponent\Tests;

use Joomla\Database\DatabaseInterface;
use Joomla\Database\DatabaseQuery;
use Joomla\Database\QueryInterface;
use PHPUnit\Framework\TestCase;

abstract class MyComponentTestCase extends TestCase
{
    /**
     * Create a real DatabaseQuery with only 2 abstract methods stubbed.
     * Gives you a working query builder with proper __toString().
     */
    protected function getQueryStub(DatabaseInterface $db): QueryInterface
    {
        return new class ($db) extends DatabaseQuery {
            public function groupConcat($expression, $separator = ','): string
            {
                return '';
            }

            public function processLimit($query, $limit, $offset = 0): string
            {
                return (string) $query;
            }
        };
    }
}
```

## Model Test Pattern

Use `createStub(DatabaseDriver::class)` for the database (see gotcha below about `DatabaseInterface` vs `DatabaseDriver`), wire up `getQueryStub()` for the query builder, and pass the stub via the model's config array:

```php
<?php

use Joomla\Database\DatabaseDriver;
use Joomla\CMS\MVC\Factory\MVCFactoryInterface;

class MyModelTest extends MyComponentTestCase
{
    public function testGetListQueryFilters(): void
    {
        $db = $this->createStub(DatabaseDriver::class);
        $db->method('createQuery')->willReturn($this->getQueryStub($db));
        $db->method('getPrefix')->willReturn('jos_');

        $model = new MyItemModel(
            ['dbo' => $db],
            $this->createStub(MVCFactoryInterface::class)
        );

        // Test the model behavior
        $this->assertInstanceOf(MyItemModel::class, $model);
    }
}
```

**Key points:**
- Models accept `['dbo' => $db]` in their config array — no need to mock the full DI container
- `getQueryStub()` gives you a real query builder, so `$query->select()`, `$query->where()`, and `$query->__toString()` all work correctly
- Stub additional methods as needed: `loadObject()`, `loadObjectList()`, `execute()`, `quoteName()`, etc.
- **Always stub `DatabaseDriver`**, not `DatabaseInterface`, when your code calls `createQuery()` (see Testing Gotchas below)

## Table Test Pattern

```php
$db = $this->createStub(DatabaseDriver::class);
$db->method('createQuery')->willReturn($this->getQueryStub($db));
$db->method('getPrefix')->willReturn('jos_');

$dispatcher = $this->createStub(DispatcherInterface::class);
$table = new MyTable($db, $dispatcher);

// Test check() validation
$table->title = '';
$this->expectException(\UnexpectedValueException::class);
$table->check();
```

## Helper / Utility Test Pattern

Pure functions and helpers are the simplest to test — no database stubs needed:

```php
class MyHelperTest extends MyComponentTestCase
{
    public function testFormatDuration(): void
    {
        $this->assertSame('1:30:00', MyHelper::formatDuration(5400));
        $this->assertSame('0:05:30', MyHelper::formatDuration(330));
    }
}
```

## JavaScript Tests (Jest)

Use Jest with jsdom for testing frontend JavaScript. Configure in `package.json`:

```json
{
  "jest": {
    "testEnvironment": "jsdom",
    "testMatch": ["<rootDir>/tests/js/**/*.test.js"],
    "coverageDirectory": "build/reports/coverage-js"
  }
}
```

For code that depends on `Joomla.Text._()` or other Joomla globals, mock them in a setup file or per-test:

```javascript
// Mock Joomla globals
beforeEach(() => {
    window.Joomla = {
        Text: {
            _: jest.fn((key) => key),
            strings: {}
        },
        getOptions: jest.fn(() => ({})),
        renderMessages: jest.fn()
    };
});
```

## What to Test (and What Not To)

**Do test:**
- Helper/utility methods (pure logic, formatting, calculations)
- Model query construction and filtering logic
- Table `check()` validation rules
- Custom form field logic
- JavaScript UI helpers and data transformations

**Don't test here:**
- Joomla framework internals (MVC routing, form binding, ACL checks)
- Simple getters/setters with no logic
- Template HTML output, response headers/status, redirects, session behaviour, and whether a refusal actually prevented the state change — these need a real request, so they belong to the **`e2e-tests`** skill's Docker-over-HTTP layer, not to an in-process test

## Testing Gotchas

**`DatabaseInterface` does NOT have `createQuery()`** — `createQuery()` lives on the abstract `DatabaseDriver` class, not on `DatabaseInterface`. When stubbing the database for tests that call `createQuery()`, you **must** use `createStub(DatabaseDriver::class)`, not `createStub(DatabaseInterface::class)`. PHPUnit will throw `MethodCannotBeConfiguredException` if you try to configure `createQuery()` on a `DatabaseInterface` stub.

```php
// WRONG — createQuery() is not on DatabaseInterface
$db = $this->createStub(DatabaseInterface::class);
$db->method('createQuery')->willReturn(...); // Throws!

// CORRECT — DatabaseDriver has createQuery()
$db = $this->createStub(DatabaseDriver::class);
$db->method('createQuery')->willReturn($this->getQueryStub($db)); // Works
```

**`CMSApplicationInterface` does NOT have `getSession()`** — `getSession()` is defined on `SessionAwareWebApplicationInterface` (from the framework) and mixed in via `SessionAwareWebApplicationTrait`. To stub an application with `getSession()`, use the concrete `CMSApplication` class:

```php
// WRONG — getSession() is not on CMSApplicationInterface
$app = $this->createStub(CMSApplicationInterface::class);
$app->method('getSession')->willReturn($session); // Throws!

// CORRECT — CMSApplication inherits getSession() via trait
$app = $this->createStub(CMSApplication::class);
$app->method('getSession')->willReturn($session); // Works
```

**Bootstrap must load Joomla's vendor autoloader** — A PSR-4 autoloader for `Joomla\CMS\*` classes (from `libraries/src/`) is not enough. Framework packages (`Joomla\Database\*`, `Joomla\Event\*`, `Joomla\Session\*`, etc.) live in `libraries/vendor/` and require loading `libraries/vendor/autoload.php`. Without this, any test stubbing framework interfaces will fail with "Class or interface does not exist".

```php
// In bootstrap.php — load BOTH autoloaders
require_once $joomlaCmsPath . '/libraries/vendor/autoload.php'; // Framework packages
// Then register your own PSR-4 autoloader for Joomla\CMS\* from libraries/src/
```

**`createMock()` vs `createStub()` for expectations** — PHPUnit's `createStub()` does not support `expects()`. If you need to assert that a method is (or isn't) called, use `createMock()` instead:

```php
// WRONG — expects() on a stub triggers a deprecation warning
$db = $this->createStub(DatabaseDriver::class);
$db->expects($this->never())->method('loadObject'); // Deprecated!

// CORRECT — use createMock() for expectations
$db = $this->createMock(DatabaseDriver::class);
$db->expects($this->never())->method('loadObject'); // Clean
```

## Composer Scripts

Add test commands to `composer.json`:

```json
{
  "scripts": {
    "test": "@test:unit",
    "test:unit": "phpunit --testsuite Unit",
    "test:integration": "phpunit --testsuite Integration",
    "check": ["@lint", "@test"]
  }
}
```
