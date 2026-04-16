# Research Suggestions, Problem Diagnosis & Publication Roadmap — CORRECTED v2
## Project: Oil Price Pass-Through to India's CPI Inflation (2004–2024)
### Author: Aniket Pandey | MS Economics, JNU New Delhi | April 2026
### Revision note: v1 of this document contained two critical factual errors and a mis-ranked
### fix sequence. All errors have been corrected and the plan re-ordered accordingly.
---

> **Purpose of this file:** This document provides full context about an ongoing MS Economics
> dissertation, its current methodological problems, proposed fixes ranked by priority, and
> constraints for converting it into a publishable journal article. Any AI assistant reading
> this file should be able to understand the research, evaluate the proposed approaches, and
> suggest further improvements without needing any prior conversation history.

---

## 1. Research Overview

### 1.1 Title
*Do Global Oil Price Shocks Raise India's Inflation More Than They Lower It?
Short-Run Pass-Through to CPI Inflation in India, 2004–2024*

### 1.2 Research Question
Does a positive oil price shock (oil price rise) raise India's CPI inflation by MORE than a
negative oil price shock (oil price fall) reduces it? This asymmetry is known in the economics
literature as the "rockets and feathers" effect.

### 1.3 Why It Matters
- India imports approximately 85% of its crude oil, making domestic prices highly sensitive to
  global oil markets.
- If pass-through is asymmetric, monetary policy must react differently to oil price increases
  vs decreases — a direct policy implication for the Reserve Bank of India.
- Existing India-specific literature is limited and often uses older data or single-direction tests.

### 1.4 Data Used
| Series | Source | Period |
|---|---|---|
| India CPI (All Groups, All India) | OECD/FRED (INDCPIALLMINMEI) | Apr 2004 – Dec 2024 |
| Brent Crude Oil Price (USD/barrel) | IMF/FRED (POILBREUSDM) | Apr 2004 – Dec 2024 |
| INR/USD Exchange Rate | Federal Reserve/FRED (EXINUS) | Apr 2004 – Dec 2024 |
| IIP General Index (chain-linked) | RBI DBIE (Base 2011-12) | Apr 2004 – Dec 2024 |
| CPI Fuel & Light sub-index | MoSPI CPI API (groupcode=5) | ~2012 – Dec 2024 |

- Total study window: **249 monthly observations**
- Oil price in INR = Brent (USD) × INR/USD exchange rate (constructed variable)
- IIP is chain-linked across base years (2004-05 and 2011-12) using a splice-ratio method

### 1.5 Methodology Used (Current)
The paper estimates an **Asymmetric Autoregressive Distributed Lag (ADL) model** in first differences:

- Dependent variable: Δln(CPI) — monthly log change in headline CPI (×100 for percent)
- Key regressors: Δln(Oil⁺) and Δln(Oil⁻) — positive and negative components of oil price change
  using the Mork (1989) decomposition: Oil⁺ = max(ΔlnOil, 0); Oil⁻ = min(ΔlnOil, 0)
- AR lags of CPI: selected by AIC from p = 1 to 4
- Oil shock lags: 0 to 3 (i.e., current month and 3 lagged months)
- Controls: Δln(IIP), monthly seasonal dummies (M1–M11), policy dummies for petrol deregulation
  (June 2010), diesel deregulation (October 2014), and COVID-19 outlier (April 2020)
- Inference: Newey-West HAC standard errors
- Asymmetry test: Wald test for H₀: CPT⁺ = CPT⁻ where CPT = cumulative pass-through coefficient

### 1.6 Key Findings — Accurate Version (CORRECTED from v1)

**Main model (INR-denominated oil):**
- CPT⁺ = 0.021 — a 10% oil price rise raises monthly CPI by ~0.21 pp
- CPT⁻ ≈ 0 — oil price falls have near-zero effect
- **Wald test H₀: CPT⁺ = CPT⁻ → p = 0.2408 — FAILS at 5%**

