-- Which city has the best customers?

SELECT 
    SUM(total) AS invoice_total,
    billing_city
FROM
    invoice
GROUP BY 
    billing_city
ORDER BY 
    invoice_total DESC
LIMIT 1;