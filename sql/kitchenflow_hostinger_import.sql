-- KitchenFlow complete MySQL schema
-- Target: MySQL 8.0.21+ / MariaDB 10.6+
-- Run with an administrative account, then grant the application user only the
-- privileges needed by this database. Never commit production passwords here.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE IF NOT EXISTS facilities (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_code VARCHAR(80) NOT NULL,
  name VARCHAR(190) NOT NULL,
  timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_facility_code (facility_code),
  KEY idx_facility_active (active)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NULL,
  external_id VARCHAR(120) NULL,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL,
  password_hash VARCHAR(255) NULL,
  role ENUM('admin','dietitian','kitchen_supervisor','chef','storekeeper','food_service','ward_nurse','auditor') NOT NULL DEFAULT 'food_service',
  active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_facility_email (facility_id, email),
  KEY idx_user_active_role (facility_id, active, role),
  CONSTRAINT fk_user_facility FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS patients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  external_id VARCHAR(120) NOT NULL,
  source_system VARCHAR(120) NOT NULL,
  hospital_no VARCHAR(120) NOT NULL,
  national_or_local_id VARCHAR(120) NULL,
  name VARCHAR(190) NOT NULL,
  date_of_birth DATE NULL,
  sex VARCHAR(30) NULL,
  ward VARCHAR(120) NULL,
  room VARCHAR(80) NULL,
  bed VARCHAR(80) NULL,
  admission_status ENUM('admitted','discharged','transferred','unknown') NOT NULL DEFAULT 'unknown',
  allergies_text TEXT NULL,
  allergies_json JSON NULL,
  clinical_notes TEXT NULL,
  data_as_of DATETIME NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_patient_source (facility_id, source_system, external_id),
  KEY idx_patient_hospital_no (facility_id, hospital_no),
  KEY idx_patient_name (facility_id, name),
  KEY idx_patient_location (facility_id, ward, room),
  CONSTRAINT fk_patient_facility FOREIGN KEY (facility_id) REFERENCES facilities(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS clinicians (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  external_id VARCHAR(120) NOT NULL,
  source_system VARCHAR(120) NOT NULL,
  name VARCHAR(190) NOT NULL,
  specialty VARCHAR(150) NULL,
  registration_no VARCHAR(120) NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_clinician_source (facility_id, source_system, external_id),
  KEY idx_clinician_name (facility_id, name),
  CONSTRAINT fk_clinician_facility FOREIGN KEY (facility_id) REFERENCES facilities(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS diet_types (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NULL,
  code VARCHAR(40) NOT NULL,
  name VARCHAR(190) NOT NULL,
  category ENUM('Standard','Therapeutic','Texture modified','Cultural preference','Other') NOT NULL DEFAULT 'Other',
  therapeutic TINYINT(1) NOT NULL DEFAULT 0,
  description TEXT NULL,
  restrictions_json JSON NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_diet_type_facility_code (facility_id, code),
  KEY idx_diet_type_active (facility_id, active),
  CONSTRAINT fk_diet_type_facility FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS diet_orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  patient_id BIGINT UNSIGNED NOT NULL,
  clinician_id BIGINT UNSIGNED NULL,
  external_id VARCHAR(120) NULL,
  source_system VARCHAR(120) NULL,
  patient_name_snapshot VARCHAR(190) NOT NULL,
  diet_code VARCHAR(40) NOT NULL,
  diet_name_snapshot VARCHAR(190) NOT NULL,
  clinician_name_snapshot VARCHAR(190) NULL,
  prescribed_at DATETIME NULL,
  effective_from DATETIME NOT NULL,
  effective_to DATETIME NULL,
  meal_texture VARCHAR(80) NULL,
  calories INT UNSIGNED NULL,
  fluid_limit_ml INT UNSIGNED NULL,
  notes TEXT NULL,
  status ENUM('draft','active','completed','cancelled','superseded','on_hold') NOT NULL DEFAULT 'draft',
  cancellation_reason VARCHAR(255) NULL,
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_diet_order_external (facility_id, source_system, external_id),
  KEY idx_diet_order_patient_status (facility_id, patient_id, status),
  KEY idx_diet_order_effective (facility_id, effective_from, effective_to),
  KEY idx_diet_order_source (facility_id, source_system, external_id),
  CONSTRAINT fk_diet_order_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_diet_order_patient FOREIGN KEY (patient_id) REFERENCES patients(id),
  CONSTRAINT fk_diet_order_clinician FOREIGN KEY (clinician_id) REFERENCES clinicians(id) ON DELETE SET NULL,
  CONSTRAINT fk_diet_order_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_diet_order_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_diet_order_dates CHECK (effective_to IS NULL OR effective_to >= effective_from)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS diet_order_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  diet_order_id BIGINT UNSIGNED NOT NULL,
  event_type ENUM('created','activated','updated','held','completed','cancelled','superseded') NOT NULL,
  previous_status VARCHAR(30) NULL,
  new_status VARCHAR(30) NULL,
  reason VARCHAR(255) NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  source_system VARCHAR(120) NULL,
  external_event_id VARCHAR(120) NULL,
  occurred_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_diet_order_event_external (facility_id, source_system, external_event_id),
  KEY idx_diet_order_events_order_time (diet_order_id, occurred_at),
  CONSTRAINT fk_diet_event_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_diet_event_order FOREIGN KEY (diet_order_id) REFERENCES diet_orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_diet_event_actor FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS menus (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  menu_date DATE NOT NULL,
  meal_period ENUM('Breakfast','Lunch','Dinner','Snack') NOT NULL,
  title VARCHAR(190) NOT NULL,
  status ENUM('Planning','Published','Archived') NOT NULL DEFAULT 'Planning',
  notes TEXT NULL,
  calories INT UNSIGNED NULL,
  protein_g DECIMAL(8,2) NULL,
  carbs_g DECIMAL(8,2) NULL,
  fat_g DECIMAL(8,2) NULL,
  published_by BIGINT UNSIGNED NULL,
  published_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_menu_facility_slot (facility_id, menu_date, meal_period),
  KEY idx_menu_date_status (facility_id, menu_date, status),
  CONSTRAINT fk_menu_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_menu_published_by FOREIGN KEY (published_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS menu_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  menu_id BIGINT UNSIGNED NOT NULL,
  item_name VARCHAR(190) NOT NULL,
  ingredients_json JSON NULL,
  calories INT UNSIGNED NULL,
  protein_g DECIMAL(8,2) NULL,
  carbs_g DECIMAL(8,2) NULL,
  fat_g DECIMAL(8,2) NULL,
  allergens_json JSON NULL,
  compatible_diets_json JSON NULL,
  texture VARCHAR(80) NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_menu_item_order (menu_id, sort_order),
  CONSTRAINT fk_menu_item_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_menu_item_menu FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ingredients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  sku VARCHAR(80) NOT NULL,
  name VARCHAR(190) NOT NULL,
  unit VARCHAR(30) NOT NULL,
  category VARCHAR(80) NULL,
  on_hand DECIMAL(12,3) NOT NULL DEFAULT 0,
  reorder_level DECIMAL(12,3) NOT NULL DEFAULT 0,
  par_level DECIMAL(12,3) NULL,
  expiry_date DATE NULL,
  storage_location VARCHAR(120) NULL,
  allergen_flags_json JSON NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_ingredient_facility_sku (facility_id, sku),
  KEY idx_ingredient_expiry (facility_id, expiry_date),
  KEY idx_ingredient_reorder (facility_id, on_hand, reorder_level),
  CONSTRAINT fk_ingredient_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT chk_ingredient_nonnegative CHECK (on_hand >= 0 AND reorder_level >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stock_movements (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  ingredient_id BIGINT UNSIGNED NOT NULL,
  movement_type ENUM('receipt','issue','adjustment','return','wastage') NOT NULL,
  quantity DECIMAL(12,3) NOT NULL,
  unit_cost DECIMAL(12,4) NULL,
  reference_type VARCHAR(80) NULL,
  reference_id BIGINT UNSIGNED NULL,
  reference_text VARCHAR(190) NULL,
  performed_by BIGINT UNSIGNED NULL,
  performed_at DATETIME NOT NULL,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_stock_movement_ingredient_time (ingredient_id, performed_at),
  KEY idx_stock_movement_facility_time (facility_id, performed_at),
  CONSTRAINT fk_stock_movement_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_stock_movement_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
  CONSTRAINT fk_stock_movement_user FOREIGN KEY (performed_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_stock_movement_quantity CHECK (quantity > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS wastage_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  ingredient_id BIGINT UNSIGNED NULL,
  ingredient_name_snapshot VARCHAR(190) NOT NULL,
  quantity DECIMAL(12,3) NOT NULL,
  unit VARCHAR(30) NOT NULL,
  reason ENUM('preparation_trim','expiry_temperature','overproduction','spillage_damage','contamination','other') NOT NULL,
  notes TEXT NULL,
  recorded_by BIGINT UNSIGNED NULL,
  recorded_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_wastage_facility_time (facility_id, recorded_at),
  KEY idx_wastage_reason (facility_id, reason),
  CONSTRAINT fk_wastage_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_wastage_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE SET NULL,
  CONSTRAINT fk_wastage_user FOREIGN KEY (recorded_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_wastage_quantity CHECK (quantity > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trays (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  tray_ref VARCHAR(80) NOT NULL,
  diet_order_id BIGINT UNSIGNED NULL,
  patient_id BIGINT UNSIGNED NULL,
  menu_id BIGINT UNSIGNED NULL,
  patient_name_snapshot VARCHAR(190) NOT NULL,
  hospital_no_snapshot VARCHAR(120) NULL,
  ward_snapshot VARCHAR(120) NULL,
  room_snapshot VARCHAR(80) NULL,
  meal_period ENUM('Breakfast','Lunch','Dinner','Snack') NOT NULL,
  diet_code VARCHAR(40) NOT NULL,
  status ENUM('Planned','Assembled','Dispatched','Delivered','Consumed','Partially Consumed','Refused','Returned','Not Received','Cancelled') NOT NULL DEFAULT 'Planned',
  scheduled_at DATETIME NOT NULL,
  assembled_at DATETIME NULL,
  dispatched_at DATETIME NULL,
  delivered_at DATETIME NULL,
  returned_at DATETIME NULL,
  closed_at DATETIME NULL,
  exception_reason VARCHAR(255) NULL,
  version_no INT UNSIGNED NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tray_facility_ref (facility_id, tray_ref),
  KEY idx_tray_service_board (facility_id, scheduled_at, status),
  KEY idx_tray_patient_date (facility_id, patient_id, scheduled_at),
  KEY idx_tray_ward_status (facility_id, ward_snapshot, status),
  CONSTRAINT fk_tray_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_tray_order FOREIGN KEY (diet_order_id) REFERENCES diet_orders(id) ON DELETE SET NULL,
  CONSTRAINT fk_tray_patient FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE SET NULL,
  CONSTRAINT fk_tray_menu FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tray_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  tray_id BIGINT UNSIGNED NOT NULL,
  event_type ENUM('planned','assembled','dispatched','delivered','consumed','partially_consumed','refused','returned','not_received','cancelled','corrected') NOT NULL,
  previous_status VARCHAR(40) NULL,
  new_status VARCHAR(40) NULL,
  reason VARCHAR(255) NULL,
  location VARCHAR(120) NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  source_system VARCHAR(120) NULL,
  source_device_id VARCHAR(120) NULL,
  external_event_id VARCHAR(120) NULL,
  occurred_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tray_event_external (facility_id, source_system, external_event_id),
  KEY idx_tray_event_tray_time (tray_id, occurred_at),
  KEY idx_tray_event_facility_time (facility_id, occurred_at),
  CONSTRAINT fk_tray_event_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_tray_event_tray FOREIGN KEY (tray_id) REFERENCES trays(id) ON DELETE CASCADE,
  CONSTRAINT fk_tray_event_actor FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS consumption_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  tray_id BIGINT UNSIGNED NOT NULL,
  status ENUM('Consumed','Partially Consumed','Refused','Not Received','Unknown') NOT NULL DEFAULT 'Unknown',
  consumed_percent TINYINT UNSIGNED NULL,
  refusal_reason VARCHAR(190) NULL,
  notes TEXT NULL,
  recorded_by BIGINT UNSIGNED NULL,
  recorded_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_consumption_tray_time (tray_id, recorded_at),
  CONSTRAINT fk_consumption_facility FOREIGN KEY (facility_id) REFERENCES facilities(id),
  CONSTRAINT fk_consumption_tray FOREIGN KEY (tray_id) REFERENCES trays(id),
  CONSTRAINT fk_consumption_user FOREIGN KEY (recorded_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_consumption_percent CHECK (consumed_percent IS NULL OR consumed_percent BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_clients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NOT NULL,
  client_code VARCHAR(100) NOT NULL,
  client_name VARCHAR(190) NOT NULL,
  source_system VARCHAR(120) NOT NULL,
  auth_method ENUM('api_key','hmac_sha256','oauth2_client_credentials','mtls') NOT NULL DEFAULT 'api_key',
  allowed_ips_json JSON NULL,
  scopes_json JSON NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  last_used_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at DATETIME NULL,
  UNIQUE KEY uq_api_client_facility_code (facility_id, client_code),
  KEY idx_api_client_active (facility_id, active),
  CONSTRAINT fk_api_client_facility FOREIGN KEY (facility_id) REFERENCES facilities(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_client_secrets (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  api_client_id BIGINT UNSIGNED NOT NULL,
  secret_prefix VARCHAR(24) NOT NULL,
  secret_hash CHAR(64) NOT NULL,
  valid_from DATETIME NOT NULL,
  valid_until DATETIME NULL,
  revoked_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_used_at DATETIME NULL,
  UNIQUE KEY uq_api_secret_prefix (secret_prefix),
  KEY idx_api_secret_client_validity (api_client_id, valid_from, valid_until, revoked_at),
  CONSTRAINT fk_api_secret_client FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  api_client_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  token_type VARCHAR(40) NOT NULL DEFAULT 'Bearer',
  scopes_json JSON NULL,
  issued_at DATETIME NOT NULL,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  last_used_at DATETIME NULL,
  UNIQUE KEY uq_api_token_hash (token_hash),
  KEY idx_api_token_validity (api_client_id, expires_at, revoked_at),
  CONSTRAINT fk_api_token_client FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_nonces (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  api_client_id BIGINT UNSIGNED NOT NULL,
  nonce VARCHAR(190) NOT NULL,
  expires_at DATETIME NOT NULL,
  consumed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_api_nonce_client_value (api_client_id, nonce),
  KEY idx_api_nonce_expiry (expires_at),
  CONSTRAINT fk_api_nonce_client FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS integration_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NULL,
  request_id VARCHAR(80) NOT NULL,
  api_client_id BIGINT UNSIGNED NULL,
  endpoint VARCHAR(190) NOT NULL,
  http_method VARCHAR(10) NOT NULL,
  source_system VARCHAR(120) NULL,
  external_id VARCHAR(120) NULL,
  request_hash CHAR(64) NULL,
  status_code SMALLINT UNSIGNED NOT NULL,
  message VARCHAR(500) NULL,
  remote_ip VARBINARY(16) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_integration_request (request_id),
  KEY idx_integration_external (facility_id, source_system, external_id),
  KEY idx_integration_created (created_at),
  CONSTRAINT fk_integration_facility FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE SET NULL,
  CONSTRAINT fk_integration_client FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  facility_id BIGINT UNSIGNED NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  api_client_id BIGINT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id BIGINT UNSIGNED NULL,
  before_json JSON NULL,
  after_json JSON NULL,
  request_id VARCHAR(80) NULL,
  remote_ip VARBINARY(16) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_audit_entity (entity_type, entity_id, created_at),
  KEY idx_audit_facility_time (facility_id, created_at),
  CONSTRAINT fk_audit_facility FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE SET NULL,
  CONSTRAINT fk_audit_user FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_audit_client FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE OR REPLACE VIEW v_active_diet_orders AS
SELECT o.*, p.hospital_no, p.ward, p.room, p.allergies_text, p.allergies_json
FROM diet_orders o
JOIN patients p ON p.id = o.patient_id
WHERE o.status = 'active'
  AND (o.effective_to IS NULL OR o.effective_to >= UTC_TIMESTAMP());

CREATE OR REPLACE VIEW v_inventory_alerts AS
SELECT i.*, CASE WHEN i.on_hand <= i.reorder_level THEN 'LOW_STOCK' ELSE 'OK' END AS stock_state,
       CASE WHEN i.expiry_date IS NOT NULL AND i.expiry_date <= UTC_DATE() + INTERVAL 7 DAY THEN 'EXPIRING_SOON' ELSE 'OK' END AS expiry_state
FROM ingredients i
WHERE i.active = 1
  AND (i.on_hand <= i.reorder_level OR (i.expiry_date IS NOT NULL AND i.expiry_date <= UTC_DATE() + INTERVAL 7 DAY));

-- Minimal lookup data. These inserts are idempotent and may be customized per facility.
INSERT INTO diet_types (facility_id, code, name, category, therapeutic, description)
SELECT NULL, 'REG', 'Regular balanced', 'Standard', 0, 'Standard balanced hospital diet'
WHERE NOT EXISTS (SELECT 1 FROM diet_types WHERE facility_id IS NULL AND code = 'REG');
INSERT INTO diet_types (facility_id, code, name, category, therapeutic, description)
SELECT NULL, 'DM', 'Diabetic / controlled carbohydrate', 'Therapeutic', 1, 'Controlled carbohydrate plan; confirm clinical targets'
WHERE NOT EXISTS (SELECT 1 FROM diet_types WHERE facility_id IS NULL AND code = 'DM');
INSERT INTO diet_types (facility_id, code, name, category, therapeutic, description)
SELECT NULL, 'RENAL', 'Renal low sodium', 'Therapeutic', 1, 'Renal plan; confirm fluid, potassium, and protein limits'
WHERE NOT EXISTS (SELECT 1 FROM diet_types WHERE facility_id IS NULL AND code = 'RENAL');
INSERT INTO diet_types (facility_id, code, name, category, therapeutic, description)
SELECT NULL, 'SOFT', 'Soft / easy chew', 'Texture modified', 0, 'Texture-modified diet'
WHERE NOT EXISTS (SELECT 1 FROM diet_types WHERE facility_id IS NULL AND code = 'SOFT');
INSERT INTO diet_types (facility_id, code, name, category, therapeutic, description)
SELECT NULL, 'VEG', 'Vegetarian Indian', 'Cultural preference', 0, 'Vegetarian cultural preference profile'
WHERE NOT EXISTS (SELECT 1 FROM diet_types WHERE facility_id IS NULL AND code = 'VEG');

-- Optional example application account. Replace the password hash using password_hash()
-- in a controlled provisioning script; do not place a plaintext password in SQL.
-- INSERT INTO users (facility_id, name, email, password_hash, role)
-- VALUES (1, 'Kitchen Supervisor', 'kitchen@example.org', '$2y$10$REPLACE_WITH_BCRYPT_HASH', 'kitchen_supervisor');

-- Recommended application privileges, to be executed by a DBA after creating the user:
-- CREATE USER 'kitchen_app'@'10.%' IDENTIFIED BY 'use-a-secret-manager';
-- GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON kitchen_food.* TO 'kitchen_app'@'10.%';
-- FLUSH PRIVILEGES;
