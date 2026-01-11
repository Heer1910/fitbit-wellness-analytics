-- Smart Wellness Insights Platform - Database Schema
-- SQLite database schema for processed wellness data

-- Daily Activity and Sleep Combined Table
CREATE TABLE IF NOT EXISTS daily_wellness (
    id INTEGER,
    activity_date DATE,
    total_steps INTEGER,
    total_distance REAL,
    very_active_minutes INTEGER,
    fairly_active_minutes INTEGER,
    lightly_active_minutes INTEGER,
    sedentary_minutes INTEGER,
    calories INTEGER,
    total_minutes_asleep INTEGER,
    total_time_in_bed INTEGER,
    sleep_efficiency REAL,
    weekday INTEGER,
    day_name TEXT,
    is_weekend BOOLEAN,
    activity_level TEXT,
    total_active_minutes INTEGER,
    active_percentage REAL,
    PRIMARY KEY (id, activity_date)
);

-- User Summary Statistics Table
CREATE TABLE IF NOT EXISTS user_summary (
    id INTEGER PRIMARY KEY,
    total_days INTEGER,
    avg_daily_steps REAL,
    median_daily_steps REAL,
    sd_daily_steps REAL,
    cv_steps REAL,
    min_steps INTEGER,
    max_steps INTEGER,
    avg_calories REAL,
    days_with_sleep_data INTEGER,
    avg_sleep_minutes REAL,
    avg_sleep_efficiency REAL,
    consistency_category TEXT,
    engagement_level TEXT
);

-- Index for common queries
CREATE INDEX IF NOT EXISTS idx_daily_wellness_date ON daily_wellness(activity_date);
CREATE INDEX IF NOT EXISTS idx_daily_wellness_id ON daily_wellness(id);
CREATE INDEX IF NOT EXISTS idx_daily_wellness_weekday ON daily_wellness(weekday);
CREATE INDEX IF NOT EXISTS idx_daily_wellness_activity_level ON daily_wellness(activity_level);
