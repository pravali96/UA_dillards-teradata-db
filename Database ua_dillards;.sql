Database ua_dillards;

help table strinfo;

help column trnsact.SKU;

select top 10 *
from strinfo
order by city asc; -- top 10 for top

select * from strinfo
sample 10; --instead of limit

SELECT *
FROM strinfo
SAMPLE .10; --top 10%

show table skuinfo;

select * from skuinfo sample 20;

select * from deptinfo ;

select * from trnsact ; 

--Examine which tables have fewer distinct rows that they have total rows
select distinct dept, brand from skuinfo ;  --actual number of rows 1564178

--Examine instances of transaction table where “amt” is different than “sprice”. 
--What did you learn about how the values in “amt”, “quantity”, and “sprice” relate to one 
--another?
select amt, quantity, sprice from trnsact where amt<>sprice
--amt is qty*sprice

select * from trnsact where orgprice=0 --1425811 rows have org price as 0

select * from skstinfo where cost=0 and retail=0; --350340 rows

select * from skstinfo where cost>retail; --7540289rows
-- it is very unlikely that a  manufacturer would provide a suggested retail price that is lower than the cost of the item

--Week3 -----------------------------------------------------------------

select count(distinct t.SKU), count(distinct skuinfo.sku)
from trnsact t Full JOIN skuinfo on t.sku = skuinfo.sku
where skuinfo.sku is NULL or t.sku is NULL --849679 dis skus in skuinfo

select count(distinct skstinfo.sku), count(distinct skuinfo.sku)
from skstinfo Full JOIN skuinfo on skstinfo.sku = skuinfo.sku
where skuinfo.sku is NULL or skstinfo.sku is NULL --skuninfo has 803966 dis skus

/*  Use COUNT and DISTINCT to determine how many distinct skus there are in pairs of the
skuinfo, skstinfo, and trnsact tables. Which skus are common to pairs of tables, or unique to specific
tables?*/
select count(distinct t.sku) as tsku, count(distinct st.sku) as stsku
from (trnsact t inner join skstinfo st on t.sku=st.sku and t.store=st.store) inner join  skuinfo sk
on t.sku=sk.sku -- 526366

/* Use COUNT to determine how many instances there are of each sku associated with each store in the 
skstinfo table and the trnsact table? */
select store, count(sku) from trnsact group by store order by store;
select store, count(sku) from skstinfo group by store order by store;
-- there are multiple instances of store/sku combinations in trnsact and single instances in skstinfo
select t.*, st.*
from trnsact t inner join skstinfo st on t.sku=st.sku and t.store=st.store

/* (a) Use COUNT and DISTINCT to determine how many distinct stores there are in the 
strinfo, store_msa, skstinfo, and trnsact tables.*/

select count(distinct str.store)
from strinfo str; --453

select count(distinct msa.store)
from  store_msa msa;--333

select count(distinct store)
from  skstinfo; --357

select count(distinct store)
from  trnsact; --332 

/* Stores common to all 4 tables */
select count(distinct st.store) 
from ((strinfo st inner join trnsact t on t.store=st.store)
 inner JOIN store_msa as msa on t.store=msa.store) 
 inner join skstinfo as sk on str.store=sk.store;

/*: It turns out there are many skus in the trnsact table that are not in the skstinfo table. As a 
consequence, we will not be able to complete many desirable analyses of Dillard’s profit, as opposed to 
revenue, because we do not have the cost information for all the skus in the transact table (recall that 
profit = revenue - cost). Examine some of the rows in the trnsact table that are not in the skstinfo table; 
can you find any common features that could explain why the cost information is missing?*/

SELECT t.* 
from trnsact t left join skstinfo sk on t.sku=sk.sku and t.store =sk.store
where sk.cost is NULL;

/* What is Dillard’s average profit per day?*/
--profit=revunue-cost
--avg profit = profit/num of days
--profit = amt - qty*cost
select t.register, sum(t.amt-(t.quantity*sk.cost)) as total_profit,
count(distinct(t.saledate)) as NumOfDays, (total_profit/NumOfDays) as avg_profit
from trnsact t left join skstinfo sk on t.sku=sk.sku and t.store = sk.store
where t.register=640 and t.stype='P'
group by t.register;

SELECT t.saledate, sum(amt) as total_returned
from trnsact t 
where t.stype='R'
GROUP BY saledate
ORDER by total_returned DESC -- 04/12/27 $3030259.76

SELECT t.saledate, sum(quantity) as total_items_returned
from trnsact t 
where t.stype='R'
GROUP BY saledate
ORDER by total_items_returned DESC -- #04/12/27 82512