**Brent+EXR specification (Robustness Check 2):**
- Separates Brent USD and INR/USD exchange rate as distinct regressors
- Asymmetry Wald p = **0.1443** — closer to significance than main model
- Exchange rate coefficients are significant, suggesting partial FX pass-through
- This model has better AIC than the primary INR-oil model
- **This is currently labelled a robustness check but has stronger results than the main model**

**Fuel & Light CPI appendix (CORRECTED — v1 was wrong here):**
- Positive pass-through (CPT⁺) is statistically significant at **p = 0.034**
- **Asymmetry Wald test (H₀: CPT⁺ = CPT⁻) p = 0.265 — ALSO FAILS**
- v1 of this document wrongly stated "Fuel & Light Wald asymmetry passes at p = 0.03"
- The correct statement is: "Fuel & Light CPI shows significant positive oil pass-through,
  but the asymmetry between positive and negative shocks remains imprecise even there"

---

## 2. Core Problem Diagnosis (Revised)

### 2.1 The Primary Problem: Wald Test Fails in ALL Specifications
The Wald test for H₀: CPT⁺ = CPT⁻ fails at 5% in every specification estimated so far:
- Main model (INR oil): p = 0.2408
- Brent+EXR model: p = 0.1443 (closest to significance)
- Fuel & Light CPI: p = 0.265

This is a consistent pattern — the issue is not specification-specific noise. The paper's point
estimates always suggest asymmetry (CPT⁺ > 0, CPT⁻ ≈ 0), but the gap is never large enough
relative to its standard error to achieve significance.

### 2.2 Why: Three Compounding Causes

**Cause A — CPI aggregation dilutes the oil signal:**
India's CPI basket is ~39% food and ~7% fuel. Food prices are driven by monsoons, MSP revisions,
and agricultural supply — entirely unrelated to oil. This inflates residual variance, widens
standard errors on all oil coefficients, and reduces the Wald statistic. Even the Fuel & Light
CPI result confirms this: positive CPT⁺ is significant (p = 0.034), but the variance of CPT⁻
is also large enough that the asymmetry gap is not detectable at 5%.

**Cause B — The INR-oil variable conflates two channels:**
The primary regressor (Oil_INR = Brent_USD × INR/USD) mixes two distinct transmission mechanisms:
(1) global oil price movements, and (2) exchange rate pass-through. These two channels do not
necessarily transmit to Indian CPI with the same speed or asymmetry. The Brent+EXR model already
shows this matters — separating them improves the Wald p from 0.2408 to 0.1443.

**Cause C — Retail price policy creates a step-function transmission:**
India's domestic fuel prices were administratively controlled until June 2010 (petrol) and October
2014 (diesel). The government absorbed oil price changes in the pre-deregulation period, suppressing
pass-through. After deregulation, prices move with the market. Using a single pass-through
coefficient over the full 2004–2024 sample averages across two structurally different regimes,
biasing CPT⁺ downward. Split-sample analysis in the paper already hints at this, but splitting
halves the sample, reducing power. The correct fix is interaction terms (see Fix 3 below).

### 2.3 What v1 Got Wrong (Documented Corrections)

| v1 Claim | Correct Fact |
|---|---|
| "Fuel & Light Wald asymmetry passes at p = 0.03" | p = 0.034 is for CPT⁺ ≠ 0 test, not the asymmetry test. Asymmetry p = 0.265. |
| "Food CPI control is the highest-priority fix" | Adding lagged food CPI cuts N to 166 and worsens asymmetry to p = 0.4338. Food term itself not significant. |
| "NOPI replaces raw positive, keep raw negative" | Kilian & Vigfusson (2011) caution this changes the test object; can hard-wire asymmetry. Use only as robustness. |
| "Simple Rademacher wild bootstrap is sufficient" | For time-series with serial dependence, need dependent wild bootstrap (Shao 2010) or block/sieve bootstrap. |
| "Fix order: Food → NOPI → Bootstrap → NARDL" | Correct order: Framing → Brent+EXR → PPAC retail prices → Interaction model → Dependent bootstrap → NOPI (robustness) → NARDL (optional Scopus upgrade) |

