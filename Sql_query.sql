/* ================================
   1. CREATE DATABASE
================================ */
CREATE DATABASE TokyoOlympics;
GO

USE TokyoOlympics;
GO

/* ================================
   2. CREATE MASTER KEY
================================ */
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword@123';
GO

/* ================================
   3. CREATE CREDENTIAL (ADLS Gen2)
================================ */
CREATE DATABASE SCOPED CREDENTIAL AzureStorageCredential
WITH
(
    IDENTITY = 'SHARED ACCESS SIGNATURE',
    SECRET = 'sv=2022-11-02&ss=bfqt&srt=sco&sp=rl&se=2026-01-01T00:00:00Z&st=2024-01-01T00:00:00Z&spr=https&sig=XXXX'
);
GO

/* ================================
   4. CREATE EXTERNAL DATA SOURCE
================================ */
CREATE EXTERNAL DATA SOURCE TokyoOlympicsData
WITH (
    LOCATION = 'https://<storageaccount>.dfs.core.windows.net/<container>',
    CREDENTIAL = AzureStorageCredential
);
GO

/* ================================
   5. CREATE FILE FORMAT (PARQUET)
================================ */
CREATE EXTERNAL FILE FORMAT SynapseParquetFormat
WITH (
    FORMAT_TYPE = PARQUET
);
GO

/* ================================
   6. CREATE EXTERNAL TABLES
================================ */

/* ---- Athletes ---- */
CREATE EXTERNAL TABLE athletes
(
    athlete_id INT,
    name VARCHAR(100),
    country VARCHAR(50),
    discipline VARCHAR(100)
)
WITH (
    LOCATION = '/curated/athletes/',
    DATA_SOURCE = TokyoOlympicsData,
    FILE_FORMAT = SynapseParquetFormat
);
GO

/* ---- Events ---- */
CREATE EXTERNAL TABLE events
(
    event_id INT,
    event_name VARCHAR(100),
    sport VARCHAR(50),
    event_date DATE
)
WITH (
    LOCATION = '/curated/events/',
    DATA_SOURCE = TokyoOlympicsData,
    FILE_FORMAT = SynapseParquetFormat
);
GO

/* ---- Medals ---- */
CREATE EXTERNAL TABLE medals
(
    country VARCHAR(50),
    gold INT,
    silver INT,
    bronze INT,
    total INT
)
WITH (
    LOCATION = '/curated/medals/',
    DATA_SOURCE = TokyoOlympicsData,
    FILE_FORMAT = SynapseParquetFormat
);
GO

/* ================================
   7. ANALYTICAL QUERIES
================================ */

/* Total medals by country */
SELECT 
    country,
    SUM(gold)   AS gold,
    SUM(silver) AS silver,
    SUM(bronze) AS bronze,
    SUM(total)  AS total_medals
FROM medals
GROUP BY country
ORDER BY total_medals DESC;
GO

/* Top 10 countries by gold medals */
SELECT TOP 10
    country,
    gold
FROM medals
ORDER BY gold DESC;
GO

/* Athletes count by country */
SELECT
    country,
    COUNT(*) AS athlete_count
FROM athletes
GROUP BY country
ORDER BY athlete_count DESC;
GO

/* Events per sport */
SELECT
    sport,
    COUNT(*) AS total_events
FROM events
GROUP BY sport
ORDER BY total_events DESC;
GO

/* Athletes per discipline */
SELECT
    discipline,
    COUNT(*) AS athlete_count
FROM athletes
GROUP BY discipline
ORDER BY athlete_count DESC;
GO

/* ================================
   8. VIEWS FOR POWER BI
================================ */

/* Medal summary view */
CREATE VIEW vw_medal_summary AS
SELECT 
    country,
    SUM(gold)   AS gold,
    SUM(silver) AS silver,
    SUM(bronze) AS bronze,
    SUM(total)  AS total_medals
FROM medals
GROUP BY country;
GO

/* Athlete distribution view */
CREATE VIEW vw_athlete_distribution AS
SELECT
    country,
    discipline,
    COUNT(*) AS athlete_count
FROM athletes
GROUP BY country, discipline;
GO

/* Events summary view */
CREATE VIEW vw_events_summary AS
SELECT
    sport,
    COUNT(*) AS total_events
FROM events
GROUP BY sport;
GO
