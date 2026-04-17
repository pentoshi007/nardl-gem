# ==============================================================================
# 04_descriptives.R — Descriptive statistics and variable definitions
# ==============================================================================
banner("04", "DESCRIPTIVE STATISTICS")

# ── Table 01: Summary statistics ─────────────────────────────────────────────
cat("  Computing descriptive statistics...\n")

desc_vars <- c("cpi", "brent_usd", "exr", "oil_inr", "iip",
               "dlnCPI", "dlnOil", "dlnBrent", "dlnEXR", "dlnIIP")
desc_labels <- c("CPI (Index)", "Brent Crude (USD/bbl)", "INR/USD Exchange Rate",
                 "Oil Price INR", "IIP (Chained Index)",
                 "dln(CPI) x100", "dln(Oil INR) x100", "dln(Brent) x100",
                 "dln(EXR) x100", "dln(IIP) x100")

desc_stats <- data.frame(
  Variable = desc_labels,
  N    = sapply(desc_vars, function(v) sum(!is.na(df[[v]]))),
  Mean = sapply(desc_vars, function(v) round(mean(df[[v]], na.rm = TRUE), 4)),
  SD   = sapply(desc_vars, function(v) round(sd(df[[v]], na.rm = TRUE), 4)),
  Min  = sapply(desc_vars, function(v) round(min(df[[v]], na.rm = TRUE), 4)),
  Q25  = sapply(desc_vars, function(v) round(quantile(df[[v]], 0.25, na.rm = TRUE), 4)),
  Median = sapply(desc_vars, function(v) round(median(df[[v]], na.rm = TRUE), 4)),
  Q75  = sapply(desc_vars, function(v) round(quantile(df[[v]], 0.75, na.rm = TRUE), 4)),
  Max  = sapply(desc_vars, function(v) round(max(df[[v]], na.rm = TRUE), 4)),
  row.names = NULL,
  stringsAsFactors = FALSE
)
save_table(desc_stats, "table_01_descriptive_stats.csv")
print(desc_stats[, c("Variable", "N", "Mean", "SD", "Min", "Max")])

# ── Table 02: Variable definitions ──────────────────────────────────────────
var_defs <- data.frame(
  Variable = c("cpi", "brent_usd", "exr", "iip", "oil_inr",
               "dlnCPI", "dlnOil", "dlnBrent", "dlnEXR", "dlnIIP",
               "dlnOil_pos", "dlnOil_neg", "dlnBrent_pos", "dlnBrent_neg",
               "nopi_pos", "nopi_neg",
               "D_petrol", "D_diesel", "D_covid", "D_post",
               "mo_Jan..mo_Nov"),
  Definition = c(
    "India CPI All Items (OECD via FRED: INDCPIALLMINMEI)",
    "Brent Crude Oil Price, USD/barrel (FRED: POILBREUSDM)",
    "INR/USD Exchange Rate, monthly avg (FRED: EXINUS)",
    "Index of Industrial Production, chain-linked (RBI DBIE)",
    "Brent x EXR: domestic-currency oil cost",
    "100 x dln(CPI): monthly CPI inflation rate",
    "100 x dln(oil_inr): monthly INR oil price change",
    "100 x dln(brent_usd): monthly USD oil price change",
    "100 x dln(exr): monthly exchange rate change",
    "100 x dln(iip): monthly industrial output growth",
    "max(dlnOil, 0): Mork positive oil shock",
    "min(dlnOil, 0): Mork negative oil shock",
    "max(dlnBrent, 0): Mork positive Brent shock",
    "min(dlnBrent, 0): Mork negative Brent shock",
    "Hamilton NOPI+: net oil price increase (12-month lookback)",
    "Hamilton NOPI-: net oil price decrease (12-month lookback)",
    "1 if date >= Jun 2010 (petrol deregulation)",
    "1 if date >= Oct 2014 (diesel deregulation)",
    "1 if date == Apr 2020 (COVID lockdown)",
    "1 if date >= Oct 2014 (post-deregulation regime)",
    "Monthly dummies (Jan-Nov; Dec = reference)"
  ),
  Source = c("FRED/OECD", "FRED/IMF", "FRED", "RBI DBIE", "Constructed",
             rep("Constructed", 11),
             rep("Policy event", 4),
             "Constructed"),
  stringsAsFactors = FALSE
)
save_table(var_defs, "table_02_variable_definitions.csv")

cat("  [04_descriptives] Done.\n")