---

## 3. Corrected Fix Sequence (Re-Ranked)

### Fix 0 — Correct the Factual Framing [IMMEDIATE, NO COMPUTATION]

**What to change:**
- Every instance of "Fuel & Light asymmetry passes at p = 0.03" must be replaced with:
  "Fuel & Light CPI shows significant positive oil pass-through (CPT⁺, p = 0.034), indicating
  the oil-inflation channel operates through energy prices; however, the asymmetry between
  positive and negative shocks (H₀: CPT⁺ = CPT⁻) remains statistically imprecise (p = 0.265),
  consistent with the headline result."
- This reframing is honest and still publication-worthy: it confirms the positive channel exists
  while attributing the asymmetry failure to a power issue common across all specifications.

---

### Fix 1 — Promote Brent+EXR as Primary Short-Run Specification [HIGH PRIORITY, EASY]

**Current status:** The Brent+EXR model is listed as Robustness Check 2 (table_5_2).
**What to change:** Make this the MAIN model; demote INR-oil to the benchmark/baseline role.

**Why it is superior:**
- AIC is better (lower) for Brent+EXR than for the INR-oil model
- Asymmetry Wald p = 0.1443 vs 0.2408 — substantially closer to significance
- Economically more honest: Brent and INR/USD transmit to CPI through different channels
  (global commodity market vs. import cost channel) and at different speeds
- Separating them allows the model to detect exchange-rate-specific asymmetry
  (INR depreciation is rarely offset by the government; appreciation is more often absorbed)
- The exchange rate coefficients being significant is itself an important finding

**Framing in the paper:**
"The preferred short-run specification separates the global crude price channel (Brent USD)
from the exchange-rate pass-through channel (Δln EXR). This decomposition is motivated by
the distinct policy and market mechanisms governing each channel in India."

---

### Fix 2 — Add PPAC Domestic Retail Fuel Prices as Transmission Variable [HIGH PRIORITY, MEDIUM EFFORT]

**What to do:**
- Download the official PPAC (Petroleum Planning & Analysis Cell, Government of India) historical
  retail selling price series for petrol and diesel at Delhi from ppac.gov.in
  - Pre-2017 data: available as a revision table (irregular dates, must be converted to monthly)
  - Post-2017 data: daily data available (average to monthly)
- Construct Δln(RetailPetrol) and Δln(RetailDiesel) as monthly log changes
- These can be used in two ways:
  (a) As direct dependent variables: estimate the ADL with Δln(RetailFuelPrice) on the left,
      replacing Δln(CPI), to isolate the first-stage pass-through
  (b) As intermediate transmission controls: add retail price changes as a regressor between
      global oil and CPI to test whether the channel operates through domestic retail prices

**Why this is better than food CPI control:**
- Retail fuel prices ARE the direct transmission mechanism from global oil to Indian inflation
  (firms use diesel for transportation; households use LPG and petrol directly)
- The food CPI control absorbed the wrong variance (food is not caused by oil) and cut the
  sample by ~70 observations because food CPI API data starts later
- PPAC data covers the full 2004–2024 window and is directly on-topic
- It targets the actual institutional mechanism: government excise adjustments create the
  asymmetry (duties are cut when global prices rise, restored when they fall; this
  dampens both directions but dampens falls more → creates measured asymmetry in retail prices)

**Data source:** https://ppac.gov.in/retail-selling-price-rsp-of-petrol-diesel-and-domestic-lpg/
  and https://ppac.gov.in/retail-selling-price-rsp-of-petrol-diesel-and-domestic-lpg/rsp-of-petrol-and-diesel-at-delhi-up-to-15-6-2017

