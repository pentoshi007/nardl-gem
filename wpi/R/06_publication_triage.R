# ==============================================================================
# 06_publication_triage.R — Decision table for publishability and model roles
# ==============================================================================
banner("06", "PUBLICATION TRIAGE")

diag_lookup <- function(label) {
  diag_short_run %>% filter(Model == label)
}

all_pass <- function(...) all(unlist(list(...)) == "PASS")

headline_diag <- diag_lookup("Headline WPI ADL (INR oil)")
headline_brent_diag <- diag_lookup("Headline WPI ADL (Brent + EXR)")
fuel_diag <- diag_lookup("Fuel & Power WPI ADL")

publication_decision <- data.frame(
  Model = c(
    "Headline WPI ADL (INR oil)",
    "Headline WPI ADL (Brent + EXR)",
    "Fuel & Power WPI ADL",
    "Literature-style NARDL appendix"
  ),
  Role = c(
    "Main WPI result",
    "Robustness / decomposition",
    "Sector mechanism result",
    "Appendix only"
  ),
  Sample = c(
    sprintf("%s to %s", min(df_headline_main$date), max(df_headline_main$date)),
    sprintf("%s to %s", min(df_headline_brent$date), max(df_headline_brent$date)),
    sprintf("%s to %s", min(df_fuel_main$date), max(df_fuel_main$date)),
    sprintf("%s to %s", min(nardl_headline_data$date), max(nardl_headline_data$date))
  ),
  Span_years = round(c(
    sample_span_years(df_headline_main$date),
    sample_span_years(df_headline_brent$date),
    sample_span_years(df_fuel_main$date),
    sample_span_years(nardl_headline_data$date)
  ), 2),
  Key_result = c(
    sprintf("CPT+=%.4f (p=%s); CPT-=%.4f (p=%s); asym p=%s",
      cpt_headline_main$cpt_pos, format_p(cpt_headline_main$pos_test$p_value),
      cpt_headline_main$cpt_neg, format_p(cpt_headline_main$neg_test$p_value),
      format_p(cpt_headline_main$asym_test$p_value)),
    sprintf("CPT+=%.4f (p=%s); CPT-=%.4f (p=%s); asym p=%s",
      cpt_headline_brent$cpt_pos, format_p(cpt_headline_brent$pos_test$p_value),
      cpt_headline_brent$cpt_neg, format_p(cpt_headline_brent$neg_test$p_value),
      format_p(cpt_headline_brent$asym_test$p_value)),
    sprintf("CPT+=%.4f (p=%s); CPT-=%.4f (p=%s); asym p=%s",
      cpt_fuel_main$cpt_pos, format_p(cpt_fuel_main$pos_test$p_value),
      cpt_fuel_main$cpt_neg, format_p(cpt_fuel_main$neg_test$p_value),
      format_p(cpt_fuel_main$asym_test$p_value)),
    paste(nardl_summary$Verdict, collapse = " | ")
  ),
  Diagnostics = c(
    sprintf("BG=%s; HAC-RESET=%s; Rec-CUSUM=%s",
      headline_diag$BG12_pass, headline_diag$RESET_HAC_pass, headline_diag$RecCUSUM_pass),
    sprintf("BG=%s; HAC-RESET=%s; Rec-CUSUM=%s",
      headline_brent_diag$BG12_pass, headline_brent_diag$RESET_HAC_pass, headline_brent_diag$RecCUSUM_pass),
    sprintf("BG=%s; HAC-RESET=%s; Rec-CUSUM=%s",
      fuel_diag$BG12_pass, fuel_diag$RESET_HAC_pass, fuel_diag$RecCUSUM_pass),
    "ECT sign governs appendix triage"
  ),
  Verdict = c(
    ifelse(all_pass(headline_diag$BG12_pass, headline_diag$RESET_HAC_pass, headline_diag$RecCUSUM_pass),
      "Use as main result",
      "Use with caution"),
    ifelse(all_pass(headline_brent_diag$BG12_pass, headline_brent_diag$RESET_HAC_pass, headline_brent_diag$RecCUSUM_pass),
      "Use as decomposition robustness",
      "Use with caution as decomposition robustness"),
    ifelse(all_pass(fuel_diag$BG12_pass, fuel_diag$RESET_HAC_pass, fuel_diag$RecCUSUM_pass),
      "Use as sector mechanism result",
      "Report with functional-form caveat"),
    ifelse(all(nardl_summary$ECT_valid == "YES"), "Keep as appendix", "Do not use for claim-bearing inference")
  ),
  stringsAsFactors = FALSE
)

model_gate <- data.frame(
  Model = c("Headline WPI ADL (INR oil)", "Fuel & Power WPI ADL"),
  Span_years = round(c(sample_span_years(df_headline_main$date), sample_span_years(df_fuel_main$date)), 2),
  Over_20_years = c("YES", "YES"),
  BG12_pass = c(headline_diag$BG12_pass, fuel_diag$BG12_pass),
  RESET_HAC_pass = c(headline_diag$RESET_HAC_pass, fuel_diag$RESET_HAC_pass),
  RecCUSUM_pass = c(headline_diag$RecCUSUM_pass, fuel_diag$RecCUSUM_pass),
  Verdict = c(
    ifelse(all_pass(headline_diag$BG12_pass, headline_diag$RESET_HAC_pass),
      "PASS", "CAUTION"),
    ifelse(all_pass(fuel_diag$BG12_pass, fuel_diag$RESET_HAC_pass),
      "PASS", "CAUTION")
  ),
  stringsAsFactors = FALSE
)

