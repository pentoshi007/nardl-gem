# ==============================================================================
# run_all.R — Master orchestrator for improved-v2 pipeline
# ==============================================================================
# Title: Oil Price Pass-Through to India's CPI Inflation (2004-2024)
# Author: Aniket Pandey | JNU MS Economics 2026
# Pipeline: improved-v2 (fresh build per suggestions.md)
#
# Usage:
#   cd /Users/aniketpandey/Documents/dissertationv2
#   Rscript improved-v2/run_all.R
#
# Or from RStudio: set working directory to project root first.
# ==============================================================================

total_start <- proc.time()

cat("\n")
cat("================================================================\n")
cat("  IMPROVED-V2 PIPELINE — FULL RUN\n")
cat("  Oil Price Pass-Through to India's CPI Inflation, 2004-2024\n")
cat("  Model hierarchy: M1 headline | PPAC mechanism | M2 robustness | No NARDL\n")
cat("================================================================\n")
cat(sprintf("  Start time: %s\n", Sys.time()))
cat(sprintf("  Working dir: %s\n", getwd()))

# ── Source each module in order ──────────────────────────────────────────────
modules <- c(
  "improved-v2/R/00_config.R",
  "improved-v2/R/01_helpers.R",
  "improved-v2/R/02_data_loader.R",
  "improved-v2/R/03_variable_builder.R",
  "improved-v2/R/04_descriptives.R",
  "improved-v2/R/05_unit_roots.R",
  "improved-v2/R/06_models.R",
  "improved-v2/R/07_diagnostics.R",
  "improved-v2/R/08_bootstrap.R",
  "improved-v2/R/09_mechanism_chain.R",
  "improved-v2/R/10_robustness.R",
  "improved-v2/R/11_figures.R",
  "improved-v2/R/12_publication_triage.R"
)

module_status <- list()

for (mod in modules) {
  mod_start <- proc.time()
  cat(sprintf("\n>> Sourcing %s ...\n", mod))

  tryCatch({
    source(mod, local = FALSE)
    elapsed <- (proc.time() - mod_start)["elapsed"]
    module_status[[basename(mod)]] <- list(status = "OK", elapsed = elapsed)
    cat(sprintf(">> %s completed in %.1f seconds.\n", basename(mod), elapsed))
  }, error = function(e) {
    elapsed <- (proc.time() - mod_start)["elapsed"]
    module_status[[basename(mod)]] <- list(status = "ERROR", elapsed = elapsed, message = e$message)
    stop(sprintf("Pipeline aborted in %s: %s", basename(mod), e$message), call. = FALSE)
  })
}

if (!exists("mandatory_gate")) {
  stop("Pipeline aborted: mandatory model gate was not created.", call. = FALSE)
}

if (any(mandatory_gate$Gate_status != "PASS")) {
  failing_models <- paste(mandatory_gate$Model[mandatory_gate$Gate_status != "PASS"], collapse = ", ")
  stop(sprintf("Pipeline aborted: mandatory gate failed for %s", failing_models), call. = FALSE)
}

# ── Final summary ────────────────────────────────────────────────────────────
total_elapsed <- (proc.time() - total_start)["elapsed"]

cat("\n")
cat("================================================================\n")
cat("  PIPELINE COMPLETE\n")
cat("================================================================\n")
cat(sprintf("  Total runtime: %.1f seconds (%.1f minutes)\n", total_elapsed, total_elapsed / 60))
cat(sprintf("  End time: %s\n\n", Sys.time()))

cat("  Module status:\n")
for (nm in names(module_status)) {
  st <- module_status[[nm]]
  cat(sprintf("    %s: %s (%.1fs)\n", nm, st$status, st$elapsed))
}

tables_list  <- list.files("improved-v2/outputs/tables", pattern = "\\.csv$")
figures_list <- list.files("improved-v2/outputs/figures", pattern = "\\.png$")

