--TABLE CREATION--

CREATE TABLE retail_sales
(		transactions_id INT primary key,
		sale_date DATE,
		sale_time TIME,
		customer_id INT,
		gender VARCHAR (15),
		age INT,
		category VARCHAR(15),
		quantity INT,
		price_per_unit FLOAT,
		cogs FLOAT,
		total_sale FLOAT
);


--Checking the data
select * from retail_sales  
limit 10


-- DATA CLEANING --

--column typo fix
update retail_sales 
set quantity = quantiy
where quantity is null;

alter table retail_sales 
drop column quantiy


--Null checks
--num nulls better for readability and scalability
select * from retail_sales  
where num_nulls(transactions_id, sale_date, sale_time, gender, category, cogs) >0 

--deleting nulls
delete from retail_sales  
where num_nulls(transactions_id, sale_date, sale_time, gender, category, cogs) >0

-- DATA EXPLORATION --

--Total Sales
select count(*) as total_sales from retail_sales

--Total Unique Customers
select count(distinct (customer_id)) as Unique_customers from retail_sales

--Total Unique sale cateogries
select distinct category as sale_categories from retail_sales


-- BUSINESS ANALYSIS --

--Sales made on 2022-11-05
select * 
from retail_sales 
where sale_date = '2022-11-05'

--"Clothing" sales in Nov,2022 with quantity sold > 4
select *
from retail_sales
where 
category = 'Clothing'
and 
to_char(sale_date, 'yyyy-mm') = '2022-11'
and quantity >= 4

--Total Sales for each category
select category,
sum(total_sale) as net_sales,
count(*) as total_orders
from retail_sales
group by 1

--Average age of customers who purchased from "Beauty" category
select
round(avg(age)) as Average_age
from retail_sales 
where category = 'Beauty'

--Transactions where total sales > 1000
select * from retail_sales 
where total_sale >1000

--Total no. of transactions by each gender for each category
select 
category,
gender,
count(*) as total_transactions
from retail_sales 
group by category, gender
order by 1

--Average sale for each month, and best selling month

select year,
month,
avg_sales
from 
(
select
extract(year from sale_date) as year,
extract(month from sale_date) as month,
avg(total_sale) as avg_sales,
rank() over(partition by extract(year from sale_date) order by avg(total_sale) desc) as rank --window function to find the best sales
from retail_sales
group by 1, 2
) as avg_sales_month
where rank = 1

--Top 5 customers based on highest total sales

select 
customer_id,
sum(total_sale) as total_sales
from retail_sales 
group by 1
order by 2 desc
limit 5

--No. of customers with items purchased from each category
select 
count(distinct customer_id) as unique_cusomters,
category
from retail_sales 
group by category

--Create shifts and no. of orders
--Shifts:
--Morning <12:00, 
--Afternoon <=12:00 and 17:00>,
--Evening >17:00

with shift_sales -- CTE to group and count
as
(
select *,
case
	when extract(hour from sale_time) < 12 then 'Morning'
	when extract(hour from sale_time) Between 12 and 17 then 'Afternoon'
	else 'Evening'
end as Shifts
from retail_sales
)
select 
shifts,
count(*) as total_orders
from shift_sales
group by shifts

