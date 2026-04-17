# ==============================================================================
# 03_models.R — Short-run ADL models and literature-style NARDL appendix
# ==============================================================================
banner("03", "MODELS")

rhs_headline_main <- c(
  paste0("dln_dep_L", 1:MAIN_AR_LAGS),
  paste0("dln_oil_pos_L", 0:MAIN_OIL_LAGS),
  paste0("dln_oil_neg_L", 0:MAIN_OIL_LAGS),
  "month"
)

rhs_headline_brent <- c(
  paste0("dln_dep_L", 1:MAIN_AR_LAGS),
  paste0("dln_brent_pos_L", 0:MAIN_OIL_LAGS),
  paste0("dln_brent_neg_L", 0:MAIN_OIL_LAGS),
  "dln_exr", "dln_exr_L1",
  "month"
)

rhs_fuel_main <- c(
  paste0("dln_dep_L", 1:MAIN_AR_LAGS),
  paste0("dln_oil_pos_L", 0:MAIN_OIL_LAGS),
  paste0("dln_oil_neg_L", 0:MAIN_OIL_LAGS),
  "dln_exr", "dln_exr_L1",
  "d_reform", "d_covid",
  "month"
)

f_headline_main <- as.formula(paste("dln_dep ~", paste(rhs_headline_main, collapse = " + ")))
f_headline_brent <- as.formula(paste("dln_dep ~", paste(rhs_headline_brent, collapse = " + ")))
f_fuel_main <- as.formula(paste("dln_dep ~", paste(rhs_fuel_main, collapse = " + ")))

df_headline_main <- estimation_data(headline_model_data, f_headline_main)
df_headline_brent <- estimation_data(headline_model_data, f_headline_brent)
df_fuel_main <- estimation_data(fuel_model_data, f_fuel_main)

m_headline_main <- lm(f_headline_main, data = df_headline_main)
m_headline_brent <- lm(f_headline_brent, data = df_headline_brent)
m_fuel_main <- lm(f_fuel_main, data = df_fuel_main)

nw_headline_main <- NeweyWest(m_headline_main, lag = nw_lag(nrow(df_headline_main)), prewhite = FALSE)
nw_headline_brent <- NeweyWest(m_headline_brent, lag = nw_lag(nrow(df_headline_brent)), prewhite = FALSE)
nw_fuel_main <- NeweyWest(m_fuel_main, lag = nw_lag(nrow(df_fuel_main)), prewhite = FALSE)

cpt_headline_main <- compute_cpt(
  m_headline_main,
  paste0("dln_oil_pos_L", 0:MAIN_OIL_LAGS),
  paste0("dln_oil_neg_L", 0:MAIN_OIL_LAGS),
  nw_headline_main,
  "Headline main: "
)

cpt_headline_brent <- compute_cpt(
  m_headline_brent,
  paste0("dln_brent_pos_L", 0:MAIN_OIL_LAGS),
  paste0("dln_brent_neg_L", 0:MAIN_OIL_LAGS),
  nw_headline_brent,
  "Headline Brent+EXR: "
)

cpt_fuel_main <- compute_cpt(
  m_fuel_main,
  paste0("dln_oil_pos_L", 0:MAIN_OIL_LAGS),
  paste0("dln_oil_neg_L", 0:MAIN_OIL_LAGS),
  nw_fuel_main,
  "Fuel main: "
)

headline_main_summary <- data.frame(
  Specification = "Headline WPI ADL: INR oil +/- , AR(12), oil lags 0:6, month FE",
  Sample_start = as.character(min(df_headline_main$date)),
  Sample_end = as.character(max(df_headline_main$date)),
  N = nrow(df_headline_main),
  Span_years = round(sample_span_years(df_headline_main$date), 2),
  Adj_R2 = round(summary(m_headline_main)$adj.r.squared, 4),
  CPT_pos = round(cpt_headline_main$cpt_pos, 6),
  CPT_neg = round(cpt_headline_main$cpt_neg, 6),
  CPTpos_p = round(cpt_headline_main$pos_test$p_value, 4),
  CPTneg_p = round(cpt_headline_main$neg_test$p_value, 4),
  Asym_p = round(cpt_headline_main$asym_test$p_value, 4),
  stringsAsFactors = FALSE
)

