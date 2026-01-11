# Daily Activity Visualizations
# Professional plots for activity metrics analysis

library(ggplot2)
library(dplyr)
library(scales)
library(lubridate)

# Source theme
source("visualizations/theme_wellness.R")

cat("\n")
cat("########################################################\n")
cat("#  GENERATING ACTIVITY VISUALIZATIONS                 #\n")
cat("########################################################\n\n")

# Load processed data
files <- list.files("data/processed", pattern = "wellness_data_clean_.*\\.csv", full.names = TRUE)
if (length(files) == 0) {
  stop("No processed data found. Run 01_exploratory_analysis.R first.")
}
latest_file <- files[order(file.mtime(files), decreasing = TRUE)][1]
data <- read.csv(latest_file)
data$Date <- as.Date(data$Date)
data$activity_level <- factor(
  data$activity_level,
  levels = c("Sedentary", "Low Active", "Somewhat Active", "Active", "Highly Active"),
  ordered = TRUE
)

# VISUALIZATION 1: Steps Distribution Histogram
cat("Creating Plot 1: Steps Distribution Histogram...\n")

p1 <- ggplot(data, aes(x = TotalSteps)) +
  geom_histogram(
    bins = 30,
    fill = wellness_colors()[1],
    color = "white",
    alpha = 0.9
  ) +
  geom_vline(
    xintercept = mean(data$TotalSteps, na.rm = TRUE),
    linetype = "dashed",
    color = "#C73E1D",
    size = 1
  ) +
  annotate(
    "text",
    x = mean(data$TotalSteps, na.rm = TRUE) + 1500,
    y = Inf,
    label = paste0("Mean: ", format_number(mean(data$TotalSteps, na.rm = TRUE))),
    vjust = 2,
    color = "#C73E1D",
    fontface = "bold"
  ) +
  labs(
    title = "Distribution of Daily Steps",
    subtitle = paste0("n = ", nrow(data), " observations across ", length(unique(data$Id)), " users"),
    x = "Total Steps per Day",
    y = "Frequency (Number of Days)",
    caption = "Red line indicates mean daily steps | Source: FitBit Wellness Data"
  ) +
  scale_x_continuous(labels = comma) +
  theme_wellness()

save_wellness_plot(p1, "outputs/plots/01_steps_distribution.png")

# VISUALIZATION 2: Time Series of Daily Steps (Aggregated)
cat("Creating Plot 2: Daily Steps Time Series...\n")

daily_aggregate <- data %>%
  group_by(Date) %>%
  summarise(
    avg_steps = mean(TotalSteps, na.rm = TRUE),
    active_users = n()
  )

p2 <- ggplot(daily_aggregate, aes(x = Date, y = avg_steps)) +
  geom_line(color = wellness_colors()[1], size = 1) +
  geom_point(color = wellness_colors()[1], size = 2, alpha = 0.6) +
  geom_smooth(method = "loess", color = wellness_colors()[5], fill = wellness_colors()[5], alpha = 0.2) +
  labs(
    title = "Daily Average Steps Over Time",
    subtitle = "Aggregated across all active users per day",
    x = "Date",
    y = "Average Steps per Day",
    caption = "Blue line shows LOESS smoothed trend | Source: FitBit Wellness Data"
  ) +
  scale_y_continuous(labels = comma) +
  theme_wellness()

save_wellness_plot(p2, "outputs/plots/02_steps_time_series.png")

# VISUALIZATION 3: Activity Level Distribution (Stacked Bar)
cat("Creating Plot 3: Activity Level Distribution...\n")

activity_counts <- data %>%
  count(activity_level) %>%
  mutate(percentage = n / sum(n) * 100)

