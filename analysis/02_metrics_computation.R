# Metrics Computation
# Calculate all required analytics metrics from PRD

library(dplyr)
library(tidyr)
library(lubridate)

cat("\n")
cat("########################################################\n")
cat("#  METRICS COMPUTATION                                #\n")
cat("########################################################\n\n")

# Load processed data (assumes exploratory analysis has run)
if (!exists("data")) {
  # Load from saved file
  files <- list.files("data/processed", pattern = "wellness_data_clean_.*\\.csv", full.names = TRUE)
  if (length(files) == 0) {
    stop("No processed data found. Run 01_exploratory_analysis.R first.")
  }
  latest_file <- files[order(file.mtime(files), decreasing = TRUE)][1]
  data <- read.csv(latest_file)
  data$Date <- as.Date(data$Date)
}

# Create outputs directory
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

cat("==================================================\n")
cat("METRIC 1: Average Daily Steps\n")
cat("==================================================\n")

# Overall average
overall_avg_steps <- mean(data$TotalSteps, na.rm = TRUE)
cat("Overall average steps per day:", round(overall_avg_steps, 0), "\n")

# By user
user_avg_steps <- data %>%
  group_by(Id) %>%
  summarise(
    avg_steps = mean(TotalSteps, na.rm = TRUE),
    days_tracked = n()
  ) %>%
  arrange(desc(avg_steps))

cat("Top 5 users by average steps:\n")
print(head(user_avg_steps, 5))

# Save metric
write.csv(user_avg_steps, "outputs/tables/metric_user_avg_steps.csv", row.names = FALSE)

cat("\n==================================================\n")
cat("METRIC 2: Sleep Duration Distribution\n")
cat("==================================================\n")

sleep_distribution <- data %>%
  filter(!is.na(TotalMinutesAsleep)) %>%
  summarise(
    observations = n(),
    mean_hours = mean(TotalMinutesAsleep / 60, na.rm = TRUE),
    median_hours = median(TotalMinutesAsleep / 60, na.rm = TRUE),
    q1_hours = quantile(TotalMinutesAsleep / 60, 0.25, na.rm = TRUE),
    q3_hours = quantile(TotalMinutesAsleep / 60, 0.75, na.rm = TRUE),
    min_hours = min(TotalMinutesAsleep / 60, na.rm = TRUE),
    max_hours = max(TotalMinutesAsleep / 60, na.rm = TRUE),
    sd_hours = sd(TotalMinutesAsleep / 60, na.rm = TRUE)
  )

print(sleep_distribution)
write.csv(sleep_distribution, "outputs/tables/metric_sleep_distribution.csv", row.names = FALSE)

cat("\n==================================================\n")
cat("METRIC 3: Activity Intensity by Weekday\n")
cat("==================================================\n")

weekday_activity <- data %>%
  group_by(day_name, weekday) %>%
  summarise(
    observations = n(),
    avg_steps = mean(TotalSteps, na.rm = TRUE),
    avg_very_active_min = mean(VeryActiveMinutes, na.rm = TRUE),
    avg_fairly_active_min = mean(FairlyActiveMinutes, na.rm = TRUE),
    avg_light_active_min = mean(LightlyActiveMinutes, na.rm = TRUE),
    avg_total_active_min = mean(total_active_minutes, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(weekday)

print(weekday_activity)
write.csv(weekday_activity, "outputs/tables/metric_weekday_activity.csv", row.names = FALSE)

cat("\n==================================================\n")
cat("METRIC 4: Activity vs Sleep Correlation\n")
cat("==================================================\n")

# Prepare data for correlation
correlation_data <- data %>%
  filter(!is.na(TotalMinutesAsleep)) %>%
  select(
    TotalSteps,
    total_active_minutes,
    VeryActiveMinutes,
    Calories,
    TotalMinutesAsleep,
    sleep_efficiency
  )

# Calculate correlations
cor_matrix <- cor(correlation_data, use = "pairwise.complete.obs")

cat("Correlation: Steps vs Sleep Duration:", round(cor_matrix["TotalSteps", "TotalMinutesAsleep"], 3), "\n")
cat("Correlation: Active Minutes vs Sleep Duration:", round(cor_matrix["total_active_minutes", "TotalMinutesAsleep"], 3), "\n")
cat("Correlation: Steps vs Sleep Efficiency:", round(cor_matrix["TotalSteps", "sleep_efficiency"], 3), "\n")
cat("Correlation: Active Minutes vs Sleep Efficiency:", round(cor_matrix["total_active_minutes", "sleep_efficiency"], 3), "\n")

write.csv(cor_matrix, "outputs/tables/metric_correlation_matrix.csv")

cat("\n==================================================\n")
cat("METRIC 5: Engagement Consistency Over Time\n")
cat("==================================================\n")

# User-level consistency metrics
user_consistency <- data %>%
  group_by(Id) %>%
  summarise(
    total_days = n(),
    avg_steps = mean(TotalSteps, na.rm = TRUE),
    sd_steps = sd(TotalSteps, na.rm = TRUE),
    cv_steps = sd_steps / avg_steps,  # Coefficient of variation
    active_days_pct = sum(TotalSteps >= 5000) / n() * 100,
    very_active_days_pct = sum(TotalSteps >= 10000) / n() * 100
  ) %>%
  arrange(cv_steps)

cat("Most consistent users (lowest coefficient of variation):\n")
print(head(user_consistency, 5))

cat("\nLeast consistent users (highest coefficient of variation):\n")
print(tail(user_consistency, 5))

write.csv(user_consistency, "outputs/tables/metric_user_consistency.csv", row.names = FALSE)

cat("\n==================================================\n")
cat("METRIC 6: Weekday vs Weekend Comparison\n")
cat("==================================================\n")

weekend_comparison <- data %>%
  mutate(period = ifelse(is_weekend, "Weekend", "Weekday")) %>%
  group_by(period) %>%
  summarise(
    observations = n(),
    avg_steps = mean(TotalSteps, na.rm = TRUE),
    avg_active_min = mean(total_active_minutes, na.rm = TRUE),
    avg_calories = mean(Calories, na.rm = TRUE),
    avg_sleep_min = mean(TotalMinutesAsleep, na.rm = TRUE),
    avg_sleep_efficiency = mean(sleep_efficiency, na.rm = TRUE)
  )

print(weekend_comparison)
write.csv(weekend_comparison, "outputs/tables/metric_weekend_comparison.csv", row.names = FALSE)

# Calculate percentage differences
weekday_steps <- weekend_comparison$avg_steps[weekend_comparison$period == "Weekday"]
weekend_steps <- weekend_comparison$avg_steps[weekend_comparison$period == "Weekend"]
pct_diff <- ((weekend_steps - weekday_steps) / weekday_steps) * 100

cat("\nWeekend vs Weekday Steps Change:", round(pct_diff, 1), "%\n")

cat("\n==================================================\n")
cat("METRIC 7: Activity Level Distribution\n")
cat("==================================================\n")

activity_level_dist <- data %>%
  group_by(activity_level) %>%
  summarise(
    count = n(),
    percentage = round(n() / nrow(data) * 100, 1),
    avg_calories = mean(Calories, na.rm = TRUE)
  )

print(activity_level_dist)
write.csv(activity_level_dist, "outputs/tables/metric_activity_distribution.csv", row.names = FALSE)

cat("\n==================================================\n")
cat("SUMMARY: All Metrics Computed Successfully\n")
cat("==================================================\n")
cat("✓ Metrics saved to outputs/tables/\n")
cat("✓ 7 core metrics calculated\n\n")
