# ══════════════════════════════════════════════════════════════════════════════
# 08_figures.R — All remaining publication-quality figures
# ══════════════════════════════════════════════════════════════════════════════
banner("8", "REMAINING FIGURES")

# ── Figure 4: Cumulative pass-through by horizon (M2 primary) ────────────────
cat("  Fig 4: Cumulative pass-through by horizon (M2)...\n")
horizons <- 0:3
cpt_pos_cum <- cumsum(coef(m2)[paste0("dlnBrent_pos_L", horizons)])
cpt_neg_cum <- cumsum(coef(m2)[paste0("dlnBrent_neg_L", horizons)])

cpt_horizon <- data.frame(
  Horizon = rep(horizons, 2),
  CPT     = c(cpt_pos_cum, cpt_neg_cum),
  Type    = rep(c("CPT+ (Positive shocks)", "CPT- (Negative shocks)"), each = 4)
)
fig4 <- ggplot(cpt_horizon, aes(x = Horizon, y = CPT, color = Type)) +
  geom_line(linewidth = 1.2) + geom_point(size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
  scale_color_manual(values = c("CPT+ (Positive shocks)" = "#C0392B",
                                "CPT- (Negative shocks)" = "#2980B9")) +
  scale_x_continuous(breaks = 0:3) +
  labs(title = sprintf("Figure 4: Cumulative Pass-Through by Horizon (M2, ADL(%d,3))", best_p),
       subtitle = "Primary Brent+EXR specification",
       x = "Lag Horizon (months)", y = "Cumulative coefficient", color = NULL) +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom")
ggsave(save_figure("fig_04_cumulative_passthrough.png"), fig4, width = 8, height = 5, dpi = 300)

# ── Figure 5: Sub-sample comparison bar chart ────────────────────────────────
cat("  Fig 5: Sub-sample comparison...\n")
fig5_data <- data.frame(
  Period = rep(c("Pre-2014", "Post-2014"), each = 2),
  Type   = rep(c("CPT+", "|CPT-|"), 2),
  Value  = c(sub_pre14$CPT_pos, abs(sub_pre14$CPT_neg),
             sub_post14$CPT_pos, abs(sub_post14$CPT_neg))
)
fig5 <- ggplot(fig5_data, aes(x = Period, y = Value, fill = Type)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = c("CPT+" = "#C0392B", "|CPT-|" = "#2980B9")) +
  labs(title = "Figure 5: Sub-Sample Asymmetry Comparison (Brent+EXR)",
       subtitle = "Pre- vs Post-Diesel Deregulation (Oct 2014)",
       x = NULL, y = "Cumulative Pass-Through", fill = NULL) +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom")
ggsave(save_figure("fig_05_subsample_comparison.png"), fig5, width = 8, height = 5, dpi = 300)

# ── Figure 6: CUSUM stability plot (Rec-CUSUM and OLS-CUSUM side by side) ────
cat("  Fig 6: CUSUM stability...\n")
png(save_figure("fig_06_cusum_stability.png"), width = 10, height = 5, units = "in", res = 300)
par(mfrow = c(1, 2))
plot(cusum_m2, main = "Rec-CUSUM (M2 Primary)",
     xlab = "Observation", ylab = "CUSUM statistic")
cusum_ols_m2_fig <- efp(f_m2, data = df_m2, type = "OLS-CUSUM")
plot(cusum_ols_m2_fig, main = "OLS-CUSUM (M2 Primary)",
     xlab = "Observation", ylab = "CUSUM statistic")
par(mfrow = c(1, 1))
dev.off()

# ── Figure 7: Rolling window CPT (M2) ───────────────────────────────────────
cat("  Fig 7: Rolling window CPT...\n")
if (exists("roll_df") && nrow(roll_df) > 10) {
  fig7 <- ggplot(roll_df) +
    geom_line(aes(Date, CPT_pos, color = "CPT+ (Brent)"), linewidth = 0.7) +
    geom_line(aes(Date, CPT_neg, color = "CPT- (Brent)"), linewidth = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.4) +
    geom_vline(xintercept = as.Date("2014-10-01"), linetype = "dotted", color = "grey40") +
    annotate("text", x = as.Date("2014-10-01"),
             y = max(roll_df$CPT_pos, na.rm = TRUE) * 0.85,
             label = "Diesel\nDeregulation", hjust = -0.1, size = 3, color = "grey40") +
    scale_color_manual(values = c("CPT+ (Brent)" = "#C0392B", "CPT- (Brent)" = "#2980B9")) +
    labs(title = "Figure 7: Rolling 60-Month CPT (M2 Brent+EXR)",
         x = "End Date of Window", y = "Cumulative Pass-Through", color = NULL) +
    theme_minimal(base_size = 10) + theme(legend.position = "bottom")
  ggsave(save_figure("fig_07_rolling_window.png"), fig7, width = 9, height = 5, dpi = 300)
} else {
  cat("    Skipped: insufficient rolling window data.\n")
}

# ── Figure 8: Residual diagnostics (M2, 4 panels) ───────────────────────────
cat("  Fig 8: Residual diagnostics (M2)...\n")
resids_m2  <- residuals(m2)
fitted_m2  <- fitted(m2)
resid_df <- data.frame(
  Date     = df_m2$date,
  Residual = resids_m2,
  Fitted   = fitted_m2,
  Actual   = df_m2$dlnCPI
)

p8a <- ggplot(resid_df, aes(Date, Residual)) +
  geom_line(color = "#1F3864", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Residuals over Time", x = NULL, y = "Residual") + theme_minimal(base_size = 9)

p8b <- ggplot(resid_df, aes(Residual)) +
  geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "#1F3864", alpha = 0.7) +
  stat_function(fun = dnorm, args = list(mean = mean(resids_m2), sd = sd(resids_m2)),
                color = "red", linewidth = 1) +
  labs(title = "Residual Histogram", x = "Residual", y = "Density") + theme_minimal(base_size = 9)

p8c <- ggplot(resid_df, aes(sample = Residual)) +
  stat_qq(color = "#1F3864") + stat_qq_line(color = "red") +
  labs(title = "Q-Q Plot", x = "Theoretical Quantiles", y = "Sample Quantiles") + theme_minimal(base_size = 9)

p8d <- ggplot(resid_df, aes(Fitted, Actual)) +
  geom_point(color = "#1F3864", alpha = 0.5, size = 1) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  labs(title = "Actual vs Fitted", x = "Fitted", y = "Actual") + theme_minimal(base_size = 9)

fig8 <- (p8a | p8b) / (p8c | p8d) +
  plot_annotation(title = "Figure 8: Residual Diagnostics (M2 Primary)",
                  theme = theme(plot.title = element_text(face = "bold", size = 11)))
ggsave(save_figure("fig_08_residual_diagnostics.png"), fig8, width = 10, height = 7, dpi = 300)

# ── Figure 9: Oil price regimes ──────────────────────────────────────────────
cat("  Fig 9: Oil price regimes...\n")
regime_df <- data.frame(
  xmin  = as.Date(c("2004-04-01", "2008-07-01", "2014-07-01", "2020-01-01", "2022-02-01")),
  xmax  = as.Date(c("2008-06-01", "2009-02-01", "2016-01-01", "2020-12-01", "2022-12-01")),
  label = c("China Boom", "GFC Crash", "Shale Glut +\nDeregulation", "COVID", "Russia-\nUkraine"),
  fill  = c("#E74C3C", "#3498DB", "#2ECC71", "#9B59B6", "#E67E22")
)
fig9 <- ggplot(df, aes(date, brent_usd)) +
  geom_rect(data = regime_df, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = label),
            inherit.aes = FALSE, alpha = 0.15) +
  geom_line(color = "#1F3864", linewidth = 0.6) +
  scale_fill_manual(values = setNames(regime_df$fill, regime_df$label)) +
  labs(title = "Figure 9: Brent Crude Oil Price with Regime Periods",
       x = "Date", y = "USD per barrel", fill = "Regime") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom")