p3 <- ggplot(activity_counts, aes(x = "", y = percentage, fill = activity_level)) +
  geom_col(width = 1, color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(percentage, 1), "%\n(n=", n, ")")),
    position = position_stack(vjust = 0.5),
    color = "white",
    fontface = "bold",
    size = 4
  ) +
  scale_fill_manual(
    values = activity_level_colors(),
    name = "Activity Level"
  ) +
  labs(
    title = "Activity Level Distribution",
    subtitle = "Percentage of days by activity category (based on daily steps)",
    caption = "Sedentary: <5K steps | Low Active: 5-7.5K | Somewhat Active: 7.5-10K | Active: 10-12.5K | Highly Active: ≥12.5K"
  ) +
  coord_flip() +
  theme_wellness() +
  theme(
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.line = element_blank(),
    panel.grid = element_blank()
  )

save_wellness_plot(p3, "outputs/plots/03_activity_level_distribution.png", width = 10, height = 4)

# VISUALIZATION 4: Intensity Levels by Hour (if hourly data available)
cat("Creating Plot 4: Activity Intensity Breakdown...\n")

intensity_data <- data %>%
  select(Id, Date, VeryActiveMinutes, FairlyActiveMinutes, LightlyActiveMinutes, SedentaryMinutes) %>%
  tidyr::pivot_longer(
    cols = c(VeryActiveMinutes, FairlyActiveMinutes, LightlyActiveMinutes, SedentaryMinutes),
    names_to = "intensity",
    values_to = "minutes"
  ) %>%
  mutate(
    intensity = gsub("Minutes", "", intensity),
    intensity = factor(
      intensity,
      levels = c("Sedentary", "Lightly Active", "Fairly Active", "Very Active"),
      labels = c("Sedentary", "Light", "Moderate", "Vigorous")
    )
  )

avg_intensity <- intensity_data %>%
  group_by(intensity) %>%
  summarise(avg_minutes = mean(minutes, na.rm = TRUE))

p4 <- ggplot(avg_intensity, aes(x = intensity, y = avg_minutes, fill = intensity)) +
  geom_col(color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(avg_minutes, 0), " min")),
    vjust = -0.5,
    fontface = "bold",
    size = 4
  ) +
  scale_fill_manual(
    values = c(
      "Sedentary" = wellness_colors()[6],
      "Light" = "#F4A259",
      "Moderate" = wellness_colors()[3],
      "Vigorous" = wellness_colors()[4]
    )
  ) +
  labs(
    title = "Average Daily Minutes by Activity Intensity",
    subtitle = "Breakdown of how users spend their day",
    x = "Intensity Level",
    y = "Average Minutes per Day",
    caption = "Based on FitBit activity intensity classifications | Source: FitBit Wellness Data"
  ) +
  theme_wellness() +
  theme(legend.position = "none")

save_wellness_plot(p4, "outputs/plots/04_intensity_breakdown.png")

# VISUALIZATION 5: Activity Heatmap (User x Date)
cat("Creating Plot 5: User Activity Heatmap...\n")

# Take a subset of users for readability
top_users <- data %>%
  group_by(Id) %>%
  summarise(total_records = n()) %>%
  arrange(desc(total_records)) %>%
  head(15) %>%
  pull(Id)

heatmap_data <- data %>%
  filter(Id %in% top_users) %>%
  mutate(Id = as.factor(Id))

p5 <- ggplot(heatmap_data, aes(x = Date, y = Id, fill = TotalSteps)) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_gradient2(
    low = "#FFFFFF",
    mid = wellness_colors()[3],
    high = wellness_colors()[1],
    midpoint = median(data$TotalSteps, na.rm = TRUE),
    name = "Steps",
    labels = comma
  ) +
  labs(
    title = "Daily Steps Heatmap by User",
    subtitle = "Top 15 users by data completeness",
    x = "Date",
    y = "User ID",
    caption = "Darker colors indicate higher step counts | Source: FitBit Wellness Data"
  ) +
  theme_wellness() +
  theme(
    axis.text.y = element_text(size = 8),
    panel.grid = element_blank()
  )

save_wellness_plot(p5, "outputs/plots/05_user_activity_heatmap.png", width = 12, height = 8)

cat("\n✓ Activity visualizations complete\n")
cat("  5 plots saved to outputs/plots/\n\n")
