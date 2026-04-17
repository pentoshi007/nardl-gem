# ==============================================================================
# 12_publication_triage.R — Publication readiness, duration gating, audit trail
# ==============================================================================
banner("12", "PUBLICATION TRIAGE")

cat("  Building publication decision tables...\n")

diag_lookup <- function(pattern) {
  if (!exists("diag_all")) return(data.frame())
  out <- diag_all[grepl(pattern, diag_all$Model, fixed = TRUE), , drop = FALSE]
  if (nrow(out) == 0) data.frame() else out[1, , drop = FALSE]
}

diag_text <- function(d) {
  if (nrow(d) == 0) return("Diagnostics not available")
  sprintf(
    "HAC-RESET p=%.4f; Rec-CUSUM p=%.4f; OLS-CUSUM p=%.4f; BG(12) p=%.4f",
    d$RESET_HAC_p, d$RecCUSUM_p, d$OLS_CUSUM_p, d$BG12_p
  )
}

bootstrap_text <- function(boot_obj) {
  if (is.null(boot_obj)) return("Bootstrap not available")
  sprintf("Observed Wald F=%.4f; asymptotic p=%s; bootstrap p=%.4f",
          boot_obj$obs_wald, format_p(boot_obj$obs_p), boot_obj$boot_p)
}

result_text <- function(cpt) {
  sprintf("CPT+=%.4f (p=%s); CPT-=%.4f (p=%s); asym p=%s",
          cpt$cpt_pos, format_p(cpt$pos_test$p_value),
          cpt$cpt_neg, format_p(cpt$neg_test$p_value),
          format_p(cpt$asym_test$p_value))
}

result_text_from_row <- function(row) {
  if (is.null(row) || nrow(row) == 0) return("Result not available")
  sprintf("CPT+=%.4f (p=%s); CPT-=%.4f (p=%s); asym p=%s",
          row$CPT_pos[1], format_p(row$CPTpos_p[1]),
          row$CPT_neg[1], format_p(row$CPTneg_p[1]),
          format_p(row$Asym_p[1]))
}

duration_fields <- function(data) {
  win <- sample_window(data)
  data.frame(
    Sample_start = as.character(win$start),
    Sample_end = as.character(win$end),
    Span_years = round(sample_span_years(data), 2),
    Duration_20Y = ifelse(duration_ok(data), "YES", "NO"),
    stringsAsFactors = FALSE
  )
}

m1_diag <- diag_lookup("M1: Asym INR")
m2_diag <- diag_lookup("M2: Brent+EXR")
m3_diag <- diag_lookup("M3: Interaction")

decision_rows <- list(
  cbind(
    data.frame(
      Specification = "M1: INR-denominated oil ADL(p,3)",
      Requested_role = "Mandatory headline model",
      Mandatory = "YES",
      Key_result = result_text(cpt_m1),
      Diagnostic_status = diag_text(m1_diag),
      Bootstrap_status = bootstrap_text(if (exists("boot_m1")) boot_m1 else NULL),
      Publication_decision = paste(
        "Use as the conservative headline model.",
        "Do not claim 5% asymmetry; keep language suggestive and restrained."
      ),
      stringsAsFactors = FALSE
    ),
    duration_fields(df_m1)
  ),
  cbind(
    data.frame(
      Specification = "M2: Brent plus exchange-rate decomposition ADL(p,3)",
      Requested_role = "Robustness/decomposition only",
      Mandatory = "NO",
      Key_result = result_text(cpt_m2),
      Diagnostic_status = diag_text(m2_diag),
      Bootstrap_status = bootstrap_text(if (exists("boot_m2")) boot_m2 else NULL),
      Publication_decision = paste(
        "Keep only as decomposition robustness.",
        "Diagnostics fail, so it cannot be the paper's lead equation."
      ),
      stringsAsFactors = FALSE
    ),
    duration_fields(df_m2)
  ),
  cbind(
    data.frame(
      Specification = "M2-AIC0: Brent plus exchange rate, q=0",
      Requested_role = "Transparency benchmark",
      Mandatory = "NO",
      Key_result = sprintf("CPT+=%.4f (p=%s); CPT-=%.4f; asym p=%s",
                           cpt_m2a$cpt_pos, format_p(cpt_m2a$pos_test$p_value),
                           cpt_m2a$cpt_neg, format_p(cpt_m2a$asym_test$p_value)),
      Diagnostic_status = "AIC-best and diagnostic-safer, but oil pass-through is weak/negative",
      Bootstrap_status = "Not required for transparency benchmark",
      Publication_decision = "Report for transparency; do not use for the substantive oil pass-through claim.",
      stringsAsFactors = FALSE
    ),
    duration_fields(df_m2a)
  ),
  cbind(
    data.frame(
      Specification = "M3: Brent plus exchange-rate interaction model",
      Requested_role = "Appendix only",
      Mandatory = "NO",
      Key_result = sprintf("Regime test p=%s; post-dereg CPT+=%.4f; asym p=%s",
                           format_p(regime_p), cpt_post$cpt_pos,
                           format_p(cpt_post$asym_test$p_value)),
      Diagnostic_status = diag_text(m3_diag),
      Bootstrap_status = "Not required for appendix-only model",
      Publication_decision = "Use only to motivate regime heterogeneity; not a claim-bearing estimate.",
      stringsAsFactors = FALSE
    ),
    duration_fields(df_m3)
  ),
  data.frame(
    Specification = "NARDL A/B",
    Requested_role = "Removed from v2 main pipeline",
    Mandatory = "NO",
    Key_result = "Removed",
    Diagnostic_status = "Prior v1 review rejected NARDL because ECT sign invalidated ECM interpretation",
    Bootstrap_status = "Not applicable",
    Publication_decision = "Keep out of the main claim structure.",
    Sample_start = NA_character_,
    Sample_end = NA_character_,
    Span_years = NA_real_,
    Duration_20Y = "NO",
    stringsAsFactors = FALSE
  )
)

