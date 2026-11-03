-- Four VS Realty Company LTD | MySQL 8.0+
-- Starter schema based on the group's concept paper.
-- Never upload real client personal data or private documents to a public repository.

CREATE DATABASE IF NOT EXISTS four_vs_realty_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE four_vs_realty_db;

CREATE TABLE roles (
 role_id INT AUTO_INCREMENT PRIMARY KEY,
 role_name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE users (
 user_id INT AUTO_INCREMENT PRIMARY KEY,
 role_id INT NOT NULL,
 full_name VARCHAR(120) NOT NULL,
 username VARCHAR(60) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 email VARCHAR(120) UNIQUE,
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE projects (
 project_id INT AUTO_INCREMENT PRIMARY KEY,
 project_name VARCHAR(100) NOT NULL UNIQUE,
 location VARCHAR(180),
 description TEXT,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lots (
 lot_id INT AUTO_INCREMENT PRIMARY KEY,
 project_id INT NOT NULL,
 lot_number VARCHAR(40) NOT NULL,
 lot_area_sqm DECIMAL(10,2) NOT NULL,
 price_per_sqm DECIMAL(12,2) NOT NULL,
 lot_price DECIMAL(14,2) NOT NULL,
 lot_status ENUM('Available','Reserved','Sold','Re-open') NOT NULL DEFAULT 'Available',
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 FOREIGN KEY (project_id) REFERENCES projects(project_id),
 UNIQUE (project_id, lot_number),
 CHECK (lot_area_sqm > 0),
 CHECK (lot_price >= 0)
);

CREATE TABLE clients (
 client_id INT AUTO_INCREMENT PRIMARY KEY,
 registered_by_user_id INT,
 full_name VARCHAR(150) NOT NULL,
 contact_number VARCHAR(30),
 email VARCHAR(120),
 address TEXT,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (registered_by_user_id) REFERENCES users(user_id)
);

CREATE TABLE client_documents (
 document_id INT AUTO_INCREMENT PRIMARY KEY,
 client_id INT NOT NULL,
 uploaded_by_user_id INT NOT NULL,
 document_type ENUM('CIS','CTS','TIN-related','ID','Specimen Signature','Receipt','Other') NOT NULL,
 file_name VARCHAR(255) NOT NULL,
 storage_path VARCHAR(500) NOT NULL,
 uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (client_id) REFERENCES clients(client_id),
 FOREIGN KEY (uploaded_by_user_id) REFERENCES users(user_id)
);

CREATE TABLE appointments (
 appointment_id INT AUTO_INCREMENT PRIMARY KEY,
 client_id INT NOT NULL,
 lot_id INT,
 requested_by_user_id INT NOT NULL,
 appointment_date DATETIME NOT NULL,
 purpose VARCHAR(255),
 appointment_status ENUM('Pending','Approved','Rejected','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
 reviewed_by_user_id INT,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (client_id) REFERENCES clients(client_id),
 FOREIGN KEY (lot_id) REFERENCES lots(lot_id),
 FOREIGN KEY (requested_by_user_id) REFERENCES users(user_id),
 FOREIGN KEY (reviewed_by_user_id) REFERENCES users(user_id)
);

CREATE TABLE reservations (
 reservation_id INT AUTO_INCREMENT PRIMARY KEY,
 lot_id INT NOT NULL,
 client_id INT NOT NULL,
 agent_user_id INT NOT NULL,
 reviewed_by_user_id INT,
 request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 decision_date DATETIME,
 reservation_fee DECIMAL(14,2) NOT NULL DEFAULT 0,
 reservation_status ENUM('Pending','Approved','Rejected','Cancelled','Converted to Sale') NOT NULL DEFAULT 'Pending',
 notes TEXT,
 FOREIGN KEY (lot_id) REFERENCES lots(lot_id),
 FOREIGN KEY (client_id) REFERENCES clients(client_id),
 FOREIGN KEY (agent_user_id) REFERENCES users(user_id),
 FOREIGN KEY (reviewed_by_user_id) REFERENCES users(user_id),
 CHECK (reservation_fee >= 0)
);

CREATE TABLE payment_plans (
 payment_plan_id INT AUTO_INCREMENT PRIMARY KEY,
 reservation_id INT NOT NULL UNIQUE,
 contract_price DECIMAL(14,2) NOT NULL,
 reservation_fee DECIMAL(14,2) NOT NULL DEFAULT 0,
 down_payment DECIMAL(14,2) NOT NULL DEFAULT 0,
 balance_financed DECIMAL(14,2) NOT NULL,
 monthly_amortization DECIMAL(14,2) NOT NULL,
 number_of_months INT NOT NULL,
 start_date DATE,
 plan_status ENUM('Active','Completed','Cancelled') NOT NULL DEFAULT 'Active',
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
 CHECK (contract_price >= 0 AND reservation_fee >= 0 AND down_payment >= 0 AND balance_financed >= 0 AND monthly_amortization >= 0 AND number_of_months > 0)
);

CREATE TABLE payments (
 payment_id INT AUTO_INCREMENT PRIMARY KEY,
 payment_plan_id INT NOT NULL,
 recorded_by_user_id INT NOT NULL,
 payment_date DATE NOT NULL,
 amount DECIMAL(14,2) NOT NULL,
 payment_method ENUM('Cash','Bank Transfer','Check') NOT NULL,
 reference_number VARCHAR(100),
 receipt_file_path VARCHAR(500),
 remarks TEXT,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (payment_plan_id) REFERENCES payment_plans(payment_plan_id),
 FOREIGN KEY (recorded_by_user_id) REFERENCES users(user_id),
 CHECK (amount > 0)
);

CREATE TABLE project_expenses (
 expense_id INT AUTO_INCREMENT PRIMARY KEY,
 project_id INT NOT NULL,
 recorded_by_user_id INT NOT NULL,
 expense_date DATE NOT NULL,
 description VARCHAR(255) NOT NULL,
 amount DECIMAL(14,2) NOT NULL,
 receipt_file_path VARCHAR(500),
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (project_id) REFERENCES projects(project_id),
 FOREIGN KEY (recorded_by_user_id) REFERENCES users(user_id),
 CHECK (amount >= 0)
);

CREATE TABLE agent_commissions (
 commission_id INT AUTO_INCREMENT PRIMARY KEY,
 reservation_id INT NOT NULL,
 agent_user_id INT NOT NULL,
 commission_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
 commission_status ENUM('Pending','Approved','Paid','Cancelled') NOT NULL DEFAULT 'Pending',
 computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 paid_at DATETIME,
 FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
 FOREIGN KEY (agent_user_id) REFERENCES users(user_id),
 CHECK (commission_amount >= 0)
);

CREATE TABLE agent_incentives (
 incentive_id INT AUTO_INCREMENT PRIMARY KEY,
 agent_user_id INT NOT NULL,
 reservation_id INT,
 incentive_type VARCHAR(80) NOT NULL DEFAULT 'Rice Incentive',
 quantity DECIMAL(10,2) NOT NULL DEFAULT 0,
 amount DECIMAL(14,2) NOT NULL DEFAULT 0,
 incentive_date DATE NOT NULL,
 remarks TEXT,
 FOREIGN KEY (agent_user_id) REFERENCES users(user_id),
 FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
 CHECK (quantity >= 0 AND amount >= 0)
);

CREATE TABLE audit_logs (
 audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
 user_id INT,
 action_type VARCHAR(80) NOT NULL,
 table_name VARCHAR(80) NOT NULL,
 record_id BIGINT,
 action_details TEXT,
 action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO roles (role_name) VALUES ('CEO'),('Admin'),('Processor'),('Agent');
INSERT INTO projects (project_name, location, description) VALUES
('Mampayag','Mampayag','Project identified in the concept paper; reported sold out.'),
('Gango','Gango','Project identified in the concept paper; reported sold out.'),
('Poblacion','Poblacion','Project identified in the concept paper; selected subdivided lots available.');

-- Quick checks
SELECT * FROM roles;
SELECT * FROM projects;
SELECT lot_status, COUNT(*) AS total_lots FROM lots GROUP BY lot_status;
