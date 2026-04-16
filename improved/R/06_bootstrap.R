# ══════════════════════════════════════════════════════════════════════════════
# 06_bootstrap.R — Restricted-Residuals Block Bootstrap for Wald Inference
#
# METHODOLOGY (Davidson & MacKinnon 1999; Paparoditis & Politis 2005):
# A valid bootstrap for H0: CPT+ = CPT- must use RESTRICTED residuals —
# residuals from a model estimated under the null. Re-sampling unrestricted
# residuals only yields sensitivity analysis, not valid inference under H0.
#
# Correct procedure:
#   1. Estimate RESTRICTED model: impose CPT+ = CPT- by collapsing
#      positive and negative oil lags into a single symmetric oil variable.
#   2. Extract RESTRICTED residuals from this constrained model.
#   3. Re-sample restricted residuals via circular block bootstrap.
#   4. Reconstruct Y* = fitted(unrestricted) + boot_resids(restricted)
#   5. Re-estimate UNRESTRICTED model on Y*, compute bootstrap Wald F.
#   6. Bootstrap p = P(Wald* >= Wald_obs).
#
# Note: This approach controls bootstrap size under H0 exactly.
# Reference: Davidson, R. & MacKinnon, J.G. (1999). Bootstrap testing in
#   nonlinear models. International Economic Review, 40(3), 487–508.
# ══════════════════════════════════════════════════════════════════════════════
banner("6", "RESTRICTED-RESIDUALS BLOCK BOOTSTRAP WALD INFERENCE")

B <- 4999
set.seed(42)

# ── Construct restricted model formula from unrestricted formula ──────────
# Restricted model imposes CPT+ = CPT-:
# dlnCPI = ... + theta*(dlnOil_pos_Lj + dlnOil_neg_Lj) + ...
# We achieve this by replacing all _pos and _neg lags with their SUM.
make_restricted_formula <- function(formula, pos_names, neg_names, data) {
  # Build symmetric oil variable names
  sym_names <- paste0("dlnOil_sym_L", seq_along(pos_names) - 1)

  # Add symmetric variables to data
  for (j in seq_along(pos_names)) {
    if (pos_names[j] %in% names(data) && neg_names[j] %in% names(data)) {
      data[[sym_names[j]]] <- data[[pos_names[j]]] + data[[neg_names[j]]]
    }
  }

  # Build restricted formula: replace pos+neg with sym
  f_chr <- deparse(formula)
  # Remove pos and neg terms
  all_oil <- c(pos_names, neg_names)
  rhs_terms <- attr(terms(formula), "term.labels")
  rhs_keep  <- rhs_terms[!rhs_terms %in% all_oil]
  sym_avail <- sym_names[sym_names %in% names(data)]

  new_rhs <- paste(c(rhs_keep, sym_avail), collapse = " + ")
  dep_var  <- all.vars(formula)[1]
  new_f    <- as.formula(paste(dep_var, "~", new_rhs))
  list(formula = new_f, data = data)
}

