--create tables and load data--
DROP TABLE IF EXISTS content;
CREATE TABLE IF NOT EXISTS content 
(
	sn INT, --remove the header of this
	content_id VARCHAR,
	user_id VARCHAR, 
	type VARCHAR,
	category VARCHAR,
	url VARCHAR
);

DROP TABLE IF EXISTS reactions;
CREATE TABLE IF NOT EXISTS reactions 
(
	sn INT, --remove the header of this later
	content_id VARCHAR,
	user_id VARCHAR, 
	type VARCHAR,
	datetime TIMESTAMP 
);

DROP TABLE IF EXISTS reactiontype;
CREATE TABLE IF NOT EXISTS reactiontype
(
	sn INT, --remove the header of this later
	type VARCHAR,
	sentiment VARCHAR, 
	score INT
);

-------------------DATA CLEANING------------------------
-- removing rows that have values which are missing
-- changing the data type of some values within a column
-- removing columns which are not relevant to this task.

------Assessing each field in each table 

--------------------content table--------------
SELECT *
FROM content;
--1000 rows

-----Delete url and user id in content table because it is not relevant to this analysis
ALTER TABLE content
DROP COLUMN url, 
DROP COLUMN user_id;

---rename content type field 
ALTER TABLE content
RENAME COLUMN type TO content_type;


-- checking for outliners in content table
SELECT category, COUNT(*) AS total_category
FROM content
GROUP BY category;
--categories contains records with "" double quotation mark 
-- to delete ""
UPDATE content
SET category = REPLACE(category, '"', '');

SELECT content_type, COUNT(*) AS total_type
FROM content
GROUP BY content_type;
--no outliners 

--checking for null records in the data
SELECT COUNT(*) 
FROM content
WHERE content_id IS NULL OR content_type IS NULL OR category IS NULL;
---no null records in content table 

--combine duplicates from categories
--come categories are same but come in different cases. 
UPDATE content
SET category = LOWER(category);

SELECT *
FROM content;
-- still 1000 rows in total after cleaning 

-------------------------reaction table------------ 
SELECT *
FROM reactions;
--initial total: 25533 rows

-----Delete user id in reaction table because it is not relevant to this analysis
ALTER TABLE reactions
DROP COLUMN user_id;
--this is what probably happened to my data.
---rename reaction type field 
ALTER TABLE reactions
RENAME COLUMN type TO reaction_type;

-- checking for outliners in reactions table
SELECT reaction_type, COUNT(*) AS total_type
FROM reactions
GROUP BY reaction_type;
--980 null value 

---checking for null records in the data
SELECT COUNT(*) 
FROM reactions 
WHERE content_id IS NULL OR 
reaction_type IS NULL OR datetime IS NULL;
---980 null records in reaction table 

---deleting the null records
DELETE FROM reactions
WHERE content_id IS NULL OR 
reaction_type IS NULL OR datetime IS NULL;

--cleaned reactions table 
SELECT *
FROM reactions;
--total result after cleaning is 24573 rows

----------------------------reaction type table---------
SELECT *
FROM reactiontypes;
-- no null, no outliner, with 16 rows

--renaming type to reaction type 
ALTER TABLE reactiontypes
RENAME COLUMN type TO reaction_type;


---------------------------------JOINING THE THREE DATA SETS 
SELECT rt.content_id, ct.content_type, rt.datetime,  rtp.sentiment, ct.category, rt.reaction_type, rtp.score
FROM reactions AS rt
INNER JOIN content AS ct
ON rt.content_id = ct.content_id
INNER JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type;

-------DATA MODELLING--------------
------ANALYSIS USING THE BUSINESS QUESTION--------
-- Figure out the Top 5 performing categories
---	What are the key trends and factors driving engagement in these top five categories?

---scores by categories 
SELECT DISTINCT category, SUM(score) OVER (PARTITION BY category) AS totalscore_by_category
FROM reactions AS rt
LEFT JOIN content AS ct
ON rt.content_id = ct.content_id
LEFT JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type
GROUP BY rt.datetime, category, score
ORDER BY totalscore_by_category DESC
--top 5 categories 
LIMIT 5;
--insight: animals, science, healthy eating, technology and food are the top 5 catergoies respectively 

