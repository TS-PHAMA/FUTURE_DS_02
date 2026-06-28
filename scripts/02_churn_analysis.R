# ==================================================
# FUTURE_DS_02
# Churn Analysis - KPIs & Visualizations
# ==================================================

library(tidyverse)
library(scales)
library(gridExtra)

# Load cleaned data
churn <- read.csv("data/cleaned/telco_churn_clean.csv")

# Convert back to factors
churn <- churn %>%
  mutate(across(where(is.character), as.factor))

cat("\n================================================")
cat("\n  CHURN ANALYSIS")
cat("\n================================================\n")

# ==================================================
# 1. OVERALL CHURN RATE
# ==================================================
churn_rate <- prop.table(table(churn$churn))[2] * 100
total_customers <- nrow(churn)
churned_customers <- sum(churn$churn == "Yes")
retained_customers <- sum(churn$churn == "No")

cat("\n==================== OVERALL METRICS ====================\n")
cat("Total Customers:", comma(total_customers), "\n")
cat("Churned:", comma(churned_customers), "(", round(churn_rate, 2), "%)\n")
cat("Retained:", comma(retained_customers), "(", round(100 - churn_rate, 2), "%)\n")

# Monthly revenue impact
avg_monthly <- mean(churn$monthly_charges)
lost_revenue_monthly <- churned_customers * avg_monthly
lost_revenue_yearly <- lost_revenue_monthly * 12

cat("\nAverage Monthly Charge: $", round(avg_monthly, 2), "\n")
cat("Estimated Monthly Revenue Lost: $", comma(round(lost_revenue_monthly)), "\n")
cat("Estimated Yearly Revenue Lost: $", comma(round(lost_revenue_yearly)), "\n")

# ==================================================
# 2. CHURN BY CONTRACT TYPE
# ==================================================
cat("\n==================== CHURN BY CONTRACT ====================\n")

contract_churn <- churn %>%
  group_by(contract) %>%
  summarise(
    total = n(),
    churned = sum(churn == "Yes"),
    churn_rate = round(churned / total * 100, 2),
    .groups = 'drop'
  ) %>%
  arrange(desc(churn_rate))

print(contract_churn)

# ==================================================
# 3. CHURN BY TENURE GROUP
# ==================================================
cat("\n==================== CHURN BY TENURE ====================\n")

tenure_churn <- churn %>%
  group_by(tenure_group) %>%
  summarise(
    total = n(),
    churned = sum(churn == "Yes"),
    churn_rate = round(churned / total * 100, 2),
    .groups = 'drop'
  )

print(tenure_churn)

# ==================================================
# 4. CHURN BY INTERNET SERVICE
# ==================================================
cat("\n==================== CHURN BY INTERNET SERVICE ====================\n")

internet_churn <- churn %>%
  group_by(internet_service) %>%
  summarise(
    total = n(),
    churned = sum(churn == "Yes"),
    churn_rate = round(churned / total * 100, 2),
    .groups = 'drop'
  ) %>%
  arrange(desc(churn_rate))

print(internet_churn)

# ==================================================
# 5. CHURN BY PAYMENT METHOD
# ==================================================
cat("\n==================== CHURN BY PAYMENT METHOD ====================\n")

payment_churn <- churn %>%
  group_by(payment_method) %>%
  summarise(
    total = n(),
    churned = sum(churn == "Yes"),
    churn_rate = round(churned / total * 100, 2),
    .groups = 'drop'
  ) %>%
  arrange(desc(churn_rate))

print(payment_churn)

# ==================================================
# 6. CHURN BY NUMBER OF SERVICES
# ==================================================
cat("\n==================== CHURN BY SERVICE COUNT ====================\n")

service_churn <- churn %>%
  group_by(num_services) %>%
  summarise(
    total = n(),
    churned = sum(churn == "Yes"),
    churn_rate = round(churned / total * 100, 2),
    .groups = 'drop'
  ) %>%
  arrange(num_services)

print(service_churn)

# ==================================================
# 7. CHURN BY SENIOR CITIZEN
# ==================================================
cat("\n==================== CHURN BY SENIOR CITIZEN ====================\n")

