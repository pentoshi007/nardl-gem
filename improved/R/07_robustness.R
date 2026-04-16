# ══════════════════════════════════════════════════════════════════════════════
# 07_robustness.R — NOPI, Fuel CPI, PPAC, post-2011, COVID, winsorized,
#                   rolling window, lag grid, sub-sample analysis
# ══════════════════════════════════════════════════════════════════════════════
banner("7", "ROBUSTNESS CHECKS")

dummy_terms <- paste0("M", 1:11, collapse = " + ")

# ══════════════════════════════════════════════════════════════════════════════
# R1: NOPI robustness (Hamilton 2003, with Kilian-Vigfusson 2011 caution)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R1: NOPI Robustness ---\n")

f_nopi <- as.formula(paste0(
  "dlnCPI ~ ", ar_terms,
  " + nopi_pos_L0 + nopi_pos_L1 + nopi_pos_L2 + nopi_pos_L3",
  " + nopi_neg_L0 + nopi_neg_L1 + nopi_neg_L2 + nopi_neg_L3",
  " + dlnIIP + D_petrol + D_diesel + D_covid + ", dummy_terms))

df_nopi <- df %>% filter(complete.cases(
  dlnCPI, !!sym(lag_col), nopi_pos_L3, nopi_neg_L3, dlnIIP))
m_nopi <- lm(f_nopi, data = df_nopi)
nw_nopi <- NeweyWest(m_nopi, lag = nw_lag(nrow(df_nopi)), prewhite = FALSE)

pos_nopi <- paste0("nopi_pos_L", 0:3)
neg_nopi <- paste0("nopi_neg_L", 0:3)
cpt_nopi <- compute_cpt(m_nopi, pos_nopi, neg_nopi, nw_nopi, "NOPI: ")

cat(sprintf("  NOPI: CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s), Asym p = %s\n",
    cpt_nopi$cpt_pos, format_p(cpt_nopi$pos_test$p_value),
    cpt_nopi$cpt_neg, format_p(cpt_nopi$neg_test$p_value),
    format_p(cpt_nopi$asym_test$p_value)))
cat("  Note: NOPI is reported as sensitivity only (Kilian & Vigfusson 2011 caution).\n")

ct_nopi <- coeftest(m_nopi, vcov. = nw_nopi)
nopi_out <- data.frame(
  Variable = rownames(ct_nopi),
  Estimate = round(ct_nopi[, 1], 6),
  NW_SE    = round(ct_nopi[, 2], 6),
  t_value  = round(ct_nopi[, 3], 4),
  p_value  = round(ct_nopi[, 4], 4),
  Sig      = sig_stars(ct_nopi[, 4]),
  row.names = NULL
)
save_table(nopi_out, "table_15_nopi_robustness.csv")