headline_brent_summary <- data.frame(
  Specification = "Headline WPI ADL: Brent +/- , EXR, AR(12), lags 0:6, month FE",
  Sample_start = as.character(min(df_headline_brent$date)),
  Sample_end = as.character(max(df_headline_brent$date)),
  N = nrow(df_headline_brent),
  Span_years = round(sample_span_years(df_headline_brent$date), 2),
  Adj_R2 = round(summary(m_headline_brent)$adj.r.squared, 4),
  CPT_pos = round(cpt_headline_brent$cpt_pos, 6),
  CPT_neg = round(cpt_headline_brent$cpt_neg, 6),
  CPTpos_p = round(cpt_headline_brent$pos_test$p_value, 4),
  CPTneg_p = round(cpt_headline_brent$neg_test$p_value, 4),
  Asym_p = round(cpt_headline_brent$asym_test$p_value, 4),
  stringsAsFactors = FALSE
)

fuel_main_summary <- data.frame(
  Specification = "Fuel & Power WPI ADL: INR oil +/- , AR(12), oil lags 0:6, month FE",
  Sample_start = as.character(min(df_fuel_main$date)),
  Sample_end = as.character(max(df_fuel_main$date)),
  N = nrow(df_fuel_main),
  Span_years = round(sample_span_years(df_fuel_main$date), 2),
  Adj_R2 = round(summary(m_fuel_main)$adj.r.squared, 4),
  CPT_pos = round(cpt_fuel_main$cpt_pos, 6),
  CPT_neg = round(cpt_fuel_main$cpt_neg, 6),
  CPTpos_p = round(cpt_fuel_main$pos_test$p_value, 4),
  CPTneg_p = round(cpt_fuel_main$neg_test$p_value, 4),
  Asym_p = round(cpt_fuel_main$asym_test$p_value, 4),
  stringsAsFactors = FALSE
)

save_table(headline_main_summary, "table_04_headline_main_model.csv")
save_table(headline_brent_summary, "table_05_headline_brent_exr_model.csv")
save_table(fuel_main_summary, "table_06_fuel_power_model.csv")
save_table(coef_table(m_headline_main, nw_headline_main), "table_04b_headline_main_coefficients.csv")
save_table(coef_table(m_headline_brent, nw_headline_brent), "table_05b_headline_brent_exr_coefficients.csv")
save_table(coef_table(m_fuel_main, nw_fuel_main), "table_06b_fuel_power_coefficients.csv")

cat("  Headline main:\n")
cat(sprintf("    N=%d | CPT+=%.4f (p=%s) | CPT-=%.4f (p=%s) | Asym p=%s\n",
  nrow(df_headline_main),
  cpt_headline_main$cpt_pos, format_p(cpt_headline_main$pos_test$p_value),
  cpt_headline_main$cpt_neg, format_p(cpt_headline_main$neg_test$p_value),
  format_p(cpt_headline_main$asym_test$p_value)))

cat("  Fuel & Power main:\n")
cat(sprintf("    N=%d | CPT+=%.4f (p=%s) | CPT-=%.4f (p=%s) | Asym p=%s\n",
  nrow(df_fuel_main),
  cpt_fuel_main$cpt_pos, format_p(cpt_fuel_main$pos_test$p_value),
  cpt_fuel_main$cpt_neg, format_p(cpt_fuel_main$neg_test$p_value),
  format_p(cpt_fuel_main$asym_test$p_value)))

cat("\n  Running literature-style NARDL appendix models...\n")

nardl_headline_data <- headline_model_data %>%
  filter(date >= NARDL_LIT_START, date <= NARDL_LIT_END) %>%
  transmute(
    date,
    ln_wpi = ln_dep,
    ln_brent = ln_brent,
    ln_exr = ln_exr,
    ln_oil_inr = ln_oil
  ) %>%
  filter(complete.cases(.))

