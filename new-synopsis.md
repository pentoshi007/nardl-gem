# REVISED RESEARCH SYNOPSIS
## Dissertation Execution Guide (AI-Readable)

**Title:** How Do Global Oil Price Shocks Pass Through to Inflation in India?  
**Subtitle:** Magnitude, Asymmetry, and the Exchange-Rate Channel in Monthly CPI Inflation (2004-2024)  
**Student:** Aniket Pandey  
**Supervisor:** Prof. Shakti Kumar  
**Programme:** MS Economics - 16 Credit Dissertation - JNU, 2026

---

> **HOW TO USE THIS FILE**  
> This is a working execution guide for analysis, writing, and supervision support. It is not the final submitted synopsis. Give this file to an AI and ask it to help you build the R script, audit the econometrics, improve the chapter draft, or explain the logic in plain language. The goal is not to force a flashy result. The goal is to produce a defensible MS Economics dissertation on India that uses sensible data, transparent methods, and honest inference.

---

## SECTION 0: RESEARCH DESIGN AT A GLANCE

**Core research question:**  
How strongly do global oil price shocks pass through to India's monthly CPI inflation, and is pass-through larger for oil price increases than for oil price decreases?

**Working hypothesis:**  
Positive oil shocks should raise inflation in India. Negative oil shocks may lower inflation by less, but whether this asymmetry is statistically significant is an empirical question, not a conclusion to assume in advance.

**Main contribution in one sentence:**  
Estimate short-run monthly inflation pass-through for India over April 2004 to December 2024 using an asymmetric ADL framework, then check whether the results remain credible when oil is modeled both as INR-denominated imported cost and as separate Brent and exchange-rate channels.

**Five research objectives:**
1. Measure the short-run pass-through from oil shocks to monthly CPI inflation in India.
2. Test whether positive and negative oil shocks have different cumulative effects.
3. Examine whether the exchange-rate channel materially changes the estimated pass-through.
4. Compare pass-through before and after diesel deregulation in October 2014.
5. Check whether the findings survive diagnostics and simple robustness tests.

**Non-negotiable standards for the dissertation:**
1. Never hard-code or "target" an expected result.
2. Never claim statistical significance when `p > 0.05`.
3. Distinguish clearly between economic significance and statistical significance.
4. Report that headline CPI in India is influenced heavily by food inflation, so oil effects may be muted in aggregate inflation.
5. Use HAC/Newey-West inference for all main regression tables and linear restrictions.
6. If the formal asymmetry test remains weak, position the dissertation around short-run pass-through magnitude and the exchange-rate channel, with asymmetry treated as a secondary empirical question.

**Full pipeline:**

| Stage | Task | Output |
|------|------|--------|
| 1 | Download and clean monthly macro data | Raw CSV files |
| 2 | Construct inflation, oil, exchange-rate, and activity variables | Clean analysis dataset |
| 3 | Produce descriptive statistics and plots | Chapter 3 tables and figures |
| 4 | Check stationarity with ADF tests | Table 4.1 |
| 5 | Estimate baseline symmetric ADL | Table 4.2 |
| 6 | Estimate primary asymmetric ADL on INR oil | Table 4.3 |
| 7 | Test cumulative asymmetry with HAC Wald/F tests | Table 4.4 |
| 8 | Re-estimate pre- and post-2014 | Table 4.5 |
| 9 | Run diagnostics | Table 4.6 |
| 10 | Run robustness checks, including Brent + EXR | Tables 5.1-5.4 |
| 11 | Save all figures and tables | `outputs/` directory |
| 12 | Generate a final console summary | Reproducible log |

---

## SECTION 1: DATA - SOURCES AND DOWNLOADS

### 1.1 Sample

Monthly sample: **April 2004 to December 2024**  
Raw merged sample: **249 monthly observations**  
Usable observations after differencing and lagging: typically **about 244-245** in the main model.

This sample is long enough to cover:
- the mid-2000s commodity upswing,
- the global financial crisis,
- the post-2014 diesel deregulation regime,
- the COVID shock,
- and the 2022 energy-price surge.

### 1.2 Core Variables

| Variable | Source | Code / Link | Units | Role |
|------|------|------|------|------|
| India CPI All Items | OECD via FRED | `INDCPIALLMINMEI` | Index (2015 = 100) | Dependent variable |
| Brent crude oil price | IMF via FRED | `POILBREUSDM` | USD per barrel | Global oil price |
| INR/USD exchange rate | Federal Reserve via FRED | `EXINUS` | INR per USD | Exchange-rate channel |
| India IIP general index | RBI DBIE | manual download | Index | Domestic activity control |

