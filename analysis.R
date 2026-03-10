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
  "car", "strucchange", "stargazer", "patchwork", "scales", "zoo",
  "jsonlite"
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

format_p_value <- function(p) {
  if (is.na(p)) {
    return(NA_character_)
  }
  if (p <= 0.01) {
    return("<0.01")
  }
  sprintf("%.4f", p)
}

sig_stars <- function(p) {
  ifelse(p < 0.01, "***",
         ifelse(p < 0.05, "**",
                ifelse(p < 0.10, "*", "")))
}

test_decision <- function(p, alpha = 0.05) {
  ifelse(p < alpha, "Statistically significant", "Not statistically significant")
}

nw_lag_length <- function(n) {
  floor(0.75 * n^(1/3))
}

sum_restriction <- function(term_names, rhs = "0") {
  paste(paste(term_names, collapse = " + "), "=", rhs)
}

extract_linear_test <- function(model, restriction, vcov_mat, label) {
  test <- linearHypothesis(model, restriction, vcov. = vcov_mat)
  data.frame(
    Test = label,
    F_Statistic = unname(test$F[2]),
    DF1 = unname(test$Df[2]),
    DF2 = unname(test$Res.Df[2]),
    P_Value = unname(test$`Pr(>F)`[2]),
    stringsAsFactors = FALSE
  )
}

fetch_mospi_cpi_group <- function(years, series, group_code,
                                  sector_code = 3, state_code = 99,
                                  base_year = "2012") {
  base_url <- "https://api.mospi.gov.in/api/cpi/getCPIIndex"
  page <- 1
  out <- list()

  repeat {
    query <- list(
      base_year = base_year,
      series = series,
      year = paste(years, collapse = ","),
      month_code = paste(1:12, collapse = ","),
      state_code = state_code,
      group_code = group_code,
      sector_code = sector_code,
      page = page,
      Format = "JSON"
    )

    url <- paste0(
      base_url, "?",
      paste(
        paste0(
          names(query), "=",
          vapply(query, function(x) utils::URLencode(as.character(x), reserved = TRUE), character(1))
        ),
        collapse = "&"
      )
    )

    raw_txt <- tryCatch(paste(readLines(url, warn = FALSE), collapse = ""), error = function(e) "")
    if (identical(raw_txt, "")) {
      break
    }

    payload <- tryCatch(jsonlite::fromJSON(raw_txt), error = function(e) NULL)
    if (is.null(payload) || !isTRUE(payload$statusCode) || is.null(payload$data) || nrow(payload$data) == 0) {
      break
    }

    out[[length(out) + 1]] <- as.data.frame(payload$data, stringsAsFactors = FALSE)

    total_pages <- tryCatch(as.integer(payload$meta_data$totalPages), error = function(e) NA_integer_)
    if (is.na(total_pages) || page >= total_pages) {
      break
    }
    page <- page + 1
  }

  if (length(out) == 0) {
    return(data.frame())
  }
  bind_rows(out)
}

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
cat(sprintf("  ✓ Missing CPI:   %d\n", sum(is.na(df$cpi))))
cat(sprintf("  ✓ Missing Brent: %d\n", sum(is.na(df$brent_usd))))
cat(sprintf("  ✓ Missing EXR:   %d\n", sum(is.na(df$exr))))
cat(sprintf("  ✓ Missing IIP:   %d\n", sum(is.na(df$iip))))

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
df$ln_exr <- log(df$exr)          # separate FX pass-through check

# 2.3 Log-differences (× 100 for percent)
df$dlnCPI <- c(NA, 100 * diff(df$ln_cpi))
df$dlnOil <- c(NA, 100 * diff(df$ln_oil))
df$dlnIIP <- c(NA, 100 * diff(df$ln_iip))
df$dlnBrent <- c(NA, 100 * diff(df$ln_brent))  # Brent-only for robustness
df$dlnEXR <- c(NA, 100 * diff(df$ln_exr))
cat("  ✓ Log-differences computed (×100 for percent)\n")

# 2.4 Signed decomposition of oil price changes
df$dlnOil_pos <- ifelse(!is.na(df$dlnOil), pmax(df$dlnOil, 0), NA)
df$dlnOil_neg <- ifelse(!is.na(df$dlnOil), pmin(df$dlnOil, 0), NA)

# Brent-only decomposition for robustness
df$dlnBrent_pos <- ifelse(!is.na(df$dlnBrent), pmax(df$dlnBrent, 0), NA)
df$dlnBrent_neg <- ifelse(!is.na(df$dlnBrent), pmin(df$dlnBrent, 0), NA)
cat("  ✓ Positive/negative oil shock decomposition created\n")

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
df$dlnEXR_L1 <- dplyr::lag(df$dlnEXR, 1)

df$dlnOil_pos_L0 <- df$dlnOil_pos
df$dlnOil_pos_L1 <- dplyr::lag(df$dlnOil_pos, 1)
df$dlnOil_pos_L2 <- dplyr::lag(df$dlnOil_pos, 2)
df$dlnOil_pos_L3 <- dplyr::lag(df$dlnOil_pos, 3)

df$dlnOil_neg_L0 <- df$dlnOil_neg
df$dlnOil_neg_L1 <- dplyr::lag(df$dlnOil_neg, 1)
df$dlnOil_neg_L2 <- dplyr::lag(df$dlnOil_neg, 2)
df$dlnOil_neg_L3 <- dplyr::lag(df$dlnOil_neg, 3)

