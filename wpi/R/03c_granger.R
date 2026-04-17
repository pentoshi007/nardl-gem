# ==============================================================================
# 03c_granger.R — Granger causality tests for oil-to-WPI transmission
# ==============================================================================
# Tests:
#   (a) dlnOil -> dlnWPI              (headline transmission)
#   (b) dlnWPI -> dlnOil              (reverse / feedback)
#   (c) dlnOil -> dlnFuelWPI          (sector-level transmission)
#   (d) dlnBrent -> dlnWPI            (USD oil to WPI)
#
# Standard Granger (1969): F-test that lagged values of X add predictive
# power for Y beyond lagged Y alone. Uses HAC-robust Wald via car.
# ==============================================================================
banner("03c", "GRANGER CAUSALITY")

p_grg <- 4  # 4 lags (quarterly frequency in monthly data)

granger_hac <- function(y_name, x_name, data, p = p_grg, label = "") {
  d <- data[, c(y_name, x_name), drop = FALSE]
  d <- d[complete.cases(d), , drop = FALSE]
  for (k in 1:p) {
    d[[paste0(y_name, "_L", k)]] <- dplyr::lag(d[[y_name]], k)
    d[[paste0(x_name, "_L", k)]] <- dplyr::lag(d[[x_name]], k)
  }
  d <- d[complete.cases(d), , drop = FALSE]
  if (nrow(d) < 30) {
    return(data.frame(
      Direction = label, N = nrow(d), Lags = p,
      F_stat = NA_real_, HAC_p = NA_real_,
      Verdict = "Insufficient obs", stringsAsFactors = FALSE
    ))
  }

  y_lags <- paste0(y_name, "_L", 1:p)
  x_lags <- paste0(x_name, "_L", 1:p)
  rhs    <- c(y_lags, x_lags)
  f_u    <- as.formula(paste(y_name, "~", paste(rhs, collapse = " + ")))
  m_u    <- lm(f_u, data = d)
  nw_u   <- NeweyWest(m_u, lag = nw_lag(nrow(d)), prewhite = FALSE)

  test   <- linearHypothesis(m_u, paste(x_lags, "= 0"), vcov. = nw_u)
  Fstat  <- unname(test$F[2])
  pval   <- unname(test$`Pr(>F)`[2])

  verdict <- if (is.na(pval)) "NA" else
             if (pval < 0.01) "Reject H0 (strong)" else
             if (pval < 0.05) "Reject H0 (5%)" else
             if (pval < 0.10) "Reject H0 (10%)" else
             "Fail to reject (no Granger cause)"

  data.frame(
    Direction = label, N = nrow(d), Lags = p,
    F_stat = round(Fstat, 4), HAC_p = round(pval, 4),
    Verdict = verdict, stringsAsFactors = FALSE
  )
}

granger_rows <- list()

# (a) dlnOil -> dlnWPI (core headline transmission)
granger_rows[["oil_wpi"]] <- granger_hac(
  "dln_dep", "dln_oil", headline_model_data,
  p = p_grg, label = "dlnOil -> dlnWPI (headline)"
)

# (b) dlnWPI -> dlnOil (reverse for completeness)
granger_rows[["wpi_oil"]] <- granger_hac(
  "dln_oil", "dln_dep", headline_model_data,
  p = p_grg, label = "dlnWPI -> dlnOil (reverse)"
)

# (c) dlnOil -> dlnFuelWPI (sector-level)
granger_rows[["oil_fuel"]] <- granger_hac(
  "dln_dep", "dln_oil", fuel_model_data,
  p = p_grg, label = "dlnOil -> dlnFuelWPI (sector)"
)

# (d) dlnBrent -> dlnWPI (USD oil channel)
granger_rows[["brent_wpi"]] <- granger_hac(
  "dln_dep", "dln_brent", headline_model_data,
  p = p_grg, label = "dlnBrent -> dlnWPI (USD oil)"
)

# (e) dlnEXR -> dlnWPI (exchange rate transmission)
granger_rows[["exr_wpi"]] <- granger_hac(
  "dln_dep", "dln_exr", headline_model_data,
  p = p_grg, label = "dlnEXR -> dlnWPI (exchange rate)"
)

granger_tbl <- bind_rows(granger_rows)
save_table(granger_tbl, "table_16_granger_causality.csv")

cat("  Granger causality results:\n")
for (i in seq_len(nrow(granger_tbl))) {
  r <- granger_tbl[i, ]
  cat(sprintf("    %s: F=%.3f, p=%s [%s]\n",
      r$Direction, r$F_stat, format_p(r$HAC_p), r$Verdict))
}

cat("  [03c_granger] Done.\n")
