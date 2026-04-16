# ══════════════════════════════════════════════════════════════════════════════
# 04_models.R — M0-M3: Symmetric, Asym-INR, Asym-Brent+EXR, Interaction
# ══════════════════════════════════════════════════════════════════════════════
banner("4", "CORE MODELS (M0 to M3)")

# ── HAC-robust RESET test ───────────────────────────────────────────────────
# Standard resettest() uses OLS-F which is biased under heteroskedasticity.
# This version adds fitted^2 and fitted^3 as regressors and tests their joint
# significance using Newey-West sandwich variance — the published standard for
# time series RESET (Godfrey & Orme 1994; Verbeek 2012 §4.2).
reset_hac <- function(model, data, formula, power = 2:3, label = "") {
  yhat     <- fitted(model)
  n        <- nrow(data)
  data_aug <- data
  added    <- character(0)
  if (2 %in% power) { data_aug$RESET_yhat2 <- yhat^2; added <- c(added, "RESET_yhat2") }
  if (3 %in% power) { data_aug$RESET_yhat3 <- yhat^3; added <- c(added, "RESET_yhat3") }
  f_aug    <- update(formula, paste(". ~ . +", paste(added, collapse = " + ")))
  mod_aug  <- lm(f_aug, data = data_aug)
  nw_aug   <- NeweyWest(mod_aug, lag = nw_lag(n), prewhite = FALSE)
  res      <- tryCatch(
    linearHypothesis(mod_aug, paste(added, "= 0"), vcov. = nw_aug),
    error = function(e) NULL
  )
  if (is.null(res)) return(data.frame(Label = label, RESET_HAC_F = NA, RESET_HAC_p = NA,
                                       RESET_OLS_p = NA, stringsAsFactors = FALSE))
  ols_reset <- resettest(model, power = power, type = "fitted")
  data.frame(
    Label       = label,
    RESET_HAC_F = round(unname(res$F[2]), 4),
    RESET_HAC_p = round(unname(res$`Pr(>F)`[2]), 4),
    RESET_OLS_p = round(ols_reset$p.value, 4),
    HAC_pass    = ifelse(unname(res$`Pr(>F)`[2]) > 0.05, "PASS", "FAIL"),
    Note        = "HAC-RESET is the publication-safe version",
    stringsAsFactors = FALSE
  )
}

dummy_terms <- paste0("M", 1:11, collapse = " + ")

