# ══════════════════════════════════════════════════════════════════════════════
# DISSERTATION ANALYSIS SCRIPT
# Title: Do Global Oil Price Shocks Raise India's Inflation More Than
#        They Lower It? — Asymmetric Pass-Through to CPI (2004–2024)
# Author: Aniket Pandey | JNU MS Economics 2026
# ══════════════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 0: SETUP — PACKAGES AND DIRECTORIES
# ══════════════════════════════════════════════════════════════════════════════
cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 0: SETUP — PACKAGES AND DIRECTORIES\n")
cat("══════════════════════════════════════════════════\n")

required_packages <- c(
  "tidyverse", "readxl", "tseries", "lmtest", "sandwich",
  "car", "strucchange", "stargazer", "patchwork", "scales", "zoo"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

cat("  ✓ All packages loaded\n")
cat("  ✓ Output directories created\n")

# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 1: DATA LOADING AND MERGING
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 1: DATA LOADING AND MERGING\n")
cat("══════════════════════════════════════════════════\n")

# --- Load FRED CSVs ---
cpi_raw <- read.csv("data/raw/INDCPIALLMINMEI.csv", stringsAsFactors = FALSE)
brent_raw <- read.csv("data/raw/POILBREUSDM.csv", stringsAsFactors = FALSE)
exr_raw <- read.csv("data/raw/EXINUS.csv", stringsAsFactors = FALSE)

# Rename columns
cpi_raw <- cpi_raw %>% rename(date = observation_date, cpi = INDCPIALLMINMEI)
brent_raw <- brent_raw %>% rename(date = observation_date, brent_usd = POILBREUSDM)
exr_raw <- exr_raw %>% rename(date = observation_date, exr = EXINUS)

# Parse dates
cpi_raw$date <- as.Date(cpi_raw$date)
brent_raw$date <- as.Date(brent_raw$date)
exr_raw$date <- as.Date(exr_raw$date)

cat(sprintf("  CPI:   %s to %s  (%d obs)\n", min(cpi_raw$date), max(cpi_raw$date), nrow(cpi_raw)))
cat(sprintf("  Brent: %s to %s  (%d obs)\n", min(brent_raw$date), max(brent_raw$date), nrow(brent_raw)))
cat(sprintf("  EXR:   %s to %s  (%d obs)\n", min(exr_raw$date), max(exr_raw$date), nrow(exr_raw)))

# --- Load IIP chained ---
iip_raw <- read_excel("data/raw/iip_chained.xlsx", sheet = "IIP_Chained")
iip_raw$date <- as.Date(iip_raw$date)
iip_raw <- iip_raw %>% rename(iip = iip_chained)
cat(sprintf("  IIP:   %s to %s  (%d obs)\n", min(iip_raw$date), max(iip_raw$date), nrow(iip_raw)))

# --- Merge all on date ---
df <- cpi_raw %>%
  inner_join(brent_raw, by = "date") %>%
  inner_join(exr_raw, by = "date") %>%
  inner_join(iip_raw, by = "date") %>%
  arrange(date)

# --- Trim to study window: April 2004 – December 2024 ---
study_start <- as.Date("2004-04-01")
study_end   <- as.Date("2024-12-01")
df <- df %>% filter(date >= study_start & date <= study_end)

cat(sprintf("\n  ✓ Merged dataset: %s to %s  (N = %d)\n", min(df$date), max(df$date), nrow(df)))
if (nrow(df) == 249) {
  cat("  ✓ 249 observations as expected\n")
} else {
  cat(sprintf("  ⚠ Got %d observations (expected 249)\n", nrow(df)))
}

}, error = function(e) cat(sprintf("  ✗ SECTION 1 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 2: VARIABLE CONSTRUCTION
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 2: VARIABLE CONSTRUCTION\n")
cat("══════════════════════════════════════════════════\n")

# 2.1 INR-denominated oil price
df$oil_inr <- df$brent_usd * df$exr
cat("  ✓ Oil_INR = Brent_USD × INR/USD constructed\n")

# 2.2 Log levels
df$ln_cpi <- log(df$cpi)
df$ln_oil <- log(df$oil_inr)
df$ln_iip <- log(df$iip)
df$ln_brent <- log(df$brent_usd)  # for robustness check

# 2.3 Log-differences (× 100 for percent)
df$dlnCPI <- c(NA, 100 * diff(df$ln_cpi))
df$dlnOil <- c(NA, 100 * diff(df$ln_oil))
df$dlnIIP <- c(NA, 100 * diff(df$ln_iip))
df$dlnBrent <- c(NA, 100 * diff(df$ln_brent))  # USD-only for robustness
cat("  ✓ Log-differences computed (×100 for percent)\n")

# 2.4 Partial sum decomposition
df$dlnOil_pos <- ifelse(!is.na(df$dlnOil), pmax(df$dlnOil, 0), NA)
df$dlnOil_neg <- ifelse(!is.na(df$dlnOil), pmin(df$dlnOil, 0), NA)

# USD-only decomposition for robustness
df$dlnBrent_pos <- ifelse(!is.na(df$dlnBrent), pmax(df$dlnBrent, 0), NA)
df$dlnBrent_neg <- ifelse(!is.na(df$dlnBrent), pmin(df$dlnBrent, 0), NA)
cat("  ✓ Partial sum decomposition: ΔOil+ and ΔOil- created\n")

# 2.5 Policy dummies
df$D_petrol <- ifelse(df$date >= as.Date("2010-06-01"), 1, 0)
df$D_diesel <- ifelse(df$date >= as.Date("2014-10-01"), 1, 0)
df$D_covid  <- ifelse(df$date == as.Date("2020-04-01"), 1, 0)

# Monthly dummies (Jan=1 through Nov=11; Dec is reference)
df$month <- as.integer(format(df$date, "%m"))
for (m in 1:11) {
  df[[paste0("M", m)]] <- ifelse(df$month == m, 1, 0)
}
cat("  ✓ Policy dummies (petrol, diesel, COVID) created\n")
cat("  ✓ Monthly seasonal dummies M1–M11 created\n")

# 2.6 Create lags — AR lags of CPI (up to L4 for AIC selection)
df$dlnCPI_L1 <- dplyr::lag(df$dlnCPI, 1)
df$dlnCPI_L2 <- dplyr::lag(df$dlnCPI, 2)
df$dlnCPI_L3 <- dplyr::lag(df$dlnCPI, 3)
df$dlnCPI_L4 <- dplyr::lag(df$dlnCPI, 4)
df$dlnOil_L1 <- dplyr::lag(df$dlnOil, 1)

df$dlnOil_pos_L0 <- df$dlnOil_pos
df$dlnOil_pos_L1 <- dplyr::lag(df$dlnOil_pos, 1)
df$dlnOil_pos_L2 <- dplyr::lag(df$dlnOil_pos, 2)
df$dlnOil_pos_L3 <- dplyr::lag(df$dlnOil_pos, 3)

df$dlnOil_neg_L0 <- df$dlnOil_neg
df$dlnOil_neg_L1 <- dplyr::lag(df$dlnOil_neg, 1)
df$dlnOil_neg_L2 <- dplyr::lag(df$dlnOil_neg, 2)
df$dlnOil_neg_L3 <- dplyr::lag(df$dlnOil_neg, 3)

# USD-only lags for robustness
df$dlnBrent_pos_L0 <- df$dlnBrent_pos
df$dlnBrent_pos_L1 <- dplyr::lag(df$dlnBrent_pos, 1)
df$dlnBrent_pos_L2 <- dplyr::lag(df$dlnBrent_pos, 2)
df$dlnBrent_pos_L3 <- dplyr::lag(df$dlnBrent_pos, 3)
df$dlnBrent_neg_L0 <- df$dlnBrent_neg
df$dlnBrent_neg_L1 <- dplyr::lag(df$dlnBrent_neg, 1)
df$dlnBrent_neg_L2 <- dplyr::lag(df$dlnBrent_neg, 2)
df$dlnBrent_neg_L3 <- dplyr::lag(df$dlnBrent_neg, 3)

cat("  ✓ All lags created (CPI up to L4, oil shocks up to L3)\n")

# Save processed dataset
write.csv(df, "data/processed/analysis_dataset.csv", row.names = FALSE)
cat("  ✓ File saved: data/processed/analysis_dataset.csv\n")
cat(sprintf("  ✓ Final usable N (after lags, no NA): %d\n",
            sum(complete.cases(df[, c("dlnCPI", "dlnCPI_L1", "dlnOil_pos_L3", "dlnOil_neg_L3", "dlnIIP")]))))

}, error = function(e) cat(sprintf("  ✗ SECTION 2 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 3: DESCRIPTIVE STATISTICS + PLOTS
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 3: DESCRIPTIVE STATISTICS + PLOTS\n")
cat("══════════════════════════════════════════════════\n")

# Table 3.1 — Descriptive statistics
desc_vars <- c("cpi", "brent_usd", "exr", "iip", "oil_inr",
               "dlnCPI", "dlnOil", "dlnIIP", "dlnOil_pos", "dlnOil_neg")
desc_labels <- c("CPI Index", "Brent USD", "INR/USD", "IIP Index", "Oil INR",
                 "ΔlnCPI (%)", "ΔlnOil (%)", "ΔlnIIP (%)", "ΔOil+ (%)", "ΔOil- (%)")

desc_stats <- data.frame(
  Variable = desc_labels,
  N    = sapply(desc_vars, function(v) sum(!is.na(df[[v]]))),
  Mean = sapply(desc_vars, function(v) round(mean(df[[v]], na.rm = TRUE), 4)),
  SD   = sapply(desc_vars, function(v) round(sd(df[[v]], na.rm = TRUE), 4)),
  Min  = sapply(desc_vars, function(v) round(min(df[[v]], na.rm = TRUE), 4)),
  Max  = sapply(desc_vars, function(v) round(max(df[[v]], na.rm = TRUE), 4)),
  row.names = NULL
)
write.csv(desc_stats, "outputs/tables/table_3_1_descriptive_stats.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_3_1_descriptive_stats.csv\n")
print(desc_stats)

# Table 3.2 — Variable definitions
var_defs <- data.frame(
  Variable = c("CPI", "Brent", "EXR", "IIP", "Oil_INR", "ΔlnCPI", "ΔlnOil",
               "ΔlnIIP", "ΔOil+", "ΔOil-", "D_petrol", "D_diesel", "D_covid"),
  Source = c("OECD/FRED", "IMF/FRED", "Fed/FRED", "RBI DBIE", "Constructed",
             "Transformed", "Transformed", "Transformed", "Decomposed", "Decomposed",
             "Policy", "Policy", "Policy"),
  Transformation = c("Level", "Level", "Level", "Chain-linked", "Brent×EXR",
                      "100×Δln", "100×Δln", "100×Δln", "max(ΔlnOil,0)", "min(ΔlnOil,0)",
                      "=1 from Jun 2010", "=1 from Oct 2014", "=1 for Apr 2020"),
  Role = c("Dependent", "Regressor input", "Regressor input", "Control",
            "Main regressor", "Dependent (y)", "Regressor", "Control",
            "Positive shock", "Negative shock", "Dummy", "Dummy", "Dummy"),
  stringsAsFactors = FALSE
)
write.csv(var_defs, "outputs/tables/table_3_2_variable_definitions.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_3_2_variable_definitions.csv\n")

# Figure 1 — Raw series (4 panels)
p1a <- ggplot(df, aes(date, cpi)) + geom_line(color = "#1F3864", linewidth = 0.5) +
  labs(title = "CPI Index (2015=100)", x = NULL, y = "Index") + theme_minimal()
p1b <- ggplot(df, aes(date, brent_usd)) + geom_line(color = "#C55A11", linewidth = 0.5) +
  labs(title = "Brent Crude (USD/barrel)", x = NULL, y = "USD") + theme_minimal()
p1c <- ggplot(df, aes(date, exr)) + geom_line(color = "#548235", linewidth = 0.5) +
  labs(title = "INR/USD Exchange Rate", x = NULL, y = "INR per USD") + theme_minimal()
p1d <- ggplot(df, aes(date, iip)) + geom_line(color = "#7030A0", linewidth = 0.5) +
  labs(title = "IIP General Index (chained)", x = NULL, y = "Index") + theme_minimal()
fig1 <- (p1a | p1b) / (p1c | p1d) + plot_annotation(
  title = "Figure 1: Raw Data Series (Apr 2004 – Dec 2024)")
ggsave("outputs/figures/fig_1_raw_series.png", fig1, width = 10, height = 6, dpi = 300)
cat("  ✓ Figure saved: outputs/figures/fig_1_raw_series.png\n")

# Figure 2 — Log-differenced series (3 panels)
df_plot <- df %>% filter(!is.na(dlnCPI))
p2a <- ggplot(df_plot, aes(date, dlnCPI)) + geom_line(color = "#1F3864", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  labs(title = "ΔlnCPI (monthly % change)", x = NULL, y = "%") + theme_minimal()
p2b <- ggplot(df_plot, aes(date, dlnOil)) + geom_line(color = "#C55A11", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  labs(title = "ΔlnOil_INR (monthly % change)", x = NULL, y = "%") + theme_minimal()
p2c <- ggplot(df_plot, aes(date, dlnIIP)) + geom_line(color = "#7030A0", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  labs(title = "ΔlnIIP (monthly % change)", x = NULL, y = "%") + theme_minimal()
fig2 <- p2a / p2b / p2c + plot_annotation(
  title = "Figure 2: Log-Differenced Series (Monthly % Changes)")
ggsave("outputs/figures/fig_2_log_diff_series.png", fig2, width = 10, height = 8, dpi = 300)
cat("  ✓ Figure saved: outputs/figures/fig_2_log_diff_series.png\n")

# Figure 3 — Oil decomposition (partial sums)
df_plot$cum_pos <- cumsum(ifelse(is.na(df_plot$dlnOil_pos), 0, df_plot$dlnOil_pos))
df_plot$cum_neg <- cumsum(ifelse(is.na(df_plot$dlnOil_neg), 0, df_plot$dlnOil_neg))
fig3 <- ggplot(df_plot) +
  geom_line(aes(date, cum_pos, color = "Positive (ΔOil+)"), linewidth = 0.6) +
  geom_line(aes(date, cum_neg, color = "Negative (ΔOil−)"), linewidth = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  scale_color_manual(values = c("Positive (ΔOil+)" = "#C0392B", "Negative (ΔOil−)" = "#2980B9")) +
  labs(title = "Figure 3: Cumulative Partial Sums of Oil Price Changes",
       x = "Date", y = "Cumulative % change", color = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave("outputs/figures/fig_3_oil_decomposition.png", fig3, width = 8, height = 5, dpi = 300)
cat("  ✓ Figure saved: outputs/figures/fig_3_oil_decomposition.png\n")

}, error = function(e) cat(sprintf("  ✗ SECTION 3 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 4: UNIT ROOT TESTS (ADF)
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 4: ADF UNIT ROOT TESTS\n")
cat("══════════════════════════════════════════════════\n")

run_adf <- function(x, name) {
  x_clean <- na.omit(x)
  test <- adf.test(x_clean, alternative = "stationary")
  data.frame(
    Variable = name,
    ADF_Statistic = round(test$statistic, 4),
    P_Value = round(test$p.value, 4),
    Lags_Used = test$parameter,
    Conclusion = ifelse(test$p.value < 0.05, "Stationary I(0)", "Non-stationary I(1)"),
    stringsAsFactors = FALSE
  )
}

adf_results <- bind_rows(
  run_adf(df$ln_cpi, "ln(CPI)"),
  run_adf(df$ln_oil, "ln(Oil_INR)"),
  run_adf(df$ln_iip, "ln(IIP)"),
  run_adf(df$dlnCPI, "ΔlnCPI"),
  run_adf(df$dlnOil, "ΔlnOil"),
  run_adf(df$dlnIIP, "ΔlnIIP")
)

write.csv(adf_results, "outputs/tables/table_4_1_adf_results.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_4_1_adf_results.csv\n\n")
cat("  ADF Results:\n")
for (i in 1:nrow(adf_results)) {
  r <- adf_results[i, ]
  cat(sprintf("    %-12s stat = %7.4f, p = %.4f  → %s\n",
              r$Variable, r$ADF_Statistic, r$P_Value, r$Conclusion))
}

}, error = function(e) cat(sprintf("  ✗ SECTION 4 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 5: BASELINE SYMMETRIC ADL(1,1)
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 5: BASELINE SYMMETRIC ADL(1,1)\n")
cat("══════════════════════════════════════════════════\n")

dummy_terms <- paste0("M", 1:11, collapse = " + ")
sym_formula <- as.formula(paste0(
  "dlnCPI ~ dlnCPI_L1 + dlnOil + dlnOil_L1 + dlnIIP + D_petrol + D_diesel + D_covid + ",
  dummy_terms
))

df_est <- df %>% filter(complete.cases(dlnCPI, dlnCPI_L1, dlnOil_L1, dlnIIP))
sym_model <- lm(sym_formula, data = df_est)

# Newey-West SEs
nw_vcov_sym <- NeweyWest(sym_model, lag = floor(0.75 * nrow(df_est)^(1/3)), prewhite = FALSE)
sym_coeftest <- coeftest(sym_model, vcov. = nw_vcov_sym)

beta0 <- coef(sym_model)["dlnOil"]
beta1 <- coef(sym_model)["dlnOil_L1"]
cpt_sym <- beta0 + beta1

cat(sprintf("\n  β₀ (dlnOil)   = %.6f\n", beta0))
cat(sprintf("  β₁ (dlnOil_L1)= %.6f\n", beta1))
cat(sprintf("  Symmetric cumulative pass-through (β₀ + β₁) = %.6f\n", cpt_sym))
cat(sprintf("  Effect of 10%% oil shock on monthly CPI = %.4f pp\n", cpt_sym * 10))
cat(sprintf("  Adj R² = %.4f\n", summary(sym_model)$adj.r.squared))
cat(sprintf("  N = %d\n", nrow(df_est)))

# Save table
sym_out <- data.frame(
  Variable = rownames(sym_coeftest),
  Estimate = round(sym_coeftest[, 1], 6),
  NW_SE = round(sym_coeftest[, 2], 6),
  t_value = round(sym_coeftest[, 3], 4),
  p_value = round(sym_coeftest[, 4], 4),
  Significance = ifelse(sym_coeftest[, 4] < 0.01, "***",
                   ifelse(sym_coeftest[, 4] < 0.05, "**",
                     ifelse(sym_coeftest[, 4] < 0.10, "*", ""))),
  row.names = NULL
)
# Add summary row
sym_summary <- data.frame(Variable = c("---", "CPT (β₀+β₁)", "Adj R²", "N"),
                          Estimate = c(NA, round(cpt_sym, 6),
                                       round(summary(sym_model)$adj.r.squared, 4), nrow(df_est)),
                          NW_SE = NA, t_value = NA, p_value = NA, Significance = "",
                          stringsAsFactors = FALSE)
sym_out <- bind_rows(sym_out, sym_summary)
write.csv(sym_out, "outputs/tables/table_4_2_baseline_adl.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_4_2_baseline_adl.csv\n")

}, error = function(e) cat(sprintf("  ✗ SECTION 5 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 6: PRIMARY ASYMMETRIC ADL(p,3) — MAIN MODEL
#  AIC-based selection of p (AR lags) from {1, 2, 3, 4}
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 6: PRIMARY ASYMMETRIC ADL(p,3) — MAIN MODEL\n")
cat("══════════════════════════════════════════════════\n")

# --- AIC-based AR lag selection ---
cat("\n  Selecting optimal p (AR lags) by AIC...\n")
# Use a common estimation sample (largest lag = L4) so AIC is comparable
df_aic <- df %>% filter(complete.cases(dlnCPI, dlnCPI_L1, dlnCPI_L2, dlnCPI_L3, dlnCPI_L4,
                  dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

aic_values <- c()
for (p_try in 1:4) {
  ar_terms <- paste0("dlnCPI_L", 1:p_try, collapse = " + ")
  f_try <- as.formula(paste0(
    "dlnCPI ~ ", ar_terms, " + ",
    "dlnOil_pos_L0 + dlnOil_pos_L1 + dlnOil_pos_L2 + dlnOil_pos_L3 + ",
    "dlnOil_neg_L0 + dlnOil_neg_L1 + dlnOil_neg_L2 + dlnOil_neg_L3 + ",
    "dlnIIP + D_petrol + D_diesel + D_covid + ",
    paste0("M", 1:11, collapse = " + ")
  ))
  mod_try <- lm(f_try, data = df_aic)
  aic_val <- AIC(mod_try)
  aic_values <- c(aic_values, aic_val)
  cat(sprintf("    p=%d: AIC=%.2f\n", p_try, aic_val))
}

best_p <- which.min(aic_values)
cat(sprintf("  → Selected p = %d (lowest AIC = %.2f)\n", best_p, aic_values[best_p]))

# --- Estimate primary model with optimal p ---
ar_terms_best <- paste0("dlnCPI_L", 1:best_p, collapse = " + ")
asym_formula <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms_best, " + ",
  "dlnOil_pos_L0 + dlnOil_pos_L1 + dlnOil_pos_L2 + dlnOil_pos_L3 + ",
  "dlnOil_neg_L0 + dlnOil_neg_L1 + dlnOil_neg_L2 + dlnOil_neg_L3 + ",
  "dlnIIP + D_petrol + D_diesel + D_covid + ",
  paste0("M", 1:11, collapse = " + ")
))

# Use the common sample for estimation (ensures enough lags available)
df_asym <- df_aic
asym_model <- lm(asym_formula, data = df_asym)

nw_vcov_asym <- NeweyWest(asym_model, lag = floor(0.75 * nrow(df_asym)^(1/3)), prewhite = FALSE)
asym_coeftest <- coeftest(asym_model, vcov. = nw_vcov_asym)

# Cumulative pass-through
cpt_pos <- sum(coef(asym_model)[grep("dlnOil_pos", names(coef(asym_model)))])
cpt_neg <- sum(coef(asym_model)[grep("dlnOil_neg", names(coef(asym_model)))])

cat(sprintf("\n  === MAIN ASYMMETRY RESULT (ADL(%d,3)) ===\n", best_p))
cat(sprintf("  CPT+ (cumulative positive pass-through) = %.6f\n", cpt_pos))
cat(sprintf("  CPT- (cumulative negative pass-through) = %.6f\n", cpt_neg))
cat(sprintf("  Asymmetry gap (CPT+ - |CPT-|)           = %.6f\n", cpt_pos - abs(cpt_neg)))
cat(sprintf("  Effect of +10%% oil shock: %.4f pp\n", cpt_pos * 10))
cat(sprintf("  Effect of -10%% oil shock: %.4f pp\n", cpt_neg * 10))
cat(sprintf("  Adj R-squared: %.4f\n", summary(asym_model)$adj.r.squared))
cat(sprintf("  N observations: %d\n", nrow(df_asym)))

# Save table
asym_out <- data.frame(
  Variable = rownames(asym_coeftest),
  Estimate = round(asym_coeftest[, 1], 6),
  NW_SE = round(asym_coeftest[, 2], 6),
  t_value = round(asym_coeftest[, 3], 4),
  p_value = round(asym_coeftest[, 4], 4),
  Significance = ifelse(asym_coeftest[, 4] < 0.01, "***",
                   ifelse(asym_coeftest[, 4] < 0.05, "**",
                     ifelse(asym_coeftest[, 4] < 0.10, "*", ""))),
  row.names = NULL
)
asym_summary <- data.frame(
  Variable = c("---", "AR lags (p)", "CPT+", "CPT-", "Asymmetry Gap", "Adj R²", "N"),
  Estimate = c(NA, best_p, round(cpt_pos, 6), round(cpt_neg, 6),
               round(cpt_pos - abs(cpt_neg), 6),
               round(summary(asym_model)$adj.r.squared, 4), nrow(df_asym)),
  NW_SE = NA, t_value = NA, p_value = NA, Significance = "",
  stringsAsFactors = FALSE
)
asym_out <- bind_rows(asym_out, asym_summary)
write.csv(asym_out, "outputs/tables/table_4_3_asymmetric_adl.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_4_3_asymmetric_adl.csv\n")

# Figure 4 — Cumulative pass-through by horizon
horizons <- 0:3
cpt_pos_cum <- cumsum(coef(asym_model)[paste0("dlnOil_pos_L", horizons)])
cpt_neg_cum <- cumsum(coef(asym_model)[paste0("dlnOil_neg_L", horizons)])
cpt_df <- data.frame(
  Horizon = rep(horizons, 2),
  CPT = c(cpt_pos_cum, cpt_neg_cum),
  Type = rep(c("CPT+ (Positive shocks)", "CPT- (Negative shocks)"), each = 4)
)
fig4 <- ggplot(cpt_df, aes(x = Horizon, y = CPT, color = Type)) +
  geom_line(linewidth = 1.2) + geom_point(size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  scale_color_manual(values = c("CPT+ (Positive shocks)" = "#C0392B",
                                "CPT- (Negative shocks)" = "#2980B9")) +
  scale_x_continuous(breaks = 0:3) +
  labs(title = sprintf("Figure 4: Cumulative Pass-Through by Horizon (ADL(%d,3))", best_p),
       subtitle = "Asymmetric ADL — Full Sample",
       x = "Lag Horizon (months)", y = "Cumulative coefficient", color = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave("outputs/figures/fig_4_cumulative_passthrough.png", fig4, width = 8, height = 5, dpi = 300)
cat("  ✓ Figure saved: outputs/figures/fig_4_cumulative_passthrough.png\n")

}, error = function(e) cat(sprintf("  ✗ SECTION 6 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 7: WALD TEST FOR ASYMMETRY
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 7: WALD TEST FOR ASYMMETRY\n")
cat("══════════════════════════════════════════════════\n")

# H0: sum(pi+) = sum(pi-)
# Build the linear hypothesis string
pos_coefs <- paste0("dlnOil_pos_L", 0:3)
neg_coefs <- paste0("dlnOil_neg_L", 0:3)
hyp_string <- paste0(
  paste(pos_coefs, collapse = " + "), " = ",
  paste(neg_coefs, collapse = " + ")
)

wald_result <- linearHypothesis(asym_model, hyp_string, vcov. = nw_vcov_asym)
wald_f <- wald_result$F[2]
wald_p <- wald_result$`Pr(>F)`[2]
wald_decision <- ifelse(wald_p < 0.05, "Reject H₀ at 5%", "Fail to reject H₀ at 5%")

cat(sprintf("\n  Wald Test: H₀: CPT+ = CPT-\n"))
cat(sprintf("    F-statistic = %.4f\n", wald_f))
cat(sprintf("    p-value     = %.4f\n", wald_p))
cat(sprintf("    Decision    = %s\n", wald_decision))

wald_out <- data.frame(
  Test = "Wald: CPT+ = CPT-",
  F_Statistic = round(wald_f, 4),
  DF1 = wald_result$Df[2],
  DF2 = wald_result$Res.Df[2],
  P_Value = round(wald_p, 4),
  Decision = wald_decision,
  CPT_Plus = round(cpt_pos, 6),
  CPT_Minus = round(cpt_neg, 6),
  stringsAsFactors = FALSE
)
write.csv(wald_out, "outputs/tables/table_4_4_wald_test.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_4_4_wald_test.csv\n")

}, error = function(e) cat(sprintf("  ✗ SECTION 7 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 8: SUB-SAMPLE ANALYSIS (PRE/POST OCT 2014)
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 8: SUB-SAMPLE ANALYSIS (PRE/POST 2014)\n")
cat("══════════════════════════════════════════════════\n")

deregulation_date <- as.Date("2014-10-01")

# Helper to estimate subsample — uses same optimal p as main model
estimate_subsample <- function(data_sub, label) {
  # Build AR terms matching the main model's best_p
  ar_terms_sub <- paste0("dlnCPI_L", 1:best_p, collapse = " + ")
  # Include all potentially relevant dummies
  sub_formula <- as.formula(paste0(
    "dlnCPI ~ ", ar_terms_sub, " + ",
    "dlnOil_pos_L0 + dlnOil_pos_L1 + dlnOil_pos_L2 + dlnOil_pos_L3 + ",
    "dlnOil_neg_L0 + dlnOil_neg_L1 + dlnOil_neg_L2 + dlnOil_neg_L3 + ",
    "dlnIIP + D_petrol + D_diesel + D_covid + ",
    paste0("M", 1:11, collapse = " + ")
  ))
  # Determine which lag column to check based on best_p
  lag_col <- paste0("dlnCPI_L", best_p)
  sub_est <- data_sub %>% filter(complete.cases(dlnCPI, !!sym(lag_col),
                    dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
  # Remove dummies that are constant (all 0 or all 1) in the subsample
  if (length(unique(sub_est$D_covid)) == 1) {
    sub_formula <- update(sub_formula, . ~ . - D_covid)
  }
  if (length(unique(sub_est$D_petrol)) == 1) {
    sub_formula <- update(sub_formula, . ~ . - D_petrol)
  }
  if (length(unique(sub_est$D_diesel)) == 1) {
    sub_formula <- update(sub_formula, . ~ . - D_diesel)
  }
  mod <- lm(sub_formula, data = sub_est)
  nw_vcov <- NeweyWest(mod, lag = floor(0.75 * nrow(sub_est)^(1/3)), prewhite = FALSE)
  ct <- coeftest(mod, vcov. = nw_vcov)

  cpt_p <- sum(coef(mod)[grep("dlnOil_pos", names(coef(mod)))])
  cpt_n <- sum(coef(mod)[grep("dlnOil_neg", names(coef(mod)))])

  cat(sprintf("  %s: N=%d, CPT+=%.6f, CPT-=%.6f, Gap=%.6f, Adj R²=%.4f\n",
              label, nrow(sub_est), cpt_p, cpt_n, cpt_p - abs(cpt_n),
              summary(mod)$adj.r.squared))

  data.frame(Period = label, N = nrow(sub_est),
             CPT_Plus = round(cpt_p, 6), CPT_Minus = round(cpt_n, 6),
             Gap = round(cpt_p - abs(cpt_n), 6),
             Adj_R2 = round(summary(mod)$adj.r.squared, 4),
             stringsAsFactors = FALSE)
}

pre  <- df %>% filter(date < deregulation_date)
post <- df %>% filter(date >= deregulation_date)

cat("\n  Sub-Sample Comparison:\n")
sub_pre  <- estimate_subsample(pre, "Pre-2014 (Apr 2004 – Sep 2014)")
sub_post <- estimate_subsample(post, "Post-2014 (Oct 2014 – Dec 2024)")

subsample_out <- bind_rows(sub_pre, sub_post)
write.csv(subsample_out, "outputs/tables/table_4_5_subsample.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_4_5_subsample.csv\n")

# Figure 5 — Sub-sample comparison bar chart
fig5_data <- data.frame(
  Period = rep(c("Pre-2014", "Post-2014"), each = 2),
  Type = rep(c("CPT+", "|CPT-|"), 2),
  Value = c(sub_pre$CPT_Plus, abs(sub_pre$CPT_Minus),
            sub_post$CPT_Plus, abs(sub_post$CPT_Minus))
)
fig5 <- ggplot(fig5_data, aes(x = Period, y = Value, fill = Type)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = c("CPT+" = "#C0392B", "|CPT-|" = "#2980B9")) +
  labs(title = "Figure 5: Sub-Sample Asymmetry Comparison",
       subtitle = "Pre- vs Post-Diesel Deregulation (Oct 2014)",
       x = NULL, y = "Cumulative Pass-Through", fill = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave("outputs/figures/fig_5_subsample_comparison.png", fig5, width = 8, height = 5, dpi = 300)
cat("  ✓ Figure saved: outputs/figures/fig_5_subsample_comparison.png\n")

}, error = function(e) cat(sprintf("  ✗ SECTION 8 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 9: DIAGNOSTIC TESTS
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 9: DIAGNOSTIC TESTS\n")
cat("══════════════════════════════════════════════════\n")

# Breusch-Godfrey LM test (12 lags)
bg_test <- bgtest(asym_model, order = 12)
bg_pass <- ifelse(bg_test$p.value > 0.05, "PASS", "FAIL")

# Breusch-Pagan test
bp_test <- bptest(asym_model)
bp_pass <- ifelse(bp_test$p.value > 0.05, "PASS", "FAIL")

# Ramsey RESET test
reset_test <- resettest(asym_model, power = 2:3, type = "fitted")
reset_pass <- ifelse(reset_test$p.value > 0.05, "PASS", "FAIL")

cat("\n  Diagnostic Results:\n")
cat(sprintf("    Breusch-Godfrey (12): stat=%.4f, p=%.4f → %s\n",
            bg_test$statistic, bg_test$p.value, bg_pass))
cat(sprintf("    Breusch-Pagan:        stat=%.4f, p=%.4f → %s\n",
            bp_test$statistic, bp_test$p.value, bp_pass))
cat(sprintf("    Ramsey RESET:         stat=%.4f, p=%.4f → %s\n",
            reset_test$statistic, reset_test$p.value, reset_pass))

# CUSUM test
cusum_test <- efp(asym_formula, data = df_asym, type = "Rec-CUSUM")
cusum_cross <- sctest(cusum_test)
cusum_pass <- ifelse(cusum_cross$p.value > 0.05, "PASS (within bounds)", "FAIL (crossed)")
cat(sprintf("    CUSUM:                stat=%.4f, p=%.4f → %s\n",
            cusum_cross$statistic, cusum_cross$p.value, cusum_pass))

# Save diagnostics table
diag_out <- data.frame(
  Test = c("Breusch-Godfrey LM (12)", "Breusch-Pagan", "Ramsey RESET", "CUSUM"),
  Statistic = c(round(bg_test$statistic, 4), round(bp_test$statistic, 4),
                round(reset_test$statistic, 4), round(cusum_cross$statistic, 4)),
  P_Value = c(round(bg_test$p.value, 4), round(bp_test$p.value, 4),
              round(reset_test$p.value, 4), round(cusum_cross$p.value, 4)),
  Result = c(bg_pass, bp_pass, reset_pass, cusum_pass),
  stringsAsFactors = FALSE
)
write.csv(diag_out, "outputs/tables/table_4_6_diagnostics.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_4_6_diagnostics.csv\n")

# Figure 6 — CUSUM stability plot
png("outputs/figures/fig_6_cusum_stability.png", width = 8, height = 5, units = "in", res = 300)
plot(cusum_test, main = "Figure 6: CUSUM Recursive Stability Test",
     xlab = "Observation", ylab = "CUSUM statistic")
dev.off()
cat("  ✓ Figure saved: outputs/figures/fig_6_cusum_stability.png\n")

# Figure 8 — Residual diagnostics (4-panel)
resids <- residuals(asym_model)
fitted_vals <- fitted(asym_model)
resid_df <- data.frame(
  Date = df_asym$date,
  Residual = resids,
  Fitted = fitted_vals,
  Actual = df_asym$dlnCPI
)
p8a <- ggplot(resid_df, aes(Date, Residual)) + geom_line(color = "#1F3864", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Residuals over Time", x = NULL, y = "Residual") + theme_minimal()
p8b <- ggplot(resid_df, aes(Residual)) +
  geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "#1F3864", alpha = 0.7) +
  stat_function(fun = dnorm, args = list(mean = mean(resids), sd = sd(resids)),
                color = "red", linewidth = 1) +
  labs(title = "Residual Histogram", x = "Residual", y = "Density") + theme_minimal()
p8c <- ggplot(resid_df, aes(sample = Residual)) + stat_qq(color = "#1F3864") + stat_qq_line(color = "red") +
  labs(title = "Q-Q Plot", x = "Theoretical Quantiles", y = "Sample Quantiles") + theme_minimal()
p8d <- ggplot(resid_df, aes(Fitted, Actual)) + geom_point(color = "#1F3864", alpha = 0.5, size = 1) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  labs(title = "Actual vs Fitted", x = "Fitted", y = "Actual") + theme_minimal()
fig8 <- (p8a | p8b) / (p8c | p8d) + plot_annotation(
  title = "Figure 8: Residual Diagnostic Plots")
ggsave("outputs/figures/fig_8_residual_diagnostics.png", fig8, width = 10, height = 7, dpi = 300)
cat("  ✓ Figure saved: outputs/figures/fig_8_residual_diagnostics.png\n")

}, error = function(e) cat(sprintf("  ✗ SECTION 9 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 10: ROBUSTNESS CHECKS (5 CHECKS)
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 10: ROBUSTNESS CHECKS\n")
cat("══════════════════════════════════════════════════\n")

# --- Check 1: Lag sensitivity (q = 0, 1, 2, 3) with optimal p AR lags ---
cat("\n  --- Check 1: Lag Sensitivity ---\n")
lag_results <- list()
for (q in 0:3) {
  pos_terms <- paste0("dlnOil_pos_L", 0:q, collapse = " + ")
  neg_terms <- paste0("dlnOil_neg_L", 0:q, collapse = " + ")
  f_str <- paste0("dlnCPI ~ ", ar_terms_best, " + ", pos_terms, " + ", neg_terms,
                  " + dlnIIP + D_petrol + D_diesel + D_covid + ",
                  paste0("M", 1:11, collapse = " + "))
  f <- as.formula(f_str)
  # Use common sample (need L4 for CPI, Lq for oil)
  lag_col <- paste0("dlnOil_pos_L", q)
  df_q <- df_aic %>% filter(complete.cases(!!sym(lag_col)))
  mod_q <- lm(f, data = df_q)
  aic_q <- AIC(mod_q)
  cp <- sum(coef(mod_q)[grep("dlnOil_pos", names(coef(mod_q)))])
  cn <- sum(coef(mod_q)[grep("dlnOil_neg", names(coef(mod_q)))])
  lag_results[[q + 1]] <- data.frame(
    q = q, AIC = round(aic_q, 2), N = nrow(df_q),
    CPT_Plus = round(cp, 6), CPT_Minus = round(cn, 6),
    Gap = round(cp - abs(cn), 6), stringsAsFactors = FALSE
  )
  consistent <- ifelse(cp > abs(cn), "Consistent", "Inconsistent")
  cat(sprintf("    q=%d: AIC=%.2f, CPT+=%.6f, CPT-=%.6f, Gap=%.6f → %s\n",
              q, aic_q, cp, cn, cp - abs(cn), consistent))
}
lag_sensitivity <- bind_rows(lag_results)
write.csv(lag_sensitivity, "outputs/tables/table_5_1_lag_sensitivity.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_5_1_lag_sensitivity.csv\n")

# --- Check 2: USD-only Brent ---
cat("\n  --- Check 2: USD-Only Brent ---\n")
usd_formula <- as.formula(paste0(
  "dlnCPI ~ dlnCPI_L1 + ",
  "dlnBrent_pos_L0 + dlnBrent_pos_L1 + dlnBrent_pos_L2 + dlnBrent_pos_L3 + ",
  "dlnBrent_neg_L0 + dlnBrent_neg_L1 + dlnBrent_neg_L2 + dlnBrent_neg_L3 + ",
  "dlnIIP + D_petrol + D_diesel + D_covid + ",
  paste0("M", 1:11, collapse = " + ")
))
df_usd <- df %>% filter(complete.cases(dlnCPI, dlnCPI_L1, dlnBrent_pos_L3, dlnBrent_neg_L3, dlnIIP))
usd_model <- lm(usd_formula, data = df_usd)
cpt_usd_pos <- sum(coef(usd_model)[grep("dlnBrent_pos", names(coef(usd_model)))])
cpt_usd_neg <- sum(coef(usd_model)[grep("dlnBrent_neg", names(coef(usd_model)))])
cat(sprintf("    USD-only: CPT+=%.6f, CPT-=%.6f, Gap=%.6f → %s\n",
            cpt_usd_pos, cpt_usd_neg, cpt_usd_pos - abs(cpt_usd_neg),
            ifelse(cpt_usd_pos > abs(cpt_usd_neg), "Consistent", "Inconsistent")))
usd_out <- data.frame(
  Specification = c("Primary (INR)", "USD-only"),
  CPT_Plus = c(round(cpt_pos, 6), round(cpt_usd_pos, 6)),
  CPT_Minus = c(round(cpt_neg, 6), round(cpt_usd_neg, 6)),
  Gap = c(round(cpt_pos - abs(cpt_neg), 6), round(cpt_usd_pos - abs(cpt_usd_neg), 6)),
  stringsAsFactors = FALSE
)
write.csv(usd_out, "outputs/tables/table_5_2_usd_specification.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_5_2_usd_specification.csv\n")

# --- Check 3: COVID sensitivity ---
cat("\n  --- Check 3: COVID Sensitivity ---\n")
nocovid_formula <- update(asym_formula, . ~ . - D_covid)
nocovid_model <- lm(nocovid_formula, data = df_asym)
cpt_nc_pos <- sum(coef(nocovid_model)[grep("dlnOil_pos", names(coef(nocovid_model)))])
cpt_nc_neg <- sum(coef(nocovid_model)[grep("dlnOil_neg", names(coef(nocovid_model)))])
cat(sprintf("    Without COVID: CPT+=%.6f, CPT-=%.6f, Gap=%.6f → %s\n",
            cpt_nc_pos, cpt_nc_neg, cpt_nc_pos - abs(cpt_nc_neg),
            ifelse(cpt_nc_pos > abs(cpt_nc_neg), "Consistent", "Inconsistent")))
covid_out <- data.frame(
  Specification = c("With COVID dummy", "Without COVID dummy"),
  CPT_Plus = c(round(cpt_pos, 6), round(cpt_nc_pos, 6)),
  CPT_Minus = c(round(cpt_neg, 6), round(cpt_nc_neg, 6)),
  Gap = c(round(cpt_pos - abs(cpt_neg), 6), round(cpt_nc_pos - abs(cpt_nc_neg), 6)),
  stringsAsFactors = FALSE
)
write.csv(covid_out, "outputs/tables/table_5_3_covid_sensitivity.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_5_3_covid_sensitivity.csv\n")

# --- Check 4: Winsorized ---
cat("\n  --- Check 4: Winsorized (top/bottom 1%) ---\n")
winsorize_vec <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs = probs, na.rm = TRUE)
  x[x < q[1]] <- q[1]
  x[x > q[2]] <- q[2]
  x
}
df_win <- df
df_win$dlnOil_pos_L0 <- winsorize_vec(df_win$dlnOil_pos)
df_win$dlnOil_neg_L0 <- winsorize_vec(df_win$dlnOil_neg)
# Recreate lags on winsorized data
df_win$dlnOil_pos_L1 <- dplyr::lag(df_win$dlnOil_pos_L0, 1)
df_win$dlnOil_pos_L2 <- dplyr::lag(df_win$dlnOil_pos_L0, 2)
df_win$dlnOil_pos_L3 <- dplyr::lag(df_win$dlnOil_pos_L0, 3)
df_win$dlnOil_neg_L1 <- dplyr::lag(df_win$dlnOil_neg_L0, 1)
df_win$dlnOil_neg_L2 <- dplyr::lag(df_win$dlnOil_neg_L0, 2)
df_win$dlnOil_neg_L3 <- dplyr::lag(df_win$dlnOil_neg_L0, 3)
df_win_est <- df_win %>% filter(complete.cases(dlnCPI, dlnCPI_L1, dlnCPI_L2, dlnCPI_L3, dlnCPI_L4,
                 dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
win_model <- lm(asym_formula, data = df_win_est)
cpt_w_pos <- sum(coef(win_model)[grep("dlnOil_pos", names(coef(win_model)))])
cpt_w_neg <- sum(coef(win_model)[grep("dlnOil_neg", names(coef(win_model)))])
cat(sprintf("    Winsorized: CPT+=%.6f, CPT-=%.6f, Gap=%.6f → %s\n",
            cpt_w_pos, cpt_w_neg, cpt_w_pos - abs(cpt_w_neg),
            ifelse(cpt_w_pos > abs(cpt_w_neg), "Consistent", "Inconsistent")))
win_out <- data.frame(
  Specification = c("Original", "Winsorized (1%)"),
  CPT_Plus = c(round(cpt_pos, 6), round(cpt_w_pos, 6)),
  CPT_Minus = c(round(cpt_neg, 6), round(cpt_w_neg, 6)),
  Gap = c(round(cpt_pos - abs(cpt_neg), 6), round(cpt_w_pos - abs(cpt_w_neg), 6)),
  stringsAsFactors = FALSE
)
write.csv(win_out, "outputs/tables/table_5_4_winsorized.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_5_4_winsorized.csv\n")

# --- Check 5: Rolling window (60 months) ---
cat("\n  --- Check 5: Rolling Window (60-month) ---\n")
window_size <- 60
df_roll <- df %>% filter(complete.cases(dlnCPI, dlnCPI_L1, dlnCPI_L2, dlnCPI_L3, dlnCPI_L4,
               dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
n_roll <- nrow(df_roll)
roll_dates <- c()
roll_cpt_pos <- c()
roll_cpt_neg <- c()

if (n_roll >= window_size + 10) {
  for (i in 1:(n_roll - window_size + 1)) {
    sub <- df_roll[i:(i + window_size - 1), ]
    roll_formula <- as.formula(paste0(
      "dlnCPI ~ ", ar_terms_best, " + ",
      "dlnOil_pos_L0 + dlnOil_pos_L1 + dlnOil_pos_L2 + dlnOil_pos_L3 + ",
      "dlnOil_neg_L0 + dlnOil_neg_L1 + dlnOil_neg_L2 + dlnOil_neg_L3 + ",
      "dlnIIP + D_petrol + D_diesel + D_covid + ", paste0("M", 1:11, collapse = " + ")
    ))
    # Remove constant dummies in this window
    if (length(unique(sub$D_covid)) == 1)  roll_formula <- update(roll_formula, . ~ . - D_covid)
    if (length(unique(sub$D_petrol)) == 1) roll_formula <- update(roll_formula, . ~ . - D_petrol)
    if (length(unique(sub$D_diesel)) == 1) roll_formula <- update(roll_formula, . ~ . - D_diesel)
    tryCatch({
      mod_r <- lm(roll_formula, data = sub)
      cp <- sum(coef(mod_r)[grep("dlnOil_pos", names(coef(mod_r)))])
      cn <- sum(coef(mod_r)[grep("dlnOil_neg", names(coef(mod_r)))])
      roll_dates <- c(roll_dates, as.character(sub$date[window_size]))
      roll_cpt_pos <- c(roll_cpt_pos, cp)
      roll_cpt_neg <- c(roll_cpt_neg, cn)
    }, error = function(e) NULL)
  }

  roll_df <- data.frame(
    Date = as.Date(roll_dates),
    CPT_Plus = roll_cpt_pos,
    CPT_Minus = roll_cpt_neg
  )

  fig7 <- ggplot(roll_df) +
    geom_line(aes(Date, CPT_Plus, color = "CPT+"), linewidth = 0.7) +
    geom_line(aes(Date, CPT_Minus, color = "CPT-"), linewidth = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
    geom_vline(xintercept = as.Date("2014-10-01"), linetype = "dotted", color = "grey40") +
    annotate("text", x = as.Date("2014-10-01"), y = max(roll_cpt_pos, na.rm = TRUE) * 0.9,
             label = "Diesel\nDeregulation", hjust = -0.1, size = 3, color = "grey40") +
    scale_color_manual(values = c("CPT+" = "#C0392B", "CPT-" = "#2980B9")) +
    labs(title = "Figure 7: Rolling 60-Month CPT+ and CPT-",
         x = "End Date of Window", y = "Cumulative Pass-Through", color = NULL) +
    theme_minimal() + theme(legend.position = "bottom")
  ggsave("outputs/figures/fig_7_rolling_window.png", fig7, width = 8, height = 5, dpi = 300)
  cat("  ✓ Figure saved: outputs/figures/fig_7_rolling_window.png\n")
} else {
  cat("  ⚠ Not enough observations for 60-month rolling window\n")
}

}, error = function(e) cat(sprintf("  ✗ SECTION 10 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 11: REMAINING FIGURES
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP 11: REMAINING FIGURES\n")
cat("══════════════════════════════════════════════════\n")

# Figure 9 — Oil price regimes
regime_df <- data.frame(
  xmin = as.Date(c("2004-04-01", "2008-07-01", "2014-07-01", "2020-01-01", "2022-02-01")),
  xmax = as.Date(c("2008-06-01", "2009-02-01", "2016-01-01", "2020-12-01", "2022-12-01")),
  label = c("China Boom", "GFC Crash", "Shale Glut +\nDeregulation", "COVID", "Russia-\nUkraine"),
  fill = c("#E74C3C", "#3498DB", "#2ECC71", "#9B59B6", "#E67E22")
)
fig9 <- ggplot(df, aes(date, brent_usd)) +
  geom_rect(data = regime_df, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = label),
            inherit.aes = FALSE, alpha = 0.15) +
  geom_line(color = "#1F3864", linewidth = 0.6) +
  scale_fill_manual(values = setNames(regime_df$fill, regime_df$label)) +
  labs(title = "Figure 9: Brent Crude Oil Price with Regime Periods",
       x = "Date", y = "USD per barrel", fill = "Regime") +
  theme_minimal() + theme(legend.position = "bottom")
ggsave("outputs/figures/fig_9_oil_price_regimes.png", fig9, width = 10, height = 5, dpi = 300)
cat("  ✓ Figure saved: outputs/figures/fig_9_oil_price_regimes.png\n")

# Figure 10 — Asymmetry gap bar chart (full sample + sub-samples)
fig10_data <- data.frame(
  Sample = c("Full Sample", "Pre-2014", "Post-2014"),
  CPT_Plus = c(cpt_pos, sub_pre$CPT_Plus, sub_post$CPT_Plus),
  CPT_Minus_Abs = c(abs(cpt_neg), abs(sub_pre$CPT_Minus), abs(sub_post$CPT_Minus))
)
fig10_long <- fig10_data %>%
  pivot_longer(cols = c(CPT_Plus, CPT_Minus_Abs), names_to = "Type", values_to = "Value") %>%
  mutate(Type = ifelse(Type == "CPT_Plus", "CPT+", "|CPT-|"),
         Sample = factor(Sample, levels = c("Full Sample", "Pre-2014", "Post-2014")))
fig10 <- ggplot(fig10_long, aes(x = Sample, y = Value, fill = Type)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = c("CPT+" = "#C0392B", "|CPT-|" = "#2980B9")) +
  labs(title = "Figure 10: Asymmetry Gap — CPT+ vs |CPT-|",
       subtitle = "Full Sample and Sub-Sample Comparison",
       x = NULL, y = "Cumulative Pass-Through", fill = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave("outputs/figures/fig_10_asymmetry_gap.png", fig10, width = 8, height = 5, dpi = 300)
cat("  ✓ Figure saved: outputs/figures/fig_10_asymmetry_gap.png\n")

}, error = function(e) cat(sprintf("  ✗ SECTION 11 ERROR: %s\n", e$message)))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 12: FINAL SUMMARY LOG
# ══════════════════════════════════════════════════════════════════════════════
cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  ANALYSIS COMPLETE — FILES CREATED\n")
cat("══════════════════════════════════════════════════\n")

tables_list <- list.files("outputs/tables")
figures_list <- list.files("outputs/figures")

cat("  Tables (", length(tables_list), " files):\n")
for (f in tables_list) cat("    •", f, "\n")
cat("\n  Figures (", length(figures_list), " files):\n")
for (f in figures_list) cat("    •", f, "\n")

cat(sprintf("\n  Dataset: N = %d observations\n", nrow(df)))
cat(sprintf("  Sample:  %s to %s\n", min(df$date), max(df$date)))

cat("\n  === KEY RESULTS SUMMARY ===\n")
cat(sprintf("  CPT+ (full sample)  = %.6f  (10%% shock → %.4f pp)\n", cpt_pos, cpt_pos * 10))
cat(sprintf("  CPT- (full sample)  = %.6f  (10%% shock → %.4f pp)\n", cpt_neg, cpt_neg * 10))
cat(sprintf("  Asymmetry ratio     = %.1f×\n", ifelse(abs(cpt_neg) > 0, abs(cpt_pos / cpt_neg), Inf)))
cat(sprintf("  Wald test p-value   = %.4f\n", wald_p))
cat(sprintf("  Adj R² (main model) = %.4f\n", summary(asym_model)$adj.r.squared))
cat("══════════════════════════════════════════════════\n")
