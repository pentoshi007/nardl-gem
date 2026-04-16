# ══════════════════════════════════════════════════════════════════════════════
# 05_nardl.R — NARDL: APPENDIX-ONLY EXPLORATORY ANALYSIS
#
# IMPORTANT: This section is APPENDIX-ONLY and EXPLORATORY.
# Both NARDL specifications (A and B) yield positive ECT coefficients,
# which is inconsistent with a valid error-correction mechanism (ECM requires
# ECT < 0 for mean-reversion). Per Shin, Yu & Greenwood-Nimmo (2014) and
# standard ARDL theory, a positive ECT implies divergence from equilibrium,
# rendering the long-run cointegration interpretation unreliable.
#
# We retain these results for completeness and transparency, clearly labelled
# as exploratory. The dynamic multiplier analysis is suppressed when ECT > 0
# (Pesaran, Shin & Smith 2001; Granger & Lee 1989).
#
# The primary results of this paper are the short-run asymmetric ADL models
# M1–M3 in 04_models.R and their robustness checks in 07_robustness.R.
# ══════════════════════════════════════════════════════════════════════════════
banner("5", "NARDL — APPENDIX EXPLORATORY (Shin et al. 2014)")

cat("\n  *** APPENDIX SECTION — EXPLORATORY ONLY ***\n")
cat("  ECT sign will be checked. If ECT >= 0, cointegration claims are invalid.\n")
cat("  Dynamic multipliers are suppressed for any model with ECT >= 0.\n\n")

# ── Prepare NARDL data ──────────────────────────────────────────────────────
df_nardl <- df %>%
  select(date, ln_cpi, ln_oil, ln_brent, ln_exr, ln_iip) %>%
  filter(complete.cases(.))

cat(sprintf("  NARDL sample: %s to %s (N = %d)\n",
    min(df_nardl$date), max(df_nardl$date), nrow(df_nardl)))

# ── Helper: extract ECT coefficient from nardl object ─────────────────────
# The ECT coefficient (speed of adjustment, rho) is the coefficient on the
# lagged dependent variable in the short-run ECM regression.
# In the nardl package, it is the second row of sels$coefficients
# (after the intercept). Must be NEGATIVE for a valid ECM.
extract_ect_coef <- function(nardl_obj) {
  sr   <- nardl_obj$sels$coefficients
  coef <- sr[2, 1]
  name <- rownames(sr)[2]
  cat(sprintf("    ECT extracted from '%s' = %.6f\n", name, coef))
  coef
}

