use chinook;
select * from album;
-- Qbjective question NO.1
-- Does any table have missing values or duplicates? If yes how would you handle it ?
-- Solution 
-- so lets check the missing values or duplicates in each and every table
-- first in album table
SELECT title, artist_id,  COUNT(*) AS duplicate_count
FROM album
GROUP BY title, artist_id
HAVING COUNT(*) > 1;


-- in artist table
SELECT * FROM artist WHERE name IS NULL; -- for missing values 
SELECT name, COUNT(*) FROM artist GROUP BY name HAVING COUNT(*) > 1; -- for duplicate value

-- in customer table 

SELECT * FROM customer WHERE address IS NULL OR city IS NULL; -- for missing values 
SELECT email, COUNT(*) FROM customer GROUP BY email HAVING COUNT(*) > 1; -- for duplicate value 

-- in employee Table

SELECT * FROM employee WHERE reports_to IS NULL; -- for missing values 
UPDATE employee SET reports_to = 0 WHERE reports_to IS NULL; -- update missing value 
SELECT email, COUNT(*) FROM employee GROUP BY email HAVING COUNT(*) > 1; -- for duplicate value 

-- in genre table

SELECT * FROM genre WHERE name IS NULL;
UPDATE genre SET name = 'Unknown' WHERE name IS NULL; -- for missing value
SELECT name, COUNT(*) FROM genre GROUP BY name HAVING COUNT(*) > 1; -- for duplicate value 

-- in invoice table
SELECT * FROM invoice WHERE billing_address IS NULL; -- for missing value

-- invoice_line Table
SELECT invoice_id, track_id, COUNT(*)
FROM invoice_line
GROUP BY invoice_id, track_id
HAVING COUNT(*) > 1; -- for duplicate value 

select * from invoice_line; 
-- there are having the duplicate number because from one invoice_id and from one track_id 
-- there we can track multiple purchese from one track_id and there can be multiple purchese from one invoice_id

-- media_type Table

SELECT * FROM media_type WHERE name IS NULL; -- for missing value
SELECT name, COUNT(*) FROM media_type GROUP BY name HAVING COUNT(*) > 1; -- for duplicate value 

-- playlist Table
SELECT * FROM playlist WHERE name IS NULL; -- for missing value
SELECT name, COUNT(*) FROM playlist GROUP BY name HAVING COUNT(*) > 1; -- for duplicate value 

-- playlist_track Table
SELECT playlist_id, track_id, COUNT(*)
FROM playlist_track
GROUP BY playlist_id, track_id
HAVING COUNT(*) > 1; -- for duplicate value 

-- track Table
SELECT * FROM track WHERE album_id IS NULL;

SELECT name, album_id, media_type_id, COUNT(*)
FROM track
GROUP BY name, album_id, media_type_id
HAVING COUNT(*) > 1;

-- in one album_id or in one media_type_id there can be a mutiple name 
-- or by one person name there can be mutiple tracks, album_id or media_type_id

-- Qbjective question No 2
-- Find the top-selling tracks and top artist in the USA and identify their most famous genres.
-- Ans-: 

SELECT i.invoice_id
    FROM invoice i
    WHERE i.billing_country = 'USA';
    
    -- Step 1: Find invoices in the USA
WITH usa_invoices AS (
    SELECT i.invoice_id
    FROM invoice i
    WHERE i.billing_country = 'USA'
),

-- Step 2: Calculate total sales per track for USA invoices
track_sales AS (
    SELECT 
        il.track_id,
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM invoice_line il
    JOIN usa_invoices ui ON il.invoice_id = ui.invoice_id
    GROUP BY il.track_id
),

-- Step 3: Get top-selling tracks and their details
top_tracks AS (
    SELECT 
        t.track_id,
        t.name AS track_name,
        a.artist_id,
        ar.name AS artist_name,
        g.genre_id,
        g.name AS genre_name,
        ts.total_sales
    FROM track_sales ts
    JOIN track t ON ts.track_id = t.track_id
    JOIN album a ON t.album_id = a.album_id
    JOIN artist ar ON a.artist_id = ar.artist_id
    JOIN genre g ON t.genre_id = g.genre_id
    ORDER BY ts.total_sales DESC
    LIMIT 10 -- top 10 tracks
),