**Expected result:** Using retail fuel prices as dependent variable or as a control variable
may sharpen identification of the oil-CPI link by targeting the actual transmission mechanism;
however, whether it produces a significant asymmetry Wald test cannot be predicted in advance.

---

### Fix 3 — Interaction Model (Deregulation Regime) Instead of Split Samples [HIGH PRIORITY, MEDIUM EFFORT]

**Problem with current approach:**
The paper currently estimates two separate sub-sample regressions (pre/post Oct 2014 diesel
deregulation). Splitting a sample of T = 240 into two halves (~120 each) roughly halves
statistical power per regression. The Wald test may not pass in either sub-sample simply due
to insufficient observations.

**What to do instead:**
Keep the full sample and add interaction terms between oil shock variables and a post-deregulation
dummy (D_post = 1 after October 2014):

Model:
  Δln(CPI)_t = [AR terms] +
               Σ π_k⁺ · ΔlnOilpos_{t-k} +                     (pre-deregulation slope)
               Σ π_k⁻ · ΔlnOilneg_{t-k} +
               Σ γ_k⁺ · (ΔlnOilpos_{t-k} × D_post) +           (regime change in slope)
               Σ γ_k⁻ · (ΔlnOilneg_{t-k} × D_post) +
               [other controls] + ε_t

**What tests to run:**
- Post-deregulation positive pass-through: π_k⁺ + γ_k⁺ summed → CPT⁺_post
- Post-deregulation asymmetry: H₀: CPT⁺_post = CPT⁻_post (this should be the main Wald test)
- Test significance of regime change: H₀: all γ_k⁺ = γ_k⁻ = 0

**Why this works:**
- Full sample is used; no power loss from splitting
- The asymmetry test is focused within the post-deregulation regime where market pricing applies — this may sharpen detection, but significance is not guaranteed
- Pre-deregulation period acts as the control/baseline
- Directly tests whether deregulation strengthened pass-through asymmetry (the paper's implicit
  policy argument)

**Caveat:** The interaction model adds ~8 regressors (4 positive + 4 negative interactions).
With T ≈ 240 and already ~20 regressors, degrees-of-freedom must be monitored. A parsimonious
version using only q = 2 or 3 oil lags (not 4) in the interaction block is advisable.

---

### Fix 4 — Dependent Wild Bootstrap / Block Bootstrap for Wald Test Inference [MEDIUM PRIORITY]

**Problem with simple Rademacher wild bootstrap (v1 suggestion):**
The plain wild bootstrap multiplies residuals by ±1 weights independently at each time period.
This correctly replicates heteroskedasticity but DOES NOT replicate serial correlation.
For a model with Newey-West HAC standard errors (which correct for autocorrelation), the
corresponding bootstrap must also replicate the serial dependence structure of the errors.
Using the plain wild bootstrap with HAC tests produces tests that are oversized (reject too
often) under serial dependence — confirmed by Shao (2010) and Davidson & Monticini (2016).

**What to use instead:**

Option A — **Dependent Wild Bootstrap (DWB, Shao 2010):**
- Generates bootstrap weights that are autocorrelated at the same bandwidth as the HAC estimator
- Weights follow a moving average structure: w_t = Σ k(j/l) · η_{t-j} where k() is the
  Bartlett/Parzen kernel and η are iid N(0,1) draws
- Directly mirrors the HAC bandwidth assumption in the bootstrap weighting scheme
- This is the theoretically correct counterpart to Newey-West inference for time series

Option B — **Block Bootstrap:**
- Resample consecutive blocks of residuals (block length ≈ HAC bandwidth)
- Preserves the autocorrelation structure within each block
- Simpler to implement but less efficient than DWB
- Recommended block length: l ≈ floor(0.75 × T^(1/3)) or same as HAC lag

Option C — **Sieve Bootstrap:**
- Fits an AR(p) model to residuals, bootstraps the AR innovations
- Best when the autocorrelation structure is well-approximated by a low-order AR

