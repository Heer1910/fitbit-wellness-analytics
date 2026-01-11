# Custom Wellness Theme for ggplot2
# Professional, accessible design following PRD guidelines

library(ggplot2)
library(scales)

#' Custom wellness theme
#'
#' Design principles:
#' - Minimal visual noise
#' - Clear labeling and units
#' - Accessible color schemes (WCAG AA compliant)
#' - Professional appearance
theme_wellness <- function(base_size = 12, base_family = "") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      # Plot background
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      panel.grid.major = element_line(color = "#E5E5E5", size = 0.3),
      panel.grid.minor = element_blank(),
      
      # Plot titles and labels
      plot.title = element_text(
        size = base_size * 1.3,
        face = "bold",
        hjust = 0,
        margin = margin(b = 10)
      ),
      plot.subtitle = element_text(
        size = base_size * 1.1,
        hjust = 0,
        color = "#666666",
        margin = margin(b = 15)
      ),
      plot.caption = element_text(
        size = base_size * 0.9,
        hjust = 1,
        color = "#999999",
        margin = margin(t = 15)
      ),
      
      # Axis
      axis.title = element_text(size = base_size * 1.05, face = "bold"),
      axis.text = element_text(size = base_size * 0.95, color = "#333333"),
      axis.line = element_line(color = "#333333", size = 0.5),
      axis.ticks = element_line(color = "#333333", size = 0.5),
      
      # Legend
      legend.position = "right",
      legend.title = element_text(size = base_size * 1.0, face = "bold"),
      legend.text = element_text(size = base_size * 0.95),
      legend.key = element_blank(),
      legend.background = element_rect(fill = "white", color = NA),
      legend.margin = margin(l = 10),
      
      # Strip (facet labels)
      strip.text = element_text(
        size = base_size * 1.05,
        face = "bold",
        margin = margin(b = 5)
      ),
      strip.background = element_rect(fill = "#F5F5F5", color = NA),
      
      # Margins
      plot.margin = margin(15, 15, 15, 15)
    )
}

#' Accessible color palette for wellness data
#' WCAG AA compliant contrast ratios
#'
#' @param n Number of colors needed
#' @return Vector of color codes
wellness_colors <- function(n = NULL) {
  # Primary palette (colorblind-friendly)
  colors <- c(
    primary_blue = "#2E86AB",      # Steps, primary metric
    primary_green = "#06A77D",     # Sleep, health
    primary_orange = "#F18F01",    # Calories, energy
    primary_purple = "#7B2CBF",    # Activity intensity
    primary_teal = "#16697A",      # Engagement
    neutral_gray = "#666666",      # Reference/baseline
    accent_red = "#C73E1D",        # Alerts/warnings
    accent_yellow = "#F4A259"      # Secondary highlights
  )
  
  if (is.null(n)) {
    return(colors)
  } else if (n <= length(colors)) {
    return(colors[1:n])
  } else {
    # Use colorRampPalette for more colors
    return(colorRampPalette(colors)(n))
  }
}

#' Activity level color palette (ordered)
activity_level_colors <- function() {
  c(
    "Sedentary" = "#D62828",        # Red
    "Low Active" = "#F77F00",       # Orange
    "Somewhat Active" = "#F4A259",  # Light orange
    "Active" = "#06A77D",           # Green
    "Highly Active" = "#2E86AB"     # Blue
  )
}

#' Engagement level color palette
engagement_colors <- function() {
  c(
    "Low Engagement" = "#F18F01",
    "Moderate Engagement" = "#16697A",
    "High Engagement" = "#06A77D"
  )
}

#' Weekend vs Weekday colors
period_colors <- function() {
  c(
    "Weekday" = "#2E86AB",
    "Weekend" = "#F18F01"
  )
}

#' Format number with thousands separator
format_number <- function(x) {
  comma(x, accuracy = 1)
}

#' Save plot with consistent dimensions and quality
#'
#' @param plot ggplot object
#' @param filename File path to save
#' @param width Width in inches
#' @param height Height in inches
#' @param dpi Resolution
save_wellness_plot <- function(plot, filename, width = 10, height = 6, dpi = 300) {
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  
  ggsave(
    filename,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
  
  cat("✓ Saved plot:", filename, "\n")
}

# Example usage and documentation
if (FALSE) {
  # Example plot with custom theme
  library(ggplot2)
  
  example_data <- data.frame(
    category = c("A", "B", "C", "D"),
    value = c(120, 340, 256, 198)
  )
  
  p <- ggplot(example_data, aes(x = category, y = value, fill = category)) +
    geom_col() +
    scale_fill_manual(values = wellness_colors(4)) +
    labs(
      title = "Example Wellness Visualization",
      subtitle = "Demonstrating custom theme and color palette",
      x = "Category",
      y = "Value",
      caption = "Source: Smart Wellness Insights Platform"
    ) +
    theme_wellness()
  
  save_wellness_plot(p, "outputs/plots/example_theme.png")
}
