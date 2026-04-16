# ══════════════════════════════════════════════════════════════════════════════
# 06_bootstrap.R — Block bootstrap for Wald test inference
# ══════════════════════════════════════════════════════════════════════════════
banner("6", "BLOCK BOOTSTRAP WALD TEST INFERENCE")

B <- 4999
set.seed(42)

# ── Block bootstrap engine ───────────────────────────────────────────────────
# Circular block bootstrap (Politis & Romano 1992)
# Resamples residual blocks, reconstructs Y, re-estimates model, computes Wald F
#
# Block length matches HAC bandwidth: floor(0.75 * T^(1/3)), per Shao (2010)
# and suggestions.md §Fix 4. Previous value of 1.75 was too large, resulting
# in too few effective independent blocks and upward-biased bootstrap p-values.
block_bootstrap_wald <- function(model, formula, data, pos_names, neg_names,
                                 B = 4999, label = "Model") {
  n <- nrow(data)
  block_len <- max(2, nw_lag(n))  # same as HAC bandwidth

  y_hat <- fitted(model)
  resids <- residuals(model)

  # Center residuals (impose null hypothesis of no asymmetry)
  resids <- resids - mean(resids)

  # Observed Wald F-statistic
  nw_obs <- NeweyWest(model, lag = nw_lag(n), prewhite = FALSE)
  obs_wald <- extract_wald(model, sum_eq_sum(pos_names, neg_names), nw_obs,
                           "observed")$F_stat

  depvar <- all.vars(formula)[1]
  boot_wald <- numeric(B)
  n_fail <- 0

  for (b in 1:B) {
    num_blocks <- ceiling(n / block_len)
    starts <- sample(1:n, num_blocks, replace = TRUE)
    idx <- unlist(lapply(starts, function(s) ((s - 1 + 0:(block_len - 1)) %% n) + 1))
    idx <- idx[1:n]
    boot_resids <- resids[idx]

    data_b <- data
    data_b[[depvar]] <- y_hat + boot_resids

    tryCatch({
      mod_b <- lm(formula, data = data_b)
      nw_b <- NeweyWest(mod_b, lag = nw_lag(n), prewhite = FALSE)
      boot_wald[b] <- extract_wald(mod_b, sum_eq_sum(pos_names, neg_names),
                                   nw_b, "boot")$F_stat
    }, error = function(e) {
      boot_wald[b] <<- NA
      n_fail <<- n_fail + 1
    })
  }

  boot_wald_clean <- na.omit(boot_wald)
  boot_p <- mean(boot_wald_clean >= obs_wald)

  cat(sprintf("  %s: obs Wald F = %.4f, boot p = %.4f (B=%d, block=%d, fails=%d)\n",
      label, obs_wald, boot_p, length(boot_wald_clean), block_len, n_fail))

  list(
    label = label,
    obs_wald = obs_wald,
    boot_p = boot_p,
    block_len = block_len,
    B_effective = length(boot_wald_clean),
    boot_distribution = boot_wald_clean
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# Run bootstrap on M1, M2, M3
# ══════════════════════════════════════════════════════════════════════════════
cat(sprintf("\n  Block bootstrap with B = %d replications\n", B))
cat("  (This may take several minutes...)\n\n")

pos_m1_names <- paste0("dlnOil_pos_L", 0:3)
neg_m1_names <- paste0("dlnOil_neg_L", 0:3)
pos_m2_names <- paste0("dlnBrent_pos_L", 0:3)
neg_m2_names <- paste0("dlnBrent_neg_L", 0:3)

# M3: post-deregulation asymmetry test
post_pos_m3_names <- c(paste0("dlnBrent_pos_L", 0:2), paste0("dlnBrent_pos_L", 0:2, "_post"))
post_neg_m3_names <- c(paste0("dlnBrent_neg_L", 0:2), paste0("dlnBrent_neg_L", 0:2, "_post"))

boot_m1 <- block_bootstrap_wald(m1, f_m1, df_m1, pos_m1_names, neg_m1_names,
                                 B = B, label = "M1 (INR oil)")
boot_m2 <- block_bootstrap_wald(m2, f_m2, df_m2, pos_m2_names, neg_m2_names,
                                 B = B, label = "M2 (Brent+EXR)")
boot_m3 <- block_bootstrap_wald(m3, f_m3, df_m3, post_pos_m3_names, post_neg_m3_names,
                                 B = B, label = "M3 (Interaction post-dereg)")

# ── Results table ────────────────────────────────────────────────────────────
boot_results <- data.frame(
  Model = c("M1: Asym INR", "M2: Brent+EXR", "M3: Interaction (post-dereg)"),
  Asymptotic_Wald_F = round(c(boot_m1$obs_wald, boot_m2$obs_wald, boot_m3$obs_wald), 4),
  Asymptotic_p = round(c(cpt_m1$asym_test$p_value, cpt_m2$asym_test$p_value,
                          cpt_post$asym_test$p_value), 4),
  Block_Bootstrap_p = round(c(boot_m1$boot_p, boot_m2$boot_p, boot_m3$boot_p), 4),
  Block_Length = c(boot_m1$block_len, boot_m2$block_len, boot_m3$block_len),
  B_Effective = c(boot_m1$B_effective, boot_m2$B_effective, boot_m3$B_effective),
  stringsAsFactors = FALSE
)
save_table(boot_results, "table_14_bootstrap_wald.csv")
cat("\n")
print(boot_results)

# Store
assign("boot_m1", boot_m1, envir = .GlobalEnv)
assign("boot_m2", boot_m2, envir = .GlobalEnv)
assign("boot_m3", boot_m3, envir = .GlobalEnv)

cat("  [06_bootstrap] Done.\n")
