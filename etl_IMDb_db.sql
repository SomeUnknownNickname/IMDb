-- Vytvorenie databázy
CREATE DATABASE IMDb_DB;

-- Vytvorenie schémy pre staging tabuľky
CREATE SCHEMA IMDb_DB.staging;

USE SCHEMA IMDb_DB.staging;

--vytvorenie staging tabuliek

CREATE TABLE movie(
  id VARCHAR(10) NOT NULL,
  title VARCHAR(200) DEFAULT NULL,
  year INT DEFAULT NULL,
  date_published DATE DEFAULT null,
  duration INT,
  country VARCHAR(250),
  worlwide_gross_income VARCHAR(30),
  languages VARCHAR(200),
  production_company VARCHAR(200),
  PRIMARY KEY (id)
);

CREATE TABLE ratings(
	movie_id VARCHAR(10) NOT NULL,
	avg_rating DECIMAL(3,1),
	total_votes INT,
	median_rating INT,
    PRIMARY KEY (movie_id)
);


CREATE TABLE genre(
  id INT NOT NULL,
  genre_name VARCHAR(20) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE names(
  id varchar(10) NOT NULL,
  name varchar(100) DEFAULT NULL,
  height int DEFAULT NULL,
  date_of_birth date DEFAULT null,
  known_for_movies varchar(100),
  PRIMARY KEY (id)
);

CREATE TABLE director_mapping(
    movie_id VARCHAR(10),
    name_id VARCHAR(10),
	PRIMARY KEY (movie_id, name_id)
);

CREATE TABLE role_mapping(
    movie_id VARCHAR(10) NOT NULL,
    name_id VARCHAR(10) NOT NULL,
    category VARCHAR(10),
	PRIMARY KEY (movie_id, name_id)
);

-- Vytvorenie my_stage pre .csv súbory
CREATE OR REPLACE STAGE my_stage;

-- Nahratie dát do staging tabuliek
COPY INTO movie
FROM @my_stage/movie.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO ratings
FROM @my_stage/ratings.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO genre
FROM @my_stage/genre.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO names
FROM @my_stage/names.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 NULL_IF = ('NULL')); -- davame NULL_IF = ('NULL') pretoze mame hybu v datoch

COPY INTO director_mapping
FROM @my_stage/director_mapping.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO role_mapping
FROM @my_stage/role_mapping.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- ELT - (T)ransform

-- dim_movie
DROP TABLE IF EXISTS dim_movie;
CREATE TABLE dim_movie AS
SELECT
    id AS movie_id,
    title,
    date_published,
    duration,
    country,
    DAY(date_published) AS day,      
    MONTH(date_published) AS month,  
    YEAR(date_published) AS year,     
    worlwide_gross_income,
    production_company
FROM movie
WHERE date_published IS NOT NULL;

-- dim_names
DROP TABLE IF EXISTS dim_names;
CREATE TABLE dim_names AS
SELECT DISTINCT
    n.id AS name_id,
    n.name,
    n.known_for_movies,
    CASE
        WHEN rm.category IS NULL OR rm.category = 'NULL' THEN 'director'
        WHEN rm.category = 'actor' THEN 'actor'
        WHEN rm.category = 'actress' THEN 'actress'
    END AS category
FROM names n
LEFT JOIN role_mapping rm
    ON n.id = rm.name_id;
Select * from dim_names;

-- dim_genre
DROP TABLE IF EXISTS dim_genre;
CREATE TABLE dim_genre AS
SELECT DISTINCT 
    genre AS genre_name              
FROM genre
WHERE genre IS NOT NULL;

-- movie_genre_bridge
DROP TABLE IF EXISTS movie_genre_bridge;
CREATE TABLE movie_genre_bridge AS
SELECT 
    movie_id,                        
    genre AS genre_name              
FROM genre
WHERE genre IS NOT NULL;

-- fact_raitings
DROP TABLE IF EXISTS fact_raitings;
CREATE TABLE fact_raitings AS
SELECT
    ROW_NUMBER() OVER (ORDER BY r.movie_id) AS id,  
    r.avg_rating,                                   
    r.total_votes,                                  
    r.median_rating,                                
    m.movie_id AS movieId,                          
    n.id AS nameId,                                 
    d.date_id AS dateId                             
FROM ratings r
JOIN dim_movie m ON r.movie_id = m.movie_id         
LEFT JOIN director_mapping dm ON r.movie_id = dm.movie_id
LEFT JOIN names n ON dm.name_id = n.id             
JOIN dim_date d ON m.date_published = d.full_date;

-- drop staging tables 
DROP TABLE names;
DROP TABLE genre;
DROP TABLE raitings;
DROP TABLE director_mapping;
DROP TABLE role_mapping;
DROP TABLE movie;

