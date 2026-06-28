# ==================================================
# FUTURE_DS_02
# Statistical Analysis - Chi-Square & Logistic Regression
# ==================================================

library(tidyverse)
library(scales)
library(broom)
library(gridExtra)

# Load cleaned data
churn <- read.csv("data/cleaned/telco_churn_clean.csv")
churn <- churn %>% mutate(across(where(is.character), as.factor))

# Create binary churn variable
churn$churn_binary <- ifelse(churn$churn == "Yes", 1, 0)

cat("\n================================================")
cat("\n  STATISTICAL ANALYSIS")
cat("\n================================================\n")

# ==================================================
# 1. CHI-SQUARE TESTS - Which factors matter?
# ==================================================
cat("\n==================== CHI-SQUARE TESTS ====================\n")
cat("H0: No relationship between variable and churn\n")
cat("H1: Significant relationship exists\n\n")

# Variables to test
test_vars <- c("gender", "senior_citizen", "partner", "dependents", 
               "phone_service", "multiple_lines", "internet_service",
               "online_security", "online_backup", "device_protection",
               "tech_support", "streaming_tv", "streaming_movies",
               "contract", "paperless_billing", "payment_method",
               "tenure_group", "monthly_charges_group", "has_internet")

chi_square_results <- data.frame(
  Variable = character(),
  Chi_Square = numeric(),
  df = integer(),
  p_value = numeric(),
  Significant = character(),
  stringsAsFactors = FALSE
)

for (var in test_vars) {
  contingency_table <- table(churn[[var]], churn$churn)
  chi_test <- chisq.test(contingency_table)
  
  chi_square_results <- rbind(chi_square_results, data.frame(
    Variable = var,
    Chi_Square = round(chi_test$statistic, 2),
    df = chi_test$parameter,
    p_value = format(chi_test$p.value, scientific = TRUE, digits = 4),
    Significant = ifelse(chi_test$p.value < 0.05, "✅ YES", "❌ NO"),
    stringsAsFactors = FALSE
  ))
}

# Sort by significance
chi_square_results <- chi_square_results %>% arrange(p_value)

cat("\nChi-Square Test Results (sorted by significance):\n")
print(chi_square_results, row.names = FALSE)

# Count significant factors
sig_count <- sum(grepl("YES", chi_square_results$Significant))
cat("\nSignificant factors:", sig_count, "out of", nrow(chi_square_results), "\n")

# ==================================================
# 2. CRAMER'S V - Effect Size
# ==================================================
cat("\n==================== CRAMER'S V - EFFECT SIZE ====================\n")

cramers_v_results <- data.frame(
  Variable = character(),
  Cramers_V = numeric(),
  Strength = character(),
  stringsAsFactors = FALSE
)

for (var in test_vars) {
  contingency_table <- table(churn[[var]], churn$churn)
  chi_test <- chisq.test(contingency_table)
  
  n <- sum(contingency_table)
  min_dim <- min(dim(contingency_table)) - 1
  cramers_v <- sqrt(chi_test$statistic / (n * min_dim))
  
  strength <- case_when(
    cramers_v >= 0.5 ~ "Strong",
    cramers_v >= 0.3 ~ "Moderate",
    cramers_v >= 0.1 ~ "Weak",
    TRUE ~ "Negligible"
  )
  
  cramers_v_results <- rbind(cramers_v_results, data.frame(
    Variable = var,
    Cramers_V = round(cramers_v, 4),
    Strength = strength,
    stringsAsFactors = FALSE
  ))
}

cramers_v_results <- cramers_v_results %>% arrange(desc(Cramers_V))
print(cramers_v_results, row.names = FALSE)

# ==================================================
# 3. LOGISTIC REGRESSION MODEL
# ==================================================
cat("\n==================== LOGISTIC REGRESSION ====================\n")
cat("Model: Churn ~ Contract + Tenure + Internet + Payment + Services\n\n")

# Build model
logit_model <- glm(churn_binary ~ contract + tenure_group + internet_service + 
                     payment_method + num_services + senior_citizen + paperless_billing,
                   data = churn, family = "binomial")

# Summary
model_summary <- summary(logit_model)
print(model_summary)

# ==================================================
# 4. ODDS RATIOS
# ==================================================
cat("\n==================== ODDS RATIOS ====================\n")

