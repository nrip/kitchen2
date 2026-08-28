# Kitchen and Food Service Management Module

## Product boundary

This module is a standalone hospital kitchen service that can run under its own URL and be opened from an existing HIS/HMS menu. It owns kitchen operations and references clinical data through stable external identifiers. Patient, doctor, allergy, clinical record, and diet prescription data may be supplied by REST APIs or scheduled flat-file imports; the module does not require the source HIS schema.

## Core workflows

| Workflow | Primary users | Outcome |
|---|---|---|
| Diet order intake | Physician, dietitian, ward clerk | A patient-linked therapeutic diet order with allergy and clinical context is recorded with traceable status and audit information. |
| Menu and meal planning | Dietitian, kitchen supervisor | Menus are published by meal/date, with nutrient totals and diet suitability metadata. |
| Production planning | Kitchen supervisor, chef | Required portions and ingredients are calculated from active diet orders and planned menus. |
| Tray assembly | Kitchen staff | Each meal tray receives a scannable/reference number and progresses through assembled, dispatched, delivered, and consumed/refused states. |
| Delivery and consumption | Food service staff, ward staff | Delivery time, recipient/location, consumption, refusal reason, and exceptions are captured. |
| Inventory and wastage | Storekeeper, kitchen supervisor | Ingredient stock, reorder thresholds, stock movements, expiry risks, and wastage reasons are visible. |
| Integration | HIS/HMS administrators | External systems can push patients, clinicians, allergies, diet orders, and acknowledgements through versioned JSON APIs or CSV files. |

## Data ownership and identifiers

The module generates its own numeric primary keys, but every externally sourced person or order carries an `external_id` and `source_system`. This permits multiple HIS tenants or competitor systems to integrate without coupling to their internal database keys. The integration layer must be idempotent on `(source_system, external_id)` for patients, clinicians, and diet orders.

## Initial relational model

| Entity | Important fields | Relationships |
|---|---|---|
| users | name, email, role, active | Creates and updates operational records. |
| patients | external_id, source_system, hospital_no, name, ward, room, allergies_json, clinical_notes | Has many diet orders, trays, and consumption records. |
| clinicians | external_id, source_system, name, specialty | Authors diet orders. |
| diet_types | code, name, category, therapeutic flag, restrictions_json | Used by diet orders and menu suitability. |
| diet_orders | patient_id, clinician_id, diet_type_id, prescribed_on, effective_from/to, meal_texture, calories, notes, status | Drives production and tray generation. |
| menus | menu_date, meal_period, title, status | Has many menu items. |
| menu_items | menu_id, item_name, ingredients_json, calories, protein_g, carbs_g, fat_g, allergens_json, compatible_diets_json | Provides nutrient and diet metadata. |
| trays | diet_order_id, patient_id, menu_id, tray_ref, meal_period, status, assembled_at, dispatched_at, delivered_at | Has one or more consumption records. |
| consumption_records | tray_id, status, consumed_percent, recorded_by, recorded_at, refusal_reason | Records actual intake/refusal. |
| ingredients | sku, name, unit, on_hand, reorder_level, expiry_date, active | Has stock movements and wastage. |
| stock_movements | ingredient_id, movement_type, quantity, reference, performed_by | Auditable inventory ledger. |
| wastage_records | ingredient_id, quantity, reason, notes, recorded_by | Controls wastage and loss. |
| integration_logs | endpoint, source_system, external_id, request_hash, status, message | Supports diagnostics and idempotency. |

## Status transitions

Diet orders: `draft → active → completed/cancelled`.

Trays: `planned → assembled → dispatched → delivered → consumed/refused`.

Inventory movements: `receipt`, `issue`, `adjustment`, `return`, and `wastage`; negative stock is prevented in the production implementation unless an administrator explicitly enables it.

## Integration contract

Base path: `/api/v1`.

Authentication: production deployments should place the module behind HTTPS and configure an API key or signed bearer token. The demo includes a configurable `INTEGRATION_API_KEY` and accepts `X-Integration-Key`.

Endpoints:

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/v1/health` | Connectivity check. |
| GET | `/api/v1/patients?search=&external_id=` | Patient lookup for widgets or HIS screens. |
| POST | `/api/v1/patients/upsert` | Create or update a patient snapshot. |
| POST | `/api/v1/clinicians/upsert` | Create or update a clinician snapshot. |
| POST | `/api/v1/diet-orders` | Create a patient-linked diet order from the HIS/EHR. |
| GET | `/api/v1/diet-orders?patient_external_id=` | Retrieve active or historical diet orders. |
| POST | `/api/v1/import/csv` | Import a documented CSV payload when REST is unavailable. |
| GET | `/api/v1/export/daily-kitchen.csv?date=YYYY-MM-DD` | Export daily kitchen production data. |

All mutating endpoints return `{success, data, message, request_id}`. Dates are ISO-8601. The API preserves external IDs and returns module IDs for reconciliation.

## Embedded widget contract

The clinician-facing widget is available at `/widget/diet-order.php?patient_external_id=...&source_system=...`. It is designed for an iframe or server-side include. The host HIS can supply a patient external ID and source system, and optionally a clinician external ID. The widget displays the patient summary and existing active diet orders, then submits new orders to the module API. `widget/embed-example.html` documents the minimal embed code and `postMessage` callback shape.

## Security and safety baseline

The module uses prepared SQL statements, CSRF tokens for browser forms, output escaping, API authentication hooks, request logging, role checks, and an audit trail. Clinical notes are treated as sensitive data. Production deployment should use HTTPS, database credentials outside the web root, least-privilege database accounts, backups, centralized identity/SSO, and a formal privacy/security review before connecting real patient data.

## Implementation choice

MySQL remains the recommended production database because it matches the existing HIS skill set and supports relational integrity, indexing, and reporting. The application uses PDO so it can be adapted to MariaDB with minimal changes. A JSON mock repository is included only for a zero-configuration preview; it is not intended for production clinical data.
