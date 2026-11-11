-- =====================================================
-- File   : 05_Basic_Queries.sql
-- Purpose: Basic SELECT, filtering, sorting, DISTINCT [DQL]
--          and UPDATE / DELETE demonstrations        [DML]
-- =====================================================
USE medicare_db;

-- Q1. List all patients
SELECT patient_id, first_name, last_name, gender, phone FROM Patients;

-- Q2. Patients with blood group O+
SELECT patient_id, first_name, last_name, blood_group
FROM Patients
WHERE blood_group = 'O+';

-- Q3. Doctors whose consultation fee is above 700
SELECT doctor_id, first_name, last_name, specialization, consultation_fee
FROM Doctors
WHERE consultation_fee > 700;

-- Q4. Appointments that are still scheduled
SELECT appointment_id, patient_id, doctor_id, appointment_date, appointment_time
FROM Appointments
WHERE status = 'Scheduled';

-- Q5. Patients registered between 1 Aug 2026 and 31 Aug 2026 (BETWEEN)
SELECT patient_id, first_name, last_name, registered_on
FROM Patients
WHERE registered_on BETWEEN '2026-08-01' AND '2026-08-31';

-- Q6. Search patients whose first name starts with 'A' (LIKE)
SELECT patient_id, first_name, last_name
FROM Patients
WHERE first_name LIKE 'A%';

-- Q7. Doctors sorted by fee, highest first (ORDER BY)
SELECT first_name, last_name, specialization, consultation_fee
FROM Doctors
ORDER BY consultation_fee DESC, last_name ASC;

-- Q8. Distinct doctor specializations (DISTINCT)
SELECT DISTINCT specialization
FROM Doctors
ORDER BY specialization;

-- Q9. Distinct blood groups present among patients
SELECT DISTINCT blood_group
FROM Patients
ORDER BY blood_group;

-- Q10. Appointments with status Completed or Cancelled (IN)
SELECT appointment_id, appointment_date, status
FROM Appointments
WHERE status IN ('Completed','Cancelled')
ORDER BY appointment_date DESC
LIMIT 5;

-- -----------------------------------------------------
-- DML demonstrations: INSERT, UPDATE, DELETE
-- (uses a temporary test patient; cleanup is safe to repeat)
-- -----------------------------------------------------

-- Clean up test record if an earlier execution was interrupted
DELETE FROM Patients WHERE phone = '9900009999' OR phone = '9900008888';

-- INSERT a new patient (patient registration step of the workflow)
INSERT INTO Patients (first_name,last_name,gender,date_of_birth,phone,email,address,blood_group)
VALUES ('Test','Patient','Other','2000-01-01','9900009999','test.patient@mail.test','Demo Address','O+');

-- UPDATE: change the new patient's phone number and address
UPDATE Patients
SET phone = '9900008888', address = 'Updated Demo Address'
WHERE phone = '9900009999';

SELECT patient_id, first_name, phone, address FROM Patients WHERE first_name = 'Test';

-- DELETE: remove the test patient using phone number
DELETE FROM Patients WHERE phone = '9900008888';

SELECT COUNT(*) AS patients_after_delete FROM Patients;
