# ==============================================================================
# 11_figures.R — Publication-quality figures
# ==============================================================================
# All figures saved as PNG to improved-v2/outputs/figures/
# ==============================================================================
banner("11", "PUBLICATION FIGURES")

theme_pub <- theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption  = element_text(color = "grey50", size = 8),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

# ==============================================================================
# Figure 1: Raw series (levels)
# ==============================================================================
cat("  Fig 01: Raw series...\n")
tryCatch({
  p1a <- ggplot(df, aes(date, cpi)) +
    geom_line(color = "#1F3864", linewidth = 0.6) +
    labs(title = "India CPI (All Items)", x = NULL, y = "Index") + theme_pub
  p1b <- ggplot(df, aes(date, brent_usd)) +
    geom_line(color = "#C0392B", linewidth = 0.6) +
    labs(title = "Brent Crude (USD/bbl)", x = NULL, y = "USD") + theme_pub
  p1c <- ggplot(df, aes(date, exr)) +
    geom_line(color = "#27AE60", linewidth = 0.6) +
    labs(title = "INR/USD Exchange Rate", x = NULL, y = "INR per USD") + theme_pub
  p1d <- ggplot(df, aes(date, iip)) +
    geom_line(color = "#8E44AD", linewidth = 0.6) +
    labs(title = "IIP General Index (Chained)", x = NULL, y = "Index") + theme_pub

  fig1 <- (p1a | p1b) / (p1c | p1d) +
    plot_annotation(
      title = "Raw Data Series: India Oil Pass-Through Study",
      subtitle = sprintf("Monthly, %s to %s (N = %d)",
        format(STUDY_START, "%b %Y"), format(STUDY_END, "%b %Y"), nrow(df)))
  ggsave(save_figure_path("fig_01_raw_series.png"), fig1, width = 12, height = 8, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 01 error: %s\n", e$message)))

# ==============================================================================
# Figure 2: Log-differenced series
# ==============================================================================
cat("  Fig 02: Log-differenced series...\n")
tryCatch({
  df_cpi <- df %>% filter(!is.na(dlnCPI))
  df_oil <- df %>% filter(!is.na(dlnOil))
  df_brent <- df %>% filter(!is.na(dlnBrent))
  df_iip <- df %>% filter(!is.na(dlnIIP))

  p2a <- ggplot(df_cpi, aes(date, dlnCPI)) +
    geom_line(color = "#1F3864", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(title = "dln(CPI) x100", x = NULL, y = "%") + theme_pub
  p2b <- ggplot(df_oil, aes(date, dlnOil)) +
    geom_line(color = "#C0392B", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(title = "dln(Oil INR) x100", x = NULL, y = "%") + theme_pub
  p2c <- ggplot(df_brent, aes(date, dlnBrent)) +
    geom_line(color = "#E67E22", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(title = "dln(Brent USD) x100", x = NULL, y = "%") + theme_pub
  p2d <- ggplot(df_iip, aes(date, dlnIIP)) +
    geom_line(color = "#8E44AD", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(title = "dln(IIP) x100", x = NULL, y = "%") + theme_pub

  fig2 <- (p2a | p2b) / (p2c | p2d) +
    plot_annotation(title = "Monthly Growth Rates (Log-Differenced x100)")
  ggsave(save_figure_path("fig_02_log_diff_series.png"), fig2, width = 12, height = 8, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 02 error: %s\n", e$message)))

# ==============================================================================
# Figure 3: Oil price decomposition (Mork positive/negative)
# ==============================================================================
cat("  Fig 03: Oil decomposition...\n")
tryCatch({
  df_plot <- df %>% filter(!is.na(dlnOil_pos))
  fig3 <- ggplot(df_plot, aes(x = date)) +
    geom_col(aes(y = dlnOil_pos), fill = "#C0392B", alpha = 0.7, width = 25) +
    geom_col(aes(y = dlnOil_neg), fill = "#2980B9", alpha = 0.7, width = 25) +
    geom_hline(yintercept = 0, linewidth = 0.5) +
    labs(title = "Mork Decomposition: INR Oil Price Changes",
         subtitle = "Red = positive shocks | Blue = negative shocks",
         x = NULL, y = "dln(Oil INR) x100") +
    theme_pub
  ggsave(save_figure_path("fig_03_oil_decomposition.png"), fig3, width = 10, height = 5, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 03 error: %s\n", e$message)))

# ==============================================================================
# Figure 4: Cumulative pass-through comparison (M0, M1, M2)
# ==============================================================================
cat("  Fig 04: Cumulative pass-through...\n")
tryCatch({
  cpt_data <- data.frame(
    Model = rep(c("M0: Symmetric", "M1: INR Oil\n(Headline)", "M2: Brent+EXR\n(Robustness)"), each = 2),
    Type  = rep(c("CPT+", "|CPT-|"), 3),
    Value = c(cpt_sym, NA,
              cpt_m1$cpt_pos, abs(cpt_m1$cpt_neg),
              cpt_m2$cpt_pos, abs(cpt_m2$cpt_neg))
  )
  cpt_data$Model <- factor(cpt_data$Model, levels = unique(cpt_data$Model))

  fig4 <- ggplot(cpt_data %>% filter(!is.na(Value)), aes(x = Model, y = Value, fill = Type)) +
    geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
    geom_text(aes(label = sprintf("%.4f", Value)),
              position = position_dodge(width = 0.7), vjust = -0.5, size = 3.2) +
    scale_fill_manual(values = c("CPT+" = "#C0392B", "|CPT-|" = "#2980B9")) +
    labs(title = "Cumulative Pass-Through Coefficients",
         subtitle = "Sum of oil lag coefficients (L0 to L3)",
         x = NULL, y = "CPT", fill = NULL) +
    theme_pub
  ggsave(save_figure_path("fig_04_cumulative_passthrough.png"), fig4, width = 8, height = 6, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 04 error: %s\n", e$message)))

# ==============================================================================
# Figure 5: Subsample comparison (pre/post 2014)
# ==============================================================================
cat("  Fig 05: Subsample comparison...\n")
tryCatch({
  if (exists("robustness_rows") && "Regime_pre" %in% names(robustness_rows)) {
    sub_data <- bind_rows(
      robustness_rows[["Regime_pre"]],
      robustness_rows[["Regime_post"]],
      robustness_rows[["M1_baseline"]]
    )
    sub_long <- sub_data %>%
      select(Check, CPT_pos, CPT_neg) %>%
      tidyr::pivot_longer(cols = c(CPT_pos, CPT_neg), names_to = "Type", values_to = "Value") %>%
      mutate(Type = ifelse(Type == "CPT_pos", "CPT+", "CPT-"))

    fig5 <- ggplot(sub_long, aes(x = Check, y = Value, fill = Type)) +
      geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
      scale_fill_manual(values = c("CPT+" = "#C0392B", "CPT-" = "#2980B9")) +
      labs(title = "Pre/Post Diesel Deregulation (Oct 2014)",
           x = NULL, y = "CPT", fill = NULL) +
      theme_pub +
      theme(axis.text.x = element_text(angle = 15, hjust = 1))
    ggsave(save_figure_path("fig_05_subsample_comparison.png"), fig5, width = 8, height = 6, dpi = 300)
  }
}, error = function(e) cat(sprintf("  Fig 05 error: %s\n", e$message)))

# ==============================================================================
# Figure 6: CUSUM stability (M1 and M2)
# ==============================================================================
cat("  Fig 06: CUSUM stability...\n")
tryCatch({
  png(save_figure_path("fig_06_cusum_stability.png"), width = 10, height = 8, units = "in", res = 300)
  par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))

  # M1 Rec-CUSUM
  plot(cusum_m1, main = "M1 (INR Oil): Recursive CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#1F3864")
  # M1 OLS-CUSUM
  cusum_m1_ols <- efp(f_m1, data = df_m1, type = "OLS-CUSUM")
  plot(cusum_m1_ols, main = "M1 (INR Oil): OLS-CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#1F3864")
  # M2 Rec-CUSUM
  plot(cusum_m2, main = "M2 (Brent+EXR): Recursive CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#C0392B")
  # M2 OLS-CUSUM
  cusum_m2_ols <- efp(f_m2, data = df_m2, type = "OLS-CUSUM")
  plot(cusum_m2_ols, main = "M2 (Brent+EXR): OLS-CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#C0392B")

  dev.off()
}, error = function(e) cat(sprintf("  Fig 06 error: %s\n", e$message)))

# ==============================================================================
# Figure 7: Rolling-window CPT
# ==============================================================================
cat("  Fig 07: Rolling window...\n")
tryCatch({
  roll_file <- file.path(PATHS$tables, "rolling_window_data.csv")
  if (file.exists(roll_file)) {
    roll_df <- read.csv(roll_file, stringsAsFactors = FALSE)
    roll_df$date <- as.Date(roll_df$date)

    fig7 <- ggplot(roll_df, aes(x = date)) +
      geom_line(aes(y = CPT_pos, color = "CPT+"), linewidth = 0.7) +
      geom_line(aes(y = CPT_neg, color = "CPT-"), linewidth = 0.7) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      scale_color_manual(values = c("CPT+" = "#C0392B", "CPT-" = "#2980B9")) +
      labs(title = "Rolling-Window Cumulative Pass-Through (60-month)",
           subtitle = "M1 specification re-estimated on moving window",
           x = NULL, y = "CPT", color = NULL) +
      theme_pub
    ggsave(save_figure_path("fig_07_rolling_window.png"), fig7, width = 10, height = 5, dpi = 300)
  }
}, error = function(e) cat(sprintf("  Fig 07 error: %s\n", e$message)))

# ==============================================================================
# Figure 8: Residual diagnostics (M1)
# ==============================================================================
cat("  Fig 08: Residual diagnostics...\n")
tryCatch({
  resid_m1 <- residuals(m1)
  fitted_m1 <- fitted(m1)

  p8a <- ggplot(data.frame(x = fitted_m1, y = resid_m1), aes(x, y)) +
    geom_point(alpha = 0.5, size = 1.5, color = "#1F3864") +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(title = "Residuals vs Fitted", x = "Fitted", y = "Residuals") + theme_pub
  p8b <- ggplot(data.frame(r = resid_m1), aes(sample = r)) +
    stat_qq(color = "#1F3864", size = 1.5, alpha = 0.5) +
    stat_qq_line(color = "#C0392B") +
    labs(title = "Q-Q Plot", x = "Theoretical", y = "Sample") + theme_pub
  p8c <- ggplot(data.frame(t = seq_along(resid_m1), r = resid_m1), aes(t, r)) +
    geom_line(color = "#1F3864", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(title = "Residuals over Time", x = "Observation", y = "Residual") + theme_pub
  p8d <- ggplot(data.frame(r = resid_m1), aes(r)) +
    geom_histogram(bins = 30, fill = "#1F3864", alpha = 0.7, color = "white") +
    labs(title = "Residual Distribution", x = "Residual", y = "Count") + theme_pub

  fig8 <- (p8a | p8b) / (p8c | p8d) +
    plot_annotation(title = "M1 Residual Diagnostics")
  ggsave(save_figure_path("fig_08_residual_diagnostics.png"), fig8, width = 12, height = 8, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 08 error: %s\n", e$message)))

# ==============================================================================
# Figure 9: Oil price regime timeline
# ==============================================================================
cat("  Fig 09: Oil price regimes...\n")
tryCatch({
  fig9 <- ggplot(df, aes(date, oil_inr)) +
    geom_line(color = "#1F3864", linewidth = 0.6) +
    geom_vline(xintercept = DATE_PETROL_DEREG, linetype = "dashed",
               color = "#E67E22", linewidth = 0.8) +
    geom_vline(xintercept = DATE_DIESEL_DEREG, linetype = "dashed",
               color = "#C0392B", linewidth = 0.8) +
    geom_vline(xintercept = DATE_COVID_START, linetype = "dotted",
               color = "#8E44AD", linewidth = 0.8) +
    annotate("text", x = DATE_PETROL_DEREG, y = max(df$oil_inr, na.rm = TRUE) * 0.95,
             label = "Petrol\nDereg", hjust = -0.1, size = 3, color = "#E67E22") +
    annotate("text", x = DATE_DIESEL_DEREG, y = max(df$oil_inr, na.rm = TRUE) * 0.85,
             label = "Diesel\nDereg", hjust = -0.1, size = 3, color = "#C0392B") +
    annotate("text", x = DATE_COVID_START, y = max(df$oil_inr, na.rm = TRUE) * 0.75,
             label = "COVID", hjust = -0.1, size = 3, color = "#8E44AD") +
    labs(title = "INR-Denominated Oil Price with Policy Events",
         x = NULL, y = "Brent x EXR (INR)") +
    theme_pub
  ggsave(save_figure_path("fig_09_oil_price_regimes.png"), fig9, width = 10, height = 5, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 09 error: %s\n", e$message)))

# ==============================================================================
# Figure 10: Asymmetry gap (CPT+ - |CPT-|) across models
# ==============================================================================
cat("  Fig 10: Asymmetry gap...\n")
tryCatch({
  gap_data <- data.frame(
    Model = c("M1: INR Oil", "M2: Brent+EXR"),
    Gap   = c(cpt_m1$cpt_pos - abs(cpt_m1$cpt_neg),
              cpt_m2$cpt_pos - abs(cpt_m2$cpt_neg)),
    Asym_p = c(cpt_m1$asym_test$p_value, cpt_m2$asym_test$p_value)
  )

  gap_data$label <- sprintf("gap=%.4f\np=%s", gap_data$Gap, sapply(gap_data$Asym_p, format_p))

  fig10 <- ggplot(gap_data, aes(x = Model, y = Gap, fill = Model)) +
    geom_col(width = 0.5, alpha = 0.85) +
    geom_text(aes(label = label), vjust = -0.5, size = 3.5) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    scale_fill_manual(values = c("#1F3864", "#C0392B")) +
    labs(title = "Asymmetry Gap: CPT+ minus |CPT-|",
         subtitle = "Positive gap = oil increases raise CPI more than decreases lower it",
         x = NULL, y = "CPT+ - |CPT-|") +
    theme_pub + theme(legend.position = "none")
  ggsave(save_figure_path("fig_10_asymmetry_gap.png"), fig10, width = 7, height = 5, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 10 error: %s\n", e$message)))

# ==============================================================================
# Figure 11: Zivot-Andrews structural breaks
# ==============================================================================
cat("  Fig 11: Zivot-Andrews breaks...\n")
tryCatch({
  za_file <- file.path(PATHS$tables, "table_04_zivot_andrews.csv")
  if (file.exists(za_file)) {
    za_df <- read.csv(za_file, stringsAsFactors = FALSE)
    za_df$Break_date <- as.Date(za_df$Break_date)

    fig11 <- ggplot(df, aes(date, ln_oil)) +
      geom_line(color = "#1F3864", linewidth = 0.5) +
      labs(title = "Zivot-Andrews Structural Break Detection",
           subtitle = "Break dates from unit root test with intercept and trend",
           x = NULL, y = "ln(Oil INR)") +
      theme_pub

    for (i in seq_len(nrow(za_df))) {
      fig11 <- fig11 +
        geom_vline(xintercept = za_df$Break_date[i],
                   linetype = "dashed", color = "#C0392B", linewidth = 0.7) +
        annotate("text", x = za_df$Break_date[i],
                 y = max(df$ln_oil, na.rm = TRUE) * (1 - 0.05 * i),
                 label = paste0(za_df$Variable[i], "\n", za_df$Break_date[i]),
                 hjust = -0.1, size = 2.8, color = "#C0392B")
    }
    ggsave(save_figure_path("fig_11_zivot_andrews_breaks.png"), fig11, width = 10, height = 5, dpi = 300)
  }
}, error = function(e) cat(sprintf("  Fig 11 error: %s\n", e$message)))

# ==============================================================================
# Figure 12: Bootstrap distribution
# ==============================================================================
cat("  Fig 12: Bootstrap distribution...\n")
tryCatch({
  if (exists("boot_m1") && exists("boot_m2")) {
    boot_plot_df <- data.frame(
      Wald_F = c(boot_m1$boot_walds, boot_m2$boot_walds),
      Model  = rep(c("M1: INR Oil", "M2: Brent+EXR"),
                   c(length(boot_m1$boot_walds), length(boot_m2$boot_walds)))
    ) %>% filter(!is.na(Wald_F))

    obs_lines <- data.frame(
      Model = c("M1: INR Oil", "M2: Brent+EXR"),
      Obs   = c(boot_m1$obs_wald, boot_m2$obs_wald)
    )

    fig12 <- ggplot(boot_plot_df, aes(Wald_F)) +
      geom_histogram(bins = 80, fill = "#1F3864", alpha = 0.6, color = "white") +
      geom_vline(data = obs_lines, aes(xintercept = Obs),
                 color = "#C0392B", linetype = "dashed", linewidth = 0.8) +
      facet_wrap(~ Model, scales = "free_x") +
      labs(title = "Bootstrap Distribution of Wald F-Statistic",
           subtitle = sprintf("B = %d | Red line = observed Wald F", BOOTSTRAP_B),
           x = "Wald F", y = "Count",
           caption = sprintf("M1 boot p = %.4f | M2 boot p = %.4f",
                             boot_m1$boot_p, boot_m2$boot_p)) +
      theme_pub
    ggsave(save_figure_path("fig_12_bootstrap_distribution.png"), fig12, width = 10, height = 5, dpi = 300)
  }
}, error = function(e) cat(sprintf("  Fig 12 error: %s\n", e$message)))

# ==============================================================================
# Figure 13: Dilution chain
# ==============================================================================
cat("  Fig 13: Dilution chain...\n")
tryCatch({
  if (exists("dilution_tbl") && nrow(dilution_tbl) >= 2) {
    dt <- dilution_tbl %>%
      mutate(Stage_short = paste0("Stage ", seq_len(n()), "\n",
        c("Brent ->\nPPAC Petrol", "PPAC ->\nFuel & Light", "Oil ->\nHeadline CPI")[seq_len(n())]))

    fig13 <- ggplot(dt, aes(x = Stage_short)) +
      geom_col(aes(y = CPT_pos), fill = "#C0392B", alpha = 0.85, width = 0.4,
               position = position_nudge(x = -0.22)) +
      geom_col(aes(y = abs(CPT_neg)), fill = "#2980B9", alpha = 0.85, width = 0.4,
               position = position_nudge(x = 0.22)) +
      geom_text(aes(y = CPT_pos + max(CPT_pos) * 0.05,
                    label = sprintf("CPT+\n%.3f", CPT_pos)),
                position = position_nudge(x = -0.22), size = 3, color = "#C0392B") +
      geom_text(aes(y = abs(CPT_neg) + max(abs(CPT_neg)) * 0.05,
                    label = sprintf("|CPT-|\n%.3f", abs(CPT_neg))),
                position = position_nudge(x = 0.22), size = 3, color = "#2980B9") +
      labs(title = "The Dilution Hypothesis: Oil-to-CPI Pass-Through Chain",
           subtitle = "CPT estimates shrink from retail fuel to headline inflation",
           x = NULL, y = "Cumulative Pass-Through Coefficient",
           caption = "Asymmetry weakens at headline CPI due to ~70% food & services weight") +
      theme_pub
    ggsave(save_figure_path("fig_13_dilution_chain.png"), fig13, width = 10, height = 6, dpi = 300)
  }
}, error = function(e) cat(sprintf("  Fig 13 error: %s\n", e$message)))

# ── Count saved figures ──────────────────────────────────────────────────────
n_figs <- length(list.files(PATHS$figures, pattern = "\\.png$"))
cat(sprintf("\n  Total figures saved: %d\n", n_figs))
cat("  [11_figures] Done.\n")
