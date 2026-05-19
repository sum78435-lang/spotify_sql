CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

/*
-- ---------------------------------------------------
-- Data Analysis - Easy Category
-- ---------------------------------------------------
Retrieve the names of all tracks that have more than 1 billion streams.
List all albums along with their respective artists.
Get the total number of comments for tracks where licensed = TRUE.
Find all tracks that belong to the album type single.
Count the total number of tracks by each artist.
*/

-- Q1.Retrieve the names of all tracks that have more than 1 billion streams.
select * from spotify
where stream > 1000000000;

-- Q2.List all albums along with their respective artists.
select distinct album,artist
from spotify order by 1;
select distinct album
from spotify order by 1;

-- Q3. Get the total number of comments for tracks where licensed = TRUE.
select distinct licensed from spotify;
SELECT 
    SUM(comments) AS total_comments
FROM
    spotify
WHERE
    licensed = 'true';
    
-- Q4.Find all tracks that belong to the album type single.
select * from spotify
where album_type like '%single%';

-- 5.Count the total number of tracks by each artist.
SELECT 
    artist, COUNT(*) AS total_no_songs
FROM
    spotify
GROUP BY artist
ORDER BY 2 DESC;

/*
-- --------------------------------------------------------
-- Medium Level
-- --------------------------------------------------------
Calculate the average danceability of tracks in each album.
Find the top 5 tracks with the highest energy values.
List all tracks along with their views and likes where official_video = TRUE.
For each album, calculate the total views of all associated tracks.
Retrieve the track names that have been streamed on Spotify more than YouTube.
*/

-- Q6.Calculate the average danceability of tracks in each album.
SELECT 
    album, AVG(danceability) AS avg_danceability
FROM
    spotify
GROUP BY 1
ORDER BY 2 DESC;

-- Q7.Find the top 5 tracks with the highest energy values.
SELECT 
    track, MAX(energy) 
FROM
    spotify
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Q8.List all tracks along with their views and likes where official_video = TRUE.
SELECT 
    track, SUM(views) AS total_views, SUM(likes) AS total_likes
FROM
    spotify
WHERE
    official_video = 'true'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Q9.For each album, calculate the total views of all associated tracks.
SELECT 
    album, track, SUM(views)
FROM
    spotify
GROUP BY 1 , 2
ORDER BY 3 DESC;

-- Q10.Retrieve the track names that have been streamed on Spotify more than YouTube.
SELECT 
    *
FROM
    (SELECT 
        track,
            COALESCE(SUM(CASE
                WHEN most_playedon = 'Youtube' THEN stream
            END), 0) AS streamed_on_youtube,
            COALESCE(SUM(CASE
                WHEN most_playedon = 'spotify' THEN stream
            END), 0) AS streamed_on_spotify
    FROM
        spotify
    GROUP BY 1) AS t1
WHERE
    streamed_on_spotify > streamed_on_youtube
        AND streamed_on_youtube <> 0;
-- --------------------------------------------------------
-- Advanced Problems
-- --------------------------------------------------------

/* 1. Find the top 3 most-viewed tracks for each artist using window functions.
2. Write a query to find tracks where the liveness score is above the average.
3. Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.
4. Find tracks where the energy-to-liveness ratio is greater than 1.2.
5. Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.*/

-- Q11. Find the top 3 most-viewed tracks for each artist using window functions.
-- track with highest view for each artist 
-- dense rank
-- cte and filter rank <=3

with ranking_artist as(
SELECT 
    artist, 
    track, 
    SUM(views) as total_view,
    dense_rank() over(partition by artist order by sum(views) desc) as ranking
FROM
    spotify
GROUP BY 1 , 2
)
select * from ranking_artist where ranking <= 3
order by artist,total_view desc;

-- Q12. write a query to find tracks where the liveness score is above the average
SELECT 
    track, artist, liveness
FROM
    spotify
WHERE
    liveness > (SELECT 
            AVG(liveness)
        FROM
            spotify);
            
-- Q13.
-- use a with clause to calculate the difference between the
-- highest and lowest energy values for tracks in each album

with cte as(
SELECT 
    album, 
    MAX(energy) as highest_energy,
    Min(energy) as lowest_energy
FROM
    spotify
group by 1)
select album,highest_energy - lowest_energy as energy_diff
from cte
order by 2 desc;

-- Q14.Find tracks where the energy-to-liveness ratio is greater than 1.2.
select track,artist,energy,liveness,(energy / liveness) as energy_to_liveness_ratio from spotify
where liveness > 0
AND (energy / liveness) > 1.2
order by energy_to_liveness_ratio desc;

-- Q15.Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.
select track,artist,views,likes,sum(likes) over(order by views asc) as cumulative_likes from spotify
order by views asc;

-- Query optimization

set profiling = 1;

SELECT 
    artist, track, views
FROM
    spotify
WHERE
    artist = 'Gorillaz'
	AND 
    most_playedon = 'Youtube'
order by stream desc limit 5;

CREATE INDEX artist_index ON spotify(artist(50));
show index from spotify;
alter table spotify drop index artist_index;