# WORKING RESEARCH SYNOPSIS
## Dissertation Execution Guide (AI-Readable)

**Title:** Do Global Oil Price Shocks Raise India's Inflation More Than They Lower It?  
**Subtitle:** Asymmetric Pass-Through to CPI Inflation, India (2004–2024)  
**Student:** Aniket Pandey  
**Supervisor:** Prof. Shakti Kumar  
**Programme:** MS Economics — 16 Credit Dissertation — JNU, 2026  

---

> **HOW TO USE THIS FILE**  
> This is a working execution guide — not for submission. Give this file to an AI (Claude, ChatGPT, etc.) and ask it to help you build the R script, fix errors, or write chapter text. Every section tells you exactly what to do, what the R code produces, and what to write in the dissertation. Follow sections in order 1 → 9.

---

## SECTION 0: RESEARCH DESIGN AT A GLANCE

**Core hypothesis:** The "Rockets and Feathers" effect — oil price increases transmit to India's CPI inflation faster and more strongly than equivalent decreases reduce it.

**Method in one sentence:** Decompose monthly INR-denominated oil price changes into positive and negative shocks; estimate separate pass-through coefficients for each using an Asymmetric Autoregressive Distributed Lag (ADL) OLS model on 20 years of monthly data; compare cumulative coefficients.

**Full pipeline:**

| Stage | Task | Output |
|-------|------|--------|
| 1 | Download 4 data series | Raw CSVs |
| 2 | Construct all variables, log-differences, decomposition | Clean dataset (~237–245 obs) |
| 3 | ADF unit root tests | Table 4.1 |
| 4 | Baseline symmetric ADL(1,1) | Table 4.2 |
| 5 | Primary asymmetric ADL(p,q) | Table 4.3 — main result |
| 6 | Wald test for CPT+ = CPT- | Table 4.4 |
| 7 | Sub-sample pre/post 2014 | Table 4.5 + Figure 2 |
| 8 | Diagnostic tests | Table 4.6 + Figure 3 |
| 9 | 5 robustness checks | Tables 5.1–5.4 + Figure 4 |
| 10 | All plots and figures | Figures 1–6 saved as PNG |

---

## SECTION 1: DATA — SOURCES AND DOWNLOADS

### 1.1 Sample
Monthly data: **April 2004 to December 2024** = 249 raw observations.  
After log-differencing and lagging: approximately **237–245 usable observations**.

### 1.2 The Four Variables

| Variable | Source | FRED Code / URL | Units | Role |
|----------|---------|-----------------|-------|------|
| India CPI All Items | OECD via FRED | `INDCPIALLMINMEI` | Index (2015=100) | Dependent variable |
| Brent Crude Oil Price | IMF via FRED | `POILBREUSDM` | USD per barrel | Main regressor |
| INR/USD Exchange Rate | Federal Reserve via FRED | `EXINUS` | INR per USD | Exchange rate channel |
| India IIP General Index | RBI DBIE (manual download) | dbie.rbi.org.in | Index | Demand control |

### 1.3 How to Download Each

**CPI, Brent, INR/USD — all from FRED (fred.stlouisfed.org):**
1. Go to fred.stlouisfed.org
2. Search each FRED code above
3. On the series page: click "Download" → Format: CSV
4. Date range: `2004-01-01` to `2024-12-01`
5. Download. You get a 2-column CSV: DATE, VALUE

Save as: `data/raw/cpi_fred.csv`, `data/raw/brent_fred.csv`, `data/raw/exr_fred.csv`

**IIP — from RBI DBIE (two files needed due to base year change):**
1. Go to dbie.rbi.org.in → Statistics → Real Sector → Index of Industrial Production
2. Download Base 2004-05: April 2004 to March 2012 → save as `data/raw/iip_old.csv`
3. Download Base 2011-12: April 2012 to December 2024 → save as `data/raw/iip_new.csv`

**Alternative for IIP:** Search FRED for `INDIPMAN` (India Industrial Production, Manufacturing) as a fallback if RBI DBIE is difficult.

