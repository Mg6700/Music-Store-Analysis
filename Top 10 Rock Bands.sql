-- Write a query that returns the artist name and total track count of the top 10 rock bands.

SELECT 
    artist.artist_id,
    artist.name,
    COUNT(artist.artist_id) AS number_of_songs
FROM
    track
    JOIN album2 ON album2.album_id = track.track_id
    JOIN artist ON artist.artist_id = album2.artist_id
    JOIN genre ON genre.genre_id = track.genre_id
WHERE
    genre.name LIKE 'Rock'
GROUP BY 
    artist.artist_id, 
    artist.name
ORDER BY 
    number_of_songs DESC
LIMIT 10;