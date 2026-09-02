# Console Commands (CLI)

Joomla 4+ ships a single CLI entry point, `cli/joomla.php`, which boots `Joomla\CMS\Application\ConsoleApplication` — the CMS wrapper around the Joomla Framework `console` package, itself built on Symfony Console. Core commands live in `libraries/src/Console/` (`scheduler:run`, `finder:index`, `extension:install`, `session:gc`, `database:export`, `site:down`, `user:add`, …); `php cli/joomla.php list` prints every registered command.

Extensions add their own commands through a **plugin in the `console` group**. `ConsoleApplication::execute()` imports exactly three plugin groups before dispatching — `behaviour`, `system`, and `console` — so a console plugin is the officially supported hook. Core ships no console plugins, so `plugins/console/` does not exist on a stock site until you install one.

**Do not** write standalone `cli/*.php` scripts extending `CliApplication`. That class was deprecated in 4.0, still present in 5.x, and **removed in Joomla 6** — a script built on it fatals on 6.x. Everything below targets Joomla 6, backward compatible with 5.

## Table of Contents

- [Directory Structure](#directory-structure)
- [Manifest XML](#manifest-xml)
- [Service Provider](#service-provider)
- [Plugin Class — Registering Commands](#plugin-class--registering-commands)
- [Command Class](#command-class)
- [Using Your Component's Models](#using-your-components-models)
- [Language Strings](#language-strings)
- [Running and Scheduling](#running-and-scheduling)
- [Enabling the Plugin on Install](#enabling-the-plugin-on-install)
- [What Is Different Under the Console](#what-is-different-under-the-console)
- [Testing](#testing)
- [Upstream References](#upstream-references)

## Directory Structure

A console plugin is a normal Joomla plugin (see [`plugin.md`](plugin.md) for the shared structure) with `group="console"` and one extra namespace for the command classes:

```
plg_console_myext/
├── myext.xml                          # manifest (group="console")
├── services/
│   └── provider.php
├── src/
│   ├── Extension/
│   │   └── Myext.php                  # CMSPlugin + SubscriberInterface — registers commands
│   └── Command/
│       └── ImportCommand.php          # one class per command, extends AbstractCommand
└── language/
    └── en-GB/
        ├── plg_console_myext.ini
        └── plg_console_myext.sys.ini
```

The command classes can also live in the component (`administrator/components/com_myext/src/Console/ImportCommand.php`, namespace `Vendor\Component\Myext\Administrator\Console`) with the plugin doing nothing but registration. Core does this for `finder:index` (`Joomla\CMS\Console\FinderIndexCommand`) and `scheduler:run`. Keep them in the plugin when the commands are self-contained; put them in the component when they are thin wrappers over component models and services.

## Manifest XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<extension type="plugin" group="console" method="upgrade">
    <name>plg_console_myext</name>
    <author>Vendor</author>
    <creationDate>2026-09</creationDate>
    <copyright>(C) 2026 Vendor</copyright>
    <license>GNU General Public License version 2 or later; see LICENSE.txt</license>
    <version>1.0.0</version>
    <description>PLG_CONSOLE_MYEXT_XML_DESCRIPTION</description>
    <namespace path="src">Vendor\Plugin\Console\Myext</namespace>
    <files>
        <folder plugin="myext">services</folder>
        <folder>src</folder>
    </files>
    <languages>
        <language tag="en-GB">language/en-GB/plg_console_myext.ini</language>
        <language tag="en-GB">language/en-GB/plg_console_myext.sys.ini</language>
    </languages>
</extension>
```

`group="console"` is the only console-specific attribute. The plugin installs to `plugins/console/myext/` and appears under **System → Plugins** filtered by type *console*. Universal manifest elements are in [`manifest.md`](manifest.md).

## Service Provider

Identical to any other plugin — the J6.1+ single-argument constructor form documented in [`plugin.md`](plugin.md) § Service Provider. Inject the database here if your commands need it; the plugin then hands it to each command it constructs.

```php
<?php

\defined('_JEXEC') or die;

use Joomla\CMS\Extension\PluginInterface;
use Joomla\CMS\Factory;
use Joomla\CMS\Plugin\PluginHelper;
use Joomla\Database\DatabaseInterface;
use Joomla\DI\Container;
use Joomla\DI\ServiceProviderInterface;
use Vendor\Plugin\Console\Myext\Extension\Myext;

return new class () implements ServiceProviderInterface {
    public function register(Container $container): void
    {
        $container->set(
            PluginInterface::class,
            function (Container $container) {
                $plugin = new Myext(
                    (array) PluginHelper::getPlugin('console', 'myext')
                );
                $plugin->setApplication(Factory::getApplication());
                $plugin->setDatabase($container->get(DatabaseInterface::class));

                return $plugin;
            }
        );
    }
};
```

## Plugin Class — Registering Commands

The plugin subscribes to `ApplicationEvents::BEFORE_EXECUTE`, which `Joomla\Console\Application::execute()` dispatches after the plugin groups are imported and before the requested command runs.

**The event name is the constant, not an `on*` string.** `ApplicationEvents::BEFORE_EXECUTE` resolves to `'application.before_execute'`. There is no `onBeforeExecute` legacy method mapping — a console plugin **must** implement `SubscriberInterface` and reference the constant in `getSubscribedEvents()`.

```php
<?php

namespace Vendor\Plugin\Console\Myext\Extension;

\defined('_JEXEC') or die;

use Joomla\Application\ApplicationEvents;
use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\Database\DatabaseAwareInterface;
use Joomla\Database\DatabaseAwareTrait;
use Joomla\Event\SubscriberInterface;
use Vendor\Plugin\Console\Myext\Command\ImportCommand;

final class Myext extends CMSPlugin implements SubscriberInterface, DatabaseAwareInterface
{
    use DatabaseAwareTrait;

    protected $autoloadLanguage = true;

    public static function getSubscribedEvents(): array
    {
        return [
            ApplicationEvents::BEFORE_EXECUTE => 'registerCommands',
        ];
    }

    public function registerCommands(): void
    {
        $this->getApplication()->addCommand(new ImportCommand($this->getDatabase()));
    }
}
```

`$this->getApplication()` is the `ConsoleApplication`, and `addCommand()` comes from the framework's `Joomla\Console\Application`. Because the `console` group is only ever imported by the console application, no `instanceof` guard is needed here. If you register commands from a **system** plugin instead (legitimate when the plugin already exists and you want one fewer extension), guard the handler — system plugins run under the web applications too, where `addCommand()` does not exist:

```php
public function registerCommands(): void
{
    $app = $this->getApplication();

    if (!$app instanceof \Joomla\CMS\Application\ConsoleApplication) {
        return;
    }

    $app->addCommand(new ImportCommand($this->getDatabase()));
}
```

### Lazy registration through the container loader

`addCommand()` instantiates the command on **every** CLI invocation, including `php cli/joomla.php list`. That is fine for a command whose constructor takes a database handle. For a command with expensive dependencies (booting a component, building an HTTP client), register it the way core registers its own commands: share the class in the DI container and add its name to the writable command loader. The loader only resolves the class when that command is actually requested.

```php
use Joomla\CMS\Console\Loader\WritableLoaderInterface;
use Joomla\CMS\Factory;

public function registerCommands(): void
{
    $container = Factory::getContainer();

    $container->share(
        ImportCommand::class,
        fn ($c) => new ImportCommand($c->get(\Joomla\Database\DatabaseInterface::class)),
        true
    );

    $container->get(WritableLoaderInterface::class)
        ->add(ImportCommand::getDefaultName(), ImportCommand::class);
}
```

`WritableLoaderInterface` is an alias of the same `LoaderInterface` service the console application was constructed with (`libraries/src/Service/Provider/Application.php` aliases `WritableContainerLoader::class` and `WritableLoaderInterface::class` to `LoaderInterface::class`), so anything added here is visible to `list`, `help`, and dispatch. Core wires every one of its own commands this way — `SessionGcCommand::getDefaultName() => SessionGcCommand::class` and so on.

## Command Class

Extend `Joomla\Console\Command\AbstractCommand`. Three things matter: the static `$defaultName`, `configure()` for the definition and help text, and `doExecute()` for the work.

```php
<?php

namespace Vendor\Plugin\Console\Myext\Command;

\defined('_JEXEC') or die;

use Joomla\Console\Command\AbstractCommand;
use Joomla\Database\DatabaseInterface;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

final class ImportCommand extends AbstractCommand
{
    /**
     * The default command name — what the user types after cli/joomla.php.
     *
     * @var    string
     * @since  1.0.0
     */
    protected static $defaultName = 'myext:import';

    public function __construct(private readonly DatabaseInterface $db)
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->addArgument('file', InputArgument::REQUIRED, 'Path to the CSV file to import');
        $this->addOption('dry-run', null, InputOption::VALUE_NONE, 'Parse and validate without writing to the database');
        $this->addOption('batch', 'b', InputOption::VALUE_REQUIRED, 'Rows per transaction', 500);

        $this->setDescription('Import items from a CSV file');
        $this->setHelp(
            <<<'HELP'
            <info>%command.name%</info> imports items from a CSV file into #__myext_items.

            Usage: <info>php %command.full_name% /path/to/items.csv</info>
                   <info>php %command.full_name% /path/to/items.csv --dry-run</info>
                   <info>php %command.full_name% /path/to/items.csv --batch=1000</info>
            HELP
        );
    }

    protected function doExecute(InputInterface $input, OutputInterface $output): int
    {
        $io     = new SymfonyStyle($input, $output);
        $file   = $input->getArgument('file');
        $dryRun = (bool) $input->getOption('dry-run');
        $batch  = (int) $input->getOption('batch');

        $io->title('MyExt import');

        if (!is_readable($file)) {
            $io->error(\sprintf('Cannot read "%s".', $file));

            return Command::INVALID;
        }

        $rows = $this->parse($file);
        $io->text(\sprintf('%d rows parsed (batch size %d)', \count($rows), $batch));

        if ($dryRun) {
            $io->success('Dry run — nothing written.');

            return Command::SUCCESS;
        }

        $io->progressStart(\count($rows));

        try {
            foreach (array_chunk($rows, $batch) as $chunk) {
                $this->insert($chunk);
                $io->progressAdvance(\count($chunk));
            }
        } catch (\RuntimeException $e) {
            $io->progressFinish();
            $io->error($e->getMessage());

            return Command::FAILURE;
        }

        $io->progressFinish();
        $io->success(\sprintf('%d rows imported.', \count($rows)));

        return Command::SUCCESS;
    }

    // parse() and insert() omitted — ordinary PHP + DatabaseInterface work.
}
```

Conventions, all taken from core commands:

- **Name** — `namespace:verb` in lowercase, extension-prefixed so it cannot collide with core (`myext:import`, not `import`). `getDefaultName()` returns it statically, which is what the container loader keys on.
- **Return an `int`.** `Command::SUCCESS` (0), `Command::FAILURE` (1), `Command::INVALID` (2) are the Symfony constants core uses; the shell sees the value as the exit code, which is what cron and CI check. Do not `exit()` — let the return propagate so `AFTER_EXECUTE` listeners and the queued-message flush still run.
- **Help text placeholders** — `%command.name%` expands to `myext:import`, `%command.full_name%` to `cli/joomla.php myext:import`. Symfony tag markup (`<info>`, `<comment>`, `<error>`) works in help, description, and any `$io` / `$output` call.
- **Dependencies through the constructor**, then `parent::__construct()`. Core does this for `FinderIndexCommand(DatabaseInterface $db)`. Do not reach for `Factory::getDbo()`; the command is easier to test with the handle injected.
- **Options with values** — `InputOption::VALUE_REQUIRED` means "if the option is given it needs a value" (`--batch=1000`), `VALUE_OPTIONAL` allows a bare `--batch`, `VALUE_NONE` is a boolean flag. The fifth argument is the default. Arguments use `InputArgument::REQUIRED` / `OPTIONAL` / `IS_ARRAY`.
- **Verbosity** is free: `-v`, `-vv`, `-vvv`, `-q` are global options. Branch on `$output->isVerbose()` / `isVeryVerbose()` for extra diagnostics rather than adding your own `--verbose`.
- `initialise(InputInterface $input, OutputInterface $output)` is a hook that runs after input is bound and before validation — use it to normalise options, not for work.

## Using Your Component's Models

The console application uses `ExtensionManagerTrait`, so `bootComponent()` works exactly as it does on the web. Core's `finder:index` does this to reach `com_finder`'s Index model:

```php
$app     = $this->getApplication();   // ConsoleApplication
$factory = $app->bootComponent('com_myext')->getMVCFactory();

/** @var \Vendor\Component\Myext\Administrator\Model\ItemsModel $model */
$model = $factory->createModel('Items', 'Administrator', ['ignore_request' => true]);
$model->setState('filter.published', 1);
$model->setState('list.limit', 0);

$items = $model->getItems();
```

Pass **`['ignore_request' => true]`**. Without it, `ListModel::populateState()` reads filters, ordering, and pagination through `$app->getUserStateFromRequest()`, which `ConsoleApplication` does implement (since 4.4) — but it resolves against the CLI session and `Joomla\CMS\Input\Cli`, not against your Symfony arguments, so the model picks up whatever defaults or stale state it finds there. With it, the model starts blank and you set state explicitly.

For saving, `AdminModel::save()` runs the same table workflow as the admin UI (`prepareTable()` → `bind()` → `check()` → `store()`), so validation and observers behave the same — see [`component-lifecycle.md`](component-lifecycle.md). Anything in that path that calls `$app->getIdentity()->authorise(...)` or `$app->getIdentity()->id` needs an identity loaded first; see [What Is Different Under the Console](#what-is-different-under-the-console).

## Language Strings

- **Plugin strings** — set `protected $autoloadLanguage = true;` on the plugin class and `PLG_CONSOLE_MYEXT_*` keys from `plg_console_myext.ini` are available through `Text::_()` inside the commands too. Prefix rules are in [`language-files.md`](language-files.md).
- **Component strings** — nothing loads them for you. Load them once in the command:

  ```php
  $this->getApplication()->getLanguage()->load('com_myext', JPATH_ADMINISTRATOR);
  ```

  `ConsoleApplication` is constructed with a `Language` instance built from the site's configured default language (`$config->get('language')`), so `Text::_()` resolves against that locale, not against any user's preference.
- **Core pattern (optional)** — `FinderIndexCommand` implements `LanguageAwareInterface` + `LanguageAwareTrait` and receives its `Language` from the service provider. Worth copying when a command is shared by more than one application; overkill for a plugin-local command.

## Running and Scheduling

```bash
php cli/joomla.php list                       # every registered command, grouped by namespace
php cli/joomla.php myext:import --help        # generated synopsis + your setHelp() text
php cli/joomla.php myext:import /srv/items.csv --dry-run -v
echo $?                                       # exit code from doExecute()
```

`cli/joomla.php` refuses to run if `configuration.php` is missing (it tells you to run `php installation/joomla.php install`) or if the **CLI** PHP binary is below `JOOMLA_MINIMUM_PHP` (8.3 on Joomla 6). The CLI `php` is frequently a different binary from the web server's, with its own `php.ini`, `memory_limit`, and extension set — check `php -v` and `php -m` on the host before blaming the command.

**Cron.** A bare crontab line works:

```cron
*/15 * * * * cd /var/www/site && /usr/bin/php cli/joomla.php myext:import /srv/items.csv --quiet
```

The Joomla-native alternative is a **task plugin** driven by `php cli/joomla.php scheduler:run --all` (or the web-cron / lazy-scheduler triggers): the admin gets a UI to enable, schedule, and inspect runs, and you write the routine once. Pattern in [`plugin.md`](plugin.md) § Task Plugin. Ship a console command when the operation is operator-driven (import a file, rebuild an index, one-off migrations) and a task plugin when it is recurring; wrapping the same service class in both is common.

**`--live-site`.** Under the console there is no HTTP host. `ConsoleApplication::populateHttpHost()` seeds `$_SERVER['HTTP_HOST']` from the `--live-site` global option, then from `$live_site` in `configuration.php`, and otherwise from the placeholder `https://joomla.invalid/set/by/console/application`. Any command that builds absolute URLs (mail templates, `Uri::root()`, `Route::link()`) must be run with `--live-site=https://example.com` or on a site whose `$live_site` is set — otherwise the links point at `joomla.invalid`.

## Enabling the Plugin on Install

Plugins install **disabled**. A console plugin that nobody enables silently contributes no commands, and there is no error — `list` just does not show them. Enable it from the install script's `postflight()` (lifecycle in [`install-script.md`](install-script.md)):

```php
public function postflight(string $type, InstallerAdapter $adapter): void
{
    if ($type !== 'install' && $type !== 'discover_install') {
        return;
    }

    $db    = $this->getDatabase();
    $query = $db->getQuery(true)
        ->update($db->quoteName('#__extensions'))
        ->set($db->quoteName('enabled') . ' = 1')
        ->where($db->quoteName('type') . ' = ' . $db->quote('plugin'))
        ->where($db->quoteName('folder') . ' = ' . $db->quote('console'))
        ->where($db->quoteName('element') . ' = ' . $db->quote('myext'));

    $db->setQuery($query)->execute();
}
```

Restrict it to fresh installs so an admin who deliberately disabled the plugin is not re-enabled by every update. When the plugin ships inside a package with the component, do this from the **package** script so it runs after every member extension is in place.

## What Is Different Under the Console

`ConsoleApplication` implements `CMSApplicationInterface` but **not** `CMSWebApplicationInterface`. Verified against `libraries/src/Application/ConsoleApplication.php` on `6.1-dev`:

| Web assumption | Console reality | What to do |
|---|---|---|
| `$app->getDocument()` exists | **No such method** — fatal `Call to undefined method` | Guard shared code with `if ($app instanceof CMSWebApplicationInterface)`. This bites in `system` and `task` plugin constructors and any bootstrap file they `require`, because those groups load under the console too (`scheduler:run` imports every task plugin merely to list routines). See [`gotchas.md`](gotchas.md) § Plugins Load Under the Console Application. |
| `$app->getIdentity()` is the logged-in user | `null` until something calls `loadIdentity()` | Load one explicitly when the code path needs it: `$app->loadIdentity($container->get(UserFactoryInterface::class)->loadUserById($id))`. `loadIdentity()` with no argument loads the guest (id 0) user. Models that check `$user->authorise()` will fatally error on `null`. |
| `$app->isClient('administrator')` / `isClient('site')` | Both `false`; `$app->getName()` is `'cli'` so `isClient('cli')` is `true` | Branch on `isClient('cli')` rather than assuming "not administrator means site". |
| `$app->getInput()` carries the request | Returns `Joomla\CMS\Input\Cli` — **not** the Symfony input that holds your arguments | Read arguments and options from the `$input` passed to `doExecute()`. `getInput()` only exists so legacy controllers instantiated under CLI do not crash. |
| Session persists between requests | A `session.cli` session exists (the container aliases `session` to it in `cli/joomla.php`) but nothing survives the process | Do not stash state in the session; pass it through options or the database. |
| `$app->enqueueMessage()` shows a banner | Messages are queued and flushed at exit through `SymfonyStyle` (`MSG_ERROR` → `error()`, `MSG_INFO` → `note()`, `MSG_SUCCESS` → `success()`, …) | Fine to leave in shared code. For command-local output use `$io` directly so it appears in order. |
| `Uri::root()` knows the host | Host is `--live-site`, then `$live_site`, then `joomla.invalid` | Pass `--live-site` or set `$live_site` before generating absolute URLs. |
| `system` plugins run on every page | They also run on **every CLI invocation**, including `list` | Keep plugin constructors side-effect free. Anything slow or web-only in a system plugin constructor slows or breaks every command. |
| `$app->getMenu()` / `getPathway()` / `getTemplate()` | Absent (web-only) | Same `CMSWebApplicationInterface` guard. |

Each of these is quiet on the web and loud on the console, and the console is where cron runs them, unattended. Assume any extension code reachable from a plugin constructor or a `bootComponent()` will one day execute under `php cli/joomla.php`.

## Testing

Keep `doExecute()` thin. Parsing, validation, and persistence belong in a service class or component model that PHPUnit can exercise directly — the [`testing.md`](testing.md) patterns apply unchanged. The command's own job is argument handling, output, and the exit code.

For a command test without a running application, `AbstractCommand::execute()` short-circuits `mergeApplicationDefinition()` when no application has been set, so a command with injected dependencies runs against an `ArrayInput` and a `BufferedOutput`:

```php
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Output\BufferedOutput;

public function testDryRunWritesNothing(): void
{
    $db      = $this->createMock(DatabaseInterface::class);
    $command = new ImportCommand($db);
    $output  = new BufferedOutput();

    $db->expects($this->never())->method('setQuery');

    $exit = $command->execute(
        new ArrayInput(['file' => __DIR__ . '/fixtures/items.csv', '--dry-run' => true]),
        $output
    );

    $this->assertSame(Command::SUCCESS, $exit);
    $this->assertStringContainsString('Dry run', $output->fetch());
}
```

Smoke-test the integration on a real install after packaging: `php cli/joomla.php list | grep myext` proves the plugin is enabled and the event wiring is right; `php cli/joomla.php myext:import --help` proves `configure()` ran; `echo $?` after a real run proves the exit code.

## Upstream References

Commit-pinned to `joomla-cms` `6.1-dev` @ `5a28ad8` (verified 2026-09-02):

- [`libraries/src/Application/ConsoleApplication.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Application/ConsoleApplication.php) — `execute()` imports `behaviour` / `system` / `console`; `$name = 'cli'`; `populateHttpHost()`; message-queue flush in `doExecute()`.
- [`libraries/src/Service/Provider/Application.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Service/Provider/Application.php) — `WritableContainerLoader` aliased to `LoaderInterface` / `WritableLoaderInterface`; every core command mapped by `getDefaultName()`.
- [`libraries/src/Service/Provider/Console.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Service/Provider/Console.php) — container factories for core commands (constructor injection of `DatabaseInterface`, `setLanguage()` on `FinderIndexCommand`).
- [`libraries/src/Console/SessionGcCommand.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Console/SessionGcCommand.php) — minimal reference command (`$defaultName`, `configure()`, `doExecute()`, `Command::SUCCESS` / `FAILURE`).
- [`libraries/src/Console/FinderIndexCommand.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Console/FinderIndexCommand.php) — `bootComponent()->getMVCFactory()->createModel()` from a command; `LanguageAwareTrait`.
- [`cli/joomla.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/cli/joomla.php) — entry point; `session.cli` aliasing; PHP-version and install checks.
- Joomla Framework: [`console/src/Command/AbstractCommand.php`](https://github.com/joomla-framework/console/blob/3.x-dev/src/Command/AbstractCommand.php) (`execute()` / `mergeApplicationDefinition()` / `initialise()`), [`application/src/ApplicationEvents.php`](https://github.com/joomla-framework/application/blob/3.x-dev/src/ApplicationEvents.php) (`BEFORE_EXECUTE = 'application.before_execute'`).
- Manual: [Basic Console Plugin — Hello World](https://manual.joomla.org/docs/next/building-extensions/plugins/plugin-examples/basic-console-plugin-helloworld/) and [Console Plugin — SQL file](https://manual.joomla.org/docs/next/building-extensions/plugins/plugin-examples/console-plugin-sqlfile/).
