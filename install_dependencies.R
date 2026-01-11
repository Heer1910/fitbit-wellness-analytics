#!/usr/bin/env Rscript
# Smart Wellness Insights Platform - Dependency Installer
# Automated installation of all required R packages

cat("==========================================================\n")
cat("Smart Wellness Insights Platform - Dependency Installer\n")
cat("==========================================================\n\n")

# CRAN packages required for the project
packages <- c(
  # Data manipulation and pipeline
  "tidyverse",      # Meta-package: dplyr, ggplot2, tidyr, readr, purrr, tibble, stringr, forcats
  "lubridate",      # Date/time manipulation
  "data.table",     # High-performance data manipulation
  
  # Database and SQL
  "DBI",            # Database interface
  "RSQLite",        # SQLite database connector
  
  # Visualization
  "scales",         # Scale functions for ggplot2
  "viridis",        # Accessible color palettes
  "RColorBrewer",   # Color palettes
  "ggthemes",       # Additional ggplot2 themes
  "patchwork",      # Combine multiple plots
  
  # Reporting
  "rmarkdown",      # RMarkdown reports
  "knitr",          # Dynamic report generation
  "kableExtra",     # Enhanced tables for RMarkdown
  
  # Statistical analysis
  "psych",          # Statistical analysis tools
  "corrplot",       # Correlation plot visualization
  
  # Testing
  "testthat",       # Unit testing framework
  
  # Utilities
  "here",           # Path management
  "glue"            # String interpolation
)

cat("Checking and installing required packages...\n\n")

# Function to install packages if not already installed
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    cat(paste0("Installing: ", package, "\n"))
    install.packages(package, dependencies = TRUE, repos = "https://cloud.r-project.org/")
    
    # Verify installation
    if (require(package, character.only = TRUE, quietly = TRUE)) {
      cat(paste0("✓ Successfully installed: ", package, "\n"))
    } else {
      cat(paste0("✗ FAILED to install: ", package, "\n"))
    }
  } else {
    cat(paste0("✓ Already installed: ", package, "\n"))
  }
}

# Install all packages
for (pkg in packages) {
  install_if_missing(pkg)
}

cat("\n==========================================================\n")
cat("Dependency installation complete!\n")
cat("==========================================================\n\n")

# Display session info for reproducibility
cat("R Session Information:\n")
cat("----------------------\n")
print(sessionInfo())

# Create a file documenting installed versions
sink("logs/package_versions.txt")
cat("Smart Wellness Insights Platform - Installed Package Versions\n")
cat(paste0("Generated: ", Sys.time(), "\n\n"))
cat("Session Info:\n")
cat("=============\n")
print(sessionInfo())
cat("\n\nInstalled Packages:\n")
cat("===================\n")
ip <- as.data.frame(installed.packages()[, c("Package", "Version")])
print(ip[ip$Package %in% packages, ])
sink()

cat("\n✓ Package version log saved to: logs/package_versions.txt\n")
