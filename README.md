# MediCare - Healthcare Management System

A MySQL DBMS project modelling the core workflow of a small healthcare facility:

**patient registration -> appointment booking -> diagnosis -> prescription -> billing -> payment -> reporting**

## Project overview

MediCare is an academic database prototype. It contains ten relational tables, primary and foreign keys, unique and check constraints, a generated column for appointment-slot management, a stored procedure, and SQL demonstrations covering DDL, DML, DQL, TCL and DCL.

All sample patients, doctors, contact details and transactions are fictional. Do not use this project to store real patient data.

## Requirements

| Component | Minimum version |
|---|---|
| MySQL Server | **8.0.16 or later** |
| MySQL Workbench | 8.0 or later |
| Operating system | Windows, Linux or macOS |

MySQL 8.0.16 is specified because this project relies on enforced `CHECK` constraints. The schema also uses a stored generated column.

## Folder structure

```text
Healthcare-Management-System/
├── README.md
├── SQL/                         # Numbered, executable MySQL scripts
├── Documentation/
│   ├── Project_Report.docx
│   ├── Project_Report.pdf
│   ├── ER_Diagram.png
│   ├── ER_Diagram.dot
│   ├── ER_Diagram.svg
│   ├── Relational_Schema.png
│   ├── Relational_Schema.svg
│   └── Screenshots/             # Add genuine MySQL Workbench captures here
├── References/
│   └── Research_Sources.md
└── Application/
    └── README.md                # Optional Java/JDBC extension
```

## Database tables

`Departments`, `Doctors`, `Patients`, `Appointments`, `Medical_Records`, `Medicines`, `Prescriptions`, `Prescription_Items`, `Bills`, and `Payments`.

See [the ER diagram](Documentation/ER_Diagram.png) and [the relational schema](Documentation/Relational_Schema.png).

## How to run the project

1. Install MySQL Server 8.0.16 or later and MySQL Workbench.
2. Open MySQL Workbench and connect using an account with permission to create databases, tables and users (typically a local administrator account).
3. Open each SQL file from the `SQL/` folder and execute them **in numerical order, from 01 to 10**.
4. Check the result grid and Action Output after each script. Resolve any error before moving to the next file.

| Order | Script | Category | Purpose |
|---:|---|---|---|
| 01 | `01_Create_Database.sql` | DDL | Creates/resets `medicare_db` |
| 02 | `02_Create_Tables.sql` | DDL | Creates ten tables and their keys/constraints |
| 03 | `03_Constraints.sql` | DDL | Demonstrates ALTER, indexes, temporary table and view |
| 04 | `04_Insert_Data.sql` | DML | Inserts fictional sample records |
| 05 | `05_Basic_Queries.sql` | DQL/DML | Filtering, sorting, DISTINCT, INSERT, UPDATE and DELETE |
| 06 | `06_Joins.sql` | DQL | INNER, LEFT and SELF JOIN demonstrations |
| 07 | `07_Subqueries.sql` | DQL | Scalar, IN, NOT IN and correlated subqueries |
| 08 | `08_Aggregate_Functions.sql` | DQL | Aggregates, GROUP BY, HAVING and analytics |
| 09 | `09_Transactions.sql` | TCL + stored procedure | COMMIT, ROLLBACK, SAVEPOINT, appointment booking and payment reconciliation |
| 10 | `10_User_Permissions.sql` | DCL | Creates demo users, grants/revokes privileges, displays grants, then removes demo users |

### Important reset warning

`01_Create_Database.sql` contains `DROP DATABASE IF EXISTS medicare_db`. Running it deletes and recreates the project database, including all data. Run it only when you intend to reset the project from scratch. Scripts 02-04 are setup scripts and should be run once after a reset; do not rerun them over an existing populated database.

Scripts 05-10 are intended as demonstrations after setup. Script 09 cleans up only its clearly labelled test appointments; it preserves a test appointment if a bill references it. Script 10 creates demo users and removes them at the end.

## Main features

- **Appointment-slot protection:** a generated `active_status` column is `NULL` for cancelled appointments and `Active` otherwise. A UNIQUE key on doctor, date, time and generated status prevents two active appointments from occupying the same slot while allowing a cancelled slot to be reused.
- **Patient history:** a multi-table query uses LEFT JOIN for optional diagnoses and prescriptions, so appointments remain visible even when a later clinical record has not been entered.
- **Stored procedure:** `sp_book_appointment` checks availability and books a slot; the UNIQUE key remains the final protection against simultaneous booking attempts.
- **Billing reconciliation:** script 09 recalculates each bill's `payment_status` from recorded payment rows and runs a consistency query. This is an explicit reconciliation step, not an automatic trigger on every payment insert.
- **Hospital analytics:** busiest doctors, department-wise patient counts, monthly collected revenue and frequently prescribed medicines.

## Validation checklist

After running the scripts, verify:

- `SHOW TABLES;` returns ten tables.
- The sample-data script inserts the expected departments, doctors, patients, appointments, medicines, records, prescriptions, bills and payments.
- Query J4 returns the patient's appointment history and preserves rows with missing optional medical records/prescriptions.
- An active duplicate doctor/date/time slot is rejected.
- A cancelled appointment does not block a new appointment for the same doctor/date/time.
- The stored procedure reports an occupied slot as unavailable and permits rebooking after cancellation.
- Script 09's payment consistency output shows `Consistent` for every bill.
- Script 10 displays the GRANT/REVOKE results. The demo accounts are removed at the end of the script.



## Optional application

A Java + JDBC front end is a future extension, not required to run the SQL database project. See `Application/README.md`.

## References and GitHub publishing

See [References/Research_Sources.md](References/Research_Sources.md). For first-time repository publication, follow [GITHUB_UPLOAD_GUIDE.md](GITHUB_UPLOAD_GUIDE.md).