nardl_fuel_data <- fuel_model_data %>%
  filter(date >= max(as.Date("1995-04-01"), NARDL_LIT_START), date <= NARDL_LIT_END) %>%
  transmute(
    date,
    ln_fuel = ln_dep,
    ln_brent = ln_brent,
    ln_exr = ln_exr,
    ln_oil_inr = ln_oil
  ) %>%
  filter(complete.cases(.))

nardl_headline_brent <- nardl(
  ln_wpi ~ ln_brent,
  data = nardl_headline_data,
  ic = "aic",
  maxlag = NARDL_MAX_LAG,
  graph = FALSE,
  case = 3
)

nardl_headline_brent_exr <- nardl(
  ln_wpi ~ ln_brent | ln_exr,
  data = nardl_headline_data,
  ic = "aic",
  maxlag = NARDL_MAX_LAG,
  graph = FALSE,
  case = 3
)

nardl_headline_inr <- nardl(
  ln_wpi ~ ln_oil_inr,
  data = nardl_headline_data,
  ic = "aic",
  maxlag = NARDL_MAX_LAG,
  graph = FALSE,
  case = 3
)

nardl_fuel_inr <- nardl(
  ln_fuel ~ ln_oil_inr,
  data = nardl_fuel_data,
  ic = "aic",
  maxlag = NARDL_MAX_LAG,
  graph = FALSE,
  case = 3
)

nardl_summary <- bind_rows(
  collect_nardl_summary(
    "NARDL headline: ln(WPI) ~ ln(Brent)",
    nardl_headline_brent,
    min(nardl_headline_data$date),
    max(nardl_headline_data$date),
    "ln_wpi"
  ),
  collect_nardl_summary(
    "NARDL headline: ln(WPI) ~ ln(Brent) | ln(EXR)",
    nardl_headline_brent_exr,
    min(nardl_headline_data$date),
    max(nardl_headline_data$date),
    "ln_wpi"
  ),
  collect_nardl_summary(
    "NARDL headline: ln(WPI) ~ ln(INR-oil)",
    nardl_headline_inr,
    min(nardl_headline_data$date),
    max(nardl_headline_data$date),
    "ln_wpi"
  ),
  collect_nardl_summary(
    "NARDL fuel: ln(Fuel&Power) ~ ln(INR-oil)",
    nardl_fuel_inr,
    min(nardl_fuel_data$date),
    max(nardl_fuel_data$date),
    "ln_fuel"
  )
)

nardl_long_run <- bind_rows(
  data.frame(
    Specification = "NARDL headline: ln(WPI) ~ ln(Brent)",
    Coefficient = rownames(nardl_headline_brent$lres),
    Estimate = round(nardl_headline_brent$lres[, 1], 6),
    SE = round(nardl_headline_brent$lres[, 2], 6),
    t_value = round(nardl_headline_brent$lres[, 3], 4),
    p_value = round(nardl_headline_brent$lres[, 4], 4),
    stringsAsFactors = FALSE
  ),
  data.frame(
    Specification = "NARDL headline: ln(WPI) ~ ln(Brent) | ln(EXR)",
    Coefficient = rownames(nardl_headline_brent_exr$lres),
    Estimate = round(nardl_headline_brent_exr$lres[, 1], 6),
    SE = round(nardl_headline_brent_exr$lres[, 2], 6),
    t_value = round(nardl_headline_brent_exr$lres[, 3], 4),
    p_value = round(nardl_headline_brent_exr$lres[, 4], 4),
    stringsAsFactors = FALSE
  ),
  data.frame(
    Specification = "NARDL headline: ln(WPI) ~ ln(INR-oil)",
    Coefficient = rownames(nardl_headline_inr$lres),
    Estimate = round(nardl_headline_inr$lres[, 1], 6),
    SE = round(nardl_headline_inr$lres[, 2], 6),
    t_value = round(nardl_headline_inr$lres[, 3], 4),
    p_value = round(nardl_headline_inr$lres[, 4], 4),
    stringsAsFactors = FALSE
  ),
  data.frame(
    Specification = "NARDL fuel: ln(Fuel&Power) ~ ln(INR-oil)",
    Coefficient = rownames(nardl_fuel_inr$lres),
    Estimate = round(nardl_fuel_inr$lres[, 1], 6),
    SE = round(nardl_fuel_inr$lres[, 2], 6),
    t_value = round(nardl_fuel_inr$lres[, 3], 4),
    p_value = round(nardl_fuel_inr$lres[, 4], 4),
    stringsAsFactors = FALSE
  )
)