/* Exercise 6: What is the maximum price paid for an item in our database? What is the minimum price
paid for an item in our database? */
SELECT MAX(amt) as max_price, MIN(amt) as min_price
FROM trnsact
WHERE stype='P'; --max:6017.00    min: 0.00
 
 /* How many departments have more than 100 brands associated with them, and what are their 
descriptions?*/
select d.dept, count(distinct s.brand) as num_Brands, d.deptdesc
from deptinfo d left join skuinfo s on s.dept=d.dept
group by d.dept, d.deptdesc
having num_Brands > 100 --3 brands- environ, carters,  colehaan

/* query that retrieves the department descriptions of each of the skus in the skstinfo 
table. */
select distinct sk.sku, d.deptdesc
from (skstinfo as sk left join skuinfo s on s.sku=sk.sku)
 left join deptinfo d on d.dept=s.dept 
where sk.sku=5020024

/* What department (with department description), brand, style, and color had the greatest total 
value of returned items? What department (with department description), brand, style, and color had the greatest total 
value of returned items? */

select d.dept, d.deptdesc, sk.brand, sk.color, sk.style, sum(t.amt) as returned
from (deptinfo d left join skuinfo sk on d.dept=sk.dept) 
    left join trnsact t on t.sku=sk.sku
where t.stype='R'
group by d.dept, d.deptdesc, sk.brand, sk.color, sk.style
order by returned desc;
-- 4505 -- POLOMEN -- POLO FAS -- U KHAKI --4GZ 782633  --216633.59

/*In what state and zip code is the store that had the greatest total revenue during the time 
period monitored in our dataset? */
select si.state, si.city,si.zip, si.store,sum( t.amt) as total_rev
from strinfo as si left join trnsact t on si.store=t.store 
where t.stype='P'
GROUP BY  si.state, si.zip, si.city, si.store
ORDER by total_rev desc;

select t.saledate, sum(t.amt) as purchases
from trnsact where stype='P'
GROUP BY  saledate
order by purchases desc

select d.deptdesc, count(sku) as num
from deptinfo d right join skuinfo on d.dept=skuinfo.dept 
group by d.deptdesc
order by num desc

select count(distinct sku) from skuinfo;

select count(distinct st.sku)
from skstinfo st left join skuinfo sk
on st.sku=sk.sku 
where sk.sku is NULL

--8
select m.state, (m.msa), m.msa_pop, msa_income
from store_msa m
where m.state='NC'
order by msa_pop asc, msa_income desc;

--9
select s.dept, dd.deptdesc, s.brand, s.style, s.color, sum(amt) as highest_amt
from (trnsact t left join skuinfo s on t.sku=s.sku)
 left JOIN deptinfo dd on dd.dept=s.dept
where t.stype='P'
GROUP BY s.dept, dd.deptdesc, s.brand, s.style, s.color
ORDER BY highest_amt desc;

--10
select store, count(distinct sku) as num
from skstinfo
GROUP BY store
having num>180000;

--11
select DISTINCT sku, s.dept, s.brand, s.color 
from skuinfo s
where brand='federal'and color='rinse wash';

--12
select count(distinct sk.sku)
from skuinfo sk left join skstinfo st on sk.sku = st.sku
where st.sku is NULL;

--13
select top 10 s.store, s.city, s.state , sum(amt) as highest
from trnsact t join strinfo s on t.store=s.store 
where stype='P'
group by  s.store, s.city, s.state
ORDER by highest desc;

--15
select m.state, count(m.store ) as num
from strinfo m
GROUP BY  m.state
having num>10;

--16
select d.sku, d.brand, d.color, dd.deptdesc, s.retail
from (skuinfo d left join deptinfo dd on d.dept=dd.dept)
left join skstinfo s on d.sku = s.sku
where d.brand='skechers'and d.color='wht/saphire'and dd.deptdesc='reebok';

--week 5
--1
select extract(year from saledate)as yr, extract(month from saledate) as mon, count(DISTINCT saledate) as num 
from trnsact
group by yr, mon
order by yr asc, mon asc;

--2
select sku, sum(amt) as total_sales
from trnsact 
where Extract(month from saledate) in (6,7,8) and stype='P'
GROUP BY sku 
order by total_sales desc
--sku-4108011 mon- 8 total_sales-1646017.38

--2 suggested
select distinct sku,
sum(case when extract(month from saledate)=6 and stype='p' then amt end) as rev_june,
sum(case when extract(month from saledate)=7 and stype='p' then amt end) as rev_july,
sum(case when extract(month from saledate)=8 and stype='p'
and extract(year from saledate)=12
then amt end) as rev_aug,
(rev_aug+rev_june+rev_july) as rev_total_tummer
from Trnsact
group by sku
order by rev_total_summer desc

--3
select extract(year from saledate) as yr, extract(month from saledate) as mon,
store as store_name, count(distinct saledate) as num
from trnsact 
where stype='P' 
group by yr, mon, store_name
order by num asc

--4
select store as store_name, extract(year from saledate) as yr, extract(month from saledate) as mon,
count(distinct saledate) as num, sum(amt) as rev, rev/num as avg_rev
from trnsact 
where stype='P'
group by store_name, mon, yr
order by avg_rev desc

--only purchases
--exclude all stores with less than 20 days of data
--exclude all data from Aug,2005

--5

select count(distinct t.store) as store_name,extract(year from t.saledate) as yr, extract(month from saledate) as mon,
count(distinct t.saledate) as num, sum(t.amt) as rev, rev/num as avg_rev,
case when msa_high<=60 and msa_high>49 then 'low'
when msa_high<=70 and msa_high>60 then 'medium'
when msa_high>70 then 'high'
end as education_pc
from trnsact t left join store_msa as sm on sm.store=t.store
where t.stype='P' and (extract(year from t.saledate)<>2005 and extract(month from saledate)<>8)
group by education_pc, yr, mon, store_name
having num>=20
order by avg_rev desc

select case when msa_high<=60 and msa_high>49 then 'low'
when msa_high<=70 and msa_high>60 then 'medium'
when msa_high>70 then 'high'
end as education_level,
sum(sub.rev)/sum(sub.num) as avg_daily_revenue
from store_msa s 
join (select store,extract(year from t.saledate) as yr,
 extract(month from saledate) as mon,
 sum(amt) as rev, count(distinct saledate) as num,
 case when (yr=2005 and mon=8) then 'exclude'
 else 'include' end as inc
 from trnsact t
 where t.stype='P' and inc='include'
 group by yr, mon, store 
 having num>=20) as sub on sub.store=s.store 
 GROUP BY education_level
/*
low 34159.76
medium 25037.89
high 20937.31
*/

--6
/*Compare the average daily revenues of the stores with the highest median 
msa_income and the lowest median msa_income. In what city and state were these stores, 
and which store had a higher average daily revenue?  */
select s.state, s.city, s.store,s.msa_income,
sum(sub.rev)/sum(sub.num) as avg_daily_revenue
from store_msa s 
join (select store,extract(year from t.saledate) as yr,
 extract(month from saledate) as mon,
 sum(amt) as rev, count(distinct saledate) as num,
 case when (yr=2005 and mon=8) then 'exclude'
 else 'include' end as inc
 from trnsact t
 where t.stype='P' and inc='include'
 group by yr, mon, store 
 having num>=20) as sub on sub.store=s.store 
 where s.msa_income in (
     (select max(msa_income) from store_msa),
     (select min(msa_income) from store_msa)
 )
 GROUP BY  s.state, s.city, s.store, s.msa_income

--7
 /*
 What is the brand of the sku with the greatest standard deviation in sprice? 
Only examine skus that have been part of over 100 sales transactions.
 */
select distinct t.sku as item, s.brand, stddev_samp(t.sprice) as dev_price,
COUNT(DISTINCT(t.SEQ||t.STORE||t.REGISTER||t.TRANNUM||t.SALEDATE)) AS distinct_transactions
from trnsact t join skuinfo s on t.sku=s.sku
WHERE t.stype='p'
HAVING distinct_transactions>100
GROUP BY item, s.brand
ORDER BY dev_price DESC

--8
select distinct t.sku as item, s.brand, 
avg(t.sprice),stddev_samp(t.sprice) as dev_price,
avg(t.orgprice)-avg(t.sprice) AS sale_price_diff,
COUNT(DISTINCT(t.SEQ||t.STORE||t.REGISTER||t.TRANNUM||t.SALEDATE)) AS distinct_transactions
from trnsact t join skuinfo s on t.sku=s.sku
WHERE t.stype='p'
GROUP BY item, s.brand
HAVING distinct_transactions>100
ORDER BY dev_price DESC

--9
/* What was the average daily revenue Dillard’s brought in during each month of 
the year? */
select extract(year from saledate) as yr, extract(month from saledate) as mon,
count(distinct saledate) as num, sum(amt) as rev, rev/num as avg_rev
from trnsact 
where stype='P'
group by mon, yr
order by yr desc, mon desc

--10
/*Which department, in which city and state of what store, had the greatest % 
increase in average daily sales revenue from November to December?*/
select sub.store,
sum(case when sub.mon=11 then sub.amt end) as nov_rev,
sum(case when sub.mon=12 then sub.amt end) as dec_rev,
count(distinct case when sub.mon=11 then sub.saledate end) as nov_days,
count(distinct case when sub.mon=12 then sub.saledate end) as dec_days,
nov_rev/nov_days as nov_daily_rev, 
dec_rev/dec_days as dec_daily_rev,
((dec_daily_rev-nov_daily_rev)*100)/(nov_daily_rev) as pc_increase
from (select store, amt, extract(month from saledate) as mon,
extract(year from saledate) as yr,
(case when (yr=2005 and mon=8) then 'exclude' else 'include' END) as ex
from trnsact 
where stype='P' and ex='include'
) as sub
GROUP BY sub.store
having nov_days>=20 and dec_days>=20
order by pc_increase desc

/*Which department, in which city and state of what store, had the greatest % 
increase in average daily sales revenue from November to December? */
select sub.store, sub.dept, sub2.city,  sub2.state,
sum(case when sub.mon=11 then sub.amt end) as nov_sales,
sum(case when sub.mon=12 then sub.amt end) as dec_sales,
count(distinct case when sub.mon=11 then sub.saledate end) as nov_days,
count(distinct case when sub.mon=12 then sub.saledate end) as dec_days,
nov_sales/nov_days as nov_rev,
dec_sales/dec_days as dec_rev,
((dec_rev-nov_rev)/nov_rev)*100 as pc_inc
from(select s.dept,t.store,t.saledate,
extract(month from t.saledate) as mon,
extract(year from t.saledate) as yr,
t.amt,(case when (yr=2005 and mon=8) then 'exclude' else 'include' END) as ex
 from skuinfo s join trnsact t on t.sku=s.sku
where t.stype='P' and ex='include') as sub join(select store, state, city from strinfo) as sub2 on sub2.store=sub.store
group by  sub.dept,sub.store,sub2.state, sub2.city
having nov_days>=20 and dec_days>=20
order by pc_inc desc
--Asheville, NC had 14 pc increase in revenue
--High Point, NC has 325pc inc in dept 4303 in store 4704

--Question 11
/*What is the city and state of the store that had the greatest decrease in 
average daily revenue from August to September?*/
Select sub.store, sub2.city,  sub2.state,
sum(case when sub.mon=8 then sub.amt end) as aug_sales,
sum(case when sub.mon=9 then sub.amt end) as sept_sales,
count(distinct case when sub.mon=8 then sub.saledate end) as aug_trns,
count(distinct case when sub.mon=9 then sub.saledate end) as sept_trns,
aug_sales/aug_trns as aug_rev, sept_sales/sept_trns as sept_rev,
(sept_rev-aug_rev) as rev_dec
from (select t.store, saledate, amt,
extract(month from saledate) as mon,
extract(year from saledate) as yr,
(case when(yr=2005 and mon=8) then 'exclude' else 'include' end) as inc_exc
from trnsact t
where stype='P' and inc_exc='include') as sub join (select s.store, state, city
from strinfo s) as sub2 on sub2.store=sub.store 
group by sub.store,  sub2.city,sub2.state
having aug_trns>19 and sept_trns>19
order by rev_dec asc

--Question 12
/* Determine the month of minimum total revenue for each store. Count the 
number of stores whose month of minimum total revenue was in each of the twelve months. 
Then determine the month of minimum average daily revenue. Count the number of stores 
whose month of minimum average daily revenue was in each of the twelve months. How do 
they compare?*/
select store as store_name, extract(year from saledate) as yr, extract(month from saledate) as mon,
count(distinct saledate) as num, sum(amt) as rev, rev/num as avg_rev
from trnsact 
where stype='P'
group by store_name, mon, yr
order by avg_rev desc

--gives out highest avg_daily_rev for each store in a given month
select sub.store, (case sub.mon
when 1 then 'Jan'
when 2 then 'Feb'
when 3 then 'Mar'
when 4 then 'Apr'
when 5 then 'May'
when 6 then 'Jun'
when 7 then 'Jul'
when 8 then 'Aug'
when 9 then 'Sep'
when 10 then 'Oct'
when 11 then 'Nov'
when 12 then 'Dec'
end) as Pmonth, sum(sub.total_rev)/sum(num_days) as avg_daily_rev
from (select store, extract(month from saledate)as mon, 
    extract(year from saledate)as yr, sum(amt) as total_rev,
    count(distinct saledate) as num_days,
    (case when (mon=8 and yr=2005) then 'exclude' else 'include' end) as inc
    from trnsact
    where stype='P' and inc='include'
    group by store,mon,yr
    having num_days>=20) as sub