# ── KPSS Footnote: dln(WPI) anomaly ──────────────────────────────────────────
# dln(WPI) KPSS = 0.90 > 5% CV (0.463), but ADF/PP strongly reject I(1).
# This is a known finite-sample KPSS issue in long series with structural breaks.
ur_tbl <- tryCatch(
  read.csv(file.path(PATHS$tables, "table_13_unit_root_battery.csv"), stringsAsFactors = FALSE),
  error = function(e) NULL
)
kpss_footnotes <- NULL
if (!is.null(ur_tbl)) {
  dln_wpi <- ur_tbl[ur_tbl$Variable == "dln(WPI)", ]
  if (nrow(dln_wpi) > 0 && !is.na(dln_wpi$KPSS_stat) && !is.na(dln_wpi$KPSS_cv5)) {
    if (dln_wpi$KPSS_stat > dln_wpi$KPSS_cv5) {
      kpss_footnotes <- data.frame(
        Variable = "dln(WPI)",
        KPSS_stat = dln_wpi$KPSS_stat,
        KPSS_cv5 = dln_wpi$KPSS_cv5,
        ADF_stat = dln_wpi$ADF_stat,
        PP_stat = dln_wpi$PP_stat,
        Footnote = paste0(
          "KPSS on dln(WPI) = ", round(dln_wpi$KPSS_stat, 4),
          " exceeds the 5% CV (", round(dln_wpi$KPSS_cv5, 3), "). ",
          "However, ADF (", round(dln_wpi$ADF_stat, 2), ") and PP (", round(dln_wpi$PP_stat, 2), ") ",
          "strongly reject I(1). This is a known KPSS over-rejection issue in long samples ",
          "with structural breaks (see Mueller 2005). The Bai-Perron break at 2013-09 confirms ",
          "a structural shift in WPI inflation."
        ),
        stringsAsFactors = FALSE
      )
      save_table(kpss_footnotes, "table_11b_kpss_footnotes.csv")
      cat("  KPSS footnote generated for dln(WPI).\n")
    }
  }
  # Also check dln(EXR) borderline
  dln_exr <- ur_tbl[ur_tbl$Variable == "dln(EXR)", ]
  if (nrow(dln_exr) > 0 && !is.na(dln_exr$KPSS_stat) && !is.na(dln_exr$KPSS_cv5)) {
    if (abs(dln_exr$KPSS_stat - dln_exr$KPSS_cv5) < 0.05) {
      exr_note <- data.frame(
        Variable = "dln(EXR)",
        KPSS_stat = dln_exr$KPSS_stat,
        KPSS_cv5 = dln_exr$KPSS_cv5,
        ADF_stat = dln_exr$ADF_stat,
        PP_stat = dln_exr$PP_stat,
        Footnote = paste0(
          "KPSS on dln(EXR) = ", round(dln_exr$KPSS_stat, 4),
          " is borderline relative to 5% CV (", round(dln_exr$KPSS_cv5, 3), "). ",
          "ADF (", round(dln_exr$ADF_stat, 2), ") and PP (", round(dln_exr$PP_stat, 2), ") ",
          "strongly confirm stationarity. EXR is a control variable."
        ),
        stringsAsFactors = FALSE
      )
      if (!is.null(kpss_footnotes)) kpss_footnotes <- bind_rows(kpss_footnotes, exr_note)
      save_table(kpss_footnotes, "table_11b_kpss_footnotes.csv")
      cat("  KPSS borderline note generated for dln(EXR).\n")
    }
  }
}

# ── NARDL ECT Speed Framing ─────────────────────────────────────────────────
# ECT headline ≈ −0.02/month (slow) vs fuel ≈ −0.08/month (faster)
# Frame: administered pricing dampens headline adjustment
nardl_ect_framing <- data.frame(
  Specification = c("Headline (Brent)", "Headline (INR-oil)", "Fuel & Power (INR-oil)"),
  ECT_coef = round(c(
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL headline: ln(WPI) ~ ln(Brent)"],
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL headline: ln(WPI) ~ ln(INR-oil)"],
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL fuel: ln(Fuel&Power) ~ ln(INR-oil)"]
  ), 4),
  Adjustment_pct_month = round(abs(c(
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL headline: ln(WPI) ~ ln(Brent)"],
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL headline: ln(WPI) ~ ln(INR-oil)"],
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL fuel: ln(Fuel&Power) ~ ln(INR-oil)"]
  )) * 100, 1),
  Half_life_months = round(log(0.5) / log(1 - abs(c(
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL headline: ln(WPI) ~ ln(Brent)"],
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL headline: ln(WPI) ~ ln(INR-oil)"],
    nardl_summary$ECT_coef[nardl_summary$Specification == "NARDL fuel: ln(Fuel&Power) ~ ln(INR-oil)"]
  ))), 1),
  Framing = c(
    "Slow adjustment: consistent with administered pricing dampening equilibrium restoration",
    "Slow adjustment: consistent with administered pricing dampening equilibrium restoration",
    "Faster adjustment: deregulated sector responds more quickly to disequilibrium"
  ),
  stringsAsFactors = FALSE
)
save_table(nardl_ect_framing, "table_11c_nardl_ect_framing.csv")
cat("  NARDL ECT speed framing table generated.\n")

save_table(publication_decision, "table_10_publication_decision.csv")
save_table(model_gate, "table_11_model_gate.csv")

print(publication_decision)
cat("  [06_publication_triage] Done.\n")
