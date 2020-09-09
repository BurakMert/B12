WITH COHORTS as(
select *,
       cast(strftime('%w', created_timestamp) as int) as dow,
       date(event_timestamp) as cohort_date
from Users
join Events
on Users.id = Events.user_id
where dow not in (0,6)
and event_timestamp > created_timestamp
),
COHORT_TOTAL_USERS as (
    select cohort_date, count(user_id) as total_users
    from COHORTS
    group by cohort_date
),
COHORT_SIGNUP_FLOW_START_ANALYSIS as(
    select cohort_date, count(user_id) as total_users_by_signup_start
    from COHORTS
    where event_type = 'signup_flow_start'
    group by cohort_date

),
COHORT_SIGNUP_FLOW_END_ANALYSIS as(
    select cohort_date,  count(user_id) as total_users_by_signup_end
    from COHORTS
    where event_type = 'signup_flow_end'
    group by cohort_date

),
COHORT_AI_VIEW_ANALYSIS as(
    select cohort_date,  count(user_id) as total_users_by_ai_view
    from COHORTS
    where event_type = 'ai_draft_view'
    group by cohort_date
),
COHORT_SIGNUP_WITHIN_ONE_DAY_ANALYSIS as (
    select cohort_date, count(user_id) as total_signup_within_1_day
    from COHORTS
    where
          event_type = 'signup_flow_end' and
        event_timestamp <= datetime(created_timestamp, '+24 hours')
    group by cohort_date

)
select cohort_date,
       ifnull(total_users, 0) as total_users,
       ifnull(total_users_by_signup_start, 0) as total_users_by_signup_start,
       ifnull(total_users_by_signup_end, 0) as total_users_by_signup_end,
       ifnull(total_users_by_ai_view, 0) as total_users_by_ai_view,
       ifnull(total_signup_within_1_day, 0) as total_signup_within_1_day,
       CAST(ifnull(total_users_by_signup_end, 0) as FLOAT) / total_users as signup_completion_ratio
from COHORT_TOTAL_USERS
LEFT JOIN COHORT_SIGNUP_FLOW_START_ANALYSIS
USING (cohort_date)
LEFT JOIN COHORT_SIGNUP_FLOW_END_ANALYSIS
USING (cohort_date)
LEFT JOIN COHORT_AI_VIEW_ANALYSIS
USING (cohort_date)
LEFT JOIN (COHORT_SIGNUP_WITHIN_ONE_DAY_ANALYSIS)
USING (cohort_date)
order by cohort_date desc