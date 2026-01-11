# Wellness Dataset Validation Utilities
# Reusable functions for data quality checks

library(dplyr)
library(lubridate)

#' Check for non-negative values in specified columns
#'
#' @param data A data frame
#' @param columns Character vector of column names to check
#' @return List with is_valid (boolean) and invalid_rows (data frame)
check_non_negative <- function(data, columns) {
  invalid_rows <- data.frame()
  
  for (col in columns) {
    if (col %in% names(data)) {
      col_invalid <- data %>%
        filter(.data[[col]] < 0) %>%
        mutate(validation_issue = paste0(col, " is negative"))
      
      invalid_rows <- bind_rows(invalid_rows, col_invalid)
    }
  }
  
  list(
    is_valid = nrow(invalid_rows) == 0,
    invalid_count = nrow(invalid_rows),
    invalid_rows = invalid_rows
  )
}

#' Check for duplicate records based on key columns
#'
#' @param data A data frame
#' @param key_columns Character vector of columns that define uniqueness
#' @return List with is_valid, duplicate_count, and duplicate_rows
check_duplicates <- function(data, key_columns) {
  duplicates <- data %>%
    group_by(across(all_of(key_columns))) %>%
    filter(n() > 1) %>%
    ungroup() %>%
    mutate(validation_issue = "Duplicate record")
  
  list(
    is_valid = nrow(duplicates) == 0,
    duplicate_count = nrow(duplicates),
    duplicate_rows = duplicates
  )
}

#' Detect statistical outliers using IQR method
#'
#' @param data A data frame
#' @param column Column name to check for outliers
#' @param multiplier IQR multiplier (default 1.5, use 3.0 for extreme outliers)
#' @return List with outlier information
detect_outliers <- function(data, column, multiplier = 1.5) {
  if (!column %in% names(data)) {
    return(list(is_valid = TRUE, outlier_count = 0, outliers = data.frame()))
  }
  
  values <- data[[column]]
  q1 <- quantile(values, 0.25, na.rm = TRUE)
  q3 <- quantile(values, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  
  lower_bound <- q1 - (multiplier * iqr)
  upper_bound <- q3 + (multiplier * iqr)
  
  outliers <- data %>%
    mutate(
      is_outlier = .data[[column]] < lower_bound | .data[[column]] > upper_bound,
      outlier_type = case_when(
        .data[[column]] < lower_bound ~ "low",
        .data[[column]] > upper_bound ~ "high",
        TRUE ~ "none"
      ),
      validation_issue = ifelse(
        is_outlier,
        paste0(column, " is an outlier (", outlier_type, ")"),
        NA_character_
      )
    ) %>%
    filter(is_outlier)
  
  list(
    is_valid = nrow(outliers) == 0,
    outlier_count = nrow(outliers),
    outliers = outliers,
    bounds = c(lower = lower_bound, upper = upper_bound),
    summary = c(q1 = q1, median = median(values, na.rm = TRUE), q3 = q3, iqr = iqr)
  )
}

#' Validate date continuity for each user
#'
#' @param data A data frame with Id and date column
#' @param id_col Name of the ID column
#' @param date_col Name of the date column
#' @return List with validation results
check_date_continuity <- function(data, id_col = "Id", date_col = "ActivityDate") {
  gaps <- data %>%
    arrange(.data[[id_col]], .data[[date_col]]) %>%
    group_by(.data[[id_col]]) %>%
    mutate(
      prev_date = lag(.data[[date_col]]),
      day_gap = as.numeric(difftime(.data[[date_col]], prev_date, units = "days"))
    ) %>%
    filter(!is.na(day_gap) & day_gap > 1) %>%
    ungroup() %>%
    mutate(validation_issue = paste0("Date gap of ", day_gap, " days"))
  
  list(
    is_valid = nrow(gaps) == 0,
    gap_count = nrow(gaps),
    gaps = gaps
  )
}

#' Validate values are within expected range
#'
#' @param data A data frame
#' @param column Column name to validate
#' @param min_val Minimum expected value (inclusive)
#' @param max_val Maximum expected value (inclusive)
#' @return List with validation results
validate_range <- function(data, column, min_val, max_val) {
  if (!column %in% names(data)) {
    return(list(is_valid = TRUE, out_of_range_count = 0, out_of_range_rows = data.frame()))
  }
  
  out_of_range <- data %>%
    filter(.data[[column]] < min_val | .data[[column]] > max_val) %>%
    mutate(validation_issue = paste0(
      column, " out of range [", min_val, ", ", max_val, "]"
    ))
  
  list(
    is_valid = nrow(out_of_range) == 0,
    out_of_range_count = nrow(out_of_range),
    out_of_range_rows = out_of_range
  )
}

#' Check for missing values in required columns
#'
#' @param data A data frame
#' @param required_columns Character vector of columns that must not be NA
#' @return List with validation results
check_missing_required <- function(data, required_columns) {
  missing_data <- data.frame()
  
  for (col in required_columns) {
    if (col %in% names(data)) {
      col_missing <- data %>%
        filter(is.na(.data[[col]])) %>%
        mutate(validation_issue = paste0(col, " is missing (NA)"))
      
      missing_data <- bind_rows(missing_data, col_missing)
    }
  }
  
  list(
    is_valid = nrow(missing_data) == 0,
    missing_count = nrow(missing_data),
    missing_rows = missing_data
  )
}

#' Validate logical consistency between related fields
#'
#' @param data A data frame
#' @param condition A quoted expression representing the consistency rule
#' @param error_message Message to display for violations
#' @return List with validation results
check_logical_consistency <- function(data, condition, error_message) {
  inconsistent <- data %>%
    filter(!(!!rlang::parse_expr(condition))) %>%
    mutate(validation_issue = error_message)
  
  list(
    is_valid = nrow(inconsistent) == 0,
    inconsistent_count = nrow(inconsistent),
    inconsistent_rows = inconsistent
  )
}

#' Comprehensive validation report
#'
#' @param validation_results List of results from validation functions
#' @param dataset_name Name of the dataset being validated
#' @return Character string with formatted report
generate_validation_report <- function(validation_results, dataset_name) {
  report <- paste0(
    "========================================\n",
    "VALIDATION REPORT: ", dataset_name, "\n",
    "Generated: ", Sys.time(), "\n",
    "========================================\n\n"
  )
  
  total_issues <- 0
  
  for (check_name in names(validation_results)) {
    result <- validation_results[[check_name]]
    
    if (!is.null(result$is_valid)) {
      status <- ifelse(result$is_valid, "✓ PASS", "✗ FAIL")
      count_field <- names(result)[grepl("count", names(result))][1]
      issue_count <- if (!is.null(count_field)) result[[count_field]] else 0
      
      report <- paste0(
        report,
        status, " - ", check_name, "\n"
      )
      
      if (issue_count > 0) {
        report <- paste0(report, "  Issues found: ", issue_count, "\n")
        total_issues <- total_issues + issue_count
      }
      
      report <- paste0(report, "\n")
    }
  }
  
  report <- paste0(
    report,
    "========================================\n",
    "TOTAL ISSUES: ", total_issues, "\n",
    "========================================\n"
  )
  
  return(report)
}
