CREATE DATABASE Zomato;
USE Zomato;
-- ---------------------------------- Swiggy Case Study------------------------------------------------------------------------
-- ---------------------------------- Basic SQL Queries -----------------------------------------------------------------------

SELECT *
FROM orders;

SELECT *
FROM order_details;

SELECT *
FROM users;

SELECT *
FROM restaurants;

SELECT *
FROM menu;

SELECT *
FROM food;

-- To find the NULL values
SELECT * FROM orders WHERE restaurant_rating IS NULL;

-- 1. Find Number of orders Placed by every user.
SELECT user_id , COUNT(*) AS 'orders' 
FROM orders 
GROUP BY user_id;

-- 2. Find userid and max amount spent by user on food
SELECT user_id , SUM(amount) as Total_amount
FROM orders
GROUP BY user_id
ORDER BY SUM(amount) DESC
LIMIT 1;

-- 3. Avg delivery time taken to deliver food round to 2 decimal ?
SELECT CONCAT(ROUND(AVG(delivery_time),2)," MINUTES") AS avg_delivery_time
FROM orders;

-- 4. Find customers who have never ordered
SELECT * 
FROM users as u
WHERE u.user_id NOT IN (SELECT user_id FROM orders);




-- ----------------------------------  SQL Queries Using Joins  -------------------------------------------------------------

-- 1. Find Number of orders Placed by every user.
SELECT t2.name,COUNT(*) AS 'orders_placed' FROM orders t1
JOIN users t2 ON t1.user_id = t2.user_id
GROUP BY t2.name;

-- 2. Average Price/dish 
SELECT m.f_id , f.f_name , round(avg(m.price),2) AS avg_price
FROM food as f JOIN menu as m ON m.f_id = f.f_id
GROUP BY m.f_id, f.f_name;

-- 3. Find the top restaurant in terms of the number of orders for a given month (month = June)
SELECT MONTHNAME(o.date), o.r_id as restaurand_id ,r.r_name,  count(o.user_id) as oreders_placed 
FROM orders AS o
JOIN restaurants AS r ON r.r_id = o.r_id
WHERE  MONTHNAME(date) = "June"
GROUP BY r.r_id,  MONTHNAME(date) , r.r_name
ORDER BY count(o.user_id) DESC
LIMIT 1;


-- 4. Name the restaurants with monthly sales greater than 500
SELECT o.r_id,  r.r_name, sum(amount)
FROM orders as o
JOIN restaurants as r ON r.r_id =o.r_id
WHERE MONTHNAME(date) = "June" 
GROUP BY r_id, r.r_name
HAVING sum(amount) > 500;


-- 5. Show all orders with order details for a particular customer in a particular date range (Ankit , 10June-10 July)
SELECT u.name , o.order_id, f.f_name , r.r_name
FROM orders as o
JOIN users as u ON u.user_id = o.user_id
JOIN order_details as od ON o.order_id = od.order_id
JOIN food as f ON f.f_id = od.f_id
JOIN restaurants as r ON o.r_id = r.r_id
WHERE u.name = "Ankit" AND o.date between "2022-06-10" AND "2022-07-10" ;



-- ---------------------------------- Advance SQL Queries -----------------------------------------------------------------------


-- 1. Find restaurants with max repeated customers  (Loyal Customers)
SELECT r.r_id , r.r_name, COUNT(r.r_id) as "Loyal_Customers"
FROM 
			(SELECT user_id , r_id , count(user_id) as visits
			FROM orders 
			GROUP BY user_id , r_id
			HAVING visits > 1
			ORDER BY count(user_id) DESC) t
JOIN restaurants as r ON r.r_id = t.r_id
GROUP BY t.r_id , r.r_name
ORDER BY Loyal_Customers DESC;


-- 2. Month over month revenue growth of swiggy
SELECT  MONTHNAME(date) as Month, SUM(amount) AS Total_sales,
		((SUM(amount) - LAG(SUM(amount)) OVER() )/ LAG(SUM(amount)) OVER()) * 100 AS MOM_Revenue_Swiggy
From orders
GROUP BY MONTHNAME(date);


-- 3. Print Customer and their favorite food
SELECT t.user_id, u.name ,f.f_name, t.count_of_orders 
FROM
		(SELECT o.user_id, od.f_id , count(od.f_id) as count_of_orders,
		RANK() OVER(PARTITION BY o.user_id ORDER BY count(od.f_id) DESC) as "ranks"
		FROM orders AS o
		JOIN order_details AS od ON o.order_id = od.order_id
		GROUP BY o.user_id, od.f_id
		ORDER BY o.user_id , count_of_orders DESC) t
JOIN users as u ON u.user_id = t.user_id
JOIN food as f ON f.f_id = t.f_id
WHERE ranks = 1 
ORDER BY t.user_id;


-- 4.Find the most loyal customers for all restaurants and their visits
SELECT u.name as Loyal_customers  , r.r_name as Restaurant_name, t.visits
FROM (SELECT user_id , count(*) as visits, r_id,
		RANK() OVER(PARTITION BY r_id ORDER BY count(*) DESC) as "ranks"
		FROM orders
		GROUP BY user_id , r_id
		ORDER BY count(*) DESC) t
JOIN users as u ON t.user_id = u.user_id    
JOIN restaurants as r ON r.r_id = t.r_id
WHERE ranks = 1    
ORDER BY r.r_id;

-- 5.Month over month revenue growth of a restaurant
SELECT r_id , MONTHNAME(date)as Month, sum(amount) AS sales,
		((SUM(amount) - LAG(SUM(amount)) OVER() ) /LAG(sum(amount)) OVER()) *100 as MOM_revenue
FROM orders
WHERE r_id = 1
GROUP BY r_id , MONTHNAME(date);

-- 6. Find the Most Paired Products that are ordered together

WITH ProductPairs AS (
    SELECT 
        o1.user_id, 
        f1.f_name AS product1, 
        f2.f_name AS product2, 
        COUNT(*) AS pair_count
    FROM orders AS o1
    JOIN order_details AS od1 ON o1.order_id = od1.order_id
    JOIN orders AS o2 ON o1.order_id = o2.order_id AND o1.user_id = o2.user_id
    JOIN order_details AS od2 ON o2.order_id = od2.order_id AND od1.f_id < od2.f_id
    JOIN food AS f1 ON f1.f_id = od1.f_id
    JOIN food AS f2 ON f2.f_id = od2.f_id
    GROUP BY o1.user_id, f1.f_name, f2.f_name
)
SELECT 
    u.name AS user_name, product1, product2, pair_count
    FROM ProductPairs
JOIN users AS u ON u.user_id = ProductPairs.user_id
ORDER BY pair_count DESC;
