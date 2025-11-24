/*sk 9: Finding Top 5 Customers by Sales Volume (6 Marks)
Walmart wants to reward its top 5 customers who have generated the most sales Revenue.*/
SELECT 
    SUM(Total), Customer ID
FROM
    walmartsales
GROUP BY Customer_ID
ORDER BY Total DESC
LIMIT 5;
/*
Task 8: Identifying Repeat Customers (6 Marks)
Walmart needs to identify customers who made repeat purchases within a specific time frame (e.g., within 30
days).*/

SELECT 
    a.CustomerID,
    a.Invoice ID  AS  First_Purchase_Date,
    b.Invoice_date AS Repeat_Purchase_Date,
    DATEDIFF(STR_TO_DATE(b.Invoice_date, '%m/%d/%Y'), STR_TO_DATE(a.Invoice_date, '%m/%d/%Y')) AS Days_Between
FROM sales a
JOIN sales b 
    ON a.Customer_ID = b.Customer_ID
    AND STR_TO_DATE(b.Invoice_date, '%m/%d/%Y') > STR_TO_DATE(a.Invoice_date, '%m/%d/%Y')
    AND DATEDIFF(STR_TO_DATE(b.Invoice_date, '%m/%d/%Y'), STR_TO_DATE(a.Invoice_date, '%m/%d/%Y')) <= 30
ORDER BY a.Customer_ID, a.Invoice_date;

/*Task 1: Identifying the Top Branch by Sales Growth Rate (6 Marks)
Walmart wants to identify which branch has exhibited the highest sales growth over time. Analyze the total sales
for each branch and compare the growth rate across months to find the top performer.*/
SELECT 
    Branch,
    DATE_FORMAT(STR_TO_DATE(Invoice_date, '%m/%d/%Y'), '%Y-%m') AS Month,
    SUM(Total) AS Monthly_Sales
INTO monthly_sales
FROM walmartsales
GROUP BY Branch, Month;

-- Step 2: Add previous month's sales for comparison
SELECT 
    Branch,
    Month,
    Monthly_Sales,
    LAG(Monthly_Sales) OVER (PARTITION BY Branch ORDER BY Month) AS Previous_Month_Sales
INTO sales_with_growth
FROM monthly_sales;

-- Step 3: Calculate growth rate and average it for each branch
SELECT 
    Branch,
    ROUND(AVG(
        CASE 
            WHEN Previous_Month_Sales IS NULL OR Previous_Month_Sales = 0 THEN 0
            ELSE (Monthly_Sales - Previous_Month_Sales) / Previous_Month_Sales * 100
        END
    ), 2) AS Avg_Growth_Rate
FROM sales_with_growth
GROUP BY Branch
ORDER BY Avg_Growth_Rate DESC
LIMIT 1;

/*Task 2: Finding the Most Profitable Product Line for Each Branch (6 Marks)
Walmart needs to determine which product line contributes the highest profit to each branch.The profit margin
should be calculated based on the difference between the gross income and cost of goods sold.*/
WITH product_profit AS (
    SELECT Branch,Product_line,
        SUM(gross_income) AS Total_Profit   FRom walmartsales
    GROUP BY Branch, Product_line
),ranked_profit AS (
    SELECT *,RANK() OVER (PARTITION BY Branch ORDER BY Total_Profit DESC) AS profit_rank
    FROM product_profit
)SELECT Branch,Product_line,Total_Profit
FROM ranked_profit
WHERE profit_rank = 1;

/*Task 3: Analyzing Customer Segmentation Based on Spending (6 Marks)
Walmart wants to segment customers based on their average spending behavior. Classify customers into three
tiers: High, Medium, and Low spenders based on their total purchase amounts*/
WITH customer_spending AS (
    SELECT 
        Customer_ID,
        ROUND(SUM(Total), 2) AS Total_Spent,
        ROUND(AVG(Total), 2) AS Avg_Spent
    FROM sales group by Customer_ID
),segmented_customers AS (
    SELECT Customer_ID,Total_Spent,Avg_Spent,
        CASE 
            WHEN Avg_Spent >= 200 THEN 'High Spender'
            WHEN Avg_Spent BETWEEN 100 AND 199.99 THEN 'Medium Spender'
            ELSE 'Low Spender'
        END AS Spending_Tier
    FROM customer_spending
)SELECT * FROM segmented_customers
ORDER BY Total_Spent DESC;

/*Task 4: Detecting Anomalies in Sales Transactions (6 Marks)
Walmart suspects that some transactions have unusually high or low sales compared to the average for the
product line. Identify these anomalies.*/
WITH product_stats AS (
    SELECT Product_line,AVG(Total) AS avg_sales,STDDEV(Total) AS std_sales
    FROM sales GROUP BY Product_line
),sales_with_stats AS (
    SELECT s.Invoice_ID,s.Product_line,s.Total,p.avg_sales,p.std_sales
    FROM sales s
JOIN product_stats p ON s.Product_line = p.Product_line
)
SELECT Invoice_ID,Product_line,Total,
    ROUND(avg_sales, 2) AS Avg_Sales,
    ROUND(std_sales, 2) AS Std_Dev,
    CASE 
        WHEN Total > avg_sales + 2 * std_sales THEN 'High Anomaly'
        WHEN Total < avg_sales - 2 * std_sales THEN 'Low Anomaly'
    END AS Anomaly_Type
FROM sales_with_stats
WHERE Total > avg_sales + 2 * std_sales 
   OR Total < avg_sales - 2 * std_sales;
   
/*Task 5: Most Popular Payment Method by City 
Walmart needs to determine the most popular payment method in each city to tailor marketing strategies*/
WITH payment_counts AS (
    SELECT City,Payment,COUNT(*) AS Payment_Count
    FROM sales GROUP BY City, Payment
),ranked_payments AS (
    SELECT *,
           RANK() OVER (PARTITION BY City ORDER BY Payment_Count DESC) AS payment_rank
    FROM payment_counts
)
SELECT 
    City,Payment AS Most_Popular_Payment_Method,Payment_Count
FROM ranked_payments
WHERE payment_rank = 1;

/*Task 6: Monthly Sales Distribution by Gender 
Walmart wants to understand the sales distribution between male and female customers on a monthly basis */
SELECT 
    DATE_FORMAT(STR_TO_DATE(Invoice_date, '%m/%d/%Y'), '%Y-%m') AS Month,Gender,
    ROUND(SUM(Total), 2) AS Total_Sales
FROM walmartsales
GROUP BY Month, Gender
ORDER BY Month, Gender;

/*Task 7: Best Product Line by Customer Type 
Walmart wants to know which product lines are preferred by different customer types(Member vs. Normal).*/
WITH product_preference AS (
    SELECT Customer_type,Product_line,SUM(Quantity) AS Total_Quantity
    FROM walmartsales
    GROUP BY Customer_type, Product_line
),ranked_preferences AS (
    SELECT *,
           RANK() OVER (PARTITION BY Customer_type ORDER BY Total_Quantity DESC) AS rank_order
    FROM product_preference
)SELECT 
    Customer_type,
    Product_line AS Top_Product_Line,
    Total_Quantity
FROM ranked_preferences
WHERE rank_order = 1;

/*Task 10: Analyzing Sales Trends by Day of the Week (6 Marks)
Walmart wants to analyze the sales patterns to determine which day of the week
brings the highest sales.*/
SELECT 
    DAYNAME(STR_TO_DATE(Invoice_date, '%m/%d/%Y')) AS Day_Name,
    ROUND(SUM(Total), 2) AS Total_Sales
FROM sales
GROUP BY Day_Name
ORDER BY Total_Sales DESC;






























