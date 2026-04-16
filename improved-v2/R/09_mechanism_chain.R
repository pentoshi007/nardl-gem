# ==============================================================================
# 09_mechanism_chain.R — 3-Stage Dilution Hypothesis
# ==============================================================================
# Stage 1: Brent (USD) -> PPAC Retail Petrol (Delhi)
# Stage 2: PPAC Retail Petrol -> CPI Fuel & Light
# Stage 3: Oil -> Headline CPI (M1 and M2 results)
#
# Motivation: Blanchard & Gali (2010), Chen (2009), Pradeep (2022)
# Energy dilution: food+services ~70% of CPI basket
# ==============================================================================
banner("09", "MECHANISM CHAIN — DILUTION HYPOTHESIS")

cat("  Testing 3-stage transmission:\n")
cat("  Brent => PPAC Petrol => Fuel & Light CPI => Headline CPI\n\n")

# ── Helper: compact dilution row ─────────────────────────────────────────────
dilution_row <- function(stage, dv_label, iv_label, cpt_pos, cpt_neg,
                          pos_p, neg_p, asym_p, n_obs, adj_r2, note = "") {
  data.frame(
    Stage   = stage,
    DV      = dv_label,
    IV      = iv_label,
    N       = n_obs,
    CPT_pos = round(cpt_pos, 6),
    CPT_neg = round(cpt_neg, 6),
    CPTpos_p = round(pos_p, 4),
    CPTneg_p = round(neg_p, 4),
    Asym_p   = round(asym_p, 4),
    Adj_R2   = round(adj_r2, 4),
    Asym_evidence = ifelse(asym_p < 0.05, "Strong (p<5%)",
                    ifelse(asym_p < 0.10, "Marginal (p<10%)",
                    ifelse(asym_p < 0.15, "Suggestive (p<15%)", "Weak/None"))),
    Note    = note,
    stringsAsFactors = FALSE
  )
}

dilution_results <- list()

# ==============================================================================
# STAGE 1: Brent (USD) -> PPAC Retail Petrol
# ==============================================================================
cat("  --- Stage 1: Brent USD => PPAC Retail Petrol (Delhi) ---\n")

m_ppac <- NULL
if (ppac_available) {
  # Build petrol pass-through model
  ppac_df <- ppac_raw %>%
    arrange(date) %>%
    mutate(
      dlnPetrol = c(NA, 100 * diff(log(petrol_delhi))),
      dlnPetrol_L1 = dplyr::lag(dlnPetrol, 1)
    )

  # Merge with Brent data
  brent_study <- brent_raw %>%
    filter(date >= STUDY_START & date <= STUDY_END) %>%
    mutate(
      dlnBrent = c(NA, 100 * diff(log(brent_usd))),
      dlnBrent_pos = pmax(dlnBrent, 0),
      dlnBrent_neg = pmin(dlnBrent, 0)
    )

  for (k in 0:3) {
    brent_study[[paste0("dlnBrent_pos_L", k)]] <- dplyr::lag(brent_study$dlnBrent_pos, k)
    brent_study[[paste0("dlnBrent_neg_L", k)]] <- dplyr::lag(brent_study$dlnBrent_neg, k)
  }

  ppac_est <- ppac_df %>%
    inner_join(brent_study[, c("date", grep("dlnBrent", names(brent_study), value = TRUE))],
               by = "date") %>%
    filter(complete.cases(dlnPetrol, dlnPetrol_L1, dlnBrent_pos_L3, dlnBrent_neg_L3))

  if (nrow(ppac_est) >= 36) {
    f_ppac <- dlnPetrol ~ dlnPetrol_L1 +
      dlnBrent_pos_L0 + dlnBrent_pos_L1 + dlnBrent_pos_L2 + dlnBrent_pos_L3 +
      dlnBrent_neg_L0 + dlnBrent_neg_L1 + dlnBrent_neg_L2 + dlnBrent_neg_L3

    m_ppac   <- lm(f_ppac, data = ppac_est)
    nw_ppac  <- NeweyWest(m_ppac, lag = nw_lag(nrow(ppac_est)), prewhite = FALSE)
    pos_ppac <- paste0("dlnBrent_pos_L", 0:3)
    neg_ppac <- paste0("dlnBrent_neg_L", 0:3)
    c1       <- compute_cpt(m_ppac, pos_ppac, neg_ppac, nw_ppac, "Stage1: ")

    cat(sprintf("  N=%d | CPT+= %.4f (p=%s) | CPT-= %.4f (p=%s) | Asym p = %s\n",
        nrow(ppac_est),
        c1$cpt_pos, format_p(c1$pos_test$p_value),
        c1$cpt_neg, format_p(c1$neg_test$p_value),
        format_p(c1$asym_test$p_value)))

    save_table(coef_table(m_ppac, nw_ppac), "table_22_ppac_retail_fuel.csv")

    dilution_results[["S1"]] <- dilution_row(
      stage    = "Stage 1: Brent -> PPAC Petrol",
      dv_label = "dlnPetrol (Delhi RSP)",
      iv_label = "dlnBrent +/- (Brent USD, q=3)",
      cpt_pos  = c1$cpt_pos, cpt_neg = c1$cpt_neg,
      pos_p    = c1$pos_test$p_value, neg_p = c1$neg_test$p_value,
      asym_p   = c1$asym_test$p_value,
      n_obs    = nrow(ppac_est), adj_r2 = summary(m_ppac)$adj.r.squared,
      note     = "Market-linked pricing post-2010/2014"
    )
  } else {
    cat(sprintf("  Stage 1: insufficient data (N=%d)\n", nrow(ppac_est)))
  }
} else {
  cat("  Stage 1 skipped: PPAC data not available.\n")
}

