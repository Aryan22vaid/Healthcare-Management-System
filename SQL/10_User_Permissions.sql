-- =====================================================
-- File   : 10_User_Permissions.sql
-- Purpose: DCL - CREATE USER, GRANT, REVOKE (MySQL 8.0)
-- Run as : root / an account with CREATE USER and GRANT privileges
-- =====================================================
USE medicare_db;

-- Clean start
DROP USER IF EXISTS 'receptionist'@'localhost';
DROP USER IF EXISTS 'doctor_user'@'localhost';
DROP USER IF EXISTS 'admin_user'@'localhost';

-- 1. Create users (demo passwords only)
CREATE USER 'receptionist'@'localhost' IDENTIFIED BY 'Recep@123';
CREATE USER 'doctor_user'@'localhost'  IDENTIFIED BY 'Doctor@123';
CREATE USER 'admin_user'@'localhost'   IDENTIFIED BY 'Admin@123';

-- 2. GRANT privileges
-- Receptionist: register patients and book appointments only
GRANT SELECT, INSERT, UPDATE ON medicare_db.Patients     TO 'receptionist'@'localhost';
GRANT SELECT, INSERT, UPDATE ON medicare_db.Appointments TO 'receptionist'@'localhost';
GRANT SELECT ON medicare_db.Doctors TO 'receptionist'@'localhost';

-- Doctor: read patients, write medical records and prescriptions
GRANT SELECT ON medicare_db.Patients  TO 'doctor_user'@'localhost';
GRANT SELECT ON medicare_db.Appointments TO 'doctor_user'@'localhost';
GRANT SELECT, INSERT, UPDATE ON medicare_db.Medical_Records     TO 'doctor_user'@'localhost';
GRANT SELECT, INSERT, UPDATE ON medicare_db.Prescriptions       TO 'doctor_user'@'localhost';
GRANT SELECT, INSERT, UPDATE ON medicare_db.Prescription_Items  TO 'doctor_user'@'localhost';
GRANT SELECT ON medicare_db.Medicines TO 'doctor_user'@'localhost';

-- Administrator: full control of this database
GRANT ALL PRIVILEGES ON medicare_db.* TO 'admin_user'@'localhost';

FLUSH PRIVILEGES;

-- 3. Check what was granted
SHOW GRANTS FOR 'receptionist'@'localhost';
SHOW GRANTS FOR 'doctor_user'@'localhost';
SHOW GRANTS FOR 'admin_user'@'localhost';

-- 4. REVOKE a privilege
REVOKE UPDATE ON medicare_db.Patients FROM 'receptionist'@'localhost';
SHOW GRANTS FOR 'receptionist'@'localhost';

-- 5. Remove the demo users
DROP USER 'receptionist'@'localhost';
DROP USER 'doctor_user'@'localhost';
DROP USER 'admin_user'@'localhost';
