# ==============================================================================
# 09_mechanism_chain.R — Mechanism evidence and dilution chain
# ==============================================================================
# Restores the stronger v1 mechanism equations, while enforcing the v2 rule that
# only 20+ year models can be treated as mandatory/main-text evidence.
# ==============================================================================
banner("09", "MECHANISM CHAIN — DILUTION HYPOTHESIS")

cat("  Testing transmission chain:\n")
cat("  Brent => PPAC Petrol => Fuel & Light CPI => Headline CPI\n\n")

mechanism_summary_row <- function(specification, requested_role, data, cpt, adj_r2,
                                  note = "", duration_required = MIN_MAIN_YEARS) {
  win <- sample_window(data)
  span_years <- sample_span_years(data)
  duration_flag <- duration_ok(data, min_years = duration_required)

  data.frame(
    Specification = specification,
    Requested_role = requested_role,
    Sample_start = as.character(win$start),
    Sample_end = as.character(win$end),
    N = nrow(data),
    Span_years = round(span_years, 2),
    Duration_20Y = ifelse(duration_flag, "YES", "NO"),
    CPT_pos = round(cpt$cpt_pos, 6),
    CPT_neg = round(cpt$cpt_neg, 6),
    CPTpos_p = round(cpt$pos_test$p_value, 4),
    CPTneg_p = round(cpt$neg_test$p_value, 4),
    Asym_p = round(cpt$asym_test$p_value, 4),
    Adj_R2 = round(adj_r2, 4),
    Note = note,
    stringsAsFactors = FALSE
  )
}

dilution_row <- function(stage, dv_label, iv_label, cpt_pos, cpt_neg,
                         pos_p, neg_p, asym_p, n_obs, adj_r2, note = "") {
  data.frame(
    Stage = stage,
    DV = dv_label,
    IV = iv_label,
    N = n_obs,
    CPT_pos = round(cpt_pos, 6),
    CPT_neg = round(cpt_neg, 6),
    CPTpos_p = round(pos_p, 4),
    CPTneg_p = round(neg_p, 4),
    Asym_p = round(asym_p, 4),
    Adj_R2 = round(adj_r2, 4),
    Asym_evidence = ifelse(asym_p < 0.05, "Strong (p<5%)",
                    ifelse(asym_p < 0.10, "Marginal (p<10%)",
                    ifelse(asym_p < 0.15, "Suggestive (p<15%)", "Weak/None"))),
    Note = note,
    stringsAsFactors = FALSE
  )
}

dilution_results <- list()

# ==============================================================================
# STAGE 1: Brent -> PPAC retail petrol
# Uses the richer v1 specification so v2 does not regress in mechanism strength.
# ==============================================================================
cat("  --- Stage 1: Brent USD => PPAC Retail Petrol (Delhi) ---\n")

ppac_result <- NULL
m_ppac <- NULL

