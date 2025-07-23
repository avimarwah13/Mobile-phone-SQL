use SQL_CASE_STUDIES
select*from DIM_CUSTOMER
select*from DIM_DATE
select*from DIM_LOCATION
select*from DIM_MANUFACTURER
select*from DIM_MODEL
select*from FACT_TRANSACTIONS
--Q1. List all the states in which we have customers who have bought cell phones from 2005 till today.
select distinct State
from
FACT_TRANSACTIONS  as T1
right join DIM_CUSTOMER AS T2 on T1.IDCustomer=T2.IDCustomer
right join DIM_LOCATION as T3 ON T1.IDLocation=T3.IDLocation
where 
DATEPART(YEAR,Date)>=2005

--Q2.Which state in the US is buying more 'Samsung' cellphones?
select top 3 state,sum(cnt_of_qty1) from(
select state,sum(cnt_of_qty) as cnt_of_qty1 from(
select
Model_name,T4.IDManufacturer,Manufacturer_name,state,count(Quantity) as cnt_of_qty,Country
from
FACT_TRANSACTIONS AS T1
right join DIM_MODEL AS T2 ON T1.IDModel=T2.IDModel
right join DIM_LOCATION AS T3 ON T1.IDLocation=T3.IDLocation
left join DIM_MANUFACTURER AS T4 ON T4.IDManufacturer=T2.IDManufacturer
WHERE
Manufacturer_Name like 'Sam%' and Country='US'
group by
Model_name,T4.IDManufacturer,Manufacturer_name,Country,State
) as tt
group by
State,cnt_of_qty
) as tt
group by
state,cnt_of_qty1
order by
cnt_of_qty1 desc

--Q3. Show the number of transactions for each model per zip code per state.
SELECT Manufacturer_Name,STATE,ZIPCODE,SUM(CNT_OF_TRANS) AS CNT_OF_TRANS_PER_MOD FROM (
select
state,zipcode,IDcustomer,MODEL_NAME,Manufacturer_Name,COUNT(Quantity) AS CNT_OF_TRANS
from
FACT_TRANSACTIONS AS T1
right join DIM_LOCATION AS T2 ON T1.IDLocation=T2.IDLocation
RIGHT JOIN DIM_MODEL AS T3 ON T1.IDModel=T3.IDModel
RIGHT JOIN DIM_MANUFACTURER AS T4 ON T4.IDManufacturer=T3.IDManufacturer
GROUP BY
state,zipcode,IDcustomer,MODEL_NAME,Manufacturer_Name
) AS TT
GROUP BY
STATE,ZIPCODE,Manufacturer_Name
order by 
ZipCode,CNT_OF_TRANS_PER_MOD desc,Manufacturer_Name
--Q4. Show the cheapest cellphone.
select TOP 1 Manufacturer_name,MIN(CHEAPEST_PRICE) AS CHEAPEST_PRICE from(
select manufacturer_name,min(totalprice) as CHEAPEST_PRICE from(
select totalprice,quantity,manufacturer_name,Model_Name
from
FACT_TRANSACTIONS as T1
RIGHT JOIN DIM_MODEL AS T2 ON T1.IDModel=T2.IDModel
RIGHT JOIN DIM_MANUFACTURER AS T3 ON T3.IDManufacturer=T2.IDManufacturer
) as t3
GROUP BY
manufacturer_name
) as tt
GROUP BY
Manufacturer_Name
ORDER BY
CHEAPEST_PRICE
--Q5. Find the Average price for each model in the top 5 manufacturers in terms of sales quantity and order by average price.
SELECT distinct MODEL_NAME,AVG(TOT_SALES) as AVG_PRICE FROM (
select distinct Top 5 
Manufacturer_Name,Model_Name,SUM(TOTALPRICE) AS TOT_SALES,Quantity
from
FACT_TRANSACTIONS as T1
right join DIM_MODEL AS T2 on T1.IDModel=T2.IDModel
right join DIM_MANUFACTURER AS T3 ON T2.IDManufacturer=T3.IDManufacturer
GROUP BY
Manufacturer_Name,Quantity,Model_Name
order by 
quantity desc) AS TT
GROUP BY
MODEL_NAME
ORDER BY
AVG_PRICE DESC

--Q6. List the names of the customers and the average amount spent in 2009,where the average is higher than 500.
select 
customer_name,avg(totalprice) AS AVG_PRICE,YEAR
FROM
FACT_TRANSACTIONS AS T1
RIGHT JOIN DIM_CUSTOMER AS T2 ON T1.IDCustomer=T2.IDCustomer
RIGHT JOIN DIM_DATE AS T3 ON T1.Date=T3.DATE
WHERE
YEAR=2009 
GROUP BY
Customer_Name,YEAR
HAVING
AVG(TOTALPRICE)>500

--Q7.List if there is any model that was in top 5 in terms of quantity,simulatenously in 2008,2009 and 2010.
WITH
  Ranking (IdModel, rn) AS (
    SELECT IdModel,
      RANK() OVER (PARTITION BY YEAR(Date) ORDER BY SUM(Quantity) DESC)
    FROM FACT_TRANSACTIONS
    WHERE YEAR(Date) IN (2008, 2009, 2010)
    GROUP BY YEAR(Date), IdModel
  )
