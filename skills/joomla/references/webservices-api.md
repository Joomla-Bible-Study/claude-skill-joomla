# Web Services API (JSON:API)

Joomla 4+ ships a REST API at `/api/index.php/v1/...` served by `Joomla\CMS\Application\ApiApplication` and speaking [JSON:API](https://jsonapi.org/) (`application/vnd.api+json`). Core exposes articles, categories, users, menus, and more; an extension exposes its own data by registering routes from a **webservices plugin** and adding an `api/` tier to the component that reuses the **administrator** models. This reference covers both halves: **authoring** endpoints for your component and **consuming** the API from PHP, JavaScript, or the shell.

Everything below is verified against `joomla-cms` `6.1-dev` (permalinks at the end) and targets Joomla 6, backward compatible with 5.

## Table of Contents

- [How a Request Flows](#how-a-request-flows)
- [Directory Structure](#directory-structure)
- [Webservices Plugin — Registering Routes](#webservices-plugin--registering-routes)
- [API Controller](#api-controller)
- [API View (JsonapiView)](#api-view-jsonapiview)
- [Manifest and Language Files](#manifest-and-language-files)
- [Authentication and Tokens](#authentication-and-tokens)
- [Query Conventions the Client Uses](#query-conventions-the-client-uses)
- [Errors](#errors)
- [CORS](#cors)
- [Consuming the API](#consuming-the-api)
- [Gotchas](#gotchas)
- [Testing](#testing)
- [Upstream References](#upstream-references)

## How a Request Flows

1. `api/index.php` boots `ApiApplication`. Its client name is `api`, so `$app->isClient('api')` is true and `isClient('site')` / `isClient('administrator')` are false.
2. `ApiApplication::route()` imports the **`webservices`** plugin group and dispatches `onBeforeApiRoute` with a `BeforeApiRouteEvent` carrying the `ApiRouter`. Every webservices plugin adds its routes here.
3. `ApiRouter::parseApiRoute()` matches method + path against the registered routes and yields `controller`, `task`, and the route's `vars` (`component`, `public`, `id`, …). No match is a 404.
4. Content negotiation runs against the `Accept` header. The only format registered by default is `application/vnd.api+json` → document type `jsonapi`. A client whose `Accept` cannot match gets **406 Not Acceptable**. `Accept: */*` (what curl and most HTTP clients send by default) and the exact type both match; `Accept: application/json` alone does not.
5. Unless the route's `public` var is `true`, the application calls `login()` with the **`api-authentication`** plugin group (not `authentication`). Failure is **401**. There is no session-cookie path: a browser session logged into the admin does **not** authenticate `/api`.
6. `dispatch()` boots the component with the `Api` namespace, and `ApiController::displayList()` / `displayItem()` / `add()` / `edit()` / `delete()` run against the component's models, rendered by a `JsonapiView`.

## Directory Structure

```
com_example/
├── admin/                          # existing administrator tier — its models and tables do the work
│   └── src/Model/ItemsModel.php, ItemModel.php, Table/ItemTable.php, forms/item.xml
├── api/                            # new tier — installs to api/components/com_example/
│   ├── language/en-GB/com_example.ini   (optional; see Manifest and Language Files)
│   └── src/
│       ├── Controller/ItemsController.php
│       └── View/Items/JsonapiView.php
└── plugins/webservices/example/    # registers routes
    ├── example.xml
    ├── services/provider.php
    └── src/Extension/Example.php
```

**No `api/src/Model/`.** The component's service provider hands the API application an `ApiMVCFactory`, whose `createModel()` and `createTable()` try the `Api` namespace first and fall back to **`Administrator`**. Your admin `ItemsModel` / `ItemModel` / `ItemTable` are what the API uses, with the same validation, ACL, and observers the admin UI gets. Only write an `api/src/Model/` when the API needs a genuinely different query.

Namespace for the tier is `Vendor\Component\Example\Api\...`, mapped by the `<namespace path="src">` element already in the component manifest.

## Webservices Plugin — Registering Routes

A plugin in the `webservices` group — structure and service provider per [`plugin.md`](plugin.md). The event is `onBeforeApiRoute` with a typed `BeforeApiRouteEvent`; take the router from the event, not from a by-reference argument (that signature is legacy).

```php
<?php

namespace Vendor\Plugin\WebServices\Example\Extension;

\defined('_JEXEC') or die;

use Joomla\CMS\Event\Application\BeforeApiRouteEvent;
use Joomla\CMS\Plugin\CMSPlugin;
use Joomla\CMS\Router\ApiRouter;
use Joomla\Event\SubscriberInterface;
use Joomla\Router\Route;

final class Example extends CMSPlugin implements SubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return ['onBeforeApiRoute' => 'onBeforeApiRoute'];
    }

    public function onBeforeApiRoute(BeforeApiRouteEvent $event): void
    {
        $router = $event->getRouter();

        // Reads are public only if the site admin opts in via the plugin's params.
        $publicReads = (bool) $this->params->get('public_reads', 0);

        // 1. Full CRUD in one call
        $router->createCRUDRoutes(
            'v1/example/items',
            'items',
            ['component' => 'com_example'],
            $publicReads
        );

        // 2. A read-only resource: register only the GET routes
        $this->createReadOnlyRoutes($router, 'v1/example/categories', 'categories', $publicReads);

        // 3. A custom action beyond CRUD
        $router->addRoutes([
            new Route(
                ['PATCH'],
                'v1/example/items/:id/publish',
                'items.publish',
                ['id' => '(\d+)'],
                ['component' => 'com_example', 'public' => false]
            ),
        ]);
    }

    private function createReadOnlyRoutes(ApiRouter $router, string $base, string $controller, bool $public): void
    {
        $defaults = ['component' => 'com_example', 'public' => $public];

        $router->addRoutes([
            new Route(['GET'], $base, $controller . '.displayList', [], $defaults),
            new Route(['GET'], $base . '/:id', $controller . '.displayItem', ['id' => '(\d+)'], $defaults),
        ]);
    }
}
```

What `createCRUDRoutes($baseName, $controller, $defaults, $publicGets)` registers, verbatim from `ApiRouter`:

| Method | Path | Task | `public` |
|---|---|---|---|
| GET | `v1/example/items` | `items.displayList` | `$publicGets` |
| GET | `v1/example/items/:id` | `items.displayItem` | `$publicGets` |
| POST | `v1/example/items` | `items.add` | never |
| PATCH | `v1/example/items/:id` | `items.edit` | never |
| DELETE | `v1/example/items/:id` | `items.delete` | never |

Rules from the `Route` constructor: `new Route(array $methods, string $pattern, string 'controller.task', array $rules, array $defaults)`. `:id` in the pattern becomes `$rules['id']` (a regex — `(\d+)`), and everything in `$defaults` lands in the request input, so `component` is how the router knows which extension to boot. **`public` defaults to `false`** when absent, which is the safe default — an unauthenticated GET gets 401, not data.

Core convention for the path is `v1/<extension-short-name>/<resource>`; core's own routes are `v1/content/articles`, `v1/users`, `v1/menus/site/items`. Do not put the `index.php` in the pattern — the router strips it.

## API Controller

**File:** `api/src/Controller/ItemsController.php`

```php
<?php

namespace Vendor\Component\Example\Api\Controller;

\defined('_JEXEC') or die;

use Joomla\CMS\Filter\InputFilter;
use Joomla\CMS\MVC\Controller\ApiController;

class ItemsController extends ApiController
{
    protected $contentType = 'items';
    protected $default_view = 'items';

    public function displayList()
    {
        // Translate JSON:API filter[...] / list[...] query vars into model state.
        // Only whitelisted keys reach the model — the base class does not do this for you.
        $apiFilter = $this->input->get('filter', [], 'array');
        $clean     = InputFilter::getInstance();

        if (\array_key_exists('search', $apiFilter)) {
            $this->modelState->set('filter.search', $clean->clean($apiFilter['search'], 'STRING'));
        }

        if (\array_key_exists('category', $apiFilter)) {
            $this->modelState->set('filter.category_id', $clean->clean($apiFilter['category'], 'INT'));
        }

        if (\array_key_exists('state', $apiFilter)) {
            $this->modelState->set('filter.published', $clean->clean($apiFilter['state'], 'INT'));
        }

        $apiList = $this->input->get('list', [], 'array');

        if (\array_key_exists('ordering', $apiList)) {
            $this->modelState->set('list.ordering', $clean->clean($apiList['ordering'], 'STRING'));
        }

        if (\array_key_exists('direction', $apiList)) {
            $this->modelState->set('list.direction', $clean->clean($apiList['direction'], 'STRING'));
        }

        return parent::displayList();
    }

    protected function preprocessSaveData(array $data): array
    {
        // Never let a client set internal columns.
        unset($data['asset_id'], $data['checked_out'], $data['checked_out_time'], $data['modified_by']);

        // Clients without core.edit.state can only create unpublished records.
        if (!$this->app->getIdentity()->authorise('core.edit.state', $this->option)) {
            $data['published'] = 0;
        }

        return $data;
    }

    // Custom task wired by the extra Route above
    public function publish(): void
    {
        if (!$this->app->getIdentity()->authorise('core.edit.state', $this->option)) {
            throw new \Joomla\CMS\Access\Exception\NotAllowed('JLIB_APPLICATION_ERROR_EDITSTATE_NOT_PERMITTED', 403);
        }

        $id    = $this->input->getInt('id');
        $model = $this->getModel('Item', 'Administrator', ['ignore_request' => true]);

        if (!$model->publish($id, 1)) {
            throw new \RuntimeException($model->getError(), 500);
        }

        $this->displayItem($id);
    }
}
```

What the base class gives you (from `ApiController` on `6.1-dev`):

- **`$contentType`** is the JSON:API `type` and, singularised by Doctrine Inflector, the **model name** (`items` → `ItemModel` for item/add/edit/delete, `ItemsModel` for the list). Override `getModel()` to map when your models carry a vendor prefix.
- **`$modelState`** is a `Registry` handed to the model as its initial state (with `ignore_request => true`, so nothing leaks in from the request). Set filters and list state there **before** `parent::displayList()`.
- **Pagination** is parsed for you: `page[offset]` → `list.start`, `page[limit]` → `list.limit`, default `$itemsPerPage = 20`. An offset past the total is a 404.
- **`list.ordering`** is validated against the model's `isValidFilterColumn()` (the `filter_fields` array on your `ListModel`), and `list.direction` must be `asc` / `desc`. Anything else is silently reset — so populate `filter_fields`.
- **`add()` / `edit()` / `delete()`** call `allowAdd()` / `allowEdit()` / `allowDelete()`, which require `core.manage` on the component **plus** `core.create` / `core.edit` / `core.delete`. Override them for per-record or category ACL. Denial throws `NotAllowed` → 403.
- **`save()`** reads the JSON body (`$this->input->json`), fills unspecified fields from the existing row on PATCH, calls `preprocessSaveData()`, then runs the **admin form** (`Form::addFormPath(JPATH_ADMINISTRATOR . '/components/com_example/forms')`) through `$model->validate()` and `$model->save()`. Validation failure throws `InvalidParameterException` → 400 with up to three messages. Save failure throws `Exception\Save`. Check-out / check-in is handled when the table has `checked_out`.
- **`delete()`** returns **204** with no body. A model that reports a 409 via the session (`http_status_code_409`, the "must be trashed first" case) gets a plain-JSON 409.
- `add()` and `edit()` end by calling `displayItem($id)`, so a successful write returns the full resource.

The request body for POST / PATCH is a **flat JSON object of field names**, not a JSON:API `{"data": {"attributes": …}}` envelope — `$this->input->get('data', json_decode(raw, true))` accepts either a top-level `data` key or the raw object. Field names are the admin form's field names.

## API View (JsonapiView)

**File:** `api/src/View/Items/JsonapiView.php`

```php
<?php

namespace Vendor\Component\Example\Api\View\Items;

\defined('_JEXEC') or die;

use Joomla\CMS\MVC\View\JsonApiView as BaseApiView;
use Joomla\Registry\Registry;

class JsonapiView extends BaseApiView
{
    protected $fieldsToRenderItem = [
        'id', 'title', 'alias', 'description', 'catid', 'published', 'access',
        'params', 'created', 'created_by', 'modified', 'hits',
    ];

    protected $fieldsToRenderList = [
        'id', 'title', 'alias', 'catid', 'published', 'access', 'created', 'hits',
    ];

    // Attribute names that render as JSON:API relationships. Each must be
    // resolvable to an object with an id — see prepareItem().
    protected $relationship = ['category', 'created_by'];

    protected function prepareItem($item)
    {
        if (!$item) {
            return $item;
        }

        // Decode JSON columns so clients get objects, not strings.
        if (isset($item->params) && \is_string($item->params)) {
            $item->params = (new Registry($item->params))->toArray();
        }

        // Shape relationship targets as {id, ...}
        if (!empty($item->catid)) {
            $item->category = (object) ['id' => $item->catid, 'title' => $item->category_title ?? null];
        }

        return parent::prepareItem($item);
    }
}
```

- The view class **must** be named `JsonapiView` in `View/<Contenttype>/` — `ApiController` asks the factory for the view by `$default_view` and the negotiated document type `jsonapi`.
- `$fieldsToRenderItem` / `$fieldsToRenderList` are **whitelists**; anything not listed is dropped even if the model returns it. Keep the list variant lean — it is what `page[limit]=200` multiplies. `id` is mandatory (the serializer needs it; a missing `id` on an item is a 404).
- `prepareItem()` runs per item for both list and single responses. Do decoding, computed fields, and relationship shaping there.
- `displayList()` adds `meta.total-pages` and `links.self / first / previous / next / last` automatically from the model's `getPagination()`.
- `JoomlaSerializer` turns the item into attributes and dispatches `onGetApiAttributes` — other extensions can inject attributes into your resource without touching your code, the same way the `onApiGetFields` event lets plugins add to the render whitelist. `onGetApiRelation` does the same for relationships.
- Need a resource that is not a model row (a status singleton, an aggregate)? Build the object yourself and pass it: `$view->displayItem($object)` / `$view->displayList($arrayOfObjects)`.

## Manifest and Language Files

Add an `<api>` block to the **component** manifest; the folder name must match `folder=`:

```xml
<api>
    <files folder="api">
        <folder>src</folder>
        <folder>language</folder>   <!-- optional: api/components/com_example/language/en-GB/com_example.ini -->
    </files>
</api>
```

`ComponentAdapter` copies `<api><files>` but has no `<languages>` handling for the API client, so API-tier language files travel inside `<files>` and land at `api/components/com_example/language/<tag>/com_example.ini` — which is the second path `ComponentDispatcher::loadLanguage()` tries.

**Language strings under the API application load from the API tier, not the admin tier.** `ComponentDispatcher::loadLanguage()` calls `$lang->load($option, JPATH_BASE)` then `JPATH_BASE . '/components/' . $option`, and `JPATH_BASE` is the `api/` directory. So `COM_EXAMPLE_*` keys used by API responses — most visibly the **admin form's validation messages** that `save()` surfaces in 400 errors — come back as raw keys unless you either ship that API-tier `.ini` or load the admin file explicitly:

```php
// in the controller constructor or at the top of save()
$this->app->getLanguage()->load('com_example', JPATH_ADMINISTRATOR);
```

Loading the admin file is the pragmatic choice; it is where the form messages already live and it avoids maintaining a second copy. The webservices plugin itself follows normal plugin language rules (`plg_webservices_example.ini`, [`language-files.md`](language-files.md)) and only needs `.sys.ini` for its name in the plugin manager unless it has params.

## Authentication and Tokens

The API authenticates **per request** through the `api-authentication` plugin group. Core ships two providers:

| Plugin | Mechanism | Header |
|---|---|---|
| `plg_api-authentication_token` | Joomla API Token (recommended) | `Authorization: Bearer <token>` or `X-Joomla-Token: <token>` |
| `plg_api-authentication_basic` | HTTP Basic with the user's password | `Authorization: Basic base64(user:pass)` |

On a fresh install `plg_api-authentication_token` and `plg_user_token` (which adds the token UI to the user profile) are **enabled**; `plg_api-authentication_basic` is **disabled** (`installation/sql/mysql/base.sql`). If tokens are not being accepted, the plugin manager filtered by type *api-authentication* is the first place to look. Verified against `plugins/api-authentication/token/src/Extension/Token.php`:

- The token a user copies from **Users → Edit → Joomla API Token** is `base64("<algo>:<userId>:<hmac>")`, where `hmac = hash_hmac(algo, rawSeed, $config->secret)`, the seed is random bytes stored in `#__user_profiles` under `joomlatoken.token`, and `algo` is `sha256` or `sha512`. It is therefore **bound to the site's `$secret`** — regenerating `configuration.php`'s secret invalidates every token, and a token copied between sites never works.
- The plugin checks `joomlatoken.enabled = 1`, that the user is in the **allowed user groups** configured on `plg_user_token` (default: Super Users only — widen it deliberately), and that the account is not blocked, unactivated, or password-reset-pending. Comparison is timing-safe.
- On success the request runs **as that user**: `$app->getIdentity()` is the token's owner and every `authorise()` check in `ApiController` uses their ACL. A read-only integration deserves its own user in a group with `core.manage` on your component and nothing else.
- The token plugin reads `Authorization` first, then `X-Joomla-Token`. Some Apache setups strip `Authorization` from PHP; the plugin handles the `REDIRECT_HTTP_AUTHORIZATION` and `apache_request_headers()` fallbacks, but `X-Joomla-Token` is the header that always survives.

Writing your own provider (an app-specific key, an OAuth bearer, an HMAC signature) is a plugin in the `api-authentication` group subscribing to `onUserAuthenticate` with an `AuthenticationEvent`, setting `$response->status = Authentication::STATUS_SUCCESS` plus `username` / `email` / `fullname`, and calling `$event->stopPropagation()`. The core token plugin is the template.

## Query Conventions the Client Uses

| Purpose | Query string | Handled by |
|---|---|---|
| Offset pagination | `page[offset]=40&page[limit]=20` | `ApiController::displayList()` (core) |
| Ordering | `list[ordering]=title&list[direction]=desc` | your `displayList()` override reads `list`, core validates against `filter_fields` |
| Filtering | `filter[search]=foo&filter[category]=3` | your `displayList()` override — every key is opt-in |
| Sparse fields / includes | not supported by core — the whitelist is server-side | — |

Brackets are sent URL-encoded (`page%5Boffset%5D=40`); Joomla decodes them. The pagination links the response returns are already in that form.

## Errors

Every error is a JSON:API `errors` document with the HTTP status set, rendered by `JsonapiRenderer` through typed handlers:

| Thrown | Status |
|---|---|
| `RouteNotFoundException` (no route, bad method) | 404 |
| `AuthenticationFailed` (no or bad token on a non-public route) | 401 |
| `NotAllowed` (ACL) | 403 |
| `Tobscure\JsonApi\Exception\InvalidParameterException` (form validation) | 400 |
| `Exception\ResourceNotFound`, item `id === null` | 404 |
| `Application\Exception\NotAcceptable` (Accept mismatch) | 406 |
| `Exception\Save`, `Exception\CheckinCheckout`, anything else | 500 (detail only with `JDEBUG`) |

Inside your controller, throw those same classes rather than echoing JSON — the renderer owns the response shape. With debug off, the fallback handler hides the exception message; turn on **System → Global Configuration → Debug System** while developing, or the 500s are opaque.

## CORS

Browser clients on another origin need CORS, which is off by default. **Global Configuration → Web Services**: *Enable CORS* (`cors`), *Allowed Origin* (`cors_allow_origin`, default `*`; a comma list of origins is matched against the request `Origin` and echoed back with `Access-Control-Allow-Credentials: true`), *Allowed Headers* (`cors_allow_headers`, default `Content-Type,X-Joomla-Token,Authorization`), *Allowed Methods* (`cors_allow_methods`, default: whatever methods the matched routes declare). Preflight `OPTIONS` requests are answered with 204 by `ApiApplication::handlePreflight()` before authentication, so a preflight never 401s. An `Origin` outside the allow list gets 403 on preflight and no CORS headers on the real request.

## Consuming the API

### From the shell

```bash
TOKEN='c2hhMjU2OjYyOjdlM...'   # from the user's profile

# list, filtered and paged
curl -s -H "X-Joomla-Token: $TOKEN" \
  'https://example.com/api/index.php/v1/example/items?filter%5Bsearch%5D=foo&page%5Blimit%5D=5' | jq .

# create
curl -s -X POST -H "X-Joomla-Token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"New item","catid":3,"published":1}' \
  https://example.com/api/index.php/v1/example/items

# update one field (PATCH merges with the stored row)
curl -s -X PATCH -H "X-Joomla-Token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"published":0}' https://example.com/api/index.php/v1/example/items/42

# delete → 204
curl -s -o /dev/null -w '%{http_code}\n' -X DELETE -H "X-Joomla-Token: $TOKEN" \
  https://example.com/api/index.php/v1/example/items/42
```

### From PHP (another Joomla site, a task plugin, a CLI command)

Use the framework HTTP client — never `curl_*` or `file_get_contents()` directly (see [`gotchas.md`](gotchas.md) § HTTP Client Class):

```php
use Joomla\CMS\Http\HttpFactory;

$http = HttpFactory::getHttp(null, ['curl', 'stream']);
$headers = [
    'X-Joomla-Token' => $token,
    'Accept'         => 'application/vnd.api+json',
];

$response = $http->get('https://example.com/api/index.php/v1/example/items?page[limit]=50', $headers, 10);

if ($response->code !== 200) {
    throw new \RuntimeException('API returned ' . $response->code);
}

$items = json_decode($response->body, false, 512, JSON_THROW_ON_ERROR)->data;

// write
$headers['Content-Type'] = 'application/json';
$created = $http->post(
    'https://example.com/api/index.php/v1/example/items',
    json_encode(['title' => 'From PHP', 'catid' => 3]),
    $headers,
    10
);
```

Keep the token in the extension's params with a `password` field type, never in code. The `HttpFactory::getHttp()` transport falls back from cURL to streams; always pass the timeout argument so a slow remote cannot hang a cron run.

### From JavaScript in the browser

Your own admin or site JS **cannot** call `/api` with the session cookie — the API ignores sessions. Two workable patterns:

- **For your own UI**, do not use `/api` at all. Add a `JsonView` or a `format=json` controller task on the admin tier, which *does* run under the admin session and CSRF token (`Joomla.getOptions('csrf.token')`, sent as `X-CSRF-Token`). Pattern in [`component.md`](component.md) § JsonView.
- **For a real external front end** (SPA, mobile app), issue each user a Joomla API token, store it client-side as you would any bearer token, and send `X-Joomla-Token` with `fetch()`. Enable CORS for the front end's origin. The token grants everything that user can do, so scope the user's groups accordingly.

## Gotchas

- **401 versus 404 is the diagnostic.** A route that returns 404 for an unauthenticated request was never registered — the webservices plugin is disabled, not installed, or throwing before `addRoutes()`. A correctly registered non-public route returns **401** without a token. Test this first after every packaging change; it is the single most common way an API ships broken.
- **The webservices plugin installs disabled.** Enable it from the package's install script `postflight()` on fresh installs ([`install-script.md`](install-script.md)) or every site comes up with a 404 API.
- **`public` is per route and defaults to false.** Forgetting the fourth argument to `createCRUDRoutes()` makes reads private; that is the safe direction. The dangerous mistake is passing `['public' => true]` in `$defaults`, which makes **writes** public too — `$defaults` is shared by all five routes. Only the `$publicGets` argument scopes it to GET.
- **Filters are opt-in.** The base `displayList()` handles `page` only. A `filter[foo]` you did not translate into `$modelState` is silently ignored and the client gets the unfiltered set. Whitelist exactly the keys your `ListModel::populateState()` / `getListQuery()` read, and clean each value.
- **Language files come from `api/`.** Validation messages in 400 responses arrive as `COM_EXAMPLE_FIELD_TITLE_REQUIRED` unless you load the admin language file (see [Manifest and Language Files](#manifest-and-language-files)).
- **`Accept` matters.** A client sending `Accept: application/json` (only) gets 406, because the API's only negotiated type is `application/vnd.api+json`. `Accept: */*` or the exact type both work. `Content-Type` on writes is `application/json`.
- **The PATCH body is a merge.** `save()` loads the stored row and fills every column you did not send, so a PATCH with one field is safe. A POST must carry everything the admin form requires.
- **`getModel()` names come from `$contentType`.** `items` → `Item` / `Items`. If your models are `ExampleItemModel`, override `getModel()` to map, or the controller throws `JLIB_APPLICATION_ERROR_MODEL_CREATE`.
- **The API is a `CMSWebApplicationInterface`**, so `getDocument()` exists (it is a `JsonapiDocument`) — but there is no template, no `getMenu()` items to speak of, and `Uri::root()` is the API URL. Code in a shared bootstrap that assumes the HTML document or admin toolbar still needs an `isClient('api')` branch.
- **Debug off hides 500 detail.** Any uncaught exception that is not one of the typed ones renders as a bare `Internal server error`. Switch on debug locally before chasing one.

## Testing

Split the surface the same way the code splits: **unit-test the controller's filter contract and the view's whitelist without HTTP, and acceptance-test the wiring over HTTP.**

- **Filter contract** — assert every `filter[...]` key the controller accepts maps to a state key the model actually reads, and vice versa. A source-level test (regex over `modelState->set('filter.X'` in the controller versus `'filter.X'` in the model) catches the silently-ignored-filter class of bug without booting Joomla.
- **Whitelist** — instantiate the `JsonapiView` and assert `fieldsToRenderItem` / `fieldsToRenderList` contain `id` and nothing sensitive (`checked_out`, `password`, internal params). Reflection is fine; the properties are protected.
- **Acceptance** — against a package-installed site (not a symlinked dev tree, which hides manifest and packaging mistakes): the plugin is present and enabled in the plugin manager; an unauthenticated GET on a private route returns **401, not 404**; a token generated through the profile UI returns a `data` array with the expected `type`; `public_reads`-style params flipped through the plugin's own form change the 401 to 200. Playwright's `request` fixture or plain `curl` in a CI job both work. General PHPUnit setup is in [`testing.md`](testing.md).

## Upstream References

Commit-pinned to `joomla-cms` `6.1-dev` @ `5a28ad8` (verified 2026-09-02):

- [`libraries/src/Application/ApiApplication.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Application/ApiApplication.php) — `route()`: webservices import, `onBeforeApiRoute`, Accept negotiation (406), `public` check → `login()` with `$authenticationPluginType = 'api-authentication'` (401); `respond()` / `handlePreflight()` for CORS.
- [`libraries/src/Router/ApiRouter.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Router/ApiRouter.php) — `createCRUDRoutes()` (the five routes and `$publicGets`), `parseApiRoute()`, `index.php` stripping.
- [`libraries/src/MVC/Controller/ApiController.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/MVC/Controller/ApiController.php) — `$contentType` / `$modelState` / `$itemsPerPage`, `displayList()` pagination and ordering validation, `save()` PATCH merge + admin form validation, `allowAdd/Edit/Delete()`, `preprocessSaveData()`, 204 / 409 on delete.
- [`libraries/src/MVC/View/JsonApiView.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/MVC/View/JsonApiView.php) — whitelists, `$relationship`, `prepareItem()`, pagination links, `onApiGetFields`.
- [`libraries/src/MVC/Factory/ApiMVCFactory.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/MVC/Factory/ApiMVCFactory.php) and [`libraries/src/Extension/Service/Provider/MVCFactory.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Extension/Service/Provider/MVCFactory.php) — `Api` → `Administrator` model/table fallback, selected when `isClient('api')`.
- [`libraries/src/Serializer/JoomlaSerializer.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Serializer/JoomlaSerializer.php) — `onGetApiAttributes` / `onGetApiRelation`.
- [`libraries/src/Error/Renderer/JsonapiRenderer.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Error/Renderer/JsonapiRenderer.php) — exception → status handlers.
- [`libraries/src/Dispatcher/ComponentDispatcher.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/libraries/src/Dispatcher/ComponentDispatcher.php) — `loadLanguage()` from `JPATH_BASE` (the `api/` tier).
- [`plugins/api-authentication/token/src/Extension/Token.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/plugins/api-authentication/token/src/Extension/Token.php) and [`plugins/user/token/src/Extension/Token.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/plugins/user/token/src/Extension/Token.php) — header parsing, `algo:userId:hmac` format, `joomlatoken.*` profile keys, allowed groups.
- Core worked example: [`plugins/webservices/content`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/plugins/webservices/content/src/Extension/Content.php) (CRUD + custom `contenthistory` routes), [`api/components/com_content/src/Controller/ArticlesController.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/api/components/com_content/src/Controller/ArticlesController.php) (filter translation, `preprocessSaveData`), [`api/components/com_content/src/View/Articles/JsonapiView.php`](https://github.com/joomla/joomla-cms/blob/5a28ad80af898c79b993e66392559db2469a4148/api/components/com_content/src/View/Articles/JsonapiView.php) (`$relationship`, `prepareItem()`).