if (ppac_available) {
  ppac_df <- ppac_raw %>%
    arrange(date) %>%
    mutate(
      ln_petrol = log(petrol_delhi),
      ln_diesel = log(diesel_delhi),
      dlnPetrol = c(NA, 100 * diff(ln_petrol)),
      dlnDiesel = c(NA, 100 * diff(ln_diesel))
    )

  df_ppac <- df %>%
    inner_join(ppac_df %>% select(date, dlnPetrol, dlnDiesel), by = "date")

  for (k in 1:4) {
    df_ppac[[paste0("dlnPetrol_L", k)]] <- dplyr::lag(df_ppac$dlnPetrol, k)
    df_ppac[[paste0("dlnDiesel_L", k)]] <- dplyr::lag(df_ppac$dlnDiesel, k)
  }

  ppac_lag <- paste0("dlnPetrol_L", best_p)
  df_ppac_est <- df_ppac %>% filter(complete.cases(
    dlnPetrol, !!sym(ppac_lag), dlnBrent_pos_L3, dlnBrent_neg_L3, dlnIIP))

  ppac_rhs <- c(
    paste0("dlnPetrol_L", 1:best_p),
    paste0("dlnBrent_pos_L", 0:3),
    paste0("dlnBrent_neg_L", 0:3),
    "dlnIIP", "D_petrol", "D_diesel", "D_covid", paste0("M", 1:11)
  )
  ppac_rhs <- ppac_rhs[vapply(ppac_rhs, function(term) {
    term %in% names(df_ppac_est) && length(unique(df_ppac_est[[term]])) > 1
  }, logical(1))]

  f_ppac <- as.formula(paste("dlnPetrol ~", paste(ppac_rhs, collapse = " + ")))
  m_ppac <- lm(f_ppac, data = df_ppac_est)
  nw_ppac <- NeweyWest(m_ppac, lag = nw_lag(nrow(df_ppac_est)), prewhite = FALSE)

  pos_ppac <- grep("^dlnBrent_pos_L", names(coef(m_ppac)), value = TRUE)
  neg_ppac <- grep("^dlnBrent_neg_L", names(coef(m_ppac)), value = TRUE)
  cpt_ppac <- compute_cpt(m_ppac, pos_ppac, neg_ppac, nw_ppac, "PPAC: ")

  cat(sprintf("  N=%d | CPT+= %.4f (p=%s) | CPT-= %.4f (p=%s) | Asym p = %s\n",
      nrow(df_ppac_est),
      cpt_ppac$cpt_pos, format_p(cpt_ppac$pos_test$p_value),
      cpt_ppac$cpt_neg, format_p(cpt_ppac$neg_test$p_value),
      format_p(cpt_ppac$asym_test$p_value)))

  ppac_result <- mechanism_summary_row(
    specification = "PPAC Delhi retail petrol model",
    requested_role = "Mandatory mechanism model",
    data = df_ppac_est,
    cpt = cpt_ppac,
    adj_r2 = summary(m_ppac)$adj.r.squared,
    note = "20+ year direct fuel-price pass-through channel"
  )
  save_table(ppac_result, "table_22_ppac_retail_fuel.csv")
  save_table(coef_table(m_ppac, nw_ppac), "table_22b_ppac_retail_fuel_coefficients.csv")

  dilution_results[["S1"]] <- dilution_row(
    stage = "Stage 1: Brent -> PPAC Petrol",
    dv_label = "dlnPetrol (Delhi RSP)",
    iv_label = "dlnBrent +/- (Brent USD, q=3)",
    cpt_pos = cpt_ppac$cpt_pos,
    cpt_neg = cpt_ppac$cpt_neg,
    pos_p = cpt_ppac$pos_test$p_value,
    neg_p = cpt_ppac$neg_test$p_value,
    asym_p = cpt_ppac$asym_test$p_value,
    n_obs = nrow(df_ppac_est),
    adj_r2 = summary(m_ppac)$adj.r.squared,
    note = "Mandatory 20+ year mechanism stage"
  )
} else {
  cat("  Stage 1 skipped: PPAC data not available.\n")
}

# ==============================================================================
# DIRECT FUEL MODEL: Oil -> Fuel & Light CPI
# Stronger than headline CPI, but shorter than 20 years in the current data.
# ==============================================================================
cat("\n  --- Direct Fuel Model: Oil => CPI Fuel & Light ---\n")

fuel_result <- NULL
m_fuel <- NULL

