# FitBit Wellness Data - Data Dictionary

## Data Source Information

**Dataset**: FitBit Fitness Tracker Data  
**Source**: Kaggle (Public Domain)  
**Collection Period**: April 12, 2016 - May 12, 2016 (31 days)  
**Participants**: 33 unique users  
**License**: Public Domain (CC0)

## ROCCC Data Quality Assessment

| Criterion | Rating | Notes |
|-----------|--------|-------|
| **Reliable** | ✓ Good | Data from Fitbit devices with consistent measurement methodology |
| **Original** | ✓ Good | First-party device data from FitBit trackers via Amazon Mechanical Turk |
| **Comprehensive** | ⚠ Limited | Small sample (n=33), short period (31 days), no demographics |
| **Current** | ✗ Poor | Data from 2016, may not reflect current user behaviors |
| **Cited** | ✓ Good | Well-documented public dataset with clear provenance |

**Overall Assessment**: Suitable for exploratory analysis and technique demonstration. Not suitable for generalizable insights due to small sample size and age of data.

## Primary Data Files

### 1. dailyActivity_merged.csv

**Records**: 940  
**Grain**: One record per user per day  
**Purpose**: Primary activity metrics aggregated daily

| Column Name | Data Type | Description | Range/Format | Validation Rules |
|-------------|-----------|-------------|--------------|------------------|
| Id | Integer | Unique user identifier | 10-digit number | Not null, consistent per user |
| ActivityDate | Date | Date of activity | M/D/YYYY | Valid date, 4/12/2016 - 5/12/2016 |
| TotalSteps | Integer | Total steps taken | 0 - 36,019 | >= 0 |
| TotalDistance | Float | Total distance in km | 0 - 28.03 | >= 0, should align with steps |
| TrackerDistance | Float | Distance recorded by tracker | 0 - 28.03 | >= 0, usually = TotalDistance |
| LoggedActivitiesDistance | Float | Manually logged distance | 0 - 4.91 | >= 0 |
| VeryActiveDistance | Float | Distance during high intensity | 0 - 21.92 | >= 0 |
| ModeratelyActiveDistance | Float | Distance during moderate activity | 0 - 6.48 | >= 0 |
| LightActiveDistance | Float | Distance during light activity | 0 - 10.71 | >= 0 |
| SedentaryActiveDistance | Float | Distance while sedentary | 0 - 0.11 | >= 0 |
| VeryActiveMinutes | Integer | Minutes of high intensity | 0 - 210 | >= 0, <= 1440 |
| FairlyActiveMinutes | Integer | Minutes of moderate activity | 0 - 143 | >= 0, <= 1440 |
| LightlyActiveMinutes | Integer | Minutes of light activity | 0 - 518 | >= 0, <= 1440 |
| SedentaryMinutes | Integer | Minutes sedentary | 0 - 1440 | >= 0, <= 1440 |
| Calories | Integer | Calories burned | 0 - 4900 | >= 0, reasonable range 1000-5000 |

**Data Quality Notes**:
- Distance components may not sum exactly to TotalDistance due to rounding
- Total minutes across all activity levels may not equal 1440 due to non-wear time
- Some users have incomplete daily records

### 2. sleepDay_merged.csv

**Records**: 413  
**Grain**: One record per user per sleep session  
**Purpose**: Sleep tracking data

| Column Name | Data Type | Description | Range/Format | Validation Rules |
|-------------|-----------|-------------|--------------|------------------|
| Id | Integer | Unique user identifier | 10-digit number | Must match Id in dailyActivity |
| SleepDay | DateTime | Date of sleep record | M/D/YYYY HH:MM:SS AM/PM | Valid date, matches ActivityDate range |
| TotalSleepRecords | Integer | Number of sleep sessions | 1 - 3 | >= 1 (can have multiple naps) |
| TotalMinutesAsleep | Integer | Total minutes asleep | 58 - 796 | >= 0, <= 1440 |
| TotalTimeInBed | Integer | Total minutes in bed | 61 - 961 | >= TotalMinutesAsleep |

**Data Quality Notes**:
- Not all users have sleep data (only 24 of 33 users)
- Not all days have sleep records (users wore devices inconsistently)
- Multiple sleep records per day indicate naps or broken sleep
- Sleep efficiency = TotalMinutesAsleep / TotalTimeInBed

### 3. hourlySteps_merged.csv

**Records**: 22,099  
**Grain**: One record per user per hour  
**Purpose**: Hourly step counts for detailed temporal analysis

