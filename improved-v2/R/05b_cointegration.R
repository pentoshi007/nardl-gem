# ==============================================================================
# 05b_cointegration.R — Pesaran-Shin-Smith (2001) ARDL bounds F-test
# ==============================================================================
# Tests for a long-run (levels) relationship between ln(CPI), ln(oil_INR),
# and ln(IIP) in a conditional ECM form.
#
#   dlnCPI_t = a + rho * ln_CPI_{t-1}
#              + theta1 * ln_oil_{t-1} + theta2 * ln_IIP_{t-1}
#              + sum_{i=1..p} phi_i * dlnCPI_{t-i}
#              + sum_{j=0..q} psi_j * dlnOil_{t-j}
#              + gamma * dlnIIP_t
#              + controls (D_petrol, D_diesel, D_covid, monthly dummies)
#              + e_t
#
# H0 (no levels relationship): rho = theta1 = theta2 = 0.
# Reject if F > I(1) upper bound. Fail to reject if F < I(0) lower bound.
# Critical values from Pesaran, Shin, Smith (2001) Table CI(iii), Case III
# (unrestricted intercept, no trend), k = 2 regressors.
# Bounds test uses Newey-West HAC-robust F via car::linearHypothesis.
# ==============================================================================
banner("05b", "ARDL BOUNDS F-TEST (Pesaran-Shin-Smith 2001)")

cat("  Testing long-run relationship: ln(CPI) ~ ln(oil_INR), ln(IIP)\n")
cat("  Conditional ECM form, Case III (unrestricted intercept, no trend).\n\n")

# Build level lags needed for the bounds test
df_ec <- df %>% arrange(date) %>%
  mutate(
    ln_cpi_L1 = dplyr::lag(ln_cpi, 1),
    ln_oil_L1 = dplyr::lag(ln_oil, 1),
    ln_iip_L1 = dplyr::lag(ln_iip, 1)
  )

# Use the same p=AIC lag structure and q=OIL_LAG_Q as M1
p_ec <- if (exists("best_p")) best_p else 1
q_ec <- OIL_LAG_Q

# Build needed dlnOil lags (03_variable_builder only creates L1 of dlnOil,
# and separately dlnOil_pos_L0..L3 / dlnOil_neg_L0..L3). Here we need the
# symmetric dlnOil at L0..q_ec for the conditional ECM, so build aliases.
df_ec$dlnOil_L0 <- df_ec$dlnOil
if (!("dlnOil_L1" %in% names(df_ec))) {
  df_ec$dlnOil_L1 <- dplyr::lag(df_ec$dlnOil, 1)
}
for (k in 2:q_ec) {
  col <- paste0("dlnOil_L", k)
  if (!(col %in% names(df_ec))) {
    df_ec[[col]] <- dplyr::lag(df_ec$dlnOil, k)
  }
}

ec_month_dummies <- paste0("mo_", c("Jan","Feb","Mar","Apr","May","Jun",
                                    "Jul","Aug","Sep","Oct","Nov"))

ec_rhs <- c(
  "ln_cpi_L1", "ln_oil_L1", "ln_iip_L1",
  paste0("dlnCPI_L", 1:p_ec),
  paste0("dlnOil_L", 0:q_ec),
  "dlnIIP",
  "D_petrol", "D_diesel", "D_covid",
  ec_month_dummies
)

# Keep only columns that actually exist
ec_rhs <- ec_rhs[ec_rhs %in% names(df_ec)]

ec_valid <- df_ec %>% filter(complete.cases(df_ec[, c("dlnCPI", ec_rhs)]))

ec_rhs <- ec_rhs[vapply(ec_rhs, function(term) length(unique(ec_valid[[term]])) > 1,
                        logical(1))]

f_ec <- as.formula(paste("dlnCPI ~", paste(ec_rhs, collapse = " + ")))
m_ec <- lm(f_ec, data = ec_valid)
nw_ec <- NeweyWest(m_ec, lag = nw_lag(nrow(ec_valid)), prewhite = FALSE)

bounds_levels <- c("ln_cpi_L1", "ln_oil_L1", "ln_iip_L1")
bounds_levels <- intersect(bounds_levels, names(coef(m_ec)))

# HAC-robust joint F-test that all level coefficients are zero
bounds_hyp  <- paste(bounds_levels, "= 0")
bounds_test <- linearHypothesis(m_ec, bounds_hyp, vcov. = nw_ec)
F_bounds    <- unname(bounds_test$F[2])
p_bounds    <- unname(bounds_test$`Pr(>F)`[2])

# Pesaran, Shin, Smith (2001) Table CI(iii) Case III, k = 2
# Critical values at 10% / 5% / 1%
psc_k2 <- data.frame(
  Level = c("10%", "5%", "1%"),
  I0_lower = c(3.17, 3.79, 5.15),
  I1_upper = c(4.14, 4.85, 6.36),
  stringsAsFactors = FALSE
)

verdict <- sapply(seq_len(nrow(psc_k2)), function(i) {
  if (F_bounds > psc_k2$I1_upper[i]) {
    "Reject H0 (cointegration)"
  } else if (F_bounds < psc_k2$I0_lower[i]) {
    "Fail to reject (no levels relation)"
  } else {
    "Inconclusive"
  }
})

bounds_tbl <- data.frame(
  Test = "Pesaran-Shin-Smith ARDL bounds F",
  Regressors_k = 2,
  Case = "III (unrestricted intercept, no trend)",
  Obs = nrow(ec_valid),
  F_statistic = round(F_bounds, 4),
  HAC_p = round(p_bounds, 4),
  stringsAsFactors = FALSE
)

cat(sprintf("  F = %.4f (HAC p = %s), n = %d\n",
    F_bounds, format_p(p_bounds), nrow(ec_valid)))
for (i in seq_len(nrow(psc_k2))) {
  cat(sprintf("    at %s level: I(0)=%.2f, I(1)=%.2f -> %s\n",
      psc_k2$Level[i], psc_k2$I0_lower[i], psc_k2$I1_upper[i], verdict[i]))
}

bounds_cv_tbl <- data.frame(
  Level = psc_k2$Level,
  I0_lower = psc_k2$I0_lower,
  I1_upper = psc_k2$I1_upper,
  F_statistic = round(F_bounds, 4),
  Verdict = verdict,
  stringsAsFactors = FALSE
)

save_table(bounds_tbl, "table_04b_bounds_test.csv")
save_table(bounds_cv_tbl, "table_04b2_bounds_critical_values.csv")

# Store for later reference
bounds_F <- F_bounds
bounds_verdict_5pct <- verdict[psc_k2$Level == "5%"]

cat(sprintf("\n  Interpretation at 5%%: %s\n", bounds_verdict_5pct))
cat("  Note: PSC (2001) CV assume asymptotic distribution (T>=80).\n")
cat("  For T=245, asymptotic CV are appropriate.\n")

cat("  [05b_cointegration] Done.\n")