**Recommendation:** Use Option A (DWB) to match the existing Newey-West HAC framework.
The R package `bootswatch` or manual implementation following Shao (2010) is required.

**Why it matters:** The Wald test currently has p = 0.2408 asymptotically. The DWB p-value
may be meaningfully different from this. More importantly, reporting DWB inference alongside
HAC asymptotic inference significantly strengthens the paper's methodological credibility for
both UGC CARE and Scopus reviewers.

---

### Fix 5 — NOPI as Robustness Only [LOW PRIORITY, NOT MAIN MODEL]

**Why NOPI should NOT replace the Mork decomposition as the main model:**
- Kilian & Vigfusson (2011) specifically caution that replacing the positive component with
  NOPI while keeping raw negative changes creates an asymmetric test object — the positive
  and negative variables are no longer conceptually symmetric measures of the same quantity
- This makes the Wald test harder to interpret: it tests whether the "new-high" positive effect
  equals the "all-decline" negative effect, which is not the rockets-and-feathers hypothesis
- Hard-wiring a directional advantage into the measurement of positive shocks can mechanically
  produce larger CPT⁺, inflating the apparent asymmetry

**How to use NOPI correctly:**
- Estimate a separate NOPI model where BOTH the positive and negative shock variables are
  NOPI-analogues: NOPI⁺ = max(0, lnOil_t − max12monthhistory) and
  NOPI⁻ = min(0, lnOil_t − min12monthhistory)
- This preserves symmetry in the measurement concept
- OR use NOPI only as a univariate test: does NOPI predict inflation? (single-side test)
- Report as sensitivity analysis, explicitly citing Kilian & Vigfusson (2011) caution

---

### Fix 6 — NARDL Framework [SCOPUS-GRADE UPGRADE, HIGH EFFORT]

**What it adds:**
The current model is entirely in first differences and captures only short-run dynamics.
The NARDL (Shin, Yu & Greenwood-Nimmo 2014) framework, already cited in the bibliography,
adds:
(1) A bounds test for asymmetric cointegration between oil price levels and CPI levels
(2) Long-run asymmetric coefficients with a more powerful long-run Wald test
(3) Dynamic multiplier plots showing cumulative impulse responses over a 12–24 month horizon

**Why it has more power:**
The long-run Wald test in NARDL tests whether the long-run equilibrium relationship between
oil prices and CPI is asymmetric. This relationship integrates information over many periods,
reducing the noise-to-signal problem that afflicts the short-run Wald test.

**Pre-condition:**
The ADF tests already in the paper must show lnCPI and lnOil are I(1) — which they should
(log levels are non-stationary, log differences are stationary). This directly satisfies the
NARDL pre-testing requirement.

**R implementation:**
Install the `nardl` package in R. The function `nardl()` takes the same variables as the current
ADL model and automatically estimates the bounds test and long-run coefficients.

**When to do this:**
- UGC CARE submission: Fixes 0–4 are sufficient; NARDL is optional
- Scopus submission (IJEEP, Journal of Quantitative Economics): NARDL substantially improves
  the paper's competitiveness; worth the extra 1–2 weeks of effort

---

### Fix 7 — Food CPI as Robustness Check Only [NOT A PRIMARY FIX]

**Why this was demoted from Fix 1:**
An empirical check on the actual data produced the following when lagged food CPI was added:
- Sample reduced from N ≈ 240 to N = 166 (food CPI API data starts later; ~74 observations lost)
- Asymmetry Wald p WORSENED from 0.2408 to 0.4338
- Food CPI L1 coefficient was NOT statistically significant

**Why it failed:**
1. The sample reduction dominates any noise-reduction benefit — losing 74 observations in a
   test that already lacks power is counterproductive
2. Food CPI inflation is correlated with headline CPI mechanically (food is 39% of CPI), so
   adding it as a control partially controls away the variation in the dependent variable itself
3. The food-oil correlation at monthly frequency is low, so food CPI provides little orthogonal
   signal to sharpen the oil coefficients