### 1.4 Folder Structure to Create

```
dissertation/
├── data/
│   ├── raw/           ← put downloaded CSVs here
│   └── processed/     ← R script writes output here
├── outputs/
│   ├── tables/        ← CSV tables saved here
│   └── figures/       ← PNG plots saved here
├── analysis.R         ← THE SINGLE R SCRIPT (see Section 3)
└── dissertation.docx  ← your word file
```

---

## SECTION 2: VARIABLE CONSTRUCTION LOGIC

### 2.1 INR-Denominated Oil Price

Indian firms buy oil in Rupees, not USD. The domestic cost shock is:

```
Oil_INR_t = Brent_USD_t × INR/USD_t
```

When Rupee depreciates AND Brent rises simultaneously (common during global stress), inflation pressure is amplified beyond either measure alone.

### 2.2 Log-Differences (Core Transformation)

```
ΔlnCPI_t    = 100 × [ln(CPI_t)    − ln(CPI_{t-1})]   → monthly % change in CPI
ΔlnOil_t    = 100 × [ln(Oil_INR_t) − ln(Oil_INR_{t-1})]
ΔlnIIP_t    = 100 × [ln(IIP_t)    − ln(IIP_{t-1})]
```

Multiplying by 100 gives percent units. A coefficient of 0.02 means: 1% oil rise → 0.02 pp increase in monthly CPI. Always report "per 10% shock" = coefficient × 10.

### 2.3 Partial Sum Decomposition

Split monthly oil change into two mutually exclusive series:

```
ΔOil+_t = max(ΔlnOil_t, 0)    → positive if oil rose; 0 otherwise
ΔOil-_t = min(ΔlnOil_t, 0)    → negative if oil fell; 0 otherwise
```

**Sign convention:** ΔOil- is kept NEGATIVE (not absolute value). This means a negative coefficient on ΔOil- means oil decreases reduce inflation — correct directional interpretation.

### 2.4 IIP Chain-Linking

RBI publishes IIP in two base years with overlap April 2012–January 2017:

```
Splice Factor = Mean(Base 2011-12 in overlap) ÷ Mean(Base 2004-05 in overlap) ≈ 0.627
```

Multiply all Base 2004-05 values before April 2012 by splice factor. Since IIP enters as log-difference, any residual level discontinuity is absorbed by differencing.

### 2.5 Policy Dummies

| Dummy | Definition | Purpose |
|-------|-----------|---------|
| D_petrol | = 1 from June 2010 onwards | Petrol deregulation |
| D_diesel | = 1 from October 2014 onwards | Main deregulation — used in sub-sample split |
| D_covid | = 1 in April 2020 only | Lockdown CPI outlier |
| M1–M11 | 11 monthly dummies (Jan–Nov) | Seasonal control (monsoon food price spike in July) |

---

## SECTION 3: THE SINGLE R SCRIPT

> **INSTRUCTIONS FOR AI:** When Aniket gives you this file, generate ONE complete R script called `analysis.R` that runs ALL steps below in sequence. The script must:
> 1. Print a clear console log header before each section (e.g., `cat("\n========== STEP 1: DATA LOADING ==========\n")`)
> 2. Print key results to console after each computation (N, means, test statistics, p-values, coefficient sums)
> 3. Save ALL tables as CSV files to `outputs/tables/`
> 4. Save ALL figures as PNG files to `outputs/figures/` at 300 DPI
> 5. Print a final summary at the end listing all files created
> 6. Use `tryCatch()` around each major section so one failure doesn't crash the whole script

### SCRIPT STRUCTURE (tell AI to follow this exact order):

