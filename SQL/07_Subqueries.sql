-- =====================================================
-- File   : 07_Subqueries.sql
-- Purpose: Nested, correlated, IN / EXISTS subqueries [DQL]
-- =====================================================
USE medicare_db;

-- S1. Doctors charging more than the average consultation fee
SELECT first_name, last_name, consultation_fee
FROM Doctors
WHERE consultation_fee > (SELECT AVG(consultation_fee) FROM Doctors);

-- S2. Patients who have consulted a Cardiology doctor (IN subquery)
SELECT patient_id, first_name, last_name
FROM Patients
WHERE patient_id IN (
    SELECT a.patient_id
    FROM Appointments a
    JOIN Doctors d ON a.doctor_id = d.doctor_id
    JOIN Departments dep ON d.dept_id = dep.dept_id
    WHERE dep.dept_name = 'Cardiology');

-- S3. Patients with at least one unpaid bill (EXISTS, correlated)
SELECT p.patient_id, p.first_name, p.last_name
FROM Patients p
WHERE EXISTS (
    SELECT 1
    FROM Appointments a
    JOIN Bills b ON b.appointment_id = a.appointment_id
    WHERE a.patient_id = p.patient_id AND b.payment_status = 'Unpaid');

-- S4. Most expensive medicine (subquery with MAX)
SELECT medicine_name, unit_price
FROM Medicines
WHERE unit_price = (SELECT MAX(unit_price) FROM Medicines);

-- S5. Bills above the average bill amount
SELECT bill_id, appointment_id, total_amount
FROM Bills
WHERE total_amount > (SELECT AVG(total_amount) FROM Bills)
ORDER BY total_amount DESC;

-- S6. DOCTOR AVAILABILITY CHECK (feature)
--     Doctor 1 on 2026-08-04 at 10:00 -> returns 'Not available' if the slot is taken
SELECT CASE
         WHEN EXISTS (SELECT 1 FROM Appointments
                      WHERE doctor_id = 1
                        AND appointment_date = '2026-08-04'
                        AND appointment_time = '10:00:00'
                        AND status <> 'Cancelled')
         THEN 'Not available'
         ELSE 'Available'
       END AS slot_status;

-- S7. Doctors who have never had a cancelled appointment (NOT IN)
SELECT doctor_id, first_name, last_name
FROM Doctors
WHERE doctor_id NOT IN (SELECT doctor_id FROM Appointments WHERE status = 'Cancelled');

-- S8. Patients with more appointments than the average per patient (subquery in HAVING)
SELECT patient_id, COUNT(*) AS visits
FROM Appointments
GROUP BY patient_id
HAVING COUNT(*) > (SELECT COUNT(*) / COUNT(DISTINCT patient_id) FROM Appointments);