-- Step 4: Identify the top artist and their most popular genre in the USA
top_artist_genre AS (
    SELECT 
        ar.artist_id,
        ar.name AS artist_name,
        g.genre_id,
        g.name AS genre_name,
        SUM(ts.total_sales) AS artist_total_sales
    FROM track_sales ts
    JOIN track t ON ts.track_id = t.track_id
    JOIN album a ON t.album_id = a.album_id
    JOIN artist ar ON a.artist_id = ar.artist_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY ar.artist_id, g.genre_id
    ORDER BY artist_total_sales DESC
    LIMIT 1 -- top artist
)

-- Step 5: Display the results
SELECT 
    'Top Tracks' AS category,
    tt.track_name,
    tt.artist_name,
    tt.genre_name,
    tt.total_sales
FROM top_tracks tt

UNION ALL

SELECT 
    'Top Artist' AS category,
    NULL AS track_name,
    tg.artist_name,
    tg.genre_name,
    tg.artist_total_sales AS total_sales
FROM top_artist_genre tg;

-- finding top selling genre in USA
select Top_Genre from 
(
select g.name as Top_Genre
from track t
left join invoice_line il on il.track_id = t.track_id
left join invoice i on i.invoice_id = il.invoice_id
left join genre g on t.genre_id = g.genre_id
where i.billing_country = 'USA'
group by g.name
order by sum(il.quantity) desc
limit 10
) sub_table;

-- Qbjective question NO.3
-- What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
-- Ans;

select * from customer; 

SELECT 
    country,
    COUNT(customer_id) AS customer_count
FROM customer
GROUP BY country
ORDER BY customer_count DESC;

-- Qbjective question NO.4
-- Calculate the total revenue and number of invoices for each country, state, and city:
-- Ans 


SELECT 
    billing_country AS country,
    billing_state AS state,
    billing_city AS city,
    COUNT(invoice_id) AS number_of_invoices,
    SUM(total) AS total_revenue
FROM 
    invoice
GROUP BY 
    billing_country, 
    billing_state, 
    billing_city
ORDER BY 
    total_revenue DESC;

-- Qbjective question NO.5
-- Find the top 5 customers by total revenue in each country
-- Ans 

WITH CustomerRevenue AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.country,
        SUM(i.total) AS total_revenue
    FROM 
        customer AS c
    JOIN 
        invoice AS i ON c.customer_id = i.customer_id
    GROUP BY 
        c.customer_id, c.country
),

RankedCustomers AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        country,
        total_revenue,
        RANK() OVER (PARTITION BY country ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        CustomerRevenue
)

SELECT 
    customer_id,
    first_name,
    last_name,
    country,
    total_revenue
FROM 
    RankedCustomers
WHERE 
    revenue_rank <= 5
ORDER BY 
    country, total_revenue DESC;


    
-- Qbjective question NO.6
-- Identify the top-selling track for each customer
-- Ans 

WITH CustomerTrackSales AS (
    SELECT 
        i.customer_id,
        t.track_id,
        t.name AS track_name,
        SUM(il.quantity) AS total_quantity_sold
    FROM 
        invoice_line AS il
    JOIN 
        invoice AS i ON il.invoice_id = i.invoice_id
    JOIN 
        track AS t ON il.track_id = t.track_id
    GROUP BY 
        i.customer_id, t.track_id
),

TopTracks AS (
    SELECT 
        customer_id,
        track_name,
        total_quantity_sold,
        RANK() OVER (PARTITION BY customer_id ORDER BY total_quantity_sold DESC) AS track_rank
    FROM 
        CustomerTrackSales
)

SELECT 
    customer_id,
    track_name AS top_selling_track,
    total_quantity_sold
FROM 
    TopTracks
WHERE 
    track_rank = 1
ORDER BY 
    customer_id;
    
-- Qbjective question NO.7
-- Are there any patterns or trends in customer purchasing behavior (e.g., frequency of purchases, preferred payment methods, average order value)?
-- Ans 

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country,
    COUNT(i.invoice_id) AS number_of_purchases
