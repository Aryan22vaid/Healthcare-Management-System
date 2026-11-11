-- =====================================================
-- File   : 09_Transactions.sql
-- Purpose: TCL - START TRANSACTION, COMMIT, ROLLBACK, SAVEPOINT
--          + stored procedure for safe appointment booking
-- Run    : After scripts 01-08, using an account with table privileges
-- =====================================================
USE medicare_db;

-- T1. COMMIT: book a clearly identified demonstration appointment
-- Delete only this script's own test row, and only when no bill references it.
START TRANSACTION;
DELETE FROM Appointments
WHERE patient_id = 7
  AND doctor_id = 6
  AND appointment_date = '2026-11-20'
  AND appointment_time = '10:00:00'
  AND reason = 'MediCare TCL commit demo'
  AND appointment_id NOT IN (SELECT appointment_id FROM Bills);

INSERT INTO Appointments
    (patient_id, doctor_id, appointment_date, appointment_time, status, reason)
VALUES
    (7, 6, '2026-11-20', '10:00:00', 'Scheduled', 'MediCare TCL commit demo');

SELECT appointment_id, status
FROM Appointments
WHERE patient_id = 7
  AND doctor_id = 6
  AND appointment_date = '2026-11-20'
  AND appointment_time = '10:00:00'
  AND reason = 'MediCare TCL commit demo';
COMMIT;

-- T2. ROLLBACK: a temporary payment is inserted and then undone.
-- The amount is deliberately small and does not exceed bill 9's sample total.
START TRANSACTION;
INSERT INTO Payments (bill_id, payment_date, amount_paid, method)
VALUES (9, '2026-11-01', 50.00, 'Cash');

SELECT COUNT(*) AS payments_inside_transaction FROM Payments;
ROLLBACK;
SELECT COUNT(*) AS payments_after_rollback FROM Payments;

-- T3. SAVEPOINT: undo only part of a transaction, then restore the original fee.
SET @doctor7_original_fee = (
    SELECT consultation_fee FROM Doctors WHERE doctor_id = 7
);

START TRANSACTION;
UPDATE Doctors SET consultation_fee = 850 WHERE doctor_id = 7;
SAVEPOINT after_fee_update;

UPDATE Doctors SET consultation_fee = 1 WHERE doctor_id = 8; -- intentional wrong update
ROLLBACK TO SAVEPOINT after_fee_update;                     -- undo only doctor 8's update
COMMIT;

SELECT doctor_id, consultation_fee
FROM Doctors
WHERE doctor_id IN (7, 8)
ORDER BY doctor_id;

-- Restore the original value so later query demonstrations remain unchanged.
UPDATE Doctors
SET consultation_fee = @doctor7_original_fee
WHERE doctor_id = 7;
SET @doctor7_original_fee = NULL;

-- -----------------------------------------------------
-- Stored procedure: book only if a doctor's slot is free.
-- The UNIQUE key on (doctor_id, date, time, active_status) is the
-- final safeguard if two sessions attempt the same slot concurrently.
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS sp_book_appointment;
DELIMITER $$
CREATE PROCEDURE sp_book_appointment(
    IN p_patient INT,
    IN p_doctor INT,
    IN p_date DATE,
    IN p_time TIME,
    IN p_reason VARCHAR(150)
)
BEGIN
    DECLARE v_busy INT DEFAULT 0;

    -- A duplicate-key error can still occur if another session books the slot
    -- after the availability check. Handle that specific race safely.
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SELECT 'Slot became unavailable; booking was not created.' AS result;
    END;

    -- Roll back and surface other unexpected errors rather than hiding them.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*) INTO v_busy
    FROM Appointments
    WHERE doctor_id = p_doctor
      AND appointment_date = p_date
      AND appointment_time = p_time
      AND status <> 'Cancelled';

    IF v_busy > 0 THEN
        SELECT 'Doctor not available at this time' AS result;
    ELSE
        START TRANSACTION;
        INSERT INTO Appointments
            (patient_id, doctor_id, appointment_date, appointment_time, reason)
        VALUES
            (p_patient, p_doctor, p_date, p_time, p_reason);
        COMMIT;
        SELECT 'Appointment booked successfully' AS result;
    END IF;
