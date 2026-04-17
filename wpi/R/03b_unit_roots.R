# ==============================================================================
# 03b_unit_roots.R — Unit root battery + Zivot-Andrews structural break
# ==============================================================================
# ADF, Phillips-Perron, KPSS on levels and first differences
# Zivot-Andrews for structural break detection
# Bai-Perron multiple breakpoints
# ==============================================================================
banner("03b", "UNIT ROOT TESTS")

# ── Test battery ─────────────────────────────────────────────────────────────
ur_series <- list(
  list(name = "ln_dep",    label = "ln(WPI)",         data = headline_model_data),
  list(name = "ln_oil",    label = "ln(Oil INR)",     data = headline_model_data),
  list(name = "ln_brent",  label = "ln(Brent USD)",   data = headline_model_data),
  list(name = "ln_exr",    label = "ln(EXR)",         data = headline_model_data),
  list(name = "dln_dep",   label = "dln(WPI)",        data = headline_model_data),
  list(name = "dln_oil",   label = "dln(Oil INR)",    data = headline_model_data),
  list(name = "dln_brent", label = "dln(Brent)",      data = headline_model_data),
  list(name = "dln_exr",   label = "dln(EXR)",        data = headline_model_data)
)

ur_results <- list()

for (s in ur_series) {
  x <- na.omit(s$data[[s$name]])
  if (length(x) < 20) next

  is_diff <- grepl("^dln", s$name)
  adf_type <- if (is_diff) "drift" else "trend"

  # ADF
  adf <- tryCatch({
    test <- ur.df(x, type = adf_type, selectlags = "AIC")
    list(stat = test@teststat[1], cval = as.numeric(test@cval[1, ]))
  }, error = function(e) list(stat = NA, cval = rep(NA, 3)))

  # Phillips-Perron
  pp <- tryCatch({
    test <- ur.pp(x, type = "Z-tau", model = if (is_diff) "constant" else "trend")
    list(stat = test@teststat[1])
  }, error = function(e) list(stat = NA))

  # KPSS (H0: stationary)
  kpss_type <- if (is_diff) "mu" else "tau"
  kpss <- tryCatch({
    test <- ur.kpss(x, type = kpss_type)
    list(stat = test@teststat[1], cval = as.numeric(test@cval[1, ]))
  }, error = function(e) list(stat = NA, cval = rep(NA, 4)))

  ur_results[[length(ur_results) + 1]] <- data.frame(
    Variable    = s$label,
    Form        = if (is_diff) "First Diff" else "Level",
    ADF_stat    = round(adf$stat, 4),
    ADF_cv1     = round(adf$cval[1], 4),
    ADF_cv5     = round(adf$cval[2], 4),
    ADF_cv10    = round(adf$cval[3], 4),
    PP_stat     = round(pp$stat, 4),
    KPSS_stat   = round(kpss$stat, 4),
    KPSS_cv10   = round(kpss$cval[1], 4),
    KPSS_cv5    = if (length(kpss$cval) >= 2) round(kpss$cval[2], 4) else NA,
    ADF_result  = ifelse(!is.na(adf$stat) && !is.na(adf$cval[2]),
                         ifelse(adf$stat < adf$cval[2], "I(0)", "I(1)"), "NA"),
    KPSS_result = ifelse(!is.na(kpss$stat) && length(kpss$cval) >= 2 && !is.na(kpss$cval[2]),
                         ifelse(kpss$stat < kpss$cval[2], "I(0)", "I(1)"), "NA"),
    stringsAsFactors = FALSE
  )
}

ur_table <- bind_rows(ur_results)
save_table(ur_table, "table_13_unit_root_battery.csv")

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
  list(name = "ln_dep",   label = "ln(WPI)",       data = headline_model_data),
  list(name = "ln_oil",   label = "ln(Oil INR)",   data = headline_model_data),
  list(name = "ln_brent", label = "ln(Brent USD)", data = headline_model_data),
  list(name = "ln_exr",   label = "ln(EXR)",       data = headline_model_data)
)

za_results <- list()
for (s in za_series) {
  x <- na.omit(s$data[[s$name]])
  dates_vec <- s$data$date[!is.na(s$data[[s$name]])]
  if (length(x) < 30) next

  za <- tryCatch({
    test <- ur.za(x, model = "both", lag = NULL)
    bp_idx  <- test@bpoint
    bp_date <- dates_vec[bp_idx]
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
  save_table(za_table, "table_14_zivot_andrews.csv")
}

# ── Bai-Perron multiple breakpoints ──────────────────────────────────────────
cat("\n  Bai-Perron multiple structural breaks (BIC-optimal)...\n")

bp_series <- list(
  list(name = "dln_dep", label = "dln(WPI) [headline inflation]", data = headline_model_data),
  list(name = "dln_oil", label = "dln(Oil INR) [rupee oil change]", data = headline_model_data)
)

bp_results <- list()
for (s in bp_series) {
  y_vec    <- s$data[[s$name]]
  date_vec <- s$data$date[!is.na(y_vec)]
  y_vec    <- y_vec[!is.na(y_vec)]
  if (length(y_vec) < 60) next

  bp_fit <- tryCatch(
    breakpoints(y_vec ~ 1, h = 0.15),
    error = function(e) NULL
  )
  if (is.null(bp_fit)) next

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
  cat(sprintf("    %-36s -> %d breaks at: %s\n", s$label, n_breaks, bp_dates))
}

if (length(bp_results) > 0) {
  bp_table <- bind_rows(bp_results)
  save_table(bp_table, "table_15_bai_perron.csv")
}

cat("  [03b_unit_roots] Done.\n")