ggsave(save_figure("fig_09_oil_price_regimes.png"), fig9, width = 10, height = 5, dpi = 300)

# ── Figure 10: Asymmetry gap comparison (all models) ─────────────────────────
cat("  Fig 10: Asymmetry gap comparison...\n")
fig10_data <- data.frame(
  Model = c("M1: INR oil", "M2: Brent+EXR", "M3: Interaction\n(post-dereg)",
            "Sub: Pre-2014", "Sub: Post-2014"),
  CPT_pos = c(cpt_m1$cpt_pos, cpt_m2$cpt_pos, cpt_post$cpt_pos,
              sub_pre14$CPT_pos, sub_post14$CPT_pos),
  CPT_neg_abs = c(abs(cpt_m1$cpt_neg), abs(cpt_m2$cpt_neg), abs(cpt_post$cpt_neg),
                  abs(sub_pre14$CPT_neg), abs(sub_post14$CPT_neg))
)
fig10_long <- fig10_data %>%
  pivot_longer(cols = c(CPT_pos, CPT_neg_abs), names_to = "Type", values_to = "Value") %>%
  mutate(
    Type = ifelse(Type == "CPT_pos", "CPT+", "|CPT-|"),
    Model = factor(Model, levels = fig10_data$Model)
  )
fig10 <- ggplot(fig10_long, aes(x = Model, y = Value, fill = Type)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = c("CPT+" = "#C0392B", "|CPT-|" = "#2980B9")) +
  labs(title = "Figure 10: Asymmetry Gap Across Models",
       subtitle = "CPT+ vs |CPT-|: larger gap = stronger asymmetry",
       x = NULL, y = "Cumulative Pass-Through", fill = NULL) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", axis.text.x = element_text(size = 8))
