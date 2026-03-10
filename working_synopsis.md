# WORKING RESEARCH SYNOPSIS
## Current Project Blueprint (Code-Aligned)

**Title:** Do Global Oil Price Shocks Raise India's Inflation More Than They Lower It?  
**Subtitle:** Short-Run Pass-Through to CPI Inflation in India, 2004-2024  
**Student:** Aniket Pandey  
**Supervisor:** Prof. Shakti Kumar  
**Programme:** MS Economics, JNU, 2026  

---

> **Purpose of this file**  
> This is the working blueprint for the dissertation as it exists now in `/Users/aniketpandey/Desktop/dissertationv2`.  
> It is not a theoretical wish list. It reflects the current project structure, the current `analysis.R`, the actual data files, the actual outputs, and the interpretation that is defensible in front of a supervisor.

---

## SECTION 0: PROJECT IN ONE PAGE

### 0.1 Core question
How strongly do oil price shocks pass through to India's monthly CPI inflation, and is pass-through larger for oil price increases than for oil price decreases?

### 0.2 Main research design
- Main dependent variable: headline CPI inflation in monthly log-differences.
- Main oil variable: `Oil_INR = Brent_USD x INR/USD`.
- Main model: asymmetric ADL in first differences.
- Main asymmetry setup: positive and negative oil changes are estimated separately.
- Main lag design: oil lags fixed at `q = 3`; autoregressive CPI lag order `p` selected by AIC over `1:4`.
- Inference: Newey-West HAC for coefficient tests and all cumulative restriction tests.

### 0.3 What the dissertation is and is not
- This is a short-run pass-through dissertation, not a structural oil-shock identification dissertation.
- It is not a NARDL, SVAR, or local-projections project in the main chapter.
- It does not try to force statistical asymmetry if the data do not support it.
- It does include a stronger India-specific robustness design through `Brent + EXR`.
- It now includes an appendix-only `Fuel and Light` CPI model using the official MoSPI CPI API on a shorter sample.

### 0.4 Verified current headline findings
These are the current verified outputs from the working script and should guide the dissertation write-up.

| Result | Current value |
|------|------|
| Main model | ADL(3,3) |
| Main sample | April 2004 to December 2024 |
| `CPT+` | `0.021296` |
| `CPT-` | `0.000598` |
| `+10%` oil shock effect on monthly CPI | `+0.2130` percentage points |
| `-10%` oil shock effect on monthly CPI | `-0.0060` percentage points |
| `p(CPT+ = 0)` | `0.1220` |
| `p(CPT- = 0)` | `0.9375` |
| `p(CPT+ = CPT-)` | `0.2408` |
| Main interpretation | point estimates suggest asymmetry, but full-sample asymmetry is not statistically significant at 5% |

### 0.5 Verified current robustness findings
| Result | Current value |
|------|------|
| Brent + EXR `CPT+` | `0.027458` |
| Brent + EXR `+10%` effect | `+0.2746` percentage points |
| Brent + EXR `p(CPT+ = 0)` | `0.0933` |
| Exchange-rate contemporaneous p-value | `0.0287` |
| Fuel and Light appendix `CPT+` | `0.060848` |
| Fuel and Light `+10%` effect | `+0.6085` percentage points |
| Fuel and Light `p(CPT+ = 0)` | `0.0337` |
| Fuel and Light asymmetry p-value | `0.2647` |

**Bottom line:**  
Headline CPI gives a realistic but noisy oil pass-through estimate. The `Fuel and Light` appendix shows a stronger and statistically cleaner positive oil effect, which strengthens the project without changing the main dissertation question.

---

## SECTION 1: DATA AND INPUTS

### 1.1 Main study window
- Raw merged sample: `2004-04-01` to `2024-12-01`
- Raw observations: `249`
- Main estimation sample after differencing and lags: around `245`

### 1.2 Main local input files
The current script is built around these exact files:

