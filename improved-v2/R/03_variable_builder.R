# ==============================================================================
# 03_variable_builder.R — Variable construction from merged raw data
# ==============================================================================
# Constructs: oil_inr, logs, % changes, Mork decomposition, NOPI,
#             policy dummies, monthly dummies, lags, interaction terms
# ==============================================================================
banner("03", "VARIABLE CONSTRUCTION")

# ── 3.1 INR-denominated oil price ────────────────────────────────────────────
df$oil_inr <- df$brent_usd * df$exr

# ── 3.2 Natural logs ────────────────────────────────────────────────────────
df$ln_cpi   <- log(df$cpi)
df$ln_oil   <- log(df$oil_inr)
df$ln_iip   <- log(df$iip)
df$ln_brent <- log(df$brent_usd)
df$ln_exr   <- log(df$exr)

# ── 3.3 Monthly percentage changes (x100 for readability) ───────────────────
df$dlnCPI   <- c(NA, 100 * diff(df$ln_cpi))
df$dlnOil   <- c(NA, 100 * diff(df$ln_oil))
df$dlnIIP   <- c(NA, 100 * diff(df$ln_iip))
df$dlnBrent <- c(NA, 100 * diff(df$ln_brent))
df$dlnEXR   <- c(NA, 100 * diff(df$ln_exr))

cat(sprintf("  Log-differences computed. First valid obs: %s\n",
    df$date[which(!is.na(df$dlnCPI))[1]]))

# ── 3.4 Mork decomposition (partial sums) ───────────────────────────────────
# Positive and negative components of oil price changes
df$dlnOil_pos <- ifelse(!is.na(df$dlnOil), pmax(df$dlnOil, 0), NA)
df$dlnOil_neg <- ifelse(!is.na(df$dlnOil), pmin(df$dlnOil, 0), NA)

df$dlnBrent_pos <- ifelse(!is.na(df$dlnBrent), pmax(df$dlnBrent, 0), NA)
df$dlnBrent_neg <- ifelse(!is.na(df$dlnBrent), pmin(df$dlnBrent, 0), NA)

# ── 3.5 NOPI: Hamilton (2003) net oil price increase/decrease ────────────────
# NOPI+ = max(0, lnOil_t - max(lnOil_{t-1},...,lnOil_{t-12})) * 100
# NOPI- = min(0, lnOil_t - min(lnOil_{t-1},...,lnOil_{t-12})) * 100
df$nopi_pos <- NA_real_
df$nopi_neg <- NA_real_
for (t in 13:nrow(df)) {
  past_max <- max(df$ln_oil[(t - 12):(t - 1)], na.rm = TRUE)
  past_min <- min(df$ln_oil[(t - 12):(t - 1)], na.rm = TRUE)
  df$nopi_pos[t] <- max(0, df$ln_oil[t] - past_max) * 100
  df$nopi_neg[t] <- min(0, df$ln_oil[t] - past_min) * 100
}

# ── 3.6 Policy dummies ──────────────────────────────────────────────────────
df$D_petrol <- as.integer(df$date >= DATE_PETROL_DEREG)
df$D_diesel <- as.integer(df$date >= DATE_DIESEL_DEREG)
df$D_covid  <- as.integer(df$date == DATE_COVID_START)
df$D_post   <- as.integer(df$date >= DATE_DIESEL_DEREG)

cat(sprintf("  Policy dummies: D_petrol from %s, D_diesel from %s, D_covid at %s\n",
    DATE_PETROL_DEREG, DATE_DIESEL_DEREG, DATE_COVID_START))

# ── 3.7 Monthly dummies (December = reference) ──────────────────────────────
# NOTE: names prefixed "mo_" to avoid collision with model labels M0/M1/M2/M3.
df$month <- as.integer(format(df$date, "%m"))
MONTH_LABELS <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov")
for (m in 1:11) df[[paste0("mo_", MONTH_LABELS[m])]] <- as.integer(df$month == m)

# ── 3.8 Lags ────────────────────────────────────────────────────────────────
# CPI AR lags (up to 4 for AIC selection)
for (k in 1:4) df[[paste0("dlnCPI_L", k)]] <- dplyr::lag(df$dlnCPI, k)

# Exchange rate lags
df$dlnEXR_L1 <- dplyr::lag(df$dlnEXR, 1)
# Symmetric oil lag (for M0)
df$dlnOil_L1 <- dplyr::lag(df$dlnOil, 1)

# Oil/Brent positive and negative lags (L0 = contemporaneous through L3)
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

# ── 3.9 Interaction terms for M3 (deregulation regime) ───────────────────────
for (k in 0:2) {
  df[[paste0("dlnBrent_pos_L", k, "_post")]] <- df[[paste0("dlnBrent_pos_L", k)]] * df$D_post
  df[[paste0("dlnBrent_neg_L", k, "_post")]] <- df[[paste0("dlnBrent_neg_L", k)]] * df$D_post
}
df$dlnEXR_post    <- df$dlnEXR * df$D_post
df$dlnEXR_L1_post <- df$dlnEXR_L1 * df$D_post

# ── 3.10 Save processed dataset ─────────────────────────────────────────────
out_path <- file.path(PATHS$processed, "analysis_dataset_v2.csv")
write.csv(df, out_path, row.names = FALSE)

usable_n <- sum(complete.cases(
  df[, c("dlnCPI", "dlnCPI_L1", "dlnOil_pos_L3", "dlnOil_neg_L3", "dlnIIP")]
))
cat(sprintf("  Saved: %s\n", out_path))
cat(sprintf("  Total obs: %d | Usable after lags: %d\n", nrow(df), usable_n))
cat(sprintf("  Missing: CPI=%d, Oil=%d, EXR=%d, IIP=%d\n",
    sum(is.na(df$dlnCPI)), sum(is.na(df$dlnOil)),
    sum(is.na(df$dlnEXR)), sum(is.na(df$dlnIIP))))
cat("  [03_variable_builder] Done.\n")
