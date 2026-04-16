# ══════════════════════════════════════════════════════════════════════════════
# 03_unit_roots.R — ADF + Phillips-Perron + KPSS + Zivot-Andrews
# ══════════════════════════════════════════════════════════════════════════════
banner("3", "UNIT ROOT TESTS (ADF, PP, KPSS, ZIVOT-ANDREWS)")

# ── Helper: run all four tests on one series ─────────────────────────────────
run_ur_battery <- function(x, name, is_diff = FALSE) {
  x_clean <- na.omit(x)

  # ADF (H0: unit root)
  adf <- suppressWarnings(adf.test(x_clean, alternative = "stationary"))

  # Phillips-Perron (H0: unit root) — Z-tau statistic
  pp <- summary(ur.pp(x_clean, type = "Z-tau", model = "trend", lags = "short"))
  pp_stat <- pp@teststat[1]
  pp_crit <- pp@cval

  # KPSS (H0: stationarity) — confirmatory test
  kpss_type <- if (is_diff) "mu" else "tau"
  kpss <- summary(ur.kpss(x_clean, type = kpss_type, lags = "short"))
  kpss_stat <- kpss@teststat[1]
  kpss_crit <- kpss@cval

  # Determine PP conclusion from critical values
  pp_reject <- pp_stat < pp_crit[, "5pct"]
  pp_conclusion <- ifelse(pp_reject, "Reject (stationary)", "Fail to reject (unit root)")

  # KPSS: reject stationarity if stat > 5% critical value
  kpss_reject <- kpss_stat > kpss_crit[, "5pct"]
  kpss_conclusion <- ifelse(kpss_reject, "Reject (not stationary)", "Fail to reject (stationary)")

  data.frame(
    Variable         = name,
    ADF_stat         = round(adf$statistic, 4),
    ADF_p            = round(adf$p.value, 4),
    ADF_conclusion   = ifelse(adf$p.value < 0.05, "Stationary", "Unit root"),
    PP_stat          = round(pp_stat, 4),
    PP_5pct_cv       = round(pp_crit[, "5pct"], 4),
    PP_conclusion    = ifelse(pp_reject, "Stationary", "Unit root"),
    KPSS_stat        = round(kpss_stat, 4),
    KPSS_5pct_cv     = round(kpss_crit[, "5pct"], 4),
    KPSS_conclusion  = ifelse(kpss_reject, "Not stationary", "Stationary"),
    stringsAsFactors = FALSE,
    row.names        = NULL
  )
}

# ── Run on all series ────────────────────────────────────────────────────────
ur_results <- bind_rows(
  run_ur_battery(df$ln_cpi,   "ln(CPI)",     FALSE),
  run_ur_battery(df$ln_oil,   "ln(Oil_INR)", FALSE),
  run_ur_battery(df$ln_brent, "ln(Brent)",   FALSE),
  run_ur_battery(df$ln_exr,   "ln(EXR)",     FALSE),
  run_ur_battery(df$ln_iip,   "ln(IIP)",     FALSE),
  run_ur_battery(df$dlnCPI,   "dlnCPI",      TRUE),
  run_ur_battery(df$dlnOil,   "dlnOil",      TRUE),
  run_ur_battery(df$dlnBrent, "dlnBrent",    TRUE),
  run_ur_battery(df$dlnEXR,   "dlnEXR",      TRUE),
  run_ur_battery(df$dlnIIP,   "dlnIIP",      TRUE)
)

save_table(ur_results, "table_03_unit_root_battery.csv")
cat("\n  Unit Root Battery:\n")
for (i in 1:nrow(ur_results)) {
  r <- ur_results[i, ]
  cat(sprintf("    %-12s  ADF: %s | PP: %s | KPSS: %s\n",
      r$Variable, r$ADF_conclusion, r$PP_conclusion, r$KPSS_conclusion))
}

# ── Zivot-Andrews structural break test (log levels only) ────────────────────
cat("\n  Zivot-Andrews Structural Break Tests (log levels):\n")

run_za <- function(x, name) {
  x_clean <- na.omit(x)
  za_both <- ur.za(x_clean, model = "both", lag = NULL)
  s <- summary(za_both)
  break_idx <- za_both@bpoint
  break_date <- df$date[which(!is.na(x))[break_idx]]

  za_stat <- s@teststat[1]
  # cval is a named numeric vector: [1%] [5%] [10%]
  cv5 <- s@cval[2]

  data.frame(
    Variable    = name,
    ZA_stat     = round(za_stat, 4),
    ZA_5pct_cv  = round(cv5, 4),
    Break_Index = break_idx,
    Break_Date  = as.character(break_date),
    Conclusion  = ifelse(za_stat < cv5,
                         "Reject unit root (break-stationary)",
                         "Fail to reject (unit root with break)"),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

za_results <- bind_rows(
  run_za(df$ln_cpi,   "ln(CPI)"),
  run_za(df$ln_oil,   "ln(Oil_INR)"),
  run_za(df$ln_brent, "ln(Brent)"),
  run_za(df$ln_exr,   "ln(EXR)"),
  run_za(df$ln_iip,   "ln(IIP)")
)

save_table(za_results, "table_04_zivot_andrews.csv")
for (i in 1:nrow(za_results)) {
  r <- za_results[i, ]
  cat(sprintf("    %-12s  ZA=%.4f (cv5%%=%.4f)  break=%s  %s\n",
      r$Variable, r$ZA_stat, r$ZA_5pct_cv, r$Break_Date, r$Conclusion))
}

# Store for later use in figures
assign("za_results", za_results, envir = .GlobalEnv)

cat("  [03_unit_roots] Done.\n")
