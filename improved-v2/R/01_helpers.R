# ==============================================================================
# 01_helpers.R — Statistical helper functions
# ==============================================================================
# Newey-West HAC, Wald tests, cumulative pass-through, formatting
# ==============================================================================
banner("01", "HELPER FUNCTIONS")

# ── P-value formatter ────────────────────────────────────────────────────────
format_p <- function(p) {
  if (is.na(p)) return("NA")
  if (p < 0.001) return("<0.001")
  sprintf("%.4f", p)
}

# ── Significance stars ───────────────────────────────────────────────────────
sig_stars <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.01, "***",
      ifelse(p < 0.05, "**",
        ifelse(p < 0.10, "*", ""))))
}

# ── Wald test extraction (single linear hypothesis, HAC vcov) ────────────────
extract_wald <- function(model, hypothesis, vcov_mat, label = "") {
  res <- linearHypothesis(model, hypothesis, vcov. = vcov_mat)
  list(
    label   = label,
    F_stat  = unname(res$F[2]),
    p_value = unname(res$`Pr(>F)`[2]),
    df1     = unname(res$Df[2]),
    df2     = res$Res.Df[2]
  )
}

# ── Cumulative pass-through (CPT) computation ────────────────────────────────
# Sums coefficients for positive and negative oil lag variables,
# tests each sum against zero, and tests CPT+ = CPT- (asymmetry).
compute_cpt <- function(model, pos_names, neg_names, vcov_mat, label = "") {
  coefs <- coef(model)

  # Filter to names actually present in model (handles safe_lm dropped terms)
  pos_names <- intersect(pos_names, names(coefs))
  neg_names <- intersect(neg_names, names(coefs))

  if (length(pos_names) == 0 || length(neg_names) == 0) {
    return(list(cpt_pos = NA_real_, cpt_neg = NA_real_,
                pos_test = list(p_value = NA_real_),
                neg_test = list(p_value = NA_real_),
                asym_test = list(p_value = NA_real_)))
  }

  # CPT+ = sum of positive oil lag coefficients
  cpt_pos <- sum(coefs[pos_names])
  # CPT- = sum of negative oil lag coefficients
  cpt_neg <- sum(coefs[neg_names])

  # Test H0: sum(pos) = 0
  pos_hyp <- paste(paste(pos_names, collapse = " + "), "= 0")
  pos_test <- extract_wald(model, pos_hyp, vcov_mat, paste0(label, "H0: CPT+ = 0"))

  # Test H0: sum(neg) = 0
  neg_hyp <- paste(paste(neg_names, collapse = " + "), "= 0")
  neg_test <- extract_wald(model, neg_hyp, vcov_mat, paste0(label, "H0: CPT- = 0"))

  # Test H0: sum(pos) = sum(neg) (asymmetry test)
  all_names <- c(pos_names, neg_names)
  # Build hypothesis: pos1 + pos2 + ... - neg1 - neg2 - ... = 0
  asym_terms <- c(pos_names, paste0("-", neg_names))
  asym_hyp <- paste(paste(asym_terms, collapse = " + "), "= 0")
  # Fix double-sign: "+ -" -> "- "
  asym_hyp <- gsub("\\+ -", "- ", asym_hyp)
  asym_test <- extract_wald(model, asym_hyp, vcov_mat, paste0(label, "H0: CPT+ = CPT-"))

  list(
    cpt_pos   = cpt_pos,
    cpt_neg   = cpt_neg,
    pos_test  = pos_test,
    neg_test  = neg_test,
    asym_test = asym_test
  )
}

