# KitchenFlow — Kitchen and Food Service Management

KitchenFlow is a standalone hospital kitchen module implemented in **PHP 8.1+, MySQL 8+/MariaDB, HTML5, CSS3, Bootstrap 5, and jQuery**. It does not use React. The supplied preview runs without database credentials using a JSON data store; production deployments should use MySQL.

## Included capabilities

The module includes patient-linked diet order management with allergy visibility and physician attribution, menu planning with calories and macronutrients, tray workflow tracking from planning through delivery, consumption recording, ingredient inventory and reorder/expiry indicators, wastage recording that adjusts preview stock, versioned JSON APIs, CSV import/export surfaces, and an embeddable clinician widget.

## Quick start

From the project directory:

```bash
cd /home/ubuntu/kitchen-food-service
php -S 127.0.0.1:8080 -t public public/index.php
```

Open `http://127.0.0.1:8080`. The preview mode automatically seeds `storage/demo.json`. The application stores no data outside this project in preview mode.

## MySQL production setup

1. Create a dedicated MySQL database and user.
2. Run `sql/schema.sql` using that user or an administrator.
3. Configure the environment before starting PHP-FPM or Apache:

```bash
export KITCHEN_DB_HOST=127.0.0.1
export KITCHEN_DB_PORT=3306
export KITCHEN_DB_NAME=kitchen_food
export KITCHEN_DB_USER=kitchen_app
export KITCHEN_DB_PASS='replace-with-secret'
export INTEGRATION_API_KEY='replace-with-long-random-key'
```

The repository uses PDO prepared statements. In a production integration, place the module behind HTTPS, keep environment secrets outside the web root, restrict the database account, enable backups, and connect the module to the HIS identity/session service or an approved SSO provider.

## HIS/HMS launch link

Add a menu link from the HIS to the module URL, for example:

```html
<a href="https://kitchen.example-hospital.org/" target="_blank" rel="noopener">Kitchen &amp; Food Service</a>
```

For a seamless experience, pass a signed or server-side authenticated session in the production deployment. Do not place database credentials or long-lived integration secrets in browser code.

## API examples

All API calls except health require `X-Integration-Key`.

```bash
curl -H 'X-Integration-Key: replace-with-long-random-key' \\
  'https://kitchen.example-hospital.org/api/v1/patients?search=Aarav'
```

Create or update a patient snapshot:

```bash
curl -X POST \\
  -H 'Content-Type: application/json' \\
  -H 'X-Integration-Key: replace-with-long-random-key' \\
  -d '{"external_id":"PAT-2001","source_system":"HIS-ACME","hospital_no":"MRN-2001","name":"Example Patient","ward":"Ward 4A","room":"401","allergies":"None reported"}' \\
  https://kitchen.example-hospital.org/api/v1/patients/upsert
```

Create a diet order after the patient, clinician, and diet code are synchronized:

```json
{
  "patient_external_id": "PAT-2001",
  "clinician_external_id": "DOC-88",
  "source_system": "HIS-ACME",
  "diet_code": "DM",
  "effective_from": "2026-08-27",
  "meal_texture": "Regular",
  "calories": 1600,
  "notes": "No added sugar; lactose-free"
}
```

The CSV importer accepts a multipart file with a `file` field. Patient rows use these headers: `entity,external_id,source_system,hospital_no,name,ward,room,allergies,clinical_notes`. The daily export is available at `/api/v1/export/daily-kitchen.csv`.

## Embedded widget

The simplest embed is:

```html
<iframe
  src="https://kitchen.example-hospital.org/widget/diet-order.php?patient_external_id=PAT-2001&amp;source_system=HIS-ACME"
  title="Patient diet order"
  style="width:100%;min-height:620px;border:0;border-radius:12px"
  loading="lazy"></iframe>
<script>
window.addEventListener('message', function (event) {
  if (event.data && event.data.type === 'kitchenflow:diet-order-created') {
    // Refresh the HIS/EHR diet panel or show a local confirmation.
    console.log('Kitchen order created:', event.data.order_id);
  }
});
</script>
```

See `widget/embed-example.html` for a complete host-page example. In production, configure a strict `Content-Security-Policy` and replace the demo wildcard `postMessage` target with the known HIS origin.

## Suggested next integration work

The delivered module uses an adapter-friendly snapshot model. For the first live HIS integration, map the HIS patient, clinician, allergy, and diet prescription events into the API contract, add HMAC signatures or OAuth2 in front of the API, and run reconciliation reports on external IDs. Add a background queue or scheduled job in the HIS environment if daily flat-file exchange is preferred.

## Training and operational guides

The implementation package includes three handoff documents under `docs/`: `USER-MANUAL.md` is the role-based hospital kitchen training guide, `API-AUTHENTICATION.md` explains shared-key configuration, rotation, and the recommended upgrade path to HMAC/OAuth2, and `TRAY-REALTIME.md` explains the current refresh-based behavior, the absence of a dedicated Returned state in the starter, and the recommended polling/event model for live updates.
