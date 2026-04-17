# ==============================================================================
# 05_figures.R — Publication-quality figures for WPI pipeline
# ==============================================================================
banner("05", "FIGURES")

theme_pub <- theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption  = element_text(color = "grey50", size = 8),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

# ==============================================================================
# Figure 1: Official WPI chained series (levels)
# ==============================================================================
cat("  Fig 01: WPI chained series...\n")
tryCatch({
  fig1 <- ggplot() +
    geom_line(data = chained_headline,
      aes(date, chained_2011, color = "Headline WPI"), linewidth = 0.7) +
    geom_line(data = chained_fuel,
      aes(date, chained_2011, color = "Fuel & Power WPI"), linewidth = 0.7) +
    scale_color_manual(values = c("Headline WPI" = "#0b5f7a", "Fuel & Power WPI" = "#bf4d28")) +
    scale_y_continuous(labels = scales::label_number(accuracy = 1)) +
    labs(title = "Official WPI Chains Converted to 2011-12 = 100",
         subtitle = sprintf("Headline: %s to %s (%d obs) | Fuel: %s to %s (%d obs)",
           min(chained_headline$date), max(chained_headline$date), nrow(chained_headline),
           min(chained_fuel$date), max(chained_fuel$date), nrow(chained_fuel)),
         x = NULL, y = "Index", color = NULL) +
    theme_pub + theme(legend.position = "top")
  ggsave(save_figure_path("fig_01_wpi_chained_series.png"), fig1, width = 10, height = 5.5, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 01 error: %s\n", e$message)))

# ==============================================================================
# Figure 2: Headline inflation vs oil change
# ==============================================================================
cat("  Fig 02: Headline inflation vs oil...\n")
tryCatch({
  headline_plot_data <- df_headline_main %>%
    transmute(date, Headline = dln_dep, Oil = dln_oil) %>%
    tidyr::pivot_longer(cols = c(Headline, Oil), names_to = "Series", values_to = "Value")

  fig2 <- ggplot(headline_plot_data, aes(date, Value, color = Series)) +
    geom_line(linewidth = 0.6, alpha = 0.9) +
    scale_color_manual(values = c("Headline" = "#0b5f7a", "Oil" = "#bf4d28")) +
    labs(title = "Headline WPI Monthly Inflation and INR Oil Changes",
         x = NULL, y = "Percent change, monthly log difference × 100",
         color = NULL) +
    theme_pub + theme(legend.position = "top")
  ggsave(save_figure_path("fig_02_headline_inflation_vs_oil.png"), fig2, width = 10, height = 5.5, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 02 error: %s\n", e$message)))

# ==============================================================================
# Figure 3: Oil price decomposition (Mork positive/negative)
# ==============================================================================
cat("  Fig 03: Oil decomposition...\n")
tryCatch({
  df_plot_decomp <- headline_model_data %>% filter(!is.na(dln_oil_pos))
  fig3 <- ggplot(df_plot_decomp, aes(x = date)) +
    geom_col(aes(y = dln_oil_pos), fill = "#C0392B", alpha = 0.7, width = 25) +
    geom_col(aes(y = dln_oil_neg), fill = "#2980B9", alpha = 0.7, width = 25) +
    geom_hline(yintercept = 0, linewidth = 0.5) +
    labs(title = "Mork Decomposition: INR Oil Price Changes",
         subtitle = "Red = positive shocks (oil price increases) | Blue = negative shocks (decreases)",
         x = NULL, y = "dln(Oil INR) × 100") +
    theme_pub
  ggsave(save_figure_path("fig_03_oil_decomposition.png"), fig3, width = 10, height = 5, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 03 error: %s\n", e$message)))

# ==============================================================================
# Figure 4: Cumulative pass-through comparison
# ==============================================================================
cat("  Fig 04: Cumulative pass-through...\n")
tryCatch({
  cpt_data <- data.frame(
    Model = rep(c("M1: Headline\nINR Oil", "M2: Headline\nBrent+EXR", "M3: Fuel &\nPower"), each = 2),
    Type  = rep(c("CPT+", "|CPT-|"), 3),
    Value = c(cpt_headline_main$cpt_pos, abs(cpt_headline_main$cpt_neg),
              cpt_headline_brent$cpt_pos, abs(cpt_headline_brent$cpt_neg),
              cpt_fuel_main$cpt_pos, abs(cpt_fuel_main$cpt_neg))
  )
  cpt_data$Model <- factor(cpt_data$Model, levels = unique(cpt_data$Model))

  fig4 <- ggplot(cpt_data, aes(x = Model, y = Value, fill = Type)) +
    geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
    geom_text(aes(label = sprintf("%.4f", Value)),
              position = position_dodge(width = 0.7), vjust = -0.5, size = 3.2) +
    scale_fill_manual(values = c("CPT+" = "#C0392B", "|CPT-|" = "#2980B9")) +
    labs(title = "Cumulative Pass-Through Coefficients",
         subtitle = "Sum of oil lag coefficients (L0 to L6)",
         x = NULL, y = "CPT", fill = NULL) +
    theme_pub
  ggsave(save_figure_path("fig_04_cumulative_passthrough.png"), fig4, width = 8, height = 6, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 04 error: %s\n", e$message)))

# ==============================================================================
# Figure 5: Subsample comparison (pre/post 2010)
# ==============================================================================
cat("  Fig 05: Subsample comparison...\n")
tryCatch({
  if (exists("subsample_summary") && nrow(subsample_summary) > 0) {
    sub_long <- subsample_summary %>%
      select(Model, Subsample, CPT_pos, CPT_neg) %>%
      tidyr::pivot_longer(cols = c(CPT_pos, CPT_neg), names_to = "Type", values_to = "Value") %>%
      mutate(
        Type = ifelse(Type == "CPT_pos", "CPT+", "|CPT-|"),
        Value = abs(Value),
        Label = paste0(Model, "\n", Subsample)
      )
    sub_long$Label <- factor(sub_long$Label, levels = unique(sub_long$Label))

    fig5 <- ggplot(sub_long, aes(x = Label, y = Value, fill = Type)) +
      geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
      geom_text(aes(label = sprintf("%.4f", Value)),
                position = position_dodge(width = 0.7), vjust = -0.5, size = 2.8) +
      scale_fill_manual(values = c("CPT+" = "#C0392B", "|CPT-|" = "#2980B9")) +
      labs(title = "Pre/Post Deregulation: Oil-to-WPI Pass-Through",
           subtitle = "Split at April 2010 (onset of petrol deregulation)",
           x = NULL, y = "CPT", fill = NULL) +
      theme_pub +
      theme(axis.text.x = element_text(angle = 15, hjust = 1, size = 8))
    ggsave(save_figure_path("fig_05_subsample_comparison.png"), fig5, width = 10, height = 6, dpi = 300)
  }
}, error = function(e) cat(sprintf("  Fig 05 error: %s\n", e$message)))

# ==============================================================================
# Figure 6: CUSUM stability plots
# ==============================================================================
cat("  Fig 06: CUSUM stability...\n")
tryCatch({
  png(save_figure_path("fig_06_cusum_stability.png"), width = 12, height = 10, units = "in", res = 300)
  par(mfrow = c(3, 2), mar = c(4, 4, 3, 1))

  # Headline main — Rec-CUSUM & OLS-CUSUM
  cusum_h_rec <- efp(f_headline_main, data = df_headline_main, type = "Rec-CUSUM")
  cusum_h_ols <- efp(f_headline_main, data = df_headline_main, type = "OLS-CUSUM")
  plot(cusum_h_rec, main = "Headline (INR oil): Recursive CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#0b5f7a")
  plot(cusum_h_ols, main = "Headline (INR oil): OLS-CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#0b5f7a")

  # Brent+EXR — Rec-CUSUM & OLS-CUSUM
  cusum_b_rec <- efp(f_headline_brent, data = df_headline_brent, type = "Rec-CUSUM")
  cusum_b_ols <- efp(f_headline_brent, data = df_headline_brent, type = "OLS-CUSUM")
  plot(cusum_b_rec, main = "Headline (Brent+EXR): Recursive CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#bf4d28")
  plot(cusum_b_ols, main = "Headline (Brent+EXR): OLS-CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#bf4d28")

  # Fuel — Rec-CUSUM & OLS-CUSUM
  cusum_f_rec <- efp(f_fuel_main, data = df_fuel_main, type = "Rec-CUSUM")
  cusum_f_ols <- efp(f_fuel_main, data = df_fuel_main, type = "OLS-CUSUM")
  plot(cusum_f_rec, main = "Fuel & Power: Recursive CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#8E44AD")
  plot(cusum_f_ols, main = "Fuel & Power: OLS-CUSUM",
       xlab = "Observation", ylab = "CUSUM", col = "#8E44AD")

  dev.off()
  cat("  Saved: fig_06_cusum_stability.png\n")
}, error = function(e) cat(sprintf("  Fig 06 error: %s\n", e$message)))

# ==============================================================================
# Figure 7: Residual diagnostics (Headline model)
# ==============================================================================
cat("  Fig 07: Residual diagnostics...\n")
tryCatch({
  resid_h <- residuals(m_headline_main)
  fitted_h <- fitted(m_headline_main)

  p7a <- ggplot(data.frame(x = fitted_h, y = resid_h), aes(x, y)) +
    geom_point(alpha = 0.4, size = 1.2, color = "#0b5f7a") +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_smooth(method = "loess", se = FALSE, color = "#C0392B", linewidth = 0.7) +
    labs(title = "Residuals vs Fitted", x = "Fitted", y = "Residuals") + theme_pub

  p7b <- ggplot(data.frame(r = resid_h), aes(sample = r)) +
    stat_qq(color = "#0b5f7a", size = 1.2, alpha = 0.5) +
    stat_qq_line(color = "#C0392B") +
    labs(title = "Q-Q Plot", x = "Theoretical", y = "Sample") + theme_pub

  p7c <- ggplot(data.frame(t = seq_along(resid_h), r = resid_h), aes(t, r)) +
    geom_line(color = "#0b5f7a", linewidth = 0.3) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(title = "Residuals over Time", x = "Observation", y = "Residual") + theme_pub

  p7d <- ggplot(data.frame(r = resid_h), aes(r)) +
    geom_histogram(bins = 40, fill = "#0b5f7a", alpha = 0.7, color = "white") +
    labs(title = "Residual Distribution", x = "Residual", y = "Count") + theme_pub

  fig7 <- (p7a | p7b) / (p7c | p7d) +
    plot_annotation(title = "Headline WPI ADL (INR oil) — Residual Diagnostics")
  ggsave(save_figure_path("fig_07_residual_diagnostics.png"), fig7, width = 12, height = 8, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 07 error: %s\n", e$message)))

# ==============================================================================
# Figure 8: Oil price regime timeline
# ==============================================================================
cat("  Fig 08: Oil price regimes...\n")
tryCatch({
  petrol_dereg <- as.Date("2010-06-01")
  diesel_dereg <- as.Date("2014-10-01")
  covid_start  <- as.Date("2020-04-01")

  fig8 <- ggplot(headline_model_data, aes(date, oil_inr)) +
    geom_line(color = "#0b5f7a", linewidth = 0.6) +
    geom_vline(xintercept = petrol_dereg, linetype = "dashed",
               color = "#E67E22", linewidth = 0.8) +
    geom_vline(xintercept = diesel_dereg, linetype = "dashed",
               color = "#C0392B", linewidth = 0.8) +
    geom_vline(xintercept = covid_start, linetype = "dotted",
               color = "#8E44AD", linewidth = 0.8) +
    annotate("text", x = petrol_dereg, y = max(headline_model_data$oil_inr, na.rm = TRUE) * 0.95,
             label = "Petrol\nDereg", hjust = -0.1, size = 3, color = "#E67E22") +
    annotate("text", x = diesel_dereg, y = max(headline_model_data$oil_inr, na.rm = TRUE) * 0.85,
             label = "Diesel\nDereg", hjust = -0.1, size = 3, color = "#C0392B") +
    annotate("text", x = covid_start, y = max(headline_model_data$oil_inr, na.rm = TRUE) * 0.75,
             label = "COVID", hjust = -0.1, size = 3, color = "#8E44AD") +
    labs(title = "INR-Denominated Oil Price with Policy Events",
         subtitle = sprintf("Brent × EXR, %s to %s",
           min(headline_model_data$date), max(headline_model_data$date)),
         x = NULL, y = "Brent × EXR (INR)") +
    theme_pub
  ggsave(save_figure_path("fig_08_oil_price_regimes.png"), fig8, width = 10, height = 5, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 08 error: %s\n", e$message)))

# ==============================================================================
# Figure 9: Asymmetry gap (CPT+ - |CPT-|) across models
# ==============================================================================
cat("  Fig 09: Asymmetry gap...\n")
tryCatch({
  gap_data <- data.frame(
    Model = c("Headline INR", "Headline Brent+EXR", "Fuel & Power"),
    Gap   = c(
      cpt_headline_main$cpt_pos - abs(cpt_headline_main$cpt_neg),
      cpt_headline_brent$cpt_pos - abs(cpt_headline_brent$cpt_neg),
      cpt_fuel_main$cpt_pos - abs(cpt_fuel_main$cpt_neg)
    ),
    Asym_p = c(
      cpt_headline_main$asym_test$p_value,
      cpt_headline_brent$asym_test$p_value,
      cpt_fuel_main$asym_test$p_value
    )
  )
  gap_data$label <- sprintf("gap=%.4f\np=%s", gap_data$Gap, sapply(gap_data$Asym_p, format_p))
  gap_data$Model <- factor(gap_data$Model, levels = gap_data$Model)

  fig9 <- ggplot(gap_data, aes(x = Model, y = Gap, fill = Model)) +
    geom_col(width = 0.5, alpha = 0.85) +
    geom_text(aes(label = label), vjust = -0.5, size = 3.3) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    scale_fill_manual(values = c("#0b5f7a", "#bf4d28", "#8E44AD")) +
    labs(title = "Asymmetry Gap: CPT+ minus |CPT-|",
         subtitle = "Positive = oil increases raise WPI more than decreases lower it",
         x = NULL, y = "CPT+ − |CPT−|") +
    theme_pub + theme(legend.position = "none")
  ggsave(save_figure_path("fig_09_asymmetry_gap.png"), fig9, width = 8, height = 5.5, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 09 error: %s\n", e$message)))

# ==============================================================================
# Figure 10: Zivot-Andrews structural breaks
# ==============================================================================
cat("  Fig 10: Zivot-Andrews breaks...\n")
tryCatch({
  za_file <- file.path(PATHS$tables, "table_14_zivot_andrews.csv")
  if (file.exists(za_file)) {
    za_df <- read.csv(za_file, stringsAsFactors = FALSE)
    za_df$Break_date <- as.Date(za_df$Break_date)

    fig10 <- ggplot(headline_model_data %>% filter(!is.na(ln_oil)),
                    aes(date, ln_oil)) +
      geom_line(color = "#0b5f7a", linewidth = 0.5) +
      labs(title = "Zivot-Andrews Structural Break Detection",
           subtitle = "Break dates from unit root test with intercept and trend",
           x = NULL, y = "ln(Oil INR)") +
      theme_pub

    for (i in seq_len(nrow(za_df))) {
      fig10 <- fig10 +
        geom_vline(xintercept = za_df$Break_date[i],
                   linetype = "dashed", color = "#C0392B", linewidth = 0.7) +
        annotate("text", x = za_df$Break_date[i],
                 y = max(headline_model_data$ln_oil, na.rm = TRUE) * (1 - 0.04 * i),
                 label = paste0(za_df$Variable[i], "\n", za_df$Break_date[i]),
                 hjust = -0.1, size = 2.5, color = "#C0392B")
    }
    ggsave(save_figure_path("fig_10_zivot_andrews_breaks.png"), fig10, width = 10, height = 5, dpi = 300)
  }
}, error = function(e) cat(sprintf("  Fig 10 error: %s\n", e$message)))

# ==============================================================================
# Figure 11: Bootstrap distribution
# ==============================================================================
cat("  Fig 11: Bootstrap distribution...\n")
tryCatch({
  if (exists("boot_headline") && exists("boot_fuel")) {
    boot_plot_df <- data.frame(
      Wald_F = c(boot_headline$boot_walds, boot_fuel$boot_walds),
      Model  = rep(c("Headline WPI", "Fuel & Power WPI"),
                   c(length(boot_headline$boot_walds), length(boot_fuel$boot_walds)))
    ) %>% filter(!is.na(Wald_F))

    obs_lines <- data.frame(
      Model = c("Headline WPI", "Fuel & Power WPI"),
      Obs   = c(boot_headline$obs_wald, boot_fuel$obs_wald)
    )

    fig11 <- ggplot(boot_plot_df, aes(Wald_F)) +
      geom_histogram(bins = 80, fill = "#0b5f7a", alpha = 0.6, color = "white") +
      geom_vline(data = obs_lines, aes(xintercept = Obs),
                 color = "#C0392B", linetype = "dashed", linewidth = 0.8) +
      facet_wrap(~ Model, scales = "free_x") +
      labs(title = "Bootstrap Distribution of Wald F-Statistic (H0: CPT+ = CPT−)",
           subtitle = sprintf("B = %d | Red line = observed Wald F", BOOTSTRAP_B),
           x = "Wald F", y = "Count",
           caption = sprintf("Headline boot p = %.4f | Fuel boot p = %.4f",
                             boot_headline$boot_p, boot_fuel$boot_p)) +
      theme_pub
    ggsave(save_figure_path("fig_11_bootstrap_distribution.png"), fig11, width = 10, height = 5, dpi = 300)
  }
}, error = function(e) cat(sprintf("  Fig 11 error: %s\n", e$message)))

# ==============================================================================
# Figure 12: Log-differenced series panel
# ==============================================================================
cat("  Fig 12: Log-differenced series...\n")
tryCatch({
  df_dln <- headline_model_data %>% filter(!is.na(dln_dep))

  p12a <- ggplot(df_dln, aes(date, dln_dep)) +
    geom_line(color = "#0b5f7a", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(title = "dln(WPI) ×100", x = NULL, y = "%") + theme_pub

  p12b <- ggplot(df_dln, aes(date, dln_oil)) +
    geom_line(color = "#C0392B", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(title = "dln(Oil INR) ×100", x = NULL, y = "%") + theme_pub

  p12c <- ggplot(df_dln, aes(date, dln_brent)) +
    geom_line(color = "#E67E22", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(title = "dln(Brent USD) ×100", x = NULL, y = "%") + theme_pub

  p12d <- ggplot(df_dln, aes(date, dln_exr)) +
    geom_line(color = "#27AE60", linewidth = 0.4) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(title = "dln(EXR) ×100", x = NULL, y = "%") + theme_pub

  fig12 <- (p12a | p12b) / (p12c | p12d) +
    plot_annotation(title = "Monthly Growth Rates (Log-Differenced ×100)")
  ggsave(save_figure_path("fig_12_log_diff_series.png"), fig12, width = 12, height = 8, dpi = 300)
}, error = function(e) cat(sprintf("  Fig 12 error: %s\n", e$message)))

# ── Count saved figures ──────────────────────────────────────────────────────
n_figs <- length(list.files(PATHS$figures, pattern = "\\.png$"))
cat(sprintf("\n  Total figures saved: %d\n", n_figs))
cat("  [05_figures] Done.\n")
