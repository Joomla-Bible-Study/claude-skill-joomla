# Database Patterns

Joomla's database conventions for extension schemas: install SQL, update SQL, and the `#__` prefix replacement Joomla performs at runtime. Modern query construction (`$db->createQuery()` and `DatabaseInterface`) is covered alongside the API-do/don't tables in `SKILL.md` § Modern Joomla API.

## Install SQL

**File:** `admin/sql/install.mysql.utf8.sql`

```sql
CREATE TABLE IF NOT EXISTS `#__mycomponent_items` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `title` varchar(255) NOT NULL DEFAULT '',
    `alias` varchar(400) NOT NULL DEFAULT '',
    `published` tinyint NOT NULL DEFAULT 0,
    `access` int unsigned NOT NULL DEFAULT 0,
    `ordering` int NOT NULL DEFAULT 0,
    `checked_out` int unsigned,
    `checked_out_time` datetime,
    `created` datetime NOT NULL,
    `created_by` int unsigned NOT NULL DEFAULT 0,
    `modified` datetime NOT NULL,
    `modified_by` int unsigned NOT NULL DEFAULT 0,
    `params` text NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 DEFAULT COLLATE=utf8mb4_unicode_ci;
```

Use the `#__` prefix — Joomla replaces it with the actual table prefix at runtime so installs work on any site regardless of the configured prefix.

## Update SQL

**File:** `admin/sql/updates/mysql/1.1.0.sql`

```sql
ALTER TABLE `#__mycomponent_items` ADD COLUMN `description` text NOT NULL DEFAULT '' AFTER `alias`;
```

Version-numbered files are executed sequentially during updates. The version in the filename should match a release version of your extension.

## DDL vs DML

SQL update files only execute **DDL** (`ALTER TABLE`, `CREATE INDEX`, `DROP COLUMN`). For **DML** (`INSERT`, `UPDATE`, `DELETE` of data) — including seeding default rows or migrating existing data into new columns — use the install script's `update()` or `postflight()` method. See [`install-script.md`](install-script.md) for the script lifecycle hooks and the canonical DDL-vs-DML rule.

## Common columns

The `checked_out` / `checked_out_time` columns power Joomla's record-locking convention — see the Admin URL Routing reference ([`admin-routing.md`](admin-routing.md)) for how list templates surface lock state. Standard auditing columns (`created`, `created_by`, `modified`, `modified_by`) are populated by the model lifecycle (`prepareTable()` or `Table::store()`) — see [`component-lifecycle.md`](component-lifecycle.md).
