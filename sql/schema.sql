CREATE DATABASE IF NOT EXISTS kitchen_food CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE kitchen_food;

CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  role ENUM('admin','dietitian','kitchen_supervisor','storekeeper','food_service') NOT NULL DEFAULT 'food_service',
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS patients (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  external_id VARCHAR(120) NOT NULL,
  source_system VARCHAR(120) NOT NULL,
  hospital_no VARCHAR(120) NOT NULL,
  name VARCHAR(190) NOT NULL,
  ward VARCHAR(120) NULL,
  room VARCHAR(80) NULL,
  allergies TEXT NULL,
  clinical_notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_patient_source (external_id, source_system),
  KEY idx_patient_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS clinicians (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  external_id VARCHAR(120) NOT NULL,
  source_system VARCHAR(120) NOT NULL,
  name VARCHAR(190) NOT NULL,
  specialty VARCHAR(150) NULL,
  UNIQUE KEY uq_clinician_source (external_id, source_system)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS diet_types (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(40) NOT NULL UNIQUE,
  name VARCHAR(190) NOT NULL,
  category VARCHAR(80) NOT NULL,
  therapeutic TINYINT(1) NOT NULL DEFAULT 0,
  restrictions_json JSON NULL,
  active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS diet_orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  patient_id INT UNSIGNED NOT NULL,
  clinician_id INT UNSIGNED NULL,
  patient_name VARCHAR(190) NOT NULL,
  diet_code VARCHAR(40) NOT NULL,
  diet_name VARCHAR(190) NOT NULL,
  clinician_name VARCHAR(190) NOT NULL,
  effective_from DATE NOT NULL,
  effective_to DATE NULL,
  meal_texture VARCHAR(80) NULL,
  calories INT NULL,
  notes TEXT NULL,
  status ENUM('draft','active','completed','cancelled') NOT NULL DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_orders_patient_status (patient_id, status),
  CONSTRAINT fk_orders_patient FOREIGN KEY (patient_id) REFERENCES patients(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS menus (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  menu_date DATE NOT NULL,
  meal_period ENUM('Breakfast','Lunch','Dinner','Snack') NOT NULL,
  title VARCHAR(190) NOT NULL,
  status ENUM('Planning','Published','Archived') NOT NULL DEFAULT 'Planning',
  items TEXT NULL,
  calories INT NULL,
  protein_g DECIMAL(8,2) NULL,
  carbs_g DECIMAL(8,2) NULL,
  fat_g DECIMAL(8,2) NULL,
  UNIQUE KEY uq_menu_slot (menu_date, meal_period)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS menu_items (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  menu_id INT UNSIGNED NOT NULL,
  item_name VARCHAR(190) NOT NULL,
  ingredients_json JSON NULL,
  calories INT NULL,
  protein_g DECIMAL(8,2) NULL,
  carbs_g DECIMAL(8,2) NULL,
  fat_g DECIMAL(8,2) NULL,
  allergens_json JSON NULL,
  compatible_diets_json JSON NULL,
  CONSTRAINT fk_menu_items_menu FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trays (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tray_ref VARCHAR(80) NOT NULL UNIQUE,
  diet_order_id INT UNSIGNED NULL,
  patient_id INT UNSIGNED NULL,
  patient_name VARCHAR(190) NOT NULL,
  ward VARCHAR(120) NULL,
  meal_period VARCHAR(40) NOT NULL,
  status ENUM('Planned','Assembled','Dispatched','Delivered','Consumed','Refused') NOT NULL DEFAULT 'Planned',
  diet VARCHAR(40) NOT NULL,
  scheduled_at DATETIME NOT NULL,
  assembled_at DATETIME NULL,
  dispatched_at DATETIME NULL,
  delivered_at DATETIME NULL,
  KEY idx_trays_schedule (scheduled_at, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS consumption (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tray_ref VARCHAR(80) NOT NULL,
  patient_name VARCHAR(190) NOT NULL,
  status VARCHAR(80) NOT NULL,
  consumed_percent TINYINT UNSIGNED NOT NULL DEFAULT 0,
  refusal_reason VARCHAR(190) NULL,
  recorded_at DATETIME NOT NULL,
  recorded_by VARCHAR(190) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ingredients (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(80) NOT NULL UNIQUE,
  name VARCHAR(190) NOT NULL,
  unit VARCHAR(30) NOT NULL,
  on_hand DECIMAL(12,3) NOT NULL DEFAULT 0,
  reorder_level DECIMAL(12,3) NOT NULL DEFAULT 0,
  expiry_date DATE NULL,
  category VARCHAR(80) NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  KEY idx_ingredients_expiry (expiry_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stock_movements (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ingredient_id INT UNSIGNED NOT NULL,
  movement_type ENUM('receipt','issue','adjustment','return','wastage') NOT NULL,
  quantity DECIMAL(12,3) NOT NULL,
  reference VARCHAR(190) NULL,
  performed_by VARCHAR(190) NOT NULL,
  performed_at DATETIME NOT NULL,
  CONSTRAINT fk_movements_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS wastage (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ingredient VARCHAR(190) NOT NULL,
  quantity DECIMAL(12,3) NOT NULL,
  unit VARCHAR(30) NOT NULL,
  reason VARCHAR(190) NOT NULL,
  notes TEXT NULL,
  recorded_at DATETIME NOT NULL,
  recorded_by VARCHAR(190) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS integration_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_id VARCHAR(80) NOT NULL,
  endpoint VARCHAR(190) NOT NULL,
  source_system VARCHAR(120) NULL,
  external_id VARCHAR(120) NULL,
  request_hash CHAR(64) NULL,
  status_code SMALLINT UNSIGNED NOT NULL,
  message VARCHAR(500) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_integration_external (source_system, external_id)
) ENGINE=InnoDB;