# Brent-only lags for robustness
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
cat(sprintf("  ✓ dlnCPI missing: %d\n", sum(is.na(df$dlnCPI))))
cat(sprintf("  ✓ dlnOil missing: %d\n", sum(is.na(df$dlnOil))))
cat(sprintf("  ✓ dlnEXR missing: %d\n", sum(is.na(df$dlnEXR))))
cat(sprintf("  ✓ dlnIIP missing: %d\n", sum(is.na(df$dlnIIP))))

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
               "dlnCPI", "dlnOil", "dlnEXR", "dlnIIP", "dlnOil_pos", "dlnOil_neg")
desc_labels <- c("CPI Index", "Brent USD", "INR/USD", "IIP Index", "Oil INR",
                 "ΔlnCPI (%)", "ΔlnOil (%)", "ΔlnEXR (%)", "ΔlnIIP (%)", "ΔOil+ (%)", "ΔOil- (%)")

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
               "ΔlnEXR", "ΔlnIIP", "ΔOil+", "ΔOil-", "D_petrol", "D_diesel", "D_covid"),
  Source = c("OECD/FRED", "IMF/FRED", "Fed/FRED", "RBI DBIE", "Constructed",
             "Transformed", "Transformed", "Transformed", "Transformed",
             "Signed component", "Signed component",
             "Policy", "Policy", "Policy"),
  Transformation = c("Level", "Level", "Level", "Chain-linked", "Brent×EXR",
                      "100×Δln", "100×Δln", "100×Δln", "100×Δln",
                      "max(ΔlnOil,0)", "min(ΔlnOil,0)",
                      "=1 from Jun 2010", "=1 from Oct 2014", "=1 for Apr 2020"),
  Role = c("Source series", "Source series", "Source series", "Control source series",
            "Constructed source series", "Dependent variable", "Oil shock regressor",
            "Exchange-rate control", "Activity control",
            "Positive oil shock component", "Negative oil shock component",
            "Policy dummy", "Policy dummy", "Outlier dummy"),
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

