# ==============================================================================
# 00_config.R — Configuration, paths, constants, package loading
# ==============================================================================

required_packages <- c(
  "dplyr", "tidyr", "readr", "readxl",
  "ggplot2", "patchwork", "scales",
  "sandwich", "lmtest", "car", "strucchange",
  "urca",
  "nardl"
)

BOOTSTRAP_B    <- 4999
BOOTSTRAP_SEED <- 42

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

PROJECT_ROOT <- getwd()

PATHS <- list(
  raw_wpi = file.path(PROJECT_ROOT, "data", "raw", "wpi"),
  processed = file.path(PROJECT_ROOT, "data", "processed"),
  output_root = file.path(PROJECT_ROOT, "wpi", "outputs"),
  tables = file.path(PROJECT_ROOT, "wpi", "outputs", "tables"),
  figures = file.path(PROJECT_ROOT, "wpi", "outputs", "figures")
)

for (d in PATHS[c("processed", "output_root", "tables", "figures")]) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

RAW_FILES <- list(
  wpi_8182_a = file.path(PATHS$raw_wpi, "wpi_1981_82_monthly_1982_1991.xls"),
  wpi_8182_b = file.path(PATHS$raw_wpi, "wpi_1981_82_monthly_1992_2000.xls"),
  wpi_9394_a = file.path(PATHS$raw_wpi, "wpi_1993_94_monthly_1994_1999.xls"),
  wpi_9394_b = file.path(PATHS$raw_wpi, "wpi_1993_94_monthly_2000_onwards.xls"),
  wpi_0405_a = file.path(PATHS$raw_wpi, "wpi_2004_05_monthly_2005_2012.xls"),
  wpi_0405_b = file.path(PATHS$raw_wpi, "wpi_2004_05_monthly_2013_onwards.xls"),
  wpi_1112 = file.path(PATHS$raw_wpi, "wpi_2011_12_monthly_202603.xls"),
  brent = file.path(PATHS$raw_wpi, "world_bank_pink_sheet_monthly.xlsx"),
  exr = file.path(PATHS$raw_wpi, "EXINUS_latest.csv")
)

CHAIN_FACTORS <- list(
  headline = c(
    base_8182_to_9394 = 2.478,
    base_9394_to_0405 = 1.873,
    base_0405_to_1112 = 1.561
  ),
  fuel = c(
    base_9394_to_0405 = 2.802,
    base_0405_to_1112 = 1.690
  )
)

MAIN_AR_LAGS <- 12
MAIN_OIL_LAGS <- 6
NARDL_MAX_LAG <- 4

FULL_CHAIN_START <- as.Date("1982-04-01")
FUEL_CHAIN_START <- as.Date("1994-04-01")
NARDL_LIT_START <- as.Date("1997-04-01")
NARDL_LIT_END <- as.Date("2025-03-01")

banner <- function(num, title) {
  cat("\n")
  cat("===============================================================\n")
  cat(sprintf("  [%s] %s\n", num, title))
  cat("===============================================================\n")
}

cat("  [00_config] Loaded.\n")