| File | Role |
|------|------|
| `data/raw/INDCPIALLMINMEI.csv` | headline CPI from FRED/OECD |
| `data/raw/POILBREUSDM.csv` | Brent crude price from FRED/IMF |
| `data/raw/EXINUS.csv` | INR/USD exchange rate from FRED/Fed |
| `data/raw/iip_chained.xlsx` | chain-linked IIP series already prepared |

### 1.3 Optional online appendix input
The script may also fetch:
- official MoSPI CPI `Fuel and Light` subgroup data
- back series: `2011-2012`
- current series: `2013-2024`

This appendix is optional in design but already implemented in the current project. If the API fails, the main headline CPI dissertation still runs and remains valid.

### 1.4 Folder structure

```text
dissertationv2/
├── analysis.R
├── working_synopsis.md
├── data/
│   ├── raw/
│   │   ├── INDCPIALLMINMEI.csv
│   │   ├── POILBREUSDM.csv
│   │   ├── EXINUS.csv
│   │   └── iip_chained.xlsx
│   └── processed/
├── outputs/
│   ├── tables/
│   └── figures/
└── chain_link_iip.py
```

---

## SECTION 2: VARIABLE CONSTRUCTION

### 2.1 Main constructed variables

```text
Oil_INR_t = Brent_USD_t x INR/USD_t
```

```text
dlnCPI_t   = 100 x [ln(CPI_t) - ln(CPI_{t-1})]
dlnOil_t   = 100 x [ln(Oil_INR_t) - ln(Oil_INR_{t-1})]
dlnBrent_t = 100 x [ln(Brent_t) - ln(Brent_{t-1})]
dlnEXR_t   = 100 x [ln(EXR_t) - ln(EXR_{t-1})]
dlnIIP_t   = 100 x [ln(IIP_t) - ln(IIP_{t-1})]
```

### 2.2 Asymmetric decomposition

```text
dlnOil_pos_t = max(dlnOil_t, 0)
dlnOil_neg_t = min(dlnOil_t, 0)
```

The negative component is kept negative. This matters for correct interpretation of a `-10%` shock.

### 2.3 Policy and event controls
- `D_petrol = 1` from June 2010 onward
- `D_diesel = 1` from October 2014 onward
- `D_covid = 1` in April 2020 only
- `M1-M11` monthly dummies, with December as reference

### 2.4 Lag structure used in code
- CPI lags created up to `L4`
- main oil shock lags created up to `L3`
- Brent-only lags created up to `L3`
- exchange-rate lag `dlnEXR_L1` created for the `Brent + EXR` model

### 2.5 Fuel and Light appendix construction
- fetch official subgroup CPI from MoSPI API
- convert monthly index to `fuel_cpi`
- estimate `dlnFuelCPI`
- use the same oil-shock structure as the main model
- keep this as appendix-only because the sample starts in `2011`, not `2004`

---

## SECTION 3: SCRIPT ARCHITECTURE

The current project uses one single script: `analysis.R`.

### 3.1 Actual section order in the script

1. Setup  
2. Data loading and merging  
3. Variable construction  
4. Descriptive statistics and plots  
5. ADF unit root tests  
6. Baseline symmetric ADL  
7. Primary asymmetric ADL  
8. Wald asymmetry test  
9. Sub-sample analysis  
10. Diagnostic tests  
11. Robustness checks  
12. Remaining figures  
13. Final summary log

### 3.2 Design rules
- each major block uses `tryCatch()`
- console output is clean and sectioned
- tables are saved as CSV
- figures are saved as PNG
- main model is kept fixed once specified
- lag-grid search is reported as sensitivity, not used to cherry-pick a prettier result

---

## SECTION 4: ECONOMETRIC DESIGN

### 4.1 Stationarity design
The project uses ADF tests to verify:
- levels are generally non-stationary or borderline
- first differences are stationary

This justifies estimating short-run models in differences.

### 4.2 Baseline symmetric model

```text
dlnCPI_t = a + g1*dlnCPI_{t-1} + b0*dlnOil_t + b1*dlnOil_{t-1}
         + d*dlnIIP_t + policy dummies + month dummies + e_t
```

