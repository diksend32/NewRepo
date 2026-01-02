-- PART I: SCHOOL ANALYSIS
-- 1. View the schools and school details tables
select	*
from	schools;
select	*
from	school_details;

-- 2. In each decade, how many schools were there that produced players?

select  round(yearID, -1) as decade, count(schoolID) as total 
from schools
group by round(yearID, -1) 
order by round(yearID, -1);
-- 3. What are the names of the top 5 schools that produced the most players?
select	sd.name_full, count(distinct s.playerID) as total
from	schools s
inner join school_details sd on sd.schoolID = s.schoolID 
group by sd.name_full
order by count(s.playerID) desc
limit 5;
-- 4. For each decade, what were the names of the top 3 schools that produced the most players?
with cte as(
select	round(yearID, -1) as decade, schoolID, count(DISTINCT playerID)as total
from	schools
group by round(yearID, -1), schoolID
order by round(yearID, -1))
, cte2 as(
select decade, schoolID, total, row_number() over(partition by decade order by total desc) as r
from cte
order by decade)
select decade, schoolID, total
from cte2
where r between 1 and 3;



-- PART II: SALARY ANALYSIS
-- 1. View the salaries table
select	*
from	salaries;
-- 2. Return the top 20% of teams in terms of average annual spending
with cte1 as(
			select	teamID, yearID, sum(salary) as total
			from	salaries
			group by teamID, yearID
),
cte2 as(
select	teamID, avg(total) as avg_sp, ntile(5) over(order by avg(total) desc) as n
from	cte1
group by teamID)
select	teamID, avg_sp
from	cte2
where n=1;
-- 3. For each team, show the cumulative sum of spending over the years
with cte as(
		select	teamID, yearID, sum(salary) as total
		from	salaries
		group by teamID, yearID
		order by  teamID
)
select	teamID, yearID, total, sum(total) over(partition by teamID order by yearID) as cum_sum
from	cte;
-- 4. Return the first year that each team's cumulative spending surpassed 1 billion
with cte1 as(
		select	teamID, yearID, sum(salary) as total
		from	salaries
		group by teamID, yearID
		order by  teamID
),
cte2 as (
select	teamID, yearID, total, sum(total) over(partition by teamID order by yearID) as cum_sum
from	cte1
),
cte3 as (
select	*, row_number() over(partition by teamID order by cum_sum) as r
from	cte2
where	cum_sum > 1000000000)
select	teamID, yearID, total, round(cum_sum/1000000000,2) as cum_sum_billion
from	cte3
where	r=1;
-- PART III: PLAYER CAREER ANALYSIS
-- 1. View the players table and find the number of players in the table
select	count(distinct playerID) number_of_players
from	players;
-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.
select	distinct playerID, nameFirst, nameLast, TIMESTAMPDIFF(year,cast(concat(birthYear, '-', birthMonth, '-', birthDay)as date), debut) as debut_age,
		TIMESTAMPDIFF(year,cast(concat(birthYear, '-', birthMonth, '-', birthDay)as date), finalGame) as final_age, timestampdiff(year, debut, finalGame) as career_length 
from players
order by timestampdiff(year, debut, finalGame) desc;

-- 3. What team did each player play on for their starting and ending years?
select	 p.nameGiven, p.debut, d.teamID as debut_team, p.finalGame, f.teamID as final_team
from	players p
inner join salaries d on (p.playerID = d.playerID) and (year(p.debut)=d.yearID)
inner join salaries f on (p.playerID=f.playerID) and (year(p.finalGame)=f.yearID);

-- 4. How many players started and ended on the same team and also played for over a decade?
with cte as (
			select	p.nameGiven, p.debut, d.teamID as debut_team, p.finalGame, f.teamID as final_team
			from	players p
			inner join salaries d on (p.playerID = d.playerID) and (year(p.debut)=d.yearID)
			inner join salaries f on (p.playerID=f.playerID) and (year(p.finalGame)=f.yearID))
select	count(nameGiven) as number_of_players
from cte
where debut_team = final_team and timestampdiff(year, debut, finalGame) > 10;

-- PART IV: PLAYER COMPARISON ANALYSIS
-- 1. View the players table
select	*
from	players;
-- 2.  Which players have the same birthday?
select	p1.nameGiven, p2.nameGiven
from	players p1
inner join players p2 on p1.playerID <> p2.playerID and p1.birthMonth=p2.birthMonth and p1.birthDay=p2.birthDay and p1.birthYear=p2.birthYear;
-- with Group concat
with cte as (
select	concat(birthYear, '-', birthMonth, '-', birthDay) as birthdate, nameGiven
from	players
)
select birthdate, group_concat(nameGiven separator ', ')
from cte
where birthdate is not null and year(birthdate) between 1980 and 1990
group by birthdate
order by birthdate;

-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both
select	s.teamID, round(sum(case when bats = 'L' then 1 else 0 end)/count(bats)*100, 2) as l,
		round(sum(case when bats = 'R' then 1 else 0 end)/count(bats)*100,2) as R,
        round(sum(case when bats = 'B' then 1 else 0 end)/count(bats)*100,2) as B
from	salaries s
inner join players p on p.playerID=s.playerID
group by s.teamID;
-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?
select	year(debut) years, avg(height) as avg_h, avg(weight) as avg_w 
from	players
group by year(debut)
order by year(debut);

-- decade-over-decade difference
with cte as (
select	round(year(debut),-1) decade, avg(height) as avg_h, avg(weight) as avg_w
from	players
group by round(year(debut),-1)
order by round(year(debut),-1))

select	decade, avg_h-lag(avg_h) over(order by decade) as height_diff,
		avg_w-lag(avg_w) over(order by decade) as weight_diff
from	cte
