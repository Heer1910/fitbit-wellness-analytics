# Wellness Dataset Transformation Utilities
# Functions for data cleaning and feature engineering

library(dplyr)
library(lubridate)
library(tidyr)

#' Merge daily activity and sleep datasets
#'
#' @param activity_data Daily activity data frame
#' @param sleep_data Sleep data frame
#' @return Merged data frame with left join (keeps all activity records)
merge_datasets <- function(activity_data, sleep_data) {
  # Standardize date formats
  activity_clean <- activity_data %>%
    mutate(Date = as.Date(ActivityDate, format = "%m/%d/%Y"))
  
  sleep_clean <- sleep_data %>%
    mutate(Date = as.Date(SleepDay, format = "%m/%d/%Y"))
  
  # Aggregate sleep data by date (in case of multiple sleep records per day)
  sleep_aggregated <- sleep_clean %>%
    group_by(Id, Date) %>%
    summarise(
      TotalSleepRecords = sum(TotalSleepRecords, na.rm = TRUE),
      TotalMinutesAsleep = sum(TotalMinutesAsleep, na.rm = TRUE),
      TotalTimeInBed = sum(TotalTimeInBed, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Left join to keep all activity records
  merged <- activity_clean %>%
    left_join(sleep_aggregated, by = c("Id", "Date"))
  
  return(merged)
}

#' Calculate sleep efficiency metric
#'
#' @param data Data frame with TotalMinutesAsleep and TotalTimeInBed
#' @return Data frame with sleep_efficiency column added
calculate_sleep_efficiency <- function(data) {
  data %>%
    mutate(
      sleep_efficiency = ifelse(
        !is.na(TotalTimeInBed) & TotalTimeInBed > 0,
        TotalMinutesAsleep / TotalTimeInBed,
        NA_real_
      ),
      # Cap at 1.0 (in case of data entry errors)
      sleep_efficiency = ifelse(sleep_efficiency > 1.0, 1.0, sleep_efficiency)
    )
}

#' Categorize activity level based on daily steps
#' Based on CDC and research guidelines:
#' - Sedentary: < 5,000 steps
#' - Low Active: 5,000 - 7,499 steps
#' - Somewhat Active: 7,500 - 9,999 steps
#' - Active: 10,000 - 12,499 steps
#' - Highly Active: >= 12,500 steps
#'
#' @param data Data frame with TotalSteps column
#' @return Data frame with activity_level column added
categorize_activity_level <- function(data) {
  data %>%
    mutate(
      activity_level = case_when(
        TotalSteps < 5000 ~ "Sedentary",
        TotalSteps < 7500 ~ "Low Active",
        TotalSteps < 10000 ~ "Somewhat Active",
        TotalSteps < 12500 ~ "Active",
        TRUE ~ "Highly Active"
      ),
      activity_level = factor(
        activity_level,
        levels = c("Sedentary", "Low Active", "Somewhat Active", "Active", "Highly Active"),
        ordered = TRUE
      )
    )
}

#' Add weekday and weekend indicators
#'
#' @param data Data frame with Date column
#' @return Data frame with weekday, day_name, and is_weekend columns
add_weekday_indicator <- function(data) {
  data %>%
    mutate(
      # Use base R weekdays() function for compatibility
      day_name = weekdays(Date),
      # wday() returns 1=Sunday, 2=Monday, etc. Convert to 1=Monday, 7=Sunday
      weekday_raw = wday(Date),
      weekday = ifelse(weekday_raw == 1, 7, weekday_raw - 1),  # Convert: Sun=7, Mon=1
      # Weekend is Saturday (7) and Sunday (1) in wday() numbering
      is_weekend = weekday_raw %in% c(1, 7)
    ) %>%
    select(-weekday_raw)  # Remove temporary column
}

#' Calculate total active minutes
#'
#' @param data Data frame with activity minute columns
#' @return Data frame with total_active_minutes column
calculate_total_active_minutes <- function(data) {
  data %>%
    mutate(
      total_active_minutes = VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes,
      # Calculate percentage of non-sedentary time
      non_sedentary_minutes = 1440 - SedentaryMinutes,
      active_percentage = ifelse(
        non_sedentary_minutes > 0,
        total_active_minutes / non_sedentary_minutes,
        0
      )
    )
}

#' Create binned categories for steps for visualization
#'
#' @param data Data frame with TotalSteps column
#' @param bin_width Width of each bin (default 2500)
#' @return Data frame with steps_category column
create_steps_bins <- function(data, bin_width = 2500) {
  data %>%
    mutate(
      steps_bin = cut(
        TotalSteps,
        breaks = seq(0, max(TotalSteps, na.rm = TRUE) + bin_width, by = bin_width),
        include.lowest = TRUE,
        right = FALSE
      )
    )
}

#' Calculate user-level engagement metrics
#'
#' @param data Data frame with Id and Date columns
#' @return Data frame with user-level statistics
calculate_user_engagement <- function(data) {
  user_stats <- data %>%
    group_by(Id) %>%
    summarise(
      total_days = n(),
      avg_daily_steps = mean(TotalSteps, na.rm = TRUE),
      median_daily_steps = median(TotalSteps, na.rm = TRUE),
      sd_daily_steps = sd(TotalSteps, na.rm = TRUE),
      cv_steps = sd_daily_steps / avg_daily_steps,  # Coefficient of variation
      min_steps = min(TotalSteps, na.rm = TRUE),
      max_steps = max(TotalSteps, na.rm = TRUE),
      avg_calories = mean(Calories, na.rm = TRUE),
      days_with_sleep_data = sum(!is.na(TotalMinutesAsleep)),
      avg_sleep_minutes = mean(TotalMinutesAsleep, na.rm = TRUE),
      avg_sleep_efficiency = mean(sleep_efficiency, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      # Categorize consistency (low CV = more consistent)
      consistency_category = case_when(
        cv_steps < 0.3 ~ "High Consistency",
        cv_steps < 0.5 ~ "Moderate Consistency",
        TRUE ~ "Low Consistency"
      ),
      # Categorize overall engagement based on average steps
      engagement_level = case_when(
        avg_daily_steps < 5000 ~ "Low Engagement",
        avg_daily_steps < 10000 ~ "Moderate Engagement",
        TRUE ~ "High Engagement"
      )
    )
  
  return(user_stats)
}

#' Impute missing values with documented strategy
#' NOTE: For this wellness data, we DO NOT impute missing days as they represent
#' non-wear time, which is legitimate behavioral data
#'
#' @param data Data frame
#' @param log_file Path to log file for documenting imputation
#' @return Data frame (unchanged for this strategy)
impute_missing <- function(data, log_file = NULL) {
  # Document the strategy
  message <- paste0(
    "[", Sys.time(), "] IMPUTATION STRATEGY: ",
    "No imputation performed. Missing days represent legitimate non-wear periods. ",
    "Missing values in sleep data are left as NA (not all users track sleep).\n"
  )
  
  if (!is.null(log_file)) {
    cat(message, file = log_file, append = TRUE)
  } else {
    cat(message)
  }
  
  # Return data unchanged
  return(data)
}

#' Remove duplicate records based on key columns
#'
#' @param data Data frame
#' @param key_columns Columns that define uniqueness
#' @param log_file Path to log file
#' @return De-duplicated data frame
remove_duplicates <- function(data, key_columns, log_file = NULL) {
  original_rows <- nrow(data)
  
  data_clean <- data %>%
    distinct(across(all_of(key_columns)), .keep_all = TRUE)
  
  removed_rows <- original_rows - nrow(data_clean)
  
  message <- paste0(
    "[", Sys.time(), "] DUPLICATE REMOVAL: ",
    "Removed ", removed_rows, " duplicate records based on: ",
    paste(key_columns, collapse = ", "), "\n"
  )
  
  if (!is.null(log_file)) {
    cat(message, file = log_file, append = TRUE)
  } else {
    cat(message)
  }
  
  return(data_clean)
}

#' Apply all transformations in sequence
#'
#' @param activity_data Daily activity data
#' @param sleep_data Sleep data
#' @param log_file Path to transformation log
#' @return Fully transformed data frame
apply_all_transformations <- function(activity_data, sleep_data, log_file = "logs/transformation_log.txt") {
  cat(paste0(
    "================================================================================\n",
    "TRANSFORMATION PIPELINE STARTED: ", Sys.time(), "\n",
    "================================================================================\n\n"
  ), file = log_file, append = FALSE)
  
  # Step 1: Merge datasets
  cat("[", as.character(Sys.time()), "] Step 1: Merging activity and sleep data\n",
      file = log_file, append = TRUE)
  data <- merge_datasets(activity_data, sleep_data)
  
  # Step 2: Add weekday indicators
  cat("[", as.character(Sys.time()), "] Step 2: Adding weekday indicators\n",
      file = log_file, append = TRUE)
  data <- add_weekday_indicator(data)
  
  # Step 3: Calculate sleep efficiency
  cat("[", as.character(Sys.time()), "] Step 3: Calculating sleep efficiency\n",
      file = log_file, append = TRUE)
  data <- calculate_sleep_efficiency(data)
  
  # Step 4: Categorize activity levels
  cat("[", as.character(Sys.time()), "] Step 4: Categorizing activity levels\n",
      file = log_file, append = TRUE)
  data <- categorize_activity_level(data)
  
  # Step 5: Calculate total active minutes
  cat("[", as.character(Sys.time()), "] Step 5: Calculating activity metrics\n",
      file = log_file, append = TRUE)
  data <- calculate_total_active_minutes(data)
  
  # Step 6: Create step bins
  cat("[", as.character(Sys.time()), "] Step 6: Creating visualization bins\n",
      file = log_file, append = TRUE)
  data <- create_steps_bins(data)
  
  # Step 7: Remove duplicates
  cat("[", as.character(Sys.time()), "] Step 7: Removing duplicates\n",
      file = log_file, append = TRUE)
  data <- remove_duplicates(data, c("Id", "Date"), log_file)
  
  cat(paste0(
    "\n================================================================================\n",
    "TRANSFORMATION PIPELINE COMPLETED: ", Sys.time(), "\n",
    "Final dataset: ", nrow(data), " rows, ", ncol(data), " columns\n",
    "================================================================================\n"
  ), file = log_file, append = TRUE)
  
  return(data)
}