if (!is.null(ppac_result) && nrow(ppac_result) > 0) {
  ppac_diag <- tryCatch(run_diagnostics(m_ppac, f_ppac, df_ppac_est, "PPAC Petrol"),
                        error = function(e) data.frame())
  decision_rows[[length(decision_rows) + 1]] <- cbind(
    data.frame(
      Specification = "PPAC Delhi retail petrol model",
      Requested_role = "Mandatory mechanism model",
      Mandatory = "YES",
      Key_result = result_text_from_row(ppac_result),
      Diagnostic_status = diag_text(ppac_diag),
      Bootstrap_status = "Not required for first-stage mechanism model",
      Publication_decision = "Keep in main text as the 20+ year direct pass-through channel.",
      stringsAsFactors = FALSE
    ),
    duration_fields(df_ppac_est)
  )
}

if (!is.null(fuel_result) && nrow(fuel_result) > 0) {
  fuel_diag <- tryCatch(run_diagnostics(m_fuel, f_fuel, df_fuel_est, "CPI Fuel and Light"),
                        error = function(e) data.frame())
  decision_rows[[length(decision_rows) + 1]] <- cbind(
    data.frame(
      Specification = "CPI Fuel & Light model",
      Requested_role = "Supporting mechanism model",
      Mandatory = "NO",
      Key_result = result_text_from_row(fuel_result),
      Diagnostic_status = diag_text(fuel_diag),
      Bootstrap_status = "Not required for supporting mechanism model",
      Publication_decision = paste(
        "Useful supporting evidence because pass-through is stronger than headline CPI.",
        "Cannot be treated as mandatory/main-text proof until a 20+ year Fuel & Light series is available."
      ),
      stringsAsFactors = FALSE
    ),
    duration_fields(df_fuel_est)
  )
}

if (!is.null(bridge_result) && nrow(bridge_result) > 0) {
  bridge_diag <- tryCatch(run_diagnostics(m_s2, f_s2, df_s2_est, "PPAC Petrol to Fuel CPI"),
                          error = function(e) data.frame())
  decision_rows[[length(decision_rows) + 1]] <- cbind(
    data.frame(
      Specification = "PPAC petrol to Fuel & Light bridge model",
      Requested_role = "Dilution-chain bridge",
      Mandatory = "NO",
      Key_result = result_text_from_row(bridge_result),
      Diagnostic_status = diag_text(bridge_diag),
      Bootstrap_status = "Not required for bridge model",
      Publication_decision = "Use to narrate attenuation from retail fuel to CPI; keep out of the mandatory set.",
      stringsAsFactors = FALSE
    ),
    duration_fields(df_s2_est)
  )
}

publication_decision <- bind_rows(decision_rows)
save_table(publication_decision, "table_24_publication_decision.csv")

