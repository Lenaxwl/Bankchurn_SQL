SELECT *
FROM bankchurn.churn;

-- Make a staging table and work on it
CREATE TABLE bankchurn.churn_staging
LIKE bankchurn.churn;

TRUNCATE TABLE bankchurn.churn_staging;

INSERT bankchurn.churn_staging
SELECT * FROM bankchurn.churn;

-- Clean dataset
SELECT * 
FROM bankchurn.churn_staging;

-- 1. Check duplicate
SELECT CustomerId, COUNT(*)
FROM bankchurn.churn_staging
GROUP BY CustomerId
HAVING COUNT(*) > 1;
-- No row returns, means no duplicate.

-- 2. Check NUll or Missing value
SELECT *
FROM bankchurn.churn_staging
WHERE CustomerID IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE Surname IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE CreditScore IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE Geography IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE Gender IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE Age IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE Tenure IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE Balance IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE NumOfProducts IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE HasCrCard IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE IsActiveMember IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE EstimatedSalary IS NULL;

SELECT *
FROM bankchurn.churn_staging
WHERE Exited IS NULL;

-- No rows returns, means no NULL or Missing values

-- Check Text column to see if any inconsistance
SELECT DISTINCT Surname
FROM bankchurn.churn_staging;
-- Everything looks fine, there are 2931 distinct surnames

SELECT DISTINCT Geography
FROM bankchurn.churn_staging;
-- There are 3 countries, France, Spain and Germany

SELECT DISTINCT Gender
FROM bankchurn.churn_staging;
-- There are 2 Genders, Male and Female

-- Check numerical column to see if any outliers 
-- Check CustomerId to see if all ID is distinct
SELECT DISTINCT CustomerID
FROM bankchurn.churn_staging;
-- 10000 rows returns, same as the whole dataset, means all CustomerID is unique

SELECT 
	MAX(Age) AS max_age,
    MIN(Age) AS min_age
FROM bankchurn.churn_staging;
-- max_age is 92, min_age is 18 and it is in proper age range

SELECT 
	MAX(Tenure) AS max_tenure,
    MIN(Tenure) AS min_tenure,
	ROUND(AVG(Tenure), 0) AS avg_tenure
FROM bankchurn.churn_staging;
-- max_tenure is 10 years, while min_tenure is 0 years, and average tenure is 5 years

SELECT 
	MAX(Balance) AS max_Balance,
    MIN(Balance) AS min_Balance,
    ROUND(AVG(Balance), 2) AS avg_Balance
FROM bankchurn.churn_staging;
-- The max balance is $250898.09, the minimum balance is $0, the average balance is $76485.89

SELECT 
	MAX(EstimatedSalary) AS max_EstimatedSalary,
    MIN(EstimatedSalary) AS min_EstimatedSalary,
    ROUND(AVG(EstimatedSalary), 2) AS avg_EstimatedSalary
FROM bankchurn.churn_staging;
-- The max estimated salary is $199992.48, the minimum estimated salary is $11.58, and average estimated salary is $100090.24.

-- All the variables are in the resonable range and no outliers.

-- Analyse the data
SELECT *
FROM bankchurn.churn_staging;

-- 1. How many total records are in the dataset?
SELECT COUNT(*) AS Total_records
FROM bankchurn.churn_staging;
-- There are 10000 records in this dataset. 

-- How many customers are there per country?
SELECT Geography, COUNT(CustomerId) AS Customer_num
FROM bankchurn.churn_staging
GROUP BY Geography;
-- France has 5014 customers, Spain has 2477 customers, and Germany has 2509 customers.

-- What is the average balance for customers who churned vs. those who didn’t?
SELECT Exited, ROUND(AVG(Balance),2) AS average_balance
FROM bankchurn.churn_staging
GROUP BY Exited;
-- The average balance for churned customers are $91,108.54, while not churned customers' average balance is $72,745.3

-- Which customers have the highest credit scores? List the top 10.

SELECT CustomerID, Surname, CreditScore
FROM bankchurn.churn_staging
ORDER BY CreditScore DESC
LIMIT 10;

-- What is the total balance for each country and gender combination?
SELECT Geography, Gender, ROUND(SUM(Balance),2) AS total_balance
FROM bankchurn.churn_staging
GROUP BY Geography, Gender
Order BY Geography;

-- What percentage of customers churned vs. those who retained?
SELECT Exited, 
		ROUND(100 * COUNT(Exited) /
        (SELECT COUNT(*) AS total_count
		FROM bankchurn.churn_staging), 2) AS Percentage
FROM bankchurn.churn_staging
GROUP BY Exited;
-- The churned percentage is 20.37%, the retained percentage is 79.63%

-- What is the average tenure for customers with different numbers of products?
SELECT NumOfProducts, ROUND(AVG(Tenure), 2) AS average_churn
FROM bankchurn.churn_staging
GROUP BY NumOfProducts;

-- What are the minimum, maximum, and average credit scores by country?
SELECT Geography, 
	   MIN(CreditScore) AS min_CreditScore, 
       MAX(CreditScore) AS max_CreditScore, 
       ROUND(AVG(CreditScore), 2) AS avg_CreditScore
FROM bankchurn.churn_staging
GROUP BY Geography;

