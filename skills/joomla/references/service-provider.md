# Joomla Service Provider Reference

The `services/provider.php` file is the DI bootstrap for an extension. Joomla discovers it via the manifest, calls `register()` on the returned object, and asks the resulting container for the extension's main class via a known interface (`ComponentInterface` for components, etc.).

This is **partly cross-cutting**:

- **The wrapping pattern is universal.** `ServiceProviderInterface` + an anonymous class with a `register(Container $container): void` method, calling `$container->registerServiceProvider(...)` for ready-made factories and `$container->set(...)` for the extension's own service. Same shape for components, modules, and plugins.
- **The factories registered are extension-specific.** A component registers `MVCFactory`, `ComponentDispatcherFactory`, `RouterFactory`, and (often) `CategoryFactory`. A module registers a `ModuleDispatcherFactory`. A plugin registers a `PluginFactory` and binds the plugin class.

This reference covers the universal wrapping pattern; the per-type factory bundles live in the extension's own reference file (component / module / plugin).

## Universal pattern

Every `services/provider.php` follows this skeleton:

```php
<?php

\defined('_JEXEC') or die;

use Joomla\DI\Container;
use Joomla\DI\ServiceProviderInterface;
// + per-extension imports for the factory provider classes and the main interface

return new class () implements ServiceProviderInterface {
    public function register(Container $container): void
    {
        // 1. Register ready-made factories from \Joomla\CMS\Extension\Service\Provider\*.
        //    Each "service provider" wires up a factory class for a slice of MVC.
        $container->registerServiceProvider(new SomeFactory('\\Vendor\\Component\\Example'));
        // ... more factories ...

        // 2. Bind the extension's own main class to the well-known interface so
        //    Joomla can resolve it. Inject the factories by their interfaces.
        $container->set(
            SomeInterface::class,
            function (Container $container) {
                $extension = new MyExtension(/* injected dependencies */);
                $extension->setSomething($container->get(SomethingInterface::class));
                return $extension;
            }
        );
    }
};
```

**File location** (manifest's `<files>` block must reach it):

| Type | Path |
|------|------|
| Component | `admin/services/provider.php` |
| Module | `services/provider.php` (alongside the dispatcher) |
| Plugin | `services/provider.php` (alongside `src/Extension/`) |

## What each extension type registers

| Type | Bound interface | Common factories |
|------|----------------|------------------|
| Component | `ComponentInterface` | `MVCFactory`, `ComponentDispatcherFactory`, `RouterFactory`, `CategoryFactory` (when the component has categories) |
| Module | `ModuleInterface` | `ModuleDispatcherFactory`, `HelperFactory` (newer modules) |
| Plugin | `PluginInterface` | `PluginFactory` — wraps the plugin class so Joomla can instantiate it with its `$dispatcher`, `$config`, `$params` |

For a complete worked example see the **Service Provider** section of the relevant reference (`references/component.md`, `references/module.md`, `references/plugin.md`).

## Why this matters — and why it's brittle

The DI bootstrap is one of the few "all-or-nothing" parts of an extension: forget a factory and the corresponding feature silently doesn't work. The most common failures:

- **No `RouterFactory` registered** → `Route::_()` falls back to `?view=…` URLs across the whole component (not an error — just broken SEF). The component class also has to implement `RouterServiceInterface` for the factory to be wired in. See `references/gotchas.md` for the 3-part router contract.
- **`MVCFactory` namespace prefix wrong** → models, views, controllers all fail to load with "class not found". The string passed to `new MVCFactory('\\Vendor\\Component\\Example')` must match the manifest's `<namespace>` value exactly, with a leading double backslash.
- **Plugin class not bound** → Joomla discovers the manifest but can't construct the plugin. The plugin loads but does nothing.
- **`set()` callback throws** → Joomla swallows the exception and the extension reports as installed but inert. Wrap risky setup in a try/catch and log to `Log::add(... 'jerror')` so the user sees something.

## Constructor / DI rules of thumb

- **Inject by interface, not class.** `MVCFactoryInterface` rather than `MVCFactory`. Lets Joomla swap in a test double or alternative implementation.
- **Don't reach into `Factory::getApplication()` from the provider.** The application IS in the container — `$container->get(\Joomla\CMS\Application\CMSApplicationInterface::class)`.
- **Don't do work in `register()`.** It runs before the extension is activated. Just bind, don't initialize. Real work happens later in the bound class's constructor or `boot()`.
- **`\defined('_JEXEC') or die;` at the top.** Same as every other Joomla PHP file.

## When you don't need a service provider

You always need one. There is no opt-out: without `services/provider.php`, Joomla can't construct the extension, and `index.php?option=com_example` returns a 404. Even the smallest plugin or module ships one.
