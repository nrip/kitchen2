<?php
/**
 * HMS -> KitchenFlow diet-order widget example.
 *
 * This file is intentionally server-side PHP. The KitchenFlow API key is read
 * from the server environment and is never printed into HTML, JavaScript, or
 * an iframe URL.
 *
 * Configure these environment variables on the HMS server:
 *   KITCHENFLOW_BASE_URL=https://kitchen.example-hospital.org
 *   KITCHENFLOW_API_KEY=<long-random-secret>
 *   KITCHENFLOW_SOURCE_SYSTEM=HIS-ACME
 *   KITCHENFLOW_WIDGET_ORIGIN=https://kitchen.example-hospital.org
 */

declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

const KITCHENFLOW_TIMEOUT_SECONDS = 10;

function kitchenflow_env(string $key, ?string $default = null): ?string
{
    $value = getenv($key);
    return ($value === false || $value === '') ? $default : $value;
}

function kitchenflow_fail(string $message, int $status = 502): never
{
    http_response_code($status);
    // In production, log the detailed cause server-side and show a generic
    // message to the clinician-facing page.
    exit('<div style="font-family:Arial,sans-serif;color:#9b2633;background:#fff1f2;padding:12px;border-radius:8px">' .
        htmlspecialchars($message, ENT_QUOTES, 'UTF-8') . '</div>');
}

function kitchenflow_request(
    string $method,
    string $url,
    string $apiKey,
    ?array $jsonBody = null
): array {
    $ch = curl_init($url);
    if ($ch === false) {
        kitchenflow_fail('KitchenFlow connection could not be initialized.');
    }

    $headers = [
        'Accept: application/json',
        'X-Integration-Key: ' . $apiKey,
    ];

    $options = [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_CONNECTTIMEOUT => KITCHENFLOW_TIMEOUT_SECONDS,
        CURLOPT_TIMEOUT => KITCHENFLOW_TIMEOUT_SECONDS,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
    ];

    if ($jsonBody !== null) {
        $headers[] = 'Content-Type: application/json';
        $options[CURLOPT_HTTPHEADER] = $headers;
        $options[CURLOPT_POSTFIELDS] = json_encode($jsonBody, JSON_THROW_ON_ERROR);
    }

    curl_setopt_array($ch, $options);
    $raw = curl_exec($ch);
    $curlError = curl_error($ch);
    $httpCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($raw === false || $curlError !== '') {
        kitchenflow_fail('KitchenFlow is temporarily unavailable.');
    }

    $payload = json_decode($raw, true);
    if (!is_array($payload)) {
        kitchenflow_fail('KitchenFlow returned an invalid response.');
    }

    if ($httpCode < 200 || $httpCode >= 300 || ($payload['success'] ?? false) !== true) {
        // Do not print the API key or the complete clinical payload.
        $requestId = (string)($payload['request_id'] ?? 'not supplied');
        error_log('KitchenFlow API failure: HTTP ' . $httpCode . ', request_id=' . $requestId);
        kitchenflow_fail('The KitchenFlow request could not be completed. Reference: ' . htmlspecialchars($requestId, ENT_QUOTES, 'UTF-8'), $httpCode >= 400 ? $httpCode : 502);
    }

    return $payload;
}

// Replace this with the authenticated HMS patient context. Do not accept an
// arbitrary patient ID from an unauthenticated query string.
$patient = [
    'external_id' => (string)($_SESSION['current_patient_external_id'] ?? 'PAT-1007'),
    'source_system' => kitchenflow_env('KITCHENFLOW_SOURCE_SYSTEM', 'HIS-ACME'),
    'hospital_no' => (string)($_SESSION['current_patient_hospital_no'] ?? 'MRN-1007'),
    'name' => (string)($_SESSION['current_patient_name'] ?? 'Aarav Mehta'),
    'ward' => (string)($_SESSION['current_patient_ward'] ?? 'Ward 3B'),
    'room' => (string)($_SESSION['current_patient_room'] ?? '312'),
    'allergies' => (string)($_SESSION['current_patient_allergies'] ?? 'Peanuts; shellfish'),
];

$baseUrl = rtrim((string)kitchenflow_env('KITCHENFLOW_BASE_URL'), '/');
$apiKey = kitchenflow_env('KITCHENFLOW_API_KEY');
$sourceSystem = (string)$patient['source_system'];

if ($baseUrl === '' || $apiKey === null) {
    kitchenflow_fail('KitchenFlow integration is not configured on this HMS server.', 500);
}