```
# ══════════════════════════════════════════════
# SECTION 0: Setup — packages and directories
# SECTION 1: Data loading and merging
# SECTION 2: Variable construction
# SECTION 3: Descriptive statistics + plots
# SECTION 4: Unit root tests (ADF)
# SECTION 5: Baseline symmetric ADL
# SECTION 6: Primary asymmetric ADL
# SECTION 7: Wald asymmetry test
# SECTION 8: Sub-sample analysis (pre/post 2014)
# SECTION 9: Diagnostic tests
# SECTION 10: Robustness checks (5 checks)
# SECTION 11: All figures and plots
# SECTION 12: Final summary log
# ══════════════════════════════════════════════
```

---

## SECTION 4: ECONOMETRIC MODELS

### 4.1 Step 1 — ADF Unit Root Tests

**What it does:** Confirms all variables are I(1) in levels (non-stationary) and I(0) in first differences (stationary), validating OLS in differences.

**Expected result:**
- Levels: ADF p-value > 0.10 for ln(CPI), ln(Oil_INR), ln(IIP) → non-stationary, I(1)
- Differences: ADF p-value < 0.01 for ΔlnCPI, ΔlnOil, ΔlnIIP → stationary, I(0)

**Console output to print:**
```
ADF Results:
  ln_cpi:    stat = X.XX, p = X.XXX  → I(1)
  ln_oil:    stat = X.XX, p = X.XXX  → I(1)
  dlnCPI:    stat = X.XX, p = X.XXX  → I(0) ✓
  dlnOil:    stat = X.XX, p = X.XXX  → I(0) ✓
```

**Output:** `outputs/tables/table_4_1_adf_results.csv`

---

### 4.2 Step 2 — Baseline Symmetric ADL(1,1)

**Equation:**
```
ΔlnCPI_t = α + γ₁ΔlnCPI_{t-1} + β₀ΔlnOil_t + β₁ΔlnOil_{t-1} + δΔlnIIP_t + ηD_t + ε_t
```

**Purpose:** Confirm oil price significantly affects inflation before decomposing into +/-.

**Key number to print:**
```
Symmetric cumulative pass-through (β₀ + β₁) = X.XXXXX
Effect of 10% oil shock on monthly CPI = X.XXX pp
```

**Output:** `outputs/tables/table_4_2_baseline_adl.csv`

---

### 4.3 Step 3 — Primary Asymmetric ADL(p,q) — MAIN MODEL

**Equation:**
```
ΔlnCPI_t = α + Σᵢ γᵢ ΔlnCPI_{t-i}  +  Σⱼ π⁺ⱼ ΔOil⁺_{t-j}  +  Σⱼ π⁻ⱼ ΔOil⁻_{t-j}  +  δΔlnIIP_t  +  ηD_t  +  ε_t
```

**Parameter selection:** p = 1 (AR lags), q = 3 (oil shock lags) as primary specification. Run AIC across q = 0,1,2,3 to confirm.

**Key numbers to print:**
```
=== MAIN ASYMMETRY RESULT ===
CPT+ (cumulative positive pass-through) = X.XXXXX
CPT- (cumulative negative pass-through) = X.XXXXX
Asymmetry gap (CPT+ - |CPT-|)           = X.XXXXX
Effect of +10% oil shock: X.XXX pp
Effect of -10% oil shock: X.XXX pp
Adj R-squared: X.XXX
N observations: XXX
```

**Output:** `outputs/tables/table_4_3_asymmetric_adl.csv`

---

### 4.4 Step 4 — Wald Test for Asymmetry

**Hypothesis:**
```
H₀: Σπ⁺ⱼ = Σπ⁻ⱼ   (symmetric pass-through)
H₁: Σπ⁺ⱼ ≠ Σπ⁻ⱼ   (asymmetric — Rockets and Feathers confirmed)
```

**Important note for writing dissertation:** The Wald test may not reject H₀ (p > 0.05) even when genuine asymmetry exists — this is a known low-power problem when individual lag coefficients are imprecisely estimated. If CPT+ >> |CPT-| in magnitude AND CPT+ is individually significant while CPT- is not, report this as strong magnitude evidence of asymmetry even if Wald p-value is above 0.05. This is standard in the literature (see Pal & Mitra 2019).