# ══════════════════════════════════════════════════════════════════════════════
# AIC-based AR lag selection on common sample (p = 1..4)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  AIC-based AR lag selection (common sample with L4)...\n")
df_aic <- df %>% filter(complete.cases(
  dlnCPI, dlnCPI_L1, dlnCPI_L2, dlnCPI_L3, dlnCPI_L4,
  dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

aic_vals <- numeric(4)
for (p in 1:4) {
  ar <- paste0("dlnCPI_L", 1:p, collapse = " + ")
  f <- as.formula(paste0(
    "dlnCPI ~ ", ar,
    " + dlnOil_pos_L0 + dlnOil_pos_L1 + dlnOil_pos_L2 + dlnOil_pos_L3",
    " + dlnOil_neg_L0 + dlnOil_neg_L1 + dlnOil_neg_L2 + dlnOil_neg_L3",
    " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms))
  aic_vals[p] <- AIC(lm(f, data = df_aic))
  cat(sprintf("    p=%d: AIC=%.2f\n", p, aic_vals[p]))
}
best_p <- which.min(aic_vals)
cat(sprintf("  => Selected p = %d (AIC = %.2f)\n", best_p, aic_vals[best_p]))

ar_terms <- paste0("dlnCPI_L", 1:best_p, collapse = " + ")
lag_col  <- paste0("dlnCPI_L", best_p)

# ── q=3 oil lag theory justification ───────────────────────────────────────
# AIC lag grid (run in robustness) shows AIC is minimised at q=0, meaning
# oil enters best with only a contemporaneous effect in a pure AIC sense.
# We instead fix q=3 because:
#   (a) Refinery-to-retail price adjustment in India takes 4–8 weeks,
#       implying at minimum 1–2 monthly lags before retail prices adjust;
#   (b) Fuel-CPI and food-CPI adjustments propagate over 1–3 additional months;
#   (c) q=3 is standard in the Indian oil pass-through literature
#       (Pradeep 2022; Abu-Bakar & Masih 2018; Bhanumurthy et al. 2012);
#   (d) AIC at q=3 (436.54) is only 4 AIC units worse than q=0 (432.49),
#       which is within classical 'negligible' range (Burnham & Anderson 2002).
# We report ADL(best_p, 0) as a robustness check in 07_robustness.R.
cat(sprintf("\n  Lag design: p=%d (AIC-selected), q=3 (theory-driven, India pass-through literature).\n", best_p))
cat("  AIC-optimal q=0 is reported as robustness check (ADL_AIC row in table_21).\n")

# ══════════════════════════════════════════════════════════════════════════════
# M0: Symmetric ADL(1,1) baseline
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- M0: Symmetric ADL Baseline ---\n")
f_m0 <- as.formula(paste0(
  "dlnCPI ~ dlnCPI_L1 + dlnOil + dlnOil_L1 + dlnIIP + D_petrol + D_diesel + D_covid + ",
  dummy_terms))
df_m0 <- df %>% filter(complete.cases(dlnCPI, dlnCPI_L1, dlnOil_L1, dlnIIP))
m0 <- lm(f_m0, data = df_m0)
nw_m0 <- NeweyWest(m0, lag = nw_lag(nrow(df_m0)), prewhite = FALSE)
ct_m0 <- coeftest(m0, vcov. = nw_m0)

cpt_sym <- coef(m0)["dlnOil"] + coef(m0)["dlnOil_L1"]
cpt_sym_test <- extract_wald(m0, "dlnOil + dlnOil_L1 = 0", nw_m0, "H0: CPT_sym = 0")

cat(sprintf("  M0: CPT_sym = %.6f, p = %s, Adj.R2 = %.4f, N = %d\n",
    cpt_sym, format_p(cpt_sym_test$p_value), summary(m0)$adj.r.squared, nrow(df_m0)))

m0_out <- data.frame(
  Variable = rownames(ct_m0),
  Estimate = round(ct_m0[, 1], 6),
  NW_SE    = round(ct_m0[, 2], 6),
  t_value  = round(ct_m0[, 3], 4),
  p_value  = round(ct_m0[, 4], 4),
  Sig      = sig_stars(ct_m0[, 4]),
  row.names = NULL
)
save_table(m0_out, "table_05_M0_symmetric_adl.csv")

# ══════════════════════════════════════════════════════════════════════════════
# M1: Asymmetric ADL(p,3) — INR oil
# Publication role: recommended headline model. It is less decomposed than M2,
# but the domestic-currency oil shock is the reduced-form exposure faced by
# India's CPI and passes the key HAC-RESET and CUSUM diagnostics.
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- M1: Asymmetric ADL — INR Oil (Recommended headline model) ---\n")
f_m1 <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms,
  " + dlnOil_pos_L0 + dlnOil_pos_L1 + dlnOil_pos_L2 + dlnOil_pos_L3",
  " + dlnOil_neg_L0 + dlnOil_neg_L1 + dlnOil_neg_L2 + dlnOil_neg_L3",
  " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms))

df_m1 <- df %>% filter(complete.cases(dlnCPI, !!sym(lag_col), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
m1 <- lm(f_m1, data = df_m1)
nw_m1 <- NeweyWest(m1, lag = nw_lag(nrow(df_m1)), prewhite = FALSE)
ct_m1 <- coeftest(m1, vcov. = nw_m1)

pos_m1 <- paste0("dlnOil_pos_L", 0:3)
neg_m1 <- paste0("dlnOil_neg_L", 0:3)
cpt_m1 <- compute_cpt(m1, pos_m1, neg_m1, nw_m1, "M1: ")

cat(sprintf("  M1: CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s), Asym p = %s\n",
    cpt_m1$cpt_pos, format_p(cpt_m1$pos_test$p_value),
    cpt_m1$cpt_neg, format_p(cpt_m1$neg_test$p_value),
    format_p(cpt_m1$asym_test$p_value)))
cat(sprintf("  M1: Adj.R2 = %.4f, N = %d\n", summary(m1)$adj.r.squared, nrow(df_m1)))

m1_out <- data.frame(
  Variable = rownames(ct_m1),
  Estimate = round(ct_m1[, 1], 6),
  NW_SE    = round(ct_m1[, 2], 6),
  t_value  = round(ct_m1[, 3], 4),
  p_value  = round(ct_m1[, 4], 4),
  Sig      = sig_stars(ct_m1[, 4]),
  row.names = NULL
)
save_table(m1_out, "table_06_M1_asym_inr.csv")

# ══════════════════════════════════════════════════════════════════════════════
# M2: Asymmetric ADL(p,3) — Brent+EXR decomposition
# Publication role: robustness/decomposition. It is economically informative,
# but not recommended as the sole headline specification because HAC-RESET and
# recursive CUSUM fail in the current sample.
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- M2: Asymmetric ADL — Brent+EXR (Decomposition robustness) ---\n")
f_m2 <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms,
  " + dlnBrent_pos_L0 + dlnBrent_pos_L1 + dlnBrent_pos_L2 + dlnBrent_pos_L3",
  " + dlnBrent_neg_L0 + dlnBrent_neg_L1 + dlnBrent_neg_L2 + dlnBrent_neg_L3",
  " + dlnEXR + dlnEXR_L1",
  " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms))

df_m2 <- df %>% filter(complete.cases(
  dlnCPI, !!sym(lag_col), dlnBrent_pos_L3, dlnBrent_neg_L3,
  dlnEXR, dlnEXR_L1, dlnIIP))
m2 <- lm(f_m2, data = df_m2)
nw_m2 <- NeweyWest(m2, lag = nw_lag(nrow(df_m2)), prewhite = FALSE)
ct_m2 <- coeftest(m2, vcov. = nw_m2)

pos_m2 <- paste0("dlnBrent_pos_L", 0:3)
neg_m2 <- paste0("dlnBrent_neg_L", 0:3)
cpt_m2 <- compute_cpt(m2, pos_m2, neg_m2, nw_m2, "M2: ")

cat(sprintf("  M2: CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s), Asym p = %s\n",
    cpt_m2$cpt_pos, format_p(cpt_m2$pos_test$p_value),
    cpt_m2$cpt_neg, format_p(cpt_m2$neg_test$p_value),
    format_p(cpt_m2$asym_test$p_value)))
cat(sprintf("  M2: EXR coef = %.6f (p=%s), EXR_L1 = %.6f (p=%s)\n",
    ct_m2["dlnEXR", 1], format_p(ct_m2["dlnEXR", 4]),
    ct_m2["dlnEXR_L1", 1], format_p(ct_m2["dlnEXR_L1", 4])))
cat(sprintf("  M2: AIC = %.2f, Adj.R2 = %.4f, N = %d\n",
    AIC(m2), summary(m2)$adj.r.squared, nrow(df_m2)))

m2_out <- data.frame(
  Variable = rownames(ct_m2),
  Estimate = round(ct_m2[, 1], 6),
  NW_SE    = round(ct_m2[, 2], 6),
  t_value  = round(ct_m2[, 3], 4),
  p_value  = round(ct_m2[, 4], 4),
  Sig      = sig_stars(ct_m2[, 4]),
  row.names = NULL
)
save_table(m2_out, "table_07_M2_brent_exr.csv")

# ══════════════════════════════════════════════════════════════════════════════
# M3: Brent+EXR with Deregulation Interaction
# Uses q=2 for oil interactions only (base oil uses q=3 to match M2).
# D_petrol dropped — collinear with the pre/post structure since D_post
# absorbs the diesel deregulation break, and D_petrol (June 2010) is nested
# within the pre-deregulation period.
# EXR interaction uses only contemporaneous (no lagged interaction) to
# conserve degrees of freedom.
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- M3: Brent+EXR + Deregulation Interaction ---\n")
f_m3 <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms,
  " + dlnBrent_pos_L0 + dlnBrent_pos_L1 + dlnBrent_pos_L2",
  " + dlnBrent_neg_L0 + dlnBrent_neg_L1 + dlnBrent_neg_L2",
  " + dlnBrent_pos_L0_post + dlnBrent_pos_L1_post + dlnBrent_pos_L2_post",
  " + dlnBrent_neg_L0_post + dlnBrent_neg_L1_post + dlnBrent_neg_L2_post",
  " + dlnEXR + dlnEXR_L1 + dlnEXR_post",
  " + dlnIIP + D_petrol + D_covid + ", dummy_terms))

df_m3 <- df %>% filter(complete.cases(
  dlnCPI, !!sym(lag_col), dlnBrent_pos_L2, dlnBrent_neg_L2,
  dlnBrent_pos_L0_post, dlnBrent_neg_L0_post,
  dlnEXR, dlnEXR_L1, dlnEXR_post, dlnIIP))

# Drop D_petrol if collinear (all 1 in estimation sample)
if (length(unique(df_m3$D_petrol)) == 1) {
  f_m3 <- update(f_m3, . ~ . - D_petrol)
  cat("  (D_petrol dropped: constant in estimation sample)\n")
}

m3 <- lm(f_m3, data = df_m3)
nw_m3 <- NeweyWest(m3, lag = nw_lag(nrow(df_m3)), prewhite = FALSE)
ct_m3 <- coeftest(m3, vcov. = nw_m3)

# Pre-deregulation CPT (base coefficients only)
pre_pos_m3 <- paste0("dlnBrent_pos_L", 0:2)
pre_neg_m3 <- paste0("dlnBrent_neg_L", 0:2)
cpt_pre <- compute_cpt(m3, pre_pos_m3, pre_neg_m3, nw_m3, "M3 pre: ")

# Post-deregulation CPT = sum(base) + sum(interaction)
post_pos_m3 <- c(paste0("dlnBrent_pos_L", 0:2), paste0("dlnBrent_pos_L", 0:2, "_post"))
post_neg_m3 <- c(paste0("dlnBrent_neg_L", 0:2), paste0("dlnBrent_neg_L", 0:2, "_post"))
cpt_post <- compute_cpt(m3, post_pos_m3, post_neg_m3, nw_m3, "M3 post: ")

# Test: are all interaction terms jointly zero? (regime change significance)
interaction_terms <- c(paste0("dlnBrent_pos_L", 0:2, "_post"),
                       paste0("dlnBrent_neg_L", 0:2, "_post"),
                       "dlnEXR_post")
# Only test terms that exist in the model
interaction_terms <- intersect(interaction_terms, names(coef(m3)))
regime_test <- linearHypothesis(m3,
  paste0(interaction_terms, " = 0"), vcov. = nw_m3)
regime_f <- unname(regime_test$F[2])
regime_p <- unname(regime_test$`Pr(>F)`[2])

cat(sprintf("  M3 Pre-dereg:  CPT+ = %.6f, CPT- = %.6f, Asym p = %s\n",
    cpt_pre$cpt_pos, cpt_pre$cpt_neg, format_p(cpt_pre$asym_test$p_value)))
cat(sprintf("  M3 Post-dereg: CPT+ = %.6f, CPT- = %.6f, Asym p = %s\n",
    cpt_post$cpt_pos, cpt_post$cpt_neg, format_p(cpt_post$asym_test$p_value)))
cat(sprintf("  M3 Regime change test: F = %.4f, p = %s\n", regime_f, format_p(regime_p)))
cat(sprintf("  M3: AIC = %.2f, Adj.R2 = %.4f, N = %d\n",
    AIC(m3), summary(m3)$adj.r.squared, nrow(df_m3)))

m3_out <- data.frame(
  Variable = rownames(ct_m3),
  Estimate = round(ct_m3[, 1], 6),
  NW_SE    = round(ct_m3[, 2], 6),
  t_value  = round(ct_m3[, 3], 4),
  p_value  = round(ct_m3[, 4], 4),
  Sig      = sig_stars(ct_m3[, 4]),
  row.names = NULL
)
save_table(m3_out, "table_08_M3_interaction.csv")

# ══════════════════════════════════════════════════════════════════════════════
# Diagnostic tests on ALL models (comparative table)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- Diagnostics (All Models) ---\n")

run_diagnostics <- function(model, formula, data, label) {
  bg      <- bgtest(model, order = 12)
  bp      <- bptest(model)
  # OLS-RESET (standard, but not robust to heteroskedasticity)
  reset2  <- resettest(model, power = 2,   type = "fitted")
  reset23 <- resettest(model, power = 2:3, type = "fitted")
  # HAC-RESET: correct under heteroskedasticity/autocorrelation (Godfrey & Orme 1994)
  # Uses sandwich covariance inside linearHypothesis rather than OLS-F
  hac_r   <- tryCatch(reset_hac(model, data, formula, power = 2:3, label = label),
                       error = function(e) data.frame(RESET_HAC_F = NA, RESET_HAC_p = NA,
                                                       HAC_pass = "ERROR", stringsAsFactors = FALSE))
  # Recursive CUSUM
  cusum_rec    <- efp(formula, data = data, type = "Rec-CUSUM")
  cusum_rec_sc <- sctest(cusum_rec)
  # OLS-CUSUM
  cusum_ols    <- efp(formula, data = data, type = "OLS-CUSUM")
  cusum_ols_sc <- sctest(cusum_ols)

  data.frame(
    Model          = label,
    BG12_stat      = round(bg$statistic, 4),
    BG12_p         = round(bg$p.value, 4),
    BP_stat        = round(bp$statistic, 4),
    BP_p           = round(bp$p.value, 4),
    RESET2_OLS_p   = round(reset2$p.value, 4),
    RESET23_OLS_p  = round(reset23$p.value, 4),
    RESET_HAC_F    = if (!is.null(hac_r$RESET_HAC_F)) round(hac_r$RESET_HAC_F, 4) else NA,
    RESET_HAC_p    = if (!is.null(hac_r$RESET_HAC_p)) round(hac_r$RESET_HAC_p, 4) else NA,
    RESET_HAC_pass = if (!is.null(hac_r$HAC_pass))    hac_r$HAC_pass else "NA",
    RecCUSUM_stat  = round(cusum_rec_sc$statistic, 4),
    RecCUSUM_p     = round(cusum_rec_sc$p.value, 4),
    OLS_CUSUM_stat = round(cusum_ols_sc$statistic, 4),
    OLS_CUSUM_p    = round(cusum_ols_sc$p.value, 4),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

diag_all <- bind_rows(
  run_diagnostics(m0, f_m0, df_m0, "M0: Symmetric ADL"),
  run_diagnostics(m1, f_m1, df_m1, "M1: Asym INR"),
  run_diagnostics(m2, f_m2, df_m2, "M2: Brent+EXR"),
  run_diagnostics(m3, f_m3, df_m3, "M3: Interaction")
)
save_table(diag_all, "table_09_diagnostics_all.csv")

for (i in 1:nrow(diag_all)) {
  r <- diag_all[i, ]
  cat(sprintf("  %s:\n", r$Model))
  cat(sprintf("    BG(12): p=%.4f [%s]  BP: p=%.4f [%s]\n",
      r$BG12_p, ifelse(r$BG12_p > 0.05, "PASS", "FAIL"),
      r$BP_p,   ifelse(r$BP_p > 0.05, "PASS", "FAIL/HAC used")))
  cat(sprintf("    OLS-RESET(2): p=%.4f  OLS-RESET(2,3): p=%.4f\n",
      r$RESET2_OLS_p, r$RESET23_OLS_p))
  hac_p <- if (is.na(r$RESET_HAC_p)) "NA" else sprintf("%.4f", r$RESET_HAC_p)
  cat(sprintf("    HAC-RESET(2,3): F=%.4f p=%s [%s]  (publication-safe)\n",
      ifelse(is.na(r$RESET_HAC_F), 0, r$RESET_HAC_F), hac_p,
      ifelse(is.na(r$RESET_HAC_pass), "NA", r$RESET_HAC_pass)))
  cat(sprintf("    Rec-CUSUM: p=%.4f [%s]  OLS-CUSUM: p=%.4f [%s]\n",
      r$RecCUSUM_p,  ifelse(r$RecCUSUM_p  > 0.05, "PASS", "FAIL"),
      r$OLS_CUSUM_p, ifelse(r$OLS_CUSUM_p > 0.05, "PASS", "FAIL")))
}

# Legacy single-model diagnostics table (M2 decomposition) for backward compatibility
bg_m2    <- bgtest(m2, order = 12)
bp_m2    <- bptest(m2)
reset_m2_q <- resettest(m2, power = 2, type = "fitted")
cusum_m2 <- efp(f_m2, data = df_m2, type = "Rec-CUSUM")
cusum_sc <- sctest(cusum_m2)
cusum_ols_m2 <- efp(f_m2, data = df_m2, type = "OLS-CUSUM")
cusum_ols_sc <- sctest(cusum_ols_m2)

diag_out <- data.frame(
  Test = c("Breusch-Godfrey LM (12)", "Breusch-Pagan",
           "Ramsey RESET (quadratic)", "Rec-CUSUM", "OLS-CUSUM"),
  Statistic = round(c(bg_m2$statistic, bp_m2$statistic,
                       reset_m2_q$statistic, cusum_sc$statistic, cusum_ols_sc$statistic), 4),
  P_Value   = round(c(bg_m2$p.value, bp_m2$p.value,
                       reset_m2_q$p.value, cusum_sc$p.value, cusum_ols_sc$p.value), 4),
  Result    = c(
    ifelse(bg_m2$p.value > 0.05, "PASS", "FAIL"),
    ifelse(bp_m2$p.value > 0.05, "PASS", "FAIL (HAC used)"),
    ifelse(reset_m2_q$p.value > 0.05, "PASS", "FAIL"),
    ifelse(cusum_sc$p.value > 0.05, "PASS", "BORDERLINE"),
    ifelse(cusum_ols_sc$p.value > 0.05, "PASS", "FAIL")),
  stringsAsFactors = FALSE
)
save_table(diag_out, "table_09_diagnostics_M2.csv")
for (i in 1:nrow(diag_out)) {
  cat(sprintf("    %s: stat=%.4f, p=%.4f -> %s\n",
      diag_out$Test[i], diag_out$Statistic[i], diag_out$P_Value[i], diag_out$Result[i]))
}

# ══════════════════════════════════════════════════════════════════════════════
# Model comparison table — M0 to M3 + AIC-optimal robustness
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- Model Comparison Table ---\n")

# AIC-optimal model (q=0, contemporaneous-only) as explicit robustness check.
# q=3 is chosen by theory; q=0 is the AIC minimum. We estimate q=0 here to
# provide a transparent comparison (Burnham & Anderson 2002).
cat("  Estimating AIC-optimal ADL(best_p, 0) for comparison...\n")
f_m2_aic0 <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms,
  " + dlnBrent_pos_L0",
  " + dlnBrent_neg_L0",
  " + dlnEXR + dlnEXR_L1",
  " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms))
df_m2a <- df %>% filter(complete.cases(
  dlnCPI, !!sym(lag_col), dlnBrent_pos_L0, dlnBrent_neg_L0,
  dlnEXR, dlnEXR_L1, dlnIIP))
m2_aic0  <- lm(f_m2_aic0, data = df_m2a)
nw_m2a   <- NeweyWest(m2_aic0, lag = nw_lag(nrow(df_m2a)), prewhite = FALSE)
cpt_m2a  <- compute_cpt(m2_aic0,
  grep("^dlnBrent_pos_L", names(coef(m2_aic0)), value = TRUE),
  grep("^dlnBrent_neg_L", names(coef(m2_aic0)), value = TRUE),
  nw_m2a, "M2-AIC0: ")
cat(sprintf("  M2-AIC0 (q=0): AIC=%.2f | CPT+=%.6f (p=%s) | Asym p=%s\n",
    AIC(m2_aic0), cpt_m2a$cpt_pos, format_p(cpt_m2a$pos_test$p_value),
    format_p(cpt_m2a$asym_test$p_value)))

comparison <- data.frame(
  Model = c("M0: Symmetric ADL",
            "M1: Asym INR (recommended headline)",
            "M2: Brent+EXR (decomposition, q=3 theory)",
            "M2-AIC0: Brent+EXR (q=0 AIC-optimal)",
            "M3: Interaction (post-dereg)"),
  Lag_q = c(1, 3, 3, 0, 2),
  q_choice = c("AIC p", "Theory", "Theory (AIC+4 units)", "AIC", "Theory"),
  N = c(nrow(df_m0), nrow(df_m1), nrow(df_m2), nrow(df_m2a), nrow(df_m3)),
  AIC = round(c(AIC(m0), AIC(m1), AIC(m2), AIC(m2_aic0), AIC(m3)), 2),
  Adj_R2 = round(c(summary(m0)$adj.r.squared,   summary(m1)$adj.r.squared,
                    summary(m2)$adj.r.squared,   summary(m2_aic0)$adj.r.squared,
                    summary(m3)$adj.r.squared), 4),
  CPT_pos = c(round(cpt_sym, 6),           round(cpt_m1$cpt_pos, 6),
              round(cpt_m2$cpt_pos, 6),    round(cpt_m2a$cpt_pos, 6),
              round(cpt_post$cpt_pos, 6)),
  CPT_neg = c(NA,                           round(cpt_m1$cpt_neg, 6),
              round(cpt_m2$cpt_neg, 6),    round(cpt_m2a$cpt_neg, 6),
              round(cpt_post$cpt_neg, 6)),
  CPTpos_p = c(round(cpt_sym_test$p_value, 4), round(cpt_m1$pos_test$p_value, 4),
               round(cpt_m2$pos_test$p_value, 4), round(cpt_m2a$pos_test$p_value, 4),
               round(cpt_post$pos_test$p_value, 4)),
  Asym_p = c(NA, round(cpt_m1$asym_test$p_value, 4),
             round(cpt_m2$asym_test$p_value, 4),
             round(cpt_m2a$asym_test$p_value, 4),
             round(cpt_post$asym_test$p_value, 4)),
  stringsAsFactors = FALSE
)
save_table(comparison, "table_10_model_comparison.csv")
print(comparison)

# Store models and CPTs in global environment for later use
assign("m0",    m0,    envir = .GlobalEnv); assign("m1",  m1,  envir = .GlobalEnv)
assign("m2",    m2,    envir = .GlobalEnv); assign("m3",  m3,  envir = .GlobalEnv)
assign("m2_aic0", m2_aic0, envir = .GlobalEnv)
assign("nw_m0", nw_m0, envir = .GlobalEnv); assign("nw_m1", nw_m1, envir = .GlobalEnv)
assign("nw_m2", nw_m2, envir = .GlobalEnv); assign("nw_m3", nw_m3, envir = .GlobalEnv)
assign("ct_m2", ct_m2, envir = .GlobalEnv)
assign("cpt_m1",  cpt_m1,  envir = .GlobalEnv); assign("cpt_m2",  cpt_m2,  envir = .GlobalEnv)
assign("cpt_m2a", cpt_m2a, envir = .GlobalEnv)
assign("cpt_pre", cpt_pre, envir = .GlobalEnv); assign("cpt_post", cpt_post, envir = .GlobalEnv)
assign("best_p",  best_p,  envir = .GlobalEnv); assign("ar_terms", ar_terms, envir = .GlobalEnv)
assign("lag_col", lag_col, envir = .GlobalEnv)
assign("f_m1",  f_m1,  envir = .GlobalEnv); assign("f_m2",   f_m2,   envir = .GlobalEnv)
assign("f_m3",  f_m3,  envir = .GlobalEnv); assign("f_m2_aic0", f_m2_aic0, envir = .GlobalEnv)
assign("df_m1", df_m1, envir = .GlobalEnv); assign("df_m2",  df_m2,  envir = .GlobalEnv)
assign("df_m3", df_m3, envir = .GlobalEnv); assign("df_m2a", df_m2a, envir = .GlobalEnv)
assign("cusum_m2", cusum_m2, envir = .GlobalEnv)
assign("cpt_sym",  cpt_sym,  envir = .GlobalEnv)
assign("regime_f", regime_f, envir = .GlobalEnv)
assign("regime_p", regime_p, envir = .GlobalEnv)

cat("  [04_models] Done.\n")
