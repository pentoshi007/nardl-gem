# ══════════════════════════════════════════════════════════════════════════════
# 05_nardl.R — NARDL estimation, bounds test, long-run Wald, multiplier plot
# ══════════════════════════════════════════════════════════════════════════════
banner("5", "NARDL (Shin, Yu & Greenwood-Nimmo 2014)")

# ── Prepare NARDL data ──────────────────────────────────────────────────────
# NARDL works on levels: lnCPI as dependent, lnOil (or lnBrent + lnEXR) as regressors
# Also include lnIIP as a control variable
# The nardl package handles decomposition and lag selection internally

df_nardl <- df %>%
  select(date, ln_cpi, ln_oil, ln_brent, ln_exr, ln_iip) %>%
  filter(complete.cases(.))

cat(sprintf("  NARDL sample: %s to %s (N = %d)\n",
    min(df_nardl$date), max(df_nardl$date), nrow(df_nardl)))

# ── Helper: extract ECT coefficient properly from nardl object ────────────────
# nardl$tcoin is the t-statistic for the cointegration test (t-BDM), NOT the
# ECT coefficient itself. The ECT coefficient (speed of adjustment, rho) is the
# coefficient on the lagged dependent variable in the underlying ARDL regression.
# In the nardl package, the dependent variable's first lag (e.g. ln_cpi_1) is
# always the second row in sels$coefficients (right after the intercept).
extract_ect_coef <- function(nardl_obj) {
  sr <- nardl_obj$sels$coefficients
  # The dep var's lag is always the 2nd coefficient (after Const)
  # Verify: it should contain the dep var name
  ect_coef <- sr[2, 1]
  ect_name <- rownames(sr)[2]
  cat(sprintf("    (ECT extracted from '%s' = %.6f)\n", ect_name, ect_coef))
  ect_coef
}

# ── Pesaran et al. (2001) asymptotic critical bounds (Case III: unrestricted
#    intercept, no trend). Approximate values for common k at 5% and 10%.
pesaran_bounds <- function(k) {
  bounds_table <- list(
    "1" = list(pct10 = c(I0 = 3.02, I1 = 3.51), pct5 = c(I0 = 3.62, I1 = 4.16)),
    "2" = list(pct10 = c(I0 = 2.63, I1 = 3.35), pct5 = c(I0 = 3.10, I1 = 3.87)),
    "3" = list(pct10 = c(I0 = 2.37, I1 = 3.20), pct5 = c(I0 = 2.79, I1 = 3.67)),
    "4" = list(pct10 = c(I0 = 2.20, I1 = 3.09), pct5 = c(I0 = 2.56, I1 = 3.49))
  )
  k_str <- as.character(min(k, 4))
  bounds_table[[k_str]]
}

# ══════════════════════════════════════════════════════════════════════════════
# NARDL A: ln(CPI) ~ ln(Oil_INR) | ln(IIP)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- NARDL-A: lnCPI ~ lnOil_INR | lnIIP ---\n")
nardl_a <- tryCatch({
  nardl(ln_cpi ~ ln_oil | ln_iip, data = df_nardl, ic = "aic", maxlag = 4,
        graph = FALSE, case = 3)
}, error = function(e) {
  cat(sprintf("    ERROR: %s\n", e$message))
  NULL
})