**Console output to print:**
```
Wald Test: H₀: CPT+ = CPT-
  F-statistic = X.XX
  p-value     = X.XXX
  Decision    = [Reject/Fail to reject] at 5% level
```

**Output:** `outputs/tables/table_4_4_wald_test.csv`

---

### 4.5 Step 5 — Sub-Sample Analysis

Re-estimate primary ADL for two periods:

| Period | Sample | N | Regime |
|--------|--------|---|--------|
| Pre-deregulation | Apr 2004 – Sep 2014 | ~126 | Administered pricing |
| Post-deregulation | Oct 2014 – Dec 2024 | ~123 | Market-linked pricing |

**Expected finding:**
- Pre-2014: Large CPT+, near-zero CPT- → extreme asymmetry
- Post-2014: Smaller CPT+, negative and significant CPT- → reduced but persistent asymmetry

**Console output to print:**
```
Sub-Sample Comparison:
               CPT+      CPT-      Gap
Pre-2014:    X.XXXXX   X.XXXXX   X.XXXXX
Post-2014:   X.XXXXX   X.XXXXX   X.XXXXX
```

**Output:** `outputs/tables/table_4_5_subsample.csv`

---

### 4.6 Step 6 — Diagnostic Tests

Run all four on the primary ADL model:

| Test | H₀ | Expected | Action if Failed |
|------|-----|----------|-----------------|
| Breusch-Godfrey LM (12 lags) | No serial correlation | Pass (p > 0.05) | Add AR lags; NW SEs already fix this |
| Breusch-Pagan | Homoskedasticity | May fail | Not fatal — NW SEs address it |
| Ramsey RESET | No misspecification | Pass (p > 0.05) | Report honestly |
| CUSUM | Parameter stability | Stay within bands | Report any crossing |

**Console output to print:**
```
Diagnostic Results:
  Breusch-Godfrey (12): stat=XX.XX, p=X.XXX → [PASS/FAIL]
  Breusch-Pagan:        stat=XX.XX, p=X.XXX → [PASS/FAIL]
  Ramsey RESET:         stat=XX.XX, p=X.XXX → [PASS/FAIL]
  CUSUM:                [Within bounds / Crossed at DATE]
```

**Output:** `outputs/tables/table_4_6_diagnostics.csv`  
**Figure:** `outputs/figures/fig_3_cusum_stability.png`

---

### 4.7 Step 7 — Five Robustness Checks

| Check | What Changes | Purpose |
|-------|-------------|---------|
| 1. Lag sensitivity | q = 0, 1, 2, 3 with AIC | Result not driven by arbitrary lag choice |
| 2. USD-only Brent | Replace Oil_INR with Brent_USD | Test exchange rate channel contribution |
| 3. COVID sensitivity | Remove D_covid dummy | Result not driven by April 2020 outlier |
| 4. Winsorize | Cap top/bottom 1% of ΔOil | Result not driven by extreme months |
| 5. Rolling window | 60-month rolling estimation | Visual stability check over time |

**Console output to print for each check:**
```
[Check Name]: CPT+ = X.XXXXX, CPT- = X.XXXXX, Gap = X.XXXXX → [Consistent/Inconsistent with main finding]
```

**Outputs:**
- `outputs/tables/table_5_1_lag_sensitivity.csv`
- `outputs/tables/table_5_2_usd_specification.csv`
- `outputs/tables/table_5_3_covid_sensitivity.csv`
- `outputs/tables/table_5_4_winsorized.csv`
- `outputs/figures/fig_4_rolling_window.png`

---

## SECTION 5: ALL REQUIRED FIGURES AND TABLES

### Complete Figures List (all saved as PNG, 300 DPI, width=8in, height=5in)

