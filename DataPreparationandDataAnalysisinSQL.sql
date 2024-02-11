
-----------------------------------------------------------------------
-----------------------LOADING DATA INTO SQL---------------------------
---- Three relational datasets: content, reactionsm reactiontype 
---- Goal: Figure out the Top 5 performing categories for the business

DROP TABLE IF EXISTS content;
CREATE TABLE IF NOT EXISTS content 
(
	sn INT, 
	content_id VARCHAR,
	user_id VARCHAR, 
	type VARCHAR,
	category VARCHAR,
	url VARCHAR
);

DROP TABLE IF EXISTS reactions;
CREATE TABLE IF NOT EXISTS reactions 
(
	sn INT, 
	content_id VARCHAR,
	user_id VARCHAR, 
	type VARCHAR,
	datetime TIMESTAMP 
);

DROP TABLE IF EXISTS reactiontype;
CREATE TABLE IF NOT EXISTS reactiontype
(
	sn INT, 
	type VARCHAR,
	sentiment VARCHAR, 
	score INT
);

---------------------------------------------------------------------------------------
--------------------------------DATA PREPARATION AND CLEANING--------------------------
---Firstly, access each table to understand the data set
-- Looking out for missing values, redunancies, outliners, data patterns/data types, etc...

------------------Table 1: content table------------------
SELECT *
FROM content;
--dimension table, contains 1000 rows
--table contains records that are irrelevant to the business question, fields like url and user id
-----Delete url and user id 
ALTER TABLE content
DROP COLUMN url, 
DROP COLUMN user_id;

---rename content type field 
ALTER TABLE content
RENAME COLUMN type TO content_type;

--checking for outliners in content table
SELECT category, COUNT(*) AS total_category
FROM content
GROUP BY category;
--category field contains records with "" double quotation mark 
--update the field
UPDATE content
SET category = REPLACE(category, '"', '');

--checking for null records in the data
SELECT COUNT(*) 
FROM content
WHERE content_id IS NULL OR content_type IS NULL OR category IS NULL;
---no null records in content table 

--table contains some records (in the feild category) that are the same but stored in different cases
--update field 'category'
UPDATE content
SET category = LOWER(category);

--cleaned table
SELECT *
FROM content;
-- 1000 rows after cleaning 

-----------------Table 2: reaction table------------ 
SELECT *
FROM reactions;
--fact table: 25533 rows

--table contains records that are irrelevant to the business question, fields like user id
-----Delete user id 
ALTER TABLE reactions
DROP COLUMN user_id;

---rename reaction type field 
ALTER TABLE reactions
RENAME COLUMN type TO reaction_type;

--checking for outliners in reactions table
SELECT reaction_type, COUNT(*) AS total_type
FROM reactions
GROUP BY reaction_type;
--none found

---checking for the null records in the data
SELECT COUNT(*) 
FROM reactions 
WHERE content_id IS NULL OR 
reaction_type IS NULL OR datetime IS NULL;
---980 null records in reaction table 
---deleting the null records, as firstly does not induce any bias or distortion to this analysis,
---also its only about 4% of the dataset 
DELETE FROM reactions
WHERE content_id IS NULL OR 
reaction_type IS NULL OR datetime IS NULL;

--cleaned reactions table 
SELECT *
FROM reactions;
--total result after cleaning is 24573 rows

--For easier further analysis, create 'days of the week' column
--add days of the week to table 
ALTER TABLE reactions 
ADD COLUMN day_of_week VARCHAR(10);

UPDATE reactions
SET day_of_week = to_char(datetime, 'Day');


---------------------Table 3: reaction type table---------
SELECT *
FROM reactiontypes;
--dimension table with 16 rows 
-- no null, no outliner

--renaming type to reaction type 
ALTER TABLE reactiontypes
RENAME COLUMN type TO reaction_type;

-----------------------------------------------------------------------------------
-----------------------------------------DATA MODELLING----------------------------
---------Joining the three tables 
SELECT rt.content_id, ct.content_type, rt.datetime,  rtp.sentiment, ct.category, rt.reaction_type, rtp.score
FROM reactions AS rt
INNER JOIN content AS ct
ON rt.content_id = ct.content_id
INNER JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type;

--time of the day (morning, afternoon and night) looks like a useful column for this analysis
--add 'time of the day' column
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

-----------------------------------------------------------------------------------------
--------------------------------------ANALYSIS-------------------------------------------
-- Business question: Figure out the Top 5 performing categories

--- 1. What are the 5 top performing categories?
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

---2. What are the factors driving engagement in these top five categories?
--different reactions based on time of the day
SELECT time_of_day, COUNT(*) AS reactions_timeofday                                                                                                                                                           
FROM reactions AS rt
LEFT JOIN content AS ct
ON rt.content_id = ct.content_id
LEFT JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type
WHERE category IN ('animals', 'healthy eating', 'technology', 'science', 'culture')
GROUP BY time_of_day
ORDER BY  2 DESC;
--insight: this shows that morning, meaning that people tend to reach more in the morning

--different reactions based on time of the day
SELECT time_of_day, COUNT(*) AS reactions_timeofday, 
	ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) AS Percentage
FROM reactions AS rt
LEFT JOIN content AS ct
ON rt.content_id = ct.content_id
LEFT JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type
WHERE category IN ('animals', 'healthy eating', 'technology', 'science', 'culture')
GROUP BY time_of_day
ORDER BY  2 DESC;
--insight: half of the reactions comes in the morning, THIS WOULD BE A GREAT TIME TO ENGAGE USERS 

---propostion of different sentiment (comment) by the day
SELECT
    day_of_week,
    COUNT(*) AS positive_count, COUNT(*) AS negative_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) AS percentage
FROM reactions AS rt
LEFT JOIN content AS ct
ON rt.content_id = ct.content_id
LEFT JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type
WHERE sentiment IN ('positive', 'negative')
GROUP BY day_of_week
ORDER BY positive_count DESC, negative_count DESC;
--insight: 
---positive comments come in during end of the week starting from thursday except saturdays: Friday, Thurday and Sunday. 
--saturday has the lowest comments
--negative comments are earlier in the week: Tuesday, Wednesday and Monday respectively 


--what kind of sentiment does this top 5 most popular categories get
SELECT DISTINCT category, sentiment, COUNT(sentiment) AS sentiment_for_top5
FROM reactions AS rt
LEFT JOIN content AS ct
ON rt.content_id = ct.content_id
LEFT JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type
WHERE category IN ('animals', 'healthy eating', 'technology', 'science', 'food')
GROUP BY category, sentiment
ORDER BY 1, 3 DESC;

--total for each type of sentiment
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
FROM reactions AS rt
LEFT JOIN content AS ct
ON rt.content_id = ct.content_id
LEFT JOIN reactiontypes AS rtp
ON rt.reaction_type = rtp.reaction_type
    WHERE category IN ('animals', 'healthy eating', 'technology', 'science', 'food')
    GROUP BY category, sentiment
) AS top5
GROUP BY category
ORDER BY 2 DESC, 3 DESC, 4 DESC;
---insight: the top 5 categories get more positive comments

----------------------------------------------------------------------------
------------------------DATA VISUALISATION---------------------------------
--Data visualisation for this project would be conducted in Power BI
--These results were loaded into power BI for visualisation and further analysis 
--Please see README.md for visualisation









