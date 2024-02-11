# Social Buzz Content Analysis - From Data to Dashboard!
# Data Preparation, Cleaning, Modeling in SQL/ Analysis in SQL and Power BI
# Dashboard

<img width="1158" alt="image" src="https://github.com/bisolaola/Accenture-SocialBuzz/assets/137617628/e08cb183-49f7-4aa4-b991-5cc385c6416c">


# Data Preparation and Cleaning

There's a saying that the output of your analysis will only be as good as the dataset that has been used as an input. Essentially, garbage in, garbage out. This encapsulates the fundamental rationale behind data cleaning.

Firstly, let's get a brief understanding of the dataset for this project. The dataset is from an Accenture Virtual Internship program on theForage.com.  Analysis is for a frictional Accenture client called Social Buzz. Social Buzz is a technology company in the social media and content creation industry, currently experiencing rapid and unanticipated growth and would like to analyse its content categories to identify the 5 most popular Social Buzz content. 

Now that we're familiar with the dataset, let's discuss the role I played.

As the data analyst on the team, my major role was to analyse Social Buzz content categories, highlighting the top 5 categories with the largest aggregate popularity. The burning business question is "What are the 5 top-performing categories of Social Buzz?". To answer this question, I followed these key steps: 

1. Data Preparation and Cleaning
4. Data Modeling
5. Data Analysis
6. Visualisation of Insights

Now, back to data preparation and cleaning, the foundation of all analysis. Preparing the data, I meticulously looked out for missing values, redunancies in data, outliner(s), data patterns/data types. Overall, I:

- Removed rows that had values which are missing
- Changed the data type of some values within a column
- Removed columns which are not relevant to the business question or to the analysis.

Whats next?

# Data Modeling

Well, my next step involved delving into the relationship between the three relational tables, distinguishing the fact table from the dimension tables. Subsequently, I utilised inner join to merge these tables while implementing necessary data modifications along the way.  

    SELECT rt.content_id, ct.content_type, rt.datetime,  rtp.sentiment, ct.category, rt.reaction_type, rtp.score
    FROM reactions AS rt
    INNER JOIN content AS ct
    ON rt.content_id = ct.content_id
    INNER JOIN reactiontypes AS rtp
    ON rt.reaction_type = rtp.reaction_type;

# Analysis 

    KPI: Score
    Score quantify the popularity of each reaction type.

To gain a deeper understanding of the key insights, I transitioned into conducting analysis centered around the core business question. I was particularly curious about what really are these top-performing categories. The result shows 

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

    Top-performing categories: Animal, Science, Healthy Eating, Technology and Food respectively. 
    
 
Further analysis was then conducted to uncover the underlying factors influencing these results. It revealed that content type (including whether it was posted as a photo, video, audio, etc.) and the day of the week (content preferences varied based on different days of the week) played pivotal roles.

# Data Visualisation

The data was loaded into Power BI for further analysis and visalisation 

Results: 
- Content type, day of the week are drivers of activities
- Thursdays are the most active days of the week

Insights: 
- Animal and science are the two most popular content categories, showing that most users are animal lovers and have a desire for scientific knowledge.
- Food content are very popular, both healthy and unhealthy. This indicates that users enjoy a wide range of culinary experiences, from balanced meals to occasional treats. 

See the dashboard at the top of the page. 

Check out the full SQL queries and feel free to reach out for contributions or questions. 

#OKBye!

