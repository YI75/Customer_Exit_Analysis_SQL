-- Question: What customer segments have the highest exiting rates? In this case we are interested in the following segments: Credit Score, Age, Balance

-- Breaking down Credit Score
SELECT MIN(CreditScore) AS 'max_credit', MAX(CreditScore) AS 'min_credit'
FROM customer_churn_staging;

-- Let's create CTE to classify credit score ranges as follows:
-- Poor: 300-573, Fair: 580-669, Good: 670-739, Great: 740-799, Exceptional: 800-850

WITH credit_score_category AS(
	SELECT *,
		CASE
			WHEN CreditScore BETWEEN 300 AND 573 THEN 1
            ELSE 0
        END AS credit_is_poor,
        CASE
			WHEN CreditScore BETWEEN 574 AND 669 THEN 1
            ELSE 0
        END AS credit_is_fair,
        CASE
			WHEN CreditScore BETWEEN 670 AND 739 THEN 1
            ELSE 0
        END AS credit_is_good,
        CASE
			WHEN CreditScore BETWEEN 740 AND 799 THEN 1
            ELSE 0
        END AS credit_is_great,
        CASE
			WHEN CreditScore BETWEEN 800 AND 850 THEN 1
            ELSE 0
        END AS credit_is_exceptional
    FROM customer_churn_staging
)

-- TRY USING CASE END AGAIN
SELECT 1.0*SUM(Exited) / SUM(credit_is_good) AS credit_fair_exit_rate
FROM credit_score_category
WHERE credit_is_good = 1;



