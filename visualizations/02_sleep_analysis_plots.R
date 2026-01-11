# Sleep Analysis Visualizations
# Professional plots for sleep patterns and quality

library(ggplot2)
library(dplyr)
library(scales)

# Source theme
source("visualizations/theme_wellness.R")

cat("\n")
cat("########################################################\n")
cat("#  GENERATING SLEEP VISUALIZATIONS                    #\n")
cat("########################################################\n\n")

# Load processed data
files <- list.files("data/processed", pattern = "wellness_data_clean_.*\\.csv", full.names = TRUE)
latest_file <- files[order(file.mtime(files), decreasing = TRUE)][1]
data <- read.csv(latest_file)
data$Date <- as.Date(data$Date)

# Filter to records with sleep data
sleep_data <- data %>%
  filter(!is.na(TotalMinutesAsleep))

cat("Sleep data available for", nrow(sleep_data), "observations\n")
cat("From", length(unique(sleep_data$Id)), "users\n\n")

# VISUALIZATION 1: Sleep Duration Distribution
cat("Creating Plot 1: Sleep Duration Distribution...\n")

p1 <- ggplot(sleep_data, aes(x = TotalMinutesAsleep / 60)) +
  geom_histogram(
    bins = 25,
    fill = wellness_colors()[2],
    color = "white",
    alpha = 0.9
  ) +
  geom_vline(
    xintercept = c(7, 9),
    linetype = "dashed",
    color = wellness_colors()[4],
    size = 0.8
  ) +
  annotate(
    "rect",
    xmin = 7, xmax = 9,
    ymin = 0, ymax = Inf,
    alpha = 0.1,
    fill = wellness_colors()[2]
  ) +
  annotate(
    "text",
    x = 8, y = Inf,
    label = "Recommended: 7-9 hours",
    vjust = 2,
    fontface = "bold",
    color = wellness_colors()[4]
  ) +
  labs(
    title = "Sleep Duration Distribution",
    subtitle = paste0("n = ", nrow(sleep_data), " sleep records"),
    x = "Hours of Sleep",
    y = "Frequency (Number of Nights)",
    caption = "Shaded area shows recommended sleep duration (7-9 hours) | Source: FitBit Wellness Data"
  ) +
  theme_wellness()

save_wellness_plot(p1, "outputs/plots/06_sleep_duration_distribution.png")

# VISUALIZATION 2: Sleep Efficiency Analysis
cat("Creating Plot 2: Sleep Efficiency Distribution...\n")

p2 <- ggplot(sleep_data, aes(x = sleep_efficiency)) +
  geom_histogram(
    bins = 30,
    fill = wellness_colors()[2],
    color = "white",
    alpha = 0.9
  ) +
  geom_vline(
    xintercept = 0.85,
    linetype = "dashed",
    color = "#C73E1D",
    size = 1
  ) +
  annotate(
    "text",
    x = 0.85,
    y = Inf,
    label = "Good Sleep Efficiency: ≥0.85",
    hjust = -0.1,
    vjust = 2,
    fontface = "bold",
    color = "#C73E1D"
  ) +
  labs(
    title = "Sleep Efficiency Distribution",
    subtitle = "Sleep Efficiency = Time Asleep / Time in Bed",
    x = "Sleep Efficiency (0-1 scale)",
    y = "Frequency (Number of Nights)",
    caption = "Higher values indicate better sleep quality | Source: FitBit Wellness Data"
  ) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  theme_wellness()

save_wellness_plot(p2, "outputs/plots/07_sleep_efficiency_distribution.png")

# VISUALIZATION 3: Time in Bed vs Time Asleep Scatter
cat("Creating Plot 3: Time in Bed vs Time Asleep...\n")