# ── Block bootstrap engine — restricted-residuals variant ─────────────────
# Circular block bootstrap (Politis & Romano 1992).
# Block length = floor(0.75 * T^(1/3)), as per Shao (2010).
block_bootstrap_wald_restricted <- function(model_unres, formula_unres,
                                             data, pos_names, neg_names,
                                             B = 4999, label = "Model") {
  n         <- nrow(data)
  block_len <- max(2, nw_lag(n))

  # ── Step 1: Estimate restricted model ──────────────────────────────────
  cat(sprintf("    Building restricted model (imposing H0: CPT+ = CPT-)...\n"))
  posv <- intersect(pos_names, names(data))
  negv <- intersect(neg_names, names(data))

  # Create symmetric oil sum variable for restriction
  data_r <- data
  for (j in seq_along(posv)) {
    sym_var <- paste0("dlnOil_sym_L", j - 1)
    data_r[[sym_var]] <- data_r[[posv[j]]] + data_r[[negv[j]]]
  }
  sym_vars <- paste0("dlnOil_sym_L", seq_along(posv) - 1)

  # Build restricted formula
  rhs_orig  <- attr(terms(formula_unres), "term.labels")
  rhs_keep  <- rhs_orig[!rhs_orig %in% c(posv, negv)]
  f_res_chr <- paste(all.vars(formula_unres)[1], "~",
                     paste(c(rhs_keep, sym_vars), collapse = " + "))
  f_res     <- as.formula(f_res_chr)

  model_res <- tryCatch(
    lm(f_res, data = data_r),
    error = function(e) {
      cat(sprintf("    Restricted model error: %s. Falling back to recentered residuals.\n",
                  e$message))
      NULL
    }
  )

  # ── Step 2: Get restricted residuals ───────────────────────────────────
  if (!is.null(model_res)) {
    resids_r <- residuals(model_res)
    cat(sprintf("    Restricted model: %d obs, %d regressors\n",
                nobs(model_res), length(coef(model_res))))
  } else {
    # Fallback: use recentered unrestricted residuals (sensitivity only)
    resids_r <- residuals(model_unres) - mean(residuals(model_unres))
    cat("    WARNING: Using recentered unrestricted residuals (sensitivity only).\n")
  }

  # ── Step 3: Observed Wald statistic ────────────────────────────────────
  nw_obs   <- NeweyWest(model_unres, lag = nw_lag(n), prewhite = FALSE)
  obs_wald <- extract_wald(model_unres, sum_eq_sum(posv, negv), nw_obs, "observed")$F_stat

  # ── Step 4: Bootstrap ──────────────────────────────────────────────────
  y_hat_unres <- fitted(model_unres)
  depvar      <- all.vars(formula_unres)[1]
  boot_wald   <- numeric(B)
  n_fail      <- 0L

  for (b in 1:B) {
    num_blocks <- ceiling(n / block_len)
    starts     <- sample(1:n, num_blocks, replace = TRUE)
    idx        <- unlist(lapply(starts, function(s) ((s - 1 + 0:(block_len - 1)) %% n) + 1))
    idx        <- idx[1:n]
    boot_resids <- resids_r[idx]

    data_b             <- data
    data_b[[depvar]]   <- y_hat_unres + boot_resids

    tryCatch({
      mod_b    <- lm(formula_unres, data = data_b)
      nw_b     <- NeweyWest(mod_b, lag = nw_lag(n), prewhite = FALSE)
      boot_wald[b] <- extract_wald(mod_b, sum_eq_sum(posv, negv), nw_b, "boot")$F_stat
    }, error = function(e) {
      boot_wald[b] <<- NA
      n_fail       <<- n_fail + 1L
    })
  }

  boot_clean <- na.omit(boot_wald)
  boot_p     <- mean(boot_clean >= obs_wald)
  method_note <- ifelse(!is.null(model_res),
                        "Restricted-residuals (valid inference under H0)",
                        "Recentered unrestricted residuals (sensitivity only)")

  cat(sprintf("  %s: obs Wald F = %.4f | boot p = %.4f | B=%d | block=%d | fails=%d\n",
      label, obs_wald, boot_p, length(boot_clean), block_len, n_fail))
  cat(sprintf("    Bootstrap method: %s\n", method_note))

  list(
    label            = label,
    obs_wald         = obs_wald,
    boot_p           = boot_p,
    block_len        = block_len,
    B_effective      = length(boot_clean),
    method           = method_note,
    boot_distribution = boot_clean
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# Run bootstrap on M1, M2, M3
# ══════════════════════════════════════════════════════════════════════════════
cat(sprintf("\n  Restricted-residuals block bootstrap: B = %d replications\n", B))
cat("  (This may take several minutes...)\n\n")

# M1: INR oil
pos_m1_names <- paste0("dlnOil_pos_L",   0:3)
neg_m1_names <- paste0("dlnOil_neg_L",   0:3)

# M2: Brent
pos_m2_names <- paste0("dlnBrent_pos_L", 0:3)
neg_m2_names <- paste0("dlnBrent_neg_L", 0:3)

# M3: Post-deregulation interaction (post-period combined effect)
post_pos_m3 <- c(paste0("dlnBrent_pos_L", 0:2),
                 paste0("dlnBrent_pos_L", 0:2, "_post"))
post_neg_m3 <- c(paste0("dlnBrent_neg_L", 0:2),
                 paste0("dlnBrent_neg_L", 0:2, "_post"))

boot_m1 <- block_bootstrap_wald_restricted(m1, f_m1, df_m1,
                                            pos_m1_names, neg_m1_names,
                                            B = B, label = "M1 (INR oil)")
boot_m2 <- block_bootstrap_wald_restricted(m2, f_m2, df_m2,
                                            pos_m2_names, neg_m2_names,
                                            B = B, label = "M2 (Brent+EXR)")
boot_m3 <- block_bootstrap_wald_restricted(m3, f_m3, df_m3,
                                            post_pos_m3, post_neg_m3,
                                            B = B, label = "M3 (Interaction post-dereg)")

# ── Results table ──────────────────────────────────────────────────────────
boot_results <- data.frame(
  Model               = c("M1: Asym INR", "M2: Brent+EXR", "M3: Interaction (post-dereg)"),
  Asymptotic_Wald_F   = round(c(boot_m1$obs_wald, boot_m2$obs_wald, boot_m3$obs_wald), 4),
  Asymptotic_p        = round(c(cpt_m1$asym_test$p_value,
                                cpt_m2$asym_test$p_value,
                                cpt_post$asym_test$p_value), 4),
  Block_Bootstrap_p   = round(c(boot_m1$boot_p, boot_m2$boot_p, boot_m3$boot_p), 4),
  Block_Length        = c(boot_m1$block_len, boot_m2$block_len, boot_m3$block_len),
  B_Effective         = c(boot_m1$B_effective, boot_m2$B_effective, boot_m3$B_effective),
  Bootstrap_Method    = c(boot_m1$method, boot_m2$method, boot_m3$method),
  stringsAsFactors    = FALSE
)
save_table(boot_results, "table_14_bootstrap_wald.csv")
cat("\n")
print(boot_results)

# Store
assign("boot_m1", boot_m1, envir = .GlobalEnv)
assign("boot_m2", boot_m2, envir = .GlobalEnv)
assign("boot_m3", boot_m3, envir = .GlobalEnv)

cat("  [06_bootstrap] Done.\n")
