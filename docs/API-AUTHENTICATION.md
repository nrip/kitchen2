# KitchenFlow API Authentication and Token Configuration

**Audience:** HMS/HIS integration developers, infrastructure administrators, and security reviewers.

## 1. Current authentication model

The delivered module uses a shared integration key for server-to-server API calls. The HMS sends the key in the HTTP header `X-Integration-Key`, and KitchenFlow compares it with the server-side `INTEGRATION_API_KEY` environment value using a timing-safe comparison. This is appropriate for an initial controlled integration between trusted servers, but the key must be treated as a high-value secret and should not be exposed in browser JavaScript, iframe URLs, HTML source, mobile apps, logs, screenshots, or client-side configuration.

The health endpoint is intentionally public for connectivity checks:

```text
GET /api/v1/health
```

All other API routes require the integration key, including patient lookup, patient and clinician upsert, diet-order retrieval and creation, CSV import, and daily kitchen export.

## 2. Create a production key

Generate a long random value on a trusted administration machine. Do not use the demonstration value `demo-integration-key` in production.

```bash
openssl rand -hex 32
```

Store the output in the hospital’s approved secrets manager or protected server environment. The value should be different for each environment and, where practical, different for each integrating HMS tenant or partner.

## 3. Configure KitchenFlow

Set the application environment before starting PHP-FPM, Apache, or the process manager that launches the application:

```bash
export KITCHEN_DB_HOST=127.0.0.1
export KITCHEN_DB_PORT=3306
export KITCHEN_DB_NAME=kitchen_food
export KITCHEN_DB_USER=kitchen_app
export KITCHEN_DB_PASS='database-password-from-secret-store'
export INTEGRATION_API_KEY='paste-the-generated-random-value-here'
```

The module reads these values through `getenv()`. The environment file must not be inside the web root or committed to source control. If Apache or PHP-FPM does not inherit shell variables, configure them through the service manager or the host’s protected environment mechanism and restart the PHP worker after changing them.

A deployment should use a dedicated MySQL account with only the privileges required by the schema and application. The PHP process must be able to write the preview data file only in demo mode; in MySQL mode, it should not need write access to source files.

## 4. Configure the HMS client

The HMS should call KitchenFlow from its server-side integration service, not directly from a browser. The request must use HTTPS and include the key in the header:

```bash
curl --fail-with-body \\
  --request GET \\
  --header 'X-Integration-Key: replace-with-the-production-key' \\
  'https://kitchen.example-hospital.org/api/v1/patients?search=Mehta'
```

A patient upsert example is:

```bash
curl --fail-with-body \\
  --request POST \\
  --header 'Content-Type: application/json' \\
  --header 'X-Integration-Key: replace-with-the-production-key' \\
  --data '{
    "external_id":"PAT-2001",
    "source_system":"HIS-ACME",
    "hospital_no":"MRN-2001",
    "name":"Example Patient",
    "ward":"Ward 4A",
    "room":"401",
    "allergies":"None reported",
    "clinical_notes":""
  }' \\
  'https://kitchen.example-hospital.org/api/v1/patients/upsert'
```

The HMS should use timeouts, TLS certificate validation, bounded retries, and a correlation ID in its own logs. A retry is safe only after the HMS understands the returned status and the operation’s idempotency behavior. Patient and clinician upserts are designed around the external ID and source system. Diet-order creation should be given a separate idempotency mechanism before high-volume retrying is enabled.

## 5. Validate the connection

Start with the public health check, then test an authenticated read. A successful health response confirms routing but does not prove that the shared key is correct.

```bash
curl --fail-with-body \\
  'https://kitchen.example-hospital.org/api/v1/health'

curl --fail-with-body \\
  --header 'X-Integration-Key: replace-with-the-production-key' \\
  'https://kitchen.example-hospital.org/api/v1/diet-orders?patient_external_id=PAT-2001'
```

The API returns a JSON object containing `success`, `data` when applicable, `message` when applicable, and `request_id`. Store the `request_id` with the HMS transaction log so the two teams can troubleshoot a failed exchange without copying patient data into tickets or chat messages.

## 6. Recommended network controls

Allow API access only over HTTPS. Restrict the API at the reverse proxy or firewall to the HMS integration server addresses where a stable allowlist is possible. Apply rate limiting, request-size limits, access logging with secret redaction, and an alert for repeated HTTP 401 responses. Do not log the `X-Integration-Key` value or complete clinical payloads. If the module and HMS are hosted in different networks, use a private link or VPN where the hospital architecture supports it.

The public health endpoint should return only service and version information. It should not include database hostnames, credentials, patient data, or stack traces. Production PHP error display must be disabled and errors must be written to a protected server log.

## 7. Key rotation procedure

Use a controlled two-key rotation rather than changing the key during an active integration window. First generate a new key, deploy a small authentication change that accepts both the current and next key for a short overlap period, update the HMS to use the next key, confirm successful API calls, then remove the old key. The delivered starter code accepts one key, so the overlap behavior must be added in the deployment hardening work before rotating a live key without downtime.

Record the key owner, environment, creation date, last rotation date, next rotation date, approved consumers, and revocation contact in the hospital’s secret inventory. Revoke and replace the key immediately if it appears in source control, a browser request, a client application, a public log, or an unapproved support channel.

## 8. Partner and multi-tenant integrations

If KitchenFlow will be offered to other hospitals or competing HMS products, do not give every consumer one global key. Introduce an integration-client table with a client identifier, a hashed secret or public/private key credential, allowed scopes, source-system code, status, IP restrictions, created date, last-used date, and revocation date. Resolve the client to its permitted source system before accepting patient or diet-order payloads.

The next security level should use one of these patterns:

| Pattern | Suitable use | Implementation note |
|---|---|---|
| Separate HTTPS API key per consumer | Controlled hospital-to-hospital integration | Keep the current header pattern but issue and revoke keys independently. Store only a hash where practical. |
| HMAC-signed requests | Integrations requiring replay protection and request integrity | Sign method, path, timestamp, nonce, and body; reject stale timestamps and reused nonces. |
| OAuth2 client credentials | Multiple products, scopes, and centralized authorization | Issue short-lived access tokens to server-side clients; never use them in a browser widget. |
| mTLS plus API credential | High-assurance private network | Require a client certificate in addition to application authorization. |

For the widget, prefer a short-lived, patient-scoped server-generated session or a backend-for-frontend proxy. Do not place the master integration key in the iframe URL. The current demo widget uses the module’s browser session and CSRF token for its own form; the production HIS should add trusted-origin restrictions and a proper SSO/session bridge.

## 9. Minimum production acceptance tests

Before connecting real clinical data, the administrator should verify that an absent key returns HTTP 401, a wrong key returns HTTP 401, the correct key returns the requested data, the health response contains no secrets, TLS is enforced, the key is absent from browser source and logs, patient external IDs are reconciled, and the key can be revoked. Test the same controls in staging and production-like network conditions.

The application should also undergo the hospital’s privacy, access-control, backup, disaster-recovery, vulnerability-management, and clinical safety review. This guide describes the delivered starter authentication model and a hardening path; it is not a substitute for the hospital’s formal security approval.