save_table(nardl_summary, "table_07_nardl_summary.csv")
save_table(nardl_long_run, "table_08_nardl_long_run.csv")

cat("\n  Subsample robustness (pre/post 2010 diesel-reform onset)...\n")

split_date <- as.Date("2010-04-01")

drop_constant_terms <- function(formula, data) {
  rhs_vars <- all.vars(formula[[3]])
  bad <- character(0)
  for (v in rhs_vars) {
    if (v %in% names(data)) {
      vec <- data[[v]]
      if (is.numeric(vec) || is.integer(vec)) {
        if (all(is.na(vec)) || length(unique(vec[!is.na(vec)])) < 2) {
          bad <- c(bad, v)
        }
      }
    }
  }
  if (length(bad) == 0) return(formula)
  rhs_new <- setdiff(attr(terms(formula), "term.labels"), bad)
  lhs <- as.character(formula[[2]])
  as.formula(paste(lhs, "~", paste(rhs_new, collapse = " + ")))
}

fit_subsample <- function(d, formula, label, subsample_name) {
  if (nrow(d) < 40) return(NULL)
  f_use <- drop_constant_terms(formula, d)
  m <- lm(f_use, data = d)
  nw <- NeweyWest(m, lag = nw_lag(nrow(d)), prewhite = FALSE)
  cpt <- compute_cpt(
    m,
    paste0("dln_oil_pos_L", 0:MAIN_OIL_LAGS),
    paste0("dln_oil_neg_L", 0:MAIN_OIL_LAGS),
    nw, paste0(label, " ", subsample_name, ": ")
  )
  data.frame(
    Model = label, Subsample = subsample_name,
    Sample_start = as.character(min(d$date)),
    Sample_end = as.character(max(d$date)),
    N = nrow(d),
    CPT_pos = round(cpt$cpt_pos, 6),
    CPT_neg = round(cpt$cpt_neg, 6),
    CPTpos_p = round(cpt$pos_test$p_value, 4),
    CPTneg_p = round(cpt$neg_test$p_value, 4),
    Asym_p = round(cpt$asym_test$p_value, 4),
    stringsAsFactors = FALSE
  )
}

run_subsample_adl <- function(data_df, formula, label) {
  df_pre <- data_df %>% filter(date < split_date)
  df_post <- data_df %>% filter(date >= split_date)

  pre_d <- estimation_data(df_pre, formula)
  post_d <- estimation_data(df_post, formula)

  pre_est <- tryCatch(fit_subsample(pre_d, formula, label, "Pre-2010"),
    error = function(e) { cat(sprintf("    pre-2010 fit failed for %s: %s\n", label, e$message)); NULL })
  post_est <- tryCatch(fit_subsample(post_d, formula, label, "Post-2010"),
    error = function(e) { cat(sprintf("    post-2010 fit failed for %s: %s\n", label, e$message)); NULL })

  bind_rows(pre_est, post_est)
}

subsample_summary <- bind_rows(
  run_subsample_adl(headline_model_data, f_headline_main, "Headline WPI ADL (INR oil)"),
  run_subsample_adl(fuel_model_data, f_fuel_main, "Fuel & Power WPI ADL")
)

save_table(subsample_summary, "table_12_subsample_prepost2010.csv")

cat("  Subsample rows:", nrow(subsample_summary), "\n")

cat("  [03_models] Done.\n")