FROM 
    customer AS c
JOIN 
    invoice AS i ON c.customer_id = i.customer_id
GROUP BY 
    c.customer_id
ORDER BY 
    number_of_purchases DESC; -- number of purchases by customer


select customer_id, avg(total) as avg_order_value, count(invoice_id)as num_of_orders
from invoice
group by customer_id
order by count(invoice_id),avg(total); -- avg.order values and number of order

select count(invoice_id) as daily_invoice_count, extract(YEAR_MONTH from invoice_date), avg(total) as monthly_avg_total, sum(total) as monthly_sum_total
from invoice
group by extract(YEAR_MONTH from invoice_date)
order by extract(YEAR_MONTH from invoice_date);
-- daily invoices and monthly sum totals


-- Qbjective question NO.8
-- What is the customer churn rate?
-- Ans 

-- Total Number of Customers

SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM customer;

-- Number of Active Customers
select * from invoice;

SELECT COUNT(DISTINCT customer_id) AS active_customers
FROM invoice
WHERE DATE(invoice_date) >= '2020-12-30';

-- Number of Churned Customers
SELECT COUNT(DISTINCT c.customer_id) AS churned_customers
FROM customer c
WHERE c.customer_id NOT IN (
    SELECT DISTINCT customer_id
    FROM invoice
    WHERE DATE(invoice_date) >= '2020-12-30'
);
-- now count the distinct customer by every year and churn customer by every year 
select count(distinct customer_id) as customer_count from invoice
where invoice_date between '2018-01-01' and '2018-12-31' and customer_id not in
(select distinct customer_id from invoice
where invoice_date between '2017-01-01' and '2017-12-31');
-- customers churned in 2018

select count(distinct customer_id) as customer_count from invoice
where invoice_date between '2019-01-01' and '2019-12-31' and customer_id not in
(select distinct customer_id from invoice
where invoice_date between '2018-01-01' and '2018-12-31');
-- customers churned in 2019

select count(distinct customer_id) as customer_count from invoice
where invoice_date between '2020-01-01' and '2020-12-31' and customer_id not in
(select distinct customer_id from invoice
where invoice_date between '2019-01-01' and '2019-12-31');
-- customers churned in 2020

select count(distinct customer_id) from invoice
where invoice_date between '2017-01-01' and '2017-12-31';
-- customers in 2018


select count(distinct customer_id) from invoice
where invoice_date between '2018-01-01' and '2018-12-31';
-- customers in 2019


select count(distinct customer_id) from invoice
where invoice_date between '2019-01-01' and '2019-12-31';
-- customers in 2020

with first_three_months as 
(
select count(customer_id) as customer_count from invoice
where invoice_date between '2017-01-01' and '2017-03-31'
),
last_three_months as
(
select count(customer_id) as customer_count from invoice
where invoice_date between '2017-10-01' and '2017-12-31' 
) 
select ((first3.customer_count)-(last3.customer_count))/(first3.customer_count) * 100 as churn_rate
from first_three_months as first3,last_three_months as last3;
-- Churn Rate in 2017

with first_three_months as 
(
select count(customer_id) as customer_count from invoice
where invoice_date between '2018-01-01' and '2018-03-31'
),
last_three_months as
(
select count(customer_id) as customer_count from invoice
where invoice_date between '2018-10-01' and '2018-12-31' 
) 
select ((first3.customer_count)-(last3.customer_count))/(first3.customer_count) * 100 as churn_rate
from first_three_months as first3,last_three_months as last3;

-- churn rate in 2018

with first_three_months as 
(
select count(customer_id) as customer_count from invoice
where invoice_date between '2019-01-01' and '2019-03-31'
),
last_three_months as
(
select count(customer_id) as customer_count from invoice
where invoice_date between '2019-10-01' and '2019-12-31' 
) 
select ((first3.customer_count)-(last3.customer_count))/(first3.customer_count) * 100 as churn_rate
from first_three_months as first3,last_three_months as last3;

-- churn rate in 2019

