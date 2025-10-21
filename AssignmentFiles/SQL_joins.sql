USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
select p.name as product_name , c.name as category_name, p.price
from products as p
left join categories as c
on p.category_id = c.category_id;
-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
select oi.order_id, o.order_datetime, s.name as store_name, p.name as product_name, oi.quantity, quantity * p.price as line_total
from order_items oi
left join orders o on oi.order_id = o.order_id
left join stores s on o.store_id = s.store_id
left join products p on oi.product_id = p.product_id
order by order_datetime, order_id;
-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
select concat(c.first_name, ' ', c.last_name) as customer_name, s.name as store_name, o.order_datetime, sum(quantity * p.price) as order_total 
from order_items oi 
join orders o on oi.order_id = o.order_id and o.status = 'paid' 
join customers c on o.customer_id = c.customer_id 
join stores s on o.store_id = s.store_id 
join products p on oi.product_id = p.product_id 
group by customer_name, store_name, order_datetime;
-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
select c.first_name, c.last_name, c.city, c.state
from customers c
left join orders o on c.customer_id = o.customer_id and o.order_id is null;
-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
with products_sold as (select s.name as store_name, p.name as product_name, sum(oi.quantity) as total_units
from order_items oi
join orders o on oi.order_id = o.order_id and o.status = 'paid'
join stores s on o.store_id = s.store_id
join products p on oi.product_id = p.product_id
group by s.name, p.name),
ranked as (select store_name, product_name, total_units,
rank() over (partition by store_name	
order by total_units desc, product_name asc) as r
from products_sold)
select store_name, product_name, total_units
from ranked
where r = 1
order by store_name;
-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
select s.name as store_name, p.name as product_name, i.on_hand
from stores s
join inventory i on s.store_id = i.store_id and on_hand < 12
join products p on i.product_id = p.product_id;
-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
select concat(e.first_name, ' ', e.last_name) as manager_name, e.hire_date
from stores s 
join employees e on s.store_id = e.store_id and e.title = 'Manager'
order by e.store_id;
-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
with product_revenue as (select p.name as product_name, sum(oi.quantity * p.price) as total_revenue
from order_items oi
join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id 
where o.status = 'paid'
group by p.name),
average_revenue as (select avg(total_revenue) as avg_revenue
from product_revenue)
select pr.product_name, pr.total_revenue
from product_revenue pr, average_revenue ar
where pr.total_revenue > ar.avg_revenue
order by pr.total_revenue desc;
-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
select c.customer_id, date(max(o.order_datetime)) as last_paid_order_date
from customers c
left join orders o on c.customer_id = o.customer_id
and status = 'paid'
group by customer_id;
-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
select s.name as store_name, c.name as category_name, sum(oi.quantity) as total_units, sum(oi.quantity * p.price) as total_revenue
from order_items oi
join orders o on oi.order_id = o.order_id and o.status = 'paid'
join stores s on o.store_id = s.store_id
join products p on oi.product_id = p.product_id
join categories c on c.category_id = p.category_id
group by s.name, c.name
order by s.name, c.name;