# Extract coefficients and calculate odds ratios
odds_ratios <- tidy(logit_model) %>%
  mutate(
    odds_ratio = round(exp(estimate), 3),
    p_value = format(p.value, scientific = TRUE, digits = 3),
    significant = ifelse(p.value < 0.05, "✅", "❌")
  ) %>%
  filter(term != "(Intercept)") %>%
  arrange(desc(abs(odds_ratio - 1)))

print(odds_ratios, n = 30)

# ==================================================
# 5. MODEL PERFORMANCE
# ==================================================
cat("\n==================== MODEL PERFORMANCE ====================\n")

# Pseudo R-squared
null_deviance <- logit_model$null.deviance
residual_deviance <- logit_model$deviance
pseudo_r2 <- 1 - (residual_deviance / null_deviance)

cat("Pseudo R-squared (McFadden):", round(pseudo_r2, 4), "\n")
cat("AIC:", round(AIC(logit_model), 2), "\n")

# Confusion Matrix
churn$predicted_prob <- predict(logit_model, type = "response")
churn$predicted_churn <- ifelse(churn$predicted_prob > 0.5, "Yes", "No")

confusion <- table(Actual = churn$churn, Predicted = churn$predicted_churn)
cat("\nConfusion Matrix:\n")
print(confusion)

# Accuracy
accuracy <- sum(diag(confusion)) / sum(confusion)
cat("\nAccuracy:", round(accuracy * 100, 2), "%\n")

# Sensitivity & Specificity
sensitivity <- confusion[2,2] / sum(confusion[2,])
specificity <- confusion[1,1] / sum(confusion[1,])
cat("Sensitivity (True Positive Rate):", round(sensitivity * 100, 2), "%\n")
cat("Specificity (True Negative Rate):", round(specificity * 100, 2), "%\n")

# ==================================================
# 6. KEY PREDICTORS SUMMARY
# ==================================================
cat("\n==================== TOP CHURN PREDICTORS ====================\n")

top_predictors <- odds_ratios %>%
  filter(significant == "✅") %>%
  arrange(desc(odds_ratio)) %>%
  head(10)

cat("\nTop factors that INCREASE churn risk (Odds Ratio > 1):\n")
top_predictors %>%
  filter(odds_ratio > 1) %>%
  print(n = 10)

cat("\nTop factors that DECREASE churn risk (Odds Ratio < 1):\n")
top_predictors %>%
  filter(odds_ratio < 1) %>%
  print(n = 10)

# ==================================================
# SAVE RESULTS
# ==================================================
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

write.csv(chi_square_results, "outputs/tables/chi_square_results.csv", row.names = FALSE)
write.csv(cramers_v_results, "outputs/tables/cramers_v_results.csv", row.names = FALSE)
write.csv(odds_ratios, "outputs/tables/odds_ratios.csv", row.names = FALSE)

# ==================================================
# VISUALIZATION: Odds Ratios Forest Plot
# ==================================================
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Top 15 predictors
top15 <- odds_ratios %>%
  filter(term != "(Intercept)") %>%
  arrange(desc(odds_ratio)) %>%
  head(15)

forest_plot <- ggplot(top15, aes(x = odds_ratio, y = reorder(term, odds_ratio), color = significant)) +
  geom_point(size = 4) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray40", linewidth = 0.8) +
  geom_segment(aes(x = 1, xend = odds_ratio, y = term, yend = term), linewidth = 1.2) +
  scale_color_manual(values = c("✅" = "#e74c3c", "❌" = "gray60"), guide = "none") +
  scale_x_log10(labels = comma) +
  labs(title = "Odds Ratios: What Drives Customer Churn?",
       subtitle = "Values > 1 increase churn risk | Values < 1 decrease churn risk",
       x = "Odds Ratio (log scale)", y = NULL,
       caption = "Logistic Regression Results") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"),
        plot.subtitle = element_text(size = 10, color = "#7f8c8d"),
        axis.text.y = element_text(size = 10),
        panel.grid.minor = element_blank())

ggsave("outputs/figures/odds_ratios_forest.png", forest_plot, width = 12, height = 7, dpi = 300, bg = "white")

# ==================================================
# FINAL STATISTICAL SUMMARY
# ==================================================
cat("\n\n================================================")
cat("\n  STATISTICAL ANALYSIS COMPLETE")
cat("\n================================================\n")
cat("Significant Predictors:", sig_count, "of", nrow(chi_square_results), "\n")
cat("Model Pseudo R-squared:", round(pseudo_r2, 4), "\n")
cat("Model Accuracy:", round(accuracy * 100, 2), "%\n")
cat("\n✅ Results saved to outputs/tables/ and outputs/figures/\n")