with first_three_months as 
(
select count(customer_id) as customer_count from invoice
where invoice_date between '2020-01-01' and '2020-03-31'
),
last_three_months as
(
select count(customer_id) as customer_count from invoice
where invoice_date between '2020-10-01' and '2020-12-31' 
) 
select ((first3.customer_count)-(last3.customer_count))/(first3.customer_count) * 100 as churn_rate
from first_three_months as first3,last_three_months as last3;

-- churn rate in 2020.

-- Qbjective question NO.9
-- Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.
-- Ans

select * from genre; 

SELECT 
    g.name AS genre_name,
    i.billing_state AS region_state,
    SUM(il.unit_price * il.quantity) AS genre_sales
FROM invoice i
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY g.name, i.billing_state
ORDER BY region_state, genre_sales DESC; -- by this qurey i check all genre sales in USA.
 -- now i am Calculating the percentage of total sales contributed by each genre in the USA 
 -- and identify the best-selling genres and artists.
WITH GenreSalesUSA AS (
    SELECT 
        g.name AS genre_name,
        SUM(il.unit_price * il.quantity) AS genre_sales
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    WHERE i.billing_country = 'USA'
    GROUP BY g.name
),
TotalSalesUSA AS (
    SELECT 
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    WHERE i.billing_country = 'USA'
),
ArtistGenreSales AS (
    SELECT 
        g.name AS genre_name,
        ar.name AS artist_name,
        SUM(il.unit_price * il.quantity) AS artist_genre_sales,
        ROW_NUMBER() OVER (PARTITION BY g.genre_id ORDER BY SUM(il.unit_price * il.quantity) DESC) AS artist_rank
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN album al ON t.album_id = al.album_id
    JOIN artist ar ON al.artist_id = ar.artist_id
    JOIN genre g ON t.genre_id = g.genre_id
    WHERE i.billing_country = 'USA'
    GROUP BY g.name, ar.name, g.genre_id
)

SELECT 
    gs.genre_name,
    gs.genre_sales,
    ROUND((gs.genre_sales / ts.total_sales) * 100, 2) AS percentage_of_total_sales,
    ags.artist_name AS best_selling_artist
FROM GenreSalesUSA gs
JOIN TotalSalesUSA ts ON 1=1
LEFT JOIN ArtistGenreSales ags ON gs.genre_name = ags.genre_name AND ags.artist_rank = 1
ORDER BY gs.genre_sales DESC;


-- Qbjective question NO.10
-- Find customers who have purchased tracks from at least 3 different genres
-- Ans 

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT g.genre_id) AS genre_count
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT g.genre_id) >= 3
ORDER BY genre_count DESC;

-- Objective question NO.11
-- Rank genres based on their sales performance in the USA
-- Ans 

SELECT 
    g.name AS genre_name,
    SUM(il.unit_price * il.quantity) AS total_sales,
    RANK() OVER (ORDER BY SUM(il.unit_price * il.quantity) DESC) AS genre_rank
FROM invoice i
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY g.genre_id, g.name
ORDER BY genre_rank;

-- Objective question NO.12
-- Identify customers who have not made a purchase in the last 3 months
-- Ans

select * from invoice;

select first_name, last_name from customer c
left join (
select * 
from invoice
where invoice_date > (select max(invoice_date) from invoice) - interval 3 month) prev_3_months
on prev_3_months.customer_id = c.customer_id
where invoice_id is null;

---------------------------------------------------------------------
---------------------------------------------------------------------

-- Subjective Questions 

-- Q1 Recommend the three albums from the new record label that should be prioritised 
-- for advertising and promotion in the USA based on genre sales analysis.
-- Ans;
select * from track order by album_id,genre_id; -- an album have songs with same/single genre
select genre_id from genre where name = 'Rock'; -- genre_id = 1 for Rock

with cte as(
select sum(i.total) as total_revenue, t.album_id
from invoice i left join invoice_line il on il.invoice_id = i.invoice_id
left join track t on t.track_id = il.track_id
where i.billing_country = 'USA' and t.genre_id = 1
group by t.album_id
order by total_revenue desc
)
select a.title, a.album_id from album a
left join cte on cte.album_id = a.album_id
order by cte.total_revenue desc limit 3;

