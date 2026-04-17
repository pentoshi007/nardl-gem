# ==============================================================================
# 01_helpers.R — Helper functions
# ==============================================================================
banner("01", "HELPER FUNCTIONS")

format_p <- function(p) {
  if (is.na(p)) return("NA")
  if (p < 0.001) return("<0.001")
  sprintf("%.4f", p)
}

sig_stars <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.01, "***",
      ifelse(p < 0.05, "**",
        ifelse(p < 0.10, "*", ""))))
}

save_table <- function(df, filename) {
  path <- file.path(PATHS$tables, filename)
  write.csv(df, path, row.names = FALSE)
  cat(sprintf("  Saved: %s\n", filename))
}

save_figure_path <- function(filename) {
  file.path(PATHS$figures, filename)
}

nw_lag <- function(n) floor(0.75 * n^(1/3))

normalize_label <- function(x) {
  gsub("[^A-Z0-9]", "", toupper(trimws(x)))
}

read_excel_minimal <- function(path, sheet = 1) {
  suppressMessages(read_excel(path, sheet = sheet, col_names = FALSE, .name_repair = "minimal"))
}

parse_oea_date_id <- function(x) {
  digits <- sub("^INDEX", "", sub("^INDX", "", x))
  if (nchar(digits) == 4) {
    yy <- as.integer(substr(digits, 3, 4))
    yyyy <- ifelse(yy <= 30, 2000L + yy, 1900L + yy)
    return(as.Date(sprintf("%d-%s-01", yyyy, substr(digits, 1, 2))))
  }
  as.Date(sprintf("%s-%s-01", substr(digits, 3, 6), substr(digits, 1, 2)))
}

get_row_series <- function(path, target_label) {
  x <- read_excel_minimal(path)
  header_row <- as.character(unlist(x[1, ]))
  date_cols <- which(grepl("^(INDX|INDEX)", header_row))
  if (length(date_cols) == 0) stop("No monthly index columns found in ", basename(path))

  row_labels <- as.character(x[[1]])
  row_idx <- which(normalize_label(row_labels) == normalize_label(target_label))[1]
  if (is.na(row_idx)) stop("Row '", target_label, "' not found in ", basename(path))

  parsed_dates <- as.Date(vapply(
    header_row[date_cols],
    function(x) as.integer(parse_oea_date_id(x)),
    integer(1)
  ), origin = "1970-01-01")

  tibble(
    date = parsed_dates,
    raw_value = as.numeric(unlist(x[row_idx, date_cols])),
    source_file = basename(path),
    source_label = row_labels[row_idx]
  ) %>%
    distinct(date, .keep_all = TRUE) %>%
    arrange(date)
}

parse_world_bank_brent <- function(path) {
  x <- read_excel_minimal(path, sheet = "Monthly Prices")
  series_labels <- as.character(unlist(x[5, ]))
  date_ids <- as.character(unlist(x[7:nrow(x), 1]))
  brent_col <- which(normalize_label(series_labels) == normalize_label("Crude oil, Brent"))[1]
  if (is.na(brent_col)) stop("Brent column not found in World Bank workbook.")

  tibble(
    date = as.Date(sprintf("%s-%s-01", substr(date_ids, 1, 4), substr(date_ids, 6, 7))),
    brent_usd = as.numeric(unlist(x[7:nrow(x), brent_col]))
  ) %>%
    filter(!is.na(date), !is.na(brent_usd)) %>%
    arrange(date)
}

load_exr_series <- function(path) {
  read.csv(path, stringsAsFactors = FALSE) %>%
    transmute(date = as.Date(observation_date), exr = as.numeric(EXINUS)) %>%
    filter(!is.na(date), !is.na(exr)) %>%
    arrange(date)
}

extract_wald <- function(model, hypothesis, vcov_mat, label = "") {
  res <- linearHypothesis(model, hypothesis, vcov. = vcov_mat)
  list(
    label = label,
    F_stat = unname(res$F[2]),
    p_value = unname(res$`Pr(>F)`[2])
  )
}

compute_cpt <- function(model, pos_names, neg_names, vcov_mat, label = "") {
  coefs <- coef(model)
  pos_names <- intersect(pos_names, names(coefs))
  neg_names <- intersect(neg_names, names(coefs))

  pos_hyp <- paste(paste(pos_names, collapse = " + "), "= 0")
  neg_hyp <- paste(paste(neg_names, collapse = " + "), "= 0")
  asym_hyp <- paste(paste(pos_names, collapse = " + "), "=", paste(neg_names, collapse = " + "))

  list(
    cpt_pos = sum(coefs[pos_names]),
    cpt_neg = sum(coefs[neg_names]),
    pos_test = extract_wald(model, pos_hyp, vcov_mat, paste0(label, "H0: CPT+ = 0")),
    neg_test = extract_wald(model, neg_hyp, vcov_mat, paste0(label, "H0: CPT- = 0")),
    asym_test = extract_wald(model, asym_hyp, vcov_mat, paste0(label, "H0: CPT+ = CPT-"))
  )
}

