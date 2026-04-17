# ==============================================================================
# 02_build_data.R — Official WPI chain construction and model datasets
# ==============================================================================
banner("02", "BUILD DATA")

for (f in unlist(RAW_FILES)) {
  if (!file.exists(f)) stop("Required file not found: ", f)
}

cat("  Loading official OEA WPI rows...\n")

headline_8182 <- bind_rows(
  get_row_series(RAW_FILES$wpi_8182_a, "ALL COMMODITIES"),
  get_row_series(RAW_FILES$wpi_8182_b, "ALL COMMODITIES")
) %>%
  distinct(date, .keep_all = TRUE) %>%
  arrange(date)

headline_9394 <- bind_rows(
  get_row_series(RAW_FILES$wpi_9394_a, "ALL COMMODITIES"),
  get_row_series(RAW_FILES$wpi_9394_b, "ALL COMMODITIES")
) %>%
  distinct(date, .keep_all = TRUE) %>%
  arrange(date)

headline_0405 <- bind_rows(
  get_row_series(RAW_FILES$wpi_0405_a, "ALL COMMODITIES"),
  get_row_series(RAW_FILES$wpi_0405_b, "ALL COMMODITIES")
) %>%
  distinct(date, .keep_all = TRUE) %>%
  arrange(date)

headline_1112 <- get_row_series(RAW_FILES$wpi_1112, "All commodities") %>%
  arrange(date)

fuel_9394 <- bind_rows(
  get_row_series(RAW_FILES$wpi_9394_a, "II FUEL,POWER,LIGHT & LUBRICANTS"),
  get_row_series(RAW_FILES$wpi_9394_b, "II FUEL,POWER,LIGHT & LUBRICANTS")
) %>%
  distinct(date, .keep_all = TRUE) %>%
  arrange(date)

fuel_0405 <- bind_rows(
  get_row_series(RAW_FILES$wpi_0405_a, "II   FUEL & POWER"),
  get_row_series(RAW_FILES$wpi_0405_b, "II   FUEL & POWER")
) %>%
  distinct(date, .keep_all = TRUE) %>%
  arrange(date)

fuel_1112 <- get_row_series(RAW_FILES$wpi_1112, "II FUEL & POWER") %>%
  arrange(date)

cat("  Chaining headline WPI to 2011-12 = 100...\n")

chained_headline <- bind_rows(
  headline_8182 %>%
    filter(date < as.Date("1994-04-01")) %>%
    transmute(
      date,
      raw_value,
      series = "Headline WPI",
      segment = "1981-82 base -> 2011-12",
      chained_2011 = raw_value / prod(CHAIN_FACTORS$headline)
    ),
  headline_9394 %>%
    filter(date >= as.Date("1994-04-01"), date < as.Date("2005-01-01")) %>%
    transmute(
      date,
      raw_value,
      series = "Headline WPI",
      segment = "1993-94 base -> 2011-12",
      chained_2011 = raw_value / (CHAIN_FACTORS$headline["base_9394_to_0405"] *
        CHAIN_FACTORS$headline["base_0405_to_1112"])
    ),
  headline_0405 %>%
    filter(date >= as.Date("2005-01-01"), date < as.Date("2012-04-01")) %>%
    transmute(
      date,
      raw_value,
      series = "Headline WPI",
      segment = "2004-05 base -> 2011-12",
      chained_2011 = raw_value / CHAIN_FACTORS$headline["base_0405_to_1112"]
    ),
  headline_1112 %>%
    filter(date >= as.Date("2012-04-01")) %>%
    transmute(
      date,
      raw_value,
      series = "Headline WPI",
      segment = "2011-12 base",
      chained_2011 = raw_value
    )
) %>%
  arrange(date)

cat("  Chaining fuel-and-power WPI to 2011-12 = 100...\n")

chained_fuel <- bind_rows(
  fuel_9394 %>%
    filter(date < as.Date("2005-01-01")) %>%
    transmute(
      date,
      raw_value,
      series = "Fuel & Power WPI",
      segment = "1993-94 base -> 2011-12",
      chained_2011 = raw_value / (CHAIN_FACTORS$fuel["base_9394_to_0405"] *
        CHAIN_FACTORS$fuel["base_0405_to_1112"])
    ),
  fuel_0405 %>%
    filter(date >= as.Date("2005-01-01"), date < as.Date("2012-04-01")) %>%
    transmute(
      date,
      raw_value,
      series = "Fuel & Power WPI",
      segment = "2004-05 base -> 2011-12",
      chained_2011 = raw_value / CHAIN_FACTORS$fuel["base_0405_to_1112"]
    ),
  fuel_1112 %>%
    filter(date >= as.Date("2012-04-01")) %>%
    transmute(
      date,
      raw_value,
      series = "Fuel & Power WPI",
      segment = "2011-12 base",
      chained_2011 = raw_value
    )
) %>%
  arrange(date)

brent_raw <- parse_world_bank_brent(RAW_FILES$brent)
exr_raw <- load_exr_series(RAW_FILES$exr)