-- Q2. Determine the top-selling genres in countries 
-- other than the USA and identify any commonalities or differences.
-- Ans;
SELECT Top_Genre FROM 
(
select g.name as Top_Genre
from track t
left join invoice_line il on il.track_id = t.track_id
left join invoice i on i.invoice_id = il.invoice_id
left join genre g on t.genre_id = g.genre_id
where i.billing_country != 'USA'
group by g.name
order by sum(il.quantity) desc
limit 10
) sub_table;

-- Q3. Customer Purchasing Behavior Analysis: How do the purchasing habits 
-- (frequency, basket size, spending amount)
-- of long-term customers differ from those of new customers?
-- What insights can these patterns provide about customer loyalty and retention strategies?
-- Ans;

WITH cte as
(
select i.customer_id, max(invoice_date) as last_purchase_date, min(invoice_date) as first_purchase_date,
 sum(total) as total_spent, sum(quantity) as items_bought, count(i.customer_id) as frequency,
 abs(timestampdiff(day, max(invoice_date), min(invoice_date))) as customer_since_days
from invoice i
left join invoice_line il on il.invoice_id = i.invoice_id
left join customer c on c.customer_id = i.customer_id
group by i.customer_id
),
long_short_term as
(
SELECT total_spent, items_bought, frequency,
case
when customer_since_days>(select avg(customer_since_days) as average_days from cte) then 'Long Term'
else 'Short Term' end term
from cte
)
select term, sum(total_spent),sum(items_bought),count(frequency) as number_of_customers from long_short_term group by term;

 -- Q4. Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased 
 -- together by customers? How can this information guide product recommendations and cross-selling initiatives?
 -- Ans;
 select * from invoice_line;


select il.invoice_id,g.name
from invoice_line il
left join track t on t.track_id = il.track_id
left join genre g on  g.genre_id = t.genre_id
group by il.invoice_id,g.name;
-- different genres purchased over an invoice

select il.invoice_id, al.title
from invoice_line il
left join track t on t.track_id = il.track_id
left join album al on  al.album_id = t.album_id
group by il.invoice_id, al.title;
-- different albums purchased over an invoice

select il.invoice_id,a.name 
from invoice_line il 
left join track t on t.track_id = il.track_id
left join album al on  al.album_id = t.album_id
left join artist a on a.artist_id = al.artist_id
group by il.invoice_id,a.name ;
-- different artists prefered in a single invoice

 
-- Q5. Regional Market Analysis: Do customer purchasing behaviors and churn rates 
-- vary across different geographic regions or store locations?
-- How might these correlate with local demographic or economic factors?
-- Ans;
with first_six_months as
(
select billing_country, COUNT(customer_id) counter from invoice
where invoice_date between '2017-01-01' and '2017-06-30'
group by billing_country
),
last_six_months as
(
select billing_country, COUNT(customer_id) counter from invoice
where invoice_date between '2020-07-01' and '2020-12-31' 
group by billing_country
)
select f6.billing_country, (f6.counter - coalesce(l6.counter,0))/f6.counter * 100 churn_rate from first_six_months f6
left join  last_six_months l6 on f6.billing_country = l6.billing_country;

-- Q6.Customer Risk Profiling: Based on customer profiles 
-- (age, gender, location, purchase history),which customer segments are more likely to churn or 
-- pose a higher risk of reduced spending? What factors contribute to this risk?
-- Ans;
Select i.customer_id, concat(c.first_name, " ", c.last_name) as customer_name, i.billing_country,
sum(i.total) as total_spending, COUNT(i.invoice_id) as num_of_orders 
from invoice i
left join customer c on c.customer_id = i.customer_id
group by i.customer_id, concat(c.first_name, " ", c.last_name), i.billing_country
order by total_spending desc, num_of_orders desc;

