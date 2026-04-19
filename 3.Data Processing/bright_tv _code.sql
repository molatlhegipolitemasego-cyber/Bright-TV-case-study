---1.Viewing the entire viewership dataset (Base table)
SELECT *
FROM `consultation-class`.default.viewership
LIMIT 20;
----------------------------------------------
--1.1 Checking the column structure
DESCRIBE `consultation-class`.default.viewership;
-----------------------------------------------
--1.2 basic data overview
--there are 10000 total views, 4386 total users and 21 total channels
SELECT
     COUNT(*) AS total_views,
     COUNT(DISTINCT UserID0) AS total_users,
     COUNT(DISTINCT Channel2) AS total_channels
FROM `consultation-class`.default.viewership;
------------------------------------------
---2.Data cleaning
--2.1 Checking for NULLS (no rows returned)
SELECT *
FROM `consultation-class`.default.viewership
WHERE UserID0 IS NULL
  AND Channel2 IS NULL
  AND RecordDate2 IS NULL;
  --2.2 Check empty spaces(no rows returned)
  SELECT *
  FROM `consultation-class`.default.viewership
  WHERE TRIM(UserID0) = ''
  OR TRIM(Channel2) = ''
  OR TRIM(RecordDate2) = '';
  ----------------------------------------------
  --2.3 Check for duplicates
  --rows returned hence there are duplicates in the dataset
  SELECT
        UserID0,
        Channel2,
        RecordDate2,
        `Duration 2`,
        COUNT(*) AS duplicate_count
FROM `consultation-class`.default.viewership
GROUP BY
         UserID0,
        Channel2,
        RecordDate2,
        `Duration 2`;
---remove duplicates
SELECT DISTINCT *
FROM `consultation-class`.default.viewership;
---------------------------------------------
--2.4 Standardize text
SELECT 
      TRIM(LOWER(UserID0)) AS user_id,
      TRIM(LOWER(Channel2)) AS channel,
      RecordDate2,
      `Duration 2`
FROM `consultation-class`.default.viewership;
-----------------------------------------------------
---3.TIME CONVERSION(UTC TO SA)
SELECT 
    from_utc_timestamp(RecordDate2,'Africa/Johannesburg') AS sa_timestamp
FROM `consultation-class`.default.viewership;  
--3.1 Separate date and time
SELECT 
    from_utc_timestamp(RecordDate2,'Africa/Johannesburg') AS sa_timestamp,

    DATE(from_utc_timestamp(RecordDate2,'Africa/Johannesburg')) AS view_date,

    HOUR(from_utc_timestamp(RecordDate2,'Africa/Johannesburg')) AS hour_of_day