Purpose:
- show oil matters before asymmetry is introduced
- produce a simple cumulative benchmark `b0 + b1`

### 4.3 Main asymmetric ADL model

```text
dlnCPI_t = a
         + sum_i gi*dlnCPI_{t-i}
         + sum_j pi_plus_j*dlnOil_pos_{t-j}
         + sum_j pi_minus_j*dlnOil_neg_{t-j}
         + d*dlnIIP_t
         + policy dummies
         + month dummies
         + e_t
```

Rules:
- oil lag length fixed at `q = 3`
- AR lag order `p` selected by AIC over `1:4`
- selection is done on a common comparison sample
- final chosen model is then re-estimated on the maximal sample implied by the selected `p`

### 4.4 Cumulative pass-through definitions

```text
CPT+ = sum of positive oil coefficients
CPT- = sum of negative oil coefficients
```

The script reports:
- `CPT+`
- `CPT-`
- gap = `CPT+ - |CPT-|`
- effect of a `+10%` oil shock
- effect of a `-10%` oil shock

### 4.5 Inference design
Use Newey-West HAC throughout for:
- coefficient tables
- `H0: CPT+ = 0`
- `H0: CPT- = 0`
- `H0: CPT+ = CPT-`

This is one of the strongest parts of the current project and should not be removed.

### 4.6 Brent + EXR robustness model

```text
dlnCPI_t = main ADL structure
         + positive Brent lags
         + negative Brent lags
         + dlnEXR_t + dlnEXR_{t-1}
         + controls
```

Purpose:
- separate world oil-price shocks from the exchange-rate channel
- make the India interpretation more credible

### 4.7 Fuel and Light appendix model
Use the same asymmetric oil setup, but replace headline CPI with `Fuel and Light` CPI on the shorter official sample.

Purpose:
- not to replace the main model
- to show whether a more directly energy-exposed price index gives a clearer pass-through signal

### 4.8 What is no longer part of the project
These may appear in older drafts or old AI scripts, but they are not part of the current recommended project:
- NARDL as a main method
- local projections as a main method
- Zivot-Andrews break tests
- ADF + PP + KPSS all together
- manually forcing a preferred lag order
- claiming asymmetry only because point estimates look different

---

## SECTION 5: OUTPUTS THAT THE CURRENT PROJECT CREATES

### 5.1 Tables

| File | Content |
|------|------|
| `outputs/tables/table_3_1_descriptive_stats.csv` | descriptive statistics |
| `outputs/tables/table_3_2_variable_definitions.csv` | variable definitions |
| `outputs/tables/table_4_1_adf_results.csv` | ADF unit root results |
| `outputs/tables/table_4_2_baseline_adl.csv` | symmetric ADL results |
| `outputs/tables/table_4_3_asymmetric_adl.csv` | main asymmetric model results |
| `outputs/tables/table_4_4_wald_test.csv` | asymmetry Wald test |
| `outputs/tables/table_4_5_subsample.csv` | pre/post 2014 comparison |
| `outputs/tables/table_4_6_diagnostics.csv` | diagnostics |
| `outputs/tables/table_5_1_lag_sensitivity.csv` | full `p x q` lag grid |
| `outputs/tables/table_5_2_brent_exr_specification.csv` | Brent + EXR robustness |
| `outputs/tables/table_5_3_covid_sensitivity.csv` | without COVID dummy |
| `outputs/tables/table_5_4_winsorized.csv` | winsorized oil shocks |
| `outputs/tables/table_a_1_fuel_light_appendix.csv` | official Fuel and Light appendix |

### 5.2 Figures

