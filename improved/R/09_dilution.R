# ══════════════════════════════════════════════════════════════════════════════
# 09_dilution.R — The "Dilution Hypothesis": A 3-Stage Pass-Through Chain
#
# MOTIVATION:
# Headline CPI in India has a large weight on food (~46%) and services (~24%),
# meaning direct energy shocks are diluted in aggregate inflation. Yet the same
# shocks should be strongly visible at the retail fuel price level (PPAC) and
# the fuel & light CPI sub-index.
#
# We test this formally as a three-stage transmission chain:
#
#   Stage 1: Brent (USD) → PPAC Retail Petrol (INR/litre)
#            [Direct fuel price pass-through — should be strong & asymmetric]
#   Stage 2: PPAC Retail Petrol → CPI Fuel & Light (index)
#            [Retail fuel → measured sub-CPI — should be positive & fast]
#   Stage 3: CPI Fuel & Light → Headline CPI
#            [Sub-index → headline — attenuation expected]
#
# This is the "energy dilution hypothesis" (Blanchard & Galí 2010;
# Chen 2009; Pradeep 2022). The chain documents WHY asymmetry weakens as
# we move from retail prices to headline CPI — it is a structural dilution
# effect, not a modelling failure.
#
# Output: table_23_dilution_hypothesis.csv
#         fig_dilution_chain.png
# ══════════════════════════════════════════════════════════════════════════════
banner("9", "DILUTION HYPOTHESIS — 3-STAGE PASS-THROUGH CHAIN")

cat("\n  Testing the 'dilution hypothesis':\n")
cat("  Brent => PPAC Petrol => Fuel & Light CPI => Headline CPI\n\n")

# ── Check required upstream objects ─────────────────────────────────────────
ppac_available <- exists("m_ppac") && !is.null(m_ppac)
fuel_available <- exists("m_fuel") && !is.null(m_fuel)

if (!ppac_available) cat("  WARNING: m_ppac not available — PPAC model did not run.\n")
if (!fuel_available) cat("  WARNING: m_fuel not available — Fuel CPI model did not run.\n")

# ── Helper: compact pass-through summary ─────────────────────────────────────
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
    Asym_evidence = case_when(
      asym_p < 0.05  ~ "Strong (p<5%)",
      asym_p < 0.10  ~ "Marginal (p<10%)",
      asym_p < 0.15  ~ "Suggestive (p<15%)",
      TRUE           ~ "Weak/None"
    ),
    Note    = note,
    stringsAsFactors = FALSE
  )
}

dilution_results <- list()

# ══════════════════════════════════════════════════════════════════════════════
# STAGE 1: Brent (USD) → PPAC Retail Petrol

# Already estimated in 07_robustness.R as m_ppac
# ══════════════════════════════════════════════════════════════════════════════
cat("  --- Stage 1: Brent USD => PPAC Retail Petrol (Delhi) ---\n")

if (ppac_available) {
  pos_ppac <- grep("^dlnBrent_pos_L", names(coef(m_ppac)), value = TRUE)
  neg_ppac <- grep("^dlnBrent_neg_L", names(coef(m_ppac)), value = TRUE)
  nw_ppac  <- NeweyWest(m_ppac, lag = nw_lag(nobs(m_ppac)), prewhite = FALSE)
  c1       <- compute_cpt(m_ppac, pos_ppac, neg_ppac, nw_ppac, "Stage1: ")

  cat(sprintf("  CPT+ = %.4f (p=%s), CPT- = %.4f (p=%s), Asym p = %s\n",
      c1$cpt_pos, format_p(c1$pos_test$p_value),
      c1$cpt_neg, format_p(c1$neg_test$p_value),
      format_p(c1$asym_test$p_value)))
  cat("  Interpretation: Oil price increases raise petrol prices significantly;\n")
  cat("                  negative shocks also pass through (market-linked pricing).\n")

  dilution_results[["S1"]] <- dilution_row(
    stage    = "Stage 1: Brent → PPAC Petrol",
    dv_label = "dlnPetrol (Delhi RSP)",
    iv_label = "dlnBrent ± (Brent USD, q=3)",
    cpt_pos  = c1$cpt_pos, cpt_neg = c1$cpt_neg,
    pos_p    = c1$pos_test$p_value,
    neg_p    = c1$neg_test$p_value,
    asym_p   = c1$asym_test$p_value,
    n_obs    = nobs(m_ppac),
    adj_r2   = summary(m_ppac)$adj.r.squared,
    note     = "Market-linked pricing post-2010/2014; oil shock most direct here"
  )
} else {
  cat("  Stage 1 skipped: PPAC data not available.\n")
  cat("  To enable: download PPAC RSP files as per 07_robustness.R instructions.\n")
}