senior_churn <- churn %>%
  group_by(senior_citizen) %>%
  summarise(
    total = n(),
    churned = sum(churn == "Yes"),
    churn_rate = round(churned / total * 100, 2),
    .groups = 'drop'
  )

print(senior_churn)

# ==================================================
# SAVE ALL TABLES
# ==================================================
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

write.csv(contract_churn, "outputs/tables/churn_by_contract.csv", row.names = FALSE)
write.csv(tenure_churn, "outputs/tables/churn_by_tenure.csv", row.names = FALSE)
write.csv(internet_churn, "outputs/tables/churn_by_internet.csv", row.names = FALSE)
write.csv(payment_churn, "outputs/tables/churn_by_payment.csv", row.names = FALSE)
write.csv(service_churn, "outputs/tables/churn_by_services.csv", row.names = FALSE)
write.csv(senior_churn, "outputs/tables/churn_by_senior.csv", row.names = FALSE)

# ==================================================
# VISUALIZATIONS
# ==================================================
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# Color palette
churn_colors <- c("No" = "#2ecc71", "Yes" = "#e74c3c")

# ---- Plot 1: Overall Churn Rate ----
p1 <- ggplot(data.frame(x = c("Retained", "Churned"), 
                        y = c(retained_customers, churned_customers)),
             aes(x = "", y = y, fill = x)) +
  geom_bar(stat = "identity", width = 1, alpha = 0.9) +
  coord_polar(theta = "y") +
  scale_fill_manual(values = c("Churned" = "#e74c3c", "Retained" = "#2ecc71"), name = "Status") +
  geom_text(aes(label = paste0(x, "\n", comma(y), " (", round(y/sum(y)*100, 1), "%)")),
            position = position_stack(vjust = 0.5), size = 4, fontface = "bold") +
  labs(title = "Overall Churn Rate",
       subtitle = paste0("Churn: ", round(churn_rate, 2), "%")) +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 11, hjust = 0.5, color = "#e74c3c"),
        legend.position = "none")

ggsave("outputs/figures/churn_rate_pie.png", p1, width = 8, height = 6, dpi = 300, bg = "white")

# ---- Plot 2: Churn by Contract ----
p2 <- ggplot(contract_churn, aes(x = reorder(contract, churn_rate), y = churn_rate)) +
  geom_bar(stat = "identity", aes(fill = churn_rate), width = 0.6, alpha = 0.9) +
  geom_text(aes(label = paste0(churn_rate, "%")), hjust = -0.1, size = 4, fontface = "bold") +
  scale_fill_gradient(low = "#2ecc71", high = "#e74c3c", guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  coord_flip() +
  labs(title = "Churn Rate by Contract Type",
       subtitle = "Month-to-month contracts show highest churn",
       x = NULL, y = "Churn Rate (%)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"),
        axis.text.y = element_text(size = 11, face = "bold"))

ggsave("outputs/figures/churn_by_contract.png", p2, width = 10, height = 5, dpi = 300, bg = "white")