| Column Name | Data Type | Description | Range/Format | Validation Rules |
|-------------|-----------|-------------|--------------|------------------|
| Id | Integer | Unique user identifier | 10-digit number | Consistent per user |
| ActivityHour | DateTime | Hour of activity | M/D/YYYY HH:MM:SS AM/PM | Valid datetime |
| StepTotal | Integer | Steps in that hour | 0 - 10,554 | >= 0 |

### 4. hourlyIntensities_merged.csv

**Records**: 22,099  
**Grain**: One record per user per hour  
**Purpose**: Hourly activity intensity metrics

| Column Name | Data Type | Description | Range/Format | Validation Rules |
|-------------|-----------|-------------|--------------|------------------|
| Id | Integer | Unique user identifier | 10-digit number | Consistent per user |
| ActivityHour | DateTime | Hour of activity | M/D/YYYY HH:MM:SS AM/PM | Valid datetime |
| TotalIntensity | Integer | Total intensity score | 0 - 180 | >= 0 |
| AverageIntensity | Float | Average intensity | 0 - 3.0 | >= 0 |

### 5. weightLogInfo_merged.csv

**Records**: 67  
**Grain**: One record per user per weight log  
**Purpose**: Weight tracking (sparse data)

| Column Name | Data Type | Description | Range/Format | Validation Rules |
|-------------|-----------|-------------|--------------|------------------|
| Id | Integer | Unique user identifier | 10-digit number | Consistent per user |
| Date | DateTime | Date of measurement | M/D/YYYY HH:MM:SS AM/PM | Valid datetime |
| WeightKg | Float | Weight in kilograms | 52.6 - 133.5 | > 0, reasonable range |
| WeightPounds | Float | Weight in pounds | 116 - 294.3 | > 0, = WeightKg * 2.20462 |
| BMI | Float | Body Mass Index | 21.45 - 47.54 | > 0, reasonable range 15-60 |
| IsManualReport | Boolean | Manual vs auto-sync | True/False | Boolean |

**Data Quality Notes**:
- Only 8 users logged weight data
- Very sparse - not suitable for trend analysis
- BMI calculation may have minor rounding differences

## Derived Metrics

The following metrics will be calculated during transformation:

| Metric Name | Calculation | Purpose |
|-------------|-------------|---------|
| sleep_efficiency | TotalMinutesAsleep / TotalTimeInBed | Sleep quality indicator (0-1) |
| weekday | Extract from ActivityDate | Temporal pattern analysis |
| is_weekend | weekday in (Saturday, Sunday) | Weekend vs weekday comparison |
| activity_level | Categorize based on TotalSteps | User segmentation (Sedentary < 5000, Light 5000-7499, Moderate 7500-9999, Active >= 10000) |
| total_active_minutes | Sum(VeryActive + FairlyActive + LightlyActive) | Total non-sedentary time |
| active_percentage | total_active_minutes / (1440 - SedentaryMinutes) | Engagement metric |
| steps_category | Binned TotalSteps | Distribution visualization |

## Missing Data Patterns

Expected missing data scenarios:
1. **Sleep data**: Not all users have sleep tracking enabled
2. **Weight data**: Very few users log weight
3. **Daily gaps**: Users may not wear devices every day
4. **Hourly gaps**: Device may be off or not synced

**Imputation Strategy**:
- **Do NOT impute** missing days (represents actual non-wear)
- **Remove** duplicates before analysis
- **Flag** outliers but do not remove (may represent valid extreme behaviors)
- **Document** all missing data patterns in reports

## Data Limitations

1. **Sample Size**: Only 33 users - not statistically representative
2. **Duration**: 31 days - cannot identify long-term trends
3. **Demographics**: No age, gender, location, or health status
4. **Behavioral Bias**: Self-selected participants may be more health-conscious
5. **Device Limitations**: Fitbit accuracy varies by activity type
6. **Temporal Relevance**: 2016 data may not reflect current behaviors

## File Metadata

| File | Size | Records | Last Modified |
|------|------|---------|---------------|
| dailyActivity_merged.csv | 111 KB | 940 | -- |
| sleepDay_merged.csv | 18 KB | 413 | -- |
| hourlySteps_merged.csv | 797 KB | 22,099 | -- |
| hourlyIntensities_merged.csv | 899 KB | 22,099 | -- |
| weightLogInfo_merged.csv | 7 KB | 67 | -- |

## References

- FitBit Device Accuracy: https://www.fitbit.com/global/us/technology/accuracy
- CDC Physical Activity Guidelines: https://www.cdc.gov/physicalactivity/basics/
- Sleep Foundation Guidelines: https://www.sleepfoundation.org/