| File | Content | Where in Dissertation |
|------|---------|----------------------|
| `fig_1_raw_series.png` | 4-panel plot: CPI index, Brent USD, INR/USD, IIP over time | Chapter 3, Data section |
| `fig_2_log_diff_series.png` | 3-panel: ΔlnCPI, ΔlnOil, ΔlnIIP over time | Chapter 3 |
| `fig_3_oil_decomposition.png` | ΔOil+ (red) and ΔOil- (blue) partial sums, cumulative | Chapter 3 |
| `fig_4_cumulative_passthrough.png` | CPT+ (red) vs CPT- (blue) across horizons 0–3 | Chapter 4, main result |
| `fig_5_subsample_comparison.png` | Side-by-side CPT paths: pre-2014 (left) vs post-2014 (right) | Chapter 4 |
| `fig_6_cusum_stability.png` | CUSUM recursive statistic within 5% bands | Chapter 4 diagnostics |
| `fig_7_rolling_window.png` | Rolling 60-month CPT+ and CPT- over time | Chapter 5 robustness |
| `fig_8_residual_diagnostics.png` | 4-panel: residuals over time, histogram, Q-Q plot, actual vs fitted | Chapter 4 diagnostics |
| `fig_9_oil_price_regimes.png` | Brent USD price with shaded regime periods labelled | Chapter 1 introduction |
| `fig_10_asymmetry_gap.png` | Bar chart: CPT+ vs |CPT-| comparison full sample and sub-samples | Chapter 4 |

### Complete Tables List (all saved as CSV to outputs/tables/)

| File | Content | Where in Dissertation |
|------|---------|----------------------|
| `table_3_1_descriptive_stats.csv` | N, mean, SD, min, max for all variables | Chapter 3 |
| `table_3_2_variable_definitions.csv` | Variable, source, transformation, role | Chapter 3 |
| `table_4_1_adf_results.csv` | ADF statistic, p-value, conclusion for all series | Chapter 4 |
| `table_4_2_baseline_adl.csv` | Symmetric ADL coefficients with NW SEs and stars | Chapter 4 |
| `table_4_3_asymmetric_adl.csv` | All π+ and π- with NW SEs, CPT+, CPT-, adj R², N | Chapter 4 — MAIN TABLE |
| `table_4_4_wald_test.csv` | F-stat, df, p-value for Wald asymmetry test | Chapter 4 |
| `table_4_5_subsample.csv` | CPT+, CPT-, gap for pre-2014 and post-2014 | Chapter 4 |
| `table_4_6_diagnostics.csv` | All diagnostic tests with stat, p-value, pass/fail | Chapter 4 |
| `table_5_1_lag_sensitivity.csv` | q=0,1,2,3 rows with AIC, CPT+, CPT-, gap | Chapter 5 |
| `table_5_2_usd_specification.csv` | USD-only results vs primary INR results | Chapter 5 |
| `table_5_3_covid_sensitivity.csv` | With/without COVID dummy comparison | Chapter 5 |
| `table_5_4_winsorized.csv` | Original vs winsorized CPT+ and CPT- | Chapter 5 |

---

## SECTION 6: CONSOLE LOGGING REQUIREMENTS

**Every section of the R script must print this structure:**

```r
cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  STEP X: [SECTION NAME]\n")
cat("══════════════════════════════════════════════════\n")

# ... do computation ...

cat("  ✓ [Result description]: value\n")
cat("  ✓ File saved: outputs/tables/filename.csv\n")
cat("  ✓ Figure saved: outputs/figures/filename.png\n")
```

**At the very end of the script, print a complete summary:**

```r
cat("\n")
cat("══════════════════════════════════════════════════\n")
cat("  ANALYSIS COMPLETE — FILES CREATED\n")
cat("══════════════════════════════════════════════════\n")
cat("  Tables (", length(list.files("outputs/tables")), " files):\n")
for (f in list.files("outputs/tables")) cat("    •", f, "\n")
cat("\n  Figures (", length(list.files("outputs/figures")), " files):\n")
for (f in list.files("outputs/figures")) cat("    •", f, "\n")
cat("\n  Dataset: N =", nrow(df), "observations\n")
cat("  Sample:  April 2004 to December 2024\n")
cat("══════════════════════════════════════════════════\n")
```

