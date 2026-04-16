# ══════════════════════════════════════════════════════════════════════════════
# 01_data.R — Data loading, merging, variable construction
# ══════════════════════════════════════════════════════════════════════════════
banner("1", "DATA LOADING AND VARIABLE CONSTRUCTION")

# ── 1.1 Load FRED CSVs ──────────────────────────────────────────────────────
cpi_raw   <- read.csv(file.path(PATHS$raw, "INDCPIALLMINMEI.csv"), stringsAsFactors = FALSE)
brent_raw <- read.csv(file.path(PATHS$raw, "POILBREUSDM.csv"),     stringsAsFactors = FALSE)
exr_raw   <- read.csv(file.path(PATHS$raw, "EXINUS.csv"),          stringsAsFactors = FALSE)

cpi_raw   <- cpi_raw   %>% rename(date = observation_date, cpi = INDCPIALLMINMEI)
brent_raw <- brent_raw %>% rename(date = observation_date, brent_usd = POILBREUSDM)
exr_raw   <- exr_raw   %>% rename(date = observation_date, exr = EXINUS)

cpi_raw$date   <- as.Date(cpi_raw$date)
brent_raw$date <- as.Date(brent_raw$date)
exr_raw$date   <- as.Date(exr_raw$date)

iip_raw <- read_excel(file.path(PATHS$raw, "iip_chained.xlsx"), sheet = "IIP_Chained")
iip_raw$date <- as.Date(iip_raw$date)
iip_raw <- iip_raw %>% rename(iip = iip_chained)

cat(sprintf("  CPI:   %s to %s  (%d obs)\n", min(cpi_raw$date), max(cpi_raw$date), nrow(cpi_raw)))
cat(sprintf("  Brent: %s to %s  (%d obs)\n", min(brent_raw$date), max(brent_raw$date), nrow(brent_raw)))
cat(sprintf("  EXR:   %s to %s  (%d obs)\n", min(exr_raw$date), max(exr_raw$date), nrow(exr_raw)))
cat(sprintf("  IIP:   %s to %s  (%d obs)\n", min(iip_raw$date), max(iip_raw$date), nrow(iip_raw)))

# ── 1.2 Merge & trim to study window ────────────────────────────────────────
df <- cpi_raw %>%
  inner_join(brent_raw, by = "date") %>%
  inner_join(exr_raw,   by = "date") %>%
  inner_join(iip_raw,   by = "date") %>%
  arrange(date)

study_start <- as.Date("2004-04-01")
study_end   <- as.Date("2024-12-01")
df <- df %>% filter(date >= study_start & date <= study_end)

cat(sprintf("\n  Merged dataset: %s to %s  (N = %d)\n", min(df$date), max(df$date), nrow(df)))
stopifnot(nrow(df) >= 245)

# ── 1.3 Construct variables ─────────────────────────────────────────────────
df$oil_inr  <- df$brent_usd * df$exr

df$ln_cpi   <- log(df$cpi)
df$ln_oil   <- log(df$oil_inr)
df$ln_iip   <- log(df$iip)
df$ln_brent <- log(df$brent_usd)
df$ln_exr   <- log(df$exr)

df$dlnCPI   <- c(NA, 100 * diff(df$ln_cpi))
df$dlnOil   <- c(NA, 100 * diff(df$ln_oil))
df$dlnIIP   <- c(NA, 100 * diff(df$ln_iip))
df$dlnBrent <- c(NA, 100 * diff(df$ln_brent))
df$dlnEXR   <- c(NA, 100 * diff(df$ln_exr))

# ── 1.4 Mork decomposition ──────────────────────────────────────────────────
df$dlnOil_pos <- ifelse(!is.na(df$dlnOil), pmax(df$dlnOil, 0), NA)
df$dlnOil_neg <- ifelse(!is.na(df$dlnOil), pmin(df$dlnOil, 0), NA)

df$dlnBrent_pos <- ifelse(!is.na(df$dlnBrent), pmax(df$dlnBrent, 0), NA)
df$dlnBrent_neg <- ifelse(!is.na(df$dlnBrent), pmin(df$dlnBrent, 0), NA)