# ---- Plot 3: Churn by Tenure ----
p3 <- ggplot(tenure_churn, aes(x = tenure_group, y = churn_rate)) +
  geom_bar(stat = "identity", aes(fill = churn_rate), width = 0.7, alpha = 0.9) +
  geom_text(aes(label = paste0(churn_rate, "%")), vjust = -0.3, size = 3.5, fontface = "bold") +
  scale_fill_gradient(low = "#e74c3c", high = "#2ecc71", guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(title = "Churn Rate by Customer Tenure",
       subtitle = "Churn decreases significantly after 12 months",
       x = "Tenure Group", y = "Churn Rate (%)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/figures/churn_by_tenure.png", p3, width = 10, height = 6, dpi = 300, bg = "white")

# ---- Plot 4: Churn by Internet Service ----
p4 <- ggplot(internet_churn, aes(x = reorder(internet_service, churn_rate), y = churn_rate)) +
  geom_bar(stat = "identity", aes(fill = churn_rate), width = 0.6, alpha = 0.9) +
  geom_text(aes(label = paste0(churn_rate, "%")), hjust = -0.1, size = 4, fontface = "bold") +
  scale_fill_gradient(low = "#2ecc71", high = "#e74c3c", guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  coord_flip() +
  labs(title = "Churn Rate by Internet Service",
       subtitle = "Fiber optic customers churn at highest rate",
       x = NULL, y = "Churn Rate (%)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"),
        axis.text.y = element_text(size = 11, face = "bold"))

ggsave("outputs/figures/churn_by_internet.png", p4, width = 10, height = 5, dpi = 300, bg = "white")

# ---- Plot 5: Churn by Payment Method ----
p5 <- ggplot(payment_churn, aes(x = reorder(payment_method, churn_rate), y = churn_rate)) +
  geom_bar(stat = "identity", aes(fill = churn_rate), width = 0.6, alpha = 0.9) +
  geom_text(aes(label = paste0(churn_rate, "%")), hjust = -0.1, size = 3.5, fontface = "bold") +
  scale_fill_gradient(low = "#2ecc71", high = "#e74c3c", guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.2))) +
  coord_flip() +
  labs(title = "Churn Rate by Payment Method",
       subtitle = "Electronic check users show highest churn",
       x = NULL, y = "Churn Rate (%)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"),
        axis.text.y = element_text(size = 10, face = "bold"))

ggsave("outputs/figures/churn_by_payment.png", p5, width = 10, height = 6, dpi = 300, bg = "white")

# ---- Plot 6: Service Count vs Churn ----
p6 <- ggplot(service_churn, aes(x = factor(num_services), y = churn_rate)) +
  geom_bar(stat = "identity", aes(fill = churn_rate), width = 0.7, alpha = 0.9) +
  geom_text(aes(label = paste0(churn_rate, "%")), vjust = -0.3, size = 3.5, fontface = "bold") +
  scale_fill_gradient(low = "#e74c3c", high = "#2ecc71", guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(title = "Churn Rate by Number of Services",
       subtitle = "More services = Lower churn",
       x = "Number of Services", y = "Churn Rate (%)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"))

ggsave("outputs/figures/churn_by_services.png", p6, width = 10, height = 6, dpi = 300, bg = "white")

# ---- Plot 7: Dashboard Summary ----
p7 <- churn %>%
  group_by(contract, tenure_group) %>%
  summarise(churn_rate = round(mean(churn == "Yes") * 100, 1), .groups = 'drop') %>%
  ggplot(aes(x = tenure_group, y = contract, fill = churn_rate)) +
  geom_tile(color = "white", size = 0.5) +
  geom_text(aes(label = paste0(churn_rate, "%")), size = 4, fontface = "bold") +
  scale_fill_gradient2(low = "#2ecc71", mid = "#f39c12", high = "#e74c3c", midpoint = 30,
                       name = "Churn Rate") +
  labs(title = "Churn Heatmap: Contract × Tenure",
       subtitle = "Month-to-month + low tenure = highest churn risk",
       x = "Tenure Group", y = "Contract Type") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 14, color = "#2c3e50"),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/figures/churn_heatmap.png", p7, width = 10, height = 5, dpi = 300, bg = "white")

# ==================================================
# FINAL SUMMARY
# ==================================================
cat("\n================================================")
cat("\n  KEY INSIGHTS")
cat("\n================================================\n")
cat("1. Overall Churn Rate:", round(churn_rate, 2), "%\n")
cat("2. Highest Churn Contract:", contract_churn$contract[1], "-", contract_churn$churn_rate[1], "%\n")
cat("3. Highest Churn Tenure:", tenure_churn$tenure_group[1], "-", tenure_churn$churn_rate[1], "%\n")
cat("4. Monthly Revenue at Risk: $", comma(round(lost_revenue_monthly)), "\n")
cat("5. Yearly Revenue at Risk: $", comma(round(lost_revenue_yearly)), "\n")

cat("\nVisualizations saved to outputs/figures/\n")
cat("Tables saved to outputs/tables/\n")