coef_table <- function(model, vcov_mat) {
  ct <- coeftest(model, vcov. = vcov_mat)
  data.frame(
    Variable = rownames(ct),
    Estimate = round(ct[, 1], 6),
    NW_SE = round(ct[, 2], 6),
    t_value = round(ct[, 3], 4),
    p_value = round(ct[, 4], 4),
    Sig = sig_stars(ct[, 4]),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

estimation_data <- function(data, formula) {
  mf <- model.frame(formula, data = data, na.action = na.pass)
  keep <- complete.cases(mf)
  data[keep, , drop = FALSE]
}

reset_hac <- function(model, data, formula, power = 2:3, label = "") {
  yhat <- fitted(model)
  d_aug <- data
  added <- character(0)

  if (2 %in% power) {
    d_aug$RESET_yhat2 <- yhat^2
    added <- c(added, "RESET_yhat2")
  }
  if (3 %in% power) {
    d_aug$RESET_yhat3 <- yhat^3
    added <- c(added, "RESET_yhat3")
  }

  f_aug <- update(formula, paste(". ~ . +", paste(added, collapse = " + ")))
  mod_aug <- lm(f_aug, data = d_aug)
  nw_aug <- NeweyWest(mod_aug, lag = nw_lag(nrow(d_aug)), prewhite = FALSE)
  res <- linearHypothesis(mod_aug, paste(added, "= 0"), vcov. = nw_aug)

  data.frame(
    Label = label,
    RESET_HAC_F = round(unname(res$F[2]), 4),
    RESET_HAC_p = round(unname(res$`Pr(>F)`[2]), 4),
    HAC_pass = ifelse(unname(res$`Pr(>F)`[2]) > 0.05, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}

run_diagnostics <- function(model, formula, data, label) {
  bg <- bgtest(model, order = 12)
  bp <- bptest(model)
  hac_r <- reset_hac(model, data, formula, power = 2:3, label = label)
  cusum_rec <- efp(formula, data = data, type = "Rec-CUSUM")
  cusum_ols <- efp(formula, data = data, type = "OLS-CUSUM")
  rec_test <- sctest(cusum_rec)
  ols_test <- sctest(cusum_ols)

  data.frame(
    Model = label,
    N = nrow(data),
    BG12_p = round(bg$p.value, 4),
    BG12_pass = ifelse(bg$p.value > 0.05, "PASS", "FAIL"),
    BP_p = round(bp$p.value, 4),
    RESET_HAC_p = round(hac_r$RESET_HAC_p, 4),
    RESET_HAC_pass = hac_r$HAC_pass,
    RecCUSUM_p = round(rec_test$p.value, 4),
    RecCUSUM_pass = ifelse(rec_test$p.value > 0.05, "PASS", "FAIL"),
    OLS_CUSUM_p = round(ols_test$p.value, 4),
    OLS_CUSUM_pass = ifelse(ols_test$p.value > 0.05, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}

sample_span_years <- function(dates) {
  dates <- sort(unique(as.Date(dates)))
  if (length(dates) == 0) return(NA_real_)
  start <- dates[1]
  end <- dates[length(dates)]
  months <- 12 * (as.integer(format(end, "%Y")) - as.integer(format(start, "%Y"))) +
    (as.integer(format(end, "%m")) - as.integer(format(start, "%m"))) + 1
  months / 12
}

collect_nardl_summary <- function(label, obj, sample_start, sample_end, dep_name) {
  sels_coef <- obj$sels$coefficients
  y_lag_pattern <- paste0("^", dep_name, "_[0-9]+$")
  y_lag_rows <- grep(y_lag_pattern, rownames(sels_coef))

  ect_coef <- NA_real_
  ect_wald_p <- NA_real_

  if (length(y_lag_rows) > 0) {
    ect_coef <- sum(sels_coef[y_lag_rows, 1])

    fit <- obj$fits
    coef_vec <- coef(fit)
    keep <- !is.na(coef_vec)
    coef_vec <- coef_vec[keep]

    vcov_mat <- tryCatch(
      NeweyWest(fit, lag = nw_lag(nobs(fit)), prewhite = FALSE),
      error = function(e) vcov(fit)
    )

    pick_names <- rownames(sels_coef)[y_lag_rows]
    pick_idx <- match(pick_names, names(coef_vec))
    pick_idx <- pick_idx[!is.na(pick_idx)]

    if (length(pick_idx) > 0 &&
        is.matrix(vcov_mat) &&
        nrow(vcov_mat) == length(coef_vec) &&
        ncol(vcov_mat) == length(coef_vec)) {
      R <- matrix(0, nrow = 1, ncol = length(coef_vec))
      R[1, pick_idx] <- 1
      sum_val <- as.numeric(R %*% coef_vec)
      var_val <- as.numeric(R %*% vcov_mat %*% t(R))
      if (!is.na(var_val) && var_val > 0) {
        z <- sum_val / sqrt(var_val)
        ect_wald_p <- 2 * pnorm(-abs(z))
      }
    }
  } else {
    ect_coef <- sels_coef[2, 1]
    ect_wald_p <- sels_coef[2, 4]
  }

  data.frame(
    Specification = label,
    Sample_start = as.character(sample_start),
    Sample_end = as.character(sample_end),
    N = obj$Nobs,
    Bounds_F = round(obj$fstat, 4),
    ECT_coef = round(ect_coef, 6),
    ECT_p = round(ect_wald_p, 4),
    SR_Wald_p = round(obj$wldsr[1, 2], 4),
    LR_Wald_p = round(obj$wldq[1, 2], 4),
    ECT_valid = ifelse(!is.na(ect_coef) && ect_coef < 0, "YES", "NO"),
    Verdict = ifelse(!is.na(ect_coef) && ect_coef < 0,
      "Valid NARDL ECM",
      "ECT non-negative: treat as exploratory only"),
    stringsAsFactors = FALSE
  )
}

cat("  [01_helpers] Loaded.\n")