# ── 1.5 NOPI: Hamilton (2003) net oil price increase/decrease ────────────────
# NOPI+ = max(0, lnOil_t - max(lnOil_{t-1}, ..., lnOil_{t-12}))
# NOPI- = min(0, lnOil_t - min(lnOil_{t-1}, ..., lnOil_{t-12}))
df$nopi_pos <- NA_real_
df$nopi_neg <- NA_real_
for (t in 13:nrow(df)) {
  past_max <- max(df$ln_oil[(t - 12):(t - 1)], na.rm = TRUE)
  past_min <- min(df$ln_oil[(t - 12):(t - 1)], na.rm = TRUE)
  df$nopi_pos[t] <- max(0, df$ln_oil[t] - past_max) * 100
  df$nopi_neg[t] <- min(0, df$ln_oil[t] - past_min) * 100
}

# ── 1.6 Policy dummies ──────────────────────────────────────────────────────
df$D_petrol <- as.integer(df$date >= as.Date("2010-06-01"))
df$D_diesel <- as.integer(df$date >= as.Date("2014-10-01"))
df$D_covid  <- as.integer(df$date == as.Date("2020-04-01"))
df$D_post   <- as.integer(df$date >= as.Date("2014-10-01"))

# Monthly dummies (Dec = reference)
df$month <- as.integer(format(df$date, "%m"))
for (m in 1:11) df[[paste0("M", m)]] <- as.integer(df$month == m)

# ── 1.7 Lags ────────────────────────────────────────────────────────────────
for (k in 1:4) df[[paste0("dlnCPI_L", k)]] <- dplyr::lag(df$dlnCPI, k)

df$dlnEXR_L1 <- dplyr::lag(df$dlnEXR, 1)
df$dlnOil_L1 <- dplyr::lag(df$dlnOil, 1)

for (k in 0:3) {
  df[[paste0("dlnOil_pos_L", k)]]   <- dplyr::lag(df$dlnOil_pos, k)
  df[[paste0("dlnOil_neg_L", k)]]   <- dplyr::lag(df$dlnOil_neg, k)
  df[[paste0("dlnBrent_pos_L", k)]] <- dplyr::lag(df$dlnBrent_pos, k)
  df[[paste0("dlnBrent_neg_L", k)]] <- dplyr::lag(df$dlnBrent_neg, k)
}

# NOPI lags
for (k in 0:3) {
  df[[paste0("nopi_pos_L", k)]] <- dplyr::lag(df$nopi_pos, k)
  df[[paste0("nopi_neg_L", k)]] <- dplyr::lag(df$nopi_neg, k)
}

# ── 1.8 Interaction terms for deregulation model (M3) ────────────────────────
for (k in 0:2) {
  df[[paste0("dlnBrent_pos_L", k, "_post")]] <- df[[paste0("dlnBrent_pos_L", k)]] * df$D_post
  df[[paste0("dlnBrent_neg_L", k, "_post")]] <- df[[paste0("dlnBrent_neg_L", k)]] * df$D_post
}
df$dlnEXR_post    <- df$dlnEXR * df$D_post
df$dlnEXR_L1_post <- df$dlnEXR_L1 * df$D_post

# ── 1.9 Save processed dataset ──────────────────────────────────────────────
write.csv(df, file.path(PATHS$processed, "analysis_dataset_improved.csv"), row.names = FALSE)

usable_n <- sum(complete.cases(
  df[, c("dlnCPI", "dlnCPI_L1", "dlnOil_pos_L3", "dlnOil_neg_L3", "dlnIIP")]
))
cat(sprintf("  Final usable N (after lags): %d\n", usable_n))
cat(sprintf("  Missing: CPI=%d, Oil=%d, EXR=%d, IIP=%d\n",
    sum(is.na(df$dlnCPI)), sum(is.na(df$dlnOil)),
    sum(is.na(df$dlnEXR)), sum(is.na(df$dlnIIP))))
cat("  [01_data] Done.\n")
