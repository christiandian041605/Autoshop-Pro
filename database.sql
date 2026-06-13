-- AutoShop Pro Database Schema
-- Target: MySQL 5.7+ / 8.0+

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `staff_attendance`;
DROP TABLE IF EXISTS `feedback`;
DROP TABLE IF EXISTS `vehicle_pms_schedules`;
DROP TABLE IF EXISTS `notifications_log`;
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `invoices`;
DROP TABLE IF EXISTS `job_order_parts`;
DROP TABLE IF EXISTS `purchase_order_items`;
DROP TABLE IF EXISTS `purchase_orders`;
DROP TABLE IF EXISTS `suppliers`;
DROP TABLE IF EXISTS `parts_inventory`;
DROP TABLE IF EXISTS `job_order_tasks`;
DROP TABLE IF EXISTS `job_order_mechanics`;
DROP TABLE IF EXISTS `job_orders`;
DROP TABLE IF EXISTS `appointments`;
DROP TABLE IF EXISTS `vehicles`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- --------------------------------------------------------
-- Table: users (Staff Profiles and Accounts)
-- --------------------------------------------------------
CREATE TABLE `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `full_name` VARCHAR(100) NOT NULL,
  `role` ENUM('admin', 'mechanic', 'service_advisor', 'cashier', 'guard') NOT NULL,
  `contact_number` VARCHAR(20) DEFAULT NULL,
  `employment_status` ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_role (`role`),
  INDEX idx_user_status (`employment_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: customers
-- --------------------------------------------------------
CREATE TABLE `customers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `full_name` VARCHAR(150) NOT NULL,
  `contact_number` VARCHAR(20) NOT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `address` TEXT DEFAULT NULL,
  `customer_type` ENUM('individual', 'fleet', 'corporate') NOT NULL DEFAULT 'individual',
  `notes` TEXT DEFAULT NULL,
  `flag_vip` TINYINT(1) NOT NULL DEFAULT 0,
  `flag_blacklisted` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_customer_type (`customer_type`),
  INDEX idx_customer_flags (`flag_vip`, `flag_blacklisted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: vehicles
-- --------------------------------------------------------
CREATE TABLE `vehicles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `customer_id` INT NOT NULL,
  `plate_number` VARCHAR(20) NOT NULL UNIQUE,
  `vin_chassis` VARCHAR(50) NOT NULL UNIQUE,
  `make` VARCHAR(50) NOT NULL,
  `model` VARCHAR(50) NOT NULL,
  `year` INT NOT NULL,
  `color` VARCHAR(30) NOT NULL,
  `fuel_type` ENUM('gasoline', 'diesel', 'electric', 'hybrid', 'lpg') NOT NULL,
  `current_mileage` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_vehicle_customer (`customer_id`),
  INDEX idx_vehicle_plate (`plate_number`),
  INDEX idx_vehicle_vin (`vin_chassis`),
  CONSTRAINT fk_vehicle_customer FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: appointments
-- --------------------------------------------------------
CREATE TABLE `appointments` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `customer_id` INT NOT NULL,
  `vehicle_id` INT NOT NULL,
  `appointment_date_time` DATETIME NOT NULL,
  `classification` ENUM('walk_in', 'pre_booked') NOT NULL DEFAULT 'pre_booked',
  `assigned_mechanic_id` INT DEFAULT NULL,
  `assigned_bay_slot` VARCHAR(30) DEFAULT NULL,
  `estimated_duration_minutes` INT NOT NULL DEFAULT 60,
  `estimated_release_date_time` DATETIME NOT NULL,
  `actual_release_date_time` DATETIME DEFAULT NULL,
  `reschedule_reason` VARCHAR(255) DEFAULT NULL,
  `status` ENUM('booked', 'confirmed', 'in_progress', 'ready_for_release', 'released', 'cancelled') NOT NULL DEFAULT 'booked',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_appointment_customer (`customer_id`),
  INDEX idx_appointment_vehicle (`vehicle_id`),
  INDEX idx_appointment_status (`status`),
  INDEX idx_appointment_date (`appointment_date_time`),
  CONSTRAINT fk_appointment_customer FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_appointment_vehicle FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_appointment_mechanic FOREIGN KEY (`assigned_mechanic_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: job_orders (Work Orders)
