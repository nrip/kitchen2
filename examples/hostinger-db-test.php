<?php
/**
 * TEMPORARY Hostinger database connectivity test.
 *
 * Upload this file to the same directory that contains the `config` folder,
 * open it once in a browser, then DELETE it immediately.
 * It expects config/local.php to return an array with:
 * KITCHEN_DB_HOST, KITCHEN_DB_PORT, KITCHEN_DB_NAME, KITCHEN_DB_USER, KITCHEN_DB_PASS
 */
declare(strict_types=1);

header('Content-Type: text/plain; charset=utf-8');

$configFile = __DIR__ . '/config/local.php';
if (!is_file($configFile)) {
    http_response_code(500);
    exit("FAIL: config/local.php was not found.\n");
}

$config = require $configFile;
if (!is_array($config)) {
    http_response_code(500);
    exit("FAIL: config/local.php did not return an array.\n");
}

$host = (string)($config['KITCHEN_DB_HOST'] ?? '');
$port = (int)($config['KITCHEN_DB_PORT'] ?? 3306);
$name = (string)($config['KITCHEN_DB_NAME'] ?? '');
$user = (string)($config['KITCHEN_DB_USER'] ?? '');
$pass = (string)($config['KITCHEN_DB_PASS'] ?? '');

if ($host === '' || $name === '' || $user === '') {
    http_response_code(500);
    exit("FAIL: database configuration is incomplete.\n");
}

mysqli_report(MYSQLI_REPORT_OFF);
$db = @new mysqli($host, $user, $pass, $name, $port);
if ($db->connect_errno) {
    http_response_code(500);
    // Do not print the password or full connection string.
    exit("FAIL: MySQL connection failed.\nError: " . $db->connect_error . "\n");
}

$result = $db->query('SELECT DATABASE() AS database_name, VERSION() AS mysql_version');
$row = $result ? $result->fetch_assoc() : null;

echo "OK: MySQL connection succeeded.\n";
echo "Database: " . ($row['database_name'] ?? $name) . "\n";
echo "Server version: " . ($row['mysql_version'] ?? 'unavailable') . "\n";
$db->close();
