# Smart Wellness Insights Platform

An industry-grade analytics platform for processing FitBit wearable device data to generate actionable insights for wellness product marketing strategy.

## Project Overview

This project systematically analyzes smart-device behavioral data to produce validated, explainable insights that support:
- Marketing strategy development
- Product positioning decisions
- Customer segmentation
- Data-driven business recommendations

**Primary Business Question:** How are consumers using smart wellness devices, and how can those usage patterns inform product and marketing strategy?

## Technology Stack

- **R**: Data transformation, analysis, and visualization
- **SQL (SQLite)**: Data aggregation and validation
- **RMarkdown**: Reproducible analytical reports
- **ggplot2**: Professional data visualizations
- **testthat**: Unit testing framework

## Project Structure

```
fitbit_fitness_tracker/
├── src/                          # Core R modules (OOP classes, utilities)
│   ├── WellnessDataset.R        # Main data processing class
│   ├── utils_validation.R       # Data validation functions
│   ├── utils_transformation.R   # Data transformation utilities
│   └── database_connector.R     # SQL interface
├── analysis/                     # Analytical scripts
│   ├── 01_exploratory_analysis.R
│   ├── 02_metrics_computation.R
│   ├── 03_time_series_analysis.R
│   ├── 04_correlation_analysis.R
│   └── 05_user_segmentation.R
├── visualizations/               # Plotting scripts
│   ├── theme_wellness.R
│   ├── 01_daily_activity_plots.R
│   ├── 02_sleep_analysis_plots.R
│   ├── 03_behavioral_patterns.R
│   └── 04_export_dashboard_data.R
├── reports/                      # RMarkdown reports
│   ├── analytical_report.Rmd
│   ├── executive_summary.Rmd
│   ├── insights_and_recommendations.md
│   └── data_quality_report.md
├── sql/                          # SQL queries
│   ├── 01_create_schema.sql
│   ├── 02_aggregation_queries.sql
│   └── 03_validation_queries.sql
├── tests/                        # Unit tests
│   ├── test_validation.R
│   ├── test_transformation.R
│   └── test_WellnessDataset.R
├── data/                         # Data storage
│   ├── processed/               # Cleaned datasets (versioned)
│   └── README.md                # Data dictionary
├── logs/                         # Transformation logs
├── outputs/                      # Generated outputs
│   ├── plots/                   # Visualization exports
│   └── tables/                  # CSV exports for dashboards
└── install_dependencies.R       # Dependency installation script
```

## Data Source

**FitBit Fitness Tracker Data** (Public Domain, Kaggle)
- 33 unique users
- 31 days of activity data (April 12 - May 12, 2016)
- Daily activity, steps, sleep duration, calories, heart rate
- Location: `mturkfitbit_export_4.12.16-5.12.16/Fitabase Data 4.12.16-5.12.16/`

### Data Files Used
- `dailyActivity_merged.csv`: Primary activity metrics
- `sleepDay_merged.csv`: Sleep patterns
- `hourlyIntensities_merged.csv`: Activity intensity by hour
- `hourlySteps_merged.csv`: Hourly step counts

## Setup Instructions

### 1. Install R Dependencies

```r
# Run the automated dependency installer
source("install_dependencies.R")
```

Required packages:
- tidyverse (dplyr, ggplot2, tidyr, readr)
- lubridate
- scales
- DBI, RSQLite
- rmarkdown, knitr
- testthat

### 2. Verify Data Availability

Ensure the raw FitBit data is located in:
```
mturkfitbit_export_4.12.16-5.12.16/Fitabase Data 4.12.16-5.12.16/
```

### 3. Run the Complete Pipeline

```r
# Execute end-to-end analysis
source("analysis/01_exploratory_analysis.R")
source("analysis/02_metrics_computation.R")
source("analysis/03_time_series_analysis.R")
source("analysis/04_correlation_analysis.R")
source("analysis/05_user_segmentation.R")
```

### 4. Generate Reports

```r
# Render RMarkdown reports
rmarkdown::render("reports/analytical_report.Rmd")
rmarkdown::render("reports/executive_summary.Rmd")
```

## Architecture Highlights

### Object-Oriented Design

The `WellnessDataset` class implements industry best practices:
- **Single Responsibility**: Each method has one clear purpose
- **Explicit State Transitions**: Raw → Validated → Cleaned → Transformed
- **Deterministic Outputs**: Same input always produces same output
- **Auditable Transformations**: All operations logged with timestamps

### Data Governance

- Read-only raw data storage
- Versioned processed datasets
- Explicit transformation logs in `logs/transformation_log.txt`
- ROCCC criteria documentation

### Validation Rules

- Non-negative values for steps, calories, sleep
- Duplicate record removal
- Documented missing value imputation
- Date continuity validation per user
- Statistical outlier detection (IQR method)

## Key Metrics & Analysis

### Computed Metrics
- Average daily steps (per user and overall)
- Sleep duration distribution (mean, median, quartiles)
- Activity intensity by weekday
- Correlation between activity and sleep quality
- User engagement consistency (coefficient of variation)

### Analytical Techniques
- Time-series trend analysis
- Weekday vs weekend comparative analysis
- User segmentation by behavioral patterns
- Statistical correlation testing
- Engagement drop-off detection

## Deliverables

1. **Analytical Report** (RMarkdown HTML/PDF)
   - Complete methodology and findings
   - Embedded visualizations
   - Statistical results
   - Technical appendix

2. **Executive Summary** (PDF slides)
   - Key insights and recommendations
   - Business implications
   - Visual highlights

3. **Insights Document** (Markdown)
   - Top behavioral patterns
   - Strategic recommendations
   - Marketing implications
   - Limitations and caveats

4. **Data Quality Report**
   - ROCCC assessment
   - Validation results
   - Known limitations

5. **Visualizations**
   - Publication-ready plots (PNG, SVG)
   - Dashboard-ready data exports (CSV)
   - Interactive HTML plots (optional)

## Design Principles

All visualizations follow accessibility guidelines:
- Minimal visual noise
- Clear axis labels with units
- Consistent color semantics
- WCAG AA compliant contrast ratios
- Professional color palettes

## Testing & Quality Assurance

Run unit tests:
```r
source("tests/test_validation.R")
source("tests/test_transformation.R")
source("tests/test_WellnessDataset.R")
```

Verify reproducibility:
```r
# Clean processed data
unlink("data/processed/*")
unlink("logs/*")

# Re-run pipeline (should produce identical results)
source("analysis/01_exploratory_analysis.R")
```

## Data Limitations

- **Small sample size**: 33 users (not representative)
- **Short time period**: 31 days only
- **No demographics**: Cannot segment by age, gender, location
- **Observational**: Correlation, not causation
- **Self-reported bias**: Behavioral data may not reflect general population

All insights include explicit caveats about generalizability.

## Resume-Ready Description

> Designed and implemented an end-to-end analytics system to process, validate, and analyze wearable device data, producing stakeholder-ready insights to inform wellness product marketing strategy. Built reproducible R and SQL pipelines with object-oriented design, documented data governance practices, and delivered executive dashboards highlighting behavioral trends, engagement patterns, and strategic recommendations.

## License

This project uses public domain data. Analysis code is available for educational and portfolio purposes.

## Contact

**Author**: Dhruv Patel  
**Project Type**: Industry-grade analytics portfolio project  
**Case Study Reference**: Bellabeat - How Can a Wellness Technology Company Play It Smart?
