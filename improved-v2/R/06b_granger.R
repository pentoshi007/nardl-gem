# ==============================================================================
# 06b_granger.R — Granger causality tests for the transmission chain
# ==============================================================================
# Tests pre-estimation causal direction claims:
#   (a) dlnOil -> dlnCPI              (headline transmission)
#   (b) dlnOil -> dlnPetrol (PPAC)    (first-stage)
#   (c) dlnPetrol -> dlnFuel (F&L)    (second-stage bridge)
#
# Standard Granger (1969): F-test that lagged values of X add predictive
# power for Y beyond lagged Y alone. Uses HAC-robust Wald via car.
# Lag length p=best_p from 06_models.R (AIC-selected).
# ==============================================================================
banner("06b", "GRANGER CAUSALITY (transmission direction)")

p_grg <- if (exists("best_p")) best_p else 1

granger_hac <- function(y_name, x_name, data, p = p_grg, label = "") {
  d <- data[, c(y_name, x_name)]
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

# (a) dlnOil -> dlnCPI (core headline transmission)
granger_rows[["oil_cpi"]] <- granger_hac(
  "dlnCPI", "dlnOil", df, p = p_grg, label = "dlnOil -> dlnCPI (headline)"
)
# reverse for completeness
granger_rows[["cpi_oil"]] <- granger_hac(
  "dlnOil", "dlnCPI", df, p = p_grg, label = "dlnCPI -> dlnOil (reverse)"
)

# (b) dlnBrent -> dlnPetrol, using ppac merged dataset
if (exists("ppac_raw")) {
  ppac_dlog <- ppac_raw %>% arrange(date) %>%
    mutate(dlnPetrol = c(NA, 100 * diff(log(petrol_delhi))))
  df_pp <- df %>% inner_join(ppac_dlog %>% select(date, dlnPetrol), by = "date")

  granger_rows[["brent_petrol"]] <- granger_hac(
    "dlnPetrol", "dlnBrent", df_pp, p = p_grg,
    label = "dlnBrent -> dlnPetrol (first-stage)"
  )
}

# (c) dlnPetrol -> dlnFuel
if (exists("ppac_raw") && exists("fuel_raw")) {
  df_pf <- ppac_raw %>% arrange(date) %>%
    mutate(dlnPetrol = c(NA, 100 * diff(log(petrol_delhi)))) %>%
    inner_join(
      fuel_raw %>% transmute(date = as.Date(date),
                             fuel_cpi = as.numeric(fuel_cpi)),
      by = "date"
    ) %>%
    mutate(dlnFuel = c(NA, 100 * diff(log(fuel_cpi))))

  granger_rows[["petrol_fuel"]] <- granger_hac(
    "dlnFuel", "dlnPetrol", df_pf, p = p_grg,
    label = "dlnPetrol -> dlnFuel (bridge)"
  )
}

granger_tbl <- bind_rows(granger_rows)
save_table(granger_tbl, "table_10b_granger_causality.csv")
print(granger_tbl)

cat("  [06b_granger] Done.\n")
