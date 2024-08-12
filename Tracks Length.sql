-- Return all the track names that have a song length longer than the average song length.
-- Return the name and milliseconds for each track, order by the song length with the longest songs listed first.

SELECT 
    name, 
    milliseconds
FROM
    track
WHERE
    milliseconds > (
        SELECT 
            AVG(milliseconds) AS avg_track_length
        FROM
            track
    )
ORDER BY 
    milliseconds DESC;