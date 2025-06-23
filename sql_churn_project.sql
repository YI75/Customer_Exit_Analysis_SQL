-- Data Cleaning Steps
-- 1) Remove Duplicates
-- 2) Standardize the Data
-- 3) Deal with Null and/or Bland values
-- 4) Remove any columns if necessary 

-- Creating copy of orginal table to clean
CREATE TABLE customer_churn_staging
LIKE `customer churn new`;

INSERT customer_churn_staging
SELECT * 
FROM `customer churn new`;

-- Check for duplicates
WITH duplicate_cte AS(
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY CustomerId, Surname, CreditScore, Geography, Gender, Age, Tenure, Balance, EstimatedSalary, Exited) AS 'duplicate_check'
	FROM customer_churn_staging
)

SELECT *
FROM duplicate_cte
WHERE duplicate_check > 1;
-- No duplicates found

-- Standardizing data
SELECT Surname
FROM customer_churn_staging
ORDER BY 1;

SELECT DISTINCT CreditScore
FROM customer_churn_staging
ORDER BY 1;

SELECT DISTINCT Geography
FROM customer_churn_staging;

SELECT DISTINCT Gender
FROM customer_churn_staging;

SELECT SUM(Exited)
FROM customer_churn_staging;

-- Checking for Null or Blank values
SELECT COUNT(*), COUNT(Surname), COUNT(CreditScore), COUNT(Geography), COUNT(Age), 
	COUNT(Tenure), COUNT(Balance),COUNT(EstimatedSalary), COUNT(Exited)
FROM customer_churn_staging;

-- Removing Columns unnecessary for this project, like Surname
ALTER TABLE customer_churn_staging
DROP COLUMN Surname;