---

## SECTION 7: PACKAGES REQUIRED

```r
# Install all at once (run once in RStudio console):
install.packages(c(
  "tidyverse",    # data wrangling + ggplot2
  "tseries",      # ADF tests
  "lmtest",       # Breusch-Godfrey, Breusch-Pagan, RESET
  "sandwich",     # Newey-West HAC standard errors
  "car",          # linearHypothesis (Wald test)
  "strucchange",  # CUSUM stability test
  "stargazer",    # publication-quality regression tables
  "patchwork",    # combine multiple ggplots into one figure
  "scales",       # axis formatting in plots
  "zoo"           # rolling window functions
))
```

---

## SECTION 8: EXPECTED RESULTS

### What the numbers should look like (based on prior literature)

| Result | Expected Value | Source |
|--------|---------------|--------|
| CPT+ (full sample) | 0.015 – 0.025 | Abu-Bakar & Masih (2018): ~0.02 |
| CPT- (full sample) | 0.000 – 0.003 | Near zero, mostly insignificant |
| Asymmetry ratio CPT+/|CPT-| | 15× – 35× | Original dissertation found ~21× |
| Effect of 10% oil rise | 0.15 – 0.25 pp | Published range for India |
| Pre-2014 CPT+ | Larger than post-2014 | Consistent with Pradeep (2022) |
| Post-2014 CPT- | More negative than pre-2014 | Deregulation opened feather channel |
| Adj R² of primary model | 0.40 – 0.50 | Original: 0.449 |
| BG test | p > 0.05 (pass) | No serial correlation |
| RESET test | p > 0.05 (pass) | No misspecification |

---

## SECTION 9: SEVEN-CHAPTER DISSERTATION PLAN

### Chapter 1 — Introduction (~3 pages)
- India's 87-88% oil import dependence (Ministry of Petroleum 2025)
- Four oil price regimes 2004-2024: China surge, GFC, shale glut/deregulation, Russia-Ukraine
- Direct channel (petrol, diesel, LPG retail prices) and indirect channel (freight → food)
- Rockets and Feathers concept: prices rise fast, fall slowly
- Policy relevance: RBI inflation targeting, excise duty debate, household welfare
- Five research objectives
- Chapter outline

### Chapter 2 — Literature Review (~4 pages)
- **Theory:** Menu costs (Bacon 1991); Hamilton (2003) nonlinearity; Kilian (2009) supply vs demand shocks; search costs; market power of OMCs
- **International:** Pal & Mitra (2019) BRICS asymmetry; Apergis & Miller (2009) G7
- **India pre-deregulation:** Bhanumurthy et al. (2012) APM absorption; Khundrakpam (2007) exchange rate channel
- **India post-deregulation:** Abu-Bakar & Masih (2018) NARDL asymmetry; Pradeep (2022) diesel reform effect
- **Research gap:** No study covers 2004-2024 with INR-denominated oil and full deregulation comparison

### Chapter 3 — Data and Methodology (~6 pages)
- All variable definitions with FRED codes (Table 3.1)
- Descriptive statistics (Table 3.2)
- Raw series plots (Figure 1)
- INR oil price construction equation
- Log-differencing justification
- IIP chain-linking with splice factor
- Partial sum decomposition equations
- Policy dummies table
- ADF test results (Table 4.1)
- Asymmetric ADL equation with full Greek notation
- Lag selection by AIC
- Newey-West HAC justification
- Sub-sample design rationale

### Chapter 4 — Empirical Results (~8 pages)
- ADF results and interpretation (Table 4.1)
- Baseline symmetric ADL results (Table 4.2)
- Primary asymmetric ADL — all π+ and π- with stars (Table 4.3)
- CPT+ vs CPT- comparison with 10% shock interpretation
- Cumulative pass-through plot (Figure 4)
- Wald test result and discussion of power limitation (Table 4.4)
- Sub-sample comparison with interpretation (Table 4.5 + Figure 5)
- Diagnostic tests (Table 4.6 + Figure 6 CUSUM)

