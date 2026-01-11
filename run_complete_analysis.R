#!/usr/bin/env Rscript
# Master Script - Run Complete Smart Wellness Insights Platform Analysis
# Execute the entire analytical pipeline from data loading to report generation

cat("\n")
cat("############################################################\n")
cat("#                                                          #\n")
cat("#     SMART WELLNESS INSIGHTS PLATFORM                    #\n")
cat("#     Complete Analytical Pipeline                        #\n")
cat("#                                                          #\n")
cat("############################################################\n")
cat("\n")

start_time <- Sys.time()

# Step 1: Data Processing Pipeline
cat("\n==========================================================\n")
cat("STEP 1 OF 5: DATA PROCESSING PIPELINE\n")
cat("==========================================================\n")
source("analysis/01_exploratory_analysis.R")

# Step 2: Metrics Computation
cat("\n==========================================================\n")
cat("STEP 2 OF 5: METRICS COMPUTATION\n")
cat("==========================================================\n")
source("analysis/02_metrics_computation.R")

# Step 3: Activity Visualizations
cat("\n==========================================================\n")
cat("STEP 3 OF 5: ACTIVITY VISUALIZATIONS\n")
cat("==========================================================\n")
source("visualizations/01_daily_activity_plots.R")

# Step 4: Sleep Visualizations
cat("\n==========================================================\n")
cat("STEP 4 OF 5: SLEEP VISUALIZATIONS\n")
cat("==========================================================\n")
source("visualizations/02_sleep_analysis_plots.R")

# Step 5: Database Loader (optional)
cat("\n==========================================================\n")
cat("STEP 5 OF 5: DATABASE SETUP (OPTIONAL)\n")
cat("==========================================================\n")

if (file.exists("src/database_connector.R")) {
  cat("Setting up SQLite database...\n")
  source("src/database_connector.R")
  
  # Get clean data
  files <- list.files("data/processed", pattern = "wellness_data_clean_.*\\.csv", full.names = TRUE)
  latest_clean <- files[order(file.mtime(files), decreasing = TRUE)][1]
  clean_data <- read.csv(latest_clean)
  
  files_summary <- list.files("data/processed", pattern = "user_summary_.*\\.csv", full.names = TRUE)
  latest_summary <- files_summary[order(file.mtime(files_summary), decreasing = TRUE)][1]
  user_summary <- read.csv(latest_summary)
  
  # Setup database
  conn <- setup_database(clean_data, user_summary)
  
  # Disconnect
  disconnect_database(conn)
} else {
  cat("Skipping database setup (database_connector.R not found)\n")
}

end_time <- Sys.time()
duration <- difftime(end_time, start_time, units = "secs")

cat("\n")
cat("############################################################\n")
cat("#                                                          #\n")
cat("#     PIPELINE EXECUTION COMPLETE                         #\n")
cat("#                                                          #\n")
cat("############################################################\n")
cat("\n")
cat("Total execution time:", round(duration, 1), "seconds\n")
cat("\nOutputs Generated:\n")
cat("  - Processed data: data/processed/\n")
cat("  - Metrics tables: outputs/tables/\n")
cat("  - Visualizations: outputs/plots/\n")
cat("  - Database: data/wellness.db\n")
cat("  - Transformation logs: logs/transformation_log.txt\n")
cat("\nNext Steps:\n")
cat("  1. Review insights: reports/insights_and_recommendations.md\n")
cat("  2. View visualizations in outputs/plots/\n")
cat("  3. Query database with SQL (data/wellness.db)\n")
cat("\n")
