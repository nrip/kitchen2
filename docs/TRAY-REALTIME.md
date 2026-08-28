# Tray Delivery, Return, and Real-Time Update Guide

## Executive answer

The delivered KitchenFlow starter currently provides **workflow status updates**, but not automatic real-time browser push. A staff member changes a tray status through the Tray Service screen, the PHP form updates the data store, and the page reloads. A second user sees the new state when they refresh or reopen the page.

The current statuses are **Planned**, **Assembled**, **Dispatched**, **Delivered**, **Consumed**, and **Refused**. There is not yet a dedicated **Returned** status or a persistent event timeline for every handoff. A returned tray should therefore be handled as a refusal or exception in the starter version, with the reason recorded through the hospital’s approved operational process.

This behavior is intentionally simple and safe for the preview. It should not be described as real-time push until polling, Server-Sent Events, WebSockets, or an equivalent event channel has been added.

## Current update sequence

| Step | Staff action | Current system behavior | What another user sees |
|---|---|---|---|
| 1 | Kitchen plans a tray | Tray remains in Planned | Visible after the other user loads or refreshes Tray Service. |
| 2 | Assembly staff verifies identifiers and selects Assembled | A PHP POST updates the tray record and redirects to Tray Service | The updated badge appears on the next page load. |
| 3 | Delivery staff dispatches the tray | A PHP POST updates the status to Dispatched | The kitchen sees it after a refresh. |
| 4 | Ward or delivery staff confirms handover | A PHP POST updates the status to Delivered | The kitchen sees it after a refresh. |
| 5 | Ward staff records intake | The consumption register records a percentage and status when implemented through the operational flow | Kitchen staff see the record after a refresh or report review. |
| 6 | Patient refuses or tray comes back | The starter supports Refused but has no distinct Returned state or return timestamp | Staff need a clear reason and local escalation until the return event extension is implemented. |

## Recommended operational use today

During the pilot, agree a refresh interval for each service period. For example, the kitchen supervisor can keep the Tray Service page open and refresh it every 30–60 seconds during dispatch peaks, while the ward records delivery and consumption promptly. For urgent changes such as a nil-by-mouth instruction, patient transfer, allergy discovery, or missing tray, staff must use the hospital’s immediate escalation channel rather than waiting for a screen refresh.

Use the tray reference as the shared identifier in phone calls, ward messages, paper downtime records, and reconciliation reports. A message should identify the tray reference, patient hospital number, ward, meal period, current status, requested action, and staff member. Avoid transmitting unnecessary clinical notes in unsecured chat.

## Recommended production event model

For reliable delivery and return tracking, retain the current tray row as the latest state and add an append-only `tray_events` table. Each event should include the tray ID, event type, event time, actor ID, source device or system, ward, reason, notes, and a unique event ID. The latest state is convenient for dashboards; the event history is needed for audit, reconciliation, and investigation.

Recommended event types are `planned`, `assembled`, `dispatched`, `delivered`, `consumed`, `partially_consumed`, `refused`, `returned`, `not_received`, `cancelled`, and `corrected`. A return event should capture whether the tray was untouched, partially consumed, clinically held, rejected due to mismatch, or returned for another reason. It should also capture the time the ward handed the tray back and the time the kitchen received it.

A recommended return workflow is:

1. Ward staff select **Return tray** and choose a reason.
2. Kitchen receives the tray and confirms **Return received**.
3. The system records the return time, receiver, reason, and food-safety disposition.
4. The supervisor decides whether the tray is discarded, reworked under an approved policy, or investigated as a mismatch.
5. The dietitian or ward is notified when the return relates to a clinical restriction, allergy, patient transfer, or missed meal.

A returned tray must not automatically be marked consumed. Consumption and return are separate clinical and operational outcomes.

## Real-time implementation choices

| Method | User experience | Fit for this PHP/MySQL module | Recommendation |
|---|---|---|---|
| Manual refresh | Staff refresh the board when needed | Already available | Acceptable for a controlled pilot or downtime-safe fallback. |
| Short polling | Browser asks for changes every 15–30 seconds | Simple PHP endpoint plus jQuery timer | Best first production enhancement for normal hospital volumes. |
| Server-Sent Events | Browser receives one-way updates as they occur | Requires a long-lived PHP-compatible process and proxy configuration | Good when live one-way status updates are important and the host supports long-lived requests. |
| WebSockets | Bi-directional live communication | More infrastructure and operational complexity | Use only if the hospital needs high-frequency collaboration or live acknowledgements. |
| Push notification to phones | Alerts staff outside the dashboard | Requires mobile/device notification infrastructure | Consider for urgent exceptions, not as the only tray record. |

For this module’s stack, **short polling is the safest next step**. Add an authenticated endpoint such as `GET /api/v1/trays/updates?since=2026-08-27T10:30:00Z`, returning only changed tray states and new event IDs. The kitchen and ward screens can use jQuery to request updates every 15–30 seconds, update the affected card, and show a non-clinical alert such as “Tray TRAY-24004 changed to Delivered.” The response should be scoped to the authorized hospital, ward, or role.

## Polling design requirements

The polling endpoint should use a server timestamp or monotonic event ID rather than relying only on the browser clock. It should return a `server_time`, `next_since`, and a list of changed records. The client should back off after repeated failures, show the age of the last successful update, and never overwrite a newer local state with an older response.

A production endpoint should support filters such as hospital, kitchen, ward, meal period, and status. It should return only fields needed for the operational board. Patient clinical notes and full allergy narratives should not be broadcast to every connected screen. Use authorization checks, HTTPS, rate limiting, and audit logging for update access.

## Conflict handling

Two staff members may act on the same tray close together. The server should enforce valid transitions and include a version number or `updated_at` value. If a nurse records Delivered after the kitchen has cancelled the tray, the server should reject the transition and return a conflict requiring supervisor review. The client must display a clear message and reload the authoritative state.

Do not allow a browser to change a tray solely because it received a stale notification. The status-change request must be authorized and validated on the server, and the event history must identify the actor who made the change.

## Nurse workflow after real-time enhancement

The nurse opens the ward tray board or the patient’s clinical screen. New Dispatched or Delivered events appear automatically with the tray reference, meal period, and ward location. The nurse confirms receipt, records consumption or refusal, and records a return reason when applicable. A return or refusal event is visible to the kitchen supervisor and dietitian through their next polling cycle or live subscription.

The nurse should still verify the physical tray and patient identifiers. A live update indicates a change in the operational record; it does not replace bedside identity checks.

## Kitchen workflow after real-time enhancement

The kitchen supervisor sees trays move across the board without refreshing, sees missed-delivery or return exceptions, and can filter by ward or meal period. The kitchen should acknowledge exceptions, contact the ward where appropriate, and close the loop when the returned tray is physically received. A dashboard notification is not sufficient evidence that the food changed hands; the event should be recorded by the responsible staff member.

## Testing acceptance criteria

A production release should prove that a status change in one browser becomes visible in an authorized second browser within the agreed interval, that unauthorized users receive no tray data, that a network failure shows a stale-data warning, that duplicate events do not create duplicate trays, that out-of-order responses cannot roll back a newer state, and that every delivery and return has an actor and timestamp.

The test team should simulate patient transfer, nil-by-mouth, allergy conflict, refused meal, untouched return, partially consumed return, lost connection, duplicate scan, and simultaneous nurse/kitchen updates. The hospital should approve the final meaning of each status and event before live use.