# ══════════════════════════════════════════════════════════════════════════════
# R2: CPI Fuel & Light (MoSPI API)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R2: CPI Fuel & Light (MoSPI API) ---\n")
fuel_result <- NULL
tryCatch({
  fuel_back    <- fetch_mospi_cpi_group(2011:2012, series = "Back",    group_code = 5)
  fuel_current <- fetch_mospi_cpi_group(2013:2024, series = "Current", group_code = 5)

  fuel_api <- bind_rows(fuel_back, fuel_current) %>%
    mutate(
      year      = as.integer(year),
      month_num = match(month, month.name),
      fuel_cpi  = as.numeric(index),
      date      = as.Date(sprintf("%04d-%02d-01", year, month_num))
    ) %>%
    filter(!is.na(date), !is.na(fuel_cpi)) %>%
    distinct(date, .keep_all = TRUE) %>%
    arrange(date) %>%
    select(date, fuel_cpi)

  if (nrow(fuel_api) >= 120) {
    write.csv(fuel_api, file.path(PATHS$processed, "cpi_fuel_light.csv"), row.names = FALSE)
    cat(sprintf("  Fuel CPI: %s to %s (N=%d)\n", min(fuel_api$date), max(fuel_api$date), nrow(fuel_api)))

    df_fuel <- df %>% inner_join(fuel_api, by = "date") %>% arrange(date)
    df_fuel$ln_fuel   <- log(df_fuel$fuel_cpi)
    df_fuel$dlnFuel   <- c(NA, 100 * diff(df_fuel$ln_fuel))
    for (k in 1:4) df_fuel[[paste0("dlnFuel_L", k)]] <- dplyr::lag(df_fuel$dlnFuel, k)

    fuel_lag <- paste0("dlnFuel_L", best_p)
    df_fuel_est <- df_fuel %>% filter(complete.cases(
      dlnFuel, !!sym(fuel_lag), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

    fuel_rhs <- c(paste0("dlnFuel_L", 1:best_p),
                  paste0("dlnOil_pos_L", 0:3), paste0("dlnOil_neg_L", 0:3),
                  "dlnIIP", "D_petrol", "D_diesel", "D_covid", paste0("M", 1:11))
    fuel_rhs <- fuel_rhs[vapply(fuel_rhs, function(t) length(unique(df_fuel_est[[t]])) > 1, logical(1))]
    f_fuel <- as.formula(paste("dlnFuel ~", paste(fuel_rhs, collapse = " + ")))

    m_fuel <- lm(f_fuel, data = df_fuel_est)
    nw_fuel <- NeweyWest(m_fuel, lag = nw_lag(nrow(df_fuel_est)), prewhite = FALSE)

    pos_fuel <- grep("^dlnOil_pos_L", names(coef(m_fuel)), value = TRUE)
    neg_fuel <- grep("^dlnOil_neg_L", names(coef(m_fuel)), value = TRUE)
    cpt_fuel <- compute_cpt(m_fuel, pos_fuel, neg_fuel, nw_fuel, "Fuel: ")

    cat(sprintf("  Fuel CPI: CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s), Asym p = %s\n",
        cpt_fuel$cpt_pos, format_p(cpt_fuel$pos_test$p_value),
        cpt_fuel$cpt_neg, format_p(cpt_fuel$neg_test$p_value),
        format_p(cpt_fuel$asym_test$p_value)))

    fuel_result <- data.frame(
      DV = "CPI Fuel & Light", Source = "MoSPI API",
      Sample = paste(min(df_fuel_est$date), "to", max(df_fuel_est$date)),
      N = nrow(df_fuel_est),
      CPT_pos = round(cpt_fuel$cpt_pos, 6), CPT_neg = round(cpt_fuel$cpt_neg, 6),
      CPTpos_p = round(cpt_fuel$pos_test$p_value, 4),
      CPTneg_p = round(cpt_fuel$neg_test$p_value, 4),
      Asym_p = round(cpt_fuel$asym_test$p_value, 4),
      Adj_R2 = round(summary(m_fuel)$adj.r.squared, 4),
      stringsAsFactors = FALSE)
    save_table(fuel_result, "table_16_fuel_light_appendix.csv")
  } else {
    cat("  Fuel CPI: insufficient API data, skipped.\n")
  }
}, error = function(e) cat(sprintf("  Fuel CPI: API error: %s\n", e$message)))

# ══════════════════════════════════════════════════════════════════════════════
# R3: PPAC Retail Fuel Prices (conditional on data availability)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R3: PPAC Retail Fuel Prices ---\n")
ppac_pre_xls  <- file.path(PATHS$raw, "ppac_rsp_pre2017.xls")
ppac_pre_xlsx <- file.path(PATHS$raw, "ppac_rsp_pre2017.xlsx")
ppac_pre_path <- if (file.exists(ppac_pre_xls)) ppac_pre_xls else ppac_pre_xlsx
ppac_post     <- file.path(PATHS$raw, "ppac_rsp_post2017.xlsx")

ppac_result <- NULL
if (file.exists(ppac_pre_path) && file.exists(ppac_post)) {
  cat("  PPAC files found. Processing...\n")
  tryCatch({
    # ── Pre-2017: RSP Rev(History) sheet ──────────────────────────────────────
    # Columns: Date of Revision | Petrol (Rs/Litre) | Diesel (Rs/Litre)
    # Irregular revision dates (e.g. "As on 1.4.02", "04.06.02") — convert to monthly
    raw_pre <- read_excel(ppac_pre_path, sheet = "RSP Rev(History)", col_names = FALSE)
    names(raw_pre) <- c("date_raw", "petrol", "diesel")

    # Drop header/footer rows: keep only rows where petrol is numeric
    raw_pre$petrol <- suppressWarnings(as.numeric(raw_pre$petrol))
    raw_pre$diesel <- suppressWarnings(as.numeric(raw_pre$diesel))
    raw_pre <- raw_pre %>% filter(!is.na(petrol) & !is.na(diesel))

    # Parse dates: strip "As on " prefix, parse dd.mm.yy or dd.mm.yyyy
    raw_pre$date_raw <- gsub("As on ", "", raw_pre$date_raw, ignore.case = TRUE)
    parse_ppac_date <- function(x) {
      # Try dd.mm.yy then dd.mm.yyyy then dd/mm/yy
      d <- suppressWarnings(as.Date(x, format = "%d.%m.%y"))
      if (is.na(d)) d <- suppressWarnings(as.Date(x, format = "%d.%m.%Y"))
      if (is.na(d)) d <- suppressWarnings(as.Date(x, format = "%d/%m/%y"))
      # Fix 2-digit year ambiguity: if year > 2050, subtract 100
      if (!is.na(d) && as.integer(format(d, "%Y")) > 2050) {
        d <- as.Date(paste0(as.integer(format(d, "%Y")) - 100, format(d, "-%m-%d")))
      }
      d
    }
    raw_pre$date <- as.Date(sapply(raw_pre$date_raw, parse_ppac_date), origin = "1970-01-01")
    raw_pre <- raw_pre %>% filter(!is.na(date)) %>% arrange(date)

    cat(sprintf("  Pre-2017: %d price revisions from %s to %s\n",
        nrow(raw_pre), min(raw_pre$date), max(raw_pre$date)))

    # Convert to monthly: for each month, use the last available revision price
    # (this is the standard approach for irregular revision data)
    raw_pre$ym <- format(raw_pre$date, "%Y-%m")
    monthly_pre <- raw_pre %>%
      group_by(ym) %>%
      summarise(petrol_delhi = last(petrol), diesel_delhi = last(diesel), .groups = "drop") %>%
      mutate(date = as.Date(paste0(ym, "-01"))) %>%
      select(date, petrol_delhi, diesel_delhi) %>%
      arrange(date)

    # Fill forward for months with no revision
    all_months_pre <- data.frame(
      date = seq.Date(min(monthly_pre$date), max(monthly_pre$date), by = "month"))
    monthly_pre <- all_months_pre %>%
      left_join(monthly_pre, by = "date") %>%
      fill(petrol_delhi, diesel_delhi, .direction = "down")

    cat(sprintf("  Pre-2017 monthly: %d months from %s to %s\n",
        nrow(monthly_pre), min(monthly_pre$date), max(monthly_pre$date)))

    # ── Post-2017: Monthly Avg sheet ──────────────────────────────────────────
    monthly_post <- read_excel(ppac_post, sheet = "Monthly Avg")
    names(monthly_post)[1:3] <- c("ym", "petrol_delhi", "diesel_delhi")
    monthly_post <- monthly_post %>%
      mutate(date = as.Date(paste0(ym, "-01"))) %>%
      select(date, petrol_delhi, diesel_delhi) %>%
      filter(!is.na(date))

    cat(sprintf("  Post-2017 monthly: %d months from %s to %s\n",
        nrow(monthly_post), min(monthly_post$date), max(monthly_post$date)))

    # ── Merge: prefer post-2017 where overlap exists ──────────────────────────
    monthly_pre_trimmed <- monthly_pre %>% filter(date < min(monthly_post$date))
    ppac_monthly <- bind_rows(monthly_pre_trimmed, monthly_post) %>% arrange(date)

    # Trim to study window
    ppac_monthly <- ppac_monthly %>%
      filter(date >= as.Date("2004-04-01") & date <= as.Date("2024-12-01"))

    cat(sprintf("  Combined PPAC: %d months from %s to %s\n",
        nrow(ppac_monthly), min(ppac_monthly$date), max(ppac_monthly$date)))

    write.csv(ppac_monthly, file.path(PATHS$processed, "ppac_monthly_delhi.csv"), row.names = FALSE)

    # ── Construct variables and estimate model ────────────────────────────────
    ppac_monthly$ln_petrol <- log(ppac_monthly$petrol_delhi)
    ppac_monthly$ln_diesel <- log(ppac_monthly$diesel_delhi)
    ppac_monthly$dlnPetrol <- c(NA, 100 * diff(ppac_monthly$ln_petrol))
    ppac_monthly$dlnDiesel <- c(NA, 100 * diff(ppac_monthly$ln_diesel))

    # Merge with main dataset
    df_ppac <- df %>% inner_join(ppac_monthly %>% select(date, dlnPetrol, dlnDiesel), by = "date")

    for (k in 1:4) {
      df_ppac[[paste0("dlnPetrol_L", k)]] <- dplyr::lag(df_ppac$dlnPetrol, k)
      df_ppac[[paste0("dlnDiesel_L", k)]] <- dplyr::lag(df_ppac$dlnDiesel, k)
    }

    # Model: dlnPetrol as dependent variable (first-stage pass-through)
    ppac_lag <- paste0("dlnPetrol_L", best_p)
    df_ppac_est <- df_ppac %>% filter(complete.cases(
      dlnPetrol, !!sym(ppac_lag), dlnBrent_pos_L3, dlnBrent_neg_L3, dlnIIP))

    ppac_rhs <- c(paste0("dlnPetrol_L", 1:best_p),
                  paste0("dlnBrent_pos_L", 0:3), paste0("dlnBrent_neg_L", 0:3),
                  "dlnIIP", "D_petrol", "D_diesel", "D_covid", paste0("M", 1:11))
    ppac_rhs <- ppac_rhs[vapply(ppac_rhs, function(t) length(unique(df_ppac_est[[t]])) > 1, logical(1))]
    f_ppac <- as.formula(paste("dlnPetrol ~", paste(ppac_rhs, collapse = " + ")))

    m_ppac <- lm(f_ppac, data = df_ppac_est)
    nw_ppac <- NeweyWest(m_ppac, lag = nw_lag(nrow(df_ppac_est)), prewhite = FALSE)

    pos_ppac <- grep("^dlnBrent_pos_L", names(coef(m_ppac)), value = TRUE)
    neg_ppac <- grep("^dlnBrent_neg_L", names(coef(m_ppac)), value = TRUE)
    cpt_ppac <- compute_cpt(m_ppac, pos_ppac, neg_ppac, nw_ppac, "PPAC: ")

    cat(sprintf("  PPAC Petrol: CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s), Asym p = %s, N = %d\n",
        cpt_ppac$cpt_pos, format_p(cpt_ppac$pos_test$p_value),
        cpt_ppac$cpt_neg, format_p(cpt_ppac$neg_test$p_value),
        format_p(cpt_ppac$asym_test$p_value), nrow(df_ppac_est)))

    ppac_result <- data.frame(
      DV = "dlnPetrol (Delhi RSP)", Source = "PPAC",
      Sample = paste(min(df_ppac_est$date), "to", max(df_ppac_est$date)),
      N = nrow(df_ppac_est),
      CPT_pos = round(cpt_ppac$cpt_pos, 6), CPT_neg = round(cpt_ppac$cpt_neg, 6),
      CPTpos_p = round(cpt_ppac$pos_test$p_value, 4),
      CPTneg_p = round(cpt_ppac$neg_test$p_value, 4),
      Asym_p = round(cpt_ppac$asym_test$p_value, 4),
      Adj_R2 = round(summary(m_ppac)$adj.r.squared, 4),
      stringsAsFactors = FALSE)
    save_table(ppac_result, "table_22_ppac_retail_fuel.csv")

  }, error = function(e) cat(sprintf("  PPAC processing error: %s\n", e$message)))
} else {
  cat("  PPAC files not found. Skipped.\n")
  cat("  To enable, download from:\n")
  cat("    Pre-2017: https://ppac.gov.in/retail-selling-price-rsp-of-petrol-diesel-and-domestic-lpg/rsp-of-petrol-and-diesel-at-delhi-up-to-15-6-2017\n")
  cat("    Post-2017: https://ppac.gov.in/retail-selling-price-rsp-of-petrol-diesel-and-domestic-lpg/\n")
}

# ══════════════════════════════════════════════════════════════════════════════
# R4: Post-2011 CPI subsample (addresses OECD-reconstructed pre-2011 concern)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R4: Post-2011 CPI Subsample ---\n")
df_post2011 <- df %>% filter(date >= as.Date("2011-01-01"))
df_post2011_est <- df_post2011 %>% filter(complete.cases(
  dlnCPI, !!sym(lag_col), dlnBrent_pos_L3, dlnBrent_neg_L3,
  dlnEXR, dlnEXR_L1, dlnIIP))

f_m2_sub <- f_m2
if (length(unique(df_post2011_est$D_petrol)) == 1)
  f_m2_sub <- update(f_m2_sub, . ~ . - D_petrol)

m2_post2011 <- lm(f_m2_sub, data = df_post2011_est)
nw_post2011 <- NeweyWest(m2_post2011, lag = nw_lag(nrow(df_post2011_est)), prewhite = FALSE)

pos_2011 <- grep("^dlnBrent_pos_L", names(coef(m2_post2011)), value = TRUE)
neg_2011 <- grep("^dlnBrent_neg_L", names(coef(m2_post2011)), value = TRUE)
cpt_2011 <- compute_cpt(m2_post2011, pos_2011, neg_2011, nw_post2011, "Post-2011: ")

cat(sprintf("  Post-2011: CPT+ = %.6f (p=%s), CPT- = %.6f (p=%s), Asym p = %s, N = %d\n",
    cpt_2011$cpt_pos, format_p(cpt_2011$pos_test$p_value),
    cpt_2011$cpt_neg, format_p(cpt_2011$neg_test$p_value),
    format_p(cpt_2011$asym_test$p_value), nrow(df_post2011_est)))

# ══════════════════════════════════════════════════════════════════════════════
# R5: Sub-sample analysis (pre/post Oct 2014 diesel deregulation)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R5: Sub-Sample Analysis (Pre/Post 2014) ---\n")

estimate_subsample <- function(data_sub, label) {
  f_sub <- f_m2
  sub_est <- data_sub %>% filter(complete.cases(
    dlnCPI, !!sym(lag_col), dlnBrent_pos_L3, dlnBrent_neg_L3,
    dlnEXR, dlnEXR_L1, dlnIIP))

  if (length(unique(sub_est$D_covid)) == 1)  f_sub <- update(f_sub, . ~ . - D_covid)
  if (length(unique(sub_est$D_petrol)) == 1) f_sub <- update(f_sub, . ~ . - D_petrol)
  if (length(unique(sub_est$D_diesel)) == 1) f_sub <- update(f_sub, . ~ . - D_diesel)

  mod <- lm(f_sub, data = sub_est)
  nw <- NeweyWest(mod, lag = nw_lag(nrow(sub_est)), prewhite = FALSE)

  pos <- grep("^dlnBrent_pos_L", names(coef(mod)), value = TRUE)
  neg <- grep("^dlnBrent_neg_L", names(coef(mod)), value = TRUE)
  cpt <- compute_cpt(mod, pos, neg, nw)

  cat(sprintf("  %s: N=%d, CPT+=%.6f, CPT-=%.6f, Asym p=%s, Adj.R2=%.4f\n",
      label, nrow(sub_est), cpt$cpt_pos, cpt$cpt_neg,
      format_p(cpt$asym_test$p_value), summary(mod)$adj.r.squared))

  data.frame(
    Period = label, N = nrow(sub_est),
    CPT_pos = round(cpt$cpt_pos, 6), CPT_neg = round(cpt$cpt_neg, 6),
    CPTpos_p = round(cpt$pos_test$p_value, 4),
    CPTneg_p = round(cpt$neg_test$p_value, 4),
    Asym_p = round(cpt$asym_test$p_value, 4),
    Adj_R2 = round(summary(mod)$adj.r.squared, 4),
    stringsAsFactors = FALSE)
}

pre14  <- df %>% filter(date < as.Date("2014-10-01"))
post14 <- df %>% filter(date >= as.Date("2014-10-01"))

sub_pre14  <- estimate_subsample(pre14, "Pre-2014 (Brent+EXR)")
sub_post14 <- estimate_subsample(post14, "Post-2014 (Brent+EXR)")

subsample_out <- bind_rows(sub_pre14, sub_post14)
save_table(subsample_out, "table_17_subsample.csv")

# ══════════════════════════════════════════════════════════════════════════════
# R6: COVID sensitivity
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R6: COVID Sensitivity ---\n")
f_nocovid <- update(f_m2, . ~ . - D_covid)
m2_nocovid <- lm(f_nocovid, data = df_m2)
nw_nc <- NeweyWest(m2_nocovid, lag = nw_lag(nrow(df_m2)), prewhite = FALSE)
cpt_nc <- compute_cpt(m2_nocovid,
  grep("^dlnBrent_pos_L", names(coef(m2_nocovid)), value = TRUE),
  grep("^dlnBrent_neg_L", names(coef(m2_nocovid)), value = TRUE),
  nw_nc, "NoCOVID: ")

cat(sprintf("  Without COVID: CPT+ = %.6f, CPT- = %.6f, Asym p = %s\n",
    cpt_nc$cpt_pos, cpt_nc$cpt_neg, format_p(cpt_nc$asym_test$p_value)))

covid_out <- data.frame(
  Specification = c("M2 with COVID dummy", "M2 without COVID dummy"),
  CPT_pos = c(round(cpt_m2$cpt_pos, 6), round(cpt_nc$cpt_pos, 6)),
  CPT_neg = c(round(cpt_m2$cpt_neg, 6), round(cpt_nc$cpt_neg, 6)),
  Asym_p  = c(round(cpt_m2$asym_test$p_value, 4), round(cpt_nc$asym_test$p_value, 4)),
  stringsAsFactors = FALSE
)
save_table(covid_out, "table_18_covid_sensitivity.csv")

# ══════════════════════════════════════════════════════════════════════════════
# R7: Winsorized (top/bottom 1%)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R7: Winsorized (1%) ---\n")
winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  pmin(pmax(x, q[1]), q[2])
}
df_w <- df
for (k in 0:3) {
  df_w[[paste0("dlnBrent_pos_L", k)]] <- winsorize(dplyr::lag(df_w$dlnBrent_pos, k))
  df_w[[paste0("dlnBrent_neg_L", k)]] <- winsorize(dplyr::lag(df_w$dlnBrent_neg, k))
}
df_w_est <- df_w %>% filter(complete.cases(
  dlnCPI, !!sym(lag_col), dlnBrent_pos_L3, dlnBrent_neg_L3, dlnEXR, dlnEXR_L1, dlnIIP))
m2_win <- lm(f_m2, data = df_w_est)
nw_win <- NeweyWest(m2_win, lag = nw_lag(nrow(df_w_est)), prewhite = FALSE)
cpt_win <- compute_cpt(m2_win,
  grep("^dlnBrent_pos_L", names(coef(m2_win)), value = TRUE),
  grep("^dlnBrent_neg_L", names(coef(m2_win)), value = TRUE),
  nw_win, "Win: ")

cat(sprintf("  Winsorized: CPT+ = %.6f, CPT- = %.6f, Asym p = %s\n",
    cpt_win$cpt_pos, cpt_win$cpt_neg, format_p(cpt_win$asym_test$p_value)))

win_out <- data.frame(
  Specification = c("M2 original", "M2 winsorized (1%)"),
  CPT_pos = c(round(cpt_m2$cpt_pos, 6), round(cpt_win$cpt_pos, 6)),
  CPT_neg = c(round(cpt_m2$cpt_neg, 6), round(cpt_win$cpt_neg, 6)),
  Asym_p  = c(round(cpt_m2$asym_test$p_value, 4), round(cpt_win$asym_test$p_value, 4)),
  stringsAsFactors = FALSE
)
save_table(win_out, "table_19_winsorized.csv")

# ══════════════════════════════════════════════════════════════════════════════
# R8: Rolling window (60-month) on M2 specification
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R8: Rolling Window (60-month, M2) ---\n")
window_size <- 60
df_roll <- df %>% filter(complete.cases(
  dlnCPI, !!sym(lag_col), dlnBrent_pos_L3, dlnBrent_neg_L3,
  dlnEXR, dlnEXR_L1, dlnIIP))
n_roll <- nrow(df_roll)

roll_dates <- roll_cpt_pos <- roll_cpt_neg <- c()

if (n_roll >= window_size + 10) {
  for (i in 1:(n_roll - window_size + 1)) {
    sub <- df_roll[i:(i + window_size - 1), ]
    f_roll <- f_m2
    if (length(unique(sub$D_covid)) == 1)  f_roll <- update(f_roll, . ~ . - D_covid)
    if (length(unique(sub$D_petrol)) == 1) f_roll <- update(f_roll, . ~ . - D_petrol)
    if (length(unique(sub$D_diesel)) == 1) f_roll <- update(f_roll, . ~ . - D_diesel)

    tryCatch({
      mod_r <- lm(f_roll, data = sub)
      cp <- sum(coef(mod_r)[grep("dlnBrent_pos", names(coef(mod_r)))])
      cn <- sum(coef(mod_r)[grep("dlnBrent_neg", names(coef(mod_r)))])
      roll_dates    <- c(roll_dates, as.character(sub$date[window_size]))
      roll_cpt_pos  <- c(roll_cpt_pos, cp)
      roll_cpt_neg  <- c(roll_cpt_neg, cn)
    }, error = function(e) NULL)
  }

  roll_df <- data.frame(
    Date = as.Date(roll_dates), CPT_pos = roll_cpt_pos, CPT_neg = roll_cpt_neg
  )
  write.csv(roll_df, file.path(PATHS$tables, "rolling_window_data.csv"), row.names = FALSE)
  assign("roll_df", roll_df, envir = .GlobalEnv)
  cat(sprintf("  Rolling window: %d estimates computed.\n", nrow(roll_df)))
}

# ══════════════════════════════════════════════════════════════════════════════
# R9: Lag grid sensitivity (p=1..4, q=0..3) on M2 specification
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- R9: Lag Grid Sensitivity (Brent+EXR) ---\n")
df_grid <- df %>% filter(complete.cases(
  dlnCPI, dlnCPI_L1, dlnCPI_L2, dlnCPI_L3, dlnCPI_L4,
  dlnBrent_pos_L3, dlnBrent_neg_L3, dlnEXR, dlnEXR_L1, dlnIIP))

grid_results <- list()
idx <- 1
for (p_try in 1:4) {
  ar_try <- paste0("dlnCPI_L", 1:p_try, collapse = " + ")
  for (q_try in 0:3) {
    pos_t <- paste0("dlnBrent_pos_L", 0:q_try, collapse = " + ")
    neg_t <- paste0("dlnBrent_neg_L", 0:q_try, collapse = " + ")
    f_str <- paste0("dlnCPI ~ ", ar_try, " + ", pos_t, " + ", neg_t,
                    " + dlnEXR + dlnEXR_L1 + dlnIIP + D_petrol + D_diesel + D_covid + ",
                    dummy_terms)
    mod_g <- lm(as.formula(f_str), data = df_grid)
    nw_g  <- NeweyWest(mod_g, lag = nw_lag(nrow(df_grid)), prewhite = FALSE)

    pos_g <- grep("^dlnBrent_pos_L", names(coef(mod_g)), value = TRUE)
    neg_g <- grep("^dlnBrent_neg_L", names(coef(mod_g)), value = TRUE)
    cpt_g <- compute_cpt(mod_g, pos_g, neg_g, nw_g)

    grid_results[[idx]] <- data.frame(
      p = p_try, q = q_try,
      AIC = round(AIC(mod_g), 2), BIC = round(BIC(mod_g), 2),
      CPT_pos = round(cpt_g$cpt_pos, 6), CPT_neg = round(cpt_g$cpt_neg, 6),
      Asym_p = round(cpt_g$asym_test$p_value, 4),
      Primary = ifelse(p_try == best_p && q_try == 3, "Yes", "No"),
      stringsAsFactors = FALSE)
    idx <- idx + 1
  }
}
lag_grid <- bind_rows(grid_results) %>% mutate(AIC_Rank = rank(AIC, ties.method = "first"))
save_table(lag_grid, "table_20_lag_sensitivity.csv")
best_g <- lag_grid %>% arrange(AIC) %>% slice(1)
cat(sprintf("  Primary: ADL(%d,3) AIC=%.2f | Best grid: ADL(%d,%d) AIC=%.2f, Asym p=%s\n",
    best_p,
    lag_grid %>% filter(p == best_p, q == 3) %>% pull(AIC),
    best_g$p, best_g$q, best_g$AIC, format_p(best_g$Asym_p)))

# ══════════════════════════════════════════════════════════════════════════════
# Comprehensive robustness summary table
# ══════════════════════════════════════════════════════════════════════════════
cat("\n  --- Comprehensive Robustness Summary ---\n")

robustness_summary <- bind_rows(
  data.frame(Check = "M2 Primary (Brent+EXR, q=3 theory)",
             CPT_pos = round(cpt_m2$cpt_pos, 6),
             CPT_neg = round(cpt_m2$cpt_neg, 6),
             Asym_p  = round(cpt_m2$asym_test$p_value, 4),
             Note    = "Primary model; q=3 theory-driven",
             stringsAsFactors = FALSE),
  if (exists("cpt_m2a")) data.frame(
             Check = "M2-AIC0 (Brent+EXR, q=0 AIC-optimal)",
             CPT_pos = round(cpt_m2a$cpt_pos, 6),
             CPT_neg = round(cpt_m2a$cpt_neg, 6),
             Asym_p  = round(cpt_m2a$asym_test$p_value, 4),
             Note    = "AIC-optimal; contemporaneous only; reported for transparency",
             stringsAsFactors = FALSE),
  data.frame(Check = "NOPI (Hamilton 2003)",
             CPT_pos = round(cpt_nopi$cpt_pos, 6),
             CPT_neg = round(cpt_nopi$cpt_neg, 6),
             Asym_p  = round(cpt_nopi$asym_test$p_value, 4),
             Note    = "Sensitivity only; Kilian & Vigfusson (2011) caution applies",
             stringsAsFactors = FALSE),
  if (!is.null(fuel_result)) data.frame(
             Check = "Fuel & Light CPI",
             CPT_pos = fuel_result$CPT_pos,
             CPT_neg = fuel_result$CPT_neg,
             Asym_p  = fuel_result$Asym_p,
             Note    = "Mechanism: oil->fuel sub-index; stronger signal than headline",
             stringsAsFactors = FALSE),
  if (!is.null(ppac_result)) data.frame(
             Check = "PPAC Petrol (Delhi RSP)",
             CPT_pos = ppac_result$CPT_pos,
             CPT_neg = ppac_result$CPT_neg,
             Asym_p  = ppac_result$Asym_p,
             Note    = "Mechanism: oil->retail petrol; strongest asymmetry evidence",
             stringsAsFactors = FALSE),
  data.frame(Check = "Post-2011 subsample",
             CPT_pos = round(cpt_2011$cpt_pos, 6),
             CPT_neg = round(cpt_2011$cpt_neg, 6),
             Asym_p  = round(cpt_2011$asym_test$p_value, 4),
             Note    = "Addresses OECD-reconstructed pre-2011 CPI concern",
             stringsAsFactors = FALSE),
  data.frame(Check = "Pre-2014 (Brent+EXR)",
             CPT_pos = sub_pre14$CPT_pos,
             CPT_neg = sub_pre14$CPT_neg,
             Asym_p  = sub_pre14$Asym_p,
             Note    = "Pre-diesel deregulation period",
             stringsAsFactors = FALSE),
  data.frame(Check = "Post-2014 (Brent+EXR)",
             CPT_pos = sub_post14$CPT_pos,
             CPT_neg = sub_post14$CPT_neg,
             Asym_p  = sub_post14$Asym_p,
             Note    = "Post-diesel deregulation; Pradeep (2022) comparison period",
             stringsAsFactors = FALSE),
  data.frame(Check = "No COVID dummy",
             CPT_pos = round(cpt_nc$cpt_pos, 6),
             CPT_neg = round(cpt_nc$cpt_neg, 6),
             Asym_p  = round(cpt_nc$asym_test$p_value, 4),
             Note    = "Robustness to Apr-2020 outlier specification",
             stringsAsFactors = FALSE),
  data.frame(Check = "Winsorized (1%)",
             CPT_pos = round(cpt_win$cpt_pos, 6),
             CPT_neg = round(cpt_win$cpt_neg, 6),
             Asym_p  = round(cpt_win$asym_test$p_value, 4),
             Note    = "Robustness to extreme oil price observations",
             stringsAsFactors = FALSE)
)
save_table(robustness_summary, "table_21_robustness_summary.csv")
print(robustness_summary)

# Store sub-sample results for figures
assign("sub_pre14",  sub_pre14,  envir = .GlobalEnv)
assign("sub_post14", sub_post14, envir = .GlobalEnv)
assign("cpt_nopi",   cpt_nopi,   envir = .GlobalEnv)
assign("cpt_2011",   cpt_2011,   envir = .GlobalEnv)

# Store PPAC and fuel models for dilution test (09_dilution.R)
if (exists("m_ppac") && !is.null(m_ppac)) {
  assign("m_ppac",     m_ppac,     envir = .GlobalEnv)
  assign("ppac_result", ppac_result, envir = .GlobalEnv)
}
if (exists("m_fuel") && !is.null(m_fuel)) {
  assign("m_fuel",     m_fuel,     envir = .GlobalEnv)
  assign("fuel_result", fuel_result, envir = .GlobalEnv)
}

cat("  [07_robustness] Done.\n")
