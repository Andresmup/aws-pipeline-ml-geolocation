--Preview
SELECT * FROM "geolocation_database_quality_test"."table-geolocation-glue-quality-test" limit 10;

--Number of items in total
SELECT COUNT(timestamp) AS num_rows FROM "geolocation_database_quality_test"."table-geolocation-glue-quality-test";

--Most recent item
SELECT *
FROM "geolocation_database_quality_test"."table-geolocation-glue-quality-test"
ORDER BY timestamp DESC
LIMIT 1;

--Items per day
SELECT DATE(timestamp) AS fecha, COUNT(*) AS cantidad
FROM "geolocation_database_quality_test"."table-geolocation-glue-quality-test"
GROUP BY DATE(timestamp);

-- Items per month
SELECT 
    YEAR(timestamp) AS year, 
    MONTH(timestamp) AS month, 
    COUNT(*) AS cantidad
FROM "geolocation_database_quality_test"."table-geolocation-glue-quality-test"
GROUP BY YEAR(timestamp), MONTH(timestamp)
ORDER BY year, month;

--Point in south
SELECT * 
FROM "geolocation_database_quality_test"."table-geolocation-glue-quality-test"
ORDER BY longitude DESC
LIMIT 1;

--Point in the west
SELECT * 
FROM "geolocation_database_quality_test"."table-geolocation-glue-quality-test"
ORDER BY longitude ASC
LIMIT 1;

--Number of items in mexico
SELECT COUNT(timestamp) AS num_rows 
FROM "geolocation_database_quality_test"."table-geolocation-glue-quality-test"
WHERE 
    latitude BETWEEN 14 AND 32
    AND longitude BETWEEN 86 AND 118;