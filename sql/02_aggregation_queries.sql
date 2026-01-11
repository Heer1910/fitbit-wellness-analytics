-- Aggregation Queries for Wellness Analytics

-- Query 1: Average daily steps by user
SELECT 
    id,
    COUNT(*) as days_tracked,
    ROUND(AVG(total_steps), 0) as avg_steps,
    ROUND(AVG(calories), 0) as avg_calories,
    ROUND(AVG(total_active_minutes), 1) as avg_active_minutes
FROM daily_wellness
GROUP BY id
ORDER BY avg_steps DESC;

-- Query 2: Overall activity distribution
SELECT 
    activity_level,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM daily_wellness), 1) as percentage
FROM daily_wellness
GROUP BY activity_level
ORDER BY 
    CASE activity_level
        WHEN 'Sedentary' THEN 1
        WHEN 'Low Active' THEN 2
        WHEN 'Somewhat Active' THEN 3
        WHEN 'Active' THEN 4
        WHEN 'Highly Active' THEN 5
    END;

-- Query 3: Weekday vs Weekend comparison
SELECT 
    CASE WHEN is_weekend THEN 'Weekend' ELSE 'Weekday' END as day_type,
    COUNT(*) as observations,
    ROUND(AVG(total_steps), 0) as avg_steps,
    ROUND(AVG(total_active_minutes), 1) as avg_active_minutes,
    ROUND(AVG(calories), 0) as avg_calories,
    ROUND(AVG(total_minutes_asleep), 1) as avg_sleep_minutes
FROM daily_wellness
GROUP BY is_weekend;

-- Query 4: Activity patterns by day of week
SELECT 
    day_name,
    weekday,
    COUNT(*) as observations,
    ROUND(AVG(total_steps), 0) as avg_steps,
    ROUND(AVG(total_active_minutes), 1) as avg_active_minutes,
    ROUND(AVG(total_minutes_asleep), 1) as avg_sleep_minutes
FROM daily_wellness
GROUP BY day_name, weekday
ORDER BY weekday;

-- Query 5: Sleep analysis (users with sleep data only)
SELECT 
    COUNT(*) as sleep_records,
    COUNT(DISTINCT id) as users_with_sleep_data,
    ROUND(AVG(total_minutes_asleep), 1) as avg_minutes_asleep,
    ROUND(AVG(total_time_in_bed), 1) as avg_time_in_bed,
    ROUND(AVG(sleep_efficiency), 3) as avg_sleep_efficiency,
    ROUND(MIN(sleep_efficiency), 3) as min_sleep_efficiency,
    ROUND(MAX(sleep_efficiency), 3) as max_sleep_efficiency
FROM daily_wellness
WHERE total_minutes_asleep IS NOT NULL;

-- Query 6: Correlation between activity and sleep
SELECT 
    activity_level,
    COUNT(*) as observations,
    ROUND(AVG(total_minutes_asleep), 1) as avg_sleep_minutes,
    ROUND(AVG(sleep_efficiency), 3) as avg_sleep_efficiency
FROM daily_wellness
WHERE total_minutes_asleep IS NOT NULL
GROUP BY activity_level
ORDER BY 
    CASE activity_level
        WHEN 'Sedentary' THEN 1
        WHEN 'Low Active' THEN 2
        WHEN 'Somewhat Active' THEN 3
        WHEN 'Active' THEN 4
        WHEN 'Highly Active' THEN 5
    END;

-- Query 7: User engagement consistency
SELECT 
    consistency_category,
    engagement_level,
    COUNT(*) as user_count,
    ROUND(AVG(avg_daily_steps), 0) as avg_steps,
    ROUND(AVG(total_days), 0) as avg_tracking_days
FROM user_summary
GROUP BY consistency_category, engagement_level
ORDER BY engagement_level, consistency_category;

-- Query 8: Top performers (most active users)
SELECT 
    id,
    avg_daily_steps,
    max_steps,
    total_days,
    engagement_level,
    consistency_category
FROM user_summary
ORDER BY avg_daily_steps DESC
LIMIT 10;

-- Query 9: Time series trend (daily aggregates)
SELECT 
    activity_date,
    COUNT(DISTINCT id) as active_users,
    ROUND(AVG(total_steps), 0) as avg_steps,
    ROUND(AVG(total_active_minutes), 1) as avg_active_minutes
FROM daily_wellness
GROUP BY activity_date
ORDER BY activity_date;

-- Query 10: Sleep quality by day of week
SELECT 
    day_name,
    COUNT(*) as observations,
    ROUND(AVG(total_minutes_asleep), 1) as avg_sleep_minutes,
    ROUND(AVG(sleep_efficiency), 3) as avg_sleep_efficiency
FROM daily_wellness
WHERE total_minutes_asleep IS NOT NULL
GROUP BY day_name, weekday
ORDER BY weekday;
