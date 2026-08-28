# KitchenFlow User Manual and Training Guide

**Version:** 1.0
**Audience:** Kitchen supervisors, dietitians, chefs, tray assembly staff, delivery staff, storekeepers, ward nurses, and HIS administrators.

## 1. Purpose and operating model

KitchenFlow supports the complete hospital food-service cycle: receiving a diet instruction, planning a suitable meal, preparing and assembling a tray, delivering it to the correct patient, recording consumption or refusal, managing ingredient stock, and learning from wastage. It is designed to be opened as a standalone application from the hospital information system or used as an embedded diet-order widget inside the clinical record.

> **Safety principle:** KitchenFlow is an operational record. The physician or authorized dietitian remains responsible for the clinical appropriateness of a diet order. Kitchen staff must never infer a therapeutic diet from a diagnosis alone or substitute an item without checking the active order, allergies, and approved escalation path.

## 2. Roles and responsibilities

| Role | Main responsibilities in KitchenFlow |
|---|---|
| Kitchen supervisor | Reviews the dashboard, assigns production priorities, monitors tray exceptions, approves operational corrections, and reviews wastage and low-stock alerts. |
| Dietitian or authorized prescriber | Creates or validates diet orders, checks allergies and restrictions, and confirms menu suitability. |
| Chef / production staff | Uses menus and active diet orders to prepare the planned meal and flags unavailable or unsafe items to the supervisor. |
| Tray assembly staff | Matches tray reference, patient, ward, meal period, diet code, and special instructions before marking the tray assembled. |
| Food-service delivery staff | Confirms dispatch and delivery to the correct ward, room, and patient location, then reports returns or refusals. |
| Ward nurse / ward staff | Confirms receipt, records consumption or refusal, and immediately communicates patient changes or missed delivery. |
| Storekeeper | Maintains ingredient receipts, stock levels, expiry checks, stock issues, and wastage records. |
| HIS administrator | Maintains the integration key or token, mappings, external identifiers, user access, backups, and reconciliation reports. |

## 3. First-day orientation

Open the KitchenFlow URL supplied by the hospital administrator. The left navigation contains **Dashboard**, **Diet orders**, **Menus & nutrition**, **Tray service**, **Inventory**, **Wastage control**, **Embedded widget**, and **API health**. The status indicator at the top identifies whether the screen is using preview data or the configured MySQL database. Real patient data must only be used after the administrator confirms the production database and security configuration.

The application uses standard screen controls: blue buttons create or start an action, light buttons open secondary actions, search fields filter tables, status badges show the current workflow state, and alert cards identify items that need attention. Staff should not share accounts. Each person must work under an account with the minimum role required for the job.

## 4. Start-of-shift checklist

At the beginning of every shift, the kitchen supervisor reviews the dashboard and confirms the date and service period. Check active diet orders, trays due today, trays already delivered, low-stock ingredients, and recent wastage. Confirm that the patient snapshot is current for every ward being served and escalate missing or conflicting patient information to the HIS administrator or ward coordinator.

The supervisor then opens **Diet orders** and reviews new or draft orders. For each order, compare the diet code, texture, calorie target, clinical instructions, prescriber, effective date, and allergy information. Any allergy conflict, missing allergy data, duplicate order, or unclear instruction is placed on hold and escalated before food is prepared.

Finally, open **Menus & nutrition** and confirm that the published menu exists for each meal period. Check that the planned meal is compatible with the therapeutic, texture-modified, cultural, and allergy restrictions represented in the active orders.

## 5. Diet order procedure

### 5.1 Reviewing orders

Select **Diet orders**. Use the search field to find a patient, diet, or prescriber. The order table shows patient location, diet protocol, texture and calories, clinical flags, prescriber, effective date, and status. The allergy field is an attention signal; it is not a substitute for checking the clinical record when the information is incomplete or appears stale.

A diet order marked **active** is available to drive meal production. A **draft** order requires review before it should be treated as final. A completed or cancelled order must not be used for a new tray unless a new active order exists.

### 5.2 Creating an order from the module

Select **Create order**. Choose the patient, prescriber, diet protocol, effective date, meal texture, calorie target, and clinical instructions. Write restrictions in plain language, such as “No added sugar; lactose-free” or “Fluid limit 1.5 L.” Review the patient allergy banner and verify that the order is authorized before selecting **Save order**.

The recommended source of physician orders is the HIS/EHR widget or a server-to-server API call. Manual creation in KitchenFlow should be reserved for authorized users and approved downtime procedures.

### 5.3 Handling a changed diet

When a new order replaces an existing order, do not silently edit the historical record. Confirm the new effective date and record the change through the HIS or authorized widget. Notify the kitchen supervisor and ward. The next tray must be checked against the newest active order immediately before assembly.

## 6. Menu and nutrition procedure

Select **Menus & nutrition** and choose the service date. Each meal card shows meal period, publication status, food items, calories, protein, carbohydrates, and fat. **Published** menus are available for production; **Planning** menus are not final.

The chef and dietitian should review the food items against therapeutic and texture requirements before publication. Special-diet alternatives should be clearly named and traceable. If an ingredient becomes unavailable, mark the operational issue, obtain an approved substitution, and update the menu or order note before assembly rather than relying on verbal memory.

## 7. Tray assembly and delivery procedure

Select **Tray service**. Trays are grouped into four operational columns:

