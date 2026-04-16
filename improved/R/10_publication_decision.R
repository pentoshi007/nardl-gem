# -----------------------------------------------------------------------------
# 10_publication_decision.R - publication readiness triage
# -----------------------------------------------------------------------------
# Purpose:
#   Convert the econometric checks into a clear model-use decision for the paper.
#   This prevents the write-up from treating a diagnostic-risk equation as the
#   primary claim and gives the professor a transparent audit trail.
#
# Outputs:
#   table_24_publication_decision.csv
#   table_25_headline_specification_triage.csv
#   table_26_channel_diagnostics.csv (when channel model objects are available)
# -----------------------------------------------------------------------------

banner("10", "PUBLICATION READINESS TRIAGE")

cat("\n  Building publication decision tables...\n")

diag_lookup <- function(pattern) {
  if (!exists("diag_all")) return(data.frame())
  out <- diag_all[grepl(pattern, diag_all$Model, fixed = TRUE), , drop = FALSE]
  if (nrow(out) == 0) data.frame() else out[1, , drop = FALSE]
}

diag_text <- function(d) {
  if (nrow(d) == 0) return("Diagnostics not available")
  sprintf("HAC-RESET p=%.4f; Rec-CUSUM p=%.4f; OLS-CUSUM p=%.4f; BG(12) p=%.4f",
          d$RESET_HAC_p, d$RecCUSUM_p, d$OLS_CUSUM_p, d$BG12_p)
}

result_text <- function(cpt) {
  sprintf("CPT+=%.4f (p=%s); CPT-=%.4f (p=%s); asym p=%s",
          cpt$cpt_pos, format_p(cpt$pos_test$p_value),
          cpt$cpt_neg, format_p(cpt$neg_test$p_value),
          format_p(cpt$asym_test$p_value))
}

m1_diag <- diag_lookup("M1: Asym INR")
m2_diag <- diag_lookup("M2: Brent+EXR")
m3_diag <- diag_lookup("M3: Interaction")

decision_rows <- list(
  data.frame(
    Specification = "M1: INR-denominated oil ADL(p,3)",
    Recommended_role = "Main headline CPI specification",
    Paper_location = "Main text",
    Keep = "YES",
    Key_result = result_text(cpt_m1),
    Diagnostic_status = diag_text(m1_diag),
    Publication_decision = paste(
      "Use as the conservative headline model.",
      "Do not claim 5% asymmetry; say positive pass-through is suggestive and asymmetry is weak."
    ),
    stringsAsFactors = FALSE
  ),
  data.frame(
    Specification = "M2: Brent plus exchange-rate decomposition ADL(p,3)",
    Recommended_role = "Robustness/decomposition",
    Paper_location = "Robustness section",
    Keep = "YES, with caution",
    Key_result = result_text(cpt_m2),
    Diagnostic_status = diag_text(m2_diag),
    Publication_decision = paste(
      "Do not call this the primary model.",
      "Use it to show that separating Brent and INR/USD gives a larger but diagnostic-risk positive coefficient."
    ),
    stringsAsFactors = FALSE
  ),
  data.frame(
    Specification = "M2-AIC0: Brent plus exchange rate, q=0",
    Recommended_role = "AIC benchmark",
    Paper_location = "Appendix/robustness",
    Keep = "YES",
    Key_result = sprintf("CPT+=%.4f (p=%s); CPT-=%.4f; asym p=%s",
                         cpt_m2a$cpt_pos, format_p(cpt_m2a$pos_test$p_value),
                         cpt_m2a$cpt_neg, format_p(cpt_m2a$asym_test$p_value)),
    Diagnostic_status = "AIC-best and diagnostic-safer, but oil pass-through is negative/weak",
    Publication_decision = "Report for transparency; do not use for the substantive oil pass-through claim.",
    stringsAsFactors = FALSE
  ),
  data.frame(
    Specification = "M3: Brent plus exchange-rate deregulation interaction",
    Recommended_role = "Regime-change evidence only",
    Paper_location = "Appendix or short robustness paragraph",
    Keep = "LIMITED",
    Key_result = sprintf("Regime test p=%s; post-dereg CPT+=%.4f; asym p=%s",
                         format_p(regime_p), cpt_post$cpt_pos,
                         format_p(cpt_post$asym_test$p_value)),
    Diagnostic_status = diag_text(m3_diag),
    Publication_decision = "Use only to motivate policy-regime heterogeneity; do not use as a main pass-through estimate.",
    stringsAsFactors = FALSE
  )
)

