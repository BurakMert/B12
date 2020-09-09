CREATE VIEW funnel_cohort_status as
WITH COHORTS as(
select *,
       cast(strftime('%w', event_timestamp) as int) as dow,
       date(event_timestamp) as cohort_date, -- Cohorts by day
       case
           when
                event_type = 'signup_flow_end' and event_timestamp <= datetime(created_timestamp, '+24 hours') then 1 else 0
           end as signup_within_1_day -- Create binary flag for signup_within_1_day analytics
from Users
join Events
on Users.id = Events.user_id
where dow not in (0,6) -- Filter weekend
and event_timestamp > created_timestamp -- Filter erroneous records
),
COHORT_TOTAL_USERS as (
    select cohort_date,
           count(distinct(user_id)) as total_users, -- Need to count distinct users here since one user might have multiple different events
           sum(signup_within_1_day) as total_signup_within_1_day
    from COHORTS
    group by cohort_date
),
COHORT_EVENT_ANALYSIS as(
    select cohort_date, event_type, count(user_id) as total_users_by_event
    from COHORTS
    group by cohort_date, event_type
),
FUNNEL_ANALYTICS as (
    SELECT cohort_date,
           max(total_users)               as total_users,
           max(total_signup_start)        as total_signup_start,
           max(total_signup_end)          as total_signup_end,
           max(total_ai_view)             as total_ai_view,
           max(total_signup_within_1_day) as total_signup_within_1_day,
           max(CAST(total_signup_end as float))/max(total_users)   as signup_finish_rate
    FROM (
             SELECT *,
                    CASE
                        WHEN event_type == 'signup_flow_start' then total_users_by_event
                        else 0 END                                                                 as total_signup_start,
                    CASE WHEN event_type == 'signup_flow_end' then total_users_by_event else 0 END as total_signup_end,
                    CASE WHEN event_type == 'ai_draft_view' then total_users_by_event else 0 END   as total_ai_view
             FROM COHORT_TOTAL_USERS
                      JOIN COHORT_EVENT_ANALYSIS
                           USING (cohort_date)
         ) -- Inner query for pivotting a events to columns
    GROUP BY cohort_date
    ORDER BY cohort_date DESC
)
select * from FUNNEL_ANALYTICS