END$$
DELIMITER ;

-- Clean up only the exact records created by this procedure demonstration.
-- Rows with a bill are deliberately preserved.
DELETE FROM Appointments
WHERE doctor_id = 4
  AND appointment_date = '2026-11-25'
  AND appointment_time = '09:30:00'
  AND (
        (patient_id = 3 AND reason = 'MediCare availability demo - original')
        OR
        (patient_id = 5 AND reason = 'MediCare availability demo - rebooked')
      )
  AND appointment_id NOT IN (SELECT appointment_id FROM Bills);

-- First booking succeeds; the second attempt at the occupied slot is rejected.
CALL sp_book_appointment(3, 4, '2026-11-25', '09:30:00',
                         'MediCare availability demo - original');
CALL sp_book_appointment(5, 4, '2026-11-25', '09:30:00',
                         'MediCare availability demo - rebooked');

-- Cancel the first booking. Its generated active_status becomes NULL,
-- so a different patient can now reserve the same doctor/time slot.
UPDATE Appointments
SET status = 'Cancelled'
WHERE patient_id = 3
  AND doctor_id = 4
  AND appointment_date = '2026-11-25'
  AND appointment_time = '09:30:00'
  AND reason = 'MediCare availability demo - original';

CALL sp_book_appointment(5, 4, '2026-11-25', '09:30:00',
                         'MediCare availability demo - rebooked');

SELECT appointment_id, patient_id, doctor_id, appointment_date,
       appointment_time, status, active_status
FROM Appointments
WHERE doctor_id = 4
  AND appointment_date = '2026-11-25'
  AND appointment_time = '09:30:00'
  AND reason IN (
      'MediCare availability demo - original',
      'MediCare availability demo - rebooked'
  )
ORDER BY appointment_id;

-- -----------------------------------------------------
-- Payment-status reconciliation and validation
-- This UPDATE is an explicit reconciliation step; it is not an automatic
-- trigger fired by every future INSERT into Payments.
-- -----------------------------------------------------
UPDATE Bills AS b
SET payment_status = CASE
    WHEN (SELECT COALESCE(SUM(p.amount_paid), 0)
          FROM Payments AS p WHERE p.bill_id = b.bill_id) >= b.total_amount
        THEN 'Paid'
    WHEN (SELECT COALESCE(SUM(p.amount_paid), 0)
          FROM Payments AS p WHERE p.bill_id = b.bill_id) > 0
        THEN 'Partial'
    ELSE 'Unpaid'
END;

-- Every returned row should show consistency_check = 'Consistent'.
SELECT b.bill_id,
       b.total_amount,
       b.payment_status AS stored_status,
       COALESCE(SUM(p.amount_paid), 0) AS total_paid,
       CASE
           WHEN COALESCE(SUM(p.amount_paid), 0) >= b.total_amount THEN 'Paid'
           WHEN COALESCE(SUM(p.amount_paid), 0) > 0 THEN 'Partial'
           ELSE 'Unpaid'
       END AS calculated_status,
       IF(
           b.payment_status = CASE
               WHEN COALESCE(SUM(p.amount_paid), 0) >= b.total_amount THEN 'Paid'
               WHEN COALESCE(SUM(p.amount_paid), 0) > 0 THEN 'Partial'
               ELSE 'Unpaid'
           END,
           'Consistent', 'Inconsistent'
       ) AS consistency_check
FROM Bills AS b
LEFT JOIN Payments AS p ON p.bill_id = b.bill_id
GROUP BY b.bill_id, b.total_amount, b.payment_status
ORDER BY b.bill_id;
