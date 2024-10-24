-- Music Data Analysis Project

--Question Set 1 - Easy

--Q1: Who is the senior most employee based on job title? 

SELECT first_name, last_name, title,levels 
FROM employee
ORDER BY levels DESC
LIMIT 1

--Q2: Which countries have the most Invoices?

SELECT 
	billing_country, 
	COUNT(*) AS invoice_count 
FROM invoice
GROUP BY billing_country
ORDER BY COUNT(*) DESC

--Q3: What are top 3 values of total invoice? 

SELECT total 
FROM invoice
ORDER BY total DESC
LIMIT 3

/*Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals*/

SELECT 
	billing_city, 
	SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY SUM(total) DESC

/*Q5. Who is the best customer? The customer who has spent the most money will be declared the best customer. */

	
SELECT 
	c.customer_id, 
	c.first_name, 
	c.last_name, 
	SUM(i.total) AS total_spending
FROM customer AS c
LEFT JOIN invoice AS i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY SUM(i.total) DESC
LIMIT 1

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT c.email, c.first_name, c.last_name
FROM genre AS g
JOIN track AS t
	ON g.genre_id = t.genre_id
JOIN invoice_line AS il
	ON t.track_id = il.track_id
JOIN invoice AS i
	ON il.invoice_id = i.invoice_id
JOIN customer AS c
	ON i.customer_id = c.customer_id
WHERE g.name = 'Rock'
ORDER BY c.email

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT
	art.artist_id, 
	art.name, 
	COUNT(tck.*) 
FROM artist AS art
JOIN album AS alb
	ON art.artist_id = alb.artist_id
JOIN track AS tck
	ON alb.album_id = tck.album_id
JOIN genre AS gnr
	ON tck.genre_id = gnr.genre_id
WHERE gnr.name = 'Rock'
GROUP BY art.artist_id, art.name
ORDER BY COUNT(tck.*) DESC
LIMIT 10


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT
	name, 
	milliseconds 
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) 
							FROM track)
ORDER BY milliseconds DESC


/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */


WITH best_selling_artist AS (
    SELECT art.artist_id, art.name, SUM(il.unit_price * il.quantity) AS total_amount 
    FROM artist AS art
    JOIN album AS abm ON art.artist_id = abm.artist_id
    JOIN track AS trk ON abm.album_id = trk.album_id
    JOIN invoice_line AS il ON trk.track_id = il.track_id
    GROUP BY art.artist_id, art.name
    ORDER BY SUM(il.unit_price * il.quantity) DESC
    LIMIT 1
)

SELECT c.customer_id, c.first_name, c.last_name, bsa.name,
    SUM(inl.unit_price * inl.quantity)
FROM customer AS c
JOIN invoice AS i ON c.customer_id = i.customer_id
JOIN invoice_line AS inl ON i.invoice_id = inl.invoice_id
JOIN track AS tck ON inl.track_id = tck.track_id
JOIN album AS alb ON tck.album_id = alb.album_id
JOIN best_selling_artist AS bsa ON alb.artist_id = bsa.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.name
ORDER BY SUM(inl.unit_price * inl.quantity) DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */


WITH popular_music_genre AS 
(
	SELECT i.billing_country,
		g.genre_id,
		g.name,
		COUNT(inl.*) AS purchase,
		ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY COUNT(inl.*) DESC) AS rnk	
	FROM genre as g
	JOIN track as t
	ON g.genre_id = t.genre_id
	JOIN invoice_line AS inl
	ON t.track_id = inl.track_id
	JOIN invoice AS i
	ON inl.invoice_id = i.invoice_id
	GROUP BY 1,2
	
)
SELECT 
	billing_country,
	genre_id,
	name,
	purchase
FROM popular_music_genre
WHERE rnk = 1

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

	WITH top_customer AS
	(
	SELECT 
		i.billing_country,
		c.customer_id,
		c.first_name,
		c.last_name,
		SUM(total) AS total_spent,
		DENSE_RANK() OVER(PARTITION BY i.billing_country ORDER BY SUM(total) desc) as rnk
FROM customer AS c
JOIN invoice AS i
	ON c.customer_id = i.customer_id
GROUP BY 1,2,3
)
SELECT customer_id,
	first_name,
	last_name,
	billing_country,
	total_spent
FROM top_customer
WHERE rnk = 1
