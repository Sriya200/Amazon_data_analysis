-- ANALYSIS 1
--To simplify its financial reports, Amazon India needs to standardize payment values.
SELECT 
    payment_type,
	ROUND(AVG(payment_value)) AS rounded_avg_payment
FROM 
    amazon_brazil.payments
GROUP BY 
    payment_type
ORDER BY 
    rounded_avg_payment ASC;



--To refine its payment strategy, Amazon India wants to know the distribution of orders 
--by payment type.
SELECT 
    payment_type,
    ROUND((COUNT(order_id) * 100.0) / (SELECT COUNT(*) FROM amazon_brazil.payments), 1)
	AS percentage_orders
FROM 
    amazon_brazil.payments
GROUP BY 
    payment_type
ORDER BY 
    percentage_orders DESC;


--Amazon India seeks to create targeted promotions for products within specific price ranges
SELECT 
    A.product_id, B.price 
FROM 
    amazon_brazil.order_items AS B
INNER JOIN	
    amazon_brazil.product AS A
ON  B.product_id=A.product_id
WHERE 
    B.price BETWEEN 100 AND 500
AND	A.product_category_name LIKE '%smart%'
ORDER BY 
    B.price DESC;


--To identify seasonal sales patterns, Amazon India needs to focus on the most successful months. Determine the top 3 months with the highest total sales value, rounded to the nearest integer.
SELECT
EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
ROUND(SUM(oi.price))AS total_sales
FROM
amazon_brazil.orders o
JOIN
amazon_brazil.order_items oi 
ON o.order_id = oi.order_id
GROUP BY
EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY DESC
total_sales
LIMIT 3;


--Amazon India is interested in product categories with significant price variations.
SELECT 
    A.product_category_name,
	MAX(B.price)- MIN(B.price) AS price_difference
FROM 
    amazon_brazil.order_items AS B
JOIN 
    amazon_brazil.product AS A
ON  B.product_id=A.product_id
GROUP BY 
    A.product_category_name
HAVING
    MAX(B.price)- MIN(B.price) >500
ORDER BY
    price_difference DESC;

	
--To enhance the customer experience, Amazon India wants to find which payment types have the most consistent transaction amounts.
SELECT payment_type, STDDEV(payment_value) AS std_deviation
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY std_deviation DESC;


--Amazon India wants to identify products that may have incomplete name in order to fix it from their end. 
SELECT product_id, product_category_name
FROM amazon_brazil.product
WHERE product_category_name ISNULL OR LENGTH(product_category_name)=1;

--ANALYSIS 2
--Amazon India wants to understand which payment types are most popular across different order value segments (e.g., low, medium, high). Segment order values into three ranges: orders less than 200 BRL, between 200 and 1000 BRL, and over 1000 BRL. Calculate the count of each payment type within these ranges and display the results in descending order of count
SELECT 
    CASE
        WHEN payment_value < 200 THEN 'low'
        WHEN payment_value BETWEEN 200 AND 1000 THEN 'medium'
        ELSE 'high'
    END AS order_value_segment, payment_type,
	    COUNT(*) AS count
FROM amazon_brazil.payments
GROUP BY 
     order_value_segment, payment_type
ORDER BY count DESC;



WITH CTE AS(
SELECT
payment_type ,
CASE
WHEN payment_value < 200 THEN 'low'
WHEN payment_value BETWEEN 200 AND 1000 THEN 'medium'
WHEN payment_value > 1000 THEN 'high'
END AS segment
FROM amazon_brazil.payments
)
SELECT segment , payment_type , COUNT(*)
FROM CTE
GROUP BY payment_type, segment
ORDER BY COUNT(*) DESC;


--Calculate the minimum, maximum, and average price for each category, and list them in descending order by the average price.
SELECT P.product_category_name,
MAX(oi.price) AS max_price, 
MIN(oi.price) AS min_price, 
AVG(oi.price) AS avg_price
FROM amazon_brazil.product AS P
JOIN amazon_brazil.order_items AS oi
ON P.product_id=oi.product_id
GROUP BY 
product_category_name
ORDER BY avg_price DESC;


--Find all customers with more than one order, and display their customer unique IDs along with the total number of orders they have placed.
SELECT C.customer_unique_id, COUNT(O.order_id) AS total_orders
FROM amazon_brazil.customers AS C
JOIN amazon_brazil.orders AS O
ON C.customer_id=O.customer_id
GROUP BY C.customer_unique_id
HAVING COUNT(O.order_id)>1
order by total_orders DESC;


--Amazon India wants to categorize customers into different types ('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) based on their purchase history. Use a temporary table to define these categories and join it with the customers table to update and display the customer types.
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS orders
    FROM
        amazon_brazil.orders
    GROUP BY
        customer_id
)
SELECT
    c.customer_id,
    CASE
        WHEN co.orders = 1 THEN 'New'
        WHEN co.orders BETWEEN 2 AND 4 THEN 'Returning'
        WHEN co.orders > 4 THEN 'Loyal'
        ELSE 'New'
    END AS customer_type
FROM
    amazon_brazil.customers c
LEFT JOIN
    customer_orders co
ON 
    c.customer_id = co.customer_id
	ORDER BY customer_type DESC;


