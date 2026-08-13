CREATE database supply_chain_db;
show databases;
use supply_chain_db;
SELECT COUNT(*) FROM staging_orders; 

SELECT COUNT(*) FROM data_dictionary;    
SELECT * FROM staging_orders LIMIT 10;   

SHOW COLUMNS FROM staging_orders;

DESCRIBE staging_orders;
DESCRIBE data_dictionary;
SHOW COLUMNS FROM data_dictionary;

ALTER TABLE staging_orders
ADD PRIMARY KEY (order_item_id);

-- Step 1: Primary keys require NOT NULL — fix that first
ALTER TABLE staging_orders
MODIFY COLUMN `Order Item Id` BIGINT NOT NULL;

-- Step 2: Now add the primary key, using backticks for the space in the name
ALTER TABLE staging_orders
ADD PRIMARY KEY (`Order Item Id`);


SELECT
    Market,
    `Order Region`,
    SUM(Sales) AS total_sales,
    SUM(`Order Profit Per Order`) AS total_profit
FROM staging_orders
GROUP BY Market, `Order Region`
ORDER BY total_sales DESC;

SELECT
    `Shipping Mode`,
    COUNT(*) AS total_orders,
    SUM(Late_delivery_risk) AS late_orders,
    ROUND(
        SUM(Late_delivery_risk) / COUNT(*) * 100,
        2
    ) AS late_delivery_rate
FROM staging_orders
GROUP BY `Shipping Mode`
ORDER BY late_delivery_rate DESC;


SELECT
    CONCAT(
        'ALTER TABLE staging_orders RENAME COLUMN `',
        COLUMN_NAME,
        '` TO `',
        REPLACE(COLUMN_NAME, ' ', '_'),
        '`;'
    ) AS rename_command
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'staging_orders'
  AND COLUMN_NAME LIKE '% %';

select product_name,
count(*) as total_count,
avg(order_profit_per_order) as average_profit
from staging_orders
group by product_name
order by average_profit desc
limit 10;



ALTER TABLE staging_orders
RENAME COLUMN `Type` TO transaction_type,
RENAME COLUMN `Days for shipping (real)` TO actual_shipping_days,
RENAME COLUMN `Days for shipment (scheduled)` TO scheduled_shipping_days,
RENAME COLUMN `Benefit per order` TO benefit_per_order,
RENAME COLUMN `Sales per customer` TO sales_per_customer,
RENAME COLUMN `Delivery Status` TO delivery_status,
RENAME COLUMN `Late_delivery_risk` TO late_delivery_risk,
RENAME COLUMN `Category Id` TO category_id,
RENAME COLUMN `Category Name` TO category_name,
RENAME COLUMN `Customer City` TO customer_city,
RENAME COLUMN `Customer Country` TO customer_country,
RENAME COLUMN `Customer Fname` TO customer_first_name,
RENAME COLUMN `Customer Id` TO customer_id,
RENAME COLUMN `Customer Lname` TO customer_last_name,
RENAME COLUMN `Customer Segment` TO customer_segment,
RENAME COLUMN `Customer State` TO customer_state,
RENAME COLUMN `Customer Street` TO customer_street,
RENAME COLUMN `Customer Zipcode` TO customer_zipcode,
RENAME COLUMN `Department Id` TO department_id,
RENAME COLUMN `Department Name` TO department_name,
RENAME COLUMN `Latitude` TO latitude,
RENAME COLUMN `Longitude` TO longitude,
RENAME COLUMN `Market` TO market,
RENAME COLUMN `Order City` TO order_city,
RENAME COLUMN `Order Country` TO order_country,
RENAME COLUMN `Order Customer Id` TO order_customer_id,
RENAME COLUMN `order date (DateOrders)` TO order_date,
RENAME COLUMN `Order Id` TO order_id,
RENAME COLUMN `Order Item Cardprod Id` TO order_item_cardprod_id,
RENAME COLUMN `Order Item Discount` TO order_item_discount,
RENAME COLUMN `Order Item Discount Rate` TO order_item_discount_rate,
RENAME COLUMN `Order Item Id` TO order_item_id,
RENAME COLUMN `Order Item Product Price` TO order_item_product_price,
RENAME COLUMN `Order Item Profit Ratio` TO order_item_profit_ratio,
RENAME COLUMN `Order Item Quantity` TO order_item_quantity,
RENAME COLUMN `Sales` TO sales,
RENAME COLUMN `Order Item Total` TO order_item_total,
RENAME COLUMN `Order Profit Per Order` TO order_profit_per_order,
RENAME COLUMN `Order Region` TO order_region,
RENAME COLUMN `Order State` TO order_state,
RENAME COLUMN `Order Status` TO order_status,
RENAME COLUMN `Product Card Id` TO product_card_id,
RENAME COLUMN `Product Category Id` TO product_category_id,
RENAME COLUMN `Product Name` TO product_name,
RENAME COLUMN `Product Price` TO product_price,
RENAME COLUMN `Product Status` TO product_status,
RENAME COLUMN `shipping date (DateOrders)` TO shipping_date,
RENAME COLUMN `Shipping Mode` TO shipping_mode;

