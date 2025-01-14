-- 1. Najlepšie filmy podľa priemerného hodnotenia
SELECT 
    dm.title AS movie_title, 
    MAX(fr.avg_rating) AS average_rating
FROM fakt_ratings fr
JOIN dim_movie dm ON fr.movieId = dm.movie_id
GROUP BY dm.title
ORDER BY average_rating DESC
LIMIT 10;

-- 2. Najlepšie krajiny podľa počtu filmov
SELECT 
    dm.country, 
    COUNT(DISTINCT dm.movie_id) AS movie_count
FROM dim_movie dm
GROUP BY dm.country
ORDER BY movie_count DESC
LIMIT 10;

-- 3. Najlepšie krajiny podľa priemerného hodnotenia
SELECT 
    dm.country, 
    Round(AVG(fr.avg_rating), 2) AS average_rating
FROM fakt_ratings fr
JOIN dim_movie dm ON fr.movieId = dm.movie_id
GROUP BY dm.country
ORDER BY average_rating DESC
LIMIT 10;

-- 4. Filmy s najvyšším hodnotením
SELECT 
    dm.title AS movie_title, 
    MAX(fr.avg_rating) AS average_rating
FROM fakt_ratings fr
JOIN dim_movie dm ON fr.movieId = dm.movie_id
GROUP BY dm.title
ORDER BY average_rating DESC
LIMIT 10;

-- 5. Najlepšie žánre podľa počtu filmov
SELECT 
    dg.genre_name, 
    COUNT(mgb.movie_id) AS movie_count
FROM movie_genre_bridge mgb
JOIN dim_genre dg ON mgb.genre_name = dg.genre_name
GROUP BY dg.genre_name
ORDER BY movie_count DESC
LIMIT 10;