# ── Pesaran, Shin & Smith (2001) / Narayan (2005) critical bounds ──────────
# Case III: unrestricted intercept, no trend.
# Values sourced from:
#   - PSS (2001) Table CI(iii) for asymptotic bounds (large T)
#   - Narayan (2005) for small-sample bounds (T ≈ 250, closest available)
# For k > 5 the PSS table is not published; we use interpolated Narayan values.
# k = number of long-run forcing variables (excl. dependent variable).
pesaran_bounds <- function(k, n = NULL) {
  # Asymptotic bounds (Pesaran et al. 2001, Table CI(iii))
  asymptotic <- list(
    "1"  = list(pct10 = c(I0 = 3.02, I1 = 3.51), pct5 = c(I0 = 3.62, I1 = 4.16), pct1 = c(I0 = 5.04, I1 = 5.73)),
    "2"  = list(pct10 = c(I0 = 2.63, I1 = 3.35), pct5 = c(I0 = 3.10, I1 = 3.87), pct1 = c(I0 = 4.13, I1 = 5.00)),
    "3"  = list(pct10 = c(I0 = 2.37, I1 = 3.20), pct5 = c(I0 = 2.79, I1 = 3.67), pct1 = c(I0 = 3.65, I1 = 4.66)),
    "4"  = list(pct10 = c(I0 = 2.20, I1 = 3.09), pct5 = c(I0 = 2.56, I1 = 3.49), pct1 = c(I0 = 3.27, I1 = 4.30)),
    "5"  = list(pct10 = c(I0 = 2.08, I1 = 3.00), pct5 = c(I0 = 2.39, I1 = 3.38), pct1 = c(I0 = 3.03, I1 = 4.06)),
    # For k > 5 use Narayan (2005) interpolated small-sample bounds (T ≈ 250)
    "6"  = list(pct10 = c(I0 = 2.03, I1 = 2.94), pct5 = c(I0 = 2.32, I1 = 3.28), pct1 = c(I0 = 2.90, I1 = 3.96)),
    "7"  = list(pct10 = c(I0 = 1.99, I1 = 2.89), pct5 = c(I0 = 2.27, I1 = 3.28), pct1 = c(I0 = 2.76, I1 = 3.82)),
    "8"  = list(pct10 = c(I0 = 1.95, I1 = 2.86), pct5 = c(I0 = 2.22, I1 = 3.23), pct1 = c(I0 = 2.69, I1 = 3.78)),
    "9"  = list(pct10 = c(I0 = 1.93, I1 = 2.82), pct5 = c(I0 = 2.17, I1 = 3.19), pct1 = c(I0 = 2.60, I1 = 3.73)),
    "10" = list(pct10 = c(I0 = 1.90, I1 = 2.80), pct5 = c(I0 = 2.14, I1 = 3.15), pct1 = c(I0 = 2.55, I1 = 3.68))
  )
  k_use <- min(k, 10)
  if (k > 10) cat(sprintf("    WARNING: k=%d exceeds table; using k=10 bounds (conservative)\n", k))
  b <- asymptotic[[as.character(k_use)]]
  b$k_actual  <- k
  b$k_used    <- k_use
  b$source    <- ifelse(k_use <= 5, "Pesaran et al. (2001) asymptotic",
                                    "Narayan (2005) small-sample (T≈250)")
  b
}

# ── Helper: bounds test verdict ────────────────────────────────────────────
bounds_verdict <- function(fstat, bounds) {
  if      (fstat > bounds$pct5["I1"])  "Cointegration (F > I(1) at 5%)"
  else if (fstat > bounds$pct10["I1"]) "Cointegration (F > I(1) at 10%)"
  else if (fstat > bounds$pct5["I0"])  "Inconclusive (F in band at 5%)"
  else                                  "No cointegration (F < I(0) at 10%)"
}

# ══════════════════════════════════════════════════════════════════════════════
# NARDL A: ln(CPI) ~ ln(Oil_INR) | ln(IIP)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- NARDL-A: lnCPI ~ lnOil_INR | lnIIP ---\n")
nardl_a <- tryCatch({
  nardl(ln_cpi ~ ln_oil | ln_iip, data = df_nardl, ic = "aic", maxlag = 4,
        graph = FALSE, case = 3)
}, error = function(e) {
  cat(sprintf("    ERROR: %s\n", e$message)); NULL
})

nardl_a_out  <- NULL
lr_a_df      <- NULL
nardl_a_valid <- FALSE