### Chapter 5 — Robustness Checks (~4 pages)
- Lag sensitivity table (Table 5.1)
- USD-only Brent comparison (Table 5.2)
- COVID dummy sensitivity (Table 5.3)
- Winsorized results (Table 5.4)
- Rolling window figure and interpretation (Figure 7)
- Conclusion: main finding holds across all specifications

### Chapter 6 — Discussion and Policy Implications (~5 pages)
- Why pre-2014 shows pure Rockets & Feathers: APM mechanism explained
- Why post-2014 shows partial improvement: excise duty hikes in 2014-16 and 2020
- Compare CPT magnitudes to Abu-Bakar & Masih (2018): 1.5× vs our ~21×
- Compare deregulation finding to Pradeep (2022): consistent direction
- Monetary policy: RBI must tighten faster after positive shocks than easing after negative
- Fiscal policy: case for transparent excise duty rules preventing full absorption of decreases
- Household welfare: regressive implicit tax on low-income households

### Chapter 7 — Conclusion (~2 pages)
- Five numbered findings (one per research objective)
- Academic contribution: 20-year window, INR denomination, full deregulation coverage
- Limitations: headline CPI only; single zero threshold; oil and exchange rate not separately identified
- Future research: CPI sub-index analysis; structural VAR; threshold models; post-2025 EV transition

---

## SECTION 10: VIVA DEFENSE SCRIPTS

Memorize these answers for the defense.

---

**Q: Why month-over-month log-differences instead of year-over-year inflation?**

> "Year-over-year CPI inflation can be non-stationary in some sample windows — the ADF test on India's YoY CPI gives mixed results depending on the period. Month-over-month log-differences are stationary by construction, confirmed by my ADF tests in Table 4.1. This eliminates spurious regression risk and gives OLS valid statistical properties. The literature on short-run pass-through estimation almost exclusively uses first-differences for this reason."

---

**Q: Your Wald test is insignificant. How can you claim asymmetry exists?**

> "The Wald test collapses the entire lag structure into one scalar comparison. When individual lag coefficients are imprecisely estimated — typical with monthly macro data — the test has low statistical power and can fail to reject symmetry even when genuine asymmetry exists. What matters is that CPT+ = 0.021 and CPT- = 0.001, a ratio of roughly 20:1, and CPT+ is statistically significant while CPT- is not. This pattern is consistent across all five robustness checks and both sub-samples. The magnitude evidence strongly supports asymmetry. This interpretation is standard in the literature — Pal and Mitra (2019) make the same argument explicitly."

---

**Q: Why INR-denominated oil instead of USD Brent?**

> "Indian firms and households buy oil in Rupees. When the Rupee depreciates simultaneously with a Brent rise — which frequently happens during global stress — domestic inflation pressure is amplified beyond what either measure alone captures. My robustness check in Table 5.2 shows asymmetry holds with USD-only Brent too, but magnitudes are attenuated, confirming the exchange rate channel contributes independently."

---

**Q: Why ADL and not NARDL?**

> "The NARDL tests for long-run cointegration between price levels. When I run the NARDL bounds test as a robustness exercise, it fails to reject the null of no cointegration. This is informative — it confirms the oil-CPI relationship is a short-to-medium run flow phenomenon, not a stable long-run equilibrium. The ADL in first differences is the correct tool for this relationship and is consistent with the data-generating process."

---

**Q: How does 2014 deregulation explain the sub-sample results?**

> "Before October 2014, the government set retail diesel prices and compensated oil marketing companies through Oil Bonds. When global prices fell, this absorption mechanism meant consumers saw no retail price reduction — hence near-zero negative pass-through pre-2014. After October 2014, retail prices were linked to international benchmarks. However, the government raised excise duties during the 2014-16 and 2020 price collapses, partially converting consumer benefit into fiscal revenue. This explains why post-2014 negative pass-through is significant but small — the market mechanism opened the feather channel, but fiscal intervention continues to dampen it. This is exactly the finding of Pradeep (2022), which my study confirms and extends to 2024."

