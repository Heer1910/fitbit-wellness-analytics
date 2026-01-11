# Exploratory Data Analysis
# Initial assessment of data quality and distributions

library(dplyr)
library(ggplot2)
library(lubridate)

# Source required modules
source("src/WellnessDataset.R")

cat("\n")
cat("########################################################\n")
cat("#  EXPLORATORY DATA ANALYSIS                          #\n")
cat("########################################################\n\n")

# Initialize and run pipeline
wellness <- WellnessDataset$new()
wellness$run_pipeline(export_data = TRUE)

# Get cleaned data
data <- wellness$get_clean_data()
user_stats <- wellness$get_user_summary()

cat("\n==================================================\n")
cat("EXPLORATORY ANALYSIS\n")
cat("==================================================\n\n")

# Basic dataset characteristics
cat("DATASET CHARACTERISTICS:\n")
cat("--------------------------------------------------\n")
cat("Total observations:", nrow(data), "\n")
cat("Unique users:", length(unique(data$Id)), "\n")
cat("Date range:", min(data$Date), "to", max(data$Date), "\n")
cat("Duration:", as.numeric(max(data$Date) - min(data$Date)) + 1, "days\n\n")

# Summary statistics for key variables
cat("ACTIVITY METRICS SUMMARY:\n")
cat("--------------------------------------------------\n")

activity_summary <- data %>%
  summarise(
    avg_steps = mean(TotalSteps, na.rm = TRUE),
    median_steps = median(TotalSteps, na.rm = TRUE),
    sd_steps = sd(TotalSteps, na.rm = TRUE),
    min_steps = min(TotalSteps, na.rm = TRUE),
    max_steps = max(TotalSteps, na.rm = TRUE),
    avg_calories = mean(Calories, na.rm = TRUE),
    avg_active_min = mean(total_active_minutes, na.rm = TRUE)
  )

print(activity_summary)

cat("\nSTEPS DISTRIBUTION BY ACTIVITY LEVEL:\n")
cat("--------------------------------------------------\n")
activity_dist <- data %>%
  group_by(activity_level) %>%
  summarise(
    count = n(),
    percentage = round(n() / nrow(data) * 100, 1)
  )
print(activity_dist)

cat("\nSLEEP METRICS SUMMARY:\n")
cat("--------------------------------------------------\n")

sleep_summary <- data %>%
  filter(!is.na(TotalMinutesAsleep)) %>%
  summarise(
    observations = n(),
    users_with_sleep = length(unique(Id)),
    avg_sleep_hours = mean(TotalMinutesAsleep, na.rm = TRUE) / 60,
    median_sleep_hours = median(TotalMinutesAsleep, na.rm = TRUE) / 60,
    avg_efficiency = mean(sleep_efficiency, na.rm = TRUE),
    good_sleep_pct = sum(sleep_efficiency >= 0.85, na.rm = TRUE) / n() * 100
  )

print(sleep_summary)

cat("\nMISSING DATA ANALYSIS:\n")
cat("--------------------------------------------------\n")

missing_analysis <- data %>%
  summarise(
    total_obs = n(),
    missing_sleep = sum(is.na(TotalMinutesAsleep)),
    sleep_coverage = round((1 - sum(is.na(TotalMinutesAsleep)) / n()) * 100, 1)
  )

print(missing_analysis)

cat("\nUSER ENGAGEMENT DISTRIBUTION:\n")
cat("--------------------------------------------------\n")
print(table(user_stats$engagement_level))

cat("\nUSER CONSISTENCY DISTRIBUTION:\n")
cat("--------------------------------------------------\n")
print(table(user_stats$consistency_category))

cat("\n✓ Exploratory analysis complete\n")
cat("  Cleaned data available in wellness$get_clean_data()\n")
cat("  User statistics available in wellness$get_user_summary()\n\n")
