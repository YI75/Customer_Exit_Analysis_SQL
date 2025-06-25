-- Question: What customer segments have the highest exiting rates? In this case we are interested in the following segments: Credit Score, Age, Balance

-- Breaking down Credit Score
SELECT MIN(CreditScore) AS 'max_credit', MAX(CreditScore) AS 'min_credit'
FROM customer_churn_staging;

-- Let's create CTE to classify credit score ranges as follows:
-- Poor: 300-573, Fair: 580-669, Good: 670-739, Great: 740-799, Exceptional: 800-850

CREATE TEMPORARY TABLE credit_score_category AS
SELECT CustomerId, Exited,
		CASE
			WHEN CreditScore BETWEEN 300 AND 573 THEN 'Poor'
            WHEN CreditScore BETWEEN 574 AND 669 THEN 'Fair'
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Great'
            WHEN CreditScore BETWEEN 800 AND 850 THEN 'Exceptional'
		END AS credit_range
    FROM customer_churn_staging;

WITH credit_exit_range AS(
	SELECT credit_range, ROUND(1.0 * SUM(Exited) / COUNT(*), 3) AS exit_rate
	FROM credit_score_category
	GROUP BY 1
)

SELECT credit_range, exit_rate, RANK() OVER(ORDER BY exit_rate DESC) AS rank_credit
FROM credit_exit_range;

-- We can conclude that customers with a poor credit score had higher exit rates

-- Breaking down age
-- We will group ages bases on decades, except for younger than 20 and older than 59

CREATE TEMPORARY TABLE age_category AS 
	SELECT CustomerID, Exited, 
			CASE
				WHEN Age BETWEEN 0 AND 19 THEN '0-19 years old'
				WHEN Age BETWEEN 20 AND 29 THEN '20-29 years old'
				WHEN Age BETWEEN 30 AND 39 THEN '30-39 years old'
				WHEN Age BETWEEN 40 AND 49 THEN '40-49 years old'
				WHEN Age BETWEEN 50 AND 59 THEN '50-59 years old'
				WHEN Age BETWEEN 50 AND 59 THEN '50-59 years old'
				WHEN Age >= 60 THEN 'Over 60 years old'
			END AS age_range
    FROM customer_churn_staging;
    
WITH age_exit_range AS(
	SELECT age_range, ROUND(1.0 * SUM(Exited) / COUNT(*), 3) AS exit_rate
	FROM age_category
	GROUP BY 1
)

SELECT age_range, exit_rate, RANK() OVER(ORDER BY exit_rate DESC) AS rank_age
FROM age_exit_range;

-- We can conclude that customers between the ages of 50 and 59 years old had higher exit rates, while notably those under 29 had the lowest

-- Breakdown of Balance
-- For understanding the exit rate for different balances, we are going to breakdown the balance in quartiles

CREATE TEMPORARY TABLE balance_quartile_category AS
SELECT CustomerID, Exited, Balance,  
	CASE
		WHEN quartile = 1 THEN 'First Quartile'
		WHEN quartile = 2 THEN 'Second Quartile'
		WHEN quartile = 3 THEN 'Third Quartile'
		WHEN quartile = 4 THEN 'Fourth Quartile'
	END AS quartile_cat
FROM (
	SELECT *, 
	NTILE(4) OVER(ORDER BY Balance) AS quartile
	FROM customer_churn_staging
    ) AS quartile_table;

WITH quartile_exit_range AS(
	SELECT quartile_cat, MIN(Balance) AS min_quartile, MAX(Balance) AS max_quartile, ROUND(1.0 * SUM(Exited) / COUNT(*), 3) AS exit_rate
	FROM balance_quartile_category
	GROUP BY 1
)

SELECT quartile_cat, min_quartile, max_quartile, exit_rate, RANK() OVER(ORDER BY exit_rate DESC) AS rank_age
FROM quartile_exit_range;

-- People with balances in the third quartile, ranging from 97,208.46 euros and 127,642.44 euros have the highest exit rates, and those with a balance of 0 have the lowest exit rate from the bank 

-- Breakdown of Estimated Salary
-- For understanding the exit rate for different balances, we are going to breakdown the balance in quartiles like we did for balances

CREATE TEMPORARY TABLE salary_quartile_category AS
SELECT CustomerID, Exited, EstimatedSalary,  
	CASE
		WHEN quartile = 1 THEN 'First Quartile'
		WHEN quartile = 2 THEN 'Second Quartile'
		WHEN quartile = 3 THEN 'Third Quartile'
		WHEN quartile = 4 THEN 'Fourth Quartile'
	END AS quartile_cat
FROM (
	SELECT *, 
	NTILE(4) OVER(ORDER BY EstimatedSalary) AS quartile
	FROM customer_churn_staging
    ) AS quartile_table;

WITH salary_quartile_exit_range AS(
	SELECT quartile_cat, MIN(EstimatedSalary) AS min_quartile, MAX(EstimatedSalary) AS max_quartile, ROUND(1.0 * SUM(Exited) / COUNT(*), 3) AS exit_rate
	FROM salary_quartile_category
	GROUP BY 1
)

SELECT quartile_cat, min_quartile, max_quartile, exit_rate, RANK() OVER(ORDER BY exit_rate DESC) AS rank_age
FROM salary_quartile_exit_range;

-- People with an estimated salary in the fourth quartile, ranging from 149,399.70 euros and 199,992.48 euros have the highest exit rates, and those with a balance of 0 have the lowest exit rate from the bank 


-- Question: How long do customers stay before leaving the bank? Understanding the average customer lifetime and how long their tenure is by customer segment is the goal for this question.

SELECT AVG(Tenure) AS average_tenure_exited
FROM customer_churn_staging
WHERE Exited = 1;

-- On average, customers stay around 5 years before the bank

SELECT *
FROM credit_score_category;

-- Joining all the categories we defined for CreditScore, Age, Balance, and Salary
WITH tenure_categories AS(
	SELECT cust_churn.CustomerID, cust_churn.Tenure, cust_churn.Geography, credit_cat.credit_range, age_cat.age_range, balance_cat.quartile_cat AS balance_quartile, salary_cat.quartile_cat AS salary_quartile
	FROM customer_churn_staging AS cust_churn
	INNER JOIN credit_score_category AS credit_cat
	ON cust_churn.CustomerId = credit_cat.CustomerId
	INNER JOIN age_category AS age_cat
	ON credit_cat.CustomerId = age_cat.CustomerId
	INNER JOIN balance_quartile_category AS balance_cat
	ON age_cat.CustomerId = balance_cat.CustomerId
	INNER JOIN salary_quartile_category AS salary_cat
	ON balance_cat.CustomerId = salary_cat.CustomerId
), grouped_categories AS(
	SELECT Geography, credit_range, age_range, balance_quartile, salary_quartile, 1.0*AVG(Tenure) AS avg_tenure
	FROM tenure_categories
	GROUP BY 1,2,3,4,5
), ranked_tenure_cat AS (
	SELECT *, RANK() OVER(PARTITION BY Geography ORDER BY avg_tenure) AS ranked_avg_tenure
	FROM grouped_categories
)

SELECT *
FROM ranked_tenure_cat
WHERE ranked_avg_tenure = 1;