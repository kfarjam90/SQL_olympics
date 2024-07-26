SELECT * from olympics_history
SELECT * from olympics_history_noc_regions

--- 1. How many olympics games have been held?
	
SELECT count(DISTINCT games) as total_games from olympics_history

--- 2. List down all Olympics games held so far.
	
SELECT DISTINCT YEAR, olympics_history.season, olympics_history.city
from olympics_history ORDER by YEAR ASC

--- 3. Mention the total no of nations who participated in each olympics game?
	
SELECT oh.games , count(DISTINCT orgn.region) total_contries
from olympics_history as oh
left join
olympics_history_noc_regions as orgn
on oh.noc= orgn.noc
GROUP by oh.games

--- 4. Which year saw the highest and lowest no of countries participating in olympics
	
with all_countries as (
	select games, nr.region
	from olympics_history oh
	join olympics_history_noc_regions nr ON nr.noc=oh.noc
	group by oh.games, nr.region
	),
	tot_countries AS (
	select games , count(region) as total_countries
	from all_countries
	GROUP by games
	)
select DISTINCT
concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries
      order by 1;


--- 5. Which nation has participated in all of the olympic games

WITH total_games AS (
    SELECT nr.region, COUNT(DISTINCT oh.games) AS games_count
    FROM olympics_history oh
    JOIN olympics_history_noc_regions nr ON oh.noc = nr.noc
    GROUP BY nr.region
),
max_games AS (
    SELECT MAX(games_count) AS total_participate_games
    FROM total_games
)
SELECT tg.region, tg.games_count
FROM total_games tg
JOIN max_games mg ON tg.games_count = mg.total_participate_games;


--- 6. Identify the sport which was played in all summer olympics.

with t1 as (
	select count(DISTINCT(games)) as total from olympics_history
	where season = 'Summer'
),
	t2 as (
	SELECT sport, COUNT(DISTINCT games) AS no_of_games
	FROM olympics_history
	WHERE season = 'Summer'
	GROUP BY sport
)
select *
from t2
join t1 on t1.total = t2.no_of_games

--- 7. Which Sports were just played only once in the olympics.

with t1 as (
	select sport, count(distinct games) no_of_participant
	from olympics_history
	GROUP by sport
	),
	t2 as (
	select distinct games,sport from olympics_history
	)
select t2.sport,t1.no_of_participant,t2.games
from t1
join t2 on t1.sport = t2.sport
where no_of_participant = 1

--- 8. Fetch the total no of sports played in each olympic games.

SELECT games, COUNT(DISTINCT sport) AS sport_count
FROM olympics_history
GROUP BY games
order by sport_count DESC

--- 9. Fetch oldest athletes to win a gold medal

with t1 as (
	select *
	from olympics_history
	where medal = 'Gold' and age != 'NA'
),
	t2 as (
	select max(age) as max_age
	from olympics_history
	where medal = 'Gold' and age != 'NA'
	)
select *
from t1
where t1.age = (select max_age from t2)

--- 10. Find the Ratio of male and female athletes participated in all olympic games.

WITH gender_counts AS (
    SELECT 
        sex, 
        COUNT(*) AS count 
    FROM 
        olympics_history
    GROUP BY 
        sex
)
SELECT 
    ROUND(
        (SELECT count FROM gender_counts WHERE sex = 'M')::numeric / 
        (SELECT count FROM gender_counts WHERE sex = 'F')::numeric, 
        2
    ) AS male_to_female_ratio;

--- 11. Fetch the top 5 athletes who have won the most gold medals.

with t1 as (
	select name,team,medal,count(medal) as total_medal
	from olympics_history
	where medal = 'Gold' and age != 'NA'
	group by name,team,medal
	order by total_medal DESC
),
 t2 as (
	select *,dense_rank() over (ORDER by total_medal DESC) as rnk
	from t1
 )
select name, team, total_medal
from t2
where rnk <= 5

--- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).


with t1 as (
	select name,team,count(medal) as total_medal
	from olympics_history
	where medal != 'NA'
	group by name,team
	),
	t2 as (
	select *,dense_rank() over(order by total_medal DESC) as rnk
	from t1
	)
select name,team,total_medal
from t2
where rnk <= 5

--- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.


with t1 as (
	select distinct rn.region as region , count(medal) as toal_medal
	from olympics_history oh
	join olympics_history_noc_regions rn on oh.noc = rn.noc
	where medal != 'NA'
	group by region
	order by toal_medal desc
),
	t2 as (
	select * ,dense_rank() over(order by toal_medal desc) as rnk
	from t1
	)
