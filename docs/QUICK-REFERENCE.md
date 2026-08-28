# KitchenFlow Quick Reference Card

## Before production

| Check | Confirm |
|---|---|
| Dashboard | Date, meal period, active orders, trays due, low stock, and exceptions. |
| Diet orders | Patient, hospital number, ward/room, active diet, texture, calories, allergies, prescriber, effective date. |
| Menu | Published meal, suitable alternatives, nutrition totals, therapeutic and texture compatibility. |

## Tray status sequence

`Planned → Assembled → Dispatched → Delivered → Consumed / Refused`

Use the tray reference as the shared identifier. Before assembly, match patient, hospital number, ward, room, meal period, diet code, texture, allergy warnings, and special instructions. If anything conflicts, stop and escalate.

## Returns and refusals

The starter version has **Refused** but not a dedicated **Returned** status. Record the refusal or exception reason, notify the supervisor or ward, and follow the approved physical return and food-safety process. Do not mark a returned tray as consumed.

## Inventory and wastage

Review low-stock and near-expiry items. Use the approved stock movement process for receipts and issues. For wastage, record the ingredient, exact quantity and unit, reason, notes when needed, and staff member. Never erase a record to hide an error.

## Integration safety

Never place the integration key in a browser URL, iframe, JavaScript bundle, screenshot, or ticket. Use HTTPS and the `X-Integration-Key` header from the HMS server. A 401 response means the key is absent or invalid. Save the API `request_id` when escalating an integration problem.

## If data is missing or wrong

Do not guess a patient, diet, allergy, or ward location. Pause the affected tray, contact the authorized prescriber/dietitian or ward, and use the approved downtime process if the system is unavailable.
