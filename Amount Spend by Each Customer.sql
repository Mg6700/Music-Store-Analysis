-- Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent.

SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    a.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM 
    invoice i
JOIN 
    customer c ON c.customer_id = i.customer_id
JOIN 
    invoice_line il ON il.invoice_id = i.invoice_id
JOIN 
    track t ON t.track_id = il.track_id
JOIN 
    album2 alb ON alb.album_id = t.album_id
JOIN 
    artist a ON a.artist_id = alb.artist_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name, a.name
ORDER BY 
    amount_spent DESC;