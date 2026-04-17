# ==============================================================================
# 04_diagnostics.R — Diagnostics on the short-run claim-bearing models
# ==============================================================================
banner("04", "DIAGNOSTICS")

diag_short_run <- bind_rows(
  run_diagnostics(m_headline_main, f_headline_main, df_headline_main, "Headline WPI ADL (INR oil)"),
  run_diagnostics(m_headline_brent, f_headline_brent, df_headline_brent, "Headline WPI ADL (Brent + EXR)"),
  run_diagnostics(m_fuel_main, f_fuel_main, df_fuel_main, "Fuel & Power WPI ADL")
)

save_table(diag_short_run, "table_09_diagnostics.csv")

for (i in seq_len(nrow(diag_short_run))) {
  r <- diag_short_run[i, ]
  cat(sprintf("\n  %s:\n", r$Model))
  cat(sprintf("    BG(12) p = %.4f [%s]\n", r$BG12_p, r$BG12_pass))
  cat(sprintf("    HAC-RESET p = %.4f [%s]\n", r$RESET_HAC_p, r$RESET_HAC_pass))
  cat(sprintf("    Rec-CUSUM p = %.4f [%s]\n", r$RecCUSUM_p, r$RecCUSUM_pass))
  cat(sprintf("    OLS-CUSUM p = %.4f [%s]\n", r$OLS_CUSUM_p, r$OLS_CUSUM_pass))
}

cat("  [04_diagnostics] Done.\n")
