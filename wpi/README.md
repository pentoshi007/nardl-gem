# WPI Oil Pass-Through Pipeline

A literature-aligned pipeline that estimates oil-price pass-through into India's Wholesale Price Index (WPI) using official OEA monthly WPI files, World Bank Pink Sheet Brent prices, and the FRED INR/USD series. Two estimation families are run: (a) short-run asymmetric ADL models in log-differences, and (b) Pesaran–Shin–Smith bounds NARDL models in log-levels with Shin–Yu–Greenwood-Nimmo asymmetric decomposition.

## Running

```bash
Rscript wpi/run_all.R
```

All raw inputs are already under `data/raw/wpi/`. All outputs go to `wpi/outputs/`.

## Data sources

- Office of Economic Adviser monthly WPI files and linking factors:
  - `https://eaindustry.nic.in/download_data_1112.asp`
  - `https://eaindustry.nic.in/download_data_0405.asp`
  - `https://eaindustry.nic.in/download_data_9394.asp`
  - `https://eaindustry.nic.in/download_data_8182.asp`
  - `https://eaindustry.nic.in/linking_factor1112.asp`
  - `https://eaindustry.nic.in/linking_factor0405.asp`
  - `https://eaindustry.nic.in/linking_factor9394.asp`
- World Bank Pink Sheet monthly Brent prices:
  - `https://thedocs.worldbank.org/en/doc/74e8be41ceb20fa0da750cda2f6b9e4e-0050012026/related/CMO-Historical-Data-Monthly.xlsx`
- FRED INR/USD exchange rate:
  - `https://fred.stlouisfed.org/graph/fredgraph.csv?id=EXINUS`

## Chain construction

- Headline WPI: OEA releases chained across four base-year series (1981-82, 1993-94, 2004-05, 2011-12) using official linking factors to a common `2011-12 = 100` basis, running April 1982 – March 2026 (528 observations).
- Fuel & Power WPI: chained across 1993-94, 2004-05, and 2011-12 bases to `2011-12 = 100`, running April 1994 – March 2026 (384 observations).
- After inner-joining with Brent and INR/USD, the ADL estimation samples cover roughly 43 years (headline) and 31 years (fuel).

## Models

### Main short-run ADL (claim-bearing)

- `M1 — Headline INR-oil`: Δln(WPI)_t regressed on 12 own lags, positive and negative parts of Δln(oil_INR) at lags 0–6, month fixed effects. Newey–West HAC standard errors.
- `M2 — Headline Brent + EXR`: same structure but with positive and negative Δln(Brent) and separate Δln(EXR) terms as a decomposition check.
- `M3 — Fuel & Power`: fuel inflation on asymmetric INR-oil, Δln(EXR) controls, a post-October-2014 diesel-deregulation dummy, an April–September 2020 COVID dummy, and month fixed effects.

Each spec reports cumulative pass-through (CPT+ = Σ positive-shock coefficients, CPT- = Σ negative-shock coefficients), the Wald tests for CPT+ = 0, CPT- = 0, and symmetry CPT+ = CPT-.

### Literature-style NARDL appendix (cointegration in levels)

Estimated with the `nardl` package, case = 3 (unrestricted intercept, no trend), AIC lag selection up to 4:

1. `ln(WPI) ~ ln(Brent)`
2. `ln(WPI) ~ ln(Brent) | ln(EXR)`
3. `ln(WPI) ~ ln(INR-oil)`
4. `ln(Fuel&Power) ~ ln(INR-oil)`

For each NARDL spec the pipeline reports: bounds F-statistic, the true error-correction coefficient (sum of all y-level-lag coefficients, with Newey–West Wald p-value), short-run and long-run asymmetry Wald tests, and long-run multipliers.

### Diagnostics on the short-run ADL models

Breusch–Godfrey(12), Breusch–Pagan, HAC-RESET(2,3), Rec-CUSUM, OLS-CUSUM.

### Robustness: pre- vs post-2010 subsample

Same ADL specifications re-estimated on subsamples split at 2010-04 (onset of Indian petrol deregulation and precursor to the 2013–14 diesel deregulation).

## Literature

- Pradeep (2022), *Journal of Economic Asymmetries*: diesel-reform-driven asymmetric pass-through to disaggregated wholesale and consumer prices.
- Suresh, Naveen, and Naveenan (2026), *Foreign Trade Review*: WPI-focused India NARDL with long-run asymmetry and weaker short-run asymmetry.
- Abu-Bakar and Masih (2018), MPRA: ARDL vs NARDL comparison on Indian inflation; strong asymmetric pass-through.
- Chattopadhyay and Mitra (2015), *Energy Policy*: NARDL on Indian oil products; asymmetry only in market-determined segments.
- Pal and Mitra (2016), *Economic Modelling*: multiple-threshold NARDL on Indian oil product prices.
- Sek (2019), *Panoeconomicus*: panel NARDL decomposing CPI vs WPI pass-through in oil importers.
- Sadath and Acharya (2021), *IJESM*: SVAR on India showing asymmetric macro effects of oil shocks on WPI.

## Interpreting the current outputs

Full sample (1983–2026) headline ADL: CPT+ ≈ 0.030 (p = 0.024), CPT- ≈ 0.037 (p = 0.001), symmetry not rejected (p = 0.67). Subsample split reveals the structural reason: pre-2010 pass-through is weak and insignificant on the positive side (administered-price regime), post-2010 pass-through roughly triples (CPT+ ≈ 0.074, CPT- ≈ 0.081, both significant). Fuel-and-power post-2010 pass-through is an order of magnitude larger (CPT+ ≈ 0.52, CPT- ≈ 0.44). All four NARDL specs have negative and significant error-correction coefficients with bounds-F statistics above the 1% upper critical value; long-run asymmetry is rejected in the brent-only, brent+exr, and fuel specifications. This is consistent with the literature finding that post-reform diesel deregulation sharpened pass-through, and that asymmetry is primarily a long-run phenomenon visible once the system is modelled in levels with cointegration.

## Outputs

Tables in `wpi/outputs/tables/` (15 CSV files) cover data spans, chain factors, splice checks, ADL summaries and coefficients for each spec, diagnostics, NARDL bounds/ECT/LR, publication-triage verdict, and the pre/post-2010 subsample comparison. Figures in `wpi/outputs/figures/` show the chained WPI series and headline inflation against the INR-oil change.