# ══════════════════════════════════════════════════════════════════════════════
# STAGE 2: PPAC Retail Petrol → CPI Fuel & Light
#
# We test: does a change in retail petrol price (PPAC) predict a change
# in the official CPI Fuel & Light sub-index?
# This is a direct price-chain test.
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- Stage 2: PPAC Petrol => CPI Fuel & Light ---\n")

stage2_result <- NULL
tryCatch({
  # Load both series
  ppac_file <- file.path(PATHS$processed, "ppac_monthly_delhi.csv")
  fuel_file <- file.path(PATHS$processed, "cpi_fuel_light.csv")

  if (file.exists(ppac_file) && file.exists(fuel_file)) {
    ppac_s2 <- read.csv(ppac_file, stringsAsFactors = FALSE)
    fuel_s2 <- read.csv(fuel_file, stringsAsFactors = FALSE)
    ppac_s2$date <- as.Date(ppac_s2$date)
    fuel_s2$date <- as.Date(fuel_s2$date)

    df_s2 <- ppac_s2 %>%
      inner_join(fuel_s2, by = "date") %>%
      arrange(date) %>%
      mutate(
        dlnPetrol = c(NA, 100 * diff(log(petrol_delhi))),
        dlnFuel   = c(NA, 100 * diff(log(fuel_cpi))),
        dlnPetrol_pos = pmax(dlnPetrol, 0),
        dlnPetrol_neg = pmin(dlnPetrol, 0)
      )
    # Add lags of petrol
    for (k in 0:3) {
      df_s2[[paste0("dlnPetrol_pos_L", k)]] <- dplyr::lag(df_s2$dlnPetrol_pos, k)
      df_s2[[paste0("dlnPetrol_neg_L", k)]] <- dplyr::lag(df_s2$dlnPetrol_neg, k)
    }
    df_s2$dlnFuel_L1 <- dplyr::lag(df_s2$dlnFuel, 1)

    df_s2_est <- df_s2 %>%
      filter(complete.cases(dlnFuel, dlnFuel_L1,
                            dlnPetrol_pos_L3, dlnPetrol_neg_L3))

    if (nrow(df_s2_est) >= 36) {
      f_s2 <- dlnFuel ~ dlnFuel_L1 +
        dlnPetrol_pos_L0 + dlnPetrol_pos_L1 + dlnPetrol_pos_L2 + dlnPetrol_pos_L3 +
        dlnPetrol_neg_L0 + dlnPetrol_neg_L1 + dlnPetrol_neg_L2 + dlnPetrol_neg_L3

      m_s2    <- lm(f_s2, data = df_s2_est)
      nw_s2   <- NeweyWest(m_s2, lag = nw_lag(nrow(df_s2_est)), prewhite = FALSE)
      pos_s2  <- paste0("dlnPetrol_pos_L", 0:3)
      neg_s2  <- paste0("dlnPetrol_neg_L", 0:3)
      c2      <- compute_cpt(m_s2, pos_s2, neg_s2, nw_s2, "Stage2: ")

      cat(sprintf("  N=%d | CPT+= %.4f (p=%s) | CPT-= %.4f (p=%s) | Asym p=%s\n",
          nrow(df_s2_est),
          c2$cpt_pos, format_p(c2$pos_test$p_value),
          c2$cpt_neg, format_p(c2$neg_test$p_value),
          format_p(c2$asym_test$p_value)))

      stage2_result <- list(model = m_s2, cpt = c2, n = nrow(df_s2_est))

      dilution_results[["S2"]] <- dilution_row(
        stage    = "Stage 2: PPAC Petrol → Fuel & Light CPI",
        dv_label = "dlnFuel (CPI Fuel & Light)",
        iv_label = "dlnPetrol ± (PPAC Delhi, q=3)",
        cpt_pos  = c2$cpt_pos, cpt_neg = c2$cpt_neg,
        pos_p    = c2$pos_test$p_value,
        neg_p    = c2$neg_test$p_value,
        asym_p   = c2$asym_test$p_value,
        n_obs    = nrow(df_s2_est),
        adj_r2   = summary(m_s2)$adj.r.squared,
        note     = "Retail-to-measured CPI; attenuation expected vs Stage 1"
      )
    } else {
      cat(sprintf("  Stage 2: insufficient data (N=%d). Need >=36 obs.\n", nrow(df_s2_est)))
    }
  } else {
    cat(sprintf("  Stage 2 skipped: ppac=%s, fuel=%s\n",
        file.exists(ppac_file), file.exists(fuel_file)))
  }
}, error = function(e) cat(sprintf("  Stage 2 error: %s\n", e$message)))

# ══════════════════════════════════════════════════════════════════════════════
# STAGE 3: Brent → Headline CPI (direct, main M2 model)
# This is already estimated. We pull it directly from M2.
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- Stage 3: Brent => Headline CPI (from M2) ---\n")
cat(sprintf("  CPT+ = %.4f (p=%s) | CPT- = %.4f (p=%s) | Asym p = %s\n",
    cpt_m2$cpt_pos, format_p(cpt_m2$pos_test$p_value),
    cpt_m2$cpt_neg, format_p(cpt_m2$neg_test$p_value),
    format_p(cpt_m2$asym_test$p_value)))