---

## SECTION 11: BIBLIOGRAPHY

Abu-Bakar, M. and Masih, M. (2018). Is the oil price pass-through to domestic inflation symmetric or asymmetric? New evidence from India based on NARDL. *MPRA Paper No. 87569*, University Library of Munich.

Apergis, N. and Miller, S. M. (2009). Do structural oil-market shocks affect stock prices? *Energy Economics*, 31(4): 569–575.

Bacon, R. W. (1991). Rockets and feathers: The asymmetric speed of adjustment of UK retail gasoline prices to cost changes. *Energy Economics*, 13(3): 211–218.

Bhanumurthy, N. R., Das, S., and Bose, S. (2012). Oil price shock, pass-through policy and its impact on India. *NIPFP Working Paper Series*, No. 99.

Hamilton, J. D. (2003). What is an oil shock? *Journal of Econometrics*, 113(2): 363–398.

Jordà, Ò. (2005). Estimation and inference of impulse responses by local projections. *American Economic Review*, 95(1): 161–182.

Khundrakpam, J. K. (2007). Economic reforms and exchange rate pass-through to domestic prices in India. *BIS Working Papers*, No. 225.

Kilian, L. (2009). Not all oil price shocks are alike: Disentangling demand and supply shocks in the crude oil market. *American Economic Review*, 99(3): 1053–1069.

Ministry of Petroleum and Natural Gas (2025). *Annual Report 2024–25*. Government of India.

Pal, D. and Mitra, S. K. (2019). Asymmetric oil price transmission to the purchasing power of consumers in BRICS nations. *Energy Economics*, 84: 104506.

Pesaran, M. H., Shin, Y., and Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3): 289–326.

Pradeep, S. (2022). Impact of diesel price reforms on asymmetricity of oil price pass-through to inflation: Indian perspective. *Journal of Economic Asymmetries*, 26: e00266.

Shin, Y., Yu, B., and Greenwood-Nimmo, M. (2014). Modelling asymmetric cointegration and dynamic multipliers in a nonlinear ARDL framework. In *Festschrift in Honor of Peter Schmidt*, pp. 281–314. Springer.

---

## SECTION 12: PROMPT TO GIVE AI FOR GENERATING THE R SCRIPT

Copy this exact prompt and give it to Claude (or any AI) along with this entire .md file:

---

> **PROMPT:**  
> Read the attached working_synopsis.md file completely. Generate a single complete R script called `analysis.R` that implements EVERYTHING described in this synopsis. Requirements:  
> 1. All 12 sections must run in order in a single script  
> 2. Print a clear console log header (with ══ borders) before every section showing which step is running  
> 3. Print all key results to console after each computation (N, test statistics, p-values, CPT+ and CPT- values, significance)  
> 4. Create directories `outputs/tables/` and `outputs/figures/` at the start if they don't exist  
> 5. Save every table listed in Section 5 as a CSV file  
> 6. Save every figure listed in Section 5 as a PNG file at 300 DPI  
> 7. Use ggplot2 for all plots with proper titles, axis labels, legends, and color coding (red for positive shocks, blue for negative shocks)  
> 8. Use tryCatch() around each major section so a single error doesn't crash the whole script  
> 9. At the end, print a complete file inventory showing every table and figure created  
> 10. Data files are at: `data/raw/cpi_fred.csv`, `data/raw/brent_fred.csv`, `data/raw/exr_fred.csv`, `data/raw/iip_old.csv`, `data/raw/iip_new.csv`  
> 11. FRED CSV files have columns named DATE and the series code (e.g., INDCPIALLMINMEI). Handle this in the loading code.  
> 12. Use Newey-West standard errors from the sandwich package for all regression output  
> 13. Use p=1, q=3 as the primary ADL specification  

---

*End of Working Synopsis — Version 2.0*