| File | Content |
|------|------|
| `outputs/figures/fig_1_raw_series.png` | levels of CPI, Brent, EXR, IIP |
| `outputs/figures/fig_2_log_diff_series.png` | `dlnCPI`, `dlnOil`, `dlnEXR`, `dlnIIP` |
| `outputs/figures/fig_3_oil_decomposition.png` | positive and negative oil decomposition |
| `outputs/figures/fig_4_cumulative_passthrough.png` | cumulative oil pass-through paths |
| `outputs/figures/fig_5_subsample_comparison.png` | sub-sample comparison |
| `outputs/figures/fig_6_cusum_stability.png` | CUSUM stability |
| `outputs/figures/fig_7_rolling_window.png` | rolling 60-month pass-through |
| `outputs/figures/fig_8_residual_diagnostics.png` | residual diagnostics |
| `outputs/figures/fig_9_oil_price_regimes.png` | Brent price regimes |
| `outputs/figures/fig_10_asymmetry_gap.png` | `CPT+` vs `|CPT-|` comparison |

### 5.3 Processed datasets
- `data/processed/analysis_dataset.csv`
- `data/processed/cpi_fuel_light_all_india_combined.csv`

---

## SECTION 6: HOW TO INTERPRET THE RESULTS

### 6.1 The main honest claim
Use this as the default interpretation:

> Positive oil shocks are associated with higher monthly CPI inflation in India, and the estimated effect is economically meaningful. However, the null of symmetric pass-through cannot be rejected at the 5% level in the full sample.

### 6.2 What not to claim
Do not write:
- "asymmetry is strongly proven"
- "rockets and feathers is confirmed beyond doubt"
- "negative oil shocks have no effect at all"

### 6.3 What you can claim safely
- point estimates are asymmetric
- positive oil shocks show stronger pass-through than negative shocks
- exchange-rate movements matter for India
- the Fuel and Light appendix shows a clearer positive oil transmission channel
- headline CPI is noisier because food and other components dilute the energy signal

### 6.4 Why the Wald test is the weakest part
This is not mainly a coding problem. Headline CPI in India mixes:
- food-price shocks
- services inflation
- policy intervention
- imported energy costs

So the asymmetry restriction can easily be imprecise even when the positive oil effect is real.

### 6.5 Best way to strengthen the dissertation without p-hacking
- keep headline CPI as the main model
- keep Brent + EXR as the main robustness design
- use Fuel and Light as appendix-only evidence
- report the weak Wald result honestly

This is exactly what the current project now does.

---

## SECTION 7: CREDIBLE EXPECTED RESULTS

These are not targets to force. They are realism checks.

| Item | Credible result for India |
|------|------|
| Main `CPT+` | positive and economically meaningful |
| Main `+10%` headline CPI effect | roughly `0.15` to `0.30` pp is plausible |
| Main `CPT-` | near zero or imprecise is plausible |
| Full-sample asymmetry Wald | may remain insignificant |
| Brent + EXR | often sharper than Oil_INR alone for interpretation |
| Fuel and Light appendix | should show stronger positive pass-through than headline CPI |
| Adjusted `R^2` | moderate, around `0.35` to `0.50`, is reasonable |

### 7.1 Current project fits these benchmarks
- main headline result is realistic
- exchange-rate robustness improves the India story
- Fuel and Light appendix gives stronger positive pass-through
- asymmetry still remains statistically inconclusive

That combination is acceptable and credible for an MS Economics dissertation.

---

## SECTION 8: CHAPTER PLAN

### Chapter 1: Introduction
- India's oil import dependence
- why oil matters for inflation
- research question
- motivation for asymmetry

### Chapter 2: Literature Review
- oil shocks and inflation
- rockets and feathers literature
- India-specific pass-through and pricing reforms
- exchange-rate pass-through in India

### Chapter 3: Data and Methodology
- data sources and sample window
- variable construction
- asymmetric ADL framework
- HAC inference
- reason for Brent + EXR robustness

### Chapter 4: Main Empirical Results
- descriptive patterns
- ADF tests
- symmetric benchmark
- main asymmetric ADL
- Wald test
- sub-samples
- diagnostics

### Chapter 5: Robustness and Appendix Evidence
- lag grid
- Brent + EXR
- COVID sensitivity
- winsorized shocks
- rolling window
- Fuel and Light appendix

