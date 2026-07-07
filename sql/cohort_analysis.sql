WITH users_parsed AS (
    SELECT
        user_id,
        promo_signup_flag,
        CASE
            WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 4
            THEN TO_DATE(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), 'DD-MM-YYYY')
            ELSE TO_DATE(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), 'DD-MM-YY')
        END AS signup_ts
    FROM cohort_users_raw AS u
),

events_parsed AS (
    SELECT
        user_id,
        event_type,
        CASE
            WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 4
            THEN TO_DATE(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), 'DD-MM-YYYY')
            ELSE TO_DATE(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), 'DD-MM-YY')
        END AS event_ts
    FROM cohort_events_raw AS e
),

user_activity AS (
    SELECT
       			 u.user_id,
                DATE_TRUNC('month', u.signup_ts)::date AS cohort_month,
       			 u.promo_signup_flag,
        		DATE_TRUNC('month', e.event_ts)::date AS activity_month,
         (
            (EXTRACT(YEAR FROM e.event_ts)::int - EXTRACT(YEAR FROM u.signup_ts)::int) * 12
            +
            (EXTRACT(MONTH FROM e.event_ts)::int - EXTRACT(MONTH FROM u.signup_ts)::int)
        ) AS month_offset
    FROM users_parsed AS u
    JOIN events_parsed AS e  ON u.user_id = e.user_id
    WHERE u.signup_ts IS NOT NULL 
    AND e.event_ts IS NOT NULL
    AND e.event_type IS NOT NULL 
    AND e.event_type<> 'test_event' 
    
)

SELECT 
			promo_signup_flag,
			cohort_month,
			month_offset,
			COUNT(DISTINCT user_id) AS users_total
FROM user_activity
WHERE activity_month BETWEEN '2025-01-01' AND '2025-06-01'
GROUP BY 
					promo_signup_flag,
					cohort_month,
					month_offset
ORDER BY 
					promo_signup_flag,
					cohort_month,
					month_offset
;
					

