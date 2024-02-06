--select * from goldusers_signup
--select * from users
--select * from sales
--select * from product

--1.what is total amount each customer spent on zomato ?

select s.userid, sum(p.price)  as total_amount
from sales s
join product p
on s.product_id=p.product_id
group by user_id


--2.How many days has each customer visited zomato?
 select userid, count(distict created_date) as no_days
 from sales
 group by userid
 
--3.what was the first product purchased by each customer?
with cte as (select *
,dense_rank() over(partition by userid order by create_date asc) as d_rnk
from sales)

select userid,product_id
from cte 
where drnk=1

--4.what is most purchased item on menu & how many times was it purchased by all customers ?
with most_purchased_item as (
select product_id,count(product_id) as no_of_item_purchased
,dense_rank() over(order by count(product_id) desc) as d_rnk
from sales
group by product_id
)
select product_id,no_of_item_purchased from most_purchased_item
where d_rnk=1



--5.which item was most popular for each customer?
with most_popular_item as (
select *
--, row_number() over(partition by userid order by cnt desc) as rw
, rank() over(partition by userid order by cnt desc) as rk
from (select distinct userid,product_id
      ,count(product_id) over(partition by userid,product_id) as cnt
       from sales) A
)
select * from most_popular_item
where rk=1

--6.which item was purchased first by customer after they become a member ?
with purchased_after_member as (
select gold_signup_date,b.*,rank()over(partition by a.userid order by a.userid,created_date) as rnk
from goldusers_signup a
join sales b
on a.userid=b.userid and gold_signup_date<created_date
)
select userid,product_id from purchased_after_member
where rnk=1

--7. which item was purchased just before the customer became a member?
with purchasedbeforemember as (
select gold_signup_date,b.*,rank()over(partition by a.userid order by a.userid,created_date desc) as rnk
from goldusers_signup a
join sales b
on a.userid=b.userid and gold_signup_date>created_date
)
select * from purchasedbeforemember
where rnk=1

--8. what is total orders and amount spent for each member before they become a member?
select b.userid
,count(created_date) as total_order
,sum(price)  as total_amount
from goldusers_signup a
join sales b
on a.userid=b.userid and gold_signup_date>created_date
join product p
on b.product_id=p.product_id
group by b.userid
order by b.userid

/*9. If buying each product generates points for eg 5rs=2 zomato point . 
Each product has different purchasing points  
example- for product_id=1, 5rs=1 zomato point,
             product_id=2, 10rs=5 zomato point =2rs =1zomato point
	     and product_id=3, 5rs=1 zomato point. 
calculate points collected by each customer and for which product most points have been given till now.*/

with points_collected as (
select userid,product_id,sum(price) as total
, case when product_id=1 then 5 
       when product_id=2 then 2 
       when product_id=3 then 5 else 0 
	   end as point
from (select a.*,b.price from sales a
join product b
on a.product_id=b.product_id
) A
group by userid,product_id)

,cte2 as(
select *,total/point as point_earned
from points_collected )

select userid,sum(point_earned) as total_earned_point
from cte2 
group by userid

--2nd part of the Q9.
--and for which product most points have been given till now
with points_collected as (
select userid,product_id,sum(price) as total
, case when product_id=1 then 5 
       when product_id=2 then 2 
       when product_id=3 then 5 else 0 
	   end as point
from (select a.*,b.price from sales a
join product b
on a.product_id=b.product_id
) A
group by userid,product_id)

,cte2 as(
select *,total/point as point_earned
from points_collected )

,cte3 as (select product_id,sum(point_earned) as total_earned_point
,rank() over(order by sum(point_earned)desc) as rnk
from cte2 
group by product_id)

select * from cte3 where rnk=1


--10. In the first year after a customer joins the gold program (including the join date) 
--irrespective of what customer has purchased earn 5 zomato points for every 10rs spent
--who earned more  1 or 3 what was point earning in first yr ? 1zp = 2rs i.e; 0.5zp=1rs

select b.userid, b.created_date,b.product_id,p.price*0.5 as total_earned_point
from goldusers_signup a
join sales b
on a.userid=b.userid and a.gold_signup_date<=b.created_date
and b.created_date <= DATEADD(year, 1, a.gold_signup_date)
join product p
on b.product_id=p.product_id
order by b.userid

--11. rnk all transaction of the customers
select *,rank()over(partition by userid order by created_date) as rnk
from sales

--12. rank all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as 'na'
with ranked_transaction as (
select a.*,b.gold_signup_date
--,case when b.userid is null then 'na' else 'Gold memeber'  end as status
,cast(rank()over(partition by a.userid order by a.created_date) as varchar) as trans_rnk
from sales a
left join goldusers_signup b
on a.userid=b.userid 
where b.userid is not null)
select s.userid,s.created_date,COALESCE(trans_rnk, 'NA') AS rank_status
from sales s
left join ranked_transaction t
on s.userid=t.userid and s.created_date=t.created_date
order by s.userid, s.created_date;