**If still desired:**
Use it only as an explicit robustness check on the post-2012 sub-sample (where food data exists)
and report honestly that it does not change the main result. This demonstrates due diligence
without misleading the reader about its efficacy.

---

## 4. Corrected Model Hierarchy

| Model | Dependent Variable | Oil Specification | Wald p (current/expected) | Role in Paper |
|---|---|---|---|---|
| M0 (Baseline) | Δln(Headline CPI) | INR oil, Mork decomp | p = 0.2408 | Benchmark; shows the basic result |
| M1 (Main — Fix 1) | Δln(Headline CPI) | Brent+EXR, Mork decomp | p = 0.1443 (already computed) | Preferred short-run model |
| M2 (Fix 3) | Δln(Headline CPI) | Brent+EXR + deregulation interaction | Expected lower | Policy-structural model |
| M3 (Fix 2) | Δln(Retail Fuel Price) | INR oil or Brent+EXR | May sharpen identification of transmission channel | Transmission channel model |
| M4 (Fix 5) | Δln(Headline CPI) | NOPI robustness | Sensitivity only | Robustness |
| M5 (Appendix) | Δln(Fuel & Light CPI) | INR oil, Mork decomp | CPT⁺ p = 0.034, Asym p = 0.265 | Energy channel companion |
| M6 (Fix 6, optional) | ln(CPI) level | NARDL partial sums | Long-run Wald (may provide stronger evidence if cointegration holds) | Scopus-grade extension |

---

## 5. Publication Constraints and Requirements

### 5.1 Target Journals

**Primary Target — UGC CARE (faster, India-focused):**
- **Arthshastra: Indian Journal of Economics & Research**
  - UGC CARE Group I
  - Accepts empirical India macroeconomics papers
  - Submission: via online portal (indianjournalofeconomicsandresearch.com)
  - Format: MS Word, APA/Chicago, 200-word abstract, 5 keywords, double-blind review
  - Author guidelines: https://indianjournalofeconomicsandresearch.com/index.php/aijer/gfa
  - Fees and review times: CHECK DIRECTLY on the website before submitting — fees and
    timelines change and must be verified at the time of submission

- **The Indian Economic Journal** (Indian Economic Association / SAGE)
  - UGC CARE listed, SAGE-published
  - Author instructions: https://journals.sagepub.com/author-instructions/iej
  - Suitable for India macroeconomics; moderate competition

**Secondary Target — Scopus (higher impact):**
- **International Journal of Energy Economics and Policy (IJEEP)**
  - Scopus indexed, directly covers oil-energy-inflation in developing economies
  - Author guidelines: https://econjournals.com/index.php/ijeep/about
  - Regularly publishes India-specific oil pass-through papers; directly on-topic

- **Journal of Quantitative Economics** (Indian Econometric Society)
  - Both UGC CARE and Scopus indexed
  - Ideal fit: India + econometrics

> IMPORTANT: All APC fees, review timelines, and acceptance rates should be verified live on
> each journal's official website before submission. These numbers change frequently and any
> specific figures in an AI-generated document may be outdated.

### 5.2 Non-Negotiable Submission Requirements (Universal)
- Original work not previously published (thesis/dissertation does not count as publication)
- Clear research question with testable hypothesis
- Transparent data section (sources, periods, transformations)
- All diagnostic tests reported (ADF, Breusch-Godfrey, Breusch-Pagan, RESET, CUSUM)
- Discussion of limitations — especially the failed headline Wald test, which MUST be discussed
  explicitly and honestly, not hidden or glossed over
- Properly formatted references in the journal's required citation style
- Plagiarism below the journal's threshold (typically 15–20%); the dissertation text must be
  substantially paraphrased, not copied directly into the article