-- Use joins between the tables to calculate the total revenue for each product category. Display the top 5 categories.
SELECT
p.product_category_name,
SUM(oi.price) AS total_revenue
FROM
amazon_brazil.order_items oi
JOIN
amazon_brazil.product p
ON
oi.product_id = p.product_id
JOIN
amazon_brazil.orders o
ON
oi.order_id = o.order_id
GROUP BY
p.product_category_name
ORDER BY
total_revenue DESC
LIMIT 5;


--ANALYSIS 3
--Use a subquery to calculate total sales for each season (Spring, Summer, Autumn, Winter) based on order purchase dates, and display the results. Spring is in the months of March, April and May. Summer is from June to August and Autumn is between September and November and rest months are Winter. 
SELECT
season,
SUM(total_sales) AS total_sales
FROM (
SELECT
CASE
WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (3, 4, 5) THEN 'Spring'
WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (6, 7, 8) THEN 'Summer'
WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9, 10, 11) THEN 'Autumn'
ELSE 'Winter'
END AS season,
oi.price AS total_sales
FROM
amazon_brazil.orders o
JOIN
amazon_brazil.order_items oi
ON
o.order_id = oi.order_id
)
GROUP BY
season
ORDER BY
total_sales DESC;


--The inventory team is interested in identifying products that have sales volumes above the overall average.

SELECT product_id, 
       COUNT(order_item_id) AS total_quantity_sold
FROM amazon_brazil.order_items
GROUP BY product_id
HAVING COUNT(order_item_id) > (
    SELECT AVG(total_quantity_sold)
    FROM (
        SELECT product_id, COUNT(order_item_id) AS total_quantity_sold
        FROM amazon_brazil.order_items
        GROUP BY product_id
    ) AS avg_table
);

--To understand seasonal sales patterns, the finance team is analysing the monthly revenue trends over the past year (year 2018).

SELECT EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year, SUM(oi.price) AS total_revenue, 
EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month
FROM amazon_brazil.orders AS o
JOIN amazon_brazil.order_items AS oi
ON o.order_id=oi.order_id
GROUP BY EXTRACT(MONTH FROM o.order_purchase_timestamp), EXTRACT(YEAR FROM o.order_purchase_timestamp)
HAVING EXTRACT(YEAR FROM order_purchase_timestamp)='2018'
ORDER BY month;

--A loyalty program is being designed  for Amazon India
WITH customer_order AS (
SELECT customer_id, 
COUNT(order_id) AS total_orders
    FROM amazon_brazil.orders
    GROUP BY customer_id
)

SELECT customer_type,
    COUNT(*) AS customer_count
FROM 
(SELECT  customer_id, total_orders,
    CASE 
        WHEN total_orders BETWEEN 1 AND 2 THEN 'Occasional'
        WHEN total_orders BETWEEN 3 AND 5 THEN 'Regular'
        ELSE 'Loyal'
    END AS customer_type
	 FROM customer_order
)customer 
GROUP BY customer_type;



--Amazon wants to identify high-value customers to target for an exclusive rewards program.
WITH customer_revenue AS(
SELECT o.customer_id,  AVG(oi.price) AS avg_order_value
    FROM amazon_brazil.orders AS o
JOIN amazon_brazil.order_items AS oi
ON o.order_id=oi.order_id
GROUP BY o.customer_id),
ranked_customers AS(
SELECT 
    customer_id,
	avg_order_value,
 RANK() OVER(ORDER BY avg_order_value DESC) AS customer_rank
  FROM customer_revenue
  )
 SELECT customer_id, avg_order_value, customer_rank
FROM ranked_customers
WHERE customer_rank <= 20;



-- Amazon wants to analyze sales growth trends for its key products over their lifecycle. 
WITH monthly_sales AS (
    SELECT 
        oi.product_id,
        TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS sale_month,
        SUM(oi.price) AS monthly_sales
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id
    GROUP BY oi.product_id, sale_month
)
SELECT 
    product_id,
    sale_month,
    SUM(monthly_sales) OVER (
        PARTITION BY product_id 
        ORDER BY sale_month ASC
    ) AS total_sales
FROM monthly_sales
ORDER BY product_id, sale_month;


--To understand how different payment methods affect monthly sales growth, Amazon wants to compute the total sales for each payment method and calculate the month-over-month growth rate for the past year (year 2018). 
WITH monthly_sales AS (
    SELECT 
        p.payment_type,
        TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS sale_month,
        SUM(oi.price) AS monthly_total
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi 
        ON o.order_id = oi.order_id
    JOIN amazon_brazil.payments p 
        ON o.order_id = p.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018  -- Only 2018 sales
    GROUP BY p.payment_type, sale_month
)
SELECT 
    payment_type,
    sale_month,
    monthly_total,
  ROUND(
        (monthly_total - LAG(monthly_total) OVER (
            PARTITION BY payment_type 
            ORDER BY sale_month
        )) * 100.0 / NULLIF(LAG(monthly_total) OVER (
            PARTITION BY payment_type 
            ORDER BY sale_month
        ), 0), 2
    ) AS monthly_change
FROM monthly_sales
ORDER BY payment_type, sale_month;

