ggsave(save_figure("fig_10_asymmetry_gap.png"), fig10, width = 10, height = 5.5, dpi = 300)

# ── Figure 11: Zivot-Andrews break dates visualization ──────────────────────
cat("  Fig 11: Zivot-Andrews break dates...\n")
if (exists("za_results") && is.data.frame(za_results) && nrow(za_results) > 0) {
  za_breaks <- za_results %>%
    mutate(Break_Date = as.Date(Break_Date)) %>%
    filter(!is.na(Break_Date))

  fig11 <- ggplot(df, aes(date, brent_usd)) +
    geom_line(color = "#1F3864", linewidth = 0.5, alpha = 0.6) +
    geom_vline(data = za_breaks, aes(xintercept = Break_Date, color = Variable),
               linetype = "dashed", linewidth = 0.8) +
    labs(title = "Figure 11: Zivot-Andrews Structural Break Dates",
         subtitle = "Endogenously detected break points in log-level series",
         x = "Date", y = "Brent USD (background)", color = "Series") +
    theme_minimal(base_size = 10) + theme(legend.position = "bottom")
  ggsave(save_figure("fig_11_zivot_andrews_breaks.png"), fig11, width = 9, height = 5, dpi = 300)
}

# ── Figure 12: Bootstrap distribution vs observed Wald (M2) ─────────────────
cat("  Fig 12: Bootstrap Wald distribution (M2)...\n")
if (exists("boot_m2") && length(boot_m2$boot_distribution) > 100) {
  boot_dist_df <- data.frame(Wald_F = boot_m2$boot_distribution)
  fig12 <- ggplot(boot_dist_df, aes(Wald_F)) +
    geom_histogram(aes(y = after_stat(density)), bins = 60, fill = "#2C3E50", alpha = 0.7) +
    geom_vline(xintercept = boot_m2$obs_wald, color = "#E74C3C", linewidth = 1, linetype = "dashed") +
    annotate("text", x = boot_m2$obs_wald * 1.1, y = Inf, vjust = 2,
             label = sprintf("Observed F = %.3f\nBoot p = %.4f",
                             boot_m2$obs_wald, boot_m2$boot_p),
             color = "#E74C3C", size = 3.5, hjust = 0) +
    labs(title = "Figure 12: Block Bootstrap Distribution of Wald F-statistic (M2)",
         subtitle = sprintf("B = %d, block length = %d", boot_m2$B_effective, boot_m2$block_len),
         x = "Wald F-statistic", y = "Density") +
    theme_minimal(base_size = 10)
  ggsave(save_figure("fig_12_bootstrap_distribution.png"), fig12, width = 8, height = 5, dpi = 300)
}

cat("  [08_figures] Done.\n")
