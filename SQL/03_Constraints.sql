-- =====================================================
-- File   : 03_Constraints.sql
-- Purpose: DDL demonstration - ALTER / DROP, indexes,
--          and extra constraints added after table creation
-- =====================================================

USE medicare_db;

-- ALTER: add a column
ALTER TABLE Patients ADD COLUMN emergency_contact VARCHAR(15);

-- ALTER: modify a column
ALTER TABLE Patients MODIFY COLUMN address VARCHAR(200);

-- ALTER: add a CHECK constraint
ALTER TABLE Patients
    ADD CONSTRAINT chk_dob CHECK (date_of_birth >= '1900-01-01');

-- ALTER: add an index to speed up searching patients by last name
CREATE INDEX idx_patient_lastname ON Patients(last_name);

-- Index on appointment date (used by analytics queries)
CREATE INDEX idx_app_date ON Appointments(appointment_date);

-- ALTER: drop a column (demonstration - removes the column added above)
ALTER TABLE Patients DROP COLUMN emergency_contact;

-- DROP: create and drop a temporary table
CREATE TABLE temp_demo (id INT PRIMARY KEY, note VARCHAR(20));
DROP TABLE temp_demo;

-- A VIEW for doctor-wise appointment summary (used later)
CREATE OR REPLACE VIEW vw_appointment_details AS
SELECT a.appointment_id,
       CONCAT(p.first_name,' ',p.last_name) AS patient_name,
       CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor_name,
       dep.dept_name,
       a.appointment_date, a.appointment_time, a.status
FROM Appointments a
JOIN Patients p     ON a.patient_id = p.patient_id
JOIN Doctors d      ON a.doctor_id  = d.doctor_id
JOIN Departments dep ON d.dept_id   = dep.dept_id;

DESCRIBE Patients;
