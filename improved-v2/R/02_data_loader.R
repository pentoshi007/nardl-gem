# ==============================================================================
# 02_data_loader.R — Load all raw data series
# ==============================================================================
# Reads cached FRED CSVs, IIP Excel, PPAC Excel, CPI Fuel & Light
# No API calls — all data already exists locally
# ==============================================================================
banner("02", "DATA LOADING")

# ── FRED series (already downloaded as CSV) ──────────────────────────────────
cat("  Loading FRED series...\n")

if (!file.exists(FILES$cpi))   stop("CPI CSV not found: ", FILES$cpi)
if (!file.exists(FILES$brent)) stop("Brent CSV not found: ", FILES$brent)
if (!file.exists(FILES$exr))   stop("EXR CSV not found: ", FILES$exr)

cpi_raw <- read.csv(FILES$cpi, stringsAsFactors = FALSE) %>%
  rename(date = observation_date, cpi = INDCPIALLMINMEI) %>%
  mutate(date = as.Date(date))

brent_raw <- read.csv(FILES$brent, stringsAsFactors = FALSE) %>%
  rename(date = observation_date, brent_usd = POILBREUSDM) %>%
  mutate(date = as.Date(date))

exr_raw <- read.csv(FILES$exr, stringsAsFactors = FALSE) %>%
  rename(date = observation_date, exr = EXINUS) %>%
  mutate(date = as.Date(date))

cat(sprintf("  CPI:   %s to %s  (%d obs)\n", min(cpi_raw$date), max(cpi_raw$date), nrow(cpi_raw)))
cat(sprintf("  Brent: %s to %s  (%d obs)\n", min(brent_raw$date), max(brent_raw$date), nrow(brent_raw)))
cat(sprintf("  EXR:   %s to %s  (%d obs)\n", min(exr_raw$date), max(exr_raw$date), nrow(exr_raw)))

# ── IIP (chain-linked, from Excel) ──────────────────────────────────────────
cat("  Loading IIP...\n")
if (!file.exists(FILES$iip)) stop("IIP Excel not found: ", FILES$iip)

iip_raw <- read_excel(FILES$iip, sheet = "IIP_Chained") %>%
  mutate(date = as.Date(date)) %>%
  rename(iip = iip_chained)

cat(sprintf("  IIP:   %s to %s  (%d obs)\n", min(iip_raw$date), max(iip_raw$date), nrow(iip_raw)))

# ── PPAC retail fuel prices (processed monthly series) ───────────────────────
cat("  Loading PPAC retail fuel...\n")
ppac_available <- FALSE
if (file.exists(FILES$ppac_monthly)) {
  ppac_raw <- read.csv(FILES$ppac_monthly, stringsAsFactors = FALSE) %>%
    mutate(date = as.Date(date))
  ppac_available <- TRUE
  cat(sprintf("  PPAC:  %s to %s  (%d obs)\n",
      min(ppac_raw$date), max(ppac_raw$date), nrow(ppac_raw)))
} else {
  cat("  PPAC monthly file not found — mechanism Stage 1 will be skipped.\n")
}

# ── CPI Fuel & Light (cached processed) ─────────────────────────────────────
cat("  Loading CPI Fuel & Light...\n")
fuel_available <- FALSE
if (file.exists(FILES$fuel_light)) {
  fuel_raw <- read.csv(FILES$fuel_light, stringsAsFactors = FALSE) %>%
    mutate(date = as.Date(date))
  fuel_available <- TRUE
  cat(sprintf("  Fuel:  %s to %s  (%d obs)\n",
      min(fuel_raw$date), max(fuel_raw$date), nrow(fuel_raw)))
} else {
  cat("  Fuel & Light CSV not found — mechanism Stage 2 will be skipped.\n")
}

# ── Merge core series ────────────────────────────────────────────────────────
cat("\n  Merging core series (CPI, Brent, EXR, IIP)...\n")

df <- cpi_raw %>%
  inner_join(brent_raw, by = "date") %>%
  inner_join(exr_raw,   by = "date") %>%
  inner_join(iip_raw,   by = "date") %>%
  arrange(date)

# Trim to study window
df <- df %>% filter(date >= STUDY_START & date <= STUDY_END)

cat(sprintf("  Merged dataset: %s to %s  (N = %d)\n",
    min(df$date), max(df$date), nrow(df)))

if (nrow(df) < 245) {
  stop(sprintf("Merged dataset has only %d obs — expected >= 245. Check data files.", nrow(df)))
}
if (nrow(df) != EXPECTED_N) {
  cat(sprintf("  WARNING: Got %d obs, expected %d. Check study window.\n", nrow(df), EXPECTED_N))
}

cat("  [02_data_loader] Done.\n")