if (fuel_available) {
  fuel_series <- fuel_raw %>%
    transmute(date = as.Date(date), fuel_cpi = as.numeric(fuel_cpi)) %>%
    filter(!is.na(date), !is.na(fuel_cpi)) %>%
    distinct(date, .keep_all = TRUE) %>%
    arrange(date)

  df_fuel <- df %>%
    inner_join(fuel_series, by = "date") %>%
    arrange(date)

  df_fuel$ln_fuel <- log(df_fuel$fuel_cpi)
  df_fuel$dlnFuel <- c(NA, 100 * diff(df_fuel$ln_fuel))
  for (k in 1:4) df_fuel[[paste0("dlnFuel_L", k)]] <- dplyr::lag(df_fuel$dlnFuel, k)

  fuel_lag <- paste0("dlnFuel_L", best_p)
  df_fuel_est <- df_fuel %>% filter(complete.cases(
    dlnFuel, !!sym(fuel_lag), dlnOil_pos_L3, dlnOil_neg_L3, dlnIIP))

  fuel_rhs <- c(
    paste0("dlnFuel_L", 1:best_p),
    paste0("dlnOil_pos_L", 0:3),
    paste0("dlnOil_neg_L", 0:3),
    "dlnIIP", "D_petrol", "D_diesel", "D_covid", paste0("M", 1:11)
  )
  fuel_rhs <- fuel_rhs[vapply(fuel_rhs, function(term) {
    term %in% names(df_fuel_est) && length(unique(df_fuel_est[[term]])) > 1
  }, logical(1))]

  f_fuel <- as.formula(paste("dlnFuel ~", paste(fuel_rhs, collapse = " + ")))
  m_fuel <- lm(f_fuel, data = df_fuel_est)
  nw_fuel <- NeweyWest(m_fuel, lag = nw_lag(nrow(df_fuel_est)), prewhite = FALSE)

  pos_fuel <- grep("^dlnOil_pos_L", names(coef(m_fuel)), value = TRUE)
  neg_fuel <- grep("^dlnOil_neg_L", names(coef(m_fuel)), value = TRUE)
  cpt_fuel <- compute_cpt(m_fuel, pos_fuel, neg_fuel, nw_fuel, "Fuel: ")

  cat(sprintf("  N=%d | CPT+= %.4f (p=%s) | CPT-= %.4f (p=%s) | Asym p = %s\n",
      nrow(df_fuel_est),
      cpt_fuel$cpt_pos, format_p(cpt_fuel$pos_test$p_value),
      cpt_fuel$cpt_neg, format_p(cpt_fuel$neg_test$p_value),
      format_p(cpt_fuel$asym_test$p_value)))

  fuel_note <- if (duration_ok(df_fuel_est)) {
    "Eligible for mandatory use"
  } else {
    "Supporting mechanism evidence only: current series starts in 2011"
  }

  fuel_result <- mechanism_summary_row(
    specification = "CPI Fuel & Light model",
    requested_role = "Supporting mechanism model",
    data = df_fuel_est,
    cpt = cpt_fuel,
    adj_r2 = summary(m_fuel)$adj.r.squared,
    note = fuel_note
  )
  save_table(fuel_result, "table_16_fuel_light.csv")
  save_table(coef_table(m_fuel, nw_fuel), "table_16b_fuel_light_coefficients.csv")
} else {
  cat("  Direct fuel model skipped: Fuel CPI data not available.\n")
}

# ==============================================================================
# STAGE 2 BRIDGE: PPAC petrol -> Fuel & Light CPI
# Shorter-sample bridge equation for the dilution narrative.
# ==============================================================================
cat("\n  --- Stage 2 Bridge: PPAC Petrol => CPI Fuel & Light ---\n")

bridge_result <- NULL
m_s2 <- NULL

if (ppac_available && fuel_available) {
  df_s2 <- ppac_raw %>%
    inner_join(fuel_raw %>% transmute(date = as.Date(date), fuel_cpi = as.numeric(fuel_cpi)),
               by = "date") %>%
    arrange(date) %>%
    mutate(
      dlnPetrol = c(NA, 100 * diff(log(petrol_delhi))),
      dlnFuel = c(NA, 100 * diff(log(fuel_cpi))),
      dlnPetrol_pos = pmax(dlnPetrol, 0),
      dlnPetrol_neg = pmin(dlnPetrol, 0)
    )

  for (k in 0:3) {
    df_s2[[paste0("dlnPetrol_pos_L", k)]] <- dplyr::lag(df_s2$dlnPetrol_pos, k)
    df_s2[[paste0("dlnPetrol_neg_L", k)]] <- dplyr::lag(df_s2$dlnPetrol_neg, k)
  }
  for (k in 1:best_p) {
    df_s2[[paste0("dlnFuel_L", k)]] <- dplyr::lag(df_s2$dlnFuel, k)
  }

  bridge_lag <- paste0("dlnFuel_L", best_p)
  df_s2_est <- df_s2 %>% filter(complete.cases(
    dlnFuel, !!sym(bridge_lag), dlnPetrol_pos_L3, dlnPetrol_neg_L3))

  bridge_rhs <- c(
    paste0("dlnFuel_L", 1:best_p),
    paste0("dlnPetrol_pos_L", 0:3),
    paste0("dlnPetrol_neg_L", 0:3)
  )
  bridge_rhs <- bridge_rhs[vapply(bridge_rhs, function(term) {
    term %in% names(df_s2_est) && length(unique(df_s2_est[[term]])) > 1
  }, logical(1))]

  f_s2 <- as.formula(paste("dlnFuel ~", paste(bridge_rhs, collapse = " + ")))
  m_s2 <- lm(f_s2, data = df_s2_est)
  nw_s2 <- NeweyWest(m_s2, lag = nw_lag(nrow(df_s2_est)), prewhite = FALSE)

  pos_s2 <- grep("^dlnPetrol_pos_L", names(coef(m_s2)), value = TRUE)
  neg_s2 <- grep("^dlnPetrol_neg_L", names(coef(m_s2)), value = TRUE)
  c2 <- compute_cpt(m_s2, pos_s2, neg_s2, nw_s2, "Bridge: ")

  cat(sprintf("  N=%d | CPT+= %.4f (p=%s) | CPT-= %.4f (p=%s) | Asym p = %s\n",
      nrow(df_s2_est),
      c2$cpt_pos, format_p(c2$pos_test$p_value),
      c2$cpt_neg, format_p(c2$neg_test$p_value),
      format_p(c2$asym_test$p_value)))

  bridge_result <- mechanism_summary_row(
    specification = "PPAC petrol to Fuel & Light bridge model",
    requested_role = "Dilution-chain bridge",
    data = df_s2_est,
    cpt = c2,
    adj_r2 = summary(m_s2)$adj.r.squared,
    note = "Bridge equation only; not eligible as mandatory because sample begins in 2011"
  )
  save_table(bridge_result, "table_27_ppac_to_fuel_bridge.csv")
  save_table(coef_table(m_s2, nw_s2), "table_27b_ppac_to_fuel_bridge_coefficients.csv")

  dilution_results[["S2"]] <- dilution_row(
    stage = "Stage 2: PPAC Petrol -> Fuel & Light CPI",
    dv_label = "dlnFuel (CPI Fuel & Light)",
    iv_label = "dlnPetrol +/- (PPAC Delhi, q=3)",
    cpt_pos = c2$cpt_pos,
    cpt_neg = c2$cpt_neg,
    pos_p = c2$pos_test$p_value,
    neg_p = c2$neg_test$p_value,
    asym_p = c2$asym_test$p_value,
    n_obs = nrow(df_s2_est),
    adj_r2 = summary(m_s2)$adj.r.squared,
    note = "Bridge stage only; shorter sample than headline/PPAC models"
  )
} else {
  missing <- c(if (!ppac_available) "PPAC", if (!fuel_available) "Fuel CPI")
  cat(sprintf("  Bridge skipped: %s not available.\n", paste(missing, collapse = ", ")))
}

