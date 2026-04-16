# ==============================================================================
# 08_bootstrap.R — Restricted-residual block bootstrap for Wald asymmetry
# ==============================================================================
# Method: Davidson & MacKinnon restricted-residual bootstrap
# Block resampling: circular block bootstrap (Paparoditis & Politis)
# Tests H0: CPT+ = CPT- for M1 (headline) and M2 (robustness)
# ==============================================================================
banner("08", "BOOTSTRAP INFERENCE")

# ── Build restricted formula (collapse pos/neg into symmetric) ───────────────
make_restricted_formula <- function(formula, pos_prefix, neg_prefix, q) {
  f_str <- deparse(formula, width.cutoff = 500)
  # Remove pos and neg terms, add symmetric terms
  for (k in 0:q) {
    pos_term <- paste0(pos_prefix, "_L", k)
    neg_term <- paste0(neg_prefix, "_L", k)
    f_str <- gsub(paste0("\\+ ", pos_term), "", f_str)
    f_str <- gsub(paste0("\\+ ", neg_term), "", f_str)
    f_str <- gsub(pos_term, "", f_str)
    f_str <- gsub(neg_term, "", f_str)
  }
  # Add symmetric variables
  sym_terms <- paste0(pos_prefix, "_sym_L", 0:q)
  f_str <- paste0(f_str, " + ", paste(sym_terms, collapse = " + "))
  # Clean up multiple spaces and stray +
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
    # Circular block bootstrap of restricted residuals
    starts <- sample(1:n, ceiling(n / block_len), replace = TRUE)
    idx <- unlist(lapply(starts, function(s) ((s - 1 + 0:(block_len - 1)) %% n) + 1))
    idx <- idx[1:n]
    boot_resid <- resid_r[idx]

    # Construct bootstrap Y* = fitted(unrestricted) + restricted residuals
    data_b <- data
    data_b[[dv_name]] <- fitted_u + boot_resid

    # Re-estimate unrestricted model on bootstrap sample
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

# ── Bootstrap M1 (headline model) ───────────────────────────────────────────
cat("\n  --- Bootstrap: M1 Asymmetry Test ---\n")

f_m1_res <- make_restricted_formula(f_m1, "dlnOil_pos", "dlnOil_neg", 3)
boot_m1 <- block_bootstrap_wald(
  model_unres  = m1,
  formula_unres = f_m1,
  formula_res  = f_m1_res,
  data         = df_m1,
  pos_names    = paste0("dlnOil_pos_L", 0:3),
  neg_names    = paste0("dlnOil_neg_L", 0:3),
  pos_prefix   = "dlnOil_pos",
  neg_prefix   = "dlnOil_neg",
  q            = 3
)

# ── Bootstrap M2 (robustness) ───────────────────────────────────────────────
cat("\n  --- Bootstrap: M2 Asymmetry Test ---\n")

f_m2_res <- make_restricted_formula(f_m2, "dlnBrent_pos", "dlnBrent_neg", 3)
boot_m2 <- block_bootstrap_wald(
  model_unres  = m2,
  formula_unres = f_m2,
  formula_res  = f_m2_res,
  data         = df_m2,
  pos_names    = paste0("dlnBrent_pos_L", 0:3),
  neg_names    = paste0("dlnBrent_neg_L", 0:3),
  pos_prefix   = "dlnBrent_pos",
  neg_prefix   = "dlnBrent_neg",
  q            = 3
)

# ── Save results ─────────────────────────────────────────────────────────────
boot_table <- data.frame(
  Model = c("M1: Asym INR (headline)", "M2: Brent+EXR (robustness)"),
  Obs_Wald_F   = round(c(boot_m1$obs_wald, boot_m2$obs_wald), 4),
  Asymptotic_p = c(format_p(boot_m1$obs_p), format_p(boot_m2$obs_p)),
  Bootstrap_p  = round(c(boot_m1$boot_p, boot_m2$boot_p), 4),
  B            = c(boot_m1$B, boot_m2$B),
  Failures     = c(boot_m1$failures, boot_m2$failures),
  Method       = c(boot_m1$method, boot_m2$method),
  stringsAsFactors = FALSE
)
save_table(boot_table, "table_14_bootstrap_wald.csv")
print(boot_table)

cat("  [08_bootstrap] Done.\n")
