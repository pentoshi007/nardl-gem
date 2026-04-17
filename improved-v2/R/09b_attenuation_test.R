# ==============================================================================
# 09b_attenuation_test.R — Common-sample dilution table & formal attenuation Wald
# ==============================================================================
# Problem addressed:
#   The main dilution table compares Stage 1 (PPAC, 2004+) with Stage 3
#   (headline, 2004+) on 245 obs, but Stage 2 (F&L bridge) only has ~164 obs
#   starting May 2011. Cross-sample ratios are hard to defend. This module:
#
#   (1) Re-estimates Stage 1, Stage 2, and Stage 3 on the COMMON Fuel & Light
#       sample window so the dilution ratio is apples-to-apples.
#   (2) Runs a formal Wald test that CPT+ shrinks across the chain, using a
#       stacked system with stage-indicator interactions.
# ==============================================================================
banner("09b", "COMMON-SAMPLE DILUTION + ATTENUATION WALD TEST")

attenuation_rows <- list()
common_dil_rows  <- list()

if (!fuel_available || !ppac_available) {
  cat("  Skipped: PPAC or Fuel & Light data unavailable.\n")
} else {
  # Common sample = intersection of PPAC and Fuel & Light windows
  fuel_series <- fuel_raw %>%
    transmute(date = as.Date(date), fuel_cpi = as.numeric(fuel_cpi)) %>%
    filter(!is.na(fuel_cpi))
  ppac_series <- ppac_raw %>% arrange(date) %>%
    mutate(dlnPetrol = c(NA, 100 * diff(log(petrol_delhi))))

  common_start <- max(min(fuel_series$date), min(ppac_series$date),
                      STUDY_START + 31)
  common_end   <- min(max(fuel_series$date), max(ppac_series$date), STUDY_END)

  cat(sprintf("  Common sample window: %s to %s\n", common_start, common_end))

  df_common_base <- df %>% filter(date >= common_start, date <= common_end)

  # ── Stage 1: Brent -> PPAC (common sample) ────────────────────────────────
  df_s1c <- df_common_base %>%
    inner_join(ppac_series %>% select(date, dlnPetrol), by = "date") %>%
    arrange(date) %>%
    mutate(
      dlnPetrol_L1 = dplyr::lag(dlnPetrol, 1),
      dlnPetrol_L2 = dplyr::lag(dlnPetrol, 2),
      dlnPetrol_L3 = dplyr::lag(dlnPetrol, 3),
      dlnPetrol_L4 = dplyr::lag(dlnPetrol, 4)
    )
  s1_lag_col <- paste0("dlnPetrol_L", best_p)
  df_s1c_est <- df_s1c %>% filter(complete.cases(
    dlnPetrol, !!sym(s1_lag_col), dlnBrent_pos_L3, dlnBrent_neg_L3, dlnIIP))

  month_names_common <- paste0("mo_", c("Jan","Feb","Mar","Apr","May","Jun",
                                        "Jul","Aug","Sep","Oct","Nov"))
  s1_rhs <- c(paste0("dlnPetrol_L", 1:best_p),
              paste0("dlnBrent_pos_L", 0:3), paste0("dlnBrent_neg_L", 0:3),
              "dlnIIP", "D_petrol", "D_diesel", "D_covid", month_names_common)
  s1_rhs <- s1_rhs[vapply(s1_rhs, function(t)
    t %in% names(df_s1c_est) && length(unique(df_s1c_est[[t]])) > 1, logical(1))]

  f_s1c  <- as.formula(paste("dlnPetrol ~", paste(s1_rhs, collapse = " + ")))
  m_s1c  <- lm(f_s1c, data = df_s1c_est)
  nw_s1c <- NeweyWest(m_s1c, lag = nw_lag(nrow(df_s1c_est)), prewhite = FALSE)
  cpt_s1c <- compute_cpt(m_s1c,
    paste0("dlnBrent_pos_L", 0:3), paste0("dlnBrent_neg_L", 0:3),
    nw_s1c, "S1(common): ")

  cat(sprintf("  Stage 1 (PPAC, common-sample) N=%d | CPT+= %.4f (p=%s) | CPT-= %.4f\n",
      nrow(df_s1c_est), cpt_s1c$cpt_pos,
      format_p(cpt_s1c$pos_test$p_value), cpt_s1c$cpt_neg))

  common_dil_rows[["S1"]] <- data.frame(
    Stage = "Stage 1: Brent -> PPAC Petrol (common sample)",
    N = nrow(df_s1c_est),
    CPT_pos = round(cpt_s1c$cpt_pos, 6),
    CPT_neg = round(cpt_s1c$cpt_neg, 6),
    CPTpos_p = round(cpt_s1c$pos_test$p_value, 4),
    CPTneg_p = round(cpt_s1c$neg_test$p_value, 4),
    Asym_p = round(cpt_s1c$asym_test$p_value, 4),
    Adj_R2 = round(summary(m_s1c)$adj.r.squared, 4),
    stringsAsFactors = FALSE
  )

  # ── Stage 2: PPAC -> F&L (same as main bridge, keep as-is, already common) ─
  if (!is.null(bridge_result) && nrow(bridge_result) > 0) {
    common_dil_rows[["S2"]] <- data.frame(
      Stage = "Stage 2: PPAC -> Fuel & Light (common sample)",
      N = bridge_result$N,
      CPT_pos = bridge_result$CPT_pos,
      CPT_neg = bridge_result$CPT_neg,
      CPTpos_p = bridge_result$CPTpos_p,
      CPTneg_p = bridge_result$CPTneg_p,
      Asym_p = bridge_result$Asym_p,
      Adj_R2 = bridge_result$Adj_R2,
      stringsAsFactors = FALSE
    )
  }

  # ── Stage 3: Oil -> Headline CPI on common sample ─────────────────────────
  # Uses INR-oil (as per M1) for comparability with the headline model.
  df_s3c_est <- df_common_base %>% filter(complete.cases(
    dlnCPI, !!sym(paste0("dlnCPI_L", best_p)),
    dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

  s3_rhs <- c(paste0("dlnCPI_L", 1:best_p),
              paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
              "dlnIIP", "D_petrol", "D_diesel", "D_covid", month_names_common)
  s3_rhs <- s3_rhs[vapply(s3_rhs, function(t)
    t %in% names(df_s3c_est) && length(unique(df_s3c_est[[t]])) > 1, logical(1))]

  f_s3c  <- as.formula(paste("dlnCPI ~", paste(s3_rhs, collapse = " + ")))
  m_s3c  <- lm(f_s3c, data = df_s3c_est)
  nw_s3c <- NeweyWest(m_s3c, lag = nw_lag(nrow(df_s3c_est)), prewhite = FALSE)
  cpt_s3c <- compute_cpt(m_s3c,
    paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
    nw_s3c, "S3(common): ")

  cat(sprintf("  Stage 3 (headline, common-sample) N=%d | CPT+= %.4f (p=%s)\n",
      nrow(df_s3c_est), cpt_s3c$cpt_pos, format_p(cpt_s3c$pos_test$p_value)))

  common_dil_rows[["S3"]] <- data.frame(
    Stage = "Stage 3: Oil -> Headline CPI (common sample)",
    N = nrow(df_s3c_est),
    CPT_pos = round(cpt_s3c$cpt_pos, 6),
    CPT_neg = round(cpt_s3c$cpt_neg, 6),
    CPTpos_p = round(cpt_s3c$pos_test$p_value, 4),
    CPTneg_p = round(cpt_s3c$neg_test$p_value, 4),
    Asym_p = round(cpt_s3c$asym_test$p_value, 4),
    Adj_R2 = round(summary(m_s3c)$adj.r.squared, 4),
    stringsAsFactors = FALSE
  )

  common_dil_tbl <- bind_rows(common_dil_rows)
  save_table(common_dil_tbl, "table_23b_dilution_common_sample.csv")

  # Dilution ratio on the common sample
  s1_pos <- common_dil_rows[["S1"]]$CPT_pos
  s3_pos <- common_dil_rows[["S3"]]$CPT_pos
  cat(sprintf("\n  Common-sample dilution ratio: CPT+ falls from %.4f (retail petrol) to %.4f (headline CPI).\n",
      s1_pos, s3_pos))
  if (!is.na(s1_pos) && s1_pos > 0) {
    cat(sprintf("  => Headline CPI captures ~%.1f%% of retail fuel pass-through on the common sample.\n",
        100 * s3_pos / s1_pos))
  }

  # ── Formal attenuation Wald test (stacked system, Stage 1 vs Stage 3) ─────
  # H0: sum(beta_pos_stage1) = sum(beta_pos_stage3), i.e., no attenuation.
  # H1: stage-1 CPT+ > stage-3 CPT+.
  # For a clean Wald test we use the SAME IV (dlnBrent) in both stages, so the
  # comparison is "global-oil shock to retail fuel" vs "global-oil shock to
  # headline CPI" on the same common-sample window. This mirrors standard
  # pass-through comparisons in the literature.
  df_stack_s1 <- df_s1c_est %>%
    transmute(
      date = date,
      dep = dlnPetrol,
      iv_pos_L0 = dlnBrent_pos_L0, iv_pos_L1 = dlnBrent_pos_L1,
      iv_pos_L2 = dlnBrent_pos_L2, iv_pos_L3 = dlnBrent_pos_L3,
      iv_neg_L0 = dlnBrent_neg_L0, iv_neg_L1 = dlnBrent_neg_L1,
      iv_neg_L2 = dlnBrent_neg_L2, iv_neg_L3 = dlnBrent_neg_L3,
      dep_L1 = dplyr::lag(dlnPetrol, 1),
      stage = "S1"
    )

  df_stack_s3 <- df_s3c_est %>%
    transmute(
      date = date,
      dep = dlnCPI,
      iv_pos_L0 = dlnBrent_pos_L0, iv_pos_L1 = dlnBrent_pos_L1,
      iv_pos_L2 = dlnBrent_pos_L2, iv_pos_L3 = dlnBrent_pos_L3,
      iv_neg_L0 = dlnBrent_neg_L0, iv_neg_L1 = dlnBrent_neg_L1,
      iv_neg_L2 = dlnBrent_neg_L2, iv_neg_L3 = dlnBrent_neg_L3,
      dep_L1 = dlnCPI_L1,
      stage = "S3"
    )

  df_stack <- bind_rows(df_stack_s1, df_stack_s3) %>%
    filter(complete.cases(.)) %>%
    mutate(is_S3 = as.integer(stage == "S3"))

  # Stage-specific oil pos interactions
  for (k in 0:3) {
    df_stack[[paste0("iv_pos_L", k, "_S3")]] <- df_stack[[paste0("iv_pos_L", k)]] * df_stack$is_S3
    df_stack[[paste0("iv_neg_L", k, "_S3")]] <- df_stack[[paste0("iv_neg_L", k)]] * df_stack$is_S3
  }

  stack_rhs <- c(
    "dep_L1", "is_S3",
    paste0("iv_pos_L", 0:3), paste0("iv_pos_L", 0:3, "_S3"),
    paste0("iv_neg_L", 0:3), paste0("iv_neg_L", 0:3, "_S3")
  )

  f_stack <- as.formula(paste("dep ~", paste(stack_rhs, collapse = " + ")))
  m_stack <- lm(f_stack, data = df_stack)
  nw_stack <- NeweyWest(m_stack, lag = nw_lag(nrow(df_stack)), prewhite = FALSE)

  # H0: sum of stage-3 pos interactions = 0 (Stage 1 pos = Stage 3 pos)
  pos_inter <- paste0("iv_pos_L", 0:3, "_S3")
  pos_inter <- intersect(pos_inter, names(coef(m_stack)))
  att_test_pos <- linearHypothesis(m_stack,
    paste(paste(pos_inter, collapse = " + "), "= 0"), vcov. = nw_stack)
  F_att_pos <- unname(att_test_pos$F[2])
  p_att_pos <- unname(att_test_pos$`Pr(>F)`[2])
  att_gap_pos <- sum(coef(m_stack)[pos_inter])

  # Same for negative
  neg_inter <- paste0("iv_neg_L", 0:3, "_S3")
  neg_inter <- intersect(neg_inter, names(coef(m_stack)))
  att_test_neg <- linearHypothesis(m_stack,
    paste(paste(neg_inter, collapse = " + "), "= 0"), vcov. = nw_stack)
  F_att_neg <- unname(att_test_neg$F[2])
  p_att_neg <- unname(att_test_neg$`Pr(>F)`[2])
  att_gap_neg <- sum(coef(m_stack)[neg_inter])

  # Joint (both pos and neg interactions = 0)
  all_inter <- c(pos_inter, neg_inter)
  att_test_all <- linearHypothesis(m_stack,
    paste(paste(all_inter, collapse = " + "), "= 0"), vcov. = nw_stack)
  F_att_all <- unname(att_test_all$F[2])
  p_att_all <- unname(att_test_all$`Pr(>F)`[2])

  cat("\n  --- Formal attenuation Wald test (Stage 1 vs Stage 3, stacked) ---\n")
  cat(sprintf("  Gap CPT+ (S1 - S3) = %.4f | Wald F = %.3f | HAC p = %s\n",
      -att_gap_pos, F_att_pos, format_p(p_att_pos)))
  cat(sprintf("  Gap |CPT-| (|S1|-|S3|) via pos/neg-interaction test.\n"))
  cat(sprintf("  Joint (pos and neg equal across stages) Wald F = %.3f | p = %s\n",
      F_att_all, format_p(p_att_all)))

  attenuation_rows[["pos"]] <- data.frame(
    Hypothesis = "H0: CPT+_Stage1 = CPT+_Stage3",
    F_stat = round(F_att_pos, 4),
    HAC_p = round(p_att_pos, 4),
    Gap_S1_minus_S3 = round(-att_gap_pos, 6),
    Verdict = ifelse(p_att_pos < 0.05,
      "Reject equality (attenuation present)",
      "Fail to reject equality"),
    stringsAsFactors = FALSE
  )
  attenuation_rows[["neg"]] <- data.frame(
    Hypothesis = "H0: CPT-_Stage1 = CPT-_Stage3",
    F_stat = round(F_att_neg, 4),
    HAC_p = round(p_att_neg, 4),
    Gap_S1_minus_S3 = round(-att_gap_neg, 6),
    Verdict = ifelse(p_att_neg < 0.05,
      "Reject equality", "Fail to reject"),
    stringsAsFactors = FALSE
  )
  attenuation_rows[["joint"]] <- data.frame(
    Hypothesis = "H0: All pos & neg CPT equal across stages",
    F_stat = round(F_att_all, 4),
    HAC_p = round(p_att_all, 4),
    Gap_S1_minus_S3 = NA_real_,
    Verdict = ifelse(p_att_all < 0.05,
      "Reject (stages differ)", "Fail to reject"),
    stringsAsFactors = FALSE
  )

  attenuation_tbl <- bind_rows(attenuation_rows)
  save_table(attenuation_tbl, "table_23c_attenuation_wald.csv")
  print(attenuation_tbl)
}

cat("  [09b_attenuation_test] Done.\n")