--add days of the week to table 
ALTER TABLE reactions 
ADD COLUMN day_of_week VARCHAR(10);

UPDATE reactions
SET day_of_week = to_char(datetime, 'Day');

--joined data with the days of the week column and time of the day(morning, afternoon and night)
DROP TABLE IF EXISTS new_data;
CREATE TABLE IF NOT EXISTS new_data AS
--put into a table to be about to do further analysis
SELECT rt.content_id, rt.datetime, day_of_week,
    CASE
        WHEN EXTRACT(HOUR FROM  datetime) >= 0 AND EXTRACT(HOUR FROM  datetime) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM  datetime) >= 12 AND EXTRACT(HOUR FROM  datetime) < 18 THEN 'Afternoon'
        ELSE 'Night'
    END AS time_of_day,  ct.content_type, rt.reaction_type, sentiment, category, score
FROM reactions AS rt
LEFT JOIN content AS ct
ON rt.content_id = ct.content_id
LEFT JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type;

---final data in a new table
SELECT *
FROM new_data;


--different reactions based on time of the day
SELECT time_of_day, COUNT(*) AS reactions_timeofday                                                                                                                                                           
FROM new_data
WHERE category IN ('animals', 'healthy eating', 'technology', 'science', 'culture')
GROUP BY time_of_day
ORDER BY  2 DESC;
--insight: this shows that morning, meaning that people tend to reach more in the morning

--different reactions based on time of the day
SELECT time_of_day, COUNT(*) AS reactions_timeofday, 
	ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) AS Percentage
FROM new_data
WHERE category IN ('animals', 'healthy eating', 'technology', 'science', 'culture')
GROUP BY time_of_day
ORDER BY  2 DESC;
--insight: half of the reactions comes in the morning, THIS WOULD BE A GREAT TIME TO ENGAGE USERS 

SELECT
    day_of_week,
    COUNT(*) AS positive_count, COUNT(*) AS negative_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) AS percentage
FROM new_data
WHERE sentiment IN ('positive', 'negative')
GROUP BY day_of_week
ORDER BY positive_count DESC, negative_count DESC;
--insight: 
---positive comments come in during the weekend
--friday, thurday and sunday. 
--saturday has the lowest comments
--negative comments are within the week. 
--between monday and wednesday. 
--Tuesday, wednesday and monday respectively 

SELECT
    day_of_week,
    COUNT(*) AS total_count,
    SUM(CASE WHEN sentiment = 'positive' THEN 1 ELSE 0 END) AS positive_count,
    ROUND((SUM(CASE WHEN sentiment = 'positive' THEN 1 ELSE 0 END)::decimal / COUNT(*)), 2) * 100 AS positive_percentage
FROM new_data
GROUP BY day_of_week
ORDER BY 4 DESC;

--what kind of sentiment does this top 5 most popular categories get
SELECT DISTINCT category, sentiment, COUNT(sentiment) AS sentiment_for_top5
FROM new_data
WHERE category IN ('animals', 'healthy eating', 'technology', 'science', 'food')
GROUP BY category, sentiment
ORDER BY 1, 3 DESC;

SELECT
    category,
    SUM(CASE WHEN sentiment = 'positive' THEN sentiment_for_top5 ELSE 0 END) AS positive_count,
    SUM(CASE WHEN sentiment = 'negative' THEN sentiment_for_top5 ELSE 0 END) AS negative_count,
	SUM(CASE WHEN sentiment = 'neutral' THEN sentiment_for_top5 ELSE 0 END) AS neutral_count
FROM (
    SELECT
        category,
        sentiment,
        COUNT(sentiment) AS sentiment_for_top5
    FROM new_data
    WHERE category IN ('animals', 'healthy eating', 'technology', 'science', 'food')
    GROUP BY category, sentiment
) AS top5
GROUP BY category
ORDER BY 2 DESC, 3 DESC, 4 DESC;









