# Music Store Business Analysis – SQL Project

**Tools:** SQL (MySQL)  
**Domain:** Business Intelligence | Customer Analytics | Revenue Analysis  
**Portfolio:** [mg67.vercel.app](https://mg67.vercel.app/) | **GitHub:** [Mg6700](https://github.com/Mg6700)

---

## Project Overview

This project uses SQL to answer real business questions for a music store using a relational database. The analysis covers customer value ranking, artist and genre performance, geographic revenue distribution, and employee hierarchy — demonstrating practical SQL skills across joins, aggregations, subqueries, CTEs, recursive CTEs, and window functions on an 11-table relational schema.

The project is structured as a business intelligence exercise: each query starts with a real business question and delivers a ranked, filtered, actionable output.

---

## Database Schema

The Chinook database contains 11 tables representing a digital music store:

```
employee          ← Staff hierarchy (levels, reporting structure)
customer          ← Customer records with billing country/city
invoice           ← Transaction headers (date, total, billing info)
invoice_line      ← Line items (track, quantity, unit price)
track             ← Song catalog (name, album, genre, duration, price)
album2            ← Album records linked to artists
artist            ← Artist master list
genre             ← Music genre classification
media_type        ← Format (AAC, MP3, etc.)
playlist          ← Curated playlists
playlist_track    ← Playlist-to-track mapping
```

**Relationships:** invoice → customer → billing geography | invoice_line → track → album → artist → genre

---

## Queries & Business Questions

### Query 1 – Senior Most Employee
**Business Question:** Who is the most senior employee based on job title level?

```sql
SELECT *
FROM employee
ORDER BY levels DESC
LIMIT 1;
```

**Output:** Andrew Adams — General Manager (Level L6)

---

### Query 2 – Most Invoices by Country
**Business Question:** Which countries have the most invoices?

```sql
SELECT COUNT(*) AS c, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;
```

**Output:** USA (131), Canada (76), Brazil (61), France (50), Germany (41)

---

### Query 3 – Top 3 Invoice Values
**Business Question:** What are the top 3 total invoice amounts?

```sql
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;
```

**Output:** $23.76, $19.80, $19.80

---

### Query 4 – City with Best Customers
**Business Question:** Which city has generated the most revenue? (For music festival targeting)

```sql
SELECT SUM(total) AS invoice_total, billing_city
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC
LIMIT 1;
```

**Output:** Prague — $273.24

**Business Implication:** Hosting a promotional music festival in Prague would target the highest-revenue customer base.

---

### Query 5 – Best Customer
**Business Question:** Who has spent the most money overall?

```sql
SELECT customer.customer_id, customer.first_name, customer.last_name,
       SUM(invoice.total) AS total
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY total DESC
LIMIT 1;
```

**Output:** František Wichterlová — $144.54

---

### Query 6 – Rock Music Listeners
**Business Question:** Return email, name, and genre for all Rock music listeners, ordered alphabetically by email.

```sql
SELECT DISTINCT email, first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN (
    SELECT track_id FROM track
    JOIN genre ON track.genre_id = genre.genre_id
    WHERE genre.name LIKE 'Rock'
)
ORDER BY email;
```

**Technique:** Subquery filtering with DISTINCT to eliminate duplicate customer records across multiple purchases.

---

### Query 7 – Top 10 Rock Bands by Track Count
**Business Question:** Which artists have written the most Rock tracks in the catalog?

```sql
SELECT artist.artist_id, artist.name,
       COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album2 ON album2.album_id = track.track_id
JOIN artist ON artist.artist_id = album2.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC
LIMIT 10;
```

**Output:** Deep Purple (7), Iron Maiden (5), Various Artists (4), Gilberto Gil (3), Guns N' Roses (3)

---

### Query 8 – Tracks Longer Than Average Duration
**Business Question:** Return all tracks longer than the average song length, ordered longest first.

```sql
SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds) AS avg_track_length FROM track
)
ORDER BY milliseconds DESC;
```

**Technique:** Scalar subquery in WHERE clause for dynamic threshold filtering.  
**Output:** "How Many More Times" (711,836ms), "Advance Romance" (677,694ms), "Sleeping Village" (644,571ms)

---

### Query 9 – Amount Spent by Each Customer on Each Artist
**Business Question:** Return customer name, artist name, and total amount spent per artist.

```sql
SELECT c.customer_id, c.first_name, c.last_name,
       a.name AS artist_name,
       SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album2 alb ON alb.album_id = t.album_id
JOIN artist a ON a.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, a.name
ORDER BY amount_spent DESC;
```

**Technique:** 6-table JOIN chain traversing the full invoice → customer → track → album → artist path.  
**Output:** Steve Murray → AC/DC ($17.82), Jennifer Peterson → Aerosmith ($14.85)

---

### Query 10 – Most Popular Genre by Country
**Business Question:** Find the most purchased music genre for each country. Where tied, return all genres.

```sql
WITH popular_genre AS (
    SELECT COUNT(invoice_line.quantity) AS purchases,
           customer.country,
           genre.name,
           genre.genre_id,
           ROW_NUMBER() OVER (
               PARTITION BY customer.country
               ORDER BY COUNT(invoice_line.quantity) DESC
           ) AS RowNo
    FROM invoice_line
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY customer.country, genre.name, genre.genre_id
    ORDER BY customer.country ASC, purchases DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;
```

**Technique:** CTE + ROW_NUMBER() window function with PARTITION BY country to rank genres per country.  
**Output:** Rock is the #1 genre in 24 of 25 countries analyzed.

---

### Query 11 – Top Spending Customer per Country (with tie handling)
**Business Question:** Find the highest-spending customer in each country. If two customers have equal spend, return both.

```sql
WITH RECURSIVE Customer_with_country AS (
    SELECT customer.customer_id, first_name, last_name, billing_country,
           SUM(total) AS total_spending
    FROM invoice
    JOIN customer ON customer.customer_id = invoice.customer_id
    GROUP BY customer.customer_id, first_name, last_name, billing_country
    ORDER BY customer.customer_id, total_spending DESC
),
Country_max_spending AS (
    SELECT billing_country, MAX(total_spending) AS max_spending
    FROM Customer_with_country
    GROUP BY billing_country
)
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name
FROM Customer_with_country cc
JOIN Country_max_spending ms ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY cc.billing_country;
```

**Technique:** Recursive CTE + MAX aggregation join for tie-safe top-N per group — a common real-world reporting pattern.  
**Output:** Top customer per country across all 25 billing countries (e.g. Argentina: Diego Gutiérrez $39.60, Australia: Mark Taylor $81.18)

---

## SQL Techniques Demonstrated

| Technique | Queries Used In |
|---|---|
| Basic SELECT + ORDER BY + LIMIT | Q1, Q3 |
| GROUP BY + COUNT / SUM aggregation | Q2, Q4, Q5, Q7 |
| Multi-table INNER JOIN (up to 6 tables) | Q6, Q9 |
| Subquery in WHERE clause | Q6, Q8 |
| Scalar subquery (AVG in WHERE) | Q8 |
| CTE (WITH clause) | Q10, Q11 |
| Recursive CTE | Q11 |
| Window function — ROW_NUMBER() PARTITION BY | Q10 |
| Tie-safe top-N per group pattern | Q11 |

---

## Key Business Insights

- **Rock dominates globally** — #1 genre in 24 of 25 countries. Catalog expansion should prioritize Rock artists.
- **Prague is the highest-revenue city** ($273.24) — ideal location for promotional events or priority customer targeting.
- **Top 5 countries by invoice count** (USA, Canada, Brazil, France, Germany) are the primary markets for marketing spend.
- **AC/DC generates the highest per-customer spend** ($17.82) — strong case for exclusive AC/DC promotions or bundles.
- **Deep Purple has the largest Rock catalog** (7 tracks) in the store — merchandising opportunity.

---

## How to Run

1. Clone the repository
2. Import `chinook.sql` into MySQL Workbench or any MySQL-compatible environment
3. Run individual `.sql` query files or copy queries from this README into your SQL editor
4. Each query is self-contained and runs independently

---

*Created by Mayur Goyal | [Portfolio](https://mg67.vercel.app/) | [LinkedIn](https://www.linkedin.com/in/mg67)*