-- Advanced SQL Questions
-- What is the most common tenure among customers who churned?
SELECT Tenure, COUNT(Tenure) AS Tenure_frequency
FROM bankchurn.churn_staging
WHERE Exited = 1
GROUP BY Tenure
ORDER BY Tenure_frequency DESC
LIMIT 1; 
-- Among churned customers, the most common tenure is 1

-- What is the cumulative sum of estimated salaries by geography?
SELECT Geography, 
	   EstimatedSalary,
	   ROUND (SUM(EstimatedSalary) OVER(PARTITION BY Geography ORDER BY CustomerId), 2) AS Cumulative_salary
FROM bankchurn.churn_staging;

-- What is the average and standard deviation of balance, segmented by gender and churn status?
SELECT Gender, 
	   Exited, 
       ROUND(AVG(Balance), 2) AS Avg_balance,
	   ROUND(STD(Balance), 2) AS Std_balance
FROM bankchurn.churn_staging
GROUP BY Gender, Exited;

-- How many churned customers fall within different age brackets (e.g., under 20, 20-30, etc.)?
SELECT 
CASE
	WHEN Age < 20 THEN "Under 20"
    WHEN Age BETWEEN 20 AND 30 THEN "20-30"
    WHEN Age BETWEEN 31 AND 40 THEN "31-40"
	WHEN Age BETWEEN 41 AND 50 THEN "41-50"
    ELSE "Over 50"
END AS Age_group,
COUNT(Exited) AS Churned_num
FROM bankchurn.churn_staging
WHERE Exited = 1
GROUP BY Age_group
ORDER BY Age_group;

-- Who are the top 5 customers with the highest credit scores in each country among active members?
WITH Customer_score AS(
 SELECT CustomerID, 
		Surname, 
        CreditScore, 
        Geography,
        ROW_NUMBER() OVER (
        PARTITION BY Geography 
        ORDER BY CreditScore DESC) AS Score_rank
FROM bankchurn.churn_staging
WHERE IsActiveMember = 1
)
SELECT CustomerID, 
		Surname, 
        CreditScore, 
        Geography
FROM Customer_score
WHERE Score_rank <= 5;

-- Analytical SQL Questions
-- What is the retention rate (percentage of non-churned customers) by country?
SELECT Geography, 
	   ROUND(100 * COUNT(Exited) /
        (SELECT COUNT(*) AS total_count
		FROM bankchurn.churn_staging), 2) AS Percentage
FROM bankchurn.churn_staging
WHERE Exited = 0
GROUP BY Geography;


-- How many customers are active members but do not have a credit card?
SELECT ISActiveMember, COUNT(CustomerId) AS Number
FROM bankchurn.churn_staging
WHERE HasCrCard = 0 AND IsActiveMember = 1
GROUP BY ISActiveMember;

-- What are the outliers in balance among churned customers (e.g., balances more than 2 standard deviations above the mean)?
SELECT CustomerId, 
	   Balance
FROM bankchurn.churn_staging
WHERE Exited = 1
AND Balance > (SELECT (AVG(Balance) + 2 * STDDEV(Balance)) AS Limits
				FROM bankchurn.churn_staging);

-- What is the average number of products for churned customers compared to retained ones?
SELECT Exited, ROUND(AVG(NumOfProducts)) AS Avg_products
FROM bankchurn.churn_staging
GROUP BY Exited;
-- For chured customers, the average number of products is about 1, and 2 for retained customers

-- What are the patterns in churn rates by different factors like country, age bracket, and tenure?
-- what is the churn rate by country
SELECT Geography,
	   ROUND(100 * COUNT(*) / (SELECT COUNT(*) AS Total
							   FROM bankchurn.churn_staging),
			2) AS Percentage
FROM bankchurn.churn_staging
WHERE Exited = 1
GROUP BY Geography;
-- Spain has the lowest churn rate, around 4.13%, Germany (8.14%) and France(8.10%) has the similar churn rate.

-- What is the churn rate by age bracket
SELECT 
CASE
	WHEN Age < 20 THEN "Under 20"
    WHEN Age BETWEEN 20 AND 30 THEN "20-30"
    WHEN Age BETWEEN 31 AND 40 THEN "31-40"
	WHEN Age BETWEEN 41 AND 50 THEN "41-50"
    ELSE "Over 50"
END AS Age_group,
ROUND(100 * COUNT(*) / (SELECT COUNT(*) AS Total
					    FROM bankchurn.churn_staging),
	  2) AS Percentage
FROM bankchurn.churn_staging
WHERE Exited = 1
GROUP BY Age_group
ORDER BY Percentage;
-- Under 20 has the lowest churn rate 0.03%, 41-50 age group has the highest churn rate 7.88%, 20-30 age group churn rate is 1.45%, 
-- and 31-40 age group has 5.38% churn rate, while over 50 has 5.63 churn rate.

-- What is the churn rate by Tenure
SELECT Tenure,
	   ROUND(100 * COUNT(*) / (SELECT COUNT(*) AS Total
							   FROM bankchurn.churn_staging),
			2) AS Percentage
FROM bankchurn.churn_staging
WHERE Exited = 1
GROUP BY Tenure
ORDER BY Percentage;
-- When tenure are 0(0.95%)and 10(1.01%) years, the churn rate is relatively lower, the higest churn rate is 1 year tenure, is 2.32%.
