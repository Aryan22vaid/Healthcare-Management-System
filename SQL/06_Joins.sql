-- =====================================================
-- File   : 06_Joins.sql
-- Purpose: INNER / LEFT / SELF joins and patient history [DQL]
-- =====================================================
USE medicare_db;

-- J1. Appointment list with patient and doctor names (INNER JOIN, 3 tables)
SELECT a.appointment_id,
       CONCAT(p.first_name,' ',p.last_name) AS patient,
       CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor,
       a.appointment_date, a.status
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors  d ON a.doctor_id  = d.doctor_id
ORDER BY a.appointment_date
LIMIT 8;

-- J2. Doctors with their department (INNER JOIN)
SELECT CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor,
       d.specialization, dep.dept_name, dep.location
FROM Doctors d
JOIN Departments dep ON d.dept_id = dep.dept_id
ORDER BY dep.dept_name;

-- J3. All appointments and their bills; appointments without a bill show NULL (LEFT JOIN)
SELECT a.appointment_id, a.appointment_date, a.status, b.bill_id, b.total_amount
FROM Appointments a
LEFT JOIN Bills b ON a.appointment_id = b.appointment_id
WHERE b.bill_id IS NULL;

-- J4. COMPLETE MEDICAL HISTORY of patient 1 (feature: Patient medical history)
--     Appointments -> Medical record -> Prescription -> Items -> Medicine (using LEFT JOIN for optional relationships)
SELECT a.appointment_date AS visit_date,
       CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor,
       mr.diagnosis,
       m.medicine_name, pi.dosage, pi.duration_days
FROM Patients p
JOIN Appointments a       ON a.patient_id = p.patient_id
JOIN Doctors d            ON a.doctor_id = d.doctor_id
LEFT JOIN Medical_Records mr   ON mr.appointment_id = a.appointment_id
LEFT JOIN Prescriptions pr     ON pr.record_id = mr.record_id
LEFT JOIN Prescription_Items pi ON pi.prescription_id = pr.prescription_id
LEFT JOIN Medicines m          ON m.medicine_id = pi.medicine_id
WHERE p.patient_id = 1
ORDER BY a.appointment_date;

-- J5. Outstanding balance per bill (LEFT JOIN with Payments + GROUP BY)
SELECT b.bill_id, b.total_amount,
       COALESCE(SUM(py.amount_paid),0) AS paid,
       b.total_amount - COALESCE(SUM(py.amount_paid),0) AS balance
FROM Bills b
LEFT JOIN Payments py ON py.bill_id = b.bill_id
GROUP BY b.bill_id, b.total_amount
HAVING balance > 0;

-- J6. Pairs of doctors working in the same department (SELF JOIN)
SELECT d1.last_name AS doctor_1, d2.last_name AS doctor_2, dep.dept_name
FROM Doctors d1
JOIN Doctors d2 ON d1.dept_id = d2.dept_id AND d1.doctor_id < d2.doctor_id
JOIN Departments dep ON dep.dept_id = d1.dept_id;

-- J7. Prescription of appointment 1: medicines, dosage and cost
SELECT m.medicine_name, pi.dosage, pi.quantity, m.unit_price,
       pi.quantity * m.unit_price AS line_total
FROM Medical_Records mr
JOIN Prescriptions pr      ON pr.record_id = mr.record_id
JOIN Prescription_Items pi ON pi.prescription_id = pr.prescription_id
JOIN Medicines m           ON m.medicine_id = pi.medicine_id
WHERE mr.appointment_id = 1;
