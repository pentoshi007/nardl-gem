# ==============================================================================
# 10_robustness.R — Robustness checks
# ==============================================================================
# R1: NOPI (Hamilton) specification
# R2: Post-2011 subsample
# R3: Pre/Post 2014 (diesel deregulation) subsamples
# R4: COVID sensitivity (with/without COVID dummy)
# R5: Winsorized (1%) sensitivity
# R6: Rolling-window (60-month) CPT series
# R7: Lag grid (p=1..4, q=0..3)
# ==============================================================================
banner("10", "ROBUSTNESS CHECKS")

robustness_rows <- list()
subsample_rows <- list()
dummy_terms_str <- paste0("M", 1:11, collapse = " + ")

# ==============================================================================
# R1: NOPI (Hamilton 2003) specification
# ==============================================================================
cat("\n  --- R1: NOPI (Hamilton) Specification ---\n")

tryCatch({
  df_nopi <- df %>% filter(complete.cases(
    dlnCPI, dlnCPI_L1, nopi_pos_L3, nopi_neg_L3, dlnIIP))

  f_nopi <- as.formula(paste0(
    "dlnCPI ~ ", ar_terms,
    " + nopi_pos_L0 + nopi_pos_L1 + nopi_pos_L2 + nopi_pos_L3",
    " + nopi_neg_L0 + nopi_neg_L1 + nopi_neg_L2 + nopi_neg_L3",
    " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms_str))

  m_nopi  <- lm(f_nopi, data = df_nopi)
  nw_nopi <- NeweyWest(m_nopi, lag = nw_lag(nrow(df_nopi)), prewhite = FALSE)
  cpt_nopi <- compute_cpt(m_nopi,
    paste0("nopi_pos_L", 0:3), paste0("nopi_neg_L", 0:3),
    nw_nopi, "NOPI: ")

  cat(sprintf("  NOPI: N=%d | CPT+= %.4f (p=%s) | Asym p = %s\n",
      nrow(df_nopi), cpt_nopi$cpt_pos, format_p(cpt_nopi$pos_test$p_value),
      format_p(cpt_nopi$asym_test$p_value)))

  save_table(coef_table(m_nopi, nw_nopi), "table_15_nopi_robustness.csv")

  robustness_rows[["NOPI"]] <- data.frame(
    Check = "NOPI (Hamilton)", N = nrow(df_nopi),
    CPT_pos = round(cpt_nopi$cpt_pos, 6), CPT_neg = round(cpt_nopi$cpt_neg, 6),
    Asym_p = round(cpt_nopi$asym_test$p_value, 4),
    stringsAsFactors = FALSE)
}, error = function(e) cat(sprintf("  NOPI error: %s\n", e$message)))

# ==============================================================================
# R2: Post-2011 subsample (CPI base year = 2012)
# ==============================================================================
cat("\n  --- R2: Post-2011 Subsample ---\n")

tryCatch({
  df_post2011 <- df %>% filter(
    date >= as.Date("2012-01-01"),
    complete.cases(dlnCPI, !!sym(lag_col), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

  if (nrow(df_post2011) >= 60) {
    m_post2011  <- safe_lm(f_m1, data = df_post2011)
    nw_post2011 <- NeweyWest(m_post2011, lag = nw_lag(nrow(df_post2011)), prewhite = FALSE)
    cpt_post2011 <- compute_cpt(m_post2011,
      paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
      nw_post2011, "Post2011: ")

    cat(sprintf("  Post-2011: N=%d | CPT+= %.4f (p=%s) | Asym p = %s\n",
        nrow(df_post2011), cpt_post2011$cpt_pos,
        format_p(cpt_post2011$pos_test$p_value),
        format_p(cpt_post2011$asym_test$p_value)))

    robustness_rows[["Post2011"]] <- data.frame(
      Check = "Post-2011 subsample", N = nrow(df_post2011),
      CPT_pos = round(cpt_post2011$cpt_pos, 6), CPT_neg = round(cpt_post2011$cpt_neg, 6),
      Asym_p = round(cpt_post2011$asym_test$p_value, 4),
      stringsAsFactors = FALSE)

    subsample_rows[["Post2011"]] <- data.frame(
      Period = "Post-2011 subsample", N = nrow(df_post2011),
      CPT_pos = round(cpt_post2011$cpt_pos, 6), CPT_neg = round(cpt_post2011$cpt_neg, 6),
      CPTpos_p = round(cpt_post2011$pos_test$p_value, 4),
      CPTneg_p = round(cpt_post2011$neg_test$p_value, 4),
      Asym_p = round(cpt_post2011$asym_test$p_value, 4),
      stringsAsFactors = FALSE)
  }
}, error = function(e) cat(sprintf("  Post-2011 error: %s\n", e$message)))

# ==============================================================================
# R3: Pre/Post October 2014 (diesel deregulation)
# ==============================================================================
cat("\n  --- R3: Pre/Post 2014 Subsamples ---\n")

for (regime in c("pre", "post")) {
  tryCatch({
    if (regime == "pre") {
      df_sub <- df %>% filter(date < DATE_DIESEL_DEREG,
        complete.cases(dlnCPI, !!sym(lag_col), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
    } else {
      df_sub <- df %>% filter(date >= DATE_DIESEL_DEREG,
        complete.cases(dlnCPI, !!sym(lag_col), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
    }

    if (nrow(df_sub) >= 40) {
      m_sub  <- safe_lm(f_m1, data = df_sub)
      nw_sub <- NeweyWest(m_sub, lag = nw_lag(nrow(df_sub)), prewhite = FALSE)
      cpt_sub <- compute_cpt(m_sub,
        paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
        nw_sub, paste0(regime, "2014: "))

      label <- if (regime == "pre") "Pre-Oct 2014" else "Post-Oct 2014"
      cat(sprintf("  %s: N=%d | CPT+= %.4f (p=%s) | Asym p = %s\n",
          label, nrow(df_sub), cpt_sub$cpt_pos,
          format_p(cpt_sub$pos_test$p_value),
          format_p(cpt_sub$asym_test$p_value)))

      robustness_rows[[paste0("Regime_", regime)]] <- data.frame(
        Check = label, N = nrow(df_sub),
        CPT_pos = round(cpt_sub$cpt_pos, 6), CPT_neg = round(cpt_sub$cpt_neg, 6),
        Asym_p = round(cpt_sub$asym_test$p_value, 4),
        stringsAsFactors = FALSE)

      subsample_rows[[paste0("Regime_", regime)]] <- data.frame(
        Period = label, N = nrow(df_sub),
        CPT_pos = round(cpt_sub$cpt_pos, 6), CPT_neg = round(cpt_sub$cpt_neg, 6),
        CPTpos_p = round(cpt_sub$pos_test$p_value, 4),
        CPTneg_p = round(cpt_sub$neg_test$p_value, 4),
        Asym_p = round(cpt_sub$asym_test$p_value, 4),
        stringsAsFactors = FALSE)
    }
  }, error = function(e) cat(sprintf("  %s-2014 error: %s\n", regime, e$message)))
}

# ==============================================================================
# R4: COVID sensitivity
# ==============================================================================
cat("\n  --- R4: COVID Sensitivity ---\n")

tryCatch({
  # Without COVID dummy
  f_nocovid <- update(f_m1, . ~ . - D_covid)
  m_nocovid  <- safe_lm(f_nocovid, data = df_m1)
  nw_nocovid <- NeweyWest(m_nocovid, lag = nw_lag(nrow(df_m1)), prewhite = FALSE)
  cpt_nocovid <- compute_cpt(m_nocovid,
    paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
    nw_nocovid, "NoCOVID: ")

  # Excluding COVID months entirely
  df_excl <- df_m1 %>% filter(!(date >= as.Date("2020-03-01") & date <= as.Date("2020-06-01")))
  m_excl  <- safe_lm(f_m1, data = df_excl)
  nw_excl <- NeweyWest(m_excl, lag = nw_lag(nrow(df_excl)), prewhite = FALSE)
  cpt_excl <- compute_cpt(m_excl,
    paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
    nw_excl, "ExclCOVID: ")

  covid_tbl <- data.frame(
    Variant = c("M1 with D_covid", "M1 without D_covid", "M1 excl Mar-Jun 2020"),
    N = c(nrow(df_m1), nrow(df_m1), nrow(df_excl)),
    CPT_pos = round(c(cpt_m1$cpt_pos, cpt_nocovid$cpt_pos, cpt_excl$cpt_pos), 6),
    CPT_neg = round(c(cpt_m1$cpt_neg, cpt_nocovid$cpt_neg, cpt_excl$cpt_neg), 6),
    Asym_p = round(c(cpt_m1$asym_test$p_value, cpt_nocovid$asym_test$p_value,
                     cpt_excl$asym_test$p_value), 4),
    stringsAsFactors = FALSE)
  save_table(covid_tbl, "table_18_covid_sensitivity.csv")
  print(covid_tbl)

  robustness_rows[["COVID_no"]] <- data.frame(
    Check = "No COVID dummy", N = nrow(df_m1),
    CPT_pos = round(cpt_nocovid$cpt_pos, 6), CPT_neg = round(cpt_nocovid$cpt_neg, 6),
    Asym_p = round(cpt_nocovid$asym_test$p_value, 4),
    stringsAsFactors = FALSE)
}, error = function(e) cat(sprintf("  COVID sensitivity error: %s\n", e$message)))

# ==============================================================================
# R5: Winsorized (1%) sensitivity
# ==============================================================================
cat("\n  --- R5: Winsorized (1%) Sensitivity ---\n")

tryCatch({
  winsorize <- function(x, p = 0.01) {
    q <- quantile(x, probs = c(p, 1 - p), na.rm = TRUE)
    pmin(pmax(x, q[1]), q[2])
  }

  df_w <- df_m1
  for (v in c("dlnCPI", "dlnOil_pos_L0", "dlnOil_neg_L0")) {
    if (v %in% names(df_w)) df_w[[v]] <- winsorize(df_w[[v]])
  }

  m_win  <- lm(f_m1, data = df_w)
  nw_win <- NeweyWest(m_win, lag = nw_lag(nrow(df_w)), prewhite = FALSE)
  cpt_win <- compute_cpt(m_win,
    paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
    nw_win, "Winsor: ")

  cat(sprintf("  Winsorized: CPT+= %.4f (p=%s) | Asym p = %s\n",
      cpt_win$cpt_pos, format_p(cpt_win$pos_test$p_value),
      format_p(cpt_win$asym_test$p_value)))

  win_tbl <- data.frame(
    Variant = c("M1 baseline", "M1 winsorized (1%)"),
    CPT_pos = round(c(cpt_m1$cpt_pos, cpt_win$cpt_pos), 6),
    CPT_neg = round(c(cpt_m1$cpt_neg, cpt_win$cpt_neg), 6),
    Asym_p = round(c(cpt_m1$asym_test$p_value, cpt_win$asym_test$p_value), 4),
    stringsAsFactors = FALSE)
  save_table(win_tbl, "table_19_winsorized.csv")

  robustness_rows[["Winsorized"]] <- data.frame(
    Check = "Winsorized (1%)", N = nrow(df_w),
    CPT_pos = round(cpt_win$cpt_pos, 6), CPT_neg = round(cpt_win$cpt_neg, 6),
    Asym_p = round(cpt_win$asym_test$p_value, 4),
    stringsAsFactors = FALSE)
}, error = function(e) cat(sprintf("  Winsorized error: %s\n", e$message)))

# ==============================================================================
# R6: Rolling-window (60-month) CPT series
# ==============================================================================
cat("\n  --- R6: Rolling Window (60-month) ---\n")

tryCatch({
  window_size <- 60
  df_roll <- df %>% filter(complete.cases(
    dlnCPI, !!sym(lag_col), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

  n_roll <- nrow(df_roll)
  if (n_roll >= window_size + 20) {
    roll_results <- list()
    for (i in 1:(n_roll - window_size + 1)) {
      df_win <- df_roll[i:(i + window_size - 1), ]
      tryCatch({
        m_w  <- safe_lm(f_m1, data = df_win)
        nw_w <- NeweyWest(m_w, lag = nw_lag(window_size), prewhite = FALSE)
        cpt_w <- compute_cpt(m_w,
          paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
          nw_w, "")
        roll_results[[length(roll_results) + 1]] <- data.frame(
          date    = df_win$date[window_size],
          CPT_pos = cpt_w$cpt_pos,
          CPT_neg = cpt_w$cpt_neg,
          Asym_p  = cpt_w$asym_test$p_value,
          stringsAsFactors = FALSE)
      }, error = function(e) NULL)

      if (i %% 50 == 0) cat(sprintf("      ... window %d/%d\n", i, n_roll - window_size + 1))
    }

    if (length(roll_results) > 0) {
      roll_df <- bind_rows(roll_results)
      save_table(roll_df, "rolling_window_data.csv")
      cat(sprintf("  Rolling window: %d windows computed\n", nrow(roll_df)))
    }
  } else {
    cat(sprintf("  Rolling window: insufficient data (N=%d, need >=%d)\n",
        n_roll, window_size + 20))
  }
}, error = function(e) cat(sprintf("  Rolling window error: %s\n", e$message)))

# ==============================================================================
# R7: Lag grid sensitivity (p=1..4, q=0..3)
# ==============================================================================
cat("\n  --- R7: Lag Grid Sensitivity ---\n")

tryCatch({
  df_grid <- df %>% filter(complete.cases(
    dlnCPI, dlnCPI_L1, dlnCPI_L2, dlnCPI_L3, dlnCPI_L4,
    dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

  lag_grid <- list()
  for (p in 1:4) {
    for (q in 0:3) {
      ar <- paste0("dlnCPI_L", 1:p, collapse = " + ")
      oil_pos <- paste0("dlnOil_pos_L", 0:q, collapse = " + ")
      oil_neg <- paste0("dlnOil_neg_L", 0:q, collapse = " + ")
      f <- as.formula(paste0("dlnCPI ~ ", ar, " + ", oil_pos, " + ", oil_neg,
        " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms_str))

      m_g  <- lm(f, data = df_grid)
      nw_g <- NeweyWest(m_g, lag = nw_lag(nrow(df_grid)), prewhite = FALSE)

      pos_names_g <- paste0("dlnOil_pos_L", 0:q)
      neg_names_g <- paste0("dlnOil_neg_L", 0:q)
      cpt_g <- compute_cpt(m_g, pos_names_g, neg_names_g, nw_g, "")

      lag_grid[[length(lag_grid) + 1]] <- data.frame(
        p = p, q = q, N = nrow(df_grid),
        AIC = round(AIC(m_g), 2),
        Adj_R2 = round(summary(m_g)$adj.r.squared, 4),
        CPT_pos = round(cpt_g$cpt_pos, 6),
        CPT_neg = round(cpt_g$cpt_neg, 6),
        Asym_p = round(cpt_g$asym_test$p_value, 4),
        stringsAsFactors = FALSE)
    }
  }

  lag_grid_df <- bind_rows(lag_grid)
  save_table(lag_grid_df, "table_20_lag_sensitivity.csv")
  cat("  Lag grid (p x q):\n")
  print(lag_grid_df[, c("p", "q", "AIC", "CPT_pos", "Asym_p")])
}, error = function(e) cat(sprintf("  Lag grid error: %s\n", e$message)))

if (length(subsample_rows) > 0) {
  subsample_tbl <- bind_rows(subsample_rows)
  save_table(subsample_tbl, "table_17_subsample.csv")
}

# ==============================================================================
# Robustness summary table
# ==============================================================================
if (length(robustness_rows) > 0) {
  # Add M1 baseline for comparison
  robustness_rows[["M1_baseline"]] <- data.frame(
    Check = "M1 baseline (headline)", N = nrow(df_m1),
    CPT_pos = round(cpt_m1$cpt_pos, 6), CPT_neg = round(cpt_m1$cpt_neg, 6),
    Asym_p = round(cpt_m1$asym_test$p_value, 4),
    stringsAsFactors = FALSE)

  rob_summary <- bind_rows(robustness_rows) %>%
    mutate(
      Note = dplyr::case_when(
        Check == "NOPI (Hamilton)" ~ "Sensitivity only; alternative oil-shock construction",
        Check == "Post-2011 subsample" ~ "Addresses reconstructed pre-2011 CPI continuity concern",
        Check == "Pre-Oct 2014" ~ "Pre-diesel deregulation period",
        Check == "Post-Oct 2014" ~ "Post-diesel deregulation period",
        Check == "No COVID dummy" ~ "Checks April 2020 outlier sensitivity",
        Check == "Winsorized (1%)" ~ "Checks sensitivity to extreme monthly oil shocks",
        Check == "M1 baseline (headline)" ~ "Reference model for all headline robustness checks",
        TRUE ~ ""
      )
    )
  save_table(rob_summary, "table_21_robustness_summary.csv")
  cat("\n  === ROBUSTNESS SUMMARY ===\n")
  print(rob_summary)
}

cat("  [10_robustness] Done.\n")
