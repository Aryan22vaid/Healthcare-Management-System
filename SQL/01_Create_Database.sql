-- =====================================================
-- MediCare - Healthcare Management System
-- File   : 01_Create_Database.sql
-- Purpose: Create (and reset) the database   [DDL]
-- Run    : MySQL Server 8.0.16+ / MySQL Workbench 8.0+
-- =====================================================

DROP DATABASE IF EXISTS medicare_db;
CREATE DATABASE medicare_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE medicare_db;