**Derived variables used in estimation:**
- `Oil_INR_t = Brent_USD_t x INR/USD_t`
- `dlnCPI_t`
- `dlnOil_t`
- `dlnBrent_t`
- `dlnEXR_t`
- `dlnIIP_t`

### 1.3 How to Download Each Series

**CPI, Brent, EXR from FRED**
1. Go to [FRED](https://fred.stlouisfed.org/).
2. Search the codes `INDCPIALLMINMEI`, `POILBREUSDM`, and `EXINUS`.
3. Download CSV format.
4. Keep dates broad enough to cover at least `2004-01-01` to `2024-12-01`.
5. Save as:
   - `data/raw/cpi_fred.csv`
   - `data/raw/brent_fred.csv`
   - `data/raw/exr_fred.csv`

**IIP from RBI DBIE**
1. Go to RBI DBIE and locate the IIP general index.
2. Download:
   - Base 2004-05: April 2004 to March 2012 -> `data/raw/iip_old.csv`
   - Base 2011-12: April 2012 to December 2024 -> `data/raw/iip_new.csv`
3. Keep column names unchanged if possible and clean them in R.

**Optional extension, not required for the main dissertation**
- If internet access is available, use the official MoSPI CPI API for an appendix-only `Fuel and Light` series:
  - back series: `2011-2012`
  - current series: `2013 onward`
- Treat this as a shorter appendix sample, not as a replacement for the main `2004-2024` headline CPI model.
- If the API is unavailable, skip this appendix cleanly and keep the main dissertation unchanged.

### 1.4 Folder Structure

```text
dissertationv2/
├── data/
│   ├── raw/
│   └── processed/
├── outputs/
│   ├── tables/
│   └── figures/
├── analysis.R
├── working_synopsis.md
└── new-synopsis.md
```

### 1.5 Data Handling Rules

1. The final estimation sample must stop at the shortest common period. Do not extend Brent or EXR beyond December 2024 if IIP ends there.
2. If FRED columns have different header names, rename them to a standard form in code.
3. Do not hard-code the IIP splice factor. Compute it from the overlap period in the data.
4. Save the final merged dataset to `data/processed/analysis_dataset.csv`.

---

## SECTION 2: VARIABLE CONSTRUCTION LOGIC

### 2.1 Main Oil Cost Measure for India

The imported oil cost relevant for India is:

```text
Oil_INR_t = Brent_USD_t x INR/USD_t
```

This is the main pass-through regressor because imported energy costs depend on both world oil prices and the rupee-dollar exchange rate.

### 2.2 Separate Brent and Exchange-Rate Channel

For a cleaner interpretation, also estimate a robustness model with:

```text
dlnBrent_t   = monthly percent change in Brent price
dlnEXR_t     = monthly percent change in INR/USD
```

This matters for India because oil pass-through can look weak in headline CPI if exchange-rate movements are omitted or bundled imperfectly.

### 2.3 Log-Differences Used in the Regressions

```text
dlnCPI_t   = 100 x [ln(CPI_t) - ln(CPI_{t-1})]
dlnOil_t   = 100 x [ln(Oil_INR_t) - ln(Oil_INR_{t-1})]
dlnBrent_t = 100 x [ln(Brent_t) - ln(Brent_{t-1})]
dlnEXR_t   = 100 x [ln(EXR_t) - ln(EXR_{t-1})]
dlnIIP_t   = 100 x [ln(IIP_t) - ln(IIP_{t-1})]
```

Interpretation:
- a coefficient of `0.02` means a `1%` shock raises monthly CPI inflation by `0.02` percentage points,
- a `10%` shock effect is the coefficient sum multiplied by `10`.

### 2.4 Asymmetric Decomposition

Use two mutually exclusive monthly oil shock series:

```text
dlnOil_pos_t = max(dlnOil_t, 0)
dlnOil_neg_t = min(dlnOil_t, 0)
```

For the Brent robustness model:

```text
dlnBrent_pos_t = max(dlnBrent_t, 0)
dlnBrent_neg_t = min(dlnBrent_t, 0)
```

**Important sign rule:**  
Keep the negative shock variable negative. Do not convert it to absolute value.

**Important reporting rule:**  
The effect of a `-10%` shock must be computed using the actual negative shock:

```text
Effect of -10% shock = CPT_minus x (-10)
```

This avoids the common sign mistake that makes a negative oil shock look inflationary.

### 2.5 IIP Chain-Linking

RBI changed the IIP base year. The code should:
1. Identify the overlap period between the old and new series.
2. Compute a splice factor from the overlap means.
3. Scale the old series by that factor.
4. Combine the scaled old series with the new series into one continuous IIP index.

Because the regression uses `dlnIIP`, moderate level differences after splicing are less damaging than in a level model, but the splicing should still be done carefully.

### 2.6 Controls and Dummies

| Variable | Construction | Purpose |
|------|------|------|
| `D_petrol` | `1` from June 2010 onward | Petrol deregulation shift |
| `D_diesel` | `1` from October 2014 onward | Diesel deregulation shift |
| `D_covid` | `1` in April 2020 only | Lockdown outlier control |
| `M1-M11` | January to November monthly dummies | Seasonality control |

**Why this matters for India:**  
Headline CPI is not a pure energy index. Seasonal food-price movements and policy regime changes can easily swamp the oil signal if they are ignored.

---

## SECTION 3: THE SINGLE R SCRIPT

> **INSTRUCTIONS FOR AI:**  
> Generate one complete R script called `analysis.R` that runs all sections below in sequence, prints a clean console log, saves all tables and figures, and does not overclaim any result.

### Minimum requirements for `analysis.R`

1. Use one script only.
2. Create `outputs/tables`, `outputs/figures`, and `data/processed` if missing.
3. Print a clear header before each major step.
4. Use `tryCatch()` around each major section.
5. Save all tables as CSV and all figures as PNG at 300 DPI.
6. Use Newey-West HAC covariance for:
   - coefficient tables,
   - cumulative pass-through tests,
   - asymmetry tests.
7. Use a helper such as `format_p_value()` so `p < 0.01` prints cleanly.
8. Select the AR lag order `p` by AIC over `p = 1, 2, 3, 4` using a common comparison sample.
9. After choosing `p`, re-estimate the selected model on the maximal sample implied by that lag order.
10. Never insert expected numbers by hand. Everything must come from the data.

### Recommended script structure

```text
# SECTION 0: Setup
# SECTION 1: Data loading and merging
# SECTION 2: Variable construction
# SECTION 3: Descriptive statistics and plots
# SECTION 4: Unit root tests (ADF)
# SECTION 5: Baseline symmetric ADL
# SECTION 6: Primary asymmetric ADL
# SECTION 7: Hypothesis tests for cumulative pass-through and asymmetry
# SECTION 8: Sub-sample analysis
# SECTION 9: Diagnostic tests
# SECTION 10: Robustness checks
# SECTION 11: Remaining figures
# SECTION 12: Final summary log
```

### Recommended helper functions

The AI should implement small helper functions for:
- pretty printing p-values,
- extracting HAC-robust linear restrictions,
- choosing a Newey-West lag length,
- assembling regression output tables.

This keeps the script readable without making it complicated.

---

## SECTION 4: ECONOMETRIC MODELS

### 4.1 Step 1 - ADF Unit Root Tests

Run ADF tests on:
- `ln(CPI)`
- `ln(Oil_INR)`
- `ln(EXR)`
- `ln(IIP)`
- `dlnCPI`
- `dlnOil`
- `dlnEXR`
- `dlnIIP`

**Interpretation rules:**
1. CPI, oil, and IIP are often non-stationary in levels and stationary in first differences.
2. The exchange rate may be borderline in levels. That is fine. The short-run regression still uses differenced terms.
3. If `tseries::adf.test` prints the lower bound warning, display `p < 0.01` instead of a misleading rounded value.

**Console output example:**

```text
ADF Results:
  ln(CPI)     stat = X.XXXX, p = X.XXXX  -> fail to reject unit root
  ln(Oil_INR) stat = X.XXXX, p = X.XXXX  -> fail to reject unit root
  dlnCPI      stat = X.XXXX, p = <0.01   -> stationary
  dlnOil      stat = X.XXXX, p = <0.01   -> stationary
```

**Output:** `outputs/tables/table_4_1_adf_results.csv`

---

### 4.2 Step 2 - Baseline Symmetric ADL(1,1)

Estimate:

```text
dlnCPI_t = a + g1*dlnCPI_{t-1} + b0*dlnOil_t + b1*dlnOil_{t-1}
           + d*dlnIIP_t + policy dummies + month dummies + e_t
```

**Purpose:**  
Check whether oil pass-through is economically meaningful before moving to asymmetry.

**What to report:**
- `b0`
- `b1`
- cumulative symmetric pass-through `b0 + b1`
- HAC p-value for `H0: b0 + b1 = 0`
- effect of a `+10%` oil shock on monthly CPI inflation
- adjusted `R^2` and `N`

**Output:** `outputs/tables/table_4_2_baseline_adl.csv`

---

### 4.3 Step 3 - Primary Asymmetric ADL(p,3)

Estimate the main model:

```text
dlnCPI_t = a
         + sum_i gi*dlnCPI_{t-i}
         + sum_j pi_pos_j*dlnOil_pos_{t-j}
         + sum_j pi_neg_j*dlnOil_neg_{t-j}
         + d*dlnIIP_t
         + policy dummies
         + month dummies
         + e_t
```

Use:
- `q = 3` oil lags as the primary short-run window,
- `p` selected by AIC from `1` to `4`.

**Main quantities of interest:**

```text
CPT_plus  = sum of positive oil coefficients
CPT_minus = sum of negative oil coefficients
Gap       = CPT_plus - abs(CPT_minus)
```

**Required inference:**
- HAC test for `H0: CPT_plus = 0`
- HAC test for `H0: CPT_minus = 0`
- HAC test for `H0: CPT_plus = CPT_minus`

**Report all of these:**
- coefficient table with HAC standard errors,
- `CPT_plus`,
- `CPT_minus`,
- asymmetry gap,
- effect of `+10%` shock,
- effect of `-10%` shock,
- p-values for the three cumulative restrictions,
- adjusted `R^2`,
- `N`.

**Output:** `outputs/tables/table_4_3_asymmetric_adl.csv`

---

### 4.4 Step 4 - Hypothesis Test for Asymmetry

Main null hypothesis:

```text
H0: CPT_plus = CPT_minus
H1: CPT_plus != CPT_minus
```

**Correct interpretation rules for the dissertation:**
1. If the asymmetry p-value is below `0.05`, conclude that asymmetric pass-through is statistically significant.
2. If the asymmetry p-value is above `0.05`, conclude only that point estimates suggest asymmetry, but symmetry cannot be rejected at conventional levels.
3. Do not treat a large ratio like `CPT_plus / |CPT_minus|` as proof by itself.
4. Use magnitude, sign, and robustness as supporting evidence, not as a substitute for inference.

**How to strengthen asymmetry inference without p-hacking:**
1. Keep headline CPI as the main dependent variable, but if a consistent monthly series exists, add appendix-only extensions using CPI Fuel and Light or a cleaner core CPI measure. A more directly exposed price index usually carries a stronger oil signal than headline CPI.
2. Add an appendix-only local projection exercise for horizons `0` to `6` or `0` to `12` months, following Jordà (2005), to compare dynamic responses to positive and negative oil shocks. Keep the ADL as the main model.
3. If technically feasible, report bootstrap or block-bootstrap p-values for the cumulative asymmetry restriction as a small-sample sensitivity check. Label this clearly as supplementary inference.
4. Use the Brent + EXR specification to show whether the exchange-rate channel sharpens the interpretation, but do not replace the main model only because it gives a smaller p-value.
5. Do not add break dummies, change lag orders, or swap models simply because they make the Wald p-value look better. Those are sensitivity checks, not the main identification strategy.

**Practical lesson:**  
In this dissertation, the weakest point is likely to be the formal asymmetry test. The honest way to improve it is better signal and better identification, not cosmetic changes to the regression.

**Console output example:**

```text
Wald/F Test: H0: CPT+ = CPT-
  F-statistic = X.XXXX
  p-value     = X.XXXX
  Decision    = Fail to reject H0 at 5%
```

**Output:** `outputs/tables/table_4_4_wald_test.csv`

---

### 4.5 Step 5 - Sub-Sample Analysis

Split the sample into:

| Period | Dates | Interpretation |
|------|------|------|
| Pre-deregulation | April 2004 to September 2014 | More administered pricing |
| Post-deregulation | October 2014 to December 2024 | More market-linked pricing |

Re-estimate the main asymmetric ADL on both sub-samples.

**What to expect in a realistic India study:**
- positive pass-through may remain present in both periods,
- magnitude may differ across regimes,
- negative pass-through may remain small or imprecise in headline CPI,
- do not assume the post-2014 sample must show perfect market adjustment.

**What to report:**
- `CPT_plus`
- `CPT_minus`
- asymmetry gap
- adjusted `R^2`
- `N`

**Output:** `outputs/tables/table_4_5_subsample.csv`

---

### 4.6 Step 6 - Diagnostic Tests

Run the following on the primary asymmetric ADL:

| Test | Null hypothesis | Desired outcome | Interpretation if it fails |
|------|------|------|------|
| Breusch-Godfrey LM | no serial correlation | preferably pass | AR terms may need attention, but HAC helps inference |
| Breusch-Pagan | homoskedasticity | may fail | not fatal if HAC inference is retained |
| Ramsey RESET | no functional misspecification | preferably pass | report honestly if borderline |
| CUSUM | parameter stability | preferably within bounds | instability must be discussed, not hidden |

**Output:** `outputs/tables/table_4_6_diagnostics.csv`  
**Figure:** `outputs/figures/fig_6_cusum_stability.png`

---

### 4.7 Step 7 - Five Robustness Checks

| Check | What changes | Why it matters |
|------|------|------|
| 1. Lag sensitivity | estimate the full `p = 1:4`, `q = 0:3` grid on a common sample | checks whether conclusions depend heavily on lag choices |
| 2. Brent + EXR model | replace `Oil_INR` asymmetry with `Brent` asymmetry plus `dlnEXR` controls | checks separate exchange-rate channel |
| Appendix. Fuel and Light CPI | use official MoSPI subgroup CPI on the shorter available sample | checks whether a more directly oil-exposed price index shows a stronger signal |
| 3. No COVID dummy | remove `D_covid` | checks outlier dependence |
| 4. Winsorized oil shocks | cap top and bottom 1% of oil changes | checks influence of extreme months |
| 5. Rolling window | 60-month rolling re-estimation | checks time variation and stability |

**Important reporting rule:**  
For robustness checks, report coefficients and p-values. Do not label a model "consistent" or "inconsistent" based only on whether it matches the preferred story.

**Required outputs:**
- `outputs/tables/table_5_1_lag_sensitivity.csv`
- `outputs/tables/table_5_2_brent_exr_specification.csv`
- `outputs/tables/table_a_1_fuel_light_appendix.csv` if the official MoSPI appendix runs successfully
- `outputs/tables/table_5_3_covid_sensitivity.csv`
- `outputs/tables/table_5_4_winsorized.csv`
- `outputs/figures/fig_7_rolling_window.png`

---

## SECTION 5: ALL REQUIRED FIGURES AND TABLES

### Figures

| File | Content | Suggested chapter placement |
|------|------|------|
| `fig_1_raw_series.png` | CPI, Brent, EXR, and IIP levels over time | Chapter 3 |
| `fig_2_log_diff_series.png` | `dlnCPI`, `dlnOil`, `dlnEXR`, and `dlnIIP` | Chapter 3 |
| `fig_3_oil_decomposition.png` | positive and negative oil-shock decomposition | Chapter 3 |
| `fig_4_cumulative_passthrough.png` | cumulative `CPT+` and `CPT-` over horizons | Chapter 4 |
| `fig_5_subsample_comparison.png` | pre/post-2014 cumulative pass-through comparison | Chapter 4 |
| `fig_6_cusum_stability.png` | CUSUM stability plot | Chapter 4 |
| `fig_7_rolling_window.png` | 60-month rolling `CPT+` and `CPT-` | Chapter 5 |
| `fig_8_residual_diagnostics.png` | residual time plot, histogram, QQ plot, actual vs fitted | Chapter 4 |
| `fig_9_oil_price_regimes.png` | Brent price with period labels | Chapter 1 or 3 |
| `fig_10_asymmetry_gap.png` | bar chart comparing `CPT+` and `|CPT-|` across samples | Chapter 4 |

### Tables

| File | Content | Suggested chapter placement |
|------|------|------|
| `table_3_1_descriptive_stats.csv` | descriptive statistics for levels and transformed variables | Chapter 3 |
| `table_3_2_variable_definitions.csv` | variable definitions, sources, and transformations | Chapter 3 |
| `table_4_1_adf_results.csv` | ADF statistics and conclusions | Chapter 4 |
| `table_4_2_baseline_adl.csv` | symmetric ADL results with HAC inference | Chapter 4 |
| `table_4_3_asymmetric_adl.csv` | full asymmetric ADL results, cumulative tests, model fit | Chapter 4 |
| `table_4_4_wald_test.csv` | asymmetry test summary | Chapter 4 |
| `table_4_5_subsample.csv` | pre/post-2014 comparison | Chapter 4 |
| `table_4_6_diagnostics.csv` | diagnostic test summary | Chapter 4 |
| `table_5_1_lag_sensitivity.csv` | lag sensitivity results | Chapter 5 |
| `table_5_2_brent_exr_specification.csv` | Brent + EXR robustness vs main model | Chapter 5 |
| `table_a_1_fuel_light_appendix.csv` | appendix-only Fuel and Light CPI results on shorter official sample | Appendix |
| `table_5_3_covid_sensitivity.csv` | with and without COVID dummy | Chapter 5 |
| `table_5_4_winsorized.csv` | original vs winsorized results | Chapter 5 |

---

## SECTION 6: CONSOLE LOGGING REQUIREMENTS

Each major step should print a clean block like this:

```r
cat("\n")
cat("==========================================\n")
cat("  STEP X: SECTION NAME\n")
cat("==========================================\n")
```

Then print:
- sample dates,
- number of observations,
- key coefficient sums,
- p-values,
- file save locations.

At the end, print:

```r
cat("\n")
cat("==========================================\n")
cat("  ANALYSIS COMPLETE - FILES CREATED\n")
cat("==========================================\n")
```

The final summary must include:
1. number of tables,
2. number of figures,
3. final dataset size,
4. sample dates,
5. key result summary,
6. one plain-language inference sentence.

That final inference sentence must follow this rule:
- if asymmetry is insignificant, say so directly.

---

## SECTION 7: PACKAGES REQUIRED

```r
install.packages(c(
  "tidyverse",
  "tseries",
  "lmtest",
  "sandwich",
  "car",
  "strucchange",
  "patchwork",
  "scales",
  "zoo",
  "broom"
))
```

**Notes:**
- `stargazer` is optional, not required.
- Simpler output tables as regular data frames are acceptable for this dissertation.
- Reproducibility and correct interpretation matter more than fancy table formatting.

---

## SECTION 8: EXPECTED RESULTS

This section gives realistic benchmarks for India. It does **not** give targets the code should be forced to hit.

| Item | What is generally expected in India | What counts as a credible result |
|------|------|------|
| Positive oil pass-through | should be positive | a positive and economically meaningful `CPT+` |
| Magnitude of a `+10%` oil shock | often modest in headline CPI because food dominates | roughly `0.15` to `0.30` percentage points on monthly CPI is plausible |
| Negative oil pass-through | often weaker than positive pass-through | `CPT-` may be near zero or imprecise in headline CPI |
| Asymmetry | possible, but not guaranteed to be statistically strong | if `p > 0.05`, write "point estimates suggest asymmetry, but evidence is not conclusive" |
| Exchange-rate channel | usually relevant for India | positive `dlnEXR` effect is plausible and often important |
| Diagnostics | serial correlation and RESET should ideally pass; BP may fail | heteroskedasticity is manageable with HAC inference |
| Model fit | moderate, not perfect | adjusted `R^2` around `0.35` to `0.50` is reasonable |

**Weakest point to acknowledge upfront:**  
In headline CPI work on India, the formal asymmetry test is often the weakest part. That is usually not a coding error. It reflects the fact that headline CPI mixes food, services, policy intervention, and imported energy costs. If the asymmetry p-value stays above `0.05`, the dissertation should shift emphasis toward:
- the existence and magnitude of positive oil pass-through,
- the role of the exchange-rate channel,
- and the institutional comparison before and after deregulation.

**Best honest routes to stronger asymmetry evidence:**
1. Add appendix regressions using CPI Fuel and Light or a cleaner non-food measure if a long monthly series is available. For this project, an official MoSPI Fuel and Light subgroup sample from `2011-2024` is acceptable as a shorter appendix.
2. Add appendix local projections for positive and negative shocks.
3. Add appendix bootstrap inference for the cumulative asymmetry restriction.
4. Do not try to "fix" the Wald test by searching across many break dummies or ad hoc specifications.

**How to read your current results if they look like this:**
- positive oil shocks raise inflation,
- negative shocks have much smaller or noisier effects,
- asymmetry is visible in point estimates but not significant at 5%,
- Brent + EXR works at least as well as Oil_INR,

then the dissertation is still valid and relevant. That is not a weak result. It is a realistic India result.

---

## SECTION 9: SEVEN-CHAPTER DISSERTATION PLAN

### Chapter 1 - Introduction
- India's dependence on imported crude oil and why that matters for inflation.
- Why headline inflation in India does not move one-for-one with oil.
- Oil price channels: direct fuel costs, transport costs, exchange rate, and policy transmission.
- Why asymmetry matters for households, RBI policy, and fiscal policy.
- Research questions, objectives, and chapter outline.

### Chapter 2 - Literature Review
- Classical "rockets and feathers" literature.
- Oil shock identification and nonlinearity.
- Exchange-rate pass-through to domestic prices in India.
- Indian evidence on oil, inflation, and administered price regimes.
- Research gap: long monthly sample covering deregulation, COVID, and the 2022 oil shock, with both Oil_INR and Brent + EXR views.

### Chapter 3 - Data and Methodology
- Variable definitions, transformations, and sources.
- Why monthly CPI inflation is measured with log-differences.
- Construction of `Oil_INR`.
- IIP chain-linking.
- Asymmetric decomposition.
- Symmetric and asymmetric ADL models.
- HAC inference and diagnostic design.

### Chapter 4 - Main Results
- Descriptive patterns.
- ADF tests.
- Symmetric benchmark.
- Primary asymmetric ADL.
- Cumulative pass-through tests.
- Sub-sample estimates.
- Main interpretation in plain language.

### Chapter 5 - Robustness and Alternative Specification
- Full `p x q` lag-grid sensitivity on a common sample.
- Brent + EXR specification.
- COVID sensitivity.
- Winsorized specification.
- Rolling window stability.
- Optional appendix: local projections and stronger price-index extensions if data are available.
- Summary of what changes and what does not.

### Chapter 6 - Discussion and Policy Implications
- Why pass-through is positive but muted in headline CPI.
- Why food inflation and policy intervention matter in India.
- What the exchange-rate result means for imported inflation.
- Why insignificance of asymmetry does not mean oil is irrelevant.
- Implications for monetary policy, fuel taxation, and welfare.

### Chapter 7 - Conclusion
- State the main findings directly.
- State the limits directly.
- Do not oversell the asymmetry result if the formal test is weak.
- Suggest future work on CPI sub-indices, fuel CPI, or local projections.

---

## SECTION 10: VIVA DEFENSE SCRIPTS

These are model answers to help in the viva. Keep them honest and simple.

---

**Q: Why did you use month-over-month log-differences instead of year-over-year inflation?**

> "My objective is short-run pass-through. Month-over-month log-differences are standard for that because they are much more likely to be stationary, and they let me estimate immediate and lagged responses cleanly. Year-over-year inflation smooths away short-run dynamics and can create persistence that is less suitable for a short-run ADL pass-through model."

---

**Q: Your asymmetry test is not significant. Does that mean your dissertation failed?**

> "No. My main result is that positive oil shocks are associated with higher CPI inflation in India, and that result is economically meaningful. The asymmetry test asks a narrower question: whether positive and negative pass-through are statistically different. In my sample, the point estimates suggest asymmetry, but the formal test does not reject symmetry at the 5% level. I report that directly. That is still a valid finding, especially in headline CPI where food and policy effects add noise."

---

**Q: The weakest point of your study is the Wald test. How would you improve the dissertation without manipulating the result?**

> "I would not try to improve the p-value by searching for a lucky specification. The right improvement is to strengthen the signal. The first option is an appendix using a more directly exposed price index such as CPI Fuel and Light if a consistent monthly series is available. The second is an appendix local-projection analysis to trace dynamic responses to positive and negative shocks. The third is bootstrap inference for the cumulative restriction. Those steps improve credibility without changing the core finding dishonestly."

---

**Q: Why did you use INR-denominated oil rather than only Brent in dollars?**

> "India imports oil, so the domestic cost depends on both world oil prices and the rupee-dollar exchange rate. Oil_INR is the most direct imported-cost measure. I also estimated a Brent plus exchange-rate robustness model so that I could separate the global price channel from the exchange-rate channel. That makes the interpretation more credible for India."

---

**Q: Why ADL in differences and not a more complicated NARDL or SVAR?**

> "This dissertation studies short-run monthly pass-through, not a full structural identification exercise. An ADL in differences is transparent, suitable for the data, and easier to defend at the MS level. I include asymmetry, diagnostics, and robustness checks without turning the project into something too large to execute properly."

---

**Q: Why split the sample at October 2014?**

> "That is when diesel deregulation took effect. It marks a meaningful institutional break in retail fuel pricing. The split lets me ask whether the pass-through mechanism looks different in a more administered regime versus a more market-linked regime."

---

**Q: Why use headline CPI when oil mainly affects fuel?**

> "Because the dissertation asks about aggregate inflation relevance for India, not only fuel prices. Headline CPI is harder to move, so the estimated pass-through is expected to be smaller than in a fuel-specific index. I treat that as part of the economic story rather than as a problem to hide."

---

## SECTION 11: BIBLIOGRAPHY

Use these as the core bibliography for the working draft. Verify citation formatting before final submission.

### Core academic references

Bacon, R. W. (1991). Rockets and feathers: The asymmetric speed of adjustment of UK retail gasoline prices to cost changes. *Energy Economics*, 13(3), 211-218.

Hamilton, J. D. (2003). What is an oil shock? *Journal of Econometrics*, 113(2), 363-398.

Jordà, Ò. (2005). Estimation and inference of impulse responses by local projections. *American Economic Review*, 95(1), 161-182.

Kilian, L. (2009). Not all oil price shocks are alike: Disentangling demand and supply shocks in the crude oil market. *American Economic Review*, 99(3), 1053-1069.

Pesaran, M. H., Shin, Y., and Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics*, 16(3), 289-326.

Shin, Y., Yu, B., and Greenwood-Nimmo, M. (2014). Modelling asymmetric cointegration and dynamic multipliers in a nonlinear ARDL framework. In *Festschrift in Honor of Peter Schmidt* (pp. 281-314). Springer.

### India-focused and closely related references

Abu-Bakar, M., and Masih, M. (2018). Is the oil price pass-through to domestic inflation symmetric or asymmetric? New evidence from India based on NARDL. *MPRA Paper No. 87569*.

Bhanumurthy, N. R., Das, S., and Bose, S. (2012). Oil price shock, pass-through policy and its impact on India. *NIPFP Working Paper No. 99*.

Pradeep, S. (2022). Impact of diesel price reforms on asymmetricity of oil price pass-through to inflation: Indian perspective. *Journal of Economic Asymmetries*, 26, e00266.

### Policy and institutional references

International Monetary Fund. (2016). *Exchange Rate Pass-Through to Domestic Prices in India: What is the Role of Imported Inputs?* IMF Working Paper 16/17.  
Link: [IMF WP 16/17](https://www.imf.org/external/pubs/ft/wp/2016/wp1617.pdf)

Reserve Bank of India. (2024). *Monetary Policy Report, October 2024*.  
Link: [RBI Monetary Policy Report](https://rbi.org.in/scripts/PublicationsView.aspx?Id=22725)

Reserve Bank of India. (2024). *State of the Economy*, RBI Bulletin.  
Link: [RBI Bulletin - State of the Economy](https://rbi.org.in/scripts/BS_ViewBulletin.aspx?Id=22717)

Reserve Bank of India. (2025). *Revisiting the Oil Price and Inflation Nexus in India*, RBI Bulletin.  
Link: [RBI Bulletin - Oil and Inflation Nexus](https://www.rbi.org.in/Scripts/BS_ViewBulletin.aspx?Id=23516)

Ministry of Petroleum and Natural Gas. (2025). *Annual Report 2024-25*. Government of India.

---

## SECTION 12: PROMPT TO GIVE AI FOR GENERATING THE R SCRIPT

Copy this prompt and give it to the AI together with this file:

---

> **PROMPT:**  
> Read the attached `new-synopsis.md` completely. Generate one complete R script called `analysis.R` that implements the full research workflow described there. Follow these requirements exactly:  
> 1. Run all 12 sections in order in a single script.  
> 2. Print clear console headers before each section.  
> 3. Save every required table as CSV and every required figure as PNG.  
> 4. Use local input files at:  
>    - `data/raw/cpi_fred.csv`  
>    - `data/raw/brent_fred.csv`  
>    - `data/raw/exr_fred.csv`  
>    - `data/raw/iip_old.csv`  
>    - `data/raw/iip_new.csv`  
> 5. Handle FRED CSV column names safely.  
> 6. Construct both `Oil_INR` and the separate `Brent + EXR` specification.  
> 7. Estimate the symmetric baseline ADL and the asymmetric ADL with `q = 3` and `p` selected by AIC over `1:4` on a common comparison sample.  
> 8. After selecting `p`, re-estimate the chosen model on the maximal sample implied by that lag order.  
> 9. Use Newey-West HAC covariance for coefficient tables and all linear restriction tests.  
> 10. Report `CPT_plus`, `CPT_minus`, the effect of `+10%` and `-10%` shocks, and the p-values for `H0: CPT_plus = 0`, `H0: CPT_minus = 0`, and `H0: CPT_plus = CPT_minus`.  
> 11. Compute the `-10%` shock effect with the correct sign.  
> 12. For the ADF section, print `p < 0.01` cleanly when the test reports the lower bound warning.  
> 13. For the IIP series, compute the splice factor from the overlap period instead of hard-coding it.  
> 14. Use `tryCatch()` around each major section so one error does not stop the script.  
> 15. In the final summary, if the asymmetry test is insignificant, state: "Point estimates suggest asymmetry, but it is not statistically significant at the 5% level."  
> 16. Report the full lag-sensitivity grid over `p = 1:4` and `q = 0:3` on a common sample, but keep the pre-specified main model clearly marked.  
> 17. Name the robustness output file `outputs/tables/table_5_2_brent_exr_specification.csv`.  
> 18. If internet access is available, fetch the official MoSPI CPI `Fuel and Light` subgroup through the CPI API and add an appendix-only extension on the shorter available sample. Do not replace the main headline CPI model. If the API call fails, skip this appendix cleanly.  
> 19. If feasible, add appendix-only local projections for horizons `0` to `6` or `0` to `12` months for positive and negative oil shocks, keeping the ADL as the main specification.  
> 20. Do not fabricate results, do not hard-code expected values, and do not describe a finding as significant unless the estimated p-value supports that claim.

---

*End of Revised Research Synopsis - Version 3.0*