-- --------------------------------------------------------
CREATE TABLE `job_orders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `job_order_number` VARCHAR(30) NOT NULL UNIQUE,
  `appointment_id` INT DEFAULT NULL,
  `customer_id` INT NOT NULL,
  `vehicle_id` INT NOT NULL,
  `reported_problem` TEXT NOT NULL,
  `inspection_checklist` JSON DEFAULT NULL,
  `estimated_cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('pending', 'in_progress', 'for_qc', 'payment_cleared', 'released') NOT NULL DEFAULT 'pending',
  `pre_release_cleanliness` TINYINT(1) NOT NULL DEFAULT 0,
  `pre_release_parts_returned` TINYINT(1) NOT NULL DEFAULT 0,
  `pre_release_tools_cleared` TINYINT(1) NOT NULL DEFAULT 0,
  `gate_pass_number` VARCHAR(50) DEFAULT NULL UNIQUE,
  `customer_signature` VARCHAR(255) DEFAULT NULL, -- Path to stored digital signature file
  `releasing_staff_id` INT DEFAULT NULL,
  `receiving_person_name` VARCHAR(100) DEFAULT NULL,
  `exit_photo` VARCHAR(255) DEFAULT NULL, -- Path to exit verification image
  `exit_odometer` INT DEFAULT NULL,
  `actual_release_date_time` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_jo_number (`job_order_number`),
  INDEX idx_jo_customer (`customer_id`),
  INDEX idx_jo_vehicle (`vehicle_id`),
  INDEX idx_jo_status (`status`),
  CONSTRAINT fk_jo_appointment FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_jo_customer FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_jo_vehicle FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_jo_releasing_staff FOREIGN KEY (`releasing_staff_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: job_order_mechanics (Many-to-Many Assignment)
-- --------------------------------------------------------
CREATE TABLE `job_order_mechanics` (
  `job_order_id` INT NOT NULL,
  `mechanic_id` INT NOT NULL,
  PRIMARY KEY (`job_order_id`, `mechanic_id`),
  CONSTRAINT fk_jom_jo FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_jom_mechanic FOREIGN KEY (`mechanic_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: job_order_tasks (Labor and Tasks)
-- --------------------------------------------------------
CREATE TABLE `job_order_tasks` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `job_order_id` INT NOT NULL,
  `task_description` VARCHAR(255) NOT NULL,
  `assigned_mechanic_id` INT DEFAULT NULL,
  `estimated_hours` DECIMAL(4,2) NOT NULL DEFAULT 1.00,
  `labor_rate_per_hour` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `fixed_charge` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  -- Note: We compute total labor cost dynamically or store it. For compatibility across MySQL versions, we store and update it via application or use standard generated columns.
  `total_labor_cost` DECIMAL(10,2) GENERATED ALWAYS AS (COALESCE(labor_rate_per_hour * estimated_hours, 0) + fixed_charge) STORED,
  `status` ENUM('pending', 'in_progress', 'completed') NOT NULL DEFAULT 'pending',
  `start_time` DATETIME DEFAULT NULL,
  `end_time` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_jot_jo (`job_order_id`),
  INDEX idx_jot_status (`status`),
  CONSTRAINT fk_jot_jo FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_jot_mechanic FOREIGN KEY (`assigned_mechanic_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: parts_inventory
-- --------------------------------------------------------
CREATE TABLE `parts_inventory` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `part_number` VARCHAR(50) NOT NULL UNIQUE,
  `description` VARCHAR(255) NOT NULL,
  `brand` VARCHAR(50) DEFAULT NULL,
  `category` VARCHAR(50) DEFAULT NULL,
  `current_stock` INT NOT NULL DEFAULT 0,
  `unit_of_measure` VARCHAR(20) NOT NULL DEFAULT 'pcs',
  `bin_location` VARCHAR(50) DEFAULT NULL,
  `minimum_stock` INT NOT NULL DEFAULT 5,
  `cost_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `selling_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `markup_percentage` DECIMAL(5,2) GENERATED ALWAYS AS (CASE WHEN cost_price > 0 THEN ((selling_price - cost_price) / cost_price) * 100 ELSE 0 END) STORED,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_part_number (`part_number`),
  INDEX idx_part_stock (`current_stock`, `minimum_stock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: suppliers
-- --------------------------------------------------------
CREATE TABLE `suppliers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `supplier_name` VARCHAR(150) NOT NULL,
  `contact_person` VARCHAR(100) DEFAULT NULL,
  `contact_number` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `address` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: purchase_orders
-- --------------------------------------------------------
CREATE TABLE `purchase_orders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `po_number` VARCHAR(30) NOT NULL UNIQUE,
  `supplier_id` INT NOT NULL,
  `order_date` DATE NOT NULL,
  `status` ENUM('pending', 'received', 'cancelled') NOT NULL DEFAULT 'pending',
  `total_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `received_date` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_po_number (`po_number`),
  INDEX idx_po_status (`status`),
  CONSTRAINT fk_po_supplier FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: purchase_order_items
-- --------------------------------------------------------
CREATE TABLE `purchase_order_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `purchase_order_id` INT NOT NULL,
  `part_id` INT NOT NULL,
  `quantity` INT NOT NULL,
  `unit_cost` DECIMAL(10,2) NOT NULL,
  `total_cost` DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
  CONSTRAINT fk_poi_po FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_poi_part FOREIGN KEY (`part_id`) REFERENCES `parts_inventory` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: job_order_parts (Parts Consumed in Job Orders)
-- --------------------------------------------------------
CREATE TABLE `job_order_parts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `job_order_id` INT NOT NULL,
  `part_id` INT NOT NULL,
  `quantity_used` INT NOT NULL DEFAULT 1,
  `unit_selling_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `total_price` DECIMAL(10,2) GENERATED ALWAYS AS (quantity_used * unit_selling_price) STORED,
  `status` ENUM('pending_approval', 'approved', 'rejected') NOT NULL DEFAULT 'approved',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_jop_jo (`job_order_id`),
  CONSTRAINT fk_jop_jo FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_jop_part FOREIGN KEY (`part_id`) REFERENCES `parts_inventory` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: invoices
-- --------------------------------------------------------
CREATE TABLE `invoices` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `invoice_number` VARCHAR(30) NOT NULL UNIQUE,
  `job_order_id` INT NOT NULL,
  `subtotal_labor` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `subtotal_parts` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `tax_rate` DECIMAL(5,2) NOT NULL DEFAULT 12.00, -- Default Philippine VAT is 12%
  `tax_amount` DECIMAL(10,2) GENERATED ALWAYS AS ((subtotal_labor + subtotal_parts) * (tax_rate / 100)) STORED,
  `discount_type` ENUM('none', 'senior_citizen', 'loyalty', 'promo', 'custom') NOT NULL DEFAULT 'none',
  `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` DECIMAL(10,2) GENERATED ALWAYS AS ((subtotal_labor + subtotal_parts) + ((subtotal_labor + subtotal_parts) * (tax_rate / 100)) - discount_amount) STORED,
  `balance_due` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `payment_status` ENUM('unpaid', 'partial', 'fully_paid') NOT NULL DEFAULT 'unpaid',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_invoice_number (`invoice_number`),
  INDEX idx_invoice_jo (`job_order_id`),
  INDEX idx_invoice_payment_status (`payment_status`),
  CONSTRAINT fk_invoice_jo FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: payments
-- --------------------------------------------------------
CREATE TABLE `payments` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `invoice_id` INT NOT NULL,
  `amount_paid` DECIMAL(10,2) NOT NULL,
  `payment_method` ENUM('cash', 'card', 'gcash', 'maya', 'bank_transfer') NOT NULL,
  `transaction_reference` VARCHAR(100) DEFAULT NULL,
  `payment_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `received_by_staff_id` INT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_payment_invoice (`invoice_id`),
  CONSTRAINT fk_payment_invoice FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_payment_staff FOREIGN KEY (`received_by_staff_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: notifications_log
-- --------------------------------------------------------
CREATE TABLE `notifications_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `customer_id` INT NOT NULL,
  `message_type` ENUM('appointment_reminder', 'job_started', 'approval_requested', 'ready_for_pickup', 'invoice_sent', 'maintenance_reminder') NOT NULL,
  `channel` ENUM('sms', 'email') NOT NULL,
  `recipient_address` VARCHAR(150) NOT NULL,
  `message_content` TEXT NOT NULL,
  `delivery_status` ENUM('pending', 'sent', 'failed', 'read') NOT NULL DEFAULT 'pending',
  `sent_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notif_customer (`customer_id`),
  INDEX idx_notif_status (`delivery_status`),
  CONSTRAINT fk_notif_customer FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: vehicle_pms_schedules
-- --------------------------------------------------------
CREATE TABLE `vehicle_pms_schedules` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `vehicle_id` INT NOT NULL,
  `service_interval_km` INT NOT NULL DEFAULT 5000,
  `service_interval_months` INT NOT NULL DEFAULT 3,
  `last_service_date` DATE DEFAULT NULL,
  `last_service_odometer` INT NOT NULL DEFAULT 0,
  `next_due_date` DATE DEFAULT NULL,
  `next_due_odometer` INT DEFAULT 0,
  `status` ENUM('pending', 'overdue', 'completed') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_pms_vehicle (`vehicle_id`),
  INDEX idx_pms_status (`status`),
  CONSTRAINT fk_pms_vehicle FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: feedback
-- --------------------------------------------------------
CREATE TABLE `feedback` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `job_order_id` INT NOT NULL,
  `rating` INT NOT NULL,
  `comment` TEXT DEFAULT NULL,
  `submitted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_feedback_jo (`job_order_id`),
  CONSTRAINT fk_feedback_jo FOREIGN KEY (`job_order_id`) REFERENCES `job_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT chk_feedback_rating CHECK (`rating` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Table: staff_attendance
-- --------------------------------------------------------
CREATE TABLE `staff_attendance` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `clock_in` DATETIME NOT NULL,
  `clock_out` DATETIME DEFAULT NULL,
  `attendance_date` DATE NOT NULL,
  `overtime_hours` DECIMAL(4,2) NOT NULL DEFAULT 0.00,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_attendance_user (`user_id`),
  INDEX idx_attendance_date (`attendance_date`),
  CONSTRAINT fk_attendance_user FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Seeding Initial Roles & Test Admin Account
-- Password for admin is 'AdminPassword123' (hashed using bcrypt)
-- --------------------------------------------------------
INSERT INTO `users` (`username`, `password_hash`, `full_name`, `role`, `contact_number`, `employment_status`)
VALUES ('admin', '$2y$10$wN9aE3zXw8J2z3d2G/3qLuL1L6b.kQ2tYgG83c9x3l9w6GzT4UjN2', 'System Administrator', 'admin', '09171234567', 'active');