# Figure 2 — Log-differenced series (4 panels)
df_plot <- df %>% filter(!is.na(dlnCPI))
p2a <- ggplot(df_plot, aes(date, dlnCPI)) + geom_line(color = "#1F3864", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  labs(title = "ΔlnCPI (monthly % change)", x = NULL, y = "%") + theme_minimal()
p2b <- ggplot(df_plot, aes(date, dlnOil)) + geom_line(color = "#C55A11", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  labs(title = "ΔlnOil_INR (monthly % change)", x = NULL, y = "%") + theme_minimal()
p2c <- ggplot(df_plot, aes(date, dlnEXR)) + geom_line(color = "#548235", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  labs(title = "ΔlnEXR (monthly % change)", x = NULL, y = "%") + theme_minimal()
p2d <- ggplot(df_plot, aes(date, dlnIIP)) + geom_line(color = "#7030A0", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  labs(title = "ΔlnIIP (monthly % change)", x = NULL, y = "%") + theme_minimal()
fig2 <- (p2a | p2b) / (p2c | p2d) + plot_annotation(
  title = "Figure 2: Log-Differenced Series (Monthly % Changes)")
ggsave("outputs/figures/fig_2_log_diff_series.png", fig2, width = 10, height = 6.5, dpi = 300)
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
  test <- suppressWarnings(adf.test(x_clean, alternative = "stationary"))
  data.frame(
    Variable = name,
    ADF_Statistic = round(test$statistic, 4),
    P_Value = round(test$p.value, 4),
    P_Value_Display = format_p_value(test$p.value),
    Lags_Used = test$parameter,
    Conclusion = ifelse(test$p.value < 0.05,
                        "Reject unit root (stationary)",
                        "Fail to reject unit root"),
    stringsAsFactors = FALSE
  )
}

adf_results <- bind_rows(
  run_adf(df$ln_cpi, "ln(CPI)"),
  run_adf(df$ln_oil, "ln(Oil_INR)"),
  run_adf(df$ln_exr, "ln(EXR)"),
  run_adf(df$ln_iip, "ln(IIP)"),
  run_adf(df$dlnCPI, "ΔlnCPI"),
  run_adf(df$dlnOil, "ΔlnOil"),
  run_adf(df$dlnEXR, "ΔlnEXR"),
  run_adf(df$dlnIIP, "ΔlnIIP")
)

write.csv(adf_results, "outputs/tables/table_4_1_adf_results.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_4_1_adf_results.csv\n\n")
cat("  ADF Results:\n")
for (i in 1:nrow(adf_results)) {
  r <- adf_results[i, ]
  cat(sprintf("    %-12s stat = %7.4f, p = %s  → %s\n",
              r$Variable, r$ADF_Statistic, r$P_Value_Display, r$Conclusion))
}
cat("  Note: values shown as <0.01 reflect the lower bound reported by tseries::adf.test.\n")

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
nw_vcov_sym <- NeweyWest(sym_model, lag = nw_lag_length(nrow(df_est)), prewhite = FALSE)
sym_coeftest <- coeftest(sym_model, vcov. = nw_vcov_sym)

beta0 <- coef(sym_model)["dlnOil"]
beta1 <- coef(sym_model)["dlnOil_L1"]
cpt_sym <- beta0 + beta1
sym_cpt_test <- extract_linear_test(sym_model, "dlnOil + dlnOil_L1 = 0", nw_vcov_sym, "H0: CPT = 0")

cat(sprintf("\n  β₀ (dlnOil)   = %.6f\n", beta0))
cat(sprintf("  β₁ (dlnOil_L1)= %.6f\n", beta1))
cat(sprintf("  Symmetric cumulative pass-through (β₀ + β₁) = %.6f\n", cpt_sym))
cat(sprintf("  Effect of 10%% oil shock on monthly CPI = %.4f pp\n", cpt_sym * 10))
cat(sprintf("  HAC test H₀: CPT = 0        F = %.4f, p = %s  → %s\n",
            sym_cpt_test$F_Statistic, format_p_value(sym_cpt_test$P_Value),
            test_decision(sym_cpt_test$P_Value)))
cat(sprintf("  Adj R² = %.4f\n", summary(sym_model)$adj.r.squared))
cat(sprintf("  N = %d\n", nrow(df_est)))

# Save table
sym_out <- data.frame(
  Variable = rownames(sym_coeftest),
  Estimate = round(sym_coeftest[, 1], 6),
  NW_SE = round(sym_coeftest[, 2], 6),
  t_value = round(sym_coeftest[, 3], 4),
  p_value = round(sym_coeftest[, 4], 4),
  Significance = sig_stars(sym_coeftest[, 4]),
  row.names = NULL
)
# Add summary row
sym_summary <- data.frame(
  Variable = c("---", "CPT (β₀+β₁)", "H0: CPT = 0 (F-test)", "Adj R²", "N"),
  Estimate = c(NA, round(cpt_sym, 6), round(sym_cpt_test$F_Statistic, 4),
               round(summary(sym_model)$adj.r.squared, 4), nrow(df_est)),
  NW_SE = NA,
  t_value = NA,
  p_value = c(NA, NA, round(sym_cpt_test$P_Value, 4), NA, NA),
  Significance = c("", "", sig_stars(sym_cpt_test$P_Value), "", ""),
  stringsAsFactors = FALSE
)
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
lag_col_best <- paste0("dlnCPI_L", best_p)
asym_formula <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms_best, " + ",
  "dlnOil_pos_L0 + dlnOil_pos_L1 + dlnOil_pos_L2 + dlnOil_pos_L3 + ",
  "dlnOil_neg_L0 + dlnOil_neg_L1 + dlnOil_neg_L2 + dlnOil_neg_L3 + ",
  "dlnIIP + D_petrol + D_diesel + D_covid + ",
  paste0("M", 1:11, collapse = " + ")
))

# Use the maximal sample implied by the selected lag order
df_asym <- df %>% filter(complete.cases(dlnCPI, !!sym(lag_col_best), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
asym_model <- lm(asym_formula, data = df_asym)

nw_vcov_asym <- NeweyWest(asym_model, lag = nw_lag_length(nrow(df_asym)), prewhite = FALSE)
asym_coeftest <- coeftest(asym_model, vcov. = nw_vcov_asym)

# Cumulative pass-through
cpt_pos <- sum(coef(asym_model)[grep("dlnOil_pos", names(coef(asym_model)))])
cpt_neg <- sum(coef(asym_model)[grep("dlnOil_neg", names(coef(asym_model)))])
effect_pos_10 <- cpt_pos * 10
effect_neg_10 <- cpt_neg * (-10)
asym_gap <- cpt_pos - abs(cpt_neg)

pos_coefs <- paste0("dlnOil_pos_L", 0:3)
neg_coefs <- paste0("dlnOil_neg_L", 0:3)
cpt_pos_test <- extract_linear_test(
  asym_model,
  sum_restriction(pos_coefs),
  nw_vcov_asym,
  "H0: CPT+ = 0"
)
cpt_neg_test <- extract_linear_test(
  asym_model,
  sum_restriction(neg_coefs),
  nw_vcov_asym,
  "H0: CPT- = 0"
)
cpt_asym_test <- extract_linear_test(
  asym_model,
  sum_restriction(pos_coefs, paste(neg_coefs, collapse = " + ")),
  nw_vcov_asym,
  "H0: CPT+ = CPT-"
)

cat(sprintf("\n  === MAIN ASYMMETRY RESULT (ADL(%d,3)) ===\n", best_p))
cat(sprintf("  CPT+ (cumulative positive pass-through) = %.6f\n", cpt_pos))
cat(sprintf("  CPT- (cumulative negative pass-through) = %.6f\n", cpt_neg))
cat(sprintf("  Asymmetry gap (CPT+ - |CPT-|)           = %.6f\n", asym_gap))
cat(sprintf("  Effect of +10%% oil shock: %.4f pp\n", effect_pos_10))
cat(sprintf("  Effect of -10%% oil shock: %.4f pp\n", effect_neg_10))
cat(sprintf("  HAC test H₀: CPT+ = 0       F = %.4f, p = %s  → %s\n",
            cpt_pos_test$F_Statistic, format_p_value(cpt_pos_test$P_Value),
            test_decision(cpt_pos_test$P_Value)))
cat(sprintf("  HAC test H₀: CPT- = 0       F = %.4f, p = %s  → %s\n",
            cpt_neg_test$F_Statistic, format_p_value(cpt_neg_test$P_Value),
            test_decision(cpt_neg_test$P_Value)))
cat(sprintf("  HAC test H₀: CPT+ = CPT-    F = %.4f, p = %s  → %s\n",
            cpt_asym_test$F_Statistic, format_p_value(cpt_asym_test$P_Value),
            test_decision(cpt_asym_test$P_Value)))
if (cpt_asym_test$P_Value >= 0.05) {
  cat("  Interpretation: point estimates suggest stronger pass-through from oil increases,\n")
  cat("                 but the asymmetry is not statistically significant at 5%.\n")
}
cat(sprintf("  Adj R-squared: %.4f\n", summary(asym_model)$adj.r.squared))
cat(sprintf("  N observations: %d\n", nrow(df_asym)))

# Save table
asym_out <- data.frame(
  Variable = rownames(asym_coeftest),
  Estimate = round(asym_coeftest[, 1], 6),
  NW_SE = round(asym_coeftest[, 2], 6),
  t_value = round(asym_coeftest[, 3], 4),
  p_value = round(asym_coeftest[, 4], 4),
  Significance = sig_stars(asym_coeftest[, 4]),
  row.names = NULL
)
asym_summary <- data.frame(
  Variable = c("---", "AR lags (p)", "CPT+", "H0: CPT+ = 0 (F-test)", "CPT-",
               "H0: CPT- = 0 (F-test)", "Asymmetry Gap", "H0: CPT+ = CPT- (F-test)",
               "Effect of +10% shock (pp)", "Effect of -10% shock (pp)", "Adj R²", "N"),
  Estimate = c(NA, best_p, round(cpt_pos, 6), round(cpt_pos_test$F_Statistic, 4),
               round(cpt_neg, 6), round(cpt_neg_test$F_Statistic, 4),
               round(asym_gap, 6), round(cpt_asym_test$F_Statistic, 4),
               round(effect_pos_10, 4), round(effect_neg_10, 4),
               round(summary(asym_model)$adj.r.squared, 4), nrow(df_asym)),
  NW_SE = NA,
  t_value = NA,
  p_value = c(NA, NA, NA, round(cpt_pos_test$P_Value, 4), NA, round(cpt_neg_test$P_Value, 4),
              NA, round(cpt_asym_test$P_Value, 4), NA, NA, NA, NA),
  Significance = c("", "", "", sig_stars(cpt_pos_test$P_Value), "", sig_stars(cpt_neg_test$P_Value),
                   "", sig_stars(cpt_asym_test$P_Value), "", "", "", ""),
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
wald_f <- cpt_asym_test$F_Statistic
wald_p <- cpt_asym_test$P_Value
wald_decision <- ifelse(
  wald_p < 0.05,
  "Reject H₀ at 5%: asymmetric pass-through",
  "Fail to reject H₀ at 5%: asymmetry not statistically significant"
)

cat(sprintf("\n  Wald Test: H₀: CPT+ = CPT-\n"))
cat(sprintf("    F-statistic = %.4f\n", wald_f))
cat(sprintf("    p-value     = %s\n", format_p_value(wald_p)))
cat(sprintf("    Decision    = %s\n", wald_decision))

wald_out <- data.frame(
  Test = "Wald: CPT+ = CPT-",
  F_Statistic = round(wald_f, 4),
  DF1 = cpt_asym_test$DF1,
  DF2 = cpt_asym_test$DF2,
  P_Value = round(wald_p, 4),
  P_Value_Display = format_p_value(wald_p),
  Decision = wald_decision,
  CPT_Plus = round(cpt_pos, 6),
  CPT_Minus = round(cpt_neg, 6),
  Effect_Pos_10pp = round(effect_pos_10, 4),
  Effect_Neg_10pp = round(effect_neg_10, 4),
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
  nw_vcov <- NeweyWest(mod, lag = nw_lag_length(nrow(sub_est)), prewhite = FALSE)

  cpt_p <- sum(coef(mod)[grep("dlnOil_pos", names(coef(mod)))])
  cpt_n <- sum(coef(mod)[grep("dlnOil_neg", names(coef(mod)))])
  pos_names <- grep("^dlnOil_pos_L", names(coef(mod)), value = TRUE)
  neg_names <- grep("^dlnOil_neg_L", names(coef(mod)), value = TRUE)
  pos_test <- extract_linear_test(mod, sum_restriction(pos_names), nw_vcov, "H0: CPT+ = 0")
  neg_test <- extract_linear_test(mod, sum_restriction(neg_names), nw_vcov, "H0: CPT- = 0")
  asym_test <- extract_linear_test(
    mod,
    sum_restriction(pos_names, paste(neg_names, collapse = " + ")),
    nw_vcov,
    "H0: CPT+ = CPT-"
  )

  cat(sprintf("  %s: N=%d, CPT+=%.6f, CPT-=%.6f, Gap=%.6f, p(asym)=%s, Adj R²=%.4f\n",
              label, nrow(sub_est), cpt_p, cpt_n, cpt_p - abs(cpt_n),
              format_p_value(asym_test$P_Value),
              summary(mod)$adj.r.squared))

  data.frame(Period = label, N = nrow(sub_est),
             CPT_Plus = round(cpt_p, 6), CPT_Minus = round(cpt_n, 6),
             CPT_Plus_P = round(pos_test$P_Value, 4),
             CPT_Minus_P = round(neg_test$P_Value, 4),
             Gap = round(cpt_p - abs(cpt_n), 6),
             Asym_P_Value = round(asym_test$P_Value, 4),
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
bp_pass <- ifelse(bp_test$p.value > 0.05, "PASS", "FAIL (HAC inference retained)")

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
if (bp_test$p.value < 0.05) {
  cat("  Note: heteroskedasticity is detected, so inference should rely on HAC/Newey-West tests.\n")
}

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

# --- Check 1: Lag grid sensitivity (p = 1:4, q = 0:3) on a common sample ---
cat("\n  --- Check 1: Lag Grid Sensitivity (common sample) ---\n")
lag_results <- list()
row_id <- 1
for (p_try in 1:4) {
  ar_terms_try <- paste0("dlnCPI_L", 1:p_try, collapse = " + ")
  for (q_try in 0:3) {
    pos_terms <- paste0("dlnOil_pos_L", 0:q_try, collapse = " + ")
    neg_terms <- paste0("dlnOil_neg_L", 0:q_try, collapse = " + ")
    f_str <- paste0(
      "dlnCPI ~ ", ar_terms_try, " + ", pos_terms, " + ", neg_terms,
      " + dlnIIP + D_petrol + D_diesel + D_covid + ",
      paste0("M", 1:11, collapse = " + ")
    )
    mod_q <- lm(as.formula(f_str), data = df_aic)
    nw_q <- NeweyWest(mod_q, lag = nw_lag_length(nrow(df_aic)), prewhite = FALSE)
    cp <- sum(coef(mod_q)[grep("dlnOil_pos", names(coef(mod_q)))])
    cn <- sum(coef(mod_q)[grep("dlnOil_neg", names(coef(mod_q)))])
    pos_names_q <- grep("^dlnOil_pos_L", names(coef(mod_q)), value = TRUE)
    neg_names_q <- grep("^dlnOil_neg_L", names(coef(mod_q)), value = TRUE)
    asym_q <- extract_linear_test(
      mod_q,
      sum_restriction(pos_names_q, paste(neg_names_q, collapse = " + ")),
      nw_q,
      "H0: CPT+ = CPT-"
    )
    bg_q <- bgtest(mod_q, order = 12)
    bp_q <- bptest(mod_q)
    reset_q <- resettest(mod_q, power = 2:3, type = "fitted")
    cusum_q <- sctest(efp(as.formula(f_str), data = df_aic, type = "Rec-CUSUM"))

    lag_results[[row_id]] <- data.frame(
      p = p_try,
      q = q_try,
      AIC = round(AIC(mod_q), 2),
      BIC = round(BIC(mod_q), 2),
      N = nrow(df_aic),
      CPT_Plus = round(cp, 6),
      CPT_Minus = round(cn, 6),
      Gap = round(cp - abs(cn), 6),
      Asym_P_Value = round(asym_q$P_Value, 4),
      BG_P_Value = round(bg_q$p.value, 4),
      BP_P_Value = round(bp_q$p.value, 4),
      RESET_P_Value = round(reset_q$p.value, 4),
      CUSUM_P_Value = round(cusum_q$p.value, 4),
      Primary_Model = ifelse(p_try == best_p && q_try == 3, "Yes", "No"),
      stringsAsFactors = FALSE
    )
    row_id <- row_id + 1
  }
}
lag_sensitivity <- bind_rows(lag_results) %>%
  mutate(AIC_Rank = rank(AIC, ties.method = "first")) %>%
  arrange(p, q)
write.csv(lag_sensitivity, "outputs/tables/table_5_1_lag_sensitivity.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_5_1_lag_sensitivity.csv\n")
best_grid <- lag_sensitivity %>% arrange(AIC, BIC) %>% slice(1)
cat("    Grid table is reported as sensitivity only; it does not override the pre-specified main model.\n")
cat(sprintf("    Primary model kept: ADL(%d,3)  AIC=%.2f, p(asym)=%s\n",
            best_p,
            lag_sensitivity %>% filter(p == best_p, q == 3) %>% pull(AIC),
            format_p_value((lag_sensitivity %>% filter(p == best_p, q == 3) %>% pull(Asym_P_Value))[1])))
cat(sprintf("    Lowest-AIC grid model: ADL(%d,%d)  AIC=%.2f, p(asym)=%s\n",
            best_grid$p, best_grid$q, best_grid$AIC,
            format_p_value(best_grid$Asym_P_Value)))

# --- Check 2: Brent USD with separate exchange-rate pass-through ---
cat("\n  --- Check 2: Brent USD + Exchange Rate ---\n")
usd_formula <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms_best, " + ",
  "dlnBrent_pos_L0 + dlnBrent_pos_L1 + dlnBrent_pos_L2 + dlnBrent_pos_L3 + ",
  "dlnBrent_neg_L0 + dlnBrent_neg_L1 + dlnBrent_neg_L2 + dlnBrent_neg_L3 + ",
  "dlnEXR + dlnEXR_L1 + ",
  "dlnIIP + D_petrol + D_diesel + D_covid + ",
  paste0("M", 1:11, collapse = " + ")
))
df_usd <- df %>% filter(complete.cases(
  dlnCPI, !!sym(lag_col_best), dlnBrent_pos_L3, dlnBrent_neg_L3,
  dlnEXR, dlnEXR_L1, dlnIIP
))
usd_model <- lm(usd_formula, data = df_usd)
nw_usd <- NeweyWest(usd_model, lag = nw_lag_length(nrow(df_usd)), prewhite = FALSE)
cpt_usd_pos <- sum(coef(usd_model)[grep("dlnBrent_pos", names(coef(usd_model)))])
cpt_usd_neg <- sum(coef(usd_model)[grep("dlnBrent_neg", names(coef(usd_model)))])
usd_pos_test <- extract_linear_test(
  usd_model,
  sum_restriction(grep("^dlnBrent_pos_L", names(coef(usd_model)), value = TRUE)),
  nw_usd,
  "H0: Brent CPT+ = 0"
)
usd_neg_test <- extract_linear_test(
  usd_model,
  sum_restriction(grep("^dlnBrent_neg_L", names(coef(usd_model)), value = TRUE)),
  nw_usd,
  "H0: Brent CPT- = 0"
)
usd_asym <- extract_linear_test(
  usd_model,
  sum_restriction(
    grep("^dlnBrent_pos_L", names(coef(usd_model)), value = TRUE),
    paste(grep("^dlnBrent_neg_L", names(coef(usd_model)), value = TRUE), collapse = " + ")
  ),
  nw_usd,
  "H0: Brent CPT+ = Brent CPT-"
)
usd_ct <- coeftest(usd_model, vcov. = nw_usd)
cat(sprintf(
  "    Brent+EXR: CPT+=%.6f, CPT-=%.6f, Gap=%.6f, p(CPT+)=%s, p(asym)=%s, EXR p=%s\n",
  cpt_usd_pos, cpt_usd_neg, cpt_usd_pos - abs(cpt_usd_neg),
  format_p_value(usd_pos_test$P_Value),
  format_p_value(usd_asym$P_Value),
  format_p_value(usd_ct["dlnEXR", 4])
))
usd_out <- data.frame(
  Specification = c("Primary (INR oil)", "Brent USD + EXR"),
  CPT_Plus = c(round(cpt_pos, 6), round(cpt_usd_pos, 6)),
  CPT_Minus = c(round(cpt_neg, 6), round(cpt_usd_neg, 6)),
  Gap = c(round(cpt_pos - abs(cpt_neg), 6), round(cpt_usd_pos - abs(cpt_usd_neg), 6)),
  CPT_Plus_P = c(round(cpt_pos_test$P_Value, 4), round(usd_pos_test$P_Value, 4)),
  CPT_Minus_P = c(round(cpt_neg_test$P_Value, 4), round(usd_neg_test$P_Value, 4)),
  Asym_P_Value = c(round(cpt_asym_test$P_Value, 4), round(usd_asym$P_Value, 4)),
  EXR_Coefficient = c(NA, round(usd_ct["dlnEXR", 1], 6)),
  EXR_P_Value = c(NA, round(usd_ct["dlnEXR", 4], 4)),
  EXR_L1_Coefficient = c(NA, round(usd_ct["dlnEXR_L1", 1], 6)),
  EXR_L1_P_Value = c(NA, round(usd_ct["dlnEXR_L1", 4], 4)),
  Effect_Pos_10pp = c(round(effect_pos_10, 4), round(cpt_usd_pos * 10, 4)),
  Effect_Neg_10pp = c(round(effect_neg_10, 4), round(cpt_usd_neg * (-10), 4)),
  AIC = c(round(AIC(asym_model), 2), round(AIC(usd_model), 2)),
  Adj_R2 = c(round(summary(asym_model)$adj.r.squared, 4), round(summary(usd_model)$adj.r.squared, 4)),
  stringsAsFactors = FALSE
)
if (file.exists("outputs/tables/table_5_2_usd_specification.csv")) {
  unlink("outputs/tables/table_5_2_usd_specification.csv")
}
write.csv(usd_out, "outputs/tables/table_5_2_brent_exr_specification.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_5_2_brent_exr_specification.csv\n")

# --- Appendix: CPI Fuel and Light (official MoSPI API) ---
cat("\n  --- Appendix: CPI Fuel and Light (official MoSPI API) ---\n")
fuel_appendix_out <- NULL
tryCatch({
  fuel_back <- fetch_mospi_cpi_group(2011:2012, series = "Back", group_code = 5)
  fuel_current <- fetch_mospi_cpi_group(2013:2024, series = "Current", group_code = 5)
  fuel_api <- bind_rows(fuel_back, fuel_current) %>%
    mutate(
      year = as.integer(year),
      month_num = match(month, month.name),
      fuel_cpi = as.numeric(index),
      date = as.Date(sprintf("%04d-%02d-01", year, month_num))
    ) %>%
    filter(!is.na(date), !is.na(fuel_cpi)) %>%
    distinct(date, .keep_all = TRUE) %>%
    arrange(date) %>%
    select(date, fuel_cpi, group, subgroup, sector, state, baseyear)

  if (nrow(fuel_api) >= 120) {
    write.csv(fuel_api, "data/processed/cpi_fuel_light_all_india_combined.csv", row.names = FALSE)
    cat("    ✓ File saved: data/processed/cpi_fuel_light_all_india_combined.csv\n")
    cat(sprintf("    ✓ Official Fuel & Light sample: %s to %s  (N = %d)\n",
                min(fuel_api$date), max(fuel_api$date), nrow(fuel_api)))

    df_fuel <- df %>%
      inner_join(fuel_api %>% select(date, fuel_cpi), by = "date") %>%
      arrange(date)

    df_fuel$ln_fuel_cpi <- log(df_fuel$fuel_cpi)
    df_fuel$dlnFuelCPI <- c(NA, 100 * diff(df_fuel$ln_fuel_cpi))
    for (lag_i in 1:4) {
      df_fuel[[paste0("dlnFuelCPI_L", lag_i)]] <- dplyr::lag(df_fuel$dlnFuelCPI, lag_i)
    }

    fuel_sample_lag <- paste0("dlnFuelCPI_L", best_p)
    df_fuel_est <- df_fuel %>% filter(complete.cases(
      dlnFuelCPI, !!sym(fuel_sample_lag), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP
    ))

    fuel_rhs <- c(
      paste0("dlnFuelCPI_L", 1:best_p),
      paste0("dlnOil_pos_L", 0:3),
      paste0("dlnOil_neg_L", 0:3),
      "dlnIIP", "D_petrol", "D_diesel", "D_covid",
      paste0("M", 1:11)
    )
    fuel_rhs <- fuel_rhs[vapply(fuel_rhs, function(term) length(unique(df_fuel_est[[term]])) > 1, logical(1))]
    fuel_formula <- as.formula(paste("dlnFuelCPI ~", paste(fuel_rhs, collapse = " + ")))

    fuel_model <- lm(fuel_formula, data = df_fuel_est)
    fuel_nw <- NeweyWest(fuel_model, lag = nw_lag_length(nrow(df_fuel_est)), prewhite = FALSE)
    fuel_cpt_pos <- sum(coef(fuel_model)[grep("^dlnOil_pos_L", names(coef(fuel_model)))])
    fuel_cpt_neg <- sum(coef(fuel_model)[grep("^dlnOil_neg_L", names(coef(fuel_model)))])
    fuel_pos_test <- extract_linear_test(
      fuel_model,
      sum_restriction(grep("^dlnOil_pos_L", names(coef(fuel_model)), value = TRUE)),
      fuel_nw,
      "H0: Fuel CPI CPT+ = 0"
    )
    fuel_neg_test <- extract_linear_test(
      fuel_model,
      sum_restriction(grep("^dlnOil_neg_L", names(coef(fuel_model)), value = TRUE)),
      fuel_nw,
      "H0: Fuel CPI CPT- = 0"
    )
    fuel_asym_test <- extract_linear_test(
      fuel_model,
      sum_restriction(
        grep("^dlnOil_pos_L", names(coef(fuel_model)), value = TRUE),
        paste(grep("^dlnOil_neg_L", names(coef(fuel_model)), value = TRUE), collapse = " + ")
      ),
      fuel_nw,
      "H0: Fuel CPI CPT+ = Fuel CPI CPT-"
    )

    fuel_appendix_out <- data.frame(
      Dependent_Variable = "CPI Fuel and Light (All India Combined)",
      Source = "Official MoSPI CPI API",
      Sample_Start = as.character(min(df_fuel_est$date)),
      Sample_End = as.character(max(df_fuel_est$date)),
      N = nrow(df_fuel_est),
      CPT_Plus = round(fuel_cpt_pos, 6),
      CPT_Minus = round(fuel_cpt_neg, 6),
      Gap = round(fuel_cpt_pos - abs(fuel_cpt_neg), 6),
      CPT_Plus_P = round(fuel_pos_test$P_Value, 4),
      CPT_Minus_P = round(fuel_neg_test$P_Value, 4),
      Asym_P_Value = round(fuel_asym_test$P_Value, 4),
      Effect_Pos_10pp = round(fuel_cpt_pos * 10, 4),
      Effect_Neg_10pp = round(fuel_cpt_neg * (-10), 4),
      Adj_R2 = round(summary(fuel_model)$adj.r.squared, 4),
      stringsAsFactors = FALSE
    )
    write.csv(fuel_appendix_out, "outputs/tables/table_a_1_fuel_light_appendix.csv", row.names = FALSE)
    cat("    ✓ File saved: outputs/tables/table_a_1_fuel_light_appendix.csv\n")
    cat(sprintf("    Fuel CPI appendix: CPT+=%.6f, CPT-=%.6f, p(CPT+)=%s, p(asym)=%s\n",
                fuel_cpt_pos, fuel_cpt_neg,
                format_p_value(fuel_pos_test$P_Value),
                format_p_value(fuel_asym_test$P_Value)))
  } else {
    cat("    ⚠ Official Fuel & Light appendix skipped: insufficient API data\n")
  }
}, error = function(e) {
  cat(sprintf("    ⚠ Official Fuel & Light appendix skipped: %s\n", e$message))
})

# --- Check 3: COVID sensitivity ---
cat("\n  --- Check 3: COVID Sensitivity ---\n")
nocovid_formula <- update(asym_formula, . ~ . - D_covid)
nocovid_model <- lm(nocovid_formula, data = df_asym)
nw_nocovid <- NeweyWest(nocovid_model, lag = nw_lag_length(nrow(df_asym)), prewhite = FALSE)
cpt_nc_pos <- sum(coef(nocovid_model)[grep("dlnOil_pos", names(coef(nocovid_model)))])
cpt_nc_neg <- sum(coef(nocovid_model)[grep("dlnOil_neg", names(coef(nocovid_model)))])
nocovid_asym <- extract_linear_test(
  nocovid_model,
  sum_restriction(
    grep("^dlnOil_pos_L", names(coef(nocovid_model)), value = TRUE),
    paste(grep("^dlnOil_neg_L", names(coef(nocovid_model)), value = TRUE), collapse = " + ")
  ),
  nw_nocovid,
  "H0: CPT+ = CPT-"
)
cat(sprintf("    Without COVID: CPT+=%.6f, CPT-=%.6f, Gap=%.6f, p(asym)=%s\n",
            cpt_nc_pos, cpt_nc_neg, cpt_nc_pos - abs(cpt_nc_neg),
            format_p_value(nocovid_asym$P_Value)))
covid_out <- data.frame(
  Specification = c("With COVID dummy", "Without COVID dummy"),
  CPT_Plus = c(round(cpt_pos, 6), round(cpt_nc_pos, 6)),
  CPT_Minus = c(round(cpt_neg, 6), round(cpt_nc_neg, 6)),
  Gap = c(round(cpt_pos - abs(cpt_neg), 6), round(cpt_nc_pos - abs(cpt_nc_neg), 6)),
  Asym_P_Value = c(round(cpt_asym_test$P_Value, 4), round(nocovid_asym$P_Value, 4)),
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
df_win_est <- df_win %>% filter(complete.cases(dlnCPI, !!sym(lag_col_best), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
win_model <- lm(asym_formula, data = df_win_est)
nw_win <- NeweyWest(win_model, lag = nw_lag_length(nrow(df_win_est)), prewhite = FALSE)
cpt_w_pos <- sum(coef(win_model)[grep("dlnOil_pos", names(coef(win_model)))])
cpt_w_neg <- sum(coef(win_model)[grep("dlnOil_neg", names(coef(win_model)))])
win_asym <- extract_linear_test(
  win_model,
  sum_restriction(
    grep("^dlnOil_pos_L", names(coef(win_model)), value = TRUE),
    paste(grep("^dlnOil_neg_L", names(coef(win_model)), value = TRUE), collapse = " + ")
  ),
  nw_win,
  "H0: CPT+ = CPT-"
)
cat(sprintf("    Winsorized: CPT+=%.6f, CPT-=%.6f, Gap=%.6f, p(asym)=%s\n",
            cpt_w_pos, cpt_w_neg, cpt_w_pos - abs(cpt_w_neg),
            format_p_value(win_asym$P_Value)))
win_out <- data.frame(
  Specification = c("Original", "Winsorized (1%)"),
  CPT_Plus = c(round(cpt_pos, 6), round(cpt_w_pos, 6)),
  CPT_Minus = c(round(cpt_neg, 6), round(cpt_w_neg, 6)),
  Gap = c(round(cpt_pos - abs(cpt_neg), 6), round(cpt_w_pos - abs(cpt_w_neg), 6)),
  Asym_P_Value = c(round(cpt_asym_test$P_Value, 4), round(win_asym$P_Value, 4)),
  stringsAsFactors = FALSE
)
write.csv(win_out, "outputs/tables/table_5_4_winsorized.csv", row.names = FALSE)
cat("  ✓ File saved: outputs/tables/table_5_4_winsorized.csv\n")

# --- Check 5: Rolling window (60 months) ---
cat("\n  --- Check 5: Rolling Window (60-month) ---\n")
window_size <- 60
df_roll <- df %>% filter(complete.cases(dlnCPI, !!sym(lag_col_best), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
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
cat(sprintf("  CPT+ (full sample)  = %.6f  (+10%% shock → %.4f pp)\n", cpt_pos, effect_pos_10))
cat(sprintf("  CPT- (full sample)  = %.6f  (-10%% shock → %.4f pp)\n", cpt_neg, effect_neg_10))
cat(sprintf("  CPT+ p-value        = %s\n", format_p_value(cpt_pos_test$P_Value)))
cat(sprintf("  CPT- p-value        = %s\n", format_p_value(cpt_neg_test$P_Value)))
cat(sprintf("  Wald test p-value   = %s\n", format_p_value(wald_p)))
if (wald_p < 0.05) {
  cat("  Inference           = Asymmetry is statistically significant at 5%\n")
} else {
  cat("  Inference           = Point estimates are asymmetric, but the asymmetry is not statistically significant at 5%\n")
}
cat(sprintf("  Brent+EXR model     = CPT+ %.6f (+10%% shock → %.4f pp), p = %s\n",
            cpt_usd_pos, cpt_usd_pos * 10, format_p_value(usd_pos_test$P_Value)))
cat(sprintf("  Exchange-rate p     = %s (lag p = %s)\n",
            format_p_value(usd_ct["dlnEXR", 4]), format_p_value(usd_ct["dlnEXR_L1", 4])))
if (exists("fuel_appendix_out") && is.data.frame(fuel_appendix_out)) {
  cat(sprintf("  Fuel CPI appendix   = CPT+ %.6f (+10%% shock → %.4f pp), p = %s\n",
              fuel_appendix_out$CPT_Plus[1],
              fuel_appendix_out$Effect_Pos_10pp[1],
              format_p_value(fuel_appendix_out$CPT_Plus_P[1])))
  cat(sprintf("  Fuel asymmetry p    = %s  (sample %s to %s)\n",
              format_p_value(fuel_appendix_out$Asym_P_Value[1]),
              fuel_appendix_out$Sample_Start[1],
              fuel_appendix_out$Sample_End[1]))
}
cat(sprintf("  Adj R² (main model) = %.4f\n", summary(asym_model)$adj.r.squared))
cat("══════════════════════════════════════════════════\n")
