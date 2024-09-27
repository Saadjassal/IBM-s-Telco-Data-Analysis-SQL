create database Customer_Churn;
USE Customer_Churn;

-- duplicate in customer id 
select `Customer ID`, count(`Customer ID`)
from telco_customer_churn_services
group by `Customer ID`
having count(`Customer ID`) > 1;


-- Query 1: Considering the top 5 groups with the highest
-- average monthly charges among churned customers,
-- how can personalized offers be tailored based on age,
-- gender, and contract type to potentially improve
-- customer retention rates?

select * from telco_customer_churn_services;
select * from telco_customer_churn_status;
select * from telco_customer_churn_demographics;

WITH churned_customers AS (
  SELECT a.`Customer ID`, 
         a.`Contract` AS contract_type, 
         AVG(a.`Monthly Charge`) AS average_monthly_charges,
         b.`Customer Status`,
         c.`Age`,
         c.`Gender`
  FROM telco_customer_churn_services a
  JOIN telco_customer_churn_status b
    ON a.`Customer ID` = b.`Customer ID`
  JOIN telco_customer_churn_demographics c
    ON a.`Customer ID` = c.`Customer ID`
  WHERE b.`Customer Status` = 'churned'
  GROUP BY a.`Customer ID`, a.`Contract`, b.`Customer Status`, c.`Age`, c.`Gender`
)
SELECT 
  CASE 
    WHEN Age BETWEEN 18 AND 25 THEN '18-25'
    WHEN Age BETWEEN 26 AND 35 THEN '26-35'
    WHEN Age BETWEEN 36 AND 45 THEN '36-45'
    ELSE '46+' 
  END AS age_group, 
  Gender, 
  contract_type, 
  AVG(average_monthly_charges) AS avg_monthly_charges_per_group
FROM churned_customers
GROUP BY age_group, Gender, contract_type
ORDER BY avg_monthly_charges_per_group DESC
LIMIT 5;


-- Query 2: What are the feedback or complaints from
-- those churned customers


WITH churned_customers AS (
  -- This part identifies all churned customers as in Query 1
  SELECT a.`Customer ID`, 
         a.`Contract` AS contract_type, 
         AVG(a.`Monthly Charge`) AS average_monthly_charges,
         b.`Customer Status`,
         b.`Churn Reason` AS feedback
  FROM telco_customer_churn_services a
  JOIN telco_customer_churn_status b
    ON a.`Customer ID` = b.`Customer ID`
  WHERE b.`Customer Status` = 'churned'
  GROUP BY a.`Customer ID`, a.`Contract`, b.`Customer Status`, b.`Churn Reason`
)
-- Now group by feedback to get the count of churned customers per feedback
SELECT 
    c.feedback AS feedback_reason,
    COUNT(c.`Customer ID`) AS customer_count,
    AVG(d.`Age`) AS average_age,
    d.`Gender`,
    AVG(c.average_monthly_charges) AS avg_monthly_charges
FROM 
    churned_customers c
JOIN 
    telco_customer_churn_demographics d
ON 
    c.`Customer ID` = d.`Customer ID`
GROUP BY 
    c.feedback, d.`Gender`
ORDER BY 
    customer_count DESC;


-- Query 3: How does the payment method influence
-- churn behavior?

SELECT 
    s.`Payment Method`, 
    COUNT(st.`Customer ID`) AS total_customers,
    COUNT(CASE WHEN st.`Churn Label` = 'Yes' THEN 1 END) AS churned_customers,
    ROUND(COUNT(CASE WHEN st.`Churn Label` = 'Yes' THEN 1 END) / COUNT(st.`Customer ID`) * 100, 2) AS churn_rate_percentage
FROM 
    telco_customer_churn_services s
JOIN 
    telco_customer_churn_status st
ON 
    s.`Customer ID` = st.`Customer ID`
GROUP BY 
    s.`Payment Method`
ORDER BY 
    churn_rate_percentage DESC;
