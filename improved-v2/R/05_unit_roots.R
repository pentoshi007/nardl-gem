# ==============================================================================
# 05_unit_roots.R — Unit root battery + Zivot-Andrews structural break
# ==============================================================================
# ADF, Phillips-Perron, KPSS on levels and first differences
# Zivot-Andrews for structural break detection
# ==============================================================================
banner("05", "UNIT ROOT TESTS")

# ── Test battery ─────────────────────────────────────────────────────────────
ur_series <- list(
  list(name = "ln_cpi",   label = "ln(CPI)"),
  list(name = "ln_oil",   label = "ln(Oil INR)"),
  list(name = "ln_brent", label = "ln(Brent USD)"),
  list(name = "ln_exr",   label = "ln(EXR)"),
  list(name = "ln_iip",   label = "ln(IIP)"),
  list(name = "dlnCPI",   label = "dln(CPI)"),
  list(name = "dlnOil",   label = "dln(Oil INR)"),
  list(name = "dlnBrent", label = "dln(Brent)"),
  list(name = "dlnEXR",   label = "dln(EXR)"),
  list(name = "dlnIIP",   label = "dln(IIP)")
)

ur_results <- list()

for (s in ur_series) {
  x <- na.omit(df[[s$name]])
  if (length(x) < 20) next

  # ADF (with intercept and trend for levels, intercept only for diffs)
  is_diff <- grepl("^dln", s$name)
  adf_type <- if (is_diff) "drift" else "trend"
  adf <- tryCatch({
    test <- ur.df(x, type = adf_type, selectlags = "AIC")
    list(stat = test@teststat[1], p = NA)  # ur.df uses critical values, not p
  }, error = function(e) list(stat = NA, p = NA))

  # Phillips-Perron
  pp <- tryCatch({
    test <- ur.pp(x, type = "Z-tau", model = if (is_diff) "constant" else "trend")
    list(stat = test@teststat[1])
  }, error = function(e) list(stat = NA))

  # KPSS (H0: stationary — reversed null)
  kpss_type <- if (is_diff) "mu" else "tau"
  kpss <- tryCatch({
    test <- ur.kpss(x, type = kpss_type)
    list(stat = test@teststat[1])
  }, error = function(e) list(stat = NA))

  # ADF critical values (1%, 5%, 10%)
  adf_cv <- tryCatch({
    test <- ur.df(x, type = adf_type, selectlags = "AIC")
    as.numeric(test@cval[1, ])
  }, error = function(e) rep(NA, 3))

  # KPSS critical values
  kpss_cv <- tryCatch({
    test <- ur.kpss(x, type = kpss_type)
    as.numeric(test@cval[1, ])
  }, error = function(e) rep(NA, 4))

  ur_results[[length(ur_results) + 1]] <- data.frame(
    Variable    = s$label,
    Form        = if (is_diff) "First Diff" else "Level",
    ADF_stat    = round(adf$stat, 4),
    ADF_cv1     = round(adf_cv[1], 4),
    ADF_cv5     = round(adf_cv[2], 4),
    ADF_cv10    = round(adf_cv[3], 4),
    PP_stat     = round(pp$stat, 4),
    KPSS_stat   = round(kpss$stat, 4),
    KPSS_cv10   = round(kpss_cv[1], 4),
    KPSS_cv5    = if (length(kpss_cv) >= 2) round(kpss_cv[2], 4) else NA,
    ADF_result  = ifelse(!is.na(adf$stat) && !is.na(adf_cv[2]),
                         ifelse(adf$stat < adf_cv[2], "I(0)", "I(1)"), "NA"),
    KPSS_result = ifelse(!is.na(kpss$stat) && !is.na(kpss_cv[2]),
                         ifelse(kpss$stat < kpss_cv[2], "I(0)", "I(1)"), "NA"),
    stringsAsFactors = FALSE
  )
}

ur_table <- bind_rows(ur_results)
save_table(ur_table, "table_03_unit_root_battery.csv")

cat("  Unit root battery:\n")
for (i in seq_len(nrow(ur_table))) {
  r <- ur_table[i, ]
  cat(sprintf("    %-16s [%s]: ADF=%.3f (%s) | PP=%.3f | KPSS=%.4f (%s)\n",
      r$Variable, r$Form, r$ADF_stat, r$ADF_result,
      r$PP_stat, r$KPSS_stat, r$KPSS_result))
}

