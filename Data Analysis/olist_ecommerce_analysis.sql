use olist_ecommerce;

-- What is the total number of orders by order status?
select order_status, count(*) as order_count from orders_clean group by order_status
order by order_count desc;
-- Most orders were delivered (96,478), while canceled and unavailable orders were relatively few,
-- indicating that the vast majority of orders in the dataset were successfully fulfilled.

-- How many orders were placed each month?
select date_format(order_purchase_timestamp,'%Y-%M')  as order_month,count(*) as order_count 
from orders_clean group by order_month order by order_count desc;
-- November 2017 recorded the highest order volume with 7,544 orders,
-- indicating that customer demand peaked during this month.

-- What is the total payment value generated each month?
select date_format(o.order_purchase_timestamp, '%Y-%M')  as order_month,
round(sum(p.payment_value),2) as total_payment_value
from orders_clean o inner join payment_clean as p on o.order_id=p.order_id group by order_month order by total_payment_value desc;
-- November 2017 generated the highest payment value at approximately 1.19 million,
-- aligning with the highest order volume recorded during the same month.

-- What is the Average Order Value (AOV)?
select round(sum(payment_value)/count(distinct order_id),2) from payment_clean;
-- The Average Order Value is approximately $160.99,
-- meaning customers paid about $161 per order on average.

-- Which payment methods are used most frequently?
select payment_type,count(*) as payment_count from payment_clean group by payment_type order by payment_count desc;
-- Credit card was the most frequently used payment method,
-- accounting for the majority of payment records in the dataset.

-- What percentage of total payment value comes from each payment method?
select payment_type,round(sum(payment_value),2) as total_payment_value,
round(sum(payment_value)*100/(select sum(payment_value) from payment_clean),
2) as payment_percentage from payment_clean group by payment_type order by payment_percentage desc;
-- Credit cards contributed the largest share of payment value at 78.34%,
-- followed by boleto at 17.92%, showing that credit cards were the dominant
-- payment method by both usage and total payment value.

-- Which product categories generate the highest sales?
select p.product_category_name,round(sum(oi.price),2) as total_sales from order_item_clean as oi left join product_clean as p
on oi.product_id=p.product_id group by p.product_category_name order by total_sales desc;
-- Beauty & Health generated the highest sales at approximately 1.26 million,
-- followed by Watches & Gifts and Bed, Bath & Table.
-- These categories were the strongest sales contributors in the dataset.

-- Which individual products generate the highest sales?
select product_id,round(sum(price),2) as total_sales from order_item_clean group by product_id order by total_sales desc limit 10; 
-- The top-selling product generated approximately 63,885 in sales,
-- while the next four products generated between approximately 43,026 and 54,730.
-- These products were among the strongest individual sales contributors in the dataset.

-- Which sellers generate the highest sales?
select seller_id,round(sum(price),2) as total_sales from order_item_clean group by seller_id order by total_sales desc limit 10;
-- A small number of sellers generated significantly higher sales than others.
-- The top seller contributed approximately 229,473 in sales,
-- indicating that revenue is concentrated among a few high-performing sellers.

-- How many unique customers are there?
select count(distinct customer_unique_id) as Total_Customer from customers_clean;
-- The dataset has 96,096 unique customers,
-- showing a large customer base during the period analyzed.

-- How many customers made more than one purchase?
select count(*) as repeat_customers from 
(select c.customer_unique_id  from customers_clean as c inner join orders_clean as oi on c.customer_id=oi.customer_id
group by c.customer_unique_id having count(distinct order_id)>1) as customer_orders;
-- The dataset has 2,997 repeat customers,
-- indicating that a smaller portion of customers made multiple purchases during the period analyzed.

 -- What percentage of customers are repeat customers?
select round( 
        count(*)*100.0/
       (select count(distinct customer_unique_id) from customers_clean),2
) 
as repeat_customers_percentage from 
(select c.customer_unique_id  from customers_clean as c inner join orders_clean as oi on c.customer_id=oi.customer_id
group by c.customer_unique_id having count(distinct order_id)>1) as customer_orders;
-- Repeat customers represent approximately 3.12% of the total customer base,
-- indicating that most customers made only one purchase during the period analyzed.
-- This suggests an opportunity to improve customer retention and encourage repeat purchases.

-- Which customer states generate the highest sales?
select customer_state,round(sum(oi.price),2) as total_sales from customers_clean as c inner join orders_clean as o
on c.customer_id=o.customer_id inner join order_item_clean as oi on oi.order_id=o.order_id group by customer_state order by total_sales desc;
-- Sao Paulo (SP) generated the highest sales at approximately 5.20 million,followed by Rio de Janeiro (RJ) and Minas Gerais (MG).
-- These states were the strongest contributors to sales in the dataset.

-- What is the average delivery time?
select round(avg(datediff(order_delivered_customer_date,order_purchase_timestamp))) as average_delivery_days from orders_clean where
order_delivered_customer_date is not null;
-- The average delivery time was approximately 12.09 days,
-- meaning customers received their orders in about 12 days on average.

