# ==============================================================================
# 04b_bootstrap.R — Restricted-residual block bootstrap for Wald asymmetry
# ==============================================================================
# Method: Davidson & MacKinnon restricted-residual bootstrap
# Block resampling: circular block bootstrap (Paparoditis & Politis)
# Tests H0: CPT+ = CPT- for headline and fuel ADL models
# ==============================================================================
banner("04b", "BOOTSTRAP INFERENCE")

# ── Build restricted formula (collapse pos/neg into symmetric) ───────────────
make_restricted_formula <- function(formula, pos_prefix, neg_prefix, q) {
  f_str <- deparse(formula, width.cutoff = 500)
  for (k in 0:q) {
    pos_term <- paste0(pos_prefix, "_L", k)
    neg_term <- paste0(neg_prefix, "_L", k)
    f_str <- gsub(paste0("\\+ ", pos_term), "", f_str)
    f_str <- gsub(paste0("\\+ ", neg_term), "", f_str)
    f_str <- gsub(pos_term, "", f_str)
    f_str <- gsub(neg_term, "", f_str)
  }
  sym_terms <- paste0(pos_prefix, "_sym_L", 0:q)
  f_str <- paste0(f_str, " + ", paste(sym_terms, collapse = " + "))
  f_str <- gsub("\\s+", " ", f_str)
  f_str <- gsub("\\+ \\+", "+", f_str)
  as.formula(f_str)
}

# ── Block bootstrap Wald test ────────────────────────────────────────────────
block_bootstrap_wald <- function(model_unres, formula_unres, formula_res,
                                  data, pos_names, neg_names,
                                  pos_prefix, neg_prefix, q,
                                  B = BOOTSTRAP_B, seed = BOOTSTRAP_SEED) {
  set.seed(seed)
  n <- nrow(data)
  block_len <- max(2, nw_lag(n))

  cat(sprintf("    Bootstrap: B=%d, block_len=%d, n=%d\n", B, block_len, n))

  # Step 1: Create symmetric variables for restricted model
  data_r <- data
  for (k in 0:q) {
    sym_name <- paste0(pos_prefix, "_sym_L", k)
    pos_name <- paste0(pos_prefix, "_L", k)
    neg_name <- paste0(neg_prefix, "_L", k)
    data_r[[sym_name]] <- data_r[[pos_name]] + data_r[[neg_name]]
  }

  # Step 2: Estimate restricted model and get restricted residuals
  m_res <- lm(formula_res, data = data_r)
  resid_r <- residuals(m_res)

  # Step 3: Get unrestricted fitted values
  fitted_u <- fitted(model_unres)

  # Step 4: Observed Wald statistic
  nw_u <- NeweyWest(model_unres, lag = nw_lag(n), prewhite = FALSE)
  asym_terms <- c(pos_names, paste0("-", neg_names))
  asym_hyp <- paste(paste(asym_terms, collapse = " + "), "= 0")
  asym_hyp <- gsub("\\+ -", "- ", asym_hyp)
  obs_test <- linearHypothesis(model_unres, asym_hyp, vcov. = nw_u)
  obs_wald <- unname(obs_test$F[2])
  obs_p    <- unname(obs_test$`Pr(>F)`[2])

  cat(sprintf("    Observed Wald F = %.4f (asymptotic p = %s)\n", obs_wald, format_p(obs_p)))

  # Step 5: Bootstrap loop
  boot_walds <- numeric(B)
  dv_name <- all.vars(formula_unres)[1]
  failures <- 0

  for (b in 1:B) {
    starts <- sample(1:n, ceiling(n / block_len), replace = TRUE)
    idx <- unlist(lapply(starts, function(s) ((s - 1 + 0:(block_len - 1)) %% n) + 1))
    idx <- idx[1:n]
    boot_resid <- resid_r[idx]

    data_b <- data
    data_b[[dv_name]] <- fitted_u + boot_resid

    boot_wald <- tryCatch({
      m_b  <- lm(formula_unres, data = data_b)
      nw_b <- NeweyWest(m_b, lag = nw_lag(n), prewhite = FALSE)
      test_b <- linearHypothesis(m_b, asym_hyp, vcov. = nw_b)
      unname(test_b$F[2])
    }, error = function(e) NA_real_)

    boot_walds[b] <- boot_wald
    if (is.na(boot_wald)) failures <- failures + 1

    if (b %% 1000 == 0) cat(sprintf("      ... %d/%d complete\n", b, B))
  }

  boot_p <- mean(boot_walds >= obs_wald, na.rm = TRUE)
  cat(sprintf("    Bootstrap p = %.4f (failures: %d/%d)\n", boot_p, failures, B))

  list(
    obs_wald   = obs_wald,
    obs_p      = obs_p,
    boot_p     = boot_p,
    boot_walds = boot_walds,
    B          = B,
    failures   = failures,
    method     = "Restricted-residual circular block bootstrap"
  )
}

# ── Bootstrap: Headline WPI ADL ──────────────────────────────────────────────
cat("\n  --- Bootstrap: Headline WPI Asymmetry Test ---\n")

f_res_headline <- make_restricted_formula(
  f_headline_main, "dln_oil_pos", "dln_oil_neg", MAIN_OIL_LAGS
)
boot_headline <- block_bootstrap_wald(
  model_unres   = m_headline_main,
  formula_unres = f_headline_main,
  formula_res   = f_res_headline,
  data          = df_headline_main,
  pos_names     = paste0("dln_oil_pos_L", 0:MAIN_OIL_LAGS),
  neg_names     = paste0("dln_oil_neg_L", 0:MAIN_OIL_LAGS),
  pos_prefix    = "dln_oil_pos",
  neg_prefix    = "dln_oil_neg",
  q             = MAIN_OIL_LAGS
)

# ── Bootstrap: Fuel & Power ADL ─────────────────────────────────────────────
cat("\n  --- Bootstrap: Fuel & Power WPI Asymmetry Test ---\n")

f_res_fuel <- make_restricted_formula(
  f_fuel_main, "dln_oil_pos", "dln_oil_neg", MAIN_OIL_LAGS
)
boot_fuel <- block_bootstrap_wald(
  model_unres   = m_fuel_main,
  formula_unres = f_fuel_main,
  formula_res   = f_res_fuel,
  data          = df_fuel_main,
  pos_names     = paste0("dln_oil_pos_L", 0:MAIN_OIL_LAGS),
  neg_names     = paste0("dln_oil_neg_L", 0:MAIN_OIL_LAGS),
  pos_prefix    = "dln_oil_pos",
  neg_prefix    = "dln_oil_neg",
  q             = MAIN_OIL_LAGS
)

# ── Save results ─────────────────────────────────────────────────────────────
boot_table <- data.frame(
  Model = c("Headline WPI ADL (INR oil)", "Fuel & Power WPI ADL"),
  Obs_Wald_F   = round(c(boot_headline$obs_wald, boot_fuel$obs_wald), 4),
  Asymptotic_p = c(format_p(boot_headline$obs_p), format_p(boot_fuel$obs_p)),
  Bootstrap_p  = round(c(boot_headline$boot_p, boot_fuel$boot_p), 4),
  B            = c(boot_headline$B, boot_fuel$B),
  Failures     = c(boot_headline$failures, boot_fuel$failures),
  Method       = c(boot_headline$method, boot_fuel$method),
  stringsAsFactors = FALSE
)
save_table(boot_table, "table_17_bootstrap_wald.csv")
print(boot_table)

cat("  [04b_bootstrap] Done.\n")
