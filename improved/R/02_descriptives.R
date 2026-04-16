# ══════════════════════════════════════════════════════════════════════════════
# 02_descriptives.R — Descriptive statistics, variable definitions, Figs 1-3
# ══════════════════════════════════════════════════════════════════════════════
banner("2", "DESCRIPTIVE STATISTICS AND PLOTS")

# ── Table 1: Descriptive statistics ──────────────────────────────────────────
desc_vars <- c("cpi", "brent_usd", "exr", "iip", "oil_inr",
               "dlnCPI", "dlnOil", "dlnBrent", "dlnEXR", "dlnIIP",
               "dlnOil_pos", "dlnOil_neg", "dlnBrent_pos", "dlnBrent_neg")
desc_labels <- c("CPI Index", "Brent USD/bbl", "INR/USD", "IIP Index", "Oil INR",
                 "dlnCPI (%)", "dlnOil_INR (%)", "dlnBrent (%)", "dlnEXR (%)", "dlnIIP (%)",
                 "dOil+ INR (%)", "dOil- INR (%)", "dBrent+ (%)", "dBrent- (%)")

desc_stats <- data.frame(
  Variable = desc_labels,
  N    = sapply(desc_vars, function(v) sum(!is.na(df[[v]]))),
  Mean = sapply(desc_vars, function(v) round(mean(df[[v]], na.rm = TRUE), 4)),
  SD   = sapply(desc_vars, function(v) round(sd(df[[v]], na.rm = TRUE), 4)),
  Min  = sapply(desc_vars, function(v) round(min(df[[v]], na.rm = TRUE), 4)),
  Max  = sapply(desc_vars, function(v) round(max(df[[v]], na.rm = TRUE), 4)),
  Skew = sapply(desc_vars, function(v) {
    x <- na.omit(df[[v]]); n <- length(x)
    round((n / ((n-1)*(n-2))) * sum(((x - mean(x))/sd(x))^3), 4)
  }),
  Kurtosis = sapply(desc_vars, function(v) {
    x <- na.omit(df[[v]]); n <- length(x)
    round(((n*(n+1)) / ((n-1)*(n-2)*(n-3))) * sum(((x - mean(x))/sd(x))^4) -
          (3*(n-1)^2) / ((n-2)*(n-3)), 4)
  }),
  row.names = NULL
)
save_table(desc_stats, "table_01_descriptive_stats.csv")
print(desc_stats)

# ── Table 2: Variable definitions ────────────────────────────────────────────
var_defs <- data.frame(
  Variable = c("CPI", "Brent", "EXR", "IIP", "Oil_INR",
               "dlnCPI", "dlnOil", "dlnBrent", "dlnEXR", "dlnIIP",
               "dOil+/dBrent+", "dOil-/dBrent-", "NOPI+", "NOPI-",
               "D_petrol", "D_diesel", "D_post", "D_covid"),
  Source = c("OECD/FRED", "IMF/FRED", "Fed/FRED", "RBI DBIE", "Constructed",
             rep("Transformed", 5), rep("Mork (1989)", 2), rep("Hamilton (2003)", 2),
             rep("Policy", 4)),
  Definition = c(
    "India CPI All Groups, All India (INDCPIALLMINMEI)",
    "Brent crude spot price (POILBREUSDM)",
    "INR per USD monthly average (EXINUS)",
    "IIP General Index chain-linked across base years",
    "Brent_USD x INR/USD",
    "100 x dln(CPI)", "100 x dln(Oil_INR)", "100 x dln(Brent_USD)",
    "100 x dln(EXR)", "100 x dln(IIP)",
    "max(dlnOil, 0) / max(dlnBrent, 0)",
    "min(dlnOil, 0) / min(dlnBrent, 0)",
    "100 x max(0, lnOil_t - max_{t-12:t-1})",
    "100 x min(0, lnOil_t - min_{t-12:t-1})",
    "1 from Jun 2010 (petrol deregulation)",
    "1 from Oct 2014 (diesel deregulation)",
    "1 from Oct 2014 (post-deregulation regime)",
    "1 for Apr 2020 (COVID outlier)"),
  stringsAsFactors = FALSE
)
save_table(var_defs, "table_02_variable_definitions.csv")

