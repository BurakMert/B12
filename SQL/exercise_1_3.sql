WITH PREV_DAY_APPENDED as (
    select cohort_date,
           total_signup_within_1_day,
           LAG(total_signup_within_1_day,1,0) over (order by cohort_date) as prev_total_signup_within_1_day,
           total_signup_start,
           LAG(total_signup_start,1,0) over (order by cohort_date)        as prev_total_signup_start,
           total_signup_end,
           LAG(total_signup_end,1,0) over (order by cohort_date)          as prev_total_signup_end,
           total_ai_view,
           LAG(total_ai_view,1,0) over (order by cohort_date)             as prev_total_ai_view
    from funnel_cohort_status
),
PREV_DAY_COMPARISON as (
select cohort_date,
       CASE WHEN prev_total_signup_within_1_day != 0 then CAST((total_signup_within_1_day) as FLOAT)/prev_total_signup_within_1_day else 1.0 end as signup_within_1_day_change,
       CASE WHEN prev_total_signup_start != 0 then CAST((total_signup_start) as FLOAT)/prev_total_signup_start else 1.0 end as signup_start_change,
       CASE WHEN prev_total_signup_end != 0 then CAST((total_signup_end) as FLOAT)/prev_total_signup_end else 1.0 end as signup_end_change,
       CASE WHEN prev_total_ai_view != 0 then CAST((total_ai_view) as FLOAT)/prev_total_ai_view else 1.0 end as ai_view_change
FROM PREV_DAY_APPENDED
),
FUNNEL_ALARMS as (
select *,
       CASE WHEN signup_within_1_day_change <= 0.9 then 1 else 0 end as signup_within_1_day_alarm,
       CASE WHEN signup_start_change <= 0.9 then 1 else 0 end as signup_start_alarm,
       CASE WHEN signup_end_change <= 0.9 then 1 else 0 end as signup_end_alarm,
       CASE WHEN ai_view_change <= 0.9 then 1 else 0 end as ai_view_alarm
from PREV_DAY_COMPARISON
    where ai_view_alarm is TRUE
   or signup_within_1_day_alarm is TRUE
   or signup_start_alarm is TRUE
   or signup_end_alarm is TRUE
),
SIGNUP_START_ALARM as (
select cohort_date, signup_start_change as alarm_magnitude, 'signup_flow_start' as alarm_source
from FUNNEL_ALARMS
where signup_start_alarm = 1
),
SIGNUP_END_ALARM as (
select cohort_date, signup_end_change as alarm_magnitude, 'signup_flow_end' as alarm_source
from FUNNEL_ALARMS
where signup_end_alarm = 1
),
SIGNUP_WITHIN_1_DAY_ALARM as
(
select cohort_date, signup_within_1_day_change as alarm_magnitude, 'signup_within_1_day' as alarm_source
from FUNNEL_ALARMS
where signup_within_1_day_alarm = 1
),
AI_VIEW_ALARM as
(
select cohort_date, ai_view_change as alarm_magnitude, 'ai_draft_view' as alarm_source
from FUNNEL_ALARMS
where ai_view_alarm = 1
),
NO_ALARM as
(
select cohort_date, NULL as alarm_magnitude, NULL as alarm_source
from FUNNEL_ALARMS
where ai_view_alarm = 0
  and signup_within_1_day_alarm = 0
  and signup_end_alarm = 0
  and signup_start_alarm=0
)
SELECT * from SIGNUP_START_ALARM
UNION ALL
SELECT * FROM SIGNUP_END_ALARM
UNION ALL
SELECT * FROM SIGNUP_WITHIN_1_DAY_ALARM
UNION ALL
SELECT * FROM AI_VIEW_ALARM
UNION ALL
SELECT * FROM NO_ALARM
order by cohort_date desc
