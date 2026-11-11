-- =====================================================
-- File   : 08_Aggregate_Functions.sql
-- Purpose: Aggregates, GROUP BY, HAVING, hospital analytics [DQL]
-- =====================================================
USE medicare_db;

-- A1. Total number of patients
SELECT COUNT(*) AS total_patients FROM Patients;

-- A2. Average, minimum and maximum consultation fee
SELECT AVG(consultation_fee) AS avg_fee,
       MIN(consultation_fee) AS min_fee,
       MAX(consultation_fee) AS max_fee
FROM Doctors;

-- A3. Total billed amount and total amount collected
SELECT (SELECT SUM(total_amount) FROM Bills)   AS total_billed,
       (SELECT SUM(amount_paid)  FROM Payments) AS total_collected;

-- A4. Number of appointments by status (GROUP BY)
SELECT status, COUNT(*) AS total
FROM Appointments
GROUP BY status;

-- A5. ANALYTICS: Most frequently consulted doctors
SELECT CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor,
       COUNT(*) AS consultations
FROM Appointments a
JOIN Doctors d ON a.doctor_id = d.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY consultations DESC, doctor
LIMIT 5;

-- A6. ANALYTICS: Department-wise patient count (distinct patients)
SELECT dep.dept_name, COUNT(DISTINCT a.patient_id) AS patients
FROM Departments dep
JOIN Doctors d       ON d.dept_id = dep.dept_id
JOIN Appointments a  ON a.doctor_id = d.doctor_id
GROUP BY dep.dept_id, dep.dept_name
ORDER BY patients DESC;

-- A7. ANALYTICS: Monthly revenue (payments received)
SELECT DATE_FORMAT(payment_date,'%Y-%m') AS month,
       SUM(amount_paid) AS revenue
FROM Payments
GROUP BY DATE_FORMAT(payment_date,'%Y-%m')
ORDER BY month;

-- A8. ANALYTICS: Most prescribed medicines
SELECT m.medicine_name, COUNT(*) AS times_prescribed, SUM(pi.quantity) AS total_units
FROM Prescription_Items pi
JOIN Medicines m ON m.medicine_id = pi.medicine_id
GROUP BY m.medicine_id, m.medicine_name
ORDER BY times_prescribed DESC, total_units DESC
LIMIT 5;

-- A9. Doctors with at least 3 completed consultations (HAVING)
SELECT doctor_id, COUNT(*) AS consultations
FROM Appointments
WHERE status = 'Completed'
GROUP BY doctor_id
HAVING COUNT(*) >= 3;

-- A10. Revenue per department (payments -> bills -> appointments -> doctors -> departments)
SELECT dep.dept_name, SUM(py.amount_paid) AS revenue
FROM Payments py
JOIN Bills b         ON b.bill_id = py.bill_id
JOIN Appointments a  ON a.appointment_id = b.appointment_id
JOIN Doctors d       ON d.doctor_id = a.doctor_id
JOIN Departments dep ON dep.dept_id = d.dept_id
GROUP BY dep.dept_name
HAVING SUM(py.amount_paid) > 1000
ORDER BY revenue DESC;