# ==============================================================================
# STAGE 3: Oil -> headline CPI
# ==============================================================================
cat("\n  --- Stage 3: Oil => Headline CPI (M1 headline) ---\n")
cat(sprintf("  M1 (headline): CPT+= %.4f (p=%s) | CPT-= %.4f (p=%s) | Asym p = %s\n",
    cpt_m1$cpt_pos, format_p(cpt_m1$pos_test$p_value),
    cpt_m1$cpt_neg, format_p(cpt_m1$neg_test$p_value),
    format_p(cpt_m1$asym_test$p_value)))

dilution_results[["S3"]] <- dilution_row(
  stage = "Stage 3: Oil -> Headline CPI (M1)",
  dv_label = "dlnCPI (Headline, All India)",
  iv_label = "dlnOil_INR +/- (INR oil, q=3)",
  cpt_pos = cpt_m1$cpt_pos,
  cpt_neg = cpt_m1$cpt_neg,
  pos_p = cpt_m1$pos_test$p_value,
  neg_p = cpt_m1$neg_test$p_value,
  asym_p = cpt_m1$asym_test$p_value,
  n_obs = nrow(df_m1),
  adj_r2 = summary(m1)$adj.r.squared,
  note = "Mandatory 20+ year headline model"
)

# ==============================================================================
# Dilution summary
# ==============================================================================
cat("\n  === DILUTION HYPOTHESIS SUMMARY ===\n")
if (length(dilution_results) > 0) {
  dilution_tbl <- bind_rows(dilution_results)
  save_table(dilution_tbl, "table_23_dilution_hypothesis.csv")
  print(dilution_tbl[, c("Stage", "CPT_pos", "CPT_neg", "Asym_p", "Asym_evidence")])

  cat("\n  Interpretation:\n")
  cat("  CPT+ and |CPT-| should decline from Stage 1 to Stage 3\n")
  cat("  as energy shocks get absorbed by the food and services CPI components.\n")

  if ("S1" %in% names(dilution_results) && "S3" %in% names(dilution_results)) {
    s1_pos <- dilution_results[["S1"]]$CPT_pos
    s3_pos <- dilution_results[["S3"]]$CPT_pos
    if (!is.na(s1_pos) && s1_pos > 0) {
      cat(sprintf("  Dilution ratio: CPT+ falls from %.4f to %.4f\n", s1_pos, s3_pos))
      cat(sprintf("  => Headline CPI captures ~%.1f%% of retail fuel pass-through.\n",
          100 * s3_pos / s1_pos))
    }
  }
}

cat("  [09_mechanism_chain] Done.\n")