cat(sprintf("  Tables (%d files):\n", length(tables_list)))
for (f in tables_list) cat(sprintf("    %s\n", f))
cat(sprintf("\n  Figures (%d files):\n", length(figures_list)))
for (f in figures_list) cat(sprintf("    %s\n", f))

# ── Key results ──────────────────────────────────────────────────────────────
cat("\n  === KEY RESULTS ===\n")

if (exists("cpt_m1")) {
  cat(sprintf("  M1 (HEADLINE): CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s)\n",
      cpt_m1$cpt_pos, format_p(cpt_m1$pos_test$p_value),
      cpt_m1$cpt_neg, format_p(cpt_m1$neg_test$p_value)))
  cat(sprintf("  M1 Asymmetry Wald: p = %s\n", format_p(cpt_m1$asym_test$p_value)))
}
if (exists("boot_m1")) {
  cat(sprintf("  M1 Bootstrap: Wald F = %.4f | asymptotic p = %s | bootstrap p = %.4f\n",
      boot_m1$obs_wald, format_p(boot_m1$obs_p), boot_m1$boot_p))
}
if (exists("cpt_m2")) {
  cat(sprintf("  M2 (ROBUSTNESS): CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s)\n",
      cpt_m2$cpt_pos, format_p(cpt_m2$pos_test$p_value),
      cpt_m2$cpt_neg, format_p(cpt_m2$neg_test$p_value)))
}

# ── Dilution chain ───────────────────────────────────────────────────────────
cat("\n  === DILUTION HYPOTHESIS ===\n")
dil_file <- file.path("improved-v2/outputs/tables", "table_23_dilution_hypothesis.csv")
if (file.exists(dil_file)) {
  dil <- read.csv(dil_file, stringsAsFactors = FALSE)
  for (i in seq_len(nrow(dil))) {
    cat(sprintf("  %s\n    CPT+= %.4f (p=%s)  CPT-= %.4f (p=%s)  Asym=%s\n",
        dil$Stage[i], dil$CPT_pos[i], format_p(dil$CPTpos_p[i]),
        dil$CPT_neg[i], format_p(dil$CPTneg_p[i]),
        dil$Asym_evidence[i]))
  }
}

# ── Diagnostics triage ───────────────────────────────────────────────────────
cat("\n  === DIAGNOSTIC TRIAGE ===\n")
diag_file <- file.path("improved-v2/outputs/tables", "table_09_diagnostics_all.csv")
if (file.exists(diag_file)) {
  diag_df <- read.csv(diag_file, stringsAsFactors = FALSE)
  for (i in seq_len(nrow(diag_df))) {
    r <- diag_df[i, ]
    passes <- sum(c(
      r$BG12_pass == "PASS",
      r$RESET_HAC_pass == "PASS",
      r$RecCUSUM_pass == "PASS"
    ), na.rm = TRUE)
    verdict <- if (passes == 3) "ACCEPT" else if (passes == 2) "CAUTION" else "REJECT"
    cat(sprintf("  %s: %d/3 pass -> %s\n", r$Model, passes, verdict))
  }
}

cat("\n================================================================\n")
cat("  Per suggestions.md:\n")
cat("  - M1 is the headline model (INR oil, diagnostic-safe)\n")
cat("  - PPAC is the mandatory 20+ year mechanism model\n")
cat("  - Fuel & Light is supporting-only unless a 20+ year series is supplied\n")
cat("  - M2 is robustness only (Brent+EXR decomposition)\n")
  cat("  - NARDL removed (ECT invalid in prior pipeline)\n")
cat("  - Paper framing: transmission + dilution, not pure asymmetry\n")
cat("================================================================\n")

# ── Save run log ─────────────────────────────────────────────────────────────
sink(file.path("improved-v2/outputs", "run_log.txt"))
cat(sprintf("Run completed: %s\n", Sys.time()))
cat(sprintf("Runtime: %.1f seconds\n", total_elapsed))
cat(sprintf("Tables: %d | Figures: %d\n", length(tables_list), length(figures_list)))
cat("Mandatory gate:\n")
print(mandatory_gate)
sink()
