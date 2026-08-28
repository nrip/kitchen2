# HMS PHP Diet-Order Widget Integration

## What the sample does

`examples/hms-diet-widget.php` is a server-rendered PHP integration page. It reads the current patient from the authenticated HMS session, sends a patient snapshot to KitchenFlow, retrieves the patient’s active diet orders, and embeds the KitchenFlow clinician form in an iframe.

The KitchenFlow API key is used only in server-side cURL requests. It is never included in the iframe URL, HTML source, JavaScript, or browser request headers. The page listens for the widget’s `kitchenflow:diet-order-created` message only from the configured KitchenFlow origin, then refreshes the HMS summary.

## Configuration

Set these environment variables on the HMS web server or PHP-FPM service:

```text
KITCHENFLOW_BASE_URL=https://kitchen.example-hospital.org
KITCHENFLOW_API_KEY=replace-with-a-long-random-secret
KITCHENFLOW_SOURCE_SYSTEM=HIS-ACME
KITCHENFLOW_WIDGET_ORIGIN=https://kitchen.example-hospital.org
```

The sample requires the PHP cURL extension. Confirm it with:

```bash
php -m | grep curl
```

The HMS should use the same `source_system` value consistently when synchronizing patients, clinicians, and diet orders. The `external_id` must be the stable patient identifier from the HMS, not a display name or a temporary browser value.

## Replace the sample patient context

The example contains safe fallback values so the file can be previewed. Replace that block with the HMS’s authenticated patient context. The patient must come from the HMS server-side session or a server-side controller that has already verified the logged-in user’s permission to view that patient.

```php
$patient = [
    'external_id' => $hmsPatient->external_id,
    'source_system' => getenv('KITCHENFLOW_SOURCE_SYSTEM'),
    'hospital_no' => $hmsPatient->hospital_no,
    'name' => $hmsPatient->display_name,
    'ward' => $hmsPatient->ward,
    'room' => $hmsPatient->room,
    'allergies' => $hmsPatient->allergies_summary,
];
```

Do not accept `patient_external_id` directly from an unauthenticated query parameter. If the HMS uses a route parameter, resolve it only after checking the current user’s clinical access and confirming that the patient belongs to the current encounter or care context.

## Request flow

| Stage | Server or browser | Operation |
|---|---|---|
| 1 | HMS server | Resolves the authenticated patient and clinician context. |
| 2 | HMS server | Calls `POST /api/v1/patients/upsert` with the API key. |
| 3 | HMS server | Calls `GET /api/v1/diet-orders?patient_external_id=...` with the API key. |
| 4 | HMS server | Renders the iframe URL without the API key. |
| 5 | Browser | Loads the KitchenFlow widget and submits its own protected browser form. |
| 6 | KitchenFlow widget | Sends a `postMessage` notification after a successful order. |
| 7 | HMS browser | Accepts the message only from the configured KitchenFlow origin and refreshes the HMS summary. |

For high-volume hospitals, move the patient upsert out of the page request and into the HMS integration worker triggered by patient admission, transfer, allergy update, or diet-order change. Keep the page-time lookup or use the HMS’s own cached integration result.

## Security requirements

Use HTTPS on both systems and keep TLS certificate verification enabled. Keep the API key in a secrets manager or protected service environment. Do not place it in `.env` files inside the document root, source control, JavaScript, browser storage, iframe URLs, or client-side mobile applications.

Configure the content security policy with the exact KitchenFlow origin rather than a wildcard. The sample validates `event.origin`; retain that check if the page is moved into the HMS layout. The current KitchenFlow starter widget sends its message with a wildcard target for portability, so the HMS’s origin validation remains essential. A production hardening change should make the widget target a configured trusted HMS origin.

The sample logs only the KitchenFlow `request_id` on API failure. Do not log the API key, complete patient payload, allergies, clinical notes, or full authorization headers. Return a generic error to the clinician and place technical details in a protected server log.

## Production widget protection

The starter widget accepts `patient_external_id` and `source_system` query parameters. For a live deployment, add a short-lived signed launch token or an SSO/session bridge. The token should be bound to the patient identifier, source system, user identity, purpose, and expiry, and should be single-use where practical. KitchenFlow must validate the token server-side before rendering or accepting the form.

The iframe should also be restricted by `frame-ancestors` to the approved HMS origin. If multiple hospitals or products use the module, maintain an allowlist per integration client rather than one global origin.

## Handling API failures

A 401 means the key is absent or invalid. A 422 indicates that the payload or required external record is incomplete. A 404 indicates an incorrect route or deployment path. A 5xx response indicates a server or upstream problem. The HMS should show a generic integration warning, preserve the clinician’s unsaved context where possible, and provide the returned `request_id` to an administrator.

The sample uses a ten-second connection and request timeout. Add bounded retries only for safe reads or idempotent upserts, use exponential backoff, and avoid creating duplicate diet orders when retrying a POST. Before enabling automatic retries for diet-order creation, add an idempotency key supported by the KitchenFlow API.

## Testing checklist

Test the sample in a staging environment with a synthetic patient. Confirm that the page renders without exposing the API key, that the patient snapshot is available in KitchenFlow, that active orders appear, and that a new order produces the expected `postMessage` callback. Verify that a message sent from another origin is ignored, an invalid API key is handled without a stack trace, a missing patient is not guessed, and the page remains usable when KitchenFlow is temporarily unavailable.
