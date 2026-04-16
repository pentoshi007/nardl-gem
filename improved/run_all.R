# ══════════════════════════════════════════════════════════════════════════════
# run_all.R — Master orchestrator for improved dissertation analysis
# ══════════════════════════════════════════════════════════════════════════════
# Title: Do Global Oil Price Shocks Raise India's Inflation More Than
#        They Lower It? — Asymmetric Pass-Through to CPI (2004-2024)
# Author: Aniket Pandey | JNU MS Economics 2026
# ══════════════════════════════════════════════════════════════════════════════
#
# Usage:
#   cd /Users/aniketpandey/Documents/dissertationv2
#   Rscript improved/run_all.R
#
# Or from RStudio: set working directory to the project root first.
# ══════════════════════════════════════════════════════════════════════════════

total_start <- proc.time()

cat("\n")
cat("================================================================\n")
cat("  IMPROVED DISSERTATION ANALYSIS — FULL PIPELINE\n")
cat("  Oil Price Pass-Through to India's CPI Inflation, 2004-2024\n")
cat("================================================================\n")
cat(sprintf("  Start time: %s\n", Sys.time()))
cat(sprintf("  Working dir: %s\n", getwd()))

# ── Source each module in order ──────────────────────────────────────────────
modules <- c(
  "improved/R/00_helpers.R",
  "improved/R/01_data.R",
  "improved/R/02_descriptives.R",
  "improved/R/03_unit_roots.R",
  "improved/R/04_models.R",
  "improved/R/05_nardl.R",
  "improved/R/06_bootstrap.R",
  "improved/R/07_robustness.R",
  "improved/R/08_figures.R"
)

for (mod in modules) {
  mod_start <- proc.time()
  cat(sprintf("\n>> Sourcing %s ...\n", mod))

  tryCatch({
    source(mod, local = FALSE)
    elapsed <- (proc.time() - mod_start)["elapsed"]
    cat(sprintf(">> %s completed in %.1f seconds.\n", basename(mod), elapsed))
  }, error = function(e) {
    cat(sprintf(">> ERROR in %s: %s\n", basename(mod), e$message))
    cat(">> Continuing with next module...\n")
  })
}

# ── Final summary ────────────────────────────────────────────────────────────
total_elapsed <- (proc.time() - total_start)["elapsed"]

cat("\n")
cat("================================================================\n")
cat("  ANALYSIS COMPLETE\n")
cat("================================================================\n")
cat(sprintf("  Total runtime: %.1f seconds (%.1f minutes)\n", total_elapsed, total_elapsed / 60))
cat(sprintf("  End time: %s\n\n", Sys.time()))

tables_list  <- list.files("improved/outputs/tables", pattern = "\\.csv$")
figures_list <- list.files("improved/outputs/figures", pattern = "\\.png$")

cat(sprintf("  Tables (%d files):\n", length(tables_list)))
for (f in tables_list) cat(sprintf("    %s\n", f))
cat(sprintf("\n  Figures (%d files):\n", length(figures_list)))
for (f in figures_list) cat(sprintf("    %s\n", f))

cat("\n  === KEY RESULTS SUMMARY ===\n")
if (exists("cpt_m2")) {
  cat(sprintf("  M2 (Primary): CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s)\n",
      cpt_m2$cpt_pos, format_p(cpt_m2$pos_test$p_value),
      cpt_m2$cpt_neg, format_p(cpt_m2$neg_test$p_value)))
  cat(sprintf("  M2 Asymmetry Wald: p = %s\n", format_p(cpt_m2$asym_test$p_value)))
}
if (exists("cpt_post")) {
  cat(sprintf("  M3 Post-dereg: CPT+ = %.6f, Asym p = %s\n",
      cpt_post$cpt_pos, format_p(cpt_post$asym_test$p_value)))
  cat(sprintf("  M3 Regime change: F = %.4f, p = %s\n", regime_f, format_p(regime_p)))
}
if (exists("nardl_a") && !is.null(nardl_a)) {
  cat(sprintf("  NARDL-A: Bounds F = %.4f, LR Wald p = %s\n",
      nardl_a$fstat, format_p(nardl_a$wldq[1, 2])))
}
if (exists("nardl_b") && !is.null(nardl_b)) {
  cat(sprintf("  NARDL-B: Bounds F = %.4f, LR Wald p = %s\n",
      nardl_b$fstat, format_p(nardl_b$wldq[1, 2])))
}
if (exists("boot_m2")) {
  cat(sprintf("  Bootstrap (M2): asymptotic p = %s, block-bootstrap p = %.4f\n",
      format_p(cpt_m2$asym_test$p_value), boot_m2$boot_p))
}
cat("================================================================\n")