### Chapter 6: Discussion and Policy Implications
- why headline CPI pass-through is modest
- why exchange-rate effects matter
- how deregulation and taxation matter
- why weak asymmetry inference does not make oil irrelevant

### Chapter 7: Conclusion
- state the positive oil pass-through result clearly
- state the asymmetry limitation clearly
- mention Fuel and Light as stronger supporting appendix evidence

---

## SECTION 9: VIVA ANSWERS

**Q: Why use headline CPI if oil mainly affects fuel?**  
> Because the dissertation asks about aggregate inflation relevance in India. Headline CPI is the policy-relevant inflation measure. I then add Fuel and Light as an appendix to show the more direct energy-sensitive channel.

**Q: Your asymmetry Wald test is insignificant. Did the dissertation fail?**  
> No. The main result is positive oil pass-through to CPI, with economically meaningful magnitude. The Wald test asks a narrower question about whether positive and negative pass-through are statistically different. In headline CPI that difference is often hard to estimate precisely.

**Q: Why include Brent + EXR?**  
> India imports oil, so domestic inflation pressure depends on both world oil prices and the rupee-dollar exchange rate. Brent + EXR separates those channels and improves the India interpretation.

**Q: What is the strongest extra evidence in your project?**  
> The official MoSPI Fuel and Light appendix. It shows a stronger positive oil pass-through than headline CPI, which is what we would expect from a more energy-exposed price index.

**Q: Why not keep adding more models?**  
> Because this is an MS dissertation, not a methods contest. A clean, well-defended ADL design is better than an overcomplicated project with many weakly motivated models.

---

## SECTION 10: CORE REFERENCES

Abu-Bakar, M., and Masih, M. (2018). Is the oil price pass-through to domestic inflation symmetric or asymmetric? New evidence from India based on NARDL. *MPRA Paper No. 87569*.

Bhanumurthy, N. R., Das, S., and Bose, S. (2012). Oil price shock, pass-through policy and its impact on India. *NIPFP Working Paper No. 99*.

Hamilton, J. D. (2003). What is an oil shock? *Journal of Econometrics*, 113(2), 363-398.

Kilian, L. (2009). Not all oil price shocks are alike: Disentangling demand and supply shocks in the crude oil market. *American Economic Review*, 99(3), 1053-1069.

Pradeep, S. (2022). Impact of diesel price reforms on asymmetricity of oil price pass-through to inflation: Indian perspective. *Journal of Economic Asymmetries*, 26, e00266.

RBI. *Monetary Policy Report* and related inflation analysis documents.

MoSPI CPI API documentation and CPI subgroup data.

---

## SECTION 11: PROMPT TO GIVE AN AI

Use this prompt if you want another AI to regenerate or improve `analysis.R` without drifting away from the current project:

> Read the attached `working_synopsis.md` completely. Generate one complete R script called `analysis.R` that matches this project exactly. Use the local files `data/raw/INDCPIALLMINMEI.csv`, `data/raw/POILBREUSDM.csv`, `data/raw/EXINUS.csv`, and `data/raw/iip_chained.xlsx`. Estimate a symmetric ADL benchmark and an asymmetric ADL with oil lags fixed at `q = 3` and CPI AR lags chosen by AIC over `1:4` on a common sample, then re-estimate the chosen model on the maximal usable sample. Use Newey-West HAC covariance for all coefficient and cumulative restriction tests. Report `CPT+`, `CPT-`, `+10%` and `-10%` shock effects, `p(CPT+ = 0)`, `p(CPT- = 0)`, and `p(CPT+ = CPT-)`. Keep the main model as headline CPI. Include the Brent + EXR robustness model. If internet access is available, fetch the official MoSPI CPI Fuel and Light subgroup data and run an appendix-only model on the shorter available sample. Do not replace the main model, do not hard-code expected values, do not cherry-pick lag orders, and do not claim asymmetry is significant unless the estimated p-value supports that statement.

---

*End of Working Synopsis - Version 3.0 (code-aligned)*
