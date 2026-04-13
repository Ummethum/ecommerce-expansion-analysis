USE magist;

-- 1. How many orders are there in the dataset?

SELECT count(*)
FROM orders;

-- 2. Are orders actually delivered?

SELECT count(*)
FROM orders
WHERE order_status = "delivered";

-- 3. Is Magist having user growth?
-- by orders placed

SELECT YEAR(order_purchase_timestamp) AS y, MONTH(order_purchase_timestamp) AS m, count(*)
FROM orders
GROUP BY y, m
ORDER BY y, m ASC;

-- by revenue

SELECT YEAR(order_purchase_timestamp) AS y, MONTH(order_purchase_timestamp) AS m, ROUND(SUM(price))
FROM order_items
LEFT JOIN orders USING(order_id)
GROUP BY y, m
ORDER BY y, m ASC;


-- 4. How many products are there in the products table?

SELECT count(*) FROM products;

-- 32951

-- 5. Which are the categories with most products?

SELECT count(*), pc.product_category_name_english
FROM products as s
	LEFT JOIN product_category_name_translation AS pc USING(product_category_name)
GROUP BY s.product_category_name
ORDER BY count(*) DESC;

-- 6. How many of those products were present in actual transactions?

SELECT count(DISTINCT(product_id)), pc.product_category_name_english
FROM products as s
	LEFT JOIN product_category_name_translation as pc USING(product_category_name)
    LEFT JOIN order_items USING(product_id)
    LEFT JOIN orders as o USING(order_id)
WHERE o.order_status = "delivered"
GROUP BY s.product_category_name
ORDER BY count(DISTINCT(product_id)) DESC;

-- 7. What’s the price for the most expensive and cheapest products?

SELECT 
    AVG(price), product_id
FROM
    products AS s
        INNER JOIN
    order_items AS o USING (product_id)
GROUP BY product_id
ORDER BY AVG(price) DESC;

-- 8. What are the highest and lowest payment values?

SELECT 
    round(sum(payment_value)), order_id
FROM
    orders AS o
        LEFT JOIN
    order_payments AS op USING (order_id)
GROUP BY order_id
ORDER BY sum(payment_value) ASC;



