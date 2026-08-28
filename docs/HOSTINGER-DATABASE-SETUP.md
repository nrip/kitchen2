# Hostinger Database Installation and Connection Test

## 1. Import the schema in phpMyAdmin

Use Hostinger hPanel to open the database through **Websites → Dashboard/Manage → Databases → Management → Enter phpMyAdmin**. Select the already-created KitchenFlow database before importing. If it contains old or unrelated tables, stop and take a backup first; the recommended import target is an empty database.

Use `sql/kitchenflow_hostinger_import.sql` for phpMyAdmin. This Hostinger variant assumes the database is already selected and does not run `CREATE DATABASE` or `USE kitchen_food`. In phpMyAdmin, choose **Import**, select the `.sql` file, leave the format as SQL, and click **Go**. The file creates the tables, foreign keys, indexes, views, and global diet-type seed data.

After the import, the left database tree should show tables such as `facilities`, `patients`, `clinicians`, `diet_orders`, `menus`, `ingredients`, `trays`, `tray_events`, `api_clients`, `api_tokens`, `integration_logs`, and `audit_logs`.

## 2. Configure KitchenFlow

Create `public_html/config/local.php` from `config/local.php.example`. Replace the placeholders with the exact MySQL host shown in Hostinger hPanel, the database name, the MySQL username, the database password, and a newly generated integration key. Do not use the FTP password as the integration key.

The file should return a PHP array like this:

```php
<?php
return [
    'KITCHEN_PRODUCTION' => '1',
    'KITCHEN_DB_HOST' => 'REPLACE_WITH_HOSTINGER_DATABASE_HOST',
    'KITCHEN_DB_PORT' => '3306',
    'KITCHEN_DB_NAME' => 'REPLACE_WITH_HOSTINGER_DATABASE_NAME',
    'KITCHEN_DB_USER' => 'REPLACE_WITH_HOSTINGER_DATABASE_USER',
    'KITCHEN_DB_PASS' => 'REPLACE_WITH_HOSTINGER_DATABASE_PASSWORD',
    'INTEGRATION_API_KEY' => 'REPLACE_WITH_LONG_RANDOM_KEY',
];
```

The `KITCHEN_PRODUCTION` flag makes the application fail closed if the configured database is unavailable. It prevents the live site from silently using synthetic preview data.

## 3. Run the temporary connection test

Upload `examples/hostinger-db-test.php` as `public_html/hostinger-db-test.php`. Open:

```text
https://YOUR-LIVE-DOMAIN/hostinger-db-test.php
```

The test reads `public_html/config/local.php`, connects with `mysqli`, runs `SELECT DATABASE(), VERSION()`, and prints only the connection result, selected database, and MySQL version. A successful result begins with `OK: MySQL connection succeeded.`

Delete `hostinger-db-test.php` immediately after testing. Keep `config/local.php` protected and do not paste its contents into tickets, chat, source control, or browser code.

## 4. Verify the application

After the database test succeeds, open the site root. The header should show **MySQL connected** rather than **Preview data**. Open `/api/v1/health`; it should return a service health response. The health endpoint is public, while other API routes require the `X-Integration-Key` header.

If the site shows a database error, check the exact database host in hPanel, confirm that the database user is assigned to the database with all required privileges, confirm the PHP MySQL extension is enabled, and review the Hostinger PHP error log. Do not enable public PHP error display on a live site.

## 5. Secure cleanup

After successful validation, remove the temporary test script, delete unused demo JSON data if it was uploaded, rotate the FTP password that was shared during deployment, and generate a separate integration key for the HMS. The integration key must remain server-side and must never appear in the iframe URL.

Hostinger reference: [How to import a database with phpMyAdmin in Hostinger](https://www.hostinger.com/support/1884149-how-to-import-a-database-with-phpmyadmin-in-hostinger/).
