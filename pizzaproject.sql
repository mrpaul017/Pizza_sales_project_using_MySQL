CREATE DATABASE pizza;
USE pizza;
CREATE TABLE orders (
order_id INT PRIMARY KEY,
date DATE NOT NULL,
time TIME NOT NULL
);
LOAD DATA LOCAL INFILE "C:/Users/tusha/Downloads/pizza_sales/pizza_sales/orders.csv" INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;
SELECT * FROM orders;

CREATE TABLE orders_details (
order_details_id INT PRIMARY KEY,	
order_id	INT NOT NULL,
pizza_id	TEXT NOT NULL,
quantity INT NOT NULL
);

LOAD DATA LOCAL INFILE "C:/Users/tusha/Downloads/pizza_sales/pizza_sales/order_details.csv" INTO TABLE orders_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;
SELECT * FROM orders_details;

-- ---------------------------Basic-----------------------------------
-- Retrieve the total number of orders placed.
SELECT COUNT(order_id) as total_orders from orders;

-- Calculate the total revenue generated from pizza sales.
SELECT 
ROUND(SUM(orders_details.quantity*pizzas.price),2) as total_revenue
FROM orders_details JOIN pizzas
ON pizzas.pizza_id = orders_details.pizza_id;

-- Identify the highest-priced pizza.
SELECT max(price) as expensive, pizza_type_id FROM pizzas
GROUP BY pizza_type_id
ORDER BY expensive DESC
LIMIT 1;

-- Identify the most common pizza size ordered.
SELECT pizzas.size, count(orders_details.order_details_id) as order_count
FROM pizzas JOIN orders_details
ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizzas.size 
ORDER BY order_count DESC LIMIT 1 ;

-- List the top 5 most ordered pizza types along with their quantities.
SELECT pizzas.pizza_type_id, SUM(orders_details.quantity) as item_count
FROM pizzas JOIN orders_details
ON pizzas.pizza_id=orders_details.pizza_id
GROUP BY pizza_type_id
ORDER BY item_count DESC LIMIT 5;

-- -----------------------Intermediate--------------------------------
-- Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT pizza_types.category ,
SUM(orders_details.quantity) as total_q
FROM pizza_types JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN orders_details
ON orders_details.pizza_id=pizzas.pizza_id
GROUP BY category
ORDER BY total_q ;

-- Determine the distribution of orders by hour of the day.
SELECT HOUR(time) as hour, COUNT(order_id) as no_orders
FROM orders
GROUP BY hour
ORDER BY no_orders DESC;

-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT pizza_types.category , SUM(orders_details.quantity) as total_counts
FROM pizza_types JOIN pizzas
ON pizza_types.pizza_type_id=pizzas.pizza_type_id
JOIN orders_details 
ON orders_details.pizza_id=pizzas.pizza_id
GROUP BY category
ORDER BY total_counts DESC;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT ROUND(AVG(quantity),0) FROM
(SELECT orders.date, SUM(orders_details.quantity) as quantity
FROM orders JOIN orders_details
ON orders.order_id=orders_details.order_id
GROUP BY date) as order_quantity;

-- Determine the top 3 most ordered pizza types based on revenue.
SELECT pizza_type_id, SUM(orders_details.quantity * pizzas.price) as revenue
FROM pizzas  JOIN orders_details
ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizza_type_id
ORDER BY revenue DESC LIMIT 3;

-- --------------------------Advanced---------------------------------------
-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT pizza_types.category, 
ROUND((SUM(orders_details.quantity*pizzas.price))/(SELECT 
ROUND(SUM(orders_details.quantity*pizzas.price),2) as total_revenue
FROM orders_details JOIN pizzas
ON pizzas.pizza_id = orders_details.pizza_id)*100,2) as revenue
FROM pizza_types JOIN pizzas
ON pizza_types.pizza_type_id=pizzas.pizza_type_id
JOIN orders_details
ON orders_details.pizza_id=pizzas.pizza_id
GROUP BY category 
ORDER BY revenue DESC;

-- Analyze the cumulative revenue generated over time.
SELECT date, 
SUM(revenue) over(order by date) as cum_revenue from 
(SELECT orders.date, SUM(orders_details.quantity*pizzas.price) as revenue
FROM orders_details JOIN pizzas
ON orders_details.pizza_id=pizzas.pizza_id
JOIN orders
ON orders.order_id=orders_details.order_id
GROUP BY date) as sales;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT name, revenue FROM
(SELECt category, name , revenue, RANK() OVER(partition by category order by revenue desc) as rn 
FROM
(SELECT pizza_types.category, pizza_types.name,
SUM(orders_details.quantity*pizzas.price ) as revenue
FROM pizza_types JOIN pizzas
ON pizza_types.pizza_type_id=pizzas.pizza_type_id
JOIN orders_details
ON orders_details.pizza_id=pizzas.pizza_id
GROUP BY pizza_types.category, pizza_types.name) as a)as b
WHERE rn<=3 ;


-- ----------------------------------------------------------------------------------