if (exists("ppac_result") && !is.null(ppac_result)) {
  decision_rows[[length(decision_rows) + 1]] <- data.frame(
    Specification = "PPAC Delhi retail petrol model",
    Recommended_role = "Mechanism/channel evidence",
    Paper_location = "Main text mechanism section",
    Keep = "YES",
    Key_result = sprintf("CPT+=%.4f (p=%s); CPT-=%.4f (p=%s); asym p=%s",
                         ppac_result$CPT_pos, format_p(ppac_result$CPTpos_p),
                         ppac_result$CPT_neg, format_p(ppac_result$CPTneg_p),
                         format_p(ppac_result$Asym_p)),
    Diagnostic_status = "Direct channel; diagnostics checked in table_26 when model object is available",
    Publication_decision = "This is the strongest publishable mechanism result.",
    stringsAsFactors = FALSE
  )
}

if (exists("fuel_result") && !is.null(fuel_result)) {
  decision_rows[[length(decision_rows) + 1]] <- data.frame(
    Specification = "CPI Fuel and Light model",
    Recommended_role = "Mechanism/channel evidence",
    Paper_location = "Main text or appendix",
    Keep = "YES",
    Key_result = sprintf("CPT+=%.4f (p=%s); CPT-=%.4f (p=%s); asym p=%s",
                         fuel_result$CPT_pos, format_p(fuel_result$CPTpos_p),
                         fuel_result$CPT_neg, format_p(fuel_result$CPTneg_p),
                         format_p(fuel_result$Asym_p)),
    Diagnostic_status = "Sub-index channel; diagnostics checked in table_26 when model object is available",
    Publication_decision = "Use to show attenuation from retail fuel to the CPI basket.",
    stringsAsFactors = FALSE
  )
}

if (exists("nardl_a_valid") || exists("nardl_b_valid")) {
  decision_rows[[length(decision_rows) + 1]] <- data.frame(
    Specification = "NARDL A/B",
    Recommended_role = "Not a claim-bearing model",
    Paper_location = "Appendix only, or remove",
    Keep = "NO for main claims",
    Key_result = sprintf("ECT valid: A=%s; B=%s",
                         ifelse(exists("nardl_a_valid") && isTRUE(nardl_a_valid), "YES", "NO"),
                         ifelse(exists("nardl_b_valid") && isTRUE(nardl_b_valid), "YES", "NO")),
    Diagnostic_status = "Positive ECT means the ECM interpretation is invalid",
    Publication_decision = "Do not present long-run NARDL pass-through or dynamic multipliers as evidence.",
    stringsAsFactors = FALSE
  )
}

publication_decision <- bind_rows(decision_rows)
save_table(publication_decision, "table_24_publication_decision.csv")

# -----------------------------------------------------------------------------
# Headline specification triage: show why the recommended model choice is not a
# p-value fishing exercise.
# -----------------------------------------------------------------------------

safe_extract <- function(model, restriction, vcov_mat, label) {
  tryCatch(
    extract_wald(model, restriction, vcov_mat, label),
    error = function(e) data.frame(
      Test = label, F_stat = NA_real_, df1 = NA_real_, df2 = NA_real_,
      p_value = NA_real_, stringsAsFactors = FALSE
    )
  )
}

safe_cpt <- function(model, pos_names, neg_names, nw_vcov, label_prefix = "") {
  cn <- names(coef(model))[!is.na(coef(model))]
  pos_names <- intersect(pos_names, cn)
  neg_names <- intersect(neg_names, cn)
  if (length(pos_names) == 0 || length(neg_names) == 0) {
    return(list(cpt_pos = NA_real_, cpt_neg = NA_real_,
                pos_p = NA_real_, neg_p = NA_real_, asym_p = NA_real_))
  }
  cpt_pos <- sum(coef(model)[pos_names])
  cpt_neg <- sum(coef(model)[neg_names])
  pos_test <- safe_extract(model, sum_eq_zero(pos_names), nw_vcov,
                           paste0(label_prefix, "H0: CPT+ = 0"))
  neg_test <- safe_extract(model, sum_eq_zero(neg_names), nw_vcov,
                           paste0(label_prefix, "H0: CPT- = 0"))
  asym_test <- safe_extract(model, sum_eq_sum(pos_names, neg_names), nw_vcov,
                            paste0(label_prefix, "H0: CPT+ = CPT-"))
  list(
    cpt_pos = cpt_pos,
    cpt_neg = cpt_neg,
    pos_p = pos_test$p_value[1],
    neg_p = neg_test$p_value[1],
    asym_p = asym_test$p_value[1]
  )
}