### 5.3 Word Count and Structure for Journal Article
The dissertation is too long for direct submission. It must be compressed to:
- Abstract: 150–250 words
- Introduction: 500–700 words
- Literature Review: 600–800 words (keep only most relevant 12–15 papers)
- Data & Methodology: 800–1,000 words
- Results: 1,000–1,200 words
- Discussion & Conclusion: 500–700 words
- Total: ~4,500–5,500 words body text (excluding references and tables)

Key compression decisions:
- Keep only 2–3 tables in the main text (baseline, main model, key robustness)
- Move all sensitivity tables to an online supplement or appendix
- Merge the Discussion and Conclusion chapters into one section
- Cut the extended derivation of the model; cite Shin et al. (2014) and move on

---

## 6. Limitations to Acknowledge in the Paper

1. **CPI series construction:** Pre-2010 India CPI uses an OECD/FRED reconstructed series; the
   new CPI series starts only from January 2011. Robustness over the 2011–2024 sub-sample is
   advisable.

2. **IIP chain-linking:** The activity control involves a splice ratio across two IIP base years.
   Standard practice, but introduces measurement uncertainty.

3. **No demand-supply decomposition:** All oil price movements are treated identically. Kilian
   (2009) shows supply and demand shocks have different inflationary implications. This is an
   acknowledged limitation for causal interpretation.

4. **Short-run only (without Fix 6):** The ADL-in-differences model captures only short-run
   dynamics (months 0–3). Long-run cointegration is not modelled unless NARDL is added.

5. **Wald test failure — honest disclosure required:** Both the headline CPI and the Fuel & Light
   CPI asymmetry tests fail to reach 5% significance. The paper must frame this as a power and
   aggregation problem, not as evidence that asymmetry does not exist. The correct language:
   "We cannot statistically reject the null of symmetric pass-through at the 5% level in headline
   or energy CPI; however, the point estimates consistently show larger positive than negative
   pass-through, and the significant positive CPT⁺ (p = 0.034 in Fuel & Light) confirms the
   upward channel operates. The imprecision in the asymmetry test is consistent with limited statistical power, CPI aggregation structure (food at 39% dilutes the energy signal), and policy filtering (government excise adjustments partially buffer domestic prices). We cannot rule out that the true asymmetry is simply too small to detect at this sample size."

6. **Retail price policy:** Government excise adjustments partially insulate domestic prices from
   global oil movements and create the asymmetry through a political-economy mechanism, not purely
   through market prices. This mechanism is worth discussing explicitly.

---

## 7. Honest Paper Framing (Revised)

### 7.1 Main Contributions
1. The paper provides a 20-year asymmetric pass-through analysis spanning both fuel deregulation
   episodes (2010 petrol, 2014 diesel) — a genuine data contribution.
2. The Brent+EXR decomposition shows that exchange-rate pass-through is a distinct and
   significant channel alongside the global oil price channel.
3. The paper documents that the detectability of oil-CPI asymmetry is significantly affected by
   India's CPI aggregation structure (food at 39% dilutes the energy signal). This is itself a
   policy-relevant finding about India's inflation measurement.
4. Positive oil pass-through is statistically confirmed in the energy-sensitive CPI sub-index.

### 7.2 What the Paper Cannot Claim
- It cannot claim statistically significant rockets-and-feathers asymmetry at the 5% level using
  any currently estimated specification.
- It can claim: directionally consistent asymmetric point estimates, evidence of the positive
  channel, and an identification of why the Wald test lacks power.

### 7.3 Policy Implications
- RBI's inflation targeting should track the Fuel & Light CPI sub-index and the Brent+EXR
  decomposed pass-through, not only headline CPI, when responding to oil price shocks.
- The post-deregulation period (post-2014) shows closer oil-CPI linkage; monetary policy
  transmission analysis should account for this structural break.
- Government excise duty adjustments act as an asymmetric buffer: this mechanism both dampens
  oil pass-through AND creates measured asymmetry in retail fuel prices, which is partially
  observable in the CPI Fuel & Light sub-index.

---

## 8. Evaluation Criteria (for AI reviewers assessing this document)

