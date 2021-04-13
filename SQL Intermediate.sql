-- 1.  Joins ##

SELECT *
FROM facts
INNER JOIN cities ON cities.facts_id = facts.id
LIMIT 10;

-- 2.  Inner Join ##

SELECT c.* , f.name AS country_name
FROM cities AS c
INNER JOIN facts AS f ON f.id = c.facts_id
LIMIT 5;

-- 3. Practicing Inner Joins ##

SELECT f.name AS country, c.name AS capital_city 
FROM cities AS c
INNER JOIN facts AS f ON f.id = c.facts_id
WHERE c.capital = 1

-- 4. Left Joins ##

SELECT f.name AS country, f.population
FROM facts f
LEFT JOIN cities c ON c.facts_id = f.id
WHERE c.facts_id IS NULL

-- 6. Finding the Most Populous Capital Cities ##

SELECT c.name AS capital_city, f.name AS country , c.population AS population
FROM cities c
INNER JOIN facts f ON f.id = c.facts_id
WHERE capital = 1
ORDER BY population DESC
LIMIT 10;

-- 7. Combining Joins with Subqueries ##

SELECT c.name AS capital_city, f.name AS country , c.population AS population
FROM facts f
INNER JOIN (SELECT * FROM cities WHERE population > 10000000) AS c ON c.facts_id = f.id
WHERE capital = 1
ORDER BY population DESC

-- 8. Complex Query with Joins and Subqueries ##

SELECT f.name AS country, SUM(c.population) AS  urban_pop, f.population total_pop, CAST(SUM(c.population) AS FLOAT) / CAST(f.population AS FLOAT) AS urban_pct
FROM cities c
INNER JOIN facts f ON f.id = c.facts_id
GROUP BY country
HAVING urban_pct > 0.5
ORDER BY urban_pct 



--------------------------------------------------------------------------------------------------------------------------------



-- Joining Three Tables ##

SELECT t.track_id AS track_id,t.name AS track_name,m.name AS track_type,il.unit_price AS unit_price, il.quantity AS quantity
FROM invoice_line il
INNER JOIN track t ON t.track_id = il.track_id
INNER JOIN media_type m ON m.media_type_id = t.media_type_id
WHERE invoice_id = 4

-- Joining More Than Three Tables ##

SELECT t.track_id AS track_id,
       t.name AS track_name,
       a.name AS artist_name,
       m.name AS track_type,
       il.unit_price AS unit_price,
       il.quantity AS quantity
FROM invoice_line il
INNER JOIN track t ON t.track_id = il.track_id
INNER JOIN media_type m ON m.media_type_id = t.media_type_id
INNER JOIN album al ON al.album_id = t.album_id
INNER JOIN artist a ON a.artist_id = al.artist_id
WHERE invoice_id = 4

-- 4. Combining Multiple Joins with Subqueries ##

SELECT ti.title AS album,
       ti.name AS artist,
       COUNT(*) AS tracks_purchased 
FROM invoice_line il
INNER JOIN (SELECT t.track_id,
                   ar.name,
                   a.title
            FROM track t
            INNER JOIN album a ON a.album_id = t.album_id
            INNER JOIN artist ar ON ar.artist_id = a.artist_id) ti 
            ON ti.track_id = il.track_id
GROUP BY album
ORDER BY tracks_purchased DESC
LIMIT 5;

-- 5. Recursive Joins ##

SELECT (e1.first_name  || ' '|| e1.last_name) AS employee_name,
       e1.title AS employee_title,
       (e2.first_name || ' '|| e2.last_name) AS supervisor_name,
       e2.title AS supervisor_title
FROM employee e1
LEFT JOIN employee e2 ON e1.reports_to = e2.employee_id 
ORDER BY employee_name 
       

-- 6. Pattern Matching Using Like ##

SELECT  first_name,
        last_name,
        phone
FROM customer
WHERE first_name LIKE '%belle%'

-- 7. Revisiting CASE ##