# ==============================================================================
# STAGE 2: PPAC Retail Petrol -> CPI Fuel & Light
# ==============================================================================
cat("\n  --- Stage 2: PPAC Petrol => CPI Fuel & Light ---\n")

m_fuel <- NULL
if (ppac_available && fuel_available) {
  tryCatch({
    df_s2 <- ppac_raw %>%
      inner_join(fuel_raw, by = "date") %>%
      arrange(date) %>%
      mutate(
        dlnPetrol = c(NA, 100 * diff(log(petrol_delhi))),
        dlnFuel   = c(NA, 100 * diff(log(fuel_cpi))),
        dlnPetrol_pos = pmax(dlnPetrol, 0),
        dlnPetrol_neg = pmin(dlnPetrol, 0)
      )

    for (k in 0:3) {
      df_s2[[paste0("dlnPetrol_pos_L", k)]] <- dplyr::lag(df_s2$dlnPetrol_pos, k)
      df_s2[[paste0("dlnPetrol_neg_L", k)]] <- dplyr::lag(df_s2$dlnPetrol_neg, k)
    }
    df_s2$dlnFuel_L1 <- dplyr::lag(df_s2$dlnFuel, 1)

    df_s2_est <- df_s2 %>%
      filter(complete.cases(dlnFuel, dlnFuel_L1, dlnPetrol_pos_L3, dlnPetrol_neg_L3))

    if (nrow(df_s2_est) >= 36) {
      f_s2 <- dlnFuel ~ dlnFuel_L1 +
        dlnPetrol_pos_L0 + dlnPetrol_pos_L1 + dlnPetrol_pos_L2 + dlnPetrol_pos_L3 +
        dlnPetrol_neg_L0 + dlnPetrol_neg_L1 + dlnPetrol_neg_L2 + dlnPetrol_neg_L3

      m_fuel  <- lm(f_s2, data = df_s2_est)
      nw_s2   <- NeweyWest(m_fuel, lag = nw_lag(nrow(df_s2_est)), prewhite = FALSE)
      pos_s2  <- paste0("dlnPetrol_pos_L", 0:3)
      neg_s2  <- paste0("dlnPetrol_neg_L", 0:3)
      c2      <- compute_cpt(m_fuel, pos_s2, neg_s2, nw_s2, "Stage2: ")

      cat(sprintf("  N=%d | CPT+= %.4f (p=%s) | CPT-= %.4f (p=%s) | Asym p = %s\n",
          nrow(df_s2_est),
          c2$cpt_pos, format_p(c2$pos_test$p_value),
          c2$cpt_neg, format_p(c2$neg_test$p_value),
          format_p(c2$asym_test$p_value)))

      save_table(coef_table(m_fuel, nw_s2), "table_16_fuel_light.csv")

      dilution_results[["S2"]] <- dilution_row(
        stage    = "Stage 2: PPAC Petrol -> Fuel & Light CPI",
        dv_label = "dlnFuel (CPI Fuel & Light)",
        iv_label = "dlnPetrol +/- (PPAC Delhi, q=3)",
        cpt_pos  = c2$cpt_pos, cpt_neg = c2$cpt_neg,
        pos_p    = c2$pos_test$p_value, neg_p = c2$neg_test$p_value,
        asym_p   = c2$asym_test$p_value,
        n_obs    = nrow(df_s2_est), adj_r2 = summary(m_fuel)$adj.r.squared,
        note     = "Retail-to-CPI channel; attenuation expected vs Stage 1"
      )
    } else {
      cat(sprintf("  Stage 2: insufficient data (N=%d)\n", nrow(df_s2_est)))
    }
  }, error = function(e) cat(sprintf("  Stage 2 error: %s\n", e$message)))
} else {
  missing <- c(if (!ppac_available) "PPAC", if (!fuel_available) "Fuel CPI")
  cat(sprintf("  Stage 2 skipped: %s not available.\n", paste(missing, collapse = ", ")))
}

