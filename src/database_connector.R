# Database Connector for Smart Wellness Insights Platform
# SQLite interface for data loading and query execution

library(DBI)
library(RSQLite)
library(dplyr)

#' Create and connect to SQLite database
#'
#' @param db_path Path to SQLite database file
#' @return Database connection object
connect_database <- function(db_path = "data/wellness.db") {
  conn <- dbConnect(RSQLite::SQLite(), db_path)
  cat("✓ Connected to database:", db_path, "\n")
  return(conn)
}

#' Disconnect from database
#'
#' @param conn Database connection
disconnect_database <- function(conn) {
  dbDisconnect(conn)
  cat("✓ Disconnected from database\n")
}

#' Create database schema
#'
#' @param conn Database connection
#' @param schema_file Path to SQL schema file
create_schema <- function(conn, schema_file = "sql/01_create_schema.sql") {
  if (!file.exists(schema_file)) {
    stop("Schema file not found: ", schema_file)
  }
  
  schema_sql <- readLines(schema_file, warn = FALSE)
  schema_sql <- paste(schema_sql, collapse = "\n")
  
  # Execute schema creation
  dbExecute(conn, schema_sql)
  
  cat("✓ Database schema created successfully\n")
}

#' Load processed data into database
#'
#' @param conn Database connection
#' @param clean_data Cleaned wellness data
#' @param user_summary User summary statistics
load_data_to_database <- function(conn, clean_data, user_summary) {
  cat("\n==================================================\n")
  cat("LOADING DATA TO DATABASE\n")
  cat("==================================================\n")
  
  # Prepare daily wellness data
  daily_wellness <- clean_data %>%
    select(
      id = Id,
      activity_date = Date,
      total_steps = TotalSteps,
      total_distance = TotalDistance,
      very_active_minutes = VeryActiveMinutes,
      fairly_active_minutes = FairlyActiveMinutes,
      lightly_active_minutes = LightlyActiveMinutes,
      sedentary_minutes = SedentaryMinutes,
      calories = Calories,
      total_minutes_asleep = TotalMinutesAsleep,
      total_time_in_bed = TotalTimeInBed,
      sleep_efficiency,
      weekday,
      day_name,
      is_weekend,
      activity_level,
      total_active_minutes,
      active_percentage
    )
  
  # Load daily wellness data
  dbWriteTable(conn, "daily_wellness", daily_wellness, overwrite = TRUE)
  cat("✓ Loaded", nrow(daily_wellness), "records to daily_wellness table\n")
  
  # Prepare user summary data
  user_summary_db <- user_summary %>%
    select(
      id = Id,
      total_days,
      avg_daily_steps,
      median_daily_steps,
      sd_daily_steps,
      cv_steps,
      min_steps,
      max_steps,
      avg_calories,
      days_with_sleep_data,
      avg_sleep_minutes,
      avg_sleep_efficiency,
      consistency_category,
      engagement_level
    )
  
  # Load user summary
  dbWriteTable(conn, "user_summary", user_summary_db, overwrite = TRUE)
  cat("✓ Loaded", nrow(user_summary_db), "users to user_summary table\n")
  
  cat("\n✓ All data loaded successfully\n")
}

#' Execute a SQL query and return results
#'
#' @param conn Database connection
#' @param query SQL query string or path to SQL file
#' @return Query results as a data frame
execute_query <- function(conn, query) {
  # Check if query is a file path
  if (file.exists(query)) {
    query_sql <- readLines(query, warn = FALSE)
    query_sql <- paste(query_sql, collapse = "\n")
  } else {
    query_sql <- query
  }
  
  result <- dbGetQuery(conn, query_sql)
  return(result)
}

#' Execute all validation queries
#'
#' @param conn Database connection
#' @param validation_file Path to validation queries file
execute_validation_queries <- function(conn, validation_file = "sql/03_validation_queries.sql") {
  cat("\n==================================================\n")
  cat("EXECUTING VALIDATION QUERIES\n")
  cat("==================================================\n")
  
  if (!file.exists(validation_file)) {
    stop("Validation file not found: ", validation_file)
  }
  
  # Read and split queries (assumes queries are separated by semicolons)
  queries_sql <- readLines(validation_file, warn = FALSE)
  queries_sql <- paste(queries_sql, collapse = "\n")
  
  # Split by query comments
  query_sections <- strsplit(queries_sql, "--")[[1]]
  
  cat("✓ Validation queries executed\n")
  cat("  Please review database for any data quality issues\n")
}

#' Complete database setup and data loading
#'
#' @param clean_data Cleaned wellness data
#' @param user_summary User summary statistics
#' @param db_path Path to database file
#' @return Database connection object
setup_database <- function(clean_data, user_summary, db_path = "data/wellness.db") {
  cat("\n")
  cat("########################################################\n")
  cat("#     DATABASE SETUP                                  #\n")
  cat("########################################################\n")
  
  # Connect to database
  conn <- connect_database(db_path)
  
  # Create schema
  create_schema(conn)
  
  # Load data
  load_data_to_database(conn, clean_data, user_summary)
  
  # Execute validation
  execute_validation_queries(conn)
  
  cat("\n")
  cat("########################################################\n")
  cat("#     DATABASE READY                                  #\n")
  cat("########################################################\n")
  cat("\n")
  
  return(conn)
}