# ── Zivot-Andrews structural break test ──────────────────────────────────────
cat("\n  Zivot-Andrews structural break tests...\n")

za_series <- list(
  list(name = "ln_cpi",   label = "ln(CPI)"),
  list(name = "ln_oil",   label = "ln(Oil INR)"),
  list(name = "ln_brent", label = "ln(Brent USD)"),
  list(name = "ln_exr",   label = "ln(EXR)")
)

za_results <- list()
for (s in za_series) {
  x <- na.omit(df[[s$name]])
  if (length(x) < 30) next

  za <- tryCatch({
    test <- ur.za(x, model = "both", lag = NULL)
    bp_idx <- test@bpoint
    bp_date <- df$date[which(!is.na(df[[s$name]]))[bp_idx]]
    list(
      stat    = test@teststat[1],
      bp_idx  = bp_idx,
      bp_date = bp_date,
      cv1     = test@cval[1],
      cv5     = test@cval[2],
      cv10    = test@cval[3]
    )
  }, error = function(e) NULL)

  if (!is.null(za)) {
    za_results[[length(za_results) + 1]] <- data.frame(
      Variable   = s$label,
      ZA_stat    = round(za$stat, 4),
      Break_date = as.character(za$bp_date),
      CV_1pct    = round(za$cv1, 4),
      CV_5pct    = round(za$cv5, 4),
      CV_10pct   = round(za$cv10, 4),
      Result     = ifelse(za$stat < za$cv5, "Reject H0 (5%)", "Fail to reject"),
      stringsAsFactors = FALSE
    )
    cat(sprintf("    %-16s: stat=%.3f, break=%s [%s]\n",
        s$label, za$stat, za$bp_date,
        ifelse(za$stat < za$cv5, "REJECT", "fail")))
  }
}

if (length(za_results) > 0) {
  za_table <- bind_rows(za_results)
  save_table(za_table, "table_04_zivot_andrews.csv")
}

# ── Bai-Perron multiple breakpoints ──────────────────────────────────────────
# Uses strucchange::breakpoints which implements Bai & Perron (1998, 2003)
# optimal segmentation (BIC-minimizing number of breaks).
cat("\n  Bai-Perron multiple structural breaks (BIC-optimal)...\n")

bp_series <- list(
  list(name = "dlnCPI", label = "dln(CPI) [headline inflation]"),
  list(name = "dlnOil", label = "dln(Oil INR) [rupee oil change]")
)

bp_results <- list()
bp_objects <- list()

for (s in bp_series) {
  y_vec <- df[[s$name]]
  date_vec <- df$date[!is.na(y_vec)]
  y_vec <- y_vec[!is.na(y_vec)]
  if (length(y_vec) < 60) next

  bp_fit <- tryCatch(
    breakpoints(y_vec ~ 1, h = 0.15),  # at least 15% of obs in each segment
    error = function(e) NULL
  )
  if (is.null(bp_fit)) next

  # Summary: F-stats, BIC at k=0..5
  bp_sum <- summary(bp_fit)
  best_k <- bp_fit$breakpoints
  if (all(is.na(best_k))) {
    bp_dates <- "None"
    n_breaks <- 0
  } else {
    bp_dates <- paste(format(date_vec[best_k], "%Y-%m"), collapse = "; ")
    n_breaks <- length(best_k)
  }

  bp_results[[length(bp_results) + 1]] <- data.frame(
    Series = s$label,
    N = length(y_vec),
    N_breaks_BIC = n_breaks,
    Break_dates = bp_dates,
    stringsAsFactors = FALSE
  )

  bp_objects[[s$name]] <- list(fit = bp_fit, dates = date_vec)

  cat(sprintf("    %-28s -> %d breaks at: %s\n", s$label, n_breaks, bp_dates))
}

if (length(bp_results) > 0) {
  bp_table <- bind_rows(bp_results)
  save_table(bp_table, "table_04c_bai_perron.csv")
}

cat("  [05_unit_roots] Done.\n")
