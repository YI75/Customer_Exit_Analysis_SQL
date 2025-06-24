-- Question: What customer segments have the highest exiting rates? In this case we are interested in the following segments: Credit Score, Age, Balance

-- Breaking down Credit Score
SELECT MIN(CreditScore) AS 'max_credit', MAX(CreditScore) AS 'min_credit'
FROM customer_churn_staging;

-- Let's create CTE to classify credit score ranges as follows:
-- Poor: 300-573, Fair: 580-669, Good: 670-739, Great: 740-799, Exceptional: 800-850

WITH credit_score_category AS(
	SELECT *,
		CASE
			WHEN CreditScore BETWEEN 300 AND 573 THEN 'Poor'
            WHEN CreditScore BETWEEN 574 AND 669 THEN 'Fair'
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Great'
            WHEN CreditScore BETWEEN 800 AND 850 THEN 'Exceptional'
		END AS credit_range
    FROM customer_churn_staging
), credit_exit_range AS(
	SELECT credit_range, ROUND(1.0 * SUM(Exited) / COUNT(*), 3) AS exit_rate
	FROM credit_score_category
	GROUP BY 1
)

SELECT credit_range, exit_rate, RANK() OVER(ORDER BY exit_rate DESC) AS rank_credit
FROM credit_exit_range;

-- We can conclude that customers with a poor credit score had higher exit rates

-- Breaking down age
-- We will group ages bases on decades, except for younger than 20 and older than 59
WITH age_category AS(
	SELECT *,
		CASE
			WHEN Age BETWEEN 0 AND 19 THEN '0-19 years old'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29 years old'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39 years old'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49 years old'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59 years old'
		    WHEN Age BETWEEN 50 AND 59 THEN '50-59 years old'
            WHEN Age >= 60 THEN 'Over 60 years old'
		END AS age_range
    FROM customer_churn_staging
), age_exit_range AS(
	SELECT age_range, ROUND(1.0 * SUM(Exited) / COUNT(*), 3) AS exit_rate
	FROM age_category
	GROUP BY 1
)

SELECT age_range, exit_rate, RANK() OVER(ORDER BY exit_rate DESC) AS rank_age
FROM age_exit_range;

-- We can conclude that customers between the ages of 50 and 59 years old had higher exit rates, while notably those under 29 had the lowest

-- Breakdown of Balance
-- For understanding the exit rate for different balances, we are going to breakdown the balance in quartiles
WITH balance_quartiles AS(
	SELECT *, NTILE(4) OVER(ORDER BY Balance) AS quartile
	FROM customer_churn_staging
), balance_quartile_category AS(
	SELECT *, 
		CASE
			WHEN quartile = 1 THEN 'First Quartile'
			WHEN quartile = 2 THEN 'Second Quartile'
			WHEN quartile = 3 THEN 'Third Quartile'
			WHEN quartile = 4 THEN 'Fourth Quartile'
        END AS quartile_cat
    FROM balance_quartiles
), quartile_exit_range AS(
	SELECT quartile_cat, MIN(Balance) AS min_quartile, MAX(Balance) AS max_quartile, ROUND(1.0 * SUM(Exited) / COUNT(*), 3) AS exit_rate
	FROM balance_quartile_category
	GROUP BY 1
)

SELECT quartile_cat, min_quartile, max_quartile, exit_rate, RANK() OVER(ORDER BY exit_rate DESC) AS rank_age
FROM quartile_exit_range;

-- People with balances in the third quartile, ranging from 97,208.46 euros and 127,642.44 euros have the highest exit rates, and those with a balance of 0 have the lowest exit rate from the bank 

-- Question: How long do customers stay before leaving the bank? Understanding the average customer lifetime and how long their tenure is by customer segment is the goal for this question.

SELECT AVG(Tenure) AS average_tenure_exited
FROM customer_churn_staging
WHERE Exited = 1;

-- On average, customers stay around 5 years before the bank

SELECT AVG(Tenure) AS average_tenure_exited
FROM customer_churn_staging
WHERE Exited = 1;

SELECT Geography, Gender, CreditScore, EstimatedSalary, AVG(Tenure) AS average_tenure_exited
FROM customer_churn_staging
WHERE Exited = 1
GROUP BY 1, 2, 3, 4
ORDER BY 3 ASC;

SELECT * 
FROM balance_quartiles;