# ==============================================================================
# STAGE 3: Oil -> Headline CPI (from M1 and M2)
# ==============================================================================
cat("\n  --- Stage 3: Oil => Headline CPI (M1 headline + M2 decomposition) ---\n")

# Use M1 as the primary Stage 3 result
cat(sprintf("  M1 (headline): CPT+= %.4f (p=%s) | CPT-= %.4f (p=%s) | Asym p = %s\n",
    cpt_m1$cpt_pos, format_p(cpt_m1$pos_test$p_value),
    cpt_m1$cpt_neg, format_p(cpt_m1$neg_test$p_value),
    format_p(cpt_m1$asym_test$p_value)))

dilution_results[["S3"]] <- dilution_row(
  stage    = "Stage 3: Oil -> Headline CPI (M1)",
  dv_label = "dlnCPI (Headline, All India)",
  iv_label = "dlnOil_INR +/- (INR oil, q=3)",
  cpt_pos  = cpt_m1$cpt_pos, cpt_neg = cpt_m1$cpt_neg,
  pos_p    = cpt_m1$pos_test$p_value, neg_p = cpt_m1$neg_test$p_value,
  asym_p   = cpt_m1$asym_test$p_value,
  n_obs    = nrow(df_m1), adj_r2 = summary(m1)$adj.r.squared,
  note     = "Headline CPI dilutes fuel shocks (~70% food+services weight)"
)

# ==============================================================================
# Dilution summary
# ==============================================================================
cat("\n  === DILUTION HYPOTHESIS SUMMARY ===\n")
if (length(dilution_results) > 0) {
  dilution_tbl <- bind_rows(dilution_results)
  save_table(dilution_tbl, "table_23_dilution_hypothesis.csv")
  print(dilution_tbl[, c("Stage", "CPT_pos", "CPT_neg", "Asym_p", "Asym_evidence")])

  cat("\n  Interpretation:\n")
  cat("  CPT+ and |CPT-| should decline from Stage 1 to Stage 3\n")
  cat("  as energy shocks get absorbed by food and services CPI components.\n")

  # Dilution ratio
  if ("S1" %in% names(dilution_results) && "S3" %in% names(dilution_results)) {
    s1_pos <- dilution_results[["S1"]]$CPT_pos
    s3_pos <- dilution_results[["S3"]]$CPT_pos
    if (!is.na(s1_pos) && s1_pos > 0) {
      cat(sprintf("  Dilution ratio: CPT+ falls from %.4f to %.4f\n", s1_pos, s3_pos))
      cat(sprintf("  => Headline CPI captures ~%.1f%% of retail fuel pass-through.\n",
          100 * s3_pos / s1_pos))
    }
  }
}

cat("  [09_mechanism_chain] Done.\n")