# ── Figure 1: Raw series (4 panels) ─────────────────────────────────────────
p1a <- ggplot(df, aes(date, cpi)) + geom_line(color = "#1F3864", linewidth = 0.5) +
  labs(title = "CPI Index", x = NULL, y = "Index") + theme_minimal(base_size = 10)
p1b <- ggplot(df, aes(date, brent_usd)) + geom_line(color = "#C55A11", linewidth = 0.5) +
  labs(title = "Brent Crude (USD/bbl)", x = NULL, y = "USD") + theme_minimal(base_size = 10)
p1c <- ggplot(df, aes(date, exr)) + geom_line(color = "#548235", linewidth = 0.5) +
  labs(title = "INR/USD Exchange Rate", x = NULL, y = "INR per USD") + theme_minimal(base_size = 10)
p1d <- ggplot(df, aes(date, iip)) + geom_line(color = "#7030A0", linewidth = 0.5) +
  labs(title = "IIP General Index (chained)", x = NULL, y = "Index") + theme_minimal(base_size = 10)

fig1 <- (p1a | p1b) / (p1c | p1d) +
  plot_annotation(title = "Figure 1: Raw Data Series (Apr 2004 - Dec 2024)",
                  theme = theme(plot.title = element_text(face = "bold", size = 12)))
ggsave(save_figure("fig_01_raw_series.png"), fig1, width = 10, height = 6, dpi = 300)
cat("  Fig 1 saved.\n")

# ── Figure 2: Log-differenced series (4 panels) ─────────────────────────────
df_plot <- df %>% filter(!is.na(dlnCPI))

p2a <- ggplot(df_plot, aes(date, dlnCPI)) + geom_line(color = "#1F3864", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
  labs(title = "dlnCPI (monthly %)", x = NULL, y = "%") + theme_minimal(base_size = 10)
p2b <- ggplot(df_plot, aes(date, dlnOil)) + geom_line(color = "#C55A11", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
  labs(title = "dlnOil_INR (monthly %)", x = NULL, y = "%") + theme_minimal(base_size = 10)
p2c <- ggplot(df_plot, aes(date, dlnEXR)) + geom_line(color = "#548235", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
  labs(title = "dlnEXR (monthly %)", x = NULL, y = "%") + theme_minimal(base_size = 10)
p2d <- ggplot(df_plot, aes(date, dlnIIP)) + geom_line(color = "#7030A0", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
  labs(title = "dlnIIP (monthly %)", x = NULL, y = "%") + theme_minimal(base_size = 10)

fig2 <- (p2a | p2b) / (p2c | p2d) +
  plot_annotation(title = "Figure 2: Log-Differenced Series (Monthly % Changes)",
                  theme = theme(plot.title = element_text(face = "bold", size = 12)))
ggsave(save_figure("fig_02_log_diff_series.png"), fig2, width = 10, height = 6.5, dpi = 300)
cat("  Fig 2 saved.\n")

# ── Figure 3: Oil decomposition partial sums ────────────────────────────────
df_plot$cum_pos <- cumsum(ifelse(is.na(df_plot$dlnOil_pos), 0, df_plot$dlnOil_pos))
df_plot$cum_neg <- cumsum(ifelse(is.na(df_plot$dlnOil_neg), 0, df_plot$dlnOil_neg))

fig3 <- ggplot(df_plot) +
  geom_line(aes(date, cum_pos, color = "Positive (dOil+)"), linewidth = 0.6) +
  geom_line(aes(date, cum_neg, color = "Negative (dOil-)"), linewidth = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
  scale_color_manual(values = c("Positive (dOil+)" = "#C0392B", "Negative (dOil-)" = "#2980B9")) +
  labs(title = "Figure 3: Cumulative Partial Sums of Oil Price Changes (INR)",
       x = "Date", y = "Cumulative % change", color = NULL) +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom")
ggsave(save_figure("fig_03_oil_decomposition.png"), fig3, width = 8, height = 5, dpi = 300)
cat("  Fig 3 saved.\n")

cat("  [02_descriptives] Done.\n")