fit_headline_spec <- function(label, oil_prefix, q, add_exr = FALSE, p = best_p) {
  ar <- paste0("dlnCPI_L", 1:p)
  pos <- paste0(oil_prefix, "_pos_L", 0:q)
  neg <- paste0(oil_prefix, "_neg_L", 0:q)
  rhs <- c(
    ar, pos, neg,
    if (add_exr) c("dlnEXR", "dlnEXR_L1") else character(0),
    "dlnIIP", "D_petrol", "D_diesel", "D_covid", paste0("M", 1:11)
  )
  rhs <- rhs[rhs %in% names(df)]
  dat <- df[complete.cases(df[, c("dlnCPI", rhs)]), ]
  rhs <- rhs[vapply(rhs, function(t) length(unique(dat[[t]])) > 1, logical(1))]
  f <- as.formula(paste("dlnCPI ~", paste(rhs, collapse = " + ")))
  mod <- lm(f, data = dat)
  nw <- NeweyWest(mod, lag = nw_lag(nrow(dat)), prewhite = FALSE)
  cp <- safe_cpt(mod, pos, neg, nw, paste0(label, ": "))
  dg <- tryCatch(
    run_diagnostics(mod, f, dat, label),
    error = function(e) data.frame(
      BG12_p = NA_real_, BP_p = NA_real_, RESET_HAC_p = NA_real_,
      RecCUSUM_p = NA_real_, OLS_CUSUM_p = NA_real_,
      stringsAsFactors = FALSE
    )
  )
  data.frame(
    Spec = label,
    q = q,
    N = nrow(dat),
    AIC = round(AIC(mod), 2),
    Adj_R2 = round(summary(mod)$adj.r.squared, 4),
    CPT_pos = round(cp$cpt_pos, 6),
    CPT_neg = round(cp$cpt_neg, 6),
    CPTpos_p = round(cp$pos_p, 4),
    Asym_p = round(cp$asym_p, 4),
    RESET_HAC_p = dg$RESET_HAC_p[1],
    RecCUSUM_p = dg$RecCUSUM_p[1],
    OLS_CUSUM_p = dg$OLS_CUSUM_p[1],
    BG12_p = dg$BG12_p[1],
    stringsAsFactors = FALSE
  )
}

triage_specs <- list()
for (q_try in 0:3) {
  triage_specs[[length(triage_specs) + 1]] <- fit_headline_spec(
    paste0("INR_oil_q", q_try), "dlnOil", q_try, add_exr = FALSE
  )
}
for (q_try in 0:3) {
  triage_specs[[length(triage_specs) + 1]] <- fit_headline_spec(
    paste0("Brent_EXR_q", q_try), "dlnBrent", q_try, add_exr = TRUE
  )
}
for (q_try in 0:3) {
  triage_specs[[length(triage_specs) + 1]] <- fit_headline_spec(
    paste0("INR_oil_plus_EXR_q", q_try), "dlnOil", q_try, add_exr = TRUE
  )
}

headline_triage <- bind_rows(triage_specs) %>%
  mutate(
    Diagnostics_OK = ifelse(
      RESET_HAC_p > 0.05 & RecCUSUM_p > 0.05 &
        OLS_CUSUM_p > 0.05 & BG12_p > 0.05,
      "YES", "NO"
    ),
    Publication_use = case_when(
      Spec == "INR_oil_q3" ~ "Recommended headline: diagnostic-safe and theory-consistent, but weak asymmetry",
      Spec == "Brent_EXR_q3" ~ "Robustness only: larger positive CPT but diagnostic-risk",
      Diagnostics_OK == "YES" & CPTpos_p < 0.10 ~ "Candidate, but check theory before using",
      Diagnostics_OK == "YES" ~ "Diagnostic-safe but weak/no oil effect",
      TRUE ~ "Diagnostic-risk"
    )
  )

save_table(headline_triage, "table_25_headline_specification_triage.csv")

# -----------------------------------------------------------------------------
# Channel diagnostics, when the model objects and estimation frames are available.
# -----------------------------------------------------------------------------

channel_diag <- list()

add_channel_diag <- function(label, model_name, formula_name, data_name) {
  if (!exists(model_name) || !exists(formula_name) || !exists(data_name)) return(NULL)
  mod <- get(model_name)
  f <- get(formula_name)
  dat <- get(data_name)
  tryCatch(run_diagnostics(mod, f, dat, label), error = function(e) NULL)
}

channel_diag[[length(channel_diag) + 1]] <- add_channel_diag(
  "PPAC Petrol", "m_ppac", "f_ppac", "df_ppac_est"
)
channel_diag[[length(channel_diag) + 1]] <- add_channel_diag(
  "CPI Fuel and Light", "m_fuel", "f_fuel", "df_fuel_est"
)
channel_diag[[length(channel_diag) + 1]] <- add_channel_diag(
  "PPAC Petrol to Fuel CPI", "m_s2", "f_s2", "df_s2_est"
)
channel_diag <- channel_diag[!vapply(channel_diag, is.null, logical(1))]

if (length(channel_diag) > 0) {
  channel_diagnostics <- bind_rows(channel_diag)
  save_table(channel_diagnostics, "table_26_channel_diagnostics.csv")
}

cat("  Publication triage complete.\n")
cat("  [10_publication_decision] Done.\n")