# ── HAC-robust RESET test (Godfrey & Orme 1994) ─────────────────────────────
# Standard resettest() uses OLS-F which is biased under heteroskedasticity.
# This adds fitted^2 and fitted^3 as regressors and tests their joint
# significance using Newey-West sandwich variance.
reset_hac <- function(model, data, formula, power = 2:3, label = "") {
  yhat  <- fitted(model)
  n     <- nrow(data)
  d_aug <- data
  added <- character(0)

  if (2 %in% power) { d_aug$RESET_yhat2 <- yhat^2; added <- c(added, "RESET_yhat2") }
  if (3 %in% power) { d_aug$RESET_yhat3 <- yhat^3; added <- c(added, "RESET_yhat3") }

  f_aug   <- update(formula, paste(". ~ . +", paste(added, collapse = " + ")))
  mod_aug <- lm(f_aug, data = d_aug)
  nw_aug  <- NeweyWest(mod_aug, lag = nw_lag(n), prewhite = FALSE)

  res <- tryCatch(
    linearHypothesis(mod_aug, paste(added, "= 0"), vcov. = nw_aug),
    error = function(e) NULL
  )

  if (is.null(res)) {
    return(data.frame(Label = label, RESET_HAC_F = NA, RESET_HAC_p = NA,
                      HAC_pass = "ERROR", stringsAsFactors = FALSE))
  }

  ols_reset <- resettest(model, power = power, type = "fitted")

  data.frame(
    Label       = label,
    RESET_HAC_F = round(unname(res$F[2]), 4),
    RESET_HAC_p = round(unname(res$`Pr(>F)`[2]), 4),
    RESET_OLS_p = round(ols_reset$p.value, 4),
    HAC_pass    = ifelse(unname(res$`Pr(>F)`[2]) > 0.05, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}

# ── ARCH-LM test (Engle 1982) — auxiliary regression on squared residuals ───
arch_lm_test <- function(resid, lags = 12) {
  r2 <- as.numeric(resid)^2
  n  <- length(r2)
  if (n <= lags + 2) return(list(statistic = NA_real_, p.value = NA_real_, lag = lags))
  lag_mat <- sapply(1:lags, function(k) dplyr::lag(r2, k))
  colnames(lag_mat) <- paste0("r2_L", 1:lags)
  dat  <- as.data.frame(cbind(r2 = r2, lag_mat))
  dat  <- dat[complete.cases(dat), , drop = FALSE]
  if (nrow(dat) <= lags + 1) return(list(statistic = NA_real_, p.value = NA_real_, lag = lags))
  aux  <- lm(as.formula(paste("r2 ~", paste(colnames(lag_mat), collapse = " + "))),
             data = dat)
  r2_aux <- summary(aux)$r.squared
  stat   <- nrow(dat) * r2_aux
  p_val  <- pchisq(stat, df = lags, lower.tail = FALSE)
  list(statistic = stat, p.value = p_val, lag = lags)
}

# ── Jarque-Bera normality test ───────────────────────────────────────────────
jarque_bera <- function(x) {
  x  <- as.numeric(x)
  x  <- x[is.finite(x)]
  n  <- length(x)
  if (n < 8) return(list(statistic = NA_real_, p.value = NA_real_,
                         skewness = NA_real_, kurtosis = NA_real_))
  mu <- mean(x)
  m2 <- sum((x - mu)^2) / n
  m3 <- sum((x - mu)^3) / n
  m4 <- sum((x - mu)^4) / n
  sk <- m3 / m2^1.5
  kt <- m4 / m2^2
  jb <- n * (sk^2 / 6 + (kt - 3)^2 / 24)
  list(statistic = jb, p.value = pchisq(jb, df = 2, lower.tail = FALSE),
       skewness = sk, kurtosis = kt)
}

# ── Coefficient table formatter ──────────────────────────────────────────────
coef_table <- function(model, vcov_mat) {
  ct <- coeftest(model, vcov. = vcov_mat)
  data.frame(
    Variable = rownames(ct),
    Estimate = round(ct[, 1], 6),
    NW_SE    = round(ct[, 2], 6),
    t_value  = round(ct[, 3], 4),
    p_value  = round(ct[, 4], 4),
    Sig      = sig_stars(ct[, 4]),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

# ── Safe LM: drop aliased (collinear) terms and refit ────────────────────────
# Needed for subsamples where D_petrol / D_diesel become constant
safe_lm <- function(formula, data) {
  m <- lm(formula, data = data)
  if (any(is.na(coef(m)))) {
    keep <- names(coef(m))[!is.na(coef(m))]
    keep <- setdiff(keep, "(Intercept)")
    new_f <- reformulate(keep, response = all.vars(formula)[1])
    m <- lm(new_f, data = data)
  }
  m
}

# ── Sample-span helpers ──────────────────────────────────────────────────────
sample_span_months <- function(data, date_col = "date") {
  if (!date_col %in% names(data) || nrow(data) == 0) return(NA_real_)
  dates <- sort(unique(as.Date(data[[date_col]])))
  if (length(dates) == 0) return(NA_real_)
  start <- dates[1]
  end   <- dates[length(dates)]
  12 * (as.integer(format(end, "%Y")) - as.integer(format(start, "%Y"))) +
    (as.integer(format(end, "%m")) - as.integer(format(start, "%m"))) + 1
}

sample_span_years <- function(data, date_col = "date") {
  months <- sample_span_months(data, date_col = date_col)
  if (is.na(months)) return(NA_real_)
  months / 12
}

sample_window <- function(data, date_col = "date") {
  if (!date_col %in% names(data) || nrow(data) == 0) {
    return(list(start = as.Date(NA), end = as.Date(NA)))
  }
  dates <- sort(unique(as.Date(data[[date_col]])))
  list(start = dates[1], end = dates[length(dates)])
}

duration_ok <- function(data, min_years = MIN_MAIN_YEARS, date_col = "date") {
  months <- sample_span_months(data, date_col = date_col)
  !is.na(months) && months >= (12 * min_years)
}

diagnostic_pass_count <- function(diag_row) {
  sum(c(
    diag_row$BG12_pass == "PASS",
    diag_row$RESET_HAC_pass == "PASS",
    diag_row$RecCUSUM_pass == "PASS"
  ), na.rm = TRUE)
}

diagnostic_verdict <- function(diag_row) {
  passes <- diagnostic_pass_count(diag_row)
  if (passes == 3) return("ACCEPT for main text")
  if (passes == 2) return("CAUTION — robustness only")
  "REJECT for main text"
}

cat("  [01_helpers] Loaded.\n")