if (!is.null(nardl_a)) {
  # ECT coefficient (speed of adjustment) — must be NEGATIVE for valid ECM
  ect_coef_a <- extract_ect_coef(nardl_a)
  # t-statistic on the ECT (from the short-run regression table)
  ect_tstat_a <- nardl_a$sels$coefficients[2, 3]

  cat(sprintf("  Bounds test F-stat: %.4f\n", nardl_a$fstat))
  cat(sprintf("  ECT coefficient (rho): %.6f  [must be negative]\n", ect_coef_a))
  cat(sprintf("  ECT t-statistic: %.4f (p=%.4f)\n", ect_tstat_a, nardl_a$sels$coefficients[2, 4]))

  # Pesaran bounds comparison (k = number of regressors in long-run eq excl. dep var)
  k_a <- length(nardl_a$coof) - 1
  bounds_a <- pesaran_bounds(k_a)
  cat(sprintf("  Pesaran bounds (k=%d): 5%% [%.2f, %.2f], 10%% [%.2f, %.2f]\n",
      k_a, bounds_a$pct5["I0"], bounds_a$pct5["I1"],
      bounds_a$pct10["I0"], bounds_a$pct10["I1"]))
  if (nardl_a$fstat > bounds_a$pct5["I1"]) {
    cat("  => F exceeds upper bound at 5% => COINTEGRATION\n")
    bounds_verdict_a <- "Cointegration (F > I(1) at 5%)"
  } else if (nardl_a$fstat > bounds_a$pct10["I1"]) {
    cat("  => F exceeds upper bound at 10% => COINTEGRATION (marginal)\n")
    bounds_verdict_a <- "Cointegration (F > I(1) at 10%)"
  } else if (nardl_a$fstat > bounds_a$pct5["I0"]) {
    cat("  => F in inconclusive zone\n")
    bounds_verdict_a <- "Inconclusive"
  } else {
    cat("  => F below lower bound => NO cointegration\n")
    bounds_verdict_a <- "No cointegration"
  }

  if (ect_coef_a >= 0) {
    cat("  WARNING: ECT coefficient is non-negative — error correction invalid.\n")
    cat("  Long-run Wald results should be interpreted with caution.\n")
  }

  lr_a <- nardl_a$lres
  cat("  Long-run coefficients:\n")
  print(lr_a)

  cat(sprintf("  Short-run Wald: W=%.4f, p=%s\n",
      nardl_a$wldsr[1, 1], format_p(nardl_a$wldsr[1, 2])))
  cat(sprintf("  Long-run Wald:  W=%.4f, p=%s\n",
      nardl_a$wldq[1, 1], format_p(nardl_a$wldq[1, 2])))

  nardl_a_out <- data.frame(
    Specification = "lnCPI ~ lnOil_INR | lnIIP",
    N = nardl_a$Nobs,
    Bounds_F = round(nardl_a$fstat, 4),
    ECT_coef = round(ect_coef_a, 6),
    ECT_tstat = round(ect_tstat_a, 4),
    ECT_valid = ifelse(ect_coef_a < 0, "Yes (negative)", "NO (positive — invalid ECM)"),
    Bounds_verdict = bounds_verdict_a,
    LR_Wald_stat = round(nardl_a$wldq[1, 1], 4),
    LR_Wald_p = round(nardl_a$wldq[1, 2], 6),
    SR_Wald_stat = round(nardl_a$wldsr[1, 1], 4),
    SR_Wald_p = round(nardl_a$wldsr[1, 2], 6),
    stringsAsFactors = FALSE
  )

  lr_a_df <- data.frame(
    Specification = "NARDL-A (Oil INR)",
    Coefficient = rownames(lr_a),
    Estimate = round(lr_a[, 1], 6),
    SE = round(lr_a[, 2], 6),
    t_value = round(lr_a[, 3], 4),
    p_value = round(lr_a[, 4], 4),
    Sig = sig_stars(lr_a[, 4]),
    row.names = NULL
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# NARDL B: ln(CPI) ~ ln(Brent) | ln(EXR) + ln(IIP)
# Note: nardl package only supports one decomposed variable. We decompose
# lnBrent and include lnEXR as a fixed (non-decomposed) regressor.
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- NARDL-B: lnCPI ~ lnBrent | lnEXR + lnIIP ---\n")
cat("  (lnBrent decomposed; lnEXR as fixed regressor)\n")
nardl_b <- tryCatch({
  nardl(ln_cpi ~ ln_brent | ln_exr + ln_iip, data = df_nardl, ic = "aic", maxlag = 4,
        graph = FALSE, case = 3)
}, error = function(e) {
  cat(sprintf("    ERROR: %s\n", e$message))
  NULL
})

if (!is.null(nardl_b)) {
  ect_coef_b <- extract_ect_coef(nardl_b)
  ect_tstat_b <- nardl_b$sels$coefficients[2, 3]

  cat(sprintf("  Bounds test F-stat: %.4f\n", nardl_b$fstat))
  cat(sprintf("  ECT coefficient (rho): %.6f  [must be negative]\n", ect_coef_b))
  cat(sprintf("  ECT t-statistic: %.4f (p=%.4f)\n", ect_tstat_b, nardl_b$sels$coefficients[2, 4]))

  k_b <- length(nardl_b$coof) - 1
  bounds_b <- pesaran_bounds(k_b)
  cat(sprintf("  Pesaran bounds (k=%d): 5%% [%.2f, %.2f], 10%% [%.2f, %.2f]\n",
      k_b, bounds_b$pct5["I0"], bounds_b$pct5["I1"],
      bounds_b$pct10["I0"], bounds_b$pct10["I1"]))
  if (nardl_b$fstat > bounds_b$pct5["I1"]) {
    bounds_verdict_b <- "Cointegration (F > I(1) at 5%)"
  } else if (nardl_b$fstat > bounds_b$pct10["I1"]) {
    bounds_verdict_b <- "Cointegration (F > I(1) at 10%)"
  } else if (nardl_b$fstat > bounds_b$pct5["I0"]) {
    bounds_verdict_b <- "Inconclusive"
  } else {
    bounds_verdict_b <- "No cointegration"
  }
  cat(sprintf("  => %s\n", bounds_verdict_b))

  if (ect_coef_b >= 0) {
    cat("  WARNING: ECT coefficient is non-negative — error correction invalid.\n")
  }

  lr_b <- nardl_b$lres
  cat("  Long-run coefficients:\n")
  print(lr_b)

  cat(sprintf("  Short-run Wald: W=%.4f, p=%s\n",
      nardl_b$wldsr[1, 1], format_p(nardl_b$wldsr[1, 2])))
  cat(sprintf("  Long-run Wald:  W=%.4f, p=%s\n",
      nardl_b$wldq[1, 1], format_p(nardl_b$wldq[1, 2])))

  nardl_b_out <- data.frame(
    Specification = "lnCPI ~ lnBrent | lnEXR + lnIIP",
    N = nardl_b$Nobs,
    Bounds_F = round(nardl_b$fstat, 4),
    ECT_coef = round(ect_coef_b, 6),
    ECT_tstat = round(ect_tstat_b, 4),
    ECT_valid = ifelse(ect_coef_b < 0, "Yes (negative)", "NO (positive — invalid ECM)"),
    Bounds_verdict = bounds_verdict_b,
    LR_Wald_stat = round(nardl_b$wldq[1, 1], 4),
    LR_Wald_p = round(nardl_b$wldq[1, 2], 6),
    SR_Wald_stat = round(nardl_b$wldsr[1, 1], 4),
    SR_Wald_p = round(nardl_b$wldsr[1, 2], 6),
    stringsAsFactors = FALSE
  )

  lr_b_df <- data.frame(
    Specification = "NARDL-B (Brent | EXR + IIP)",
    Coefficient = rownames(lr_b),
    Estimate = round(lr_b[, 1], 6),
    SE = round(lr_b[, 2], 6),
    t_value = round(lr_b[, 3], 4),
    p_value = round(lr_b[, 4], 4),
    Sig = sig_stars(lr_b[, 4]),
    row.names = NULL
  )
}

# ── Save combined NARDL tables ───────────────────────────────────────────────
nardl_summary <- bind_rows(
  if (exists("nardl_a_out")) nardl_a_out,
  if (exists("nardl_b_out")) nardl_b_out
)
if (nrow(nardl_summary) > 0) {
  save_table(nardl_summary, "table_11_nardl_bounds_test.csv")
}

nardl_lr <- bind_rows(
  if (exists("lr_a_df")) lr_a_df,
  if (exists("lr_b_df")) lr_b_df
)
if (nrow(nardl_lr) > 0) {
  save_table(nardl_lr, "table_12_nardl_long_run.csv")
}

# ── Short-run coefficients table ─────────────────────────────────────────────
# nardl$sels is already a summary.lm object — access $coefficients directly
nardl_sr_list <- list()
if (!is.null(nardl_a)) {
  tryCatch({
    sr_coefs_a <- nardl_a$sels$coefficients
    nardl_sr_list[["NARDL-A"]] <- data.frame(
      Specification = "NARDL-A (Oil INR)",
      Variable = rownames(sr_coefs_a),
      Estimate = round(sr_coefs_a[, 1], 6),
      SE = round(sr_coefs_a[, 2], 6),
      t_value = round(sr_coefs_a[, 3], 4),
      p_value = round(sr_coefs_a[, 4], 4),
      Sig = sig_stars(sr_coefs_a[, 4]),
      row.names = NULL
    )
  }, error = function(e) cat(sprintf("  NARDL-A SR table error: %s\n", e$message)))
}
if (!is.null(nardl_b)) {
  tryCatch({
    sr_coefs_b <- nardl_b$sels$coefficients
    nardl_sr_list[["NARDL-B"]] <- data.frame(
      Specification = "NARDL-B (Brent | EXR + IIP)",
      Variable = rownames(sr_coefs_b),
      Estimate = round(sr_coefs_b[, 1], 6),
      SE = round(sr_coefs_b[, 2], 6),
      t_value = round(sr_coefs_b[, 3], 4),
      p_value = round(sr_coefs_b[, 4], 4),
      Sig = sig_stars(sr_coefs_b[, 4]),
      row.names = NULL
    )
  }, error = function(e) cat(sprintf("  NARDL-B SR table error: %s\n", e$message)))
}
if (length(nardl_sr_list) > 0) {
  save_table(bind_rows(nardl_sr_list), "table_13_nardl_short_run.csv")
}

# ── Dynamic multiplier plot (NARDL-A) ───────────────────────────────────────
if (!is.null(nardl_a)) {
  cat("\n  Generating dynamic multiplier plot (NARDL-A)...\n")
  tryCatch({
    sr_coefs <- nardl_a$sels$coefficients[, 1]

    # ECT = coefficient on lagged dependent variable (speed of adjustment)
    ect_coef <- extract_ect_coef(nardl_a)

    # Long-run coefficients for positive and negative
    lr_coefs <- nardl_a$coof
    lr_pos <- sum(lr_coefs[grepl("_p", names(lr_coefs))])
    lr_neg <- sum(lr_coefs[grepl("_n", names(lr_coefs))])

    # Short-run impact coefficients (contemporaneous positive and negative)
    sr_pos_names <- names(sr_coefs)[grepl("_p$|_p_", names(sr_coefs)) & !grepl("^l", names(sr_coefs))]
    sr_neg_names <- names(sr_coefs)[grepl("_n$|_n_", names(sr_coefs)) & !grepl("^l", names(sr_coefs))]

    # If no short-run contemporaneous, use all _p and _n
    if (length(sr_pos_names) == 0) sr_pos_names <- names(sr_coefs)[grepl("_p", names(sr_coefs))]
    if (length(sr_neg_names) == 0) sr_neg_names <- names(sr_coefs)[grepl("_n", names(sr_coefs))]

    impact_pos <- sum(sr_coefs[sr_pos_names])
    impact_neg <- sum(sr_coefs[sr_neg_names])

    # Dynamic multiplier path: converge from impact to long-run
    H <- 24
    mult_pos <- numeric(H + 1)
    mult_neg <- numeric(H + 1)
    mult_pos[1] <- impact_pos
    mult_neg[1] <- impact_neg

    for (h in 1:H) {
      mult_pos[h + 1] <- lr_pos + (impact_pos - lr_pos) * (1 + ect_coef)^h
      mult_neg[h + 1] <- lr_neg + (impact_neg - lr_neg) * (1 + ect_coef)^h
    }

    mult_df <- data.frame(
      Horizon = rep(0:H, 3),
      Value = c(mult_pos, mult_neg, mult_pos - mult_neg),
      Type = rep(c("Positive shock (theta+)", "Negative shock (theta-)", "Asymmetry (diff)"),
                 each = H + 1)
    )

    fig_nardl <- ggplot(mult_df, aes(x = Horizon, y = Value, color = Type, linetype = Type)) +
      geom_line(linewidth = 1) +
      geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
      scale_color_manual(values = c(
        "Positive shock (theta+)" = "#C0392B",
        "Negative shock (theta-)" = "#2980B9",
        "Asymmetry (diff)" = "#27AE60")) +
      scale_linetype_manual(values = c(
        "Positive shock (theta+)" = "solid",
        "Negative shock (theta-)" = "solid",
        "Asymmetry (diff)" = "dashed")) +
      labs(title = "Figure: NARDL Dynamic Multipliers (lnCPI ~ lnOil_INR)",
           subtitle = sprintf("Bounds F = %.2f | LR Wald p = %s | ECT coef = %.4f",
                              nardl_a$fstat, format_p(nardl_a$wldq[1, 2]), ect_coef_a),
           x = "Horizon (months)", y = "Multiplier", color = NULL, linetype = NULL) +
      theme_minimal(base_size = 10) + theme(legend.position = "bottom")
    ggsave(save_figure("fig_nardl_dynamic_multiplier.png"), fig_nardl,
           width = 9, height = 5.5, dpi = 300)
    cat("  Dynamic multiplier plot saved.\n")
  }, error = function(e) {
    cat(sprintf("  Dynamic multiplier plot failed: %s\n", e$message))
  })
}

# Store for later use
assign("nardl_a", nardl_a, envir = .GlobalEnv)
assign("nardl_b", nardl_b, envir = .GlobalEnv)

cat("  [05_nardl] Done.\n")