p3 <- ggplot(sleep_data, aes(x = TotalTimeInBed / 60, y = TotalMinutesAsleep / 60)) +
  geom_point(
    alpha = 0.5,
    color = wellness_colors()[2],
    size = 2.5
  ) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed",
    color = wellness_colors()[6],
    size = 0.8
  ) +
  geom_smooth(
    method = "lm",
    color = wellness_colors()[4],
    fill = wellness_colors()[4],
    alpha = 0.2,
    se = TRUE
  ) +
  annotate(
    "text",
    x = 6, y = 10,
    label = "Perfect efficiency\n(diagonal line)",
    fontface = "italic",
    color = wellness_colors()[6],
    size = 3.5
  ) +
  labs(
    title = "Sleep Time vs. Time in Bed",
    subtitle = "Relationship between total sleep and time spent in bed",
    x = "Total Time in Bed (hours)",
    y = "Total Time Asleep (hours)",
    caption = "Points below diagonal indicate lower sleep efficiency | Source: FitBit Wellness Data"
  ) +
  coord_fixed(ratio = 1) +
  theme_wellness()

save_wellness_plot(p3, "outputs/plots/08_sleep_time_vs_bed.png")

# VISUALIZATION 4: Sleep Patterns by Day of Week
cat("Creating Plot 4: Sleep Patterns by Weekday...\n")

weekday_sleep <- sleep_data %>%
  mutate(
    day_name = factor(
      day_name,
      levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
    )
  ) %>%
  group_by(day_name, is_weekend) %>%
  summarise(
    avg_sleep_hours = mean(TotalMinutesAsleep / 60, na.rm = TRUE),
    avg_efficiency = mean(sleep_efficiency, na.rm = TRUE),
    observations = n(),
    .groups = "drop"
  )

p4 <- ggplot(weekday_sleep, aes(x = day_name, y = avg_sleep_hours, fill = is_weekend)) +
  geom_col(color = "white", size = 1) +
  geom_hline(
    yintercept = 7.5,
    linetype = "dashed",
    color = wellness_colors()[6],
    size = 0.6
  ) +
  geom_text(
    aes(label = round(avg_sleep_hours, 1)),
    vjust = -0.5,
    fontface = "bold"
  ) +
  scale_fill_manual(
    values = period_colors(),
    labels = c("Weekday", "Weekend"),
    name = ""
  ) +
  labs(
    title = "Average Sleep Duration by Day of Week",
    subtitle = "Comparing weekday vs weekend sleep patterns",
    x = "Day of Week",
    y = "Average Hours of Sleep",
    caption = "Dashed line shows 7.5-hour benchmark | Source: FitBit Wellness Data"
  ) +
  theme_wellness() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "top"
  )

save_wellness_plot(p4, "outputs/plots/09_sleep_by_weekday.png")

# VISUALIZATION 5: Sleep Quality Categories
cat("Creating Plot 5: Sleep Quality Categories...\n")

sleep_quality <- sleep_data %>%
  mutate(
    sleep_category = case_when(
      TotalMinutesAsleep / 60 < 6 ~ "Insufficient (<6h)",
      TotalMinutesAsleep / 60 < 7 ~ "Short (6-7h)",
      TotalMinutesAsleep / 60 < 9 ~ "Optimal (7-9h)",
      TRUE ~ "Long (>9h)"
    ),
    sleep_category = factor(
      sleep_category,
      levels = c("Insufficient (<6h)", "Short (6-7h)", "Optimal (7-9h)", "Long (>9h)")
    )
  ) %>%
  count(sleep_category) %>%
  mutate(percentage = n / sum(n) * 100)

p5 <- ggplot(sleep_quality, aes(x = sleep_category, y = percentage, fill = sleep_category)) +
  geom_col(color = "white", size = 1) +
  geom_text(
    aes(label = paste0(round(percentage, 1), "%\n(n=", n, ")")),
    vjust = -0.5,
    fontface = "bold"
  ) +
  scale_fill_manual(
    values = c(
      "Insufficient (<6h)" = "#C73E1D",
      "Short (6-7h)" = "#F18F01",
      "Optimal (7-9h)" = "#06A77D",
      "Long (>9h)" = "#2E86AB"
    )
  ) +
  labs(
    title = "Sleep Duration Categories",
    subtitle = "Distribution of sleep quality based on duration",
    x = "Sleep Category",
    y = "Percentage of Nights (%)",
    caption = "Optimal range based on CDC/NIH guidelines (7-9 hours) | Source: FitBit Wellness Data"
  ) +
  theme_wellness() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(size = 10)
  )

save_wellness_plot(p5, "outputs/plots/10_sleep_quality_categories.png")

cat("\n✓ Sleep visualizations complete\n")
cat("  5 plots saved to outputs/plots/\n\n")