select * from t2
where rnk <= 5

--- 14. List down total gold, silver and bronze medals won by each country.

SELECT 
    region,
    SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals,
    SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver_medals,
    SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_medals
FROM olympics_history oh
join olympics_history_noc_regions rn on oh.noc = rn.noc
GROUP BY 
    region
ORDER BY 
    gold_medals desc ;

--- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

SELECT 
    games,region,
    SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals,
    SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver_medals,
    SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_medals
FROM olympics_history oh
join olympics_history_noc_regions rn on oh.noc = rn.noc
GROUP BY 
    region,games
ORDER BY 
    games,region

--- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.


with t1 as (
	select games,region,medal, count(medal) as total_medal
	from olympics_history oh
	join olympics_history_noc_regions rn on oh.noc = rn.noc
	where medal IN ('Gold', 'Silver', 'Bronze')
	group by games,region,medal
	order by games
 ),

	t2 as (
	select games,medal,max(total_medal) as max_medal
	from t1
	group by games,medal
	)
select 
	t1.games,
    t1.region,
    t1.medal,
    t1.total_medal
from t1
join t2 on t1.games = t2.games and t1.total_medal = t2.max_medal and t1.medal = t2.medal

---- other way to solve

WITH temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    	 	, substring(games, position(' - ' in games) + 3) as country
            , coalesce(gold, 0) as gold
            , coalesce(silver, 0) as silver
            , coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    				  	, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))
    select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    			, first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
    from temp
    order by games;


--- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.


 with temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    		, substring(games, position(' - ' in games) + 3) as country
    		, coalesce(gold, 0) as gold
    		, coalesce(silver, 0) as silver
    		, coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    					, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint)),
    	tot_medals as
    		(SELECT games, nr.region as country, count(1) as total_medals
    		FROM olympics_history oh
    		JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    		where medal <> 'NA'
    		GROUP BY games,nr.region order BY 1, 2)
    select distinct t.games
    	, concat(first_value(t.country) over(partition by t.games order by gold desc)
    			, ' - '
    			, first_value(t.gold) over(partition by t.games order by gold desc)) as Max_Gold
    	, concat(first_value(t.country) over(partition by t.games order by silver desc)
    			, ' - '
    			, first_value(t.silver) over(partition by t.games order by silver desc)) as Max_Silver
    	, concat(first_value(t.country) over(partition by t.games order by bronze desc)
    			, ' - '
    			, first_value(t.bronze) over(partition by t.games order by bronze desc)) as Max_Bronze
    	, concat(first_value(tm.country) over (partition by tm.games order by total_medals desc nulls last)
    			, ' - '
    			, first_value(tm.total_medals) over(partition by tm.games order by total_medals desc nulls last)) as Max_Medals
    from temp t
    join tot_medals tm on tm.games = t.games and tm.country = t.country
    order by games;


--- 18. Which countries have never won gold medal but have won silver/bronze medals?

with country_with_silver_bronze as (
	select distinct nr.region as country,
	SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals,
    SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver_medals,
    SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_medals
	from olympics_history oh
	join olympics_history_noc_regions nr on oh.noc = nr.noc
	where medal <> 'NA' and medal in ('Silver', 'Bronze')
	group by country
),
	country_with_gold as (
	select distinct nr.region as country,
	SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals,
    SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver_medals,
    SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_medals
	from olympics_history oh
	join olympics_history_noc_regions nr on oh.noc = nr.noc
	where medal <> 'NA' and medal in ('Gold')
	group by country
	)
select *
from country_with_silver_bronze
where country not in (select country from country_with_gold)

--- 19. In which Sport/event, India has won highest medals.

with t1 as (
	select sport,count(medal) as total_medal
	from olympics_history oh
	join olympics_history_noc_regions nr on oh.noc = nr.noc
	where nr.region = 'India' and medal <> 'NA'
	group by sport
	order by total_medal desc
),
	t2 as (
		select *,dense_rank() over(order by total_medal desc) as rnk
		from t1
	)
select sport,total_medal
from t2
where rnk = 1

--- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

select team,sport,games,count(medal) as toal_medal
from olympics_history oh
join olympics_history_noc_regions nr on oh.noc = nr.noc
where nr.region = 'India' and medal <> 'NA' and sport = 'Hockey'
group by team,sport,games
order by toal_medal desc



