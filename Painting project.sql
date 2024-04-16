create database painting
use painting
select * from artist
select * from canvas_Size
select * from image_link
select * from museum
select * from museum_hours
select * from product_size
select * from dbo.subject
select * from work


--Identify the museum names which are open on sunday or monday
with CTE AS (
				select DISTINCT museum_id
				from (
						select * ,
						case when day = 'sunday' then 'Open'
						when day = 'Monday' then 'Open'
						else 'close'
						end Status
						from
						museum_hours )x 
				where Status = 'Open') 

SELECT CTE.museum_id, museum.name , museum.city
from museum right join CTE on museum.museum_id = CTE.museum_id





-- Identify the museum which are open on sunday and monday 
select m.name, m.city, m.state, m.country
FROM museum_hours mh join museum m
on m.museum_id = mh.museum_id 
where day in ('sunday','monday') 
group by m.name, m.city, m.state, m.country
having count(day)=2
ORDER BY m.name;

-- Fetch all the paintings which are not displayed on any of the museums 
select work_id, museum_id
from work
where museum_id IS NUll
group by work_id, museum_id

--ARE There any museums without paintings

select *
from museum
select * from work

select m.museum_id, m.name, w.work_id
from work w right join museum m
on w.museum_id = m.museum_id
where w.work_id is null

--How many paintings asking price is more than regular price?

select * from product_size 
where sale_price > regular_price

----how many painting asking price is 50% less than regular price?
select * from product_size
where sale_price > (regular_price*0.5)

--Which canvas size cost the most
with top_size as (
				select top 1 size_id , sale_price
				from product_size
				group by size_id, sale_price
				order by sale_price desc) 
select c.size_id , c.label , ts.sale_price
from canvas_size c join top_size ts
on c.size_id = ts.size_id


--delete duplicate records from work, product_size, subject , image_link tables

with duplicate_work as (
					SELECT work_id, COUNT(*) AS cn
					FROM work
					GROUP BY work_id
					HAVING COUNT(work_id) > 1)
delete from work
where work_id in (select work_id from duplicate_work)

select *
from product_size

with productrow as (
					select *, row_number() over(partition by work_id order by work_id) as rn
					from product_size ) 

delete from product_size
where rn>1

WITH productrow AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY work_id ORDER BY work_id) AS rn
    FROM product_size
) 
DELETE FROM productrow 
WHERE rn > 1;
--6771 rows were before
with subject_row as (
					select *, row_number() over (partition by work_id order by work_id) as rn 
					from subject)
delete from subject_row
where rn>1

select *
from subject

--image_link
with imagelinkrn as (
					select * , row_number() over (partition by work_id order by work_id ) rn
					from image_link)
delete from imagelinkrn
where rn>1

--Identify the museums with invalid city names
SELECT *
FROM museum
WHERE city NOT LIKE '%[a-zA-Z ]%';

--like '%[a-zA-z]%'
--remove the invalid entry in museum hours
with CTE AS (
			select * , row_number() over (partition by museum_id order by museum_id) as rn
			from museum_hours)
SELECT * FROM CTE
WHERE rn =1

--Fetch the top 10 most famous painting subject
select top 10 subject, count(*) as Cn
from subject
group by subject
order by Cn desc


--How many museums are open every single day
select distinct museum_id
from museum_hours
where day in ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')

SELECT museum_id
FROM museum_hours
GROUP BY museum_id
HAVING COUNT(DISTINCT day) = 7;



--Which are top 5 popular museum defined by number of paintings

with top5 as (
				select top 5 museum_id, count(work_id) as cn
				from work
				where museum_id is not null
				group by museum_id
				order by count(work_id) desc )
select m.museum_id, m.name , t.cn
from museum m right join top5 t
on m.museum_id = t.museum_id

--who are most 5 popular artist- defined by most no of paintings done by an artist
 
 with CTE AS (
			select top 5 artist_id, count(work_id) as cn
			from work
			group by artist_id
			order by count(work_id) desc)
Select C.artist_id, A.full_name, C.cn
from CTE c left join artist A
on c.artist_id = A.artist_id

--display 3 least populat canva sizes

select top 3 c.size_id,c.label, count(c.size_id) as cn
from product_size p left join canvas_size c
on p.size_id = c.size_id
where c.size_id is not null
group by c.size_id, c.label
order by cn asc



--Which museum has the most no of most popular painting style?

with CTE as (
			select m.museum_id, m.name , w.style
			from museum m left join work w
			on m.museum_id = w.museum_id	)
select top 5 name , count(style) cn
from CTE
group by name
order by cn desc

--alternative solution
with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;



--Identify the artists whose paintings are displayed in multiple countries



with CTE AS (
				select distinct w.artist_id , m.country
				from museum m left join work w on m.museum_id = w.museum_id )
	
select c.artist_id,a.full_name, count(c.country) as country_count
from CTE c left join artist a on a.artist_id = c.artist_id
group by c.artist_id,a.full_name
having count(c.country) >1
order by country_count desc


--Which country has the 5th highest no of paintings?


select * from (
			select distinct m.country, count(w.work_id) as no_of_paintings,
			rank() over (order by count(w.work_id) desc) as Rn
			from museum m left join work w
			on m.museum_id = w.museum_id
			group by m.country ) X
			where Rn = 5

--Which are the 3 most popular and 3 least popular painting styles?
select * from work
with CTE AS (
			select style , count(style) as CN, count(*) over() as no_of_records, rank() over (order by count(style) desc) as RN
			from work 
			WHERE style is not null
			group by style )

select C.style, 
case when RN < 4 THEN 'MOST POPULAR'
 ELSE 'LEAST POPULAR' END as Popularity
FROM CTE C
WHERE RN <=3 OR RN > no_of_records - 3


--Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.


select a.full_name, a.nationality, count(w.work_id)as no_of_paintings,
rank() over (order by count(w.work_id) desc) as Rnk
from
artist a join work w on a.artist_id = w.artist_id
join museum m on m.museum_id = w.museum_id
join subject s on s.work_id = w.work_id
where m.country != 'USA' and s.subject = 'Portraits' 
group by a.full_name, a.nationality







select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;








			



