prepare_short_run_data <- function(chained_df, dep_label) {
  chained_df %>%
    transmute(date, dep = chained_2011) %>%
    inner_join(brent_raw, by = "date") %>%
    inner_join(exr_raw, by = "date") %>%
    arrange(date) %>%
    mutate(
      dep_label = dep_label,
      month = factor(format(date, "%m")),
      oil_inr = brent_usd * exr,
      ln_dep = log(dep),
      ln_oil = log(oil_inr),
      ln_brent = log(brent_usd),
      ln_exr = log(exr),
      dln_dep = c(NA, 100 * diff(ln_dep)),
      dln_oil = c(NA, 100 * diff(ln_oil)),
      dln_brent = c(NA, 100 * diff(ln_brent)),
      dln_exr = c(NA, 100 * diff(ln_exr)),
      dln_oil_pos = pmax(dln_oil, 0),
      dln_oil_neg = pmin(dln_oil, 0),
      dln_brent_pos = pmax(dln_brent, 0),
      dln_brent_neg = pmin(dln_brent, 0),
      d_reform = as.integer(date >= as.Date("2014-10-01")),
      d_covid = as.integer(date >= as.Date("2020-04-01") & date <= as.Date("2020-09-01"))
    ) %>%
    {df <- .
      for (k in 1:MAIN_AR_LAGS) df[[paste0("dln_dep_L", k)]] <- dplyr::lag(df$dln_dep, k)
      for (k in 0:MAIN_OIL_LAGS) {
        df[[paste0("dln_oil_pos_L", k)]] <- dplyr::lag(df$dln_oil_pos, k)
        df[[paste0("dln_oil_neg_L", k)]] <- dplyr::lag(df$dln_oil_neg, k)
        df[[paste0("dln_brent_pos_L", k)]] <- dplyr::lag(df$dln_brent_pos, k)
        df[[paste0("dln_brent_neg_L", k)]] <- dplyr::lag(df$dln_brent_neg, k)
      }
      df$dln_exr_L1 <- dplyr::lag(df$dln_exr, 1)
      df
    }
}

headline_model_data <- prepare_short_run_data(chained_headline, "Headline WPI")
fuel_model_data <- prepare_short_run_data(chained_fuel, "Fuel & Power WPI")

data_spans <- data.frame(
  Series = c(
    "Headline WPI chained (2011 base)",
    "Fuel & Power WPI chained (2011 base)",
    "Brent USD",
    "INR/USD exchange rate",
    "Headline model data",
    "Fuel model data"
  ),
  Start = c(
    as.character(min(chained_headline$date)),
    as.character(min(chained_fuel$date)),
    as.character(min(brent_raw$date)),
    as.character(min(exr_raw$date)),
    as.character(min(headline_model_data$date)),
    as.character(min(fuel_model_data$date))
  ),
  End = c(
    as.character(max(chained_headline$date)),
    as.character(max(chained_fuel$date)),
    as.character(max(brent_raw$date)),
    as.character(max(exr_raw$date)),
    as.character(max(headline_model_data$date)),
    as.character(max(fuel_model_data$date))
  ),
  N = c(
    nrow(chained_headline),
    nrow(chained_fuel),
    nrow(brent_raw),
    nrow(exr_raw),
    nrow(headline_model_data),
    nrow(fuel_model_data)
  ),
  Span_years = round(c(
    sample_span_years(chained_headline$date),
    sample_span_years(chained_fuel$date),
    sample_span_years(brent_raw$date),
    sample_span_years(exr_raw$date),
    sample_span_years(headline_model_data$date),
    sample_span_years(fuel_model_data$date)
  ), 2),
  stringsAsFactors = FALSE
)

chain_factors_tbl <- data.frame(
  Series = c(
    "Headline WPI 1981-82 -> 1993-94",
    "Headline WPI 1993-94 -> 2004-05",
    "Headline WPI 2004-05 -> 2011-12",
    "Fuel & Power WPI 1993-94 -> 2004-05",
    "Fuel & Power WPI 2004-05 -> 2011-12"
  ),
  Linking_factor = c(
    CHAIN_FACTORS$headline["base_8182_to_9394"],
    CHAIN_FACTORS$headline["base_9394_to_0405"],
    CHAIN_FACTORS$headline["base_0405_to_1112"],
    CHAIN_FACTORS$fuel["base_9394_to_0405"],
    CHAIN_FACTORS$fuel["base_0405_to_1112"]
  ),
  Conversion_rule = "Convert old-base index to 2011-12 by dividing through the official factor chain",
  stringsAsFactors = FALSE
)

splice_check <- bind_rows(
  chained_headline %>%
    filter(date %in% as.Date(c("1994-03-01", "1994-04-01", "2004-12-01", "2005-01-01", "2012-03-01", "2012-04-01"))) %>%
    transmute(Series = "Headline WPI", date, segment, raw_value, chained_2011),
  chained_fuel %>%
    filter(date %in% as.Date(c("2004-12-01", "2005-01-01", "2012-03-01", "2012-04-01"))) %>%
    transmute(Series = "Fuel & Power WPI", date, segment, raw_value, chained_2011)
)

write.csv(chained_headline, file.path(PATHS$processed, "wpi_headline_chained_2011.csv"), row.names = FALSE)
write.csv(chained_fuel, file.path(PATHS$processed, "wpi_fuel_chained_2011.csv"), row.names = FALSE)
write.csv(headline_model_data, file.path(PATHS$processed, "wpi_headline_model_data.csv"), row.names = FALSE)
write.csv(fuel_model_data, file.path(PATHS$processed, "wpi_fuel_model_data.csv"), row.names = FALSE)

save_table(data_spans, "table_01_data_spans.csv")
save_table(chain_factors_tbl, "table_02_chain_factors.csv")
save_table(splice_check, "table_03_splice_checks.csv")

cat(sprintf("  Headline chain: %s to %s (%d obs)\n",
  min(chained_headline$date), max(chained_headline$date), nrow(chained_headline)))
cat(sprintf("  Fuel chain:     %s to %s (%d obs)\n",
  min(chained_fuel$date), max(chained_fuel$date), nrow(chained_fuel)))
cat(sprintf("  Model sample end constrained by EXR availability: %s\n",
  max(headline_model_data$date)))
cat("  [02_build_data] Done.\n")
