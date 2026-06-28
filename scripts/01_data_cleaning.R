# ==================================================
# FUTURE_DS_02
# Customer Retention & Churn Analysis
# Data Cleaning Script
# ==================================================

library(tidyverse)
library(janitor)
library(lubridate)

# ==================================================
# Import Data
# ==================================================
churn <- read.csv("data/raw/WA_Fn-UseC_-Telco-Customer-Churn.csv")

cat("\n==================== INITIAL INSPECTION ====================\n")
cat("Rows:", nrow(churn), "\n")
cat("Columns:", ncol(churn), "\n")

# ==================================================
# Clean Column Names
# ==================================================
churn <- clean_names(churn)
names(churn)

# ==================================================
# Check Structure
# ==================================================
str(churn)

# ==================================================
# Missing Values
# ==================================================
missing_values <- colSums(is.na(churn))
cat("\nMissing Values:\n")
print(missing_values[missing_values > 0])

# ==================================================
# Convert Data Types
# ==================================================

# Convert SeniorCitizen to factor
churn$senior_citizen <- as.factor(ifelse(churn$senior_citizen == 1, "Yes", "No"))

# Convert TotalCharges to numeric (some may be blank)
churn$total_charges <- as.numeric(churn$total_charges)

# Check for NA introduced in TotalCharges
cat("\nNA in TotalCharges after conversion:", sum(is.na(churn$total_charges)), "\n")

# Fill missing TotalCharges (only for tenure 0 customers)
churn <- churn %>%
  mutate(total_charges = ifelse(is.na(total_charges) & tenure == 0, 0, total_charges))

# Convert character columns to factors
churn <- churn %>%
  mutate(across(where(is.character), as.factor))

# ==================================================
# Create Derived Features
# ==================================================

# Customer tenure groups
churn <- churn %>%
  mutate(tenure_group = case_when(
    tenure <= 12 ~ "0-12 months",
    tenure <= 24 ~ "13-24 months",
    tenure <= 36 ~ "25-36 months",
    tenure <= 48 ~ "37-48 months",
    tenure <= 60 ~ "49-60 months",
    TRUE ~ "60+ months"
  ))

# Monthly charges categories
churn <- churn %>%
  mutate(monthly_charges_group = case_when(
    monthly_charges <= 30 ~ "Low ($0-$30)",
    monthly_charges <= 70 ~ "Medium ($31-$70)",
    TRUE ~ "High ($71+)"
  ))

# Number of services subscribed
service_cols <- c("phone_service", "internet_service", "online_security",
                  "online_backup", "device_protection", "tech_support",
                  "streaming_tv", "streaming_movies")

churn <- churn %>%
  mutate(
    num_services = rowSums(across(all_of(service_cols), ~ . != "No")),
    has_internet = ifelse(internet_service != "No", "Yes", "No")
  )

# ==================================================
# Duplicate Check
# ==================================================
duplicates <- sum(duplicated(churn))
cat("\nDuplicate Records:", duplicates, "\n")

# ==================================================
# Final Summary
# ==================================================
cat("\n==================== FINAL SUMMARY ====================\n")
cat("Final Rows:", nrow(churn), "\n")
cat("Final Columns:", ncol(churn), "\n")
cat("Churn Distribution:\n")
print(table(churn$churn))
cat("\nChurn Rate:", round(prop.table(table(churn$churn))[2] * 100, 2), "%\n")

# ==================================================
# Save Cleaned Data
# ==================================================
dir.create("data/cleaned", recursive = TRUE, showWarnings = FALSE)
write.csv(churn, "data/cleaned/telco_churn_clean.csv", row.names = FALSE)

cat("\nCleaned dataset saved to data/cleaned/telco_churn_clean.csv\n")