# WellnessDataset - Object-Oriented Data Processing Class
# Industry-grade Reference Class implementation for FitBit data analysis

library(dplyr)
library(lubridate)
library(readr)

# Source utility functions
source("src/utils_validation.R")
source("src/utils_transformation.R")

#' WellnessDataset Reference Class
#'
#' Implements industry best practices:
#' - Single Responsibility: Each method has one clear purpose
#' - Explicit State Transitions: raw -> validated -> cleaned -> transformed
#' - Deterministic Outputs: Same input always produces same output
#' - Auditable Transformations: All operations logged
WellnessDataset <- setRefClass(
  "WellnessDataset",
  
  fields = list(
    # Core data fields
    raw_activity = "data.frame",
    raw_sleep = "data.frame",
    clean_data = "data.frame",
    user_summary = "data.frame",
    
    # Validation and metadata
    validation_report = "list",
    transformation_log_path = "character",
    data_loaded = "logical",
    data_validated = "logical",
    data_transformed = "logical",
    
    # Configuration
    data_directory = "character",
    processed_directory = "character"
  ),
  
  methods = list(
    #' Initialize the WellnessDataset
    initialize = function(data_dir = "mturkfitbit_export_4.12.16-5.12.16/Fitabase Data 4.12.16-5.12.16",
                          processed_dir = "data/processed",
                          log_path = "logs/transformation_log.txt") {
      "Initialize a new WellnessDataset instance"
      
      data_directory <<- data_dir
      processed_directory <<- processed_dir
      transformation_log_path <<- log_path
      
      raw_activity <<- data.frame()
      raw_sleep <<- data.frame()
      clean_data <<- data.frame()
      user_summary <<- data.frame()
      validation_report <<- list()
      
      data_loaded <<- FALSE
      data_validated <<- FALSE
      data_transformed <<- FALSE
      
      cat("WellnessDataset initialized\n")
      cat("Data directory:", data_directory, "\n")
      cat("Processed output:", processed_directory, "\n")
    },
    
    #' Load raw CSV files
    load = function() {
      "Load raw FitBit CSV files into memory"
      
      cat("\n==================================================\n")
      cat("LOADING RAW DATA\n")
      cat("==================================================\n")
      
      activity_path <- file.path(data_directory, "dailyActivity_merged.csv")
      sleep_path <- file.path(data_directory, "sleepDay_merged.csv")
      
      # Load activity data
      if (!file.exists(activity_path)) {
        stop("Activity data file not found: ", activity_path)
      }
      raw_activity <<- read_csv(activity_path, show_col_types = FALSE)
      cat("✓ Loaded activity data:", nrow(raw_activity), "records\n")
      
      # Load sleep data
      if (!file.exists(sleep_path)) {
        stop("Sleep data file not found: ", sleep_path)
      }
      raw_sleep <<- read_csv(sleep_path, show_col_types = FALSE)
      cat("✓ Loaded sleep data:", nrow(raw_sleep), "records\n")
      
      # Basic summary
      cat("\nSummary:\n")
      cat("  Activity records:", nrow(raw_activity), "\n")
      cat("  Unique users (activity):", length(unique(raw_activity$Id)), "\n")
      cat("  Sleep records:", nrow(raw_sleep), "\n")
      cat("  Unique users (sleep):", length(unique(raw_sleep$Id)), "\n")
      
      data_loaded <<- TRUE
      
      return(invisible(.self))
    },
    
    #' Validate data quality
    validate = function() {
      "Apply comprehensive validation rules to raw data"
      
      if (!data_loaded) {
        stop("Data must be loaded before validation. Call load() first.")
      }
      
      cat("\n==================================================\n")
      cat("VALIDATING DATA QUALITY\n")
      cat("==================================================\n")
      
      validation_results <- list()
      
      # ACTIVITY DATA VALIDATIONS
      cat("\nVALIDATING ACTIVITY DATA:\n")
      cat("--------------------------------------------------\n")
      
      # Check non-negative values
      validation_results$activity_non_negative <- check_non_negative(
        raw_activity,
        c("TotalSteps", "TotalDistance", "VeryActiveMinutes", "FairlyActiveMinutes",
          "LightlyActiveMinutes", "SedentaryMinutes", "Calories")
      )
      cat("✓ Non-negative values:", 
          ifelse(validation_results$activity_non_negative$is_valid, "PASS", "FAIL"),
          "(", validation_results$activity_non_negative$invalid_count, "issues )\n")
      
      # Check for duplicates
      validation_results$activity_duplicates <- check_duplicates(
        raw_activity,
        c("Id", "ActivityDate")
      )
      cat("✓ Duplicate check:", 
          ifelse(validation_results$activity_duplicates$is_valid, "PASS", "FAIL"),
          "(", validation_results$activity_duplicates$duplicate_count, "duplicates )\n")
      
      # Check range for minutes (should not exceed 1440 minutes per day)
      validation_results$activity_minutes_range <- validate_range(
        raw_activity,
        "SedentaryMinutes",
        0,
        1440
      )
      cat("✓ Minutes range validation:", 
          ifelse(validation_results$activity_minutes_range$is_valid, "PASS", "FAIL"),
          "\n")
      
      # Detect outliers in steps
      validation_results$steps_outliers <- detect_outliers(
        raw_activity,
        "TotalSteps",
        multiplier = 3.0  # Use 3.0 for extreme outliers only
      )
      cat("✓ Steps outlier detection:",
          validation_results$steps_outliers$outlier_count, "extreme outliers found\n")
      
      # SLEEP DATA VALIDATIONS
      cat("\nVALIDATING SLEEP DATA:\n")
      cat("--------------------------------------------------\n")
      
      # Check non-negative sleep values
      validation_results$sleep_non_negative <- check_non_negative(
        raw_sleep,
        c("TotalMinutesAsleep", "TotalTimeInBed")
      )
      cat("✓ Non-negative values:", 
          ifelse(validation_results$sleep_non_negative$is_valid, "PASS", "FAIL"),
          "\n")
      
      # Check logical consistency: TotalTimeInBed >= TotalMinutesAsleep
      validation_results$sleep_consistency <- check_logical_consistency(
        raw_sleep,
        "TotalTimeInBed >= TotalMinutesAsleep",
        "TotalTimeInBed must be >= TotalMinutesAsleep"
      )
      cat("✓ Sleep consistency:", 
          ifelse(validation_results$sleep_consistency$is_valid, "PASS", "FAIL"),
          "(", validation_results$sleep_consistency$inconsistent_count, "inconsistencies )\n")
      
      # Store validation results
      validation_report <<- validation_results
      data_validated <<- TRUE
      
      # Generate and save validation report
      report_text <- generate_validation_report(validation_results, "FitBit Wellness Data")
      cat("\n", report_text, "\n")
      
      # Save to file
      validation_file <- file.path(processed_directory, "validation_report.txt")
      cat(report_text, file = validation_file)
      cat("✓ Validation report saved to:", validation_file, "\n")
      
      return(invisible(.self))
    },
    
    #' Clean and transform data
    transform = function() {
      "Apply transformations and create derived metrics"
      
      if (!data_validated) {
        stop("Data must be validated before transformation. Call validate() first.")
      }
      
      cat("\n==================================================\n")
      cat("TRANSFORMING DATA\n")
      cat("==================================================\n")
      
      # Apply all transformations
      clean_data <<- apply_all_transformations(
        raw_activity,
        raw_sleep,
        transformation_log_path
      )
      
      cat("✓ Transformation pipeline completed\n")
      cat("  Final dataset:", nrow(clean_data), "rows,", ncol(clean_data), "columns\n")
      
      data_transformed <<- TRUE
      
      return(invisible(.self))
    },
    
    #' Generate user-level summary statistics
    summarize = function() {
      "Calculate user-level engagement and behavior metrics"
      
      if (!data_transformed) {
        stop("Data must be transformed before summarization. Call transform() first.")
      }
      
      cat("\n==================================================\n")
      cat("GENERATING USER SUMMARY STATISTICS\n")
      cat("==================================================\n")
      
      user_summary <<- calculate_user_engagement(clean_data)
      
      cat("✓ User summary generated for", nrow(user_summary), "users\n")
      
      # Display summary
      cat("\nUser Engagement Distribution:\n")
      print(table(user_summary$engagement_level))
      
      cat("\nUser Consistency Distribution:\n")
      print(table(user_summary$consistency_category))
      
      return(invisible(.self))
    },
    
    #' Export processed data
    export = function(version = format(Sys.Date(), "%Y%m%d")) {
      "Save processed data to CSV with version control"
      
      if (!data_transformed) {
        stop("No transformed data to export. Call transform() first.")
      }
      
      cat("\n==================================================\n")
      cat("EXPORTING PROCESSED DATA\n")
      cat("==================================================\n")
      
      # Ensure output directory exists
      dir.create(processed_directory, recursive = TRUE, showWarnings = FALSE)
      
      # Export transformed data
      clean_file <- file.path(processed_directory, paste0("wellness_data_clean_", version, ".csv"))
      write_csv(clean_data, clean_file)
      cat("✓ Saved clean data:", clean_file, "\n")
      
      # Export user summary
      if (nrow(user_summary) > 0) {
        summary_file <- file.path(processed_directory, paste0("user_summary_", version, ".csv"))
        write_csv(user_summary, summary_file)
        cat("✓ Saved user summary:", summary_file, "\n")
      }
      
      # Create metadata file
      metadata <- list(
        export_date = Sys.time(),
        version = version,
        records_count = nrow(clean_data),
        users_count = length(unique(clean_data$Id)),
        date_range = paste(min(clean_data$Date), "to", max(clean_data$Date)),
        columns = ncol(clean_data)
      )
      
      metadata_file <- file.path(processed_directory, paste0("metadata_", version, ".txt"))
      cat(paste(names(metadata), metadata, sep = ": ", collapse = "\n"),
          file = metadata_file)
      cat("✓ Saved metadata:", metadata_file, "\n")
      
      return(invisible(.self))
    },
    
    #' Get cleaned data
    get_clean_data = function() {
      "Return the transformed dataset"
      if (!data_transformed) {
        stop("No transformed data available. Call transform() first.")
      }
      return(clean_data)
    },
    
    #' Get user summary
    get_user_summary = function() {
      "Return the user summary statistics"
      if (nrow(user_summary) == 0) {
        stop("No user summary available. Call summarize() first.")
      }
      return(user_summary)
    },
    
    #' Get validation results
    get_validation_report = function() {
      "Return the validation report"
      if (!data_validated) {
        stop("No validation report available. Call validate() first.")
      }
      return(validation_report)
    },
    
    #' Run complete pipeline
    run_pipeline = function(export_data = TRUE) {
      "Execute the complete data processing pipeline"
      
      cat("\n")
      cat("########################################################\n")
      cat("#                                                      #\n")
      cat("#     SMART WELLNESS INSIGHTS PLATFORM                #\n")
      cat("#     Data Processing Pipeline                        #\n")
      cat("#                                                      #\n")
      cat("########################################################\n")
      cat("\n")
      
      .self$load()
      .self$validate()
      .self$transform()
      .self$summarize()
      
      if (export_data) {
        .self$export()
      }
      
      cat("\n")
      cat("########################################################\n")
      cat("#     PIPELINE COMPLETED SUCCESSFULLY                 #\n")
      cat("########################################################\n")
      cat("\n")
      
      return(invisible(.self))
    }
  )
)