-- Q7.Customer Lifetime Value Modelling: How can you leverage customer data (tenure, purchase history, engagement)
-- to predict the lifetime value of different customer segments? This could inform targeted marketing and loyalty program strategies.
-- Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?
-- Ans;
with cte as(select inv.customer_id,inv.billing_country,inv.invoice_date, concat(c.first_name,' ',c.last_name) as customer_name,inv.total as invoice_total
from invoice inv
left join customer c on c.customer_id = inv.customer_id
group by customer_id,2,3,inv.total
order by customer_name),
cte2 as(
select customer_id, sum(total) as LTV
from invoice
group by customer_id)
select cte.customer_id, cte.billing_country, cte.invoice_date, cte.customer_name,cte.invoice_total, cte2.LTV
from cte left join cte2 on cte.customer_id = cte2.customer_id
order by cte2.LTV desc,cte.customer_name, cte.invoice_date;

-- Q8. If data on promotional campaigns (discounts, events, email marketing) is available,
-- how could you measure their impact on customer acquisition, retention, and overall sales?
-- Ans;
select count(*) from track; -- counting total tracks available

select t.name
from track t
where t.track_id not in ( select il.track_id
from invoice_line il
left join invoice i on i.invoice_id = il.invoice_id
where i.invoice_date>='2020-07-01' and i.invoice_date<='2020-12-31');
--

select concat(c.first_name,' ',c.last_name) as full_name
from customer c
where c.customer_id not in (select distinct(customer_id)
from invoice
where invoice_date>='2020-07-01' and invoice_date<='2020-12-31');
-- Identifying customer that have not made any purchase in previous 6 months.


-- Q9. How would you approach this problem, if the objective and subjective questions weren't given?
-- Ans;
SELECT * from employee; -- 1 reports_to value is null for employee_id = 1
SELECT distinct * FROM employee; -- No duplicates

SELECT * FROM genre;
SELECT distinct * FROM genre; -- No duplicates

SELECT * FROM invoice;
SELECT distinct * FROM invoice; -- No duplicates

SELECT * FROM invoice_line;
SELECT distinct * FROM invoice_line; -- No duplicates

SELECT * FROM media_type;
SELECT distinct * FROM media_type; -- No duplicates

SELECT * FROM playlist;
SELECT distinct * FROM playlist; -- No duplicates

SELECT * FROM playlist_track;
SELECT distinct * FROM playlist_track;

SELECT * FROM track;
SELECT distinct * FROM track; -- No duplicates

select * from album;
select distinct * from album; -- No duplicates

SELECT * FROM artist;
SELECT distinct * FROM artist; -- No duplicates

SELECT * from customer;
SELECT distinct * FROM customer; -- No duplicates
SELECT COUNT(*) FROM customer;
-- WHERE fax is NULL; ( count = 47)
-- WHERE state is NULL;(count = 29)
-- WHERE company is NULL; (count = 49)
-- 47 fax, 29 state and 49 company values are null in the customer table
select sum(total) as yearly_revenue, extract(year from invoice_date)
from invoice
group by extract(year from invoice_date);
-- 1201.86	2017
-- 1147.41	2018
-- 1221.66	2019
-- 1138.50	2020

select customer_id, sum(total) as life_time_value from invoice
group by customer_id
order by life_time_value desc;

select billing_country, sum(total) as total_revenue from invoice
group by billing_country
order by total_revenue desc;

-- Q10. How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?
-- Ans;
Alter table Album add ReleaseYear int;


-- Q11. Chinook is interested in understanding the purchasing behavior of customers based on their 
-- geographical location. They want to know the average total amount spent by customers from each country, 
-- along with the number of customers and the average number of tracks purchased per customer. 
-- Write an SQL query to provide this information.
-- Ans;

with cte as(
select avg(total) Avg_total_amount_spent,
count(distinct customer_id) num_of_cust,
billing_country
from invoice i
left join invoice_line il on il.invoice_id = i.invoice_id
group by billing_country
),
cte2 as(
SELECT i.customer_id, sum(quantity) as quantity_purchased from invoice i
left join invoice_line il on il.invoice_id = i.invoice_id
group by i.customer_id
),
cte3 as(
select billing_country, avg(quantity_purchased) as avg_tracks_per_country
from invoice i
left join cte2 on cte2.customer_id = i.customer_id
group by billing_country
)
select * from cte
left join cte3 on cte3.billing_country = cte.billing_country;

-----------------------------------------------------------
-----------------------------------------------------------