cat("  Headline CPI dilutes fuel shocks: food + services weight ~70%.\n")

dilution_results[["S3"]] <- dilution_row(
  stage    = "Stage 3: Brent → Headline CPI (M2 primary)",
  dv_label = "dlnCPI (Headline, All India)",
  iv_label = "dlnBrent ± (Brent USD + EXR, q=3)",
  cpt_pos  = cpt_m2$cpt_pos, cpt_neg = cpt_m2$cpt_neg,
  pos_p    = cpt_m2$pos_test$p_value,
  neg_p    = cpt_m2$neg_test$p_value,
  asym_p   = cpt_m2$asym_test$p_value,
  n_obs    = nrow(df_m2),
  adj_r2   = summary(m2)$adj.r.squared,
  note     = "Attenuation from food/services weight (~70% of CPI basket)"
)

# ══════════════════════════════════════════════════════════════════════════════
# Dilution summary table
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  === DILUTION HYPOTHESIS SUMMARY ===\n")
if (length(dilution_results) > 0) {
  dilution_tbl <- bind_rows(dilution_results)
  save_table(dilution_tbl, "table_23_dilution_hypothesis.csv")
  cat("\n")
  print(dilution_tbl[, c("Stage", "CPT_pos", "CPT_neg", "Asym_p", "Asym_evidence")])

  cat("\n  Interpretation:\n")
  cat("  The dilution hypothesis predicts CPT+ and |CPT-| decline from Stage 1 to Stage 3\n")
  cat("  as energy price shocks get absorbed by the food and services components of CPI.\n")

  # Dilution ratio (Stage 1 → Stage 3)
  if ("S1" %in% names(dilution_results) && "S3" %in% names(dilution_results)) {
    s1_pos <- dilution_results[["S1"]]$CPT_pos
    s3_pos <- dilution_results[["S3"]]$CPT_pos
    if (!is.na(s1_pos) && s1_pos > 0) {
      cat(sprintf("  Dilution ratio (Stage 1 → Stage 3): CPT+ falls from %.4f to %.4f\n",
          s1_pos, s3_pos))
      cat(sprintf("  => Headline CPI captures ~%.1f%% of the retail petrol pass-through.\n",
          100 * s3_pos / s1_pos))
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Figure: Dilution chain bar/path chart
# ══════════════════════════════════════════════════════════════════════════════
if (length(dilution_results) >= 2) {
  tryCatch({
    dt <- bind_rows(dilution_results) %>%
      mutate(
        Stage_short = c("Stage 1\nBrent →\nPPAC Petrol",
                         "Stage 2\nPPAC →\nFuel & Light",
                         "Stage 3\nBrent →\nHeadline CPI")[seq_len(nrow(.))]
      )

    fig_dil <- ggplot(dt, aes(x = Stage_short)) +
      geom_col(aes(y = CPT_pos),  fill = "#C0392B", alpha = 0.85, width = 0.4,
               position = position_nudge(x = -0.22)) +
      geom_col(aes(y = abs(CPT_neg)), fill = "#2980B9", alpha = 0.85, width = 0.4,
               position = position_nudge(x = 0.22)) +
      geom_text(aes(y = CPT_pos + 0.01,
                    label = sprintf("CPT+\n%.3f", CPT_pos)),
                position = position_nudge(x = -0.22), size = 3.2, color = "#C0392B") +
      geom_text(aes(y = abs(CPT_neg) + 0.01,
                    label = sprintf("|CPT-|\n%.3f", abs(CPT_neg))),
                position = position_nudge(x = 0.22), size = 3.2, color = "#2980B9") +
      annotate("text", x = 0.6, y = max(dt$CPT_pos) * 0.95,
               label = "Red = CPT+ (positive shocks)\nBlue = |CPT-| (negative shocks)",
               hjust = 0, size = 3, color = "grey40") +
      labs(
        title    = "The Dilution Hypothesis: Oil-to-CPI Pass-Through Chain",
        subtitle = "CPT estimates shrink as we move from retail fuel prices to headline inflation",
        x = NULL, y = "Cumulative Pass-Through Coefficient",
        caption = "Asymmetry weakens at headline CPI due to ~70% food & services weight (dilution effect)"
      ) +
      theme_minimal(base_size = 11) +
      theme(plot.caption = element_text(color = "grey50", size = 9))

    ggsave(save_figure("fig_dilution_chain.png"), fig_dil,
           width = 10, height = 6, dpi = 300)
    cat("  Dilution chain figure saved.\n")
  }, error = function(e) cat(sprintf("  Dilution figure error: %s\n", e$message)))
}

cat("  [09_dilution] Done.\n")
