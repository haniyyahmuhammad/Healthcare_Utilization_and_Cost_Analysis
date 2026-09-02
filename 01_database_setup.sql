-- ============================================
-- Healthcare Utilization & Cost Analysis
-- Database Setup
-- ============================================

-- Patients table
CREATE TABLE patients (
    id VARCHAR(50) PRIMARY KEY,
    birthdate DATE,
    deathdate DATE,
    marital VARCHAR(10),
    race VARCHAR(100),
    ethnicity VARCHAR(100),
    gender VARCHAR(20),
    birthplace VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    county VARCHAR(100),
    zip VARCHAR(20),
    lat DECIMAL(10,6),
    lon DECIMAL(10,6),
    healthcare_expenses DECIMAL(15,2),
    healthcare_coverage DECIMAL(15,2),
    income DECIMAL(15,2)
);

-- Raw patients staging table
CREATE TABLE patients_raw (
    id VARCHAR(50),
    birthdate DATE,
    deathdate DATE,
    ssn VARCHAR(20),
    drivers VARCHAR(50),
    passport VARCHAR(50),
    prefix VARCHAR(20),
    first_name VARCHAR(100),
    middle VARCHAR(100),
    last_name VARCHAR(100),
    suffix VARCHAR(20),
    maiden VARCHAR(100),
    marital VARCHAR(10),
    race VARCHAR(100),
    ethnicity VARCHAR(100),
    gender VARCHAR(20),
    birthplace VARCHAR(200),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    county VARCHAR(100),
    fips VARCHAR(20),
    zip VARCHAR(20),
    lat DECIMAL(10,6),
    lon DECIMAL(10,6),
    healthcare_expenses DECIMAL(15,2),
    healthcare_coverage DECIMAL(15,2),
    income DECIMAL(15,2)
);

-- Encounters table
CREATE TABLE encounters (
    id VARCHAR(50) PRIMARY KEY,
    start_time TIMESTAMP,
    stop_time TIMESTAMP,
    patient VARCHAR(50),
    organization VARCHAR(50),
    provider VARCHAR(50),
    payer VARCHAR(50),
    encounterclass VARCHAR(50),
    code VARCHAR(50),
    description TEXT,
    base_encounter_cost DECIMAL(15,2),
    total_claim_cost DECIMAL(15,2),
    payer_coverage DECIMAL(15,2),
    reasoncode VARCHAR(50),
    reasondescription TEXT,
    FOREIGN KEY (patient) REFERENCES patients(id)
);

-- Raw encounters staging table
CREATE TABLE encounters_raw (
    id VARCHAR(50),
    start_time TIMESTAMP,
    stop_time TIMESTAMP,
    patient VARCHAR(50),
    organization VARCHAR(50),
    provider VARCHAR(50),
    payer VARCHAR(50),
    encounterclass VARCHAR(50),
    code VARCHAR(50),
    description TEXT,
    base_encounter_cost DECIMAL(15,2),
    total_claim_cost DECIMAL(15,2),
    payer_coverage DECIMAL(15,2),
    reasoncode VARCHAR(50),
    reasondescription TEXT
);