// 1. Synchronize the patient snapshot from the HMS server to KitchenFlow.
// In a production system, this is usually done by an integration worker when
// the patient is admitted/updated, rather than on every page view.
kitchenflow_request('POST', $baseUrl . '/api/v1/patients/upsert', $apiKey, [
    'external_id' => $patient['external_id'],
    'source_system' => $sourceSystem,
    'hospital_no' => $patient['hospital_no'],
    'name' => $patient['name'],
    'ward' => $patient['ward'],
    'room' => $patient['room'],
    'allergies' => $patient['allergies'],
]);

// 2. Read current active orders so the HMS can show a compact summary beside
// the iframe. The widget itself also shows active orders.
$orderResponse = kitchenflow_request(
    'GET',
    $baseUrl . '/api/v1/diet-orders?' . http_build_query([
        'patient_external_id' => $patient['external_id'],
    ]),
    $apiKey
);
$activeOrders = is_array($orderResponse['data'] ?? null) ? $orderResponse['data'] : [];

// 3. Embed the clinician form. The secret is not included in this URL.
// The current starter widget accepts patient_external_id and source_system.
// A production deployment should additionally protect this URL with the HMS
// session/SSO bridge or a short-lived, signed launch token.
$widgetOrigin = rtrim((string)kitchenflow_env('KITCHENFLOW_WIDGET_ORIGIN', $baseUrl), '/');
$widgetUrl = $widgetOrigin . '/widget/diet-order.php?' . http_build_query([
    'patient_external_id' => $patient['external_id'],
    'source_system' => $sourceSystem,
]);

// If this page is rendered inside an existing HMS template, replace the HTML
// below with the hospital's design system. Keep the CSP and origin check.
header("Content-Security-Policy: frame-src 'self' " . $widgetOrigin . "; default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'");
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Patient diet order</title>
    <style>
        body { margin: 0; background: #f5f7fa; font-family: Arial, sans-serif; color: #1e293b; }
        .hms-panel { max-width: 960px; margin: 24px auto; padding: 20px; background: #fff; border: 1px solid #e7ebf0; border-radius: 12px; }
        .hms-panel h1 { font-size: 20px; margin: 0 0 5px; }
        .patient-context { color: #607086; font-size: 13px; margin-bottom: 16px; }
        .order-summary { background: #f8fafc; border-radius: 8px; padding: 10px 12px; margin-bottom: 16px; font-size: 13px; }
        .order-summary strong { color: #263447; }
        iframe { width: 100%; min-height: 650px; border: 1px solid #e7ebf0; border-radius: 12px; background: #f6f8fb; }
        #hmsNotice { display: none; padding: 9px 12px; margin: 10px 0; background: #e8f8f0; color: #237d5b; border-radius: 8px; font-size: 13px; }
    </style>
</head>
<body>
<div class="hms-panel">
    <h1>Patient diet order</h1>
    <div class="patient-context">
        <?= htmlspecialchars($patient['name'], ENT_QUOTES, 'UTF-8') ?> ·
        <?= htmlspecialchars($patient['hospital_no'], ENT_QUOTES, 'UTF-8') ?> ·
        <?= htmlspecialchars($patient['ward'] . ' / ' . $patient['room'], ENT_QUOTES, 'UTF-8') ?>
    </div>

    <div class="order-summary">
        <strong>Active orders:</strong>
        <?php if ($activeOrders === []): ?>
            None currently returned by KitchenFlow.
        <?php else: ?>
            <?= htmlspecialchars(implode('; ', array_map(
                static fn(array $order): string => (string)($order['diet_code'] ?? 'Unknown diet'),
                $activeOrders
            )), ENT_QUOTES, 'UTF-8') ?>
        <?php endif; ?>
    </div>

    <div id="hmsNotice" role="status"></div>

    <iframe
        id="kitchenflowDietWidget"
        src="<?= htmlspecialchars($widgetUrl, ENT_QUOTES, 'UTF-8') ?>"
        title="KitchenFlow patient diet order"
        loading="lazy"></iframe>
</div>
<script>
(function () {
    const trustedOrigin = <?= json_encode($widgetOrigin, JSON_THROW_ON_ERROR) ?>;
    const notice = document.getElementById('hmsNotice');

    window.addEventListener('message', function (event) {
        // Always validate the sending origin before acting on widget messages.
        if (event.origin !== trustedOrigin || !event.data) return;

        if (event.data.type === 'kitchenflow:diet-order-created') {
            notice.textContent = 'Diet order created in KitchenFlow. Refreshing the HMS summary.';
            notice.style.display = 'block';
            // In a production HMS, call its own patient-panel refresh endpoint
            // or reload the server-rendered summary after authorization.
            window.setTimeout(function () { window.location.reload(); }, 1200);
        }
    });
}());
</script>
</body>
</html>