| Status | Meaning | Required action |
|---|---|---|
| Planned | The tray is expected but has not been assembled. | Prepare the meal and verify all identifiers. |
| Assembled | The tray has passed the kitchen assembly check. | Keep it in the designated dispatch area and protect temperature/quality according to hospital policy. |
| Dispatched | The tray has left the kitchen. | Deliver to the stated ward, room, and patient location. |
| Delivered | The receiving ward or delivery staff has confirmed handover. | The ward records consumption, refusal, or return. |
| Consumed | The patient intake outcome has been recorded as consumed. | Retain the record for service and nutrition review. |
| Refused | The patient declined or the meal could not be accepted. | Record the reason, notify the ward/dietitian when clinically relevant, and follow the return/waste process. |

Before marking a tray **Assembled**, perform a two-person or barcode-based check whenever available. Match the tray reference, patient name or hospital number, ward, room, meal period, diet code, texture, allergens, and special instructions. Do not use a tray merely because the patient name looks similar.

When the tray leaves the kitchen, select the next status and record the dispatch time through the operational screen or future scanning interface. At the ward, confirm the handover with the receiving nurse or authorized ward staff. If the patient has moved, is nil-by-mouth, is off the ward, or has a changed order, stop delivery and escalate rather than leaving the tray unattended.

## 8. Meal consumption, return, and refusal procedure

Ward staff should record whether the meal was consumed, partially consumed, refused, or not received. For partial consumption, record the approximate percentage using the hospital’s approved observation method. For refusal, select or enter the reason, such as nausea, patient unavailable, diet mismatch, temperature concern, or clinical hold. Return trays through the designated collection route and do not mix untouched therapeutic meals with general waste.

At present, the module’s visible tray workflow records status changes through a form submission. It does not yet provide automatic browser push notifications, barcode scanning, a dedicated “returned” status, or a persistent delivery-event timeline. The recommended operational workaround is for the kitchen dashboard and ward staff to refresh the tray screen at agreed intervals and to use the hospital’s escalation channel for urgent changes. See the real-time integration section in the companion API guide for the production upgrade path.

## 9. Inventory procedure

Select **Inventory** at the start of the shift and before each major production cycle. Review ingredients below reorder level and items nearing expiry. Use first-expire, first-out rotation where appropriate and follow hospital food-safety rules for temperature, storage, segregation, and traceability.

When a receipt arrives, verify quantity, unit, batch or lot details, expiry, and storage condition against the receiving document. Record the stock receipt in the production implementation. When ingredients are issued to production, record the issue against the meal plan or service period. Never adjust stock merely to make a number look correct; use an auditable stock movement or adjustment reason.

## 10. Wastage control procedure

Select **Wastage control** and choose **Record wastage**. Select the ingredient, enter the quantity and unit, and choose the most accurate reason: preparation trim, expiry or temperature breach, overproduction, or spillage/damage. Add notes when the incident requires follow-up. In preview mode, the quantity is deducted from the JSON stock record; in MySQL production, this should be implemented as a stock movement and wastage record in the same transaction.

The supervisor reviews the wastage register daily, identifies recurring reasons, and agrees a corrective action with stores and production. Wastage records should never be deleted to conceal an error. Correct an incorrect entry using an approved adjustment process.

## 11. End-of-shift checklist

Confirm that every planned tray has a final disposition or an exception note. Review dispatched trays that are not yet delivered, delivered trays without consumption feedback, refused meals, diet changes received late, and unresolved allergy or patient-location warnings. Review low-stock and expiry alerts, record all wastage, and export the daily kitchen CSV when the hospital requires a handoff or reconciliation file.

The supervisor should compare the kitchen register with the HIS ward census and report mismatches, duplicate patients, missing orders, or unexplained tray status changes to the administrator.

## 12. Downtime and exception handling

If KitchenFlow is unavailable, follow the hospital’s approved downtime paper or local system procedure. Record the patient hospital number, ward, room, diet, allergy warnings, order source, meal period, staff initials, and times. When service is restored, reconcile each paper event against the electronic record and mark any duplicate or late entry for review.

If patient data is missing, do not create a guessed patient. If an allergy is unknown, do not treat it as “no allergy.” If an order conflicts with an allergy or a clinical hold, stop preparation for that tray and contact the authorized prescriber, dietitian, ward nurse, or supervisor.

## 13. Training and competency checklist

A staff member is ready for independent operation when they can identify the correct patient and active order, explain all tray statuses, complete the assembly check, record a delivery or refusal without using another person’s account, identify a low-stock and expiry alert, record wastage accurately, and explain what to do when data is missing or conflicting.

| Exercise | Pass condition |
|---|---|
| Find a patient diet order | Locates the correct patient, ward, diet, allergy, prescriber, and effective date. |
| Create a supervised order | Enters complete instructions and confirms the allergy banner before saving. |
| Assemble a tray | Verifies all required identifiers and moves the tray to Assembled. |
| Handle a patient move | Stops delivery and escalates rather than leaving the tray unattended. |
| Record consumption/refusal | Records the outcome and reason with the correct tray reference. |
| Record wastage | Enters the correct ingredient, unit, quantity, reason, and notes. |
| Handle downtime | Uses the approved fallback and performs reconciliation after recovery. |

## 14. Privacy and account safety

Treat patient names, hospital numbers, allergies, diet instructions, and clinical notes as confidential health information. Use only authorized accounts, lock the workstation when leaving it, do not export patient data to personal devices, do not place API keys in browser JavaScript, and report suspected credential exposure immediately. The preview dataset in this package is synthetic; production use requires the hospital’s privacy, security, access-control, backup, and audit approvals.
