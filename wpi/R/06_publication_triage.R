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

save_table(publication_decision, "table_10_publication_decision.csv")
save_table(model_gate, "table_11_model_gate.csv")

print(publication_decision)
cat("  [06_publication_triage] Done.\n")
