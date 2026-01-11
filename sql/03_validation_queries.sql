-- Data Validation Queries

-- Validation 1: Check for missing required fields
SELECT 'Missing ID or Date' as validation_check,
       COUNT(*) as issue_count
FROM daily_wellness
WHERE id IS NULL OR activity_date IS NULL;

-- Validation 2: Check for negative values
SELECT 'Negative Values in Steps' as validation_check,
       COUNT(*) as issue_count
FROM daily_wellness
WHERE total_steps < 0;

-- Validation 3: Check for invalid minute ranges (should be 0-1440)
SELECT 'Invalid Sedentary Minutes' as validation_check,
       COUNT(*) as issue_count
FROM daily_wellness
WHERE sedentary_minutes < 0 OR sedentary_minutes > 1440;

-- Validation 4: Check sleep efficiency out of range
SELECT 'Sleep Efficiency Out of Range' as validation_check,
       COUNT(*) as issue_count
FROM daily_wellness
WHERE sleep_efficiency IS NOT NULL 
  AND (sleep_efficiency < 0 OR sleep_efficiency > 1);

-- Validation 5: Count records per user
SELECT 
    id,
    COUNT(*) as record_count,
    MIN(activity_date) as first_date,
    MAX(activity_date) as last_date,
    ROUND(JULIANDAY(MAX(activity_date)) - JULIANDAY(MIN(activity_date)) + 1, 0) as day_span
FROM daily_wellness
GROUP BY id
HAVING record_count < 5
ORDER BY record_count ASC;

-- Validation 6: Check data completeness
SELECT 
    'Total Records' as metric,
    COUNT(*) as value
FROM daily_wellness
UNION ALL
SELECT 
    'Unique Users',
    COUNT(DISTINCT id)
FROM daily_wellness
UNION ALL
SELECT 
    'Records with Sleep Data',
    COUNT(*)
FROM daily_wellness
WHERE total_minutes_asleep IS NOT NULL
UNION ALL
SELECT 
    'Users with Sleep Data',
    COUNT(DISTINCT id)
FROM daily_wellness
WHERE total_minutes_asleep IS NOT NULL;

-- Validation 7: Identify potential outliers (3 standard deviations)
SELECT 
    id,
    activity_date,
    total_steps,
    (SELECT AVG(total_steps) FROM daily_wellness) as mean_steps,
    (SELECT AVG((total_steps - avg_steps) * (total_steps - avg_steps)) 
     FROM (SELECT AVG(total_steps) as avg_steps FROM daily_wellness), daily_wellness) as variance
FROM daily_wellness
WHERE total_steps > (SELECT AVG(total_steps) + 3 * 
                     SQRT(AVG((total_steps - (SELECT AVG(total_steps) FROM daily_wellness)) * 
                             (total_steps - (SELECT AVG(total_steps) FROM daily_wellness))))
                     FROM daily_wellness)
   OR total_steps < (SELECT AVG(total_steps) - 3 * 
                     SQRT(AVG((total_steps - (SELECT AVG(total_steps) FROM daily_wellness)) * 
                             (total_steps - (SELECT AVG(total_steps) FROM daily_wellness))))
                     FROM daily_wellness);

-- Validation 8: Check referential integrity
SELECT 
    'Users in daily_wellness but not in user_summary' as validation_check,
    COUNT(DISTINCT dw.id) as issue_count
FROM daily_wellness dw
LEFT JOIN user_summary us ON dw.id = us.id
WHERE us.id IS NULL;
