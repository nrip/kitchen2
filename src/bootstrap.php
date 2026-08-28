<?php
declare(strict_types=1);

session_start();

$appConfig = [];
$configFile = __DIR__ . '/../config/local.php';
if (is_file($configFile)) {
    $loadedConfig = require $configFile;
    if (is_array($loadedConfig)) $appConfig = $loadedConfig;
}

function envv(string $key, ?string $fallback = null): ?string {
    global $appConfig;
    $value = $appConfig[$key] ?? getenv($key);
    return ($value === false || $value === '' || $value === null) ? $fallback : (string)$value;
}

const APP_NAME = 'Kitchen & Food Service';
const APP_VERSION = '1.0.0';

function is_demo(): bool { return envv('KITCHEN_DB_HOST') === null; }

function csrf_token(): string {
    if (empty($_SESSION['csrf_token'])) $_SESSION['csrf_token'] = bin2hex(random_bytes(24));
    return $_SESSION['csrf_token'];
}

function verify_csrf(?string $token): void {
    if (!$token || !hash_equals($_SESSION['csrf_token'] ?? '', $token)) {
        http_response_code(419); exit('Invalid form token. Please reload the page.');
    }
}

function e(mixed $value): string { return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8'); }
function redirect(string $url): never { header('Location: ' . $url); exit; }
function now_iso(): string { return date('Y-m-d H:i:s'); }
function request_id(): string { return 'req_' . bin2hex(random_bytes(8)); }
function json_response(array $payload, int $status = 200): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    exit;
}

require_once __DIR__ . '/Repository.php';
$repo = new Repository(__DIR__ . '/../storage/demo.json');