-- What percentage of delivered orders were delivered late?
Select round(sum(
            CASE
                WHEN DATE(order_delivered_customer_date) > order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        )*100.0/COUNT(*),2) AS percentage_late_delivery
FROM orders_clean
Where TRIM(order_delivered_customer_date) <> '' and TRIM(order_estimated_delivery_date) <> '';
-- Approximately 6.77% of delivered orders were delivered late,
-- indicating that the majority of delivered orders reached customers
-- within their estimated delivery timeframe.

-- Business Question 16: What is the distribution of Early, On-Time, and Late deliveries?
select case
           when date(order_delivered_customer_date)< order_estimated_delivery_date
               then "Early"
           when date(order_delivered_customer_date) = order_estimated_delivery_date
			   then "On Time"
	       when date(order_delivered_customer_date)> order_estimated_delivery_date
           then "Late"
	   end as delivery_status, count(*) as order_count
from orders_clean where trim(order_delivered_customer_date) <> '' and trim(order_estimated_delivery_date) <> '' group by
  delivery_status order by order_count desc;
  -- Most delivered orders were delivered early (88,649),
-- while 6,535 orders were delivered late and 1,292 were delivered on time.
-- This indicates that the majority of orders reached customers before the estimated delivery date.

-- What is the average customer review score?
select round(avg(review_score),2) as average_review_score from review_clean order by average_review_score;
select count(*) as total_review from review_clean;
CREATE TABLE review_clean (
    review_id TEXT,
    order_id TEXT,
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

-- What percentage of reviews are positive, negative, and neutral?
select case
         when review_score>=4 then "Positive"
         when review_score = 3 then "Neutral"
         when review_score <= 2 then "Negative"
	   end as review_category,count(*) as review_count,
       round(count(*) * 100/ (select count(*) from review_clean),2) as percentage from review_clean
       group by review_category order by percentage desc;
-- Most reviews were positive (77.07%),
-- while 14.69% were negative and 8.24% were neutral.
-- This indicates an overall positive customer satisfaction level,
-- while the negative reviews highlight an area for further investigation.

-- Do late deliveries receive lower review scores?
select case
          when date(o.order_delivered_customer_date) < o.order_estimated_delivery_date
          then "Early"
          when date(o.order_delivered_customer_date) = o.order_estimated_delivery_date
          then "On Time"
          when date(o.order_delivered_customer_date) > o.order_estimated_delivery_date
          then "Late"
	   end as delivery_status,round(avg(r.review_score),2) as avg_review_score from orders_clean as o inner join
       review_clean as r on o.order_id=r.order_id where trim(o.order_delivered_customer_date) <> '' and
       trim(o.order_estimated_delivery_date) <> '' group by delivery_status order by avg_review_score desc;
-- Orders delivered early had an average review score of 4.29, compared with 4.03 for on-time deliveries and 2.27 for late deliveries.
-- This shows a clear association between delivery performance and customer review scores in the analyzed dataset.

-- Which product categories have the highest percentage of low-rated reviews?
select p.product_category_name,count(*) as total_review,
sum(case 
        when r.review_score<=2 then 1
        else 0
	end )as low_lated_review,
round(sum(case 
        when r.review_score<=2 then 1
        else 0
	end)*100.0/ count(*),2)  as low_rating_percentage from review_clean as r 
    inner join order_item_clean as oi on r.order_id=oi.order_id
    inner join product_clean as p on oi.product_id=p.product_id  
    group by p.product_category_name 
    order by low_rating_percentage desc;
-- Some product categories have a relatively high percentage of low-rated reviews.
-- However, categories with very few reviews can show high percentages based on a small sample size.
-- Therefore, low-rating percentage should be interpreted together with total review volume.

-- Which product categories have the most reviews?
select p.product_category_name,count(*) as total_review from review_clean as r inner join order_item_clean as oi on r.order_id=oi.order_id
inner join product_clean as p on oi.product_id=p.product_id group by p.product_category_name order by total_review desc;
-- Cama_mesa_banho received the highest number of reviews,
-- followed by beleza_saude and esporte_lazer.
-- These categories have higher customer review activity in the dataset

--  Which customer states have the highest Average Order Value?
select c.customer_state,round(sum(oi.price)/count(distinct o.order_id),2) as average_order_value from customers_clean as c
inner join orders_clean as o on c.customer_id=o.customer_id 
inner join order_item_clean as oi on o.order_id=oi.order_id group by customer_state order by average_order_value desc;
-- PB had the highest average order value among the customer states, indicating higher average spending per order in this state.
-- This comparison helps identify states with higher-value customer orders.

-- Which sellers have the highest total sales?
select oi.seller_id,round(sum(oi.price),2) as total_sales from order_item_clean as oi group by oi.seller_id order by total_sales desc; 	
-- This analysis identifies the top sellers by total sales value, helping highlight sellers who contribute the most to overall sales.																																																																																																														


    
    
       


