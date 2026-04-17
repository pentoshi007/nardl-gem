# ==============================================================================
# run_all.R — Master orchestrator for the WPI pass-through pipeline
# ==============================================================================

total_start <- proc.time()

cat("\n")
cat("===============================================================\n")
cat("  WPI PIPELINE — INDIA OIL PASS-THROUGH\n")
cat("===============================================================\n")
cat(sprintf("  Start time: %s\n", Sys.time()))
cat(sprintf("  Working dir: %s\n", getwd()))

modules <- c(
  "wpi/R/00_config.R",
  "wpi/R/01_helpers.R",
  "wpi/R/02_build_data.R",
  "wpi/R/03_models.R",
  "wpi/R/03b_unit_roots.R",
  "wpi/R/03c_granger.R",
  "wpi/R/04_diagnostics.R",
  "wpi/R/04b_bootstrap.R",
  "wpi/R/05_figures.R",
  "wpi/R/06_publication_triage.R"
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

total_elapsed <- (proc.time() - total_start)["elapsed"]

cat("\n")
cat("===============================================================\n")
cat("  PIPELINE COMPLETE\n")
cat("===============================================================\n")
cat(sprintf("  Total runtime: %.1f seconds (%.1f minutes)\n", total_elapsed, total_elapsed / 60))
cat(sprintf("  End time: %s\n\n", Sys.time()))

cat("  Module status:\n")
for (nm in names(module_status)) {
  st <- module_status[[nm]]
  cat(sprintf("    %s: %s (%.1fs)\n", nm, st$status, st$elapsed))
}

tables_list <- list.files(PATHS$tables, pattern = "\\.csv$")
figures_list <- list.files(PATHS$figures, pattern = "\\.png$")

cat(sprintf("\n  Tables (%d files):\n", length(tables_list)))
for (f in tables_list) cat(sprintf("    %s\n", f))

cat(sprintf("\n  Figures (%d files):\n", length(figures_list)))
for (f in figures_list) cat(sprintf("    %s\n", f))

if (exists("publication_decision")) {
  cat("\n  Publication triage:\n")
  print(publication_decision)
}

sink(file.path(PATHS$output_root, "run_log.txt"))
cat(sprintf("Run completed: %s\n", Sys.time()))
cat(sprintf("Runtime: %.1f seconds\n", total_elapsed))
cat(sprintf("Tables: %d | Figures: %d\n", length(tables_list), length(figures_list)))
if (exists("publication_decision")) {
  cat("\nPublication decision:\n")
  print(publication_decision)
}
sink()