if (!is.null(nardl_a)) {
  ect_coef_a  <- extract_ect_coef(nardl_a)
  ect_tstat_a <- nardl_a$sels$coefficients[2, 3]
  ect_pval_a  <- nardl_a$sels$coefficients[2, 4]

  cat(sprintf("  Bounds test F-stat: %.4f\n", nardl_a$fstat))
  cat(sprintf("  ECT coefficient (rho): %.6f  [MUST be < 0 for valid ECM]\n", ect_coef_a))
  cat(sprintf("  ECT t-statistic: %.4f  (p = %.4f)\n", ect_tstat_a, ect_pval_a))

  # Correct k: number of long-run regressors excluding dependent var
  # nardl decomposes ln_oil into ln_oil_p and ln_oil_n for the cointegration test,
  # so k = 3 (oil+, oil-, iip) for the bounds test regression
  k_a     <- length(nardl_a$coof) - 1  # from package
  bounds_a <- pesaran_bounds(k_a, n = nrow(df_nardl))
  cat(sprintf("  k = %d | Bounds source: %s\n", k_a, bounds_a$source))
  cat(sprintf("  5%%  bounds: [%.2f, %.2f]   10%% bounds: [%.2f, %.2f]\n",
      bounds_a$pct5["I0"], bounds_a$pct5["I1"],
      bounds_a$pct10["I0"], bounds_a$pct10["I1"]))

  verdict_a <- bounds_verdict(nardl_a$fstat, bounds_a)
  cat(sprintf("  => %s\n", verdict_a))

  if (ect_coef_a >= 0) {
    cat("  *** CRITICAL: ECT >= 0 — Error correction is INVALID. ***\n")
    cat("  *** Long-run Wald and cointegration interpretations are unreliable. ***\n")
    cat("  *** This model is retained for transparency as APPENDIX ONLY. ***\n")
    nardl_a_valid <- FALSE
  } else {
    cat("  ECT is negative — ECM is structurally valid.\n")
    nardl_a_valid <- TRUE
  }

  lr_a <- nardl_a$lres
  cat("  Long-run coefficients:\n"); print(lr_a)
  cat(sprintf("  Short-run Wald: W=%.4f, p=%s\n",
      nardl_a$wldsr[1, 1], format_p(nardl_a$wldsr[1, 2])))
  cat(sprintf("  Long-run Wald:  W=%.4f, p=%s\n",
      nardl_a$wldq[1, 1],  format_p(nardl_a$wldq[1, 2])))

  nardl_a_out <- data.frame(
    Specification   = "lnCPI ~ lnOil_INR | lnIIP",
    N               = nardl_a$Nobs,
    Bounds_k        = k_a,
    Bounds_F        = round(nardl_a$fstat, 4),
    Bounds_I1_5pct  = round(bounds_a$pct5["I1"], 2),
    Bounds_source   = bounds_a$source,
    Bounds_verdict  = verdict_a,
    ECT_coef        = round(ect_coef_a, 6),
    ECT_tstat       = round(ect_tstat_a, 4),
    ECT_pval        = round(ect_pval_a, 4),
    ECT_valid       = ifelse(ect_coef_a < 0, "YES — valid ECM", "NO — positive ECT, ECM invalid"),
    LR_Wald_stat    = round(nardl_a$wldq[1, 1],  4),
    LR_Wald_p       = round(nardl_a$wldq[1, 2],  6),
    SR_Wald_stat    = round(nardl_a$wldsr[1, 1], 4),
    SR_Wald_p       = round(nardl_a$wldsr[1, 2], 6),
    Appendix_status = "EXPLORATORY — ECT invalid (positive); cointegration interpretation unreliable",
    stringsAsFactors = FALSE
  )

  lr_a_df <- data.frame(
    Specification = "NARDL-A (Oil INR)",
    Coefficient   = rownames(lr_a),
    Estimate      = round(lr_a[, 1], 6),
    SE            = round(lr_a[, 2], 6),
    t_value       = round(lr_a[, 3], 4),
    p_value       = round(lr_a[, 4], 4),
    Sig           = sig_stars(lr_a[, 4]),
    ECT_valid     = ifelse(ect_coef_a < 0, "YES", "NO — interpret with caution"),
    row.names     = NULL
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# NARDL B: ln(CPI) ~ ln(Brent) | ln(EXR) + ln(IIP)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- NARDL-B: lnCPI ~ lnBrent | lnEXR + lnIIP ---\n")
cat("  (lnBrent decomposed; lnEXR and lnIIP as undecomposed regressors)\n")
nardl_b <- tryCatch({
  nardl(ln_cpi ~ ln_brent | ln_exr + ln_iip, data = df_nardl, ic = "aic", maxlag = 4,
        graph = FALSE, case = 3)
}, error = function(e) {
  cat(sprintf("    ERROR: %s\n", e$message)); NULL
})

nardl_b_out  <- NULL
lr_b_df      <- NULL
nardl_b_valid <- FALSE

if (!is.null(nardl_b)) {
  ect_coef_b  <- extract_ect_coef(nardl_b)
  ect_tstat_b <- nardl_b$sels$coefficients[2, 3]
  ect_pval_b  <- nardl_b$sels$coefficients[2, 4]

  cat(sprintf("  Bounds test F-stat: %.4f\n", nardl_b$fstat))
  cat(sprintf("  ECT coefficient (rho): %.6f  [MUST be < 0 for valid ECM]\n", ect_coef_b))
  cat(sprintf("  ECT t-statistic: %.4f  (p = %.4f)\n", ect_tstat_b, ect_pval_b))

  k_b      <- length(nardl_b$coof) - 1
  bounds_b <- pesaran_bounds(k_b, n = nrow(df_nardl))
  cat(sprintf("  k = %d | Bounds source: %s\n", k_b, bounds_b$source))
  cat(sprintf("  5%%  bounds: [%.2f, %.2f]   10%% bounds: [%.2f, %.2f]\n",
      bounds_b$pct5["I0"], bounds_b$pct5["I1"],
      bounds_b$pct10["I0"], bounds_b$pct10["I1"]))

  verdict_b <- bounds_verdict(nardl_b$fstat, bounds_b)
  cat(sprintf("  => %s\n", verdict_b))

  if (ect_coef_b >= 0) {
    cat("  *** CRITICAL: ECT >= 0 — Error correction is INVALID. ***\n")
    cat("  *** Long-run Wald and cointegration interpretations are unreliable. ***\n")
    nardl_b_valid <- FALSE
  } else {
    nardl_b_valid <- TRUE
  }

  lr_b <- nardl_b$lres
  cat("  Long-run coefficients:\n"); print(lr_b)
  cat(sprintf("  Short-run Wald: W=%.4f, p=%s\n",
      nardl_b$wldsr[1, 1], format_p(nardl_b$wldsr[1, 2])))
  cat(sprintf("  Long-run Wald:  W=%.4f, p=%s\n",
      nardl_b$wldq[1, 1],  format_p(nardl_b$wldq[1, 2])))

  nardl_b_out <- data.frame(
    Specification   = "lnCPI ~ lnBrent | lnEXR + lnIIP",
    N               = nardl_b$Nobs,
    Bounds_k        = k_b,
    Bounds_F        = round(nardl_b$fstat, 4),
    Bounds_I1_5pct  = round(bounds_b$pct5["I1"], 2),
    Bounds_source   = bounds_b$source,
    Bounds_verdict  = verdict_b,
    ECT_coef        = round(ect_coef_b, 6),
    ECT_tstat       = round(ect_tstat_b, 4),
    ECT_pval        = round(ect_pval_b, 4),
    ECT_valid       = ifelse(ect_coef_b < 0, "YES — valid ECM", "NO — positive ECT, ECM invalid"),
    LR_Wald_stat    = round(nardl_b$wldq[1, 1],  4),
    LR_Wald_p       = round(nardl_b$wldq[1, 2],  6),
    SR_Wald_stat    = round(nardl_b$wldsr[1, 1], 4),
    SR_Wald_p       = round(nardl_b$wldsr[1, 2], 6),
    Appendix_status = "EXPLORATORY — ECT invalid (positive); cointegration interpretation unreliable",
    stringsAsFactors = FALSE
  )

  lr_b_df <- data.frame(
    Specification = "NARDL-B (Brent | EXR + IIP)",
    Coefficient   = rownames(lr_b),
    Estimate      = round(lr_b[, 1], 6),
    SE            = round(lr_b[, 2], 6),
    t_value       = round(lr_b[, 3], 4),
    p_value       = round(lr_b[, 4], 4),
    Sig           = sig_stars(lr_b[, 4]),
    ECT_valid     = ifelse(ect_coef_b < 0, "YES", "NO — interpret with caution"),
    row.names     = NULL
  )
}

# ── Save combined NARDL tables ──────────────────────────────────────────────
nardl_summary <- bind_rows(
  if (!is.null(nardl_a_out)) nardl_a_out,
  if (!is.null(nardl_b_out)) nardl_b_out
)
if (nrow(nardl_summary) > 0) {
  save_table(nardl_summary, "table_11_nardl_bounds_test.csv")
}

nardl_lr <- bind_rows(
  if (!is.null(lr_a_df)) lr_a_df,
  if (!is.null(lr_b_df)) lr_b_df
)
if (nrow(nardl_lr) > 0) {
  save_table(nardl_lr, "table_12_nardl_long_run.csv")
}

# ── Short-run coefficients table ──────────────────────────────────────────
nardl_sr_list <- list()
if (!is.null(nardl_a)) {
  tryCatch({
    sr_coefs_a <- nardl_a$sels$coefficients
    nardl_sr_list[["NARDL-A"]] <- data.frame(
      Specification = "NARDL-A (Oil INR)",
      Variable      = rownames(sr_coefs_a),
      Estimate      = round(sr_coefs_a[, 1], 6),
      SE            = round(sr_coefs_a[, 2], 6),
      t_value       = round(sr_coefs_a[, 3], 4),
      p_value       = round(sr_coefs_a[, 4], 4),
      Sig           = sig_stars(sr_coefs_a[, 4]),
      ECT_valid     = ifelse(nardl_a_valid, "YES", "NO"),
      row.names     = NULL
    )
  }, error = function(e) cat(sprintf("  NARDL-A SR table error: %s\n", e$message)))
}
if (!is.null(nardl_b)) {
  tryCatch({
    sr_coefs_b <- nardl_b$sels$coefficients
    nardl_sr_list[["NARDL-B"]] <- data.frame(
      Specification = "NARDL-B (Brent | EXR + IIP)",
      Variable      = rownames(sr_coefs_b),
      Estimate      = round(sr_coefs_b[, 1], 6),
      SE            = round(sr_coefs_b[, 2], 6),
      t_value       = round(sr_coefs_b[, 3], 4),
      p_value       = round(sr_coefs_b[, 4], 4),
      Sig           = sig_stars(sr_coefs_b[, 4]),
      ECT_valid     = ifelse(nardl_b_valid, "YES", "NO"),
      row.names     = NULL
    )
  }, error = function(e) cat(sprintf("  NARDL-B SR table error: %s\n", e$message)))
}
if (length(nardl_sr_list) > 0) {
  save_table(bind_rows(nardl_sr_list), "table_13_nardl_short_run.csv")
}

# ── Dynamic multiplier plot — ONLY if ECT is valid (negative) ─────────────
cat("\n  Dynamic multiplier generation: checking ECT validity...\n")
multiplier_file <- save_figure("fig_nardl_dynamic_multiplier.png")

if (!is.null(nardl_a) && nardl_a_valid) {
  cat("  NARDL-A: ECT valid — generating dynamic multipliers.\n")
  tryCatch({
    sr_coefs   <- nardl_a$sels$coefficients[, 1]
    ect_coef_a <- extract_ect_coef(nardl_a)
    lr_coefs   <- nardl_a$coof
    lr_pos     <- sum(lr_coefs[grepl("_p", names(lr_coefs))])
    lr_neg     <- sum(lr_coefs[grepl("_n", names(lr_coefs))])

    sr_pos_names <- names(sr_coefs)[grepl("_p$|_p_", names(sr_coefs)) & !grepl("^l", names(sr_coefs))]
    sr_neg_names <- names(sr_coefs)[grepl("_n$|_n_", names(sr_coefs)) & !grepl("^l", names(sr_coefs))]
    if (length(sr_pos_names) == 0) sr_pos_names <- names(sr_coefs)[grepl("_p", names(sr_coefs))]
    if (length(sr_neg_names) == 0) sr_neg_names <- names(sr_coefs)[grepl("_n", names(sr_coefs))]

    impact_pos <- sum(sr_coefs[sr_pos_names])
    impact_neg <- sum(sr_coefs[sr_neg_names])
    H <- 24
    mult_pos <- mult_neg <- numeric(H + 1)
    mult_pos[1] <- impact_pos; mult_neg[1] <- impact_neg
    for (h in 1:H) {
      mult_pos[h + 1] <- lr_pos + (impact_pos - lr_pos) * (1 + ect_coef_a)^h
      mult_neg[h + 1] <- lr_neg + (impact_neg - lr_neg) * (1 + ect_coef_a)^h
    }
    mult_df <- data.frame(
      Horizon = rep(0:H, 3),
      Value   = c(mult_pos, mult_neg, mult_pos - mult_neg),
      Type    = rep(c("Positive shock (theta+)", "Negative shock (theta-)", "Asymmetry (diff)"),
                    each = H + 1)
    )
    fig_nardl <- ggplot(mult_df, aes(x = Horizon, y = Value, color = Type, linetype = Type)) +
      geom_line(linewidth = 1) +
      geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
      scale_color_manual(values = c(
        "Positive shock (theta+)" = "#C0392B",
        "Negative shock (theta-)" = "#2980B9",
        "Asymmetry (diff)"        = "#27AE60")) +
      scale_linetype_manual(values = c(
        "Positive shock (theta+)" = "solid",
        "Negative shock (theta-)" = "solid",
        "Asymmetry (diff)"        = "dashed")) +
      labs(title    = "NARDL Dynamic Multipliers — lnCPI ~ lnOil_INR (Appendix)",
           subtitle = sprintf("Valid ECM: ECT = %.4f | Bounds F = %.2f | LR Wald p = %s",
                              ect_coef_a, nardl_a$fstat, format_p(nardl_a$wldq[1, 2])),
           x = "Horizon (months)", y = "Multiplier", color = NULL, linetype = NULL) +
      theme_minimal(base_size = 10) + theme(legend.position = "bottom")
    ggsave(multiplier_file, fig_nardl, width = 9, height = 5.5, dpi = 300)
    cat("  Dynamic multiplier plot saved.\n")
  }, error = function(e) cat(sprintf("  Multiplier plot failed: %s\n", e$message)))

} else if (!is.null(nardl_a) && !nardl_a_valid) {
  if (file.exists(multiplier_file)) {
    unlink(multiplier_file)
    cat("  Removed stale NARDL multiplier figure from earlier valid/unsafe runs.\n")
  }
  cat(sprintf("  NARDL-A: ECT = +%.6f (positive) — dynamic multipliers SUPPRESSED.\n",
      extract_ect_coef(nardl_a)))
  cat("  Reason: convergent multipliers require ECT < 0 (Pesaran et al. 2001).\n")
  cat("  Including multiplier figures from an invalid ECM would be scientifically misleading.\n")
}

if (!is.null(nardl_b) && !nardl_b_valid) {
  cat("  NARDL-B: ECT positive — dynamic multipliers SUPPRESSED.\n")
}

# ── NARDL validity summary ─────────────────────────────────────────────────
cat("\n  === NARDL APPENDIX SUMMARY ===\n")
cat(sprintf("  NARDL-A: ECT = %.6f  [%s]\n",
    if (!is.null(nardl_a)) extract_ect_coef(nardl_a) else NA,
    if (nardl_a_valid) "VALID ECM" else "INVALID — positive ECT"))
cat(sprintf("  NARDL-B: ECT = %.6f  [%s]\n",
    if (!is.null(nardl_b)) extract_ect_coef(nardl_b) else NA,
    if (nardl_b_valid) "VALID ECM" else "INVALID — positive ECT"))
cat("  Recommendation: report NARDL as appendix exploratory only.\n")
cat("  Main inference relies on the short-run asymmetric ADL hierarchy in 04_models.R.\n")

# Store for later use
assign("nardl_a",       nardl_a,       envir = .GlobalEnv)
assign("nardl_b",       nardl_b,       envir = .GlobalEnv)
assign("nardl_a_valid", nardl_a_valid, envir = .GlobalEnv)
assign("nardl_b_valid", nardl_b_valid, envir = .GlobalEnv)

cat("  [05_nardl] Done.\n")