1. **Is Brent+EXR decomposition theoretically justified?**
   - Check: Are Brent and EXR determined by different markets? (Yes — OPEC supply vs. RBI
     and capital flows)
   - Check: Is there an identification problem if Brent affects EXR? (Partial concern — but
     at monthly frequency, the co-movement is weak enough to estimate separately)

2. **Is the interaction model (Fix 3) correctly specified?**
   - Check: Is D_post interacted with all oil lag terms, or only the contemporaneous term?
     (Must be all lags for correct CPT computation)
   - Check: Is degrees-of-freedom adequate? (With T ≈ 230 post-lag-construction and ~28 total
     regressors in the full interaction model, borderline — use q = 2 oil lags in interaction)

3. **Is the PPAC retail price approach valid as a dependent variable model?**
   - Check: Is retail fuel price CPI-comparable? (PPAC is INR/litre; needs to be indexed)
   - Check: Does it suffer from the same Wald power problem? (Less so — retail prices transmit
     oil directly; less food noise)

4. **Is the DWB the right bootstrap for this setting?**
   - Yes, given: monthly time series, Newey-West HAC inference, mild serial correlation in
     residuals (Breusch-Godfrey test p marginally above 0.05 in many specifications)
   - Block bootstrap is a valid, simpler alternative if DWB implementation is difficult

5. **Is the NARDL approach valid given ADF pre-tests?**
   - Pre-condition: lnCPI and lnOil must be I(1). The existing ADF table should confirm this.
   - If I(0), NARDL is invalid and the ADL-in-differences approach is already correct.

6. **Is the overall paper publishable for UGC CARE with Fixes 0–4 only?**
   - Yes, with honest framing of the Wald test failure, a clear positive result (CPT⁺ significant
     in Fuel & Light at p = 0.034), the Brent+EXR result (p = 0.1443), and policy implications.
   - The deregulation interaction model (Fix 3) would substantially help even for UGC CARE.

---

## 9. Priority Action Sequence (Corrected from v1)

| Step | Action | Effort | Current Status |
|---|---|---|---|
| 0 | Correct all "Fuel & Light Wald p = 0.03" claims in the paper | None | ERROR — must fix now |
| 1 | Promote Brent+EXR to main model, demote INR-oil to benchmark | None (reframing) | Already computed |
| 2 | Download PPAC historical retail petrol/diesel prices, construct monthly series | Medium (1–2 days) | Not yet done |
| 3 | Estimate deregulation interaction model (Brent+EXR with D_post interactions) | Medium (1–2 days) | Not yet done |
| 4 | Implement Dependent Wild Bootstrap for asymmetry Wald test | Medium (1–2 days) | Not yet done |
| 5 | Add NOPI robustness (symmetric NOPI⁺ and NOPI⁻) with Kilian caveat | Low (1 day) | Not yet done |
| 6 | Food CPI control as robustness on post-2012 sub-sample only | Low | Not recommended as main fix |
| 7 | NARDL estimation (if targeting Scopus) | High (1–2 weeks) | Optional |
| 8 | Compress dissertation to journal article format (7,000 words) | Medium (3–5 days) | Not yet done |
| 9 | Plagiarism check and journal-specific formatting | Low (1 day) | Not yet done |
| 10 | Submit to Arthshastra (UGC CARE) or IJEEP (Scopus) | Minimal | Target: 3–4 weeks from now |

---

*Document version: 2 (corrected) | Date: April 2026*
*Author: Aniket Pandey | Supervisor: Prof. Shakti Kumar | Centre for Economic Studies and Planning, JNU*
*Corrections based on empirical checks against actual output tables and econometrics literature review.*
*Key references: Kilian & Vigfusson (2011, Quantitative Economics), Shao (2010, JRSS-B),*
*Shin, Yu & Greenwood-Nimmo (2014), Davidson & Monticini (2016), Hamilton (2003, J. Econometrics)*
