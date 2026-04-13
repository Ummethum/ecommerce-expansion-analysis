USE magist;

-- 1. What categories of tech products does Magist have?

SELECT count(*), pc.product_category_name_english
FROM products as p
	LEFT JOIN product_category_name_translation AS pc USING(product_category_name)
GROUP BY p.product_category_name
ORDER BY count(*) DESC;

/*
pc_gamer
tablets_printing_image
cine_photo
computers
audio
home_appliances_2
fixed_telephony
small_appliances
consoles_games
home_appliances
electronics
telephony
computers_accessories
auto
*/

-- 2. How many products of these tech categories have been sold (within the time window of the database snapshot)?
-- 2. What percentage does that represent from the overall number of products sold?

-- ALL products
SELECT count(DISTINCT(product_id))
FROM products as p
	LEFT JOIN product_category_name_translation as pc USING(product_category_name)
    LEFT JOIN order_items USING(product_id)
    LEFT JOIN orders as o USING(order_id)
WHERE o.order_status = "delivered";

-- 32216

-- ALL TECH
SELECT count(DISTINCT(product_id))
FROM products as p
	LEFT JOIN product_category_name_translation as pc USING(product_category_name)
    LEFT JOIN order_items USING(product_id)
    LEFT JOIN orders as o USING(order_id)
WHERE o.order_status = "delivered" AND pc.product_category_name_english IN ("pc_gamer", "tablets_printing_image", "cine_photo",
"computers", "audio", "home_appliances_2", "fixed_telephony", "small_appliances", "consoles_games", "home_appliances", 
"electronics", "telephony", "computers_accessories", "auto");

-- 6282, percentage total: 19.5 %

-- relevant TECH
SELECT count(DISTINCT(product_id))
FROM products as p
	LEFT JOIN product_category_name_translation as pc USING(product_category_name)
    LEFT JOIN order_items USING(product_id)
    LEFT JOIN orders as o USING(order_id)
WHERE o.order_status = "delivered" AND pc.product_category_name_english IN ("pc_gamer", "tablets_printing_image",
"computers", "electronics", "telephony", "computers_accessories");

-- 3260, percentage total: 10 %

-- 3. What’s the average price of the products being sold?

SELECT AVG(price)
FROM (
SELECT DISTINCT product_id, price
FROM products as p
	LEFT JOIN product_category_name_translation as pc USING(product_category_name)
    LEFT JOIN order_items USING(product_id)
    LEFT JOIN orders as o USING(order_id)
WHERE o.order_status = "delivered" AND pc.product_category_name_english IN ("pc_gamer", "tablets_printing_image",
"computers", "electronics", "telephony", "computers_accessories")
) AS distinct_product_price_table
;

-- 132.5 € (We sell at an average price of 540 € per item)

-- 4. Are expensive tech products popular? *

SELECT price_category, count(*) FROM (
SELECT 
    DISTINCT product_id, price,
    CASE
        WHEN price < 50 THEN 'cheap'
        WHEN price < 750 THEN 'medium'
        WHEN price >= 750 THEN 'expensive'
    END AS price_category
FROM products as p
	LEFT JOIN product_category_name_translation as pc USING(product_category_name)
    LEFT JOIN order_items USING(product_id)
    LEFT JOIN orders as o USING(order_id)
WHERE o.order_status = "delivered" AND pc.product_category_name_english IN ("pc_gamer", "tablets_printing_image",
"computers", "electronics", "telephony", "computers_accessories")
) AS distinct_product_price_table
GROUP BY price_category
;

-- Of all the tech products, only 132 are considered expensive (>750€), 2191 are medium (50-750€) and 2238 are cheap (<50 €)
-- only 818 of 49298 (1.7 %) ordered items were expensive

-- 5. How many months of data are included in the magist database?

SELECT count(*) FROM (
SELECT YEAR(order_purchase_timestamp) AS y, MONTH(order_purchase_timestamp) AS m, count(*)
FROM orders
GROUP BY y, m
ORDER BY y, m ASC
) AS orders_by_year_and_month;

-- 25 months

-- 6. How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?

SELECT count(*) FROM sellers;

-- There are 3095 sellers

SELECT count(DISTINCT seller_id)
FROM sellers as s
    LEFT JOIN order_items USING(seller_id)
    LEFT JOIN products USING(product_id)
    LEFT JOIN product_category_name_translation as pc USING(product_category_name)
    LEFT JOIN orders as o USING(order_id)
WHERE o.order_status = "delivered" AND pc.product_category_name_english IN ("pc_gamer", "tablets_printing_image",
"computers", "electronics", "telephony", "computers_accessories") 
;

-- there are 432 tech sellers (14.0 %)

-- 7. What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?

SELECT ROUND(SUM(oi.price)) AS total
FROM order_items oi
LEFT JOIN orders o USING(order_id)
WHERE o.order_status NOT IN ("unavailable", "canceled");


SELECT ROUND(SUM(oi.price)) AS total
FROM order_items oi
LEFT JOIN orders o USING(order_id)
LEFT JOIN products USING(product_id)
LEFT JOIN product_category_name_translation as pc USING(product_category_name)
WHERE o.order_status NOT IN ("unavailable", "canceled") AND pc.product_category_name_english IN ("pc_gamer", "tablets_printing_image",
"computers", "electronics", "telephony", "computers_accessories");


-- total amount by all sellers: 13,494,401 €
-- only tech items by tech sellers:  1,615,543 € 
-- this is  12.0 % of all revenue


-- 8. Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

-- average monthly income of all sellers: 13,494,401/3095/25 = 174 €
-- average monthly income of tech sellers: 1,615,543/432/25 = 150 €

-- 9. What’s the average time between the order being placed and the product being delivered?

SELECT AVG(delivery_time) FROM (
SELECT *, TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS delivery_time
FROM orders
WHERE order_status = "delivered"
) AS orders_with_delivery_time
;

-- 12.1 days average delivery time

-- average estimated delivery time

SELECT AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_estimated_delivery_date)) AS avg_est_delivery_time
FROM orders
WHERE order_status = "delivered"
;

-- 23.4 days average estimated delivery time

-- 10. How many orders are delivered on time vs orders delivered with a delay?

SELECT count(*), AVG(TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)) AS days_diff_delivered_est,
    CASE
        WHEN TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) > 0 THEN 0
        ELSE 1
    END AS order_on_time
FROM orders
WHERE order_status = "delivered"
GROUP BY order_on_time;

-- 89944 orders are delivered on time, 6534 have a delay, thats only 7.3 % of orders

-- 11. Is there any pattern for delayed orders, e.g. big products being delayed more often?


SELECT AVG(price) AS avg_price_items, order_id, order_estimated_delivery_date, order_delivered_customer_date
FROM orders
LEFT JOIN order_items USING(order_id)
WHERE order_status = "delivered"
GROUP BY order_id
;

SELECT count(*), order_on_time,
    CASE
        WHEN avg_price_items < 750 THEN 'cheap-medium'
        WHEN avg_price_items >= 750 THEN 'expensive'
    END AS price_category
FROM (
SELECT AVG(price) AS avg_price_items, order_id, order_estimated_delivery_date, order_delivered_customer_date,
	CASE
        WHEN TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) > 0 THEN 0
        ELSE 1
    END AS order_on_time
FROM orders
LEFT JOIN order_items USING(order_id)
WHERE order_status = "delivered"
GROUP BY order_id
) AS avg_price_per_item_per_order
GROUP BY order_on_time, price_category;

-- Does price have an influence? 8.4 % of orders with expensive items are delayed, 6.7 % of orders with cheap-medium priced items


