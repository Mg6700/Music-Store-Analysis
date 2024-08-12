-- Write query to return the email, first name, last name, & genre of all rock music listeners.
-- Return your list ordered alphabetically by email starting with A.

SELECT DISTINCT
    email,
    first_name,
    last_name
FROM
    customer
    JOIN invoice ON customer.customer_id = invoice.customer_id
    JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE
    track_id IN (
        SELECT 
            track_id
        FROM
            track
            JOIN genre ON track.genre_id = genre.genre_id
        WHERE
            genre.name LIKE 'Rock'
    )
ORDER BY
    email;