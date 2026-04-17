# ==============================================================================
# 07_diagnostics.R — Diagnostic tests on all models
# ==============================================================================
# BG(12), Breusch-Pagan, HAC-RESET, Recursive CUSUM, OLS-CUSUM
# Per suggestions.md Section 5: acceptance rules for main models
# ==============================================================================
banner("07", "DIAGNOSTICS")

# ── Run diagnostics on a single model ────────────────────────────────────────
run_diagnostics <- function(model, formula, data, label) {
  n <- nrow(data)

  # Breusch-Godfrey serial correlation LM(12)
  bg <- bgtest(model, order = 12)

  # Breusch-Pagan heteroskedasticity
  bp <- bptest(model)

  # OLS-RESET (standard, not robust)
  reset2  <- resettest(model, power = 2,   type = "fitted")
  reset23 <- resettest(model, power = 2:3, type = "fitted")

  # HAC-RESET (publication-safe, robust to heteroskedasticity)
  hac_r <- tryCatch(
    reset_hac(model, data, formula, power = 2:3, label = label),
    error = function(e) data.frame(
      RESET_HAC_F = NA, RESET_HAC_p = NA, HAC_pass = "ERROR",
      stringsAsFactors = FALSE))

  # Recursive CUSUM
  cusum_rec    <- efp(formula, data = data, type = "Rec-CUSUM")
  cusum_rec_sc <- sctest(cusum_rec)

  # OLS-CUSUM
  cusum_ols    <- efp(formula, data = data, type = "OLS-CUSUM")
  cusum_ols_sc <- sctest(cusum_ols)

  # ARCH-LM(4) and ARCH-LM(12) on residuals (Engle 1982)
  arch4  <- arch_lm_test(residuals(model), lags = 4)
  arch12 <- arch_lm_test(residuals(model), lags = 12)

  # Jarque-Bera normality
  jb <- jarque_bera(residuals(model))

  data.frame(
    Model          = label,
    N              = n,
    BG12_stat      = round(bg$statistic, 4),
    BG12_p         = round(bg$p.value, 4),
    BG12_pass      = ifelse(bg$p.value > 0.05, "PASS", "FAIL"),
    BP_stat        = round(bp$statistic, 4),
    BP_p           = round(bp$p.value, 4),
    RESET2_OLS_p   = round(reset2$p.value, 4),
    RESET23_OLS_p  = round(reset23$p.value, 4),
    RESET_HAC_F    = if (!is.null(hac_r$RESET_HAC_F)) round(hac_r$RESET_HAC_F, 4) else NA,
    RESET_HAC_p    = if (!is.null(hac_r$RESET_HAC_p)) round(hac_r$RESET_HAC_p, 4) else NA,
    RESET_HAC_pass = if (!is.null(hac_r$HAC_pass)) hac_r$HAC_pass else "NA",
    RecCUSUM_stat  = round(cusum_rec_sc$statistic, 4),
    RecCUSUM_p     = round(cusum_rec_sc$p.value, 4),
    RecCUSUM_pass  = ifelse(cusum_rec_sc$p.value > 0.05, "PASS", "FAIL"),
    OLS_CUSUM_stat = round(cusum_ols_sc$statistic, 4),
    OLS_CUSUM_p    = round(cusum_ols_sc$p.value, 4),
    OLS_CUSUM_pass = ifelse(cusum_ols_sc$p.value > 0.05, "PASS", "FAIL"),
    ARCH4_stat     = round(arch4$statistic, 4),
    ARCH4_p        = round(arch4$p.value, 4),
    ARCH12_stat    = round(arch12$statistic, 4),
    ARCH12_p       = round(arch12$p.value, 4),
    JB_stat        = round(jb$statistic, 4),
    JB_p           = round(jb$p.value, 4),
    Skewness       = round(jb$skewness, 4),
    Kurtosis       = round(jb$kurtosis, 4),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

# ── Run on all models ────────────────────────────────────────────────────────
cat("  Running diagnostics on M0, M1, M2, M3...\n")

diag_all <- bind_rows(
  run_diagnostics(m0, f_m0, df_m0, "M0: Symmetric ADL"),
  run_diagnostics(m1, f_m1, df_m1, "M1: Asym INR"),
  run_diagnostics(m2, f_m2, df_m2, "M2: Brent+EXR"),
  run_diagnostics(m3, f_m3, df_m3, "M3: Interaction")
)
save_table(diag_all, "table_09_diagnostics_all.csv")

# ── Print summary ────────────────────────────────────────────────────────────
for (i in 1:nrow(diag_all)) {
  r <- diag_all[i, ]
  cat(sprintf("\n  %s (N=%d):\n", r$Model, r$N))
  cat(sprintf("    BG(12):      p=%.4f [%s]\n", r$BG12_p, r$BG12_pass))
  cat(sprintf("    BP:          p=%.4f [%s]\n", r$BP_p,
      ifelse(r$BP_p > 0.05, "PASS", "FAIL/HAC used")))
  hac_p_str <- if (is.na(r$RESET_HAC_p)) "NA" else sprintf("%.4f", r$RESET_HAC_p)
  cat(sprintf("    HAC-RESET:   F=%.4f p=%s [%s]\n",
      ifelse(is.na(r$RESET_HAC_F), 0, r$RESET_HAC_F), hac_p_str, r$RESET_HAC_pass))
  cat(sprintf("    Rec-CUSUM:   p=%.4f [%s]\n", r$RecCUSUM_p, r$RecCUSUM_pass))
  cat(sprintf("    OLS-CUSUM:   p=%.4f [%s]\n", r$OLS_CUSUM_p, r$OLS_CUSUM_pass))
  cat(sprintf("    ARCH-LM(4):  stat=%.3f p=%.4f [%s]  (report-only, HAC handles)\n",
      r$ARCH4_stat, r$ARCH4_p, ifelse(r$ARCH4_p > 0.05, "no ARCH", "ARCH present")))
  cat(sprintf("    ARCH-LM(12): stat=%.3f p=%.4f [%s]  (report-only, HAC handles)\n",
      r$ARCH12_stat, r$ARCH12_p, ifelse(r$ARCH12_p > 0.05, "no ARCH", "ARCH present")))
  cat(sprintf("    Jarque-Bera: stat=%.3f p=%.4f [%s]  (report-only)\n",
      r$JB_stat, r$JB_p, ifelse(r$JB_p > 0.05, "normal", "non-normal")))
}

# ── Store CUSUM objects for figures ──────────────────────────────────────────
cusum_m1 <- efp(f_m1, data = df_m1, type = "Rec-CUSUM")
cusum_m2 <- efp(f_m2, data = df_m2, type = "Rec-CUSUM")

# ── Publication acceptance triage ────────────────────────────────────────────
cat("\n\n  === PUBLICATION ACCEPTANCE TRIAGE ===\n")
for (i in 1:nrow(diag_all)) {
  r <- diag_all[i, ]
  passes <- sum(c(
    r$BG12_pass == "PASS",
    r$RESET_HAC_pass == "PASS",
    r$RecCUSUM_pass == "PASS"
  ), na.rm = TRUE)
  verdict <- if (passes == 3) "ACCEPT for main text" else
             if (passes == 2) "CAUTION — robustness only" else
             "REJECT for main text"
  cat(sprintf("  %s: %d/3 key diagnostics pass -> %s\n", r$Model, passes, verdict))
}

cat("\n  [07_diagnostics] Done.\n")
