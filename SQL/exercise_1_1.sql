WITH TOTAL_USERS as (
    select count(*) as total_users from Users
),
USERS_BY_SOURCE as (
    select source, count(*) as source_cnt
    from Users u
    inner join Businesses b
    on u.id = b.user_id
    where b.monthly_plan is not NULL
    group by source
),
CONVERSION_RATE as (
    select source, CAST(source_cnt as FLOAT)/ total_users as conversion_rate
    from USERS_BY_SOURCE
    cross join TOTAL_USERS
)

select * from CONVERSION_RATE
order by conversion_rate desc