select customer_segment,
count(distinct order_id) as total_orders,
avg(order_item_total) as average_orders
from staging_orders
group by customer_segment
order by total_orders desc;

select order_status,
round(count(*)*100/(select count(order_status) from staging_orders),2)as count_percentage
from staging_orders
group by order_status
order by count_percentage desc;

select category_name,
sum(sales) as total_sales
from staging_orders
group by category_name
order by total_sales desc
limit 1;

SHOW KEYS FROM staging_orders WHERE Key_name = 'PRIMARY';

select shipping_mode,
count(order_id) as total_order
from staging_orders
group by shipping_mode
order by total_order desc;

select order_region,
risk_percentage
from
(select order_region,
round( sum(Late_delivery_risk)*100/count(order_region),2) as risk_percentage
from staging_orders 
group by order_region) as late_delivery
group by order_region
order by risk_percentage desc;

select category_name,
avg(order_item_discount_rate) as average_order,
count(distinct order_item_id ) as total_order
from staging_orders
group by category_name
order by average_order desc;


select customer_segment,bad_count,
round( bad_count*100/status_count,2 ) as percentage
from
(select customer_segment,
count(order_status) as status_count,
sum( case 
	when order_status='CANCELED' or order_status='SUSPECTED_FRAUD'
	then 
	1
	else 
	0
end
) as bad_count
from staging_orders
group by customer_segment) as fraud_count
order by percentage desc;

SELECT order_status, COUNT(*)
FROM staging_orders
where order_status = 'CANCELED' or order_status = 'SUSPECTED_FRAUD'
GROUP BY order_status;


select shipping_mode,
avg(order_item_profit_ratio) as profit_ratio,
avg(scheduled_shipping_days)as scheduled_date,
avg(actual_shipping_days) as actual_days
from staging_orders
group by shipping_mode
order by profit_ratio desc;

with monthly_sales as(
select 
   DATE_FORMAT(order_date,'%Y-%m') as order_month,
   sum(sales) as total_sales
   from staging_orders
   group by order_month )
   select order_month,
   total_sales,
   sum(total_sales)over(order by order_month) as running_total
   from monthly_sales;
   
with monthly_sales as(
select 
   DATE_FORMAT(order_date,'%Y-%m') as order_month,
   sum(sales) as total_sales
   from staging_orders
   group by order_month ),
 sales_over_month as(
   select order_month,
   total_sales,
   lag(total_sales)over(order by order_month) as previous_month
   from monthly_sales)
   select order_month,
   total_sales,
   previous_month,
   round( (total_sales*100/previous_month),2) as percent
   from sales_over_month;


with sales_category as(
select customer_segment,
(select sum(sales) from staging_orders) as total_sales,
 sum(sales) as sales_category
 from staging_orders
 group by customer_segment)
 select customer_segment,
 sales_category,
 round( sales_category*100/total_sales,2)as sales_percent
 from sales_category
 order by sales_percent desc;

with region_sales as(
select order_region,
sum(sales) as sales_region,
sum(order_profit_per_order) as region_profit
from staging_orders
group by order_region)
select order_region,
region_profit,
sales_region,
dense_rank() over(order by region_profit desc) as ranking,
dense_rank() over(order by sales_region desc) as sales_rank
from region_sales;


WITH customer_order_dates AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order
    FROM staging_orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    first_order,
    last_order,
    DATEDIFF(last_order, first_order) AS day_gap,
    DENSE_RANK() OVER (ORDER BY DATEDIFF(last_order, first_order) DESC) AS gap_rank
FROM customer_order_dates
ORDER BY day_gap DESC;