SELECT  (first_name || ' ' || last_name) AS customer_name,
        COUNT(*) number_of_purchases,
        SUM(i.total) AS total_spent,
        CASE
            WHEN SUM(i.total) < 40 THEN 'small spender'
            WHEN SUM(i.total) > 100 THEN 'big spender'
            WHEN SUM(i.total) > 40 AND SUM(i.total) < 100 THEN 'regular'
            END AS customer_category
FROM invoice i
INNER JOIN customer c ON c.customer_id = i.customer_id
GROUP BY customer_name
ORDER BY customer_name



--------------------------------------------------------------------------------------------------------------------------------



-- 3. The With Clause ##

WITH playlist_info AS 
    (
     SELECT
        pl.playlist_id AS playlist_id,
        pl.name AS playlist_name,
        t.name ,
        t.milliseconds / 1000 AS duration
     FROM playlist pl
     LEFT JOIN playlist_track pt ON pt.playlist_id = pl.playlist_id
     LEFT JOIN track t ON t.track_id = pt.track_id
        )
SELECT 
    playlist_id ,
    playlist_name,
    COUNT(name) AS number_of_tracks,
    CAST(SUM(duration) AS INT)  AS length_seconds
FROM playlist_info
GROUP BY playlist_id 
ORDER BY playlist_id 
           
    

-- 4. Creating Views ##

CREATE VIEW chinook.customer_gt_90_dollars AS 
    SELECT
        c.*
    FROM chinook.invoice i
    INNER JOIN chinook.customer c ON i.customer_id = c.customer_id
    GROUP BY 1
    HAVING SUM(i.total) > 90;
SELECT * FROM chinook.customer_gt_90_dollars;

-- 5. Combining Rows With Union ##

SELECT *
FROM customer_usa
UNION
SELECT * 
FROM customer_gt_90_dollars

-- 6. Combining Rows Using Intersect and Except ##

WITH customers_usa_gt_90 AS
    (
        SELECT *
        FROM customer_usa
        INTERSECT
        SELECT *
        FROM customer_gt_90_dollars
    )
SELECT
    e.first_name || ' ' || e.last_name AS employee_name,
    COUNT(support_rep_id) AS customers_usa_gt_90
FROM employee e
LEFT JOIN customers_usa_gt_90 c ON c.support_rep_id = e.employee_id
WHERE title = "Sales Support Agent" 
GROUP BY employee_name
ORDER BY employee_name

-- 7. Multiple Named Subqueries ##

WITH
    customers_india AS
        (
            SELECT *
            FROM customer
            WHERE country = 'India'
        ),
    total_purchases AS
        (
            SELECT 
                SUM(total) AS total,
                customer_id
            FROM invoice
            GROUP BY customer_id
        )
SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    t.total AS total_purchases
FROM customers_india c
INNER JOIN total_purchases t ON t.customer_id = c.customer_id
ORDER BY customer_name

-- 8. Each Countrys Best Customer 

WITH
    customer_country_purchases AS
        (
         SELECT
             i.customer_id,
             c.country,
             SUM(i.total) total_purchases
         FROM invoice i
         INNER JOIN customer c ON i.customer_id = c.customer_id
         GROUP BY 1, 2
        ),
    country_max_purchase AS
        (
         SELECT
             country,
             MAX(total_purchases) max_purchase
         FROM customer_country_purchases
         GROUP BY 1
        ),
    country_best_customer AS
        (
         SELECT
            cmp.country,
            cmp.max_purchase,
            (
             SELECT ccp.customer_id
             FROM customer_country_purchases ccp
             WHERE ccp.country = cmp.country AND cmp.max_purchase = ccp.total_purchases
            ) customer_id
         FROM country_max_purchase cmp
        )
SELECT
    cbc.country country,
    c.first_name || " " || c.last_name customer_name,
    cbc.max_purchase total_purchased
FROM customer c
INNER JOIN country_best_customer cbc ON cbc.customer_id = c.customer_id
ORDER BY 1 ASC