group by 2,1
order by 3 desc

--Assign a rank to each of the ordered rows using rank() and partition()
select sub.store, (case sub.mon
when 1 then 'Jan'
when 2 then 'Feb'
when 3 then 'Mar'
when 4 then 'Apr'
when 5 then 'May'
when 6 then 'Jun'
when 7 then 'Jul'
when 8 then 'Aug'
when 9 then 'Sep'
when 10 then 'Oct'
when 11 then 'Nov'
when 12 then 'Dec'
end) as Pmonth, sum(sub.total_rev) as sum_monthly_rev,sum(sub.total_rev)/sum(num_days) as avg_daily_rev,
row_number() OVER (PARTITION by sub.store order by avg_daily_rev desc) as avg_rev_rownum,
row_number() over (partition by sub.store order by sum_monthly_rev desc) as total_rev_rownum
from (select store, extract(month from saledate)as mon, 
    extract(year from saledate)as yr, sum(amt) as total_rev,
    count(distinct saledate) as num_days,
    (case when (mon=8 and yr=2005) then 'exclude' else 'include' end) as inc
    from trnsact
    where stype='P' and inc='include'
    group by store,mon,yr
    having num_days>=20) as sub
group by 2,1
order by 3 desc

-- see how many stores have their hightest total revenue and avg rev in each of the months
select sub2.Pmonth as s_month,
count(case when sub2.total_rev_rownum=1 then sub2.store end) as monthly_rev_count,
count(case when sub2.avg_rev_rownum=1 then sub2.store end) as avg_rev_count
from (select sub.store, (case sub.mon
    when 1 then 'Jan'
    when 2 then 'Feb'
    when 3 then 'Mar'
    when 4 then 'Apr'
    when 5 then 'May'
    when 6 then 'Jun'
    when 7 then 'Jul'
    when 8 then 'Aug'
    when 9 then 'Sep'
    when 10 then 'Oct'
    when 11 then 'Nov'
    when 12 then 'Dec'
    end) as Pmonth, sum(sub.total_rev) as sum_monthly_rev,sum(sub.total_rev)/sum(num_days) as avg_daily_rev,
    row_number() OVER (PARTITION by sub.store order by avg_daily_rev desc) as avg_rev_rownum,
    row_number() over (partition by sub.store order by sum_monthly_rev desc) as total_rev_rownum
    from (select store, extract(month from saledate)as mon, 
        extract(year from saledate)as yr, sum(amt) as total_rev,
        count(distinct saledate) as num_days,
        (case when (mon=8 and yr=2005) then 'exclude' else 'include' end) as inc
        from trnsact
        where stype='P' and inc='include'
        group by store,mon,yr
        having num_days>=20) as sub
    group by 2,1) as sub2
GROUP BY 1
order by 2 desc

--321 stores have the highest monthly sales in the time
-- of dec and 317 store have their highest avg sales in dec.
--Followed by 3 each in July, then March and Sept

--Lowest total monthly revenue and avg_revenue
select sub2.Pmonth as s_month,
count(case when sub2.total_rev_rownum=1 then sub2.store end) as monthly_rev_count,
count(case when sub2.avg_rev_rownum=1 then sub2.store end) as avg_rev_count
from (select sub.store, (case sub.mon
    when 1 then 'Jan'
    when 2 then 'Feb'
    when 3 then 'Mar'
    when 4 then 'Apr'
    when 5 then 'May'
    when 6 then 'Jun'
    when 7 then 'Jul'
    when 8 then 'Aug'
    when 9 then 'Sep'
    when 10 then 'Oct'
    when 11 then 'Nov'
    when 12 then 'Dec'
    end) as Pmonth, sum(sub.total_rev) as sum_monthly_rev,sum(sub.total_rev)/sum(num_days) as avg_daily_rev,
    row_number() OVER (PARTITION by sub.store order by avg_daily_rev asc) as avg_rev_rownum,
    row_number() over (partition by sub.store order by sum_monthly_rev asc) as total_rev_rownum
    from (select store, extract(month from saledate)as mon, 
        extract(year from saledate)as yr, sum(amt) as total_rev,
        count(distinct saledate) as num_days,
        (case when (mon=8 and yr=2005) then 'exclude' else 'include' end) as inc
        from trnsact
        where stype='P' and inc='include'
        group by store,mon,yr
        having num_days>=20) as sub
    group by 2,1) as sub2
GROUP BY 1
order by 2 desc

--lowest sales_revenue is recorded in Sept, Aug, Jan, Nov, Oct, Mar