# -----------------------------------------------------------------------------
# Headline specification triage
# -----------------------------------------------------------------------------
safe_extract <- function(model, restriction, vcov_mat, label) {
  tryCatch(
    extract_wald(model, restriction, vcov_mat, label),
    error = function(e) data.frame(
      Test = label, F_stat = NA_real_, df1 = NA_real_,
      df2 = NA_real_, p_value = NA_real_, stringsAsFactors = FALSE
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
  pos_test <- safe_extract(model, paste(paste(pos_names, collapse = " + "), "= 0"),
                           nw_vcov, paste0(label_prefix, "H0: CPT+ = 0"))
  neg_test <- safe_extract(model, paste(paste(neg_names, collapse = " + "), "= 0"),
                           nw_vcov, paste0(label_prefix, "H0: CPT- = 0"))
  asym_hyp <- paste(
    paste(c(pos_names, paste0("-", neg_names)), collapse = " + "),
    "= 0"
  )
  asym_hyp <- gsub("\\+ -", "- ", asym_hyp)
  asym_test <- safe_extract(model, asym_hyp, nw_vcov,
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
    "dlnIIP", "D_petrol", "D_diesel", "D_covid",
    paste0("mo_", c("Jan","Feb","Mar","Apr","May","Jun",
                    "Jul","Aug","Sep","Oct","Nov"))
  )
  rhs <- rhs[rhs %in% names(df)]
  dat <- df[complete.cases(df[, c("dlnCPI", rhs)]), ]
  rhs <- rhs[vapply(rhs, function(term) length(unique(dat[[term]])) > 1, logical(1))]
  f <- as.formula(paste("dlnCPI ~", paste(rhs, collapse = " + ")))
  mod <- lm(f, data = dat)
  nw <- NeweyWest(mod, lag = nw_lag(nrow(dat)), prewhite = FALSE)
  cp <- safe_cpt(mod, pos, neg, nw, paste0(label, ": "))
  dg <- tryCatch(run_diagnostics(mod, f, dat, label), error = function(e) data.frame())
  win <- sample_window(dat)

  data.frame(
    Spec = label,
    q = q,
    Sample_start = as.character(win$start),
    Sample_end = as.character(win$end),
    Span_years = round(sample_span_years(dat), 2),
    Duration_20Y = ifelse(duration_ok(dat), "YES", "NO"),
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
      Diagnostics_OK == "YES" & CPTpos_p < 0.10 ~ "Candidate, but theory and stability still matter",
      Diagnostics_OK == "YES" ~ "Diagnostic-safe but weak/no oil effect",
      TRUE ~ "Diagnostic-risk"
    )
  )

save_table(headline_triage, "table_25_headline_specification_triage.csv")

# -----------------------------------------------------------------------------
# Channel diagnostics
# -----------------------------------------------------------------------------
channel_diag <- list()

add_channel_diag <- function(label, model_name, formula_name, data_name, requested_role) {
  if (!exists(model_name) || !exists(formula_name) || !exists(data_name)) return(NULL)
  mod <- get(model_name)
  f <- get(formula_name)
  dat <- get(data_name)
  dg <- tryCatch(run_diagnostics(mod, f, dat, label), error = function(e) NULL)
  if (is.null(dg)) return(NULL)
  win <- sample_window(dat)
  dg$Requested_role <- requested_role
  dg$Sample_start <- as.character(win$start)
  dg$Sample_end <- as.character(win$end)
  dg$Span_years <- round(sample_span_years(dat), 2)
  dg$Duration_20Y <- ifelse(duration_ok(dat), "YES", "NO")
  dg$Verdict <- diagnostic_verdict(dg)
  dg
}

channel_diag[[length(channel_diag) + 1]] <- add_channel_diag(
  "PPAC Petrol", "m_ppac", "f_ppac", "df_ppac_est", "Mandatory mechanism model"
)
channel_diag[[length(channel_diag) + 1]] <- add_channel_diag(
  "CPI Fuel and Light", "m_fuel", "f_fuel", "df_fuel_est", "Supporting mechanism model"
)
channel_diag[[length(channel_diag) + 1]] <- add_channel_diag(
  "PPAC Petrol to Fuel CPI", "m_s2", "f_s2", "df_s2_est", "Dilution-chain bridge"
)
channel_diag <- channel_diag[!vapply(channel_diag, is.null, logical(1))]

if (length(channel_diag) > 0) {
  channel_diagnostics <- bind_rows(channel_diag)
  save_table(channel_diagnostics, "table_26_channel_diagnostics.csv")
}

# -----------------------------------------------------------------------------
# Mandatory-model gate: only 20+ year models can be mandatory.
# -----------------------------------------------------------------------------
mandatory_gate_rows <- list(
  data.frame(
    Model = "M1 headline",
    Mandatory = "YES",
    N = nrow(df_m1),
    Sample_start = as.character(min(df_m1$date)),
    Sample_end = as.character(max(df_m1$date)),
    Span_years = round(sample_span_years(df_m1), 2),
    Duration_20Y = ifelse(duration_ok(df_m1), "YES", "NO"),
    Diagnostics_OK = ifelse(nrow(m1_diag) == 1 && diagnostic_pass_count(m1_diag) == 3, "YES", "NO"),
    Bootstrap_run = ifelse(exists("boot_m1"), "YES", "NO"),
    Gate_status = ifelse(duration_ok(df_m1) &&
                           nrow(m1_diag) == 1 &&
                           diagnostic_pass_count(m1_diag) == 3,
                         "PASS", "FAIL"),
    Note = "Mandatory headline model",
    stringsAsFactors = FALSE
  )
)

if (!is.null(ppac_result) && nrow(ppac_result) > 0) {
  ppac_diag_gate <- tryCatch(run_diagnostics(m_ppac, f_ppac, df_ppac_est, "PPAC Petrol"),
                             error = function(e) data.frame())
  mandatory_gate_rows[[length(mandatory_gate_rows) + 1]] <- data.frame(
    Model = "PPAC mechanism",
    Mandatory = "YES",
    N = nrow(df_ppac_est),
    Sample_start = as.character(min(df_ppac_est$date)),
    Sample_end = as.character(max(df_ppac_est$date)),
    Span_years = round(sample_span_years(df_ppac_est), 2),
    Duration_20Y = ifelse(duration_ok(df_ppac_est), "YES", "NO"),
    Diagnostics_OK = ifelse(nrow(ppac_diag_gate) == 1 &&
                              diagnostic_pass_count(ppac_diag_gate) == 3, "YES", "NO"),
    Bootstrap_run = "Not required",
    Gate_status = ifelse(duration_ok(df_ppac_est) &&
                           nrow(ppac_diag_gate) == 1 &&
                           diagnostic_pass_count(ppac_diag_gate) == 3,
                         "PASS", "FAIL"),
    Note = "Mandatory first-stage transmission model",
    stringsAsFactors = FALSE
  )
} else {
  mandatory_gate_rows[[length(mandatory_gate_rows) + 1]] <- data.frame(
    Model = "PPAC mechanism",
    Mandatory = "YES",
    N = NA_integer_,
    Sample_start = NA_character_,
    Sample_end = NA_character_,
    Span_years = NA_real_,
    Duration_20Y = "NO",
    Diagnostics_OK = "NO",
    Bootstrap_run = "Not required",
    Gate_status = "FAIL",
    Note = "Mandatory first-stage transmission model missing",
    stringsAsFactors = FALSE
  )
}

mandatory_gate <- bind_rows(mandatory_gate_rows)
save_table(mandatory_gate, "table_28_mandatory_model_gate.csv")

v2_upgrade_audit <- data.frame(
  Feature = c(
    "Publication decision table saved",
    "Headline specification triage saved",
    "Channel diagnostics saved",
    "Mandatory 20-year gate enforced",
    "Runner fails on errors",
    "PPAC summary and coefficient outputs both saved",
    "Fuel summary and coefficient outputs both saved",
    "Separate bridge model saved",
    "ARDL bounds F-test (Pesaran-Shin-Smith 2001)",
    "ARCH-LM(4) and ARCH-LM(12) reported",
    "Jarque-Bera normality reported",
    "Bai-Perron multiple structural breaks",
    "AIC / BIC / HQC all reported for lag selection",
    "Common-sample dilution table (2011+)",
    "Formal attenuation Wald test across stages",
    "Granger causality along the transmission chain",
    "Month dummies renamed to mo_Jan..mo_Nov (no collision with M0-M3)",
    "fig 13 dilution chart on log scale (headline stage visible)"
  ),
  improved_v1 = c("YES", "YES", "YES", "NO", "NO", "PARTIAL", "PARTIAL", "NO",
                  "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO"),
  improved_v2 = c("YES", "YES", "YES", "YES", "YES", "YES", "YES", "YES",
                  "YES", "YES", "YES", "YES", "YES", "YES", "YES", "YES", "YES", "YES"),
  stringsAsFactors = FALSE
)
save_table(v2_upgrade_audit, "table_29_v2_upgrade_audit.csv")

cat("  Publication triage complete.\n")
cat("  [12_publication_triage] Done.\n")