FROM `consultation-class`.default.viewership;
-----------------------------------------
--3.2 data time range
--Start date: 2016-01-01, end date:2016-01-01
SELECT
       MIN(DATE(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'))) AS start_date,
       MAX(DATE(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'))) AS end_date
 FROM `consultation-class`.default.viewership;
--------------------------------------------
---4. session minutes
--avg_session_time:9.1380050013	total_watch_time:91380.050013
SELECT
    AVG(
       (hour (`Duration 2`) * 60)+ minute(`Duration 2`) + (second(`Duration 2`) / 60.0)) AS avg_session_time,
       SUM(
(hour (`Duration 2`) * 60) + minute(`Duration 2`) + (second(`Duration 2`) / 60.0)) AS total_watch_time
FROM `consultation-class`.default.viewership;
---------------------------------------------------------------
---5.DAY NAME & WEEK STRUCTURE
--Fridays has the most totalviews(1675 views)
SELECT 
         day_name,
         day_type,
         COUNT(*) AS total_views   
         FROM (
            SELECT
            DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'), 'EEEE') AS day_name,
                CASE
                   WHEN 
            DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'), 'EEEE') IN('Saturday','Sunday') 
            THEN'Weekend'
            ELSE 'Weekday'
        END AS day_type
FROM `consultation-class`.default.viewership
         )t
GROUP BY day_name,day_type
ORDER BY total_views DESC;
---------------------------------------------------------------
---6. MONTH NAME ANALYSIS
---March has the most views(4816)
SELECT 
         month_name,
         COUNT(*) AS total_views   
         FROM (
            SELECT
            DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'), 'MMMM') AS month_name
FROM `consultation-class`.default.viewership
         ) t
GROUP BY month_name
ORDER BY total_views DESC;
----------------------------------------------------
--- 7. PEAK VIEWING HOURS
--hour of day 17-648 views
SELECT 
    hour_of_day,
    COUNT(*) AS total_views
FROM (
    SELECT 
        HOUR(from_utc_timestamp(RecordDate2,'Africa/Johannesburg')) AS hour_of_day
    FROM `consultation-class`.default.viewership
) t
GROUP BY hour_of_day
ORDER BY total_views DESC;
------------------------------------------
---8. MOST VIEWED CHANNELS
--Supersport Live Events has 1638 views(mostly viewed)
SELECT 
    Channel2,
    COUNT(*) AS total_views
FROM `consultation-class`.default.viewership
GROUP BY Channel2
ORDER BY total_views DESC;
--------------------------------------------
---9. TIME BUCKET ANALYSIS
--Evening Peak	3172, Afternoon:2459,Morning:2455, Night:1914
SELECT 
    time_bucket,
    COUNT(*) AS total_views
FROM (
    SELECT 
        CASE 
            WHEN date_format(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
                 BETWEEN '05:00:00' AND '11:59:59'
            THEN 'Morning'

            WHEN date_format(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
                 BETWEEN '12:00:00' AND '15:59:59'
            THEN 'Afternoon'

            WHEN date_format(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
                 BETWEEN '16:00:00' AND '20:59:59'
            THEN 'Evening Peak'

            ELSE 'Night'
        END AS time_bucket
 FROM `consultation-class`.default.viewership
) t

GROUP BY time_bucket
ORDER BY total_views DESC;
----------------------------------------------------------------------------
---10.HIGH VS LOW ENGAGEMENT USERS

SELECT 
    UserID0,
 SUM(session_minutes) AS total_watch_time,
     CASE 
        WHEN SUM(session_minutes) < 30 THEN 'Low'
        WHEN SUM(session_minutes) BETWEEN 30 AND 120 THEN 'Medium'
        ELSE 'High'
    END AS engagement_level

FROM (
    SELECT 
        UserID0,

        (HOUR(`Duration 2`) * 60) +
        MINUTE(`Duration 2`) +
        (SECOND(`Duration 2`) / 60.0) AS session_minutes
FROM `consultation-class`.default.viewership
) t
GROUP BY UserID0;
--------------------------------------------------------

---11.viewing the user profile dataset
SELECT *
FROM `consultation-class`.default.user_profiles
LIMIT 20;
----------------------------------------------
---12. Check for NULLS, BLANKS,"NONE"
--Total rows=5375, age missing=0,gender missing=218, province missing=218
SELECT 
    COUNT(*) AS total_rows,
    COUNT(CASE WHEN Age IS NULL OR TRIM(Age) = '' OR LOWER(Age) = 'None' THEN 1 END) AS age_missing,
    COUNT(CASE WHEN Gender IS NULL OR TRIM(Gender) = '' OR LOWER(Gender) = 'None' THEN 1 END) AS gender_missing,
    COUNT(CASE WHEN Province IS NULL OR TRIM(Province) = '' OR LOWER(Province) = 'None' THEN 1 END) AS province_missing
FROM `consultation-class`.default.user_profiles;
----------------------------------------------
--13. Check for duplicates
--no rows returned
SELECT UserID, COUNT(*) AS count
FROM `consultation-class`.default.user_profiles
GROUP BY UserID
HAVING COUNT(*) > 1;
--------------------------------------------------------------
--14. exploring raw data
--Age values
SELECT DISTINCT Age
FROM `consultation-class`.default.user_profiles
ORDER BY Age;
--Gender values
--we have male, female and none
SELECT DISTINCT Gender
FROM `consultation-class`.default.user_profiles;
--------------------------------------
--15.Province values
--we have 9 provinces Province namely: Free State, Eastern Cape, Kwazulu Natal, Gauteng, Western Cape, North West, Limpopo, Mpumalanga and Northern Cape and a None
SELECT DISTINCT Province
FROM `consultation-class`.default.user_profiles;
--------------------------------------------------------
--- 16.EDA and data cleaning
CREATE OR REPLACE TEMP VIEW cleaned_user_profile AS
SELECT 
    UserID,

    --16.1 AGE
    CASE 
        WHEN Age IS NULL 
             OR TRIM(Age) = '' 
             OR LOWER(Age) IN ('None', 'na', 'n/a', 'unknown')
             OR NOT TRIM(Age) RLIKE '^[0-9]+$'
        THEN NULL
        ELSE INT(TRIM(Age))
    END AS age,

    --16.2 AGE CATEGORY (BUSINESS-FRIENDLY)
    CASE 
        WHEN INT(TRIM(Age)) BETWEEN 18 AND 24 THEN 'Youth'
        WHEN INT(TRIM(Age)) BETWEEN 25 AND 34 THEN 'Young Adults'
        WHEN INT(TRIM(Age)) BETWEEN 35 AND 54 THEN 'Adults'
        WHEN INT(TRIM(Age)) >= 55 THEN 'Seniors'
        WHEN Age IS NULL 
             OR TRIM(Age) = '' 
             OR LOWER(Age) IN ('None', 'na', 'n/a', 'unknown')
             OR NOT TRIM(Age) RLIKE '^[0-9]+$'
        THEN 'Not Disclosed'
        ELSE 'Other'
    END AS age_category,

    -- 16.3 GENDER
    CASE 
        WHEN Gender IS NULL OR TRIM(Gender) = '' OR LOWER(Gender) = 'None'
        THEN 'Not Disclosed'
        WHEN LOWER(Gender) IN ('male', 'm')
        THEN 'Male'
        WHEN LOWER(Gender) IN ('female', 'f')
        THEN 'Female'
        ELSE 'Other'
    END AS gender,

    -- 16.4 PROVINCE
    CASE 
        WHEN Province IS NULL OR TRIM(Province) = '' OR LOWER(Province) = 'None'
        THEN 'Not Disclosed'
        ELSE INITCAP(TRIM(Province))
    END AS province,

    -- 16.5 RACE
    CASE 
        WHEN Race IS NULL OR TRIM(Race) = '' OR LOWER(Race) = 'None'
        THEN 'Not Disclosed'
        ELSE INITCAP(TRIM(Race))
    END AS race

FROM `consultation-class`.default.user_profiles;
--------------------------------------------------------------
--17 Quick preview
SELECT *
FROM cleaned_user_profile
LIMIT 20;
---------------------------------------------------------------
--18 missing values
SELECT 
    COUNT(*) AS total_users,

    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS age_missing,
    SUM(CASE WHEN gender = 'Not Disclosed' THEN 1 ELSE 0 END) AS gender_missing,
    SUM(CASE WHEN province = 'Not Disclosed' THEN 1 ELSE 0 END) AS province_missing,
    SUM(CASE WHEN race = 'Not Disclosed' THEN 1 ELSE 0 END) AS race_missing
FROM cleaned_user_profile;
------------------------------------------------------------------------
---19. race distribution
--Black people are the most users (1811)
SELECT race, COUNT(*) AS users
FROM cleaned_user_profile
GROUP BY race
ORDER BY users DESC;
-----------------------------------------------------------------------
--20.gender distribution
--males are main users(3918)
SELECT gender, COUNT(*) AS users
FROM cleaned_user_profile
GROUP BY gender
ORDER BY users DESC;
-----------------------------------------------------------------
---21.province distribution
--People in Gauteng are the main users
SELECT province, COUNT(*) AS users
FROM cleaned_user_profile
GROUP BY province
ORDER BY users DESC;
-------------------------------------------------------
---22. Age Category
--Young adults are the most users(1894)
SELECT age_category, COUNT(*) AS users
FROM cleaned_user_profile
GROUP BY age_category
ORDER BY users DESC;
------------------------------------------------------------------------
---BIG QUERY
SELECT 

    -- =========================
    -- BASE COLUMNS
    -- =========================
    TRIM(LOWER(v.UserID0)) AS user_id,
    TRIM(LOWER(v.Channel2)) AS channel,

    -- =========================
    -- TIME ANALYSIS
    -- =========================
    from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg') AS sa_timestamp,

    DATE(from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg')) AS view_date,

    HOUR(from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg')) AS hour_of_day,

    -- DAY NAME
    DATE_FORMAT(from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg'),'EEEE') AS day_name,

    -- WEEK STRUCTURE
    CASE 
        WHEN DATE_FORMAT(from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg'),'EEEE') 
             IN ('Saturday','Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,

    -- MONTH NAME
    DATE_FORMAT(from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg'),'MMMM') AS month_name,

    -- TIME BUCKET
    CASE 
        WHEN date_format(from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
             BETWEEN '05:00:00' AND '11:59:59'
        THEN 'Morning'

        WHEN date_format(from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
             BETWEEN '12:00:00' AND '15:59:59'
        THEN 'Afternoon'

        WHEN date_format(from_utc_timestamp(v.RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
             BETWEEN '16:00:00' AND '20:59:59'
        THEN 'Evening Peak'

        ELSE 'Night'
    END AS time_bucket,

    -- =========================
    -- SESSION ANALYSIS
    -- =========================
    (HOUR(v.`Duration 2`) * 60) +
    MINUTE(v.`Duration 2`) +
    (SECOND(v.`Duration 2`) / 60.0) AS session_minutes,

    -- =========================
    -- USER DEMOGRAPHICS
    -- =========================

    -- AGE
    CASE 
        WHEN u.Age IS NULL 
             OR TRIM(u.Age) = '' 
             OR LOWER(u.Age) IN ('none', 'na', 'n/a', 'unknown')
             OR NOT TRIM(u.Age) RLIKE '^[0-9]+$'
        THEN NULL
        ELSE INT(TRIM(u.Age))
    END AS age,

    -- AGE CATEGORY
    CASE 
        WHEN INT(TRIM(u.Age)) BETWEEN 18 AND 24 THEN 'Youth'
        WHEN INT(TRIM(u.Age)) BETWEEN 25 AND 34 THEN 'Young Adults'
        WHEN INT(TRIM(u.Age)) BETWEEN 35 AND 54 THEN 'Adults'
        WHEN INT(TRIM(u.Age)) >= 55 THEN 'Seniors'
        WHEN u.Age IS NULL 
             OR TRIM(u.Age) = '' 
             OR LOWER(u.Age) IN ('none', 'na', 'n/a', 'unknown')
             OR NOT TRIM(u.Age) RLIKE '^[0-9]+$'
        THEN 'Not Disclosed'
        ELSE 'Other'
    END AS age_category,

    -- GENDER
    CASE 
        WHEN u.Gender IS NULL OR TRIM(u.Gender) = '' OR LOWER(u.Gender) = 'none'
        THEN 'Not Disclosed'
        WHEN LOWER(u.Gender) IN ('male', 'm')
        THEN 'Male'
        WHEN LOWER(u.Gender) IN ('female', 'f')
        THEN 'Female'
        ELSE 'Other'
    END AS gender,

    -- PROVINCE
    CASE 
        WHEN u.Province IS NULL OR TRIM(u.Province) = '' OR LOWER(u.Province) = 'none'
        THEN 'Not Disclosed'
        ELSE INITCAP(TRIM(u.Province))
    END AS province,

    -- RACE
    CASE 
        WHEN u.Race IS NULL OR TRIM(u.Race) = '' OR LOWER(u.Race) = 'none'
        THEN 'Not Disclosed'
        ELSE INITCAP(TRIM(u.Race))
    END AS race

-- =========================
-- FROM + JOIN (FINAL STEP)
-- =========================
FROM `consultation-class`.default.viewership v

LEFT JOIN `consultation-class`.default.user_profiles u
ON TRIM(LOWER(v.UserID0)) = TRIM(LOWER(u.UserID));
