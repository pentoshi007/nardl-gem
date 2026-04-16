# ==============================================================================
# 00_config.R — Configuration, paths, constants, package loading
# ==============================================================================
# Project: Oil Price Pass-Through to India's CPI Inflation (2004-2024)
# Author:  Aniket Pandey | JNU MS Economics 2026
# Pipeline: improved-v2 (from-scratch rewrite per suggestions.md)
# ==============================================================================

# ── Package loading ──────────────────────────────────────────────────────────
required_packages <- c(
  "dplyr", "tidyr", "readr", "readxl",
  "sandwich", "lmtest", "car",
  "urca", "strucchange",
  "ggplot2", "patchwork", "scales"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# ── Project root (caller must setwd or run from project root) ────────────────
PROJECT_ROOT <- getwd()

# ── Paths ────────────────────────────────────────────────────────────────────
PATHS <- list(
  raw       = file.path(PROJECT_ROOT, "data", "raw"),
  processed = file.path(PROJECT_ROOT, "data", "processed"),
  tables    = file.path(PROJECT_ROOT, "improved-v2", "outputs", "tables"),
  figures   = file.path(PROJECT_ROOT, "improved-v2", "outputs", "figures")
)

# Ensure output directories exist
for (d in PATHS[c("tables", "figures")]) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# ── Study window ─────────────────────────────────────────────────────────────
STUDY_START  <- as.Date("2004-04-01")
STUDY_END    <- as.Date("2024-12-01")
RUNWAY_START <- as.Date("2003-01-01")  # pre-sample for lag construction

# Expected observation count (Apr 2004 to Dec 2024 inclusive)
EXPECTED_N <- 249

# ── Model design constants ───────────────────────────────────────────────────
# AR lag p: selected by AIC in 06_models.R (typically 1)
# Oil lag q: theory-driven = 3 (India pass-through literature)
OIL_LAG_Q     <- 3
MAX_AR_P      <- 4       # search range for AR lag selection
BOOTSTRAP_B   <- 4999    # number of bootstrap replications
BOOTSTRAP_SEED <- 42

# ── Policy event dates ───────────────────────────────────────────────────────
DATE_PETROL_DEREG <- as.Date("2010-06-01")  # petrol deregulation
DATE_DIESEL_DEREG <- as.Date("2014-10-01")  # diesel deregulation
DATE_COVID_START  <- as.Date("2020-04-01")  # COVID lockdown month

# ── Newey-West lag formula (Andrews rule) ────────────────────────────────────
nw_lag <- function(n) floor(0.75 * n^(1/3))

# ── Raw data file names ──────────────────────────────────────────────────────
FILES <- list(
  cpi         = file.path(PATHS$raw, "INDCPIALLMINMEI.csv"),
  brent       = file.path(PATHS$raw, "POILBREUSDM.csv"),
  exr         = file.path(PATHS$raw, "EXINUS.csv"),
  iip         = file.path(PATHS$raw, "iip_chained.xlsx"),
  ppac_pre    = file.path(PATHS$raw, "ppac_rsp_pre2017.xls"),
  ppac_post   = file.path(PATHS$raw, "ppac_rsp_post2017.xlsx"),
  fuel_light  = file.path(PATHS$processed, "cpi_fuel_light.csv"),
  ppac_monthly = file.path(PATHS$processed, "ppac_monthly_delhi.csv")
)

# ── Output helpers ───────────────────────────────────────────────────────────
save_table <- function(df, filename) {
  path <- file.path(PATHS$tables, filename)
  write.csv(df, path, row.names = FALSE)
  cat(sprintf("  Saved: %s\n", filename))
}

save_figure_path <- function(filename) {
  file.path(PATHS$figures, filename)
}

# ── Console formatting ───────────────────────────────────────────────────────
banner <- function(num, title) {
  cat("\n")
  cat("================================================================\n")
  cat(sprintf("  [%s] %s\n", num, title))
  cat("================================================================\n")
}

cat("  [00_config] Loaded. Study window:", format(STUDY_START, "%b %Y"),
    "to", format(STUDY_END, "%b %Y"), "\n")
