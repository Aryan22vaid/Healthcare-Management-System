-- =====================================================
-- File   : 02_Create_Tables.sql
-- Purpose: Create the 10 tables with PK, FK, UNIQUE,
--          NOT NULL, CHECK and DEFAULT constraints [DDL]
-- =====================================================

USE medicare_db;

-- 1. Departments
CREATE TABLE Departments (
    dept_id     INT AUTO_INCREMENT PRIMARY KEY,
    dept_name   VARCHAR(60)  NOT NULL UNIQUE,
    location    VARCHAR(60)  NOT NULL DEFAULT 'Main Block'
);

-- 2. Patients
CREATE TABLE Patients (
    patient_id    INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(40)  NOT NULL,
    last_name     VARCHAR(40)  NOT NULL,
    gender        ENUM('Male','Female','Other') NOT NULL,
    date_of_birth DATE         NOT NULL,
    phone         VARCHAR(15)  NOT NULL UNIQUE,
    email         VARCHAR(80)  UNIQUE,
    address       VARCHAR(150),
    blood_group   VARCHAR(3),
    registered_on DATE         NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT chk_blood CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-') OR blood_group IS NULL)
);

-- 3. Doctors
CREATE TABLE Doctors (
    doctor_id        INT AUTO_INCREMENT PRIMARY KEY,
    first_name       VARCHAR(40)  NOT NULL,
    last_name        VARCHAR(40)  NOT NULL,
    specialization   VARCHAR(60)  NOT NULL,
    phone            VARCHAR(15)  NOT NULL UNIQUE,
    email            VARCHAR(80)  UNIQUE,
    consultation_fee DECIMAL(8,2) NOT NULL,
    dept_id          INT          NOT NULL,
    joined_on        DATE         NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT chk_fee CHECK (consultation_fee > 0),
    CONSTRAINT fk_doctor_dept FOREIGN KEY (dept_id) REFERENCES Departments(dept_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 4. Appointments
CREATE TABLE Appointments (
    appointment_id   INT AUTO_INCREMENT PRIMARY KEY,
    patient_id       INT  NOT NULL,
    doctor_id        INT  NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status           ENUM('Scheduled','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    reason           VARCHAR(150),
    -- Generated status is NULL for cancelled rows, freeing that time slot.
    -- Active rows share the value Active, so the UNIQUE key prevents double-booking.
    active_status    VARCHAR(10) GENERATED ALWAYS AS
                     (CASE WHEN status = 'Cancelled' THEN NULL ELSE 'Active' END) STORED,
    CONSTRAINT fk_app_patient FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_app_doctor  FOREIGN KEY (doctor_id)  REFERENCES Doctors(doctor_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_doctor_slot UNIQUE (doctor_id, appointment_date, appointment_time, active_status)
);

-- 5. Medical_Records
CREATE TABLE Medical_Records (
    record_id      INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,          -- one record per appointment
    diagnosis      VARCHAR(200) NOT NULL,
    notes          TEXT,
    record_date    DATE NOT NULL,
    CONSTRAINT fk_rec_app FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- 6. Medicines
CREATE TABLE Medicines (
    medicine_id   INT AUTO_INCREMENT PRIMARY KEY,
    medicine_name VARCHAR(80)  NOT NULL UNIQUE,
    category      VARCHAR(50)  NOT NULL,
    unit_price    DECIMAL(8,2) NOT NULL,
    CONSTRAINT chk_price CHECK (unit_price >= 0)
);

-- 7. Prescriptions
CREATE TABLE Prescriptions (
    prescription_id   INT AUTO_INCREMENT PRIMARY KEY,
    record_id         INT  NOT NULL,
    prescription_date DATE NOT NULL,
    advice            VARCHAR(200),
    CONSTRAINT fk_presc_rec FOREIGN KEY (record_id) REFERENCES Medical_Records(record_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- 8. Prescription_Items  (resolves many-to-many: Prescriptions <-> Medicines)
CREATE TABLE Prescription_Items (
    prescription_id INT NOT NULL,
    medicine_id     INT NOT NULL,
    dosage          VARCHAR(40) NOT NULL,       -- e.g. '1-0-1'
    duration_days   INT NOT NULL,
    quantity        INT NOT NULL,
    PRIMARY KEY (prescription_id, medicine_id),  -- composite key
    CONSTRAINT chk_days CHECK (duration_days > 0),
    CONSTRAINT chk_qty  CHECK (quantity > 0),
    CONSTRAINT fk_item_presc FOREIGN KEY (prescription_id) REFERENCES Prescriptions(prescription_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_item_med   FOREIGN KEY (medicine_id) REFERENCES Medicines(medicine_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 9. Bills
CREATE TABLE Bills (
    bill_id        INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,         -- one bill per appointment
    bill_date      DATE NOT NULL,
    consult_charge DECIMAL(10,2) NOT NULL DEFAULT 0,
    medicine_charge DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount   DECIMAL(10,2) NOT NULL,
    payment_status ENUM('Unpaid','Partial','Paid') NOT NULL DEFAULT 'Unpaid',
    CONSTRAINT chk_total CHECK (total_amount >= 0),
    CONSTRAINT fk_bill_app FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 10. Payments
CREATE TABLE Payments (
    payment_id   INT AUTO_INCREMENT PRIMARY KEY,
    bill_id      INT NOT NULL,
    payment_date DATE NOT NULL,
    amount_paid  DECIMAL(10,2) NOT NULL,
    method       ENUM('Cash','Card','UPI','Insurance') NOT NULL DEFAULT 'Cash',
    CONSTRAINT chk_paid CHECK (amount_paid > 0),
    CONSTRAINT fk_pay_bill FOREIGN KEY (bill_id) REFERENCES Bills(bill_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

SHOW TABLES;
