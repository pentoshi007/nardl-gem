# ==============================================================================
# 06_models.R — Core models: M0 (symmetric), M1 (headline), M2 (robustness),
#               M2-AIC0, M3 (interaction)
# ==============================================================================
# Per suggestions.md Section 4:
#   M1 = recommended headline (INR oil, q=3)
#   M2 = robustness only (Brent+EXR, q=3)
#   M3 = appendix (deregulation interaction)
# ==============================================================================
banner("06", "CORE MODELS (M0 to M3)")

dummy_terms <- paste0("M", 1:11, collapse = " + ")

# ==============================================================================
# AIC-based AR lag selection (p = 1..4, common sample with L4)
# ==============================================================================
cat("\n  AIC-based AR lag selection (common sample with L4)...\n")

df_aic <- df %>% filter(complete.cases(
  dlnCPI, dlnCPI_L1, dlnCPI_L2, dlnCPI_L3, dlnCPI_L4,
  dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

aic_vals <- numeric(MAX_AR_P)
for (p in 1:MAX_AR_P) {
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

# Oil lag q = 3 by theory (India pass-through literature)
# q = 0 reported as M2-AIC0 robustness check
cat(sprintf("\n  Lag design: p=%d (AIC), q=%d (theory-driven).\n", best_p, OIL_LAG_Q))

# ==============================================================================
# M0: Symmetric ADL(1,1) baseline
# ==============================================================================
cat("\n  --- M0: Symmetric ADL Baseline ---\n")
f_m0 <- as.formula(paste0(
  "dlnCPI ~ dlnCPI_L1 + dlnOil + dlnOil_L1 + dlnIIP + D_petrol + D_diesel + D_covid + ",
  dummy_terms))
df_m0 <- df %>% filter(complete.cases(dlnCPI, dlnCPI_L1, dlnOil_L1, dlnIIP))
m0    <- lm(f_m0, data = df_m0)
nw_m0 <- NeweyWest(m0, lag = nw_lag(nrow(df_m0)), prewhite = FALSE)

cpt_sym <- coef(m0)["dlnOil"] + coef(m0)["dlnOil_L1"]
cpt_sym_test <- extract_wald(m0, "dlnOil + dlnOil_L1 = 0", nw_m0, "H0: CPT_sym = 0")

cat(sprintf("  M0: CPT_sym = %.6f, p = %s, Adj.R2 = %.4f, N = %d\n",
    cpt_sym, format_p(cpt_sym_test$p_value), summary(m0)$adj.r.squared, nrow(df_m0)))

save_table(coef_table(m0, nw_m0), "table_05_M0_symmetric_adl.csv")

# ==============================================================================
# M1: Asymmetric ADL(p,3) — INR oil (RECOMMENDED HEADLINE)
# ==============================================================================
cat("\n  --- M1: Asymmetric ADL — INR Oil (Recommended headline) ---\n")
f_m1 <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms,
  " + dlnOil_pos_L0 + dlnOil_pos_L1 + dlnOil_pos_L2 + dlnOil_pos_L3",
  " + dlnOil_neg_L0 + dlnOil_neg_L1 + dlnOil_neg_L2 + dlnOil_neg_L3",
  " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms))

df_m1 <- df %>% filter(complete.cases(dlnCPI, !!sym(lag_col), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))
m1    <- lm(f_m1, data = df_m1)
nw_m1 <- NeweyWest(m1, lag = nw_lag(nrow(df_m1)), prewhite = FALSE)

pos_m1 <- paste0("dlnOil_pos_L", 0:3)
neg_m1 <- paste0("dlnOil_neg_L", 0:3)
cpt_m1 <- compute_cpt(m1, pos_m1, neg_m1, nw_m1, "M1: ")

cat(sprintf("  M1: CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s), Asym p = %s\n",
    cpt_m1$cpt_pos, format_p(cpt_m1$pos_test$p_value),
    cpt_m1$cpt_neg, format_p(cpt_m1$neg_test$p_value),
    format_p(cpt_m1$asym_test$p_value)))
cat(sprintf("  M1: AIC = %.2f, Adj.R2 = %.4f, N = %d\n",
    AIC(m1), summary(m1)$adj.r.squared, nrow(df_m1)))

save_table(coef_table(m1, nw_m1), "table_06_M1_asym_inr.csv")

# ==============================================================================
# M2: Asymmetric ADL(p,3) — Brent+EXR decomposition (ROBUSTNESS ONLY)
# ==============================================================================
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
m2    <- lm(f_m2, data = df_m2)
nw_m2 <- NeweyWest(m2, lag = nw_lag(nrow(df_m2)), prewhite = FALSE)
ct_m2 <- coeftest(m2, vcov. = nw_m2)

pos_m2 <- paste0("dlnBrent_pos_L", 0:3)
neg_m2 <- paste0("dlnBrent_neg_L", 0:3)
cpt_m2 <- compute_cpt(m2, pos_m2, neg_m2, nw_m2, "M2: ")

cat(sprintf("  M2: CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s), Asym p = %s\n",
    cpt_m2$cpt_pos, format_p(cpt_m2$pos_test$p_value),
    cpt_m2$cpt_neg, format_p(cpt_m2$neg_test$p_value),
    format_p(cpt_m2$asym_test$p_value)))
cat(sprintf("  M2: AIC = %.2f, Adj.R2 = %.4f, N = %d\n",
    AIC(m2), summary(m2)$adj.r.squared, nrow(df_m2)))

save_table(coef_table(m2, nw_m2), "table_07_M2_brent_exr.csv")

# ==============================================================================
# M2-AIC0: Brent+EXR with q=0 (AIC-optimal transparency benchmark)
# ==============================================================================
cat("\n  --- M2-AIC0: Brent+EXR q=0 (AIC-optimal benchmark) ---\n")
f_m2_aic0 <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms,
  " + dlnBrent_pos_L0 + dlnBrent_neg_L0",
  " + dlnEXR + dlnEXR_L1",
  " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms))

df_m2a   <- df %>% filter(complete.cases(
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

# ==============================================================================
# M3: Brent+EXR with Deregulation Interaction (APPENDIX)
# ==============================================================================
cat("\n  --- M3: Brent+EXR + Deregulation Interaction (Appendix) ---\n")
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

# Drop D_petrol if collinear
if (length(unique(df_m3$D_petrol)) == 1) {
  f_m3 <- update(f_m3, . ~ . - D_petrol)
  cat("  (D_petrol dropped: constant in estimation sample)\n")
}

m3    <- lm(f_m3, data = df_m3)
nw_m3 <- NeweyWest(m3, lag = nw_lag(nrow(df_m3)), prewhite = FALSE)

# Pre-deregulation CPT
pre_pos_m3 <- paste0("dlnBrent_pos_L", 0:2)
pre_neg_m3 <- paste0("dlnBrent_neg_L", 0:2)
cpt_pre    <- compute_cpt(m3, pre_pos_m3, pre_neg_m3, nw_m3, "M3 pre: ")

# Post-deregulation CPT = base + interaction
post_pos_m3 <- c(paste0("dlnBrent_pos_L", 0:2), paste0("dlnBrent_pos_L", 0:2, "_post"))
post_neg_m3 <- c(paste0("dlnBrent_neg_L", 0:2), paste0("dlnBrent_neg_L", 0:2, "_post"))
cpt_post    <- compute_cpt(m3, post_pos_m3, post_neg_m3, nw_m3, "M3 post: ")

# Regime change test: all interaction terms jointly zero
interaction_terms <- c(paste0("dlnBrent_pos_L", 0:2, "_post"),
                       paste0("dlnBrent_neg_L", 0:2, "_post"),
                       "dlnEXR_post")
interaction_terms <- intersect(interaction_terms, names(coef(m3)))
regime_test <- linearHypothesis(m3, paste0(interaction_terms, " = 0"), vcov. = nw_m3)
regime_f <- unname(regime_test$F[2])
regime_p <- unname(regime_test$`Pr(>F)`[2])

cat(sprintf("  M3 Pre-dereg:  CPT+ = %.6f, CPT- = %.6f, Asym p = %s\n",
    cpt_pre$cpt_pos, cpt_pre$cpt_neg, format_p(cpt_pre$asym_test$p_value)))
cat(sprintf("  M3 Post-dereg: CPT+ = %.6f, CPT- = %.6f, Asym p = %s\n",
    cpt_post$cpt_pos, cpt_post$cpt_neg, format_p(cpt_post$asym_test$p_value)))
cat(sprintf("  M3 Regime change: F = %.4f, p = %s\n", regime_f, format_p(regime_p)))

save_table(coef_table(m3, nw_m3), "table_08_M3_interaction.csv")

# ==============================================================================
# Model comparison table
# ==============================================================================
cat("\n  --- Model Comparison Table ---\n")

comparison <- data.frame(
  Model = c("M0: Symmetric ADL",
            "M1: Asym INR (recommended headline)",
            "M2: Brent+EXR (decomposition, q=3)",
            "M2-AIC0: Brent+EXR (q=0 AIC-optimal)",
            "M3: Interaction (post-dereg)"),
  Lag_q = c(1, OIL_LAG_Q, OIL_LAG_Q, 0, 2),
  q_choice = c("AIC p", "Theory", "Theory", "AIC", "Theory"),
  N = c(nrow(df_m0), nrow(df_m1), nrow(df_m2), nrow(df_m2a), nrow(df_m3)),
  AIC = round(c(AIC(m0), AIC(m1), AIC(m2), AIC(m2_aic0), AIC(m3)), 2),
  Adj_R2 = round(c(summary(m0)$adj.r.squared, summary(m1)$adj.r.squared,
                    summary(m2)$adj.r.squared, summary(m2_aic0)$adj.r.squared,
                    summary(m3)$adj.r.squared), 4),
  CPT_pos = c(round(cpt_sym, 6), round(cpt_m1$cpt_pos, 6),
              round(cpt_m2$cpt_pos, 6), round(cpt_m2a$cpt_pos, 6),
              round(cpt_post$cpt_pos, 6)),
  CPT_neg = c(NA, round(cpt_m1$cpt_neg, 6),
              round(cpt_m2$cpt_neg, 6), round(cpt_m2a$cpt_neg, 6),
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

cat("  [06_models] Done.\n")