SELECT IdModel
FROM Ranking
WHERE rn <= 5
GROUP BY IdModel
HAVING COUNT(*) = 3


--Q8.Show the manufacturer with the 2nd top sales  in the year 2009 and the manufacturer with the second top sales in the year of 2010.
WITH CTE_TABLE AS (
select manufacturer_name,tot_price,ROW_NUMBER() over(PARTITION BY YEAR order by tot_price desc) AS ROW_NUM,YEAR FROM(
select 
manufacturer_name,sum(totalprice) as TOT_PRICE,YEAR
from
FACT_TRANSACTIONS AS T1
RIGHT JOIN DIM_MODEL AS T2 ON T1.IDModel=T2.IDModel
RIGHT JOIN DIM_MANUFACTURER AS T3 ON T2.IDManufacturer=T3.IDManufacturer
RIGHT JOIN DIM_DATE AS T4 ON T4.DATE=T1.Date
WHERE
YEAR=2009 OR YEAR=2010
GROUP BY
Manufacturer_Name,YEAR
) AS TT)
SELECT  manufacturer_name,tot_price,YEAR
FROM
CTE_TABLE
WHERE
ROW_NUM=2
--Q9. Show the manufacturers that sold cellphone in 2010 but didn't in 2009.

--Wrong ANS
select 
Manufacturer_name,count(Quantity) as cnt_of_qty
from
fact_transactions as T1
right join DIM_MODEL AS T2 ON  T1.IDModel=T2.IDModel
RIGHT JOIN DIM_MANUFACTURER AS T3 ON T3.IDManufacturer=T2.IDManufacturer
RIGHT JOIN DIM_DATE AS T4 ON T4.DATE=T1.Date
WHERE
YEAR=2010 
GROUP BY
Manufacturer_Name
HAVING
count(Quantity)>0
Except 
select 
Manufacturer_name,count(Quantity) as cnt_of_qty
from
fact_transactions as T1
right join DIM_MODEL AS T2 ON  T1.IDModel=T2.IDModel
RIGHT JOIN DIM_MANUFACTURER AS T3 ON T3.IDManufacturer=T2.IDManufacturer
RIGHT JOIN DIM_DATE AS T4 ON T4.DATE=T1.Date
WHERE
YEAR=2009
GROUP BY
Manufacturer_Name
HAVING
count(Quantity)>0
ORDER BY
cnt_of_qty DESC

/**************************************************************/ --Correct ANS
select 
Manufacturer_name
from
fact_transactions as T1
right join DIM_MODEL AS T2 ON  T1.IDModel=T2.IDModel
RIGHT JOIN DIM_MANUFACTURER AS T3 ON T3.IDManufacturer=T2.IDManufacturer
RIGHT JOIN DIM_DATE AS T4 ON T4.DATE=T1.Date
WHERE
YEAR=2010 
GROUP BY
Manufacturer_Name
HAVING
count(Quantity)>0
Except 
select 
Manufacturer_name
from
fact_transactions as T1
right join DIM_MODEL AS T2 ON  T1.IDModel=T2.IDModel
RIGHT JOIN DIM_MANUFACTURER AS T3 ON T3.IDManufacturer=T2.IDManufacturer
RIGHT JOIN DIM_DATE AS T4 ON T4.DATE=T1.Date
WHERE
YEAR=2009
GROUP BY
Manufacturer_Name
HAVING
count(Quantity)>0
--Q10.Find the top 100 customers and their average spend,average quantity by each year. Also find the percentage of change in their spend.

WITH CTE_CUST AS( 
select top 100
customer_name,avg(totalprice) AS AVG_SPEND,avg(Quantity) as avg_of_qty,YEAR,SUM(TOTALPRICE) AS TOTAL_SALES,COUNT(CUSTOMER_NAME) AS CNT_OF_CUSTS,TotalPrice,Quantity
from
FACT_TRANSACTIONS as T1
right join DIM_CUSTOMER as T2 ON T1.IDCustomer=T2.IDCustomer
right join DIM_DATE AS T3 ON T1.Date=T3.DATE
group by
customer_name,YEAR,TotalPrice,Quantity
order by
avg_of_qty desc,
AVG_SPEND desc,
YEAR,
CNT_OF_CUSTS
)
SELECT CUSTOMER_NAME,TOTAL_SALES/AVG_SPEND*avg_of_qty AS PERCENTAGE_1,AVG_SPEND,avg_of_qty,YEAR,
case when year=2003 then TOTALPRICE*quantity END AS SALES_2003,
case when year=2004 then TOTALPRICE*quantity END AS SALES_2004,
case when year=2005 then TOTALPRICE*quantity END AS SALES_2005,
case when year=2006 then TOTALPRICE*quantity END AS SALES_2006,
case when year=2007 then TOTALPRICE*quantity END AS SALES_2007,
case when year=2008 then TOTALPRICE*quantity END AS SALES_2008,
case when year=2009 then TOTALPRICE*quantity END AS SALES_2009,
case when year=2010 then TOTALPRICE*quantity END AS SALES_2010
FROM
CTE_CUST
ORDER BY
AVG_SPEND desc,avg_of_qty desc,Customer_Name
--even if i try to use the inline view on this, their is no customer who is giving sales in 2 consecutive years.


