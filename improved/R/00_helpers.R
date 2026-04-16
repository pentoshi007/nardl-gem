# ══════════════════════════════════════════════════════════════════════════════
# 00_helpers.R — Shared utility functions
# ══════════════════════════════════════════════════════════════════════════════

required_packages <- c(

  "tidyverse", "readxl", "tseries", "lmtest", "sandwich",
  "car", "strucchange", "stargazer", "patchwork", "scales", "zoo",
  "jsonlite", "urca", "nardl", "boot"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# ── Paths (relative to project root, set by run_all.R) ──────────────────────
PATHS <- list(
  raw       = "data/raw",
  processed = "data/processed",
  tables    = "improved/outputs/tables",
  figures   = "improved/outputs/figures"
)
for (p in PATHS) dir.create(p, recursive = TRUE, showWarnings = FALSE)

# ── Formatting helpers ───────────────────────────────────────────────────────
format_p <- function(p) {
  if (is.na(p)) return(NA_character_)
  if (p < 0.001) return("<0.001")
  if (p < 0.01) return(sprintf("%.4f", p))
  sprintf("%.4f", p)
}

sig_stars <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.01, "***",
      ifelse(p < 0.05, "**",
        ifelse(p < 0.10, "*", ""))))
}

decision_5pct <- function(p) {
  ifelse(p < 0.05, "Significant at 5%", "Not significant at 5%")
}

# ── Newey-West optimal lag: floor(0.75 * T^(1/3)) ───────────────────────────
nw_lag <- function(n) floor(0.75 * n^(1/3))

# ── Build restriction strings for car::linearHypothesis ──────────────────────
sum_eq_zero <- function(terms) {
  paste(paste(terms, collapse = " + "), "= 0")
}
sum_eq_sum <- function(lhs_terms, rhs_terms) {
  paste(
    paste(lhs_terms, collapse = " + "),
    "=",
    paste(rhs_terms, collapse = " + ")
  )
}

# ── Extract F-test row from linearHypothesis output ──────────────────────────
extract_wald <- function(model, restriction, vcov_mat, label) {
  test <- linearHypothesis(model, restriction, vcov. = vcov_mat)
  data.frame(
    Test     = label,
    F_stat   = unname(test$F[2]),
    df1      = unname(test$Df[2]),
    df2      = unname(test$Res.Df[2]),
    p_value  = unname(test$`Pr(>F)`[2]),
    stringsAsFactors = FALSE
  )
}

# ── Compute cumulative pass-through and its tests ────────────────────────────
compute_cpt <- function(model, pos_names, neg_names, nw_vcov, label_prefix = "") {
  cpt_pos <- sum(coef(model)[pos_names])
  cpt_neg <- sum(coef(model)[neg_names])

  pos_test <- extract_wald(model, sum_eq_zero(pos_names), nw_vcov,
                           paste0(label_prefix, "H0: CPT+ = 0"))
  neg_test <- extract_wald(model, sum_eq_zero(neg_names), nw_vcov,
                           paste0(label_prefix, "H0: CPT- = 0"))
  asym_test <- extract_wald(model, sum_eq_sum(pos_names, neg_names), nw_vcov,
                            paste0(label_prefix, "H0: CPT+ = CPT-"))

  list(
    cpt_pos    = cpt_pos,
    cpt_neg    = cpt_neg,
    gap        = cpt_pos - abs(cpt_neg),
    pos_test   = pos_test,
    neg_test   = neg_test,
    asym_test  = asym_test
  )
}

# ── Save CSV helper ──────────────────────────────────────────────────────────
save_table <- function(df, filename) {
  path <- file.path(PATHS$tables, filename)
  write.csv(df, path, row.names = FALSE)
  cat(sprintf("    -> %s\n", path))
}

save_figure <- function(filename) {
  file.path(PATHS$figures, filename)
}

# ── MoSPI CPI API fetcher (unchanged from original) ─────────────────────────
fetch_mospi_cpi_group <- function(years, series, group_code,
                                  sector_code = 3, state_code = 99,
                                  base_year = "2012") {
  base_url <- "https://api.mospi.gov.in/api/cpi/getCPIIndex"
  page <- 1
  out  <- list()

  repeat {
    query <- list(
      base_year = base_year, series = series,
      year = paste(years, collapse = ","),
      month_code = paste(1:12, collapse = ","),
      state_code = state_code, group_code = group_code,
      sector_code = sector_code, page = page, Format = "JSON"
    )
    url <- paste0(base_url, "?",
      paste(paste0(names(query), "=",
        vapply(query, function(x) utils::URLencode(as.character(x), reserved = TRUE),
               character(1))), collapse = "&"))

    raw_txt <- tryCatch(paste(readLines(url, warn = FALSE), collapse = ""),
                        error = function(e) "")
    if (identical(raw_txt, "")) break

    payload <- tryCatch(jsonlite::fromJSON(raw_txt), error = function(e) NULL)
    if (is.null(payload) || !isTRUE(payload$statusCode) ||
        is.null(payload$data) || nrow(payload$data) == 0) break

    out[[length(out) + 1]] <- as.data.frame(payload$data, stringsAsFactors = FALSE)
    total_pages <- tryCatch(as.integer(payload$meta_data$totalPages),
                            error = function(e) NA_integer_)
    if (is.na(total_pages) || page >= total_pages) break
    page <- page + 1
  }
  if (length(out) == 0) return(data.frame())
  bind_rows(out)
}

# ── Section banner printer ───────────────────────────────────────────────────
banner <- function(step, title) {
  cat(sprintf("\n%s\n  STEP %s: %s\n%s\n",
    strrep("=", 56), step, title, strrep("=", 56)))
}

cat("  [00_helpers] Loaded. Packages: ", length(required_packages), "\n")
