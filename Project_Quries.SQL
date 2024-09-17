CREATE DATABASE PIZZA_PROJECT1
SELECT * FROM [PIZZA_PROJECT1].[dbo].[order_details]
select * FROM [PIZZA_PROJECT1].[dbo].[pizza_types]
SELECT * FROM [PIZZA_PROJECT1].[dbo].[orders]
SELECT * FROM [PIZZA_PROJECT1].[dbo].[pizzas]
--Questions
--Basic:
--Retrieve the total number of orders placed.
--Calculate the total revenue generated from pizza sales.
--Identify the highest-priced pizza.
--Identify the most common pizza size ordered.
--List the top 5 most ordered pizza types along with their quantities.
--Intermediate:
--Find the total quantity of each pizza category ordered (this will help us 
--to understand the category which customers prefer the most).
--Determine the distribution of orders by hour of the day (at which time the orders are maximum (for inventory management and resource allocation).
--Find the category-wise distribution of pizzas (to understand customer behaviour).
--Group the orders by date and calculate the average number of pizzas ordered per day.
--Determine the top 3 most ordered pizza types based on revenue (let's see the revenue wise pizza orders to understand from sales perspective which pizza is the best selling)
--Advanced:
--Calculate the percentage contribution of each pizza type to total revenue (to understand % of contribution of each pizza in the total revenue)
--Analyze the cumulative revenue generated over time.
--Determine the top 3 most ordered pizza types based on revenue for each pizza category (In each category which pizza is the most selling)

-- Retrieve the total number of orders placed.
SELECT COUNT(ORDER_ID) FROM PIZZA_PROJECT1.dbo.ORDERS

SELECT ORDER_DETAILS.PIZZA_ID ,ORDER_DETAILS.QUANTITY ,PIZZAS.PRICE FROM PIZZA_PROJECT1.dbo.order_details
JOIN PIZZA_PROJECT1.dbo.pizzas ON pizzas.pizza_id=order_details.pizza_id

--total revenue generated from pizza sales.
SELECT CAST(SUM(ORDER_DETAILS.QUANTITY * PIZZAS.PRICE)AS DECIMAL(10,2)) AS Total_revenue_generated FROM PIZZA_PROJECT1.dbo.order_details
JOIN PIZZA_PROJECT1.dbo.pizzas ON pizzas.pizza_id=order_details.pizza_id

--Identify the highest-priced pizza.
SELECT TOP 1 PIZZA_TYPES.pizza_type_id,CAST(pizzas.price AS decimal(10,2)) FROM PIZZA_PROJECT1.dbo.pizzas JOIN PIZZA_PROJECT1.dbo.pizza_types
ON pizza_types.pizza_type_id=pizzas.pizza_type_id ORDER BY price DESC
--OR
SELECT TOP 1 pizza_type_id,price FROM PIZZA_PROJECT1.dbo.pizzas ORDER BY price DESC

--Identify the most common pizza size ordered.
select top 1 pizzas.size,COUNT(order_details.order_details_id) as order_count 
from pizzas join order_details on pizzas.pizza_id
=order_details.pizza_id group by pizzas.size order by order_count desc

--List the top 5 most ordered pizza types along with their quantities.
select TOP 5 pizza_types.name,SUM(order_details.quantity)AS QUANTITY FROM pizzas JOIN pizza_types 
ON PIZZAS.pizza_type_id=pizza_types.pizza_type_id JOIN 
order_details ON order_details.pizza_id=pizzas.pizza_id
GROUP BY pizza_types.name ORDER BY QUANTITY DESC
--Intermediate:
--Find the total quantity of each pizza category ordered (this will help us to understand the category which customers prefer the most).
SELECT CATEGORY,SUM(order_details.quantity) AS QUANTITY FROM pizza_types JOIN pizzas ON 
pizzas.pizza_type_id=pizza_types.pizza_type_id JOIN order_details ON order_details.pizza_id=pizzas.pizza_id
GROUP BY category ORDER BY quantity DESC

--Determine the distribution of orders by hour of the day (at which time the orders are maximum (for inventory management and resource allocation).
SELECT DATEPART(HOUR,TIME) AS HOUR_DAY ,COUNT(DISTINCT ORDER_ID) as ORDER_COUNT FROM orders 
GROUP BY DATEPART(HOUR,TIME) ORDER BY ORDER_COUNT DESC

--Find the category-wise distribution of pizzas (to understand customer behaviour).
SELECT CATEGORY,COUNT(NAME) FROM pizza_types GROUP BY category

--Group the orders by date and calculate the average number of pizzas ordered per day.
WITH CTE as ( 
SELECT orders.date,SUM(order_details.quantity) AS TOTAL_PIZZA_ORDERED FROM orders JOIN order_details
ON orders.order_id=order_details.order_id GROUP BY orders.date
)
SELECT AVG([TOTAL_PIZZA_ORDERED])AS [AVERAGE NUMBER OF PIZZAS PER DAY] FROM CTE
--Determine the top 3 most ordered pizza types based on revenue (let's see the revenue wise pizza orders to understand from sales perspective which pizza is the best selling)
SELECT TOP 3 pizza_types.name,SUM(order_details.quantity*pizzas.price) AS Revenue_from_pizza
from order_details
join pizzas  on pizzas.pizza_id=order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id=pizzas.pizza_type_id
group by pizza_types.name order by Revenue_from_pizza desc

--Advance:
--Calculate the percentage contribution of each pizza type to total revenue (to understand % of contribution of each pizza in the total revenue)
select pizza_types.name, 
concat(cast((sum(order_details.quantity*pizzas.price) /
(select sum(order_details.quantity*pizzas.price) 
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id 
))*100 as decimal(10,2)), '%')
as 'Revenue contribution from pizza'
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.name
order by [Revenue contribution from pizza] desc


-- Analyze the cumulative revenue generated over time.
--use of aggregate window function (to get the cumulative sum)
with cte as (
select date as 'Date', cast(sum(quantity*price) as decimal(10,2)) as Revenue
from order_details 
join orders on order_details.order_id = orders.order_id
join pizzas on pizzas.pizza_id = order_details.pizza_id
group by date
-- order by [Revenue] desc
)
select Date, Revenue, sum(Revenue) over (order by date) as 'Cumulative Sum'
from cte 
group by date, Revenue



-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with cte as (
select category, name, cast(sum(quantity*price) as decimal(10,2)) as Revenue
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by category, name
)
, cte1 as (
select category, name, Revenue,
rank() over (partition by category order by Revenue desc) as rnk
from cte 
)
select category, name, Revenue
from cte1 
where rnk in (1,2,3)
order by category, name, Revenue
