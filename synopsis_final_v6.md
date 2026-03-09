# ASYMMETRIC PASS-THROUGH OF GLOBAL BRENT CRUDE SHOCKS
## TO INDIA'S MONTHLY CPI INFLATION (2004–2024): A NARDL ANALYSIS

**Synopsis submitted to Jawaharlal Nehru University**
*in partial fulfilment of the requirements for the award of the degree of*
**MASTER OF SCIENCE IN ECONOMICS**

---

**Submitted by:** ANIKET PANDEY
**Submitted to:** PROF. SHAKTI KUMAR

Centre for Economic Studies and Planning
School of Social Sciences
JAWAHARLAL NEHRU UNIVERSITY
New Delhi – 110067
February 2026

---

## DATA AVAILABILITY AUDIT & SAMPLE PERIOD RATIONALE

Before proceeding to the synopsis, the following audit resolves all data availability conflicts. The chosen sample period of **April 2004 – December 2024 (N = 249 monthly observations)** is derived from the binding constraints identified below.

| Variable | FRED Series ID | Starts | Latest Obs. | Status |
|---|---|---|---|---|
| India CPI | INDCPIALLMINMEI (OECD via FRED) | Jan 2000 | Mar 2025 | ✓ No gap |
| Brent Crude Price | POILBREUSDM (IMF via FRED) | Jan 2003 | Jan 2026 | ✓ No gap in study window |
| INR/USD Exchange Rate | EXINUS monthly [Fed Reserve/FRED] | Jan 1973 | Feb 2026 | ✓ No gap |
| India IIP (demand control) | RBI DBIE — MoSPI, Base 2004-05 + Base 2011-12, Chain-linked by researcher | **Apr 2004 ★ (BINDING)** | Dec 2024 | ✓ Binding start. Both series in one sheet ('IIP Sector wise'). Spliced via overlap ratio (58-month overlap). FRED INDPROINDMISMEI ends Jan 2023 — do NOT use. |

**★ Binding Constraint:** The IIP series from RBI DBIE (Sector wise sheet) starts April 2004 (Base 2004-05). This is the earliest month for which a continuous, officially published IIP General Index exists in the RBI portal. It therefore determines the sample start date. POILBREUSDM (Brent) starts January 2003 and CPI/Exchange Rate series start even earlier, so all other variables fully cover the IIP window with no gaps.

**IIP Construction — Chain-Linking:** The IIP data is sourced from a single Excel file downloaded from RBI DBIE (data.rbi.org.in → Indicators → Real Sector Indicators → IIP Monthly), exported with both 'IIP-Industry-Base:2011-12' and 'IIP (Sector wise)' selected. The 'IIP (Sector wise)' sheet contains two sections: Base 2011-12 General Index (April 2012 – January 2026, rows 6–9) and Base 2004-05 General Index (April 2004 – January 2017, rows 14–18), with dates running right to left. The overlap period is April 2012 – January 2017 (58 months). Splice factor = mean(Base 2011-12 values during overlap) ÷ mean(Base 2004-05 values during overlap) = approximately 0.627. All Base 2004-05 values (April 2004 – March 2012) are multiplied by this factor. The Base 2011-12 series continues from April 2012 onwards. The result is one continuous IIP series (April 2004 – December 2024, N = 249) in consistent units, ready for log transformation.

**Why the base year difference is econometrically irrelevant:** After chain-linking, taking the natural log of IIP converts the remaining base-year level difference into an additive constant (ln(k·IIP) = ln(k) + ln(IIP)). This constant is absorbed entirely by the intercept term α in the NARDL specification. The short-run dynamics (ΔIIP) and the long-run cointegrating relationship are completely invariant to base-year choice. This is standard practice and requires no methodological qualification beyond the chain-linking note in Chapter 3.

**Why April 2004 – December 2024 is the ideal window for NARDL:**
- **N = 249** observations — well above the minimum (~80–100) required for robust NARDL estimation with monthly lags up to 12.
- **Covers all critical oil shocks:** China demand surge peak (2007–08), GFC spike ($147/bbl) and crash (2008–09), Arab Spring (2011), US Shale glut (2014–16), COVID-19 demand collapse (2020), Russia-Ukraine geopolitical spike (2022), and the 2023–24 moderation.
- **Covers both deregulation events:** Petrol deregulation (June 2010, step dummy D2010:06) and Diesel deregulation (October 2014, step dummy D2014:10).
- **Clean overlap:** All four series (CPI, Brent, Exchange Rate, chain-linked IIP) have complete data over April 2004 – December 2024 with zero gaps.

---

## Abstract

Crude oil is a critical driver of inflation in India, given the country's import dependency of approximately **87–88%** as of FY 2024–25 — one of the highest among large emerging economies. However, the transmission of global oil price shocks to domestic inflation is rarely symmetric. Real-world evidence consistently documents a *"Rockets and Feathers"* phenomenon: domestic prices rise sharply when global oil becomes expensive but fall sluggishly when it becomes cheap. Standard linear models fail to capture this asymmetry, producing misleading policy conclusions.

This dissertation investigates the asymmetric pass-through of global Brent crude oil prices to India's headline Consumer Price Index (CPI) over the period **April 2004 – December 2024 (N = 249 monthly observations)**. To ensure data consistency and avoid structural breaks caused by domestic base-year revisions, the study uses harmonized monthly data from internationally recognized sources: the IMF Primary Commodity Price database (via FRED, series POILBREUSDM) for oil prices, the OECD Main Economic Indicators (via FRED, series INDCPIALLMINMEI) for CPI, and the Federal Reserve's H.10 release (FRED, series EXINUS) for the INR/USD exchange rate. India's Index of Industrial Production (IIP) is constructed as a chain-linked series by splicing the RBI/MoSPI IIP Base 2004-05 General Index (April 2004 – March 2012) with the Base 2011-12 General Index (April 2012 – December 2024), using the overlap ratio method over their 58-month common period, sourced from the RBI Database on Indian Economy (DBIE).

Methodologically, the study employs the **Non-linear Autoregressive Distributed Lag (NARDL)** framework of Shin, Yu, and Greenwood-Nimmo (2014) to decompose Brent crude shocks into positive (x⁺) and negative (x⁻) partial sums. The analysis tests for long-run cointegration using the Pesaran et al. (2001) bounds test, estimates long-run asymmetric pass-through coefficients (β⁺ and β⁻), and computes dynamic multiplier graphs to visualize adjustment paths. The study specifically evaluates whether the deregulation of petrol (June 2010) and diesel (October 2014) prices increased the symmetry of pass-through. Findings are expected to provide actionable insights for the Reserve Bank of India's inflation forecasting under the flexible inflation targeting framework and for government excise duty policy during energy shocks.

**Keywords:** *Oil price pass-through, Asymmetric transmission, NARDL, CPI inflation, India, Fuel price deregulation, Rockets and Feathers, Cointegration*

---

## 1. Introduction

### 1.1 Background of the Study

Crude oil is the single most critical commodity in the global economy, acting as a primary determinant of cost structures in manufacturing, transport, and agriculture. For India, the relationship with oil is particularly sensitive. As of FY 2024–25, India imports approximately **87–88%** of its crude oil requirements (Ministry of Petroleum and Natural Gas, 2025), making it the world's third-largest oil consumer and one of the most oil-import-dependent large economies. This high dependency means that the Indian economy is effectively 'importing inflation' whenever global geopolitical or supply conditions tighten.

The period from **April 2004 to December 2024** (249 monthly observations) witnessed four structurally distinct global oil regimes that make this an ideal window for asymmetry analysis:

1. **The Demand Surge (2005–2008):** Rapid industrialization in China and India drove Brent prices from ~$55/barrel in 2005 to $147/barrel by July 2008.
2. **The GFC Shock (2008–2009):** Brent peaked at $147/barrel in July 2008 before crashing below $40/barrel within six months — one of the sharpest oil price reversals in history.
3. **The Supply Glut (2014–2016):** The US shale revolution caused prices to collapse from $110/barrel to below $30/barrel, coinciding with diesel deregulation in India.
4. **The Geopolitical Shock (2022):** Russia's invasion of Ukraine drove Brent above $120/barrel, directly testing pass-through in a fully deregulated pricing environment.

This study uses **monthly headline CPI** data, specifically inflation measured as the log-difference of the Consumer Price Index (Δ ln CPIₜ), to capture high-frequency price dynamics that annual data would mask.

### 1.2 The "Pass-Through" Mechanism

When global oil prices change, they affect Indian consumers through two channels:

- **Direct Channel:** Immediate changes in retail prices of petrol, diesel, and LPG, which are directly included in the CPI basket.
- **Indirect Channel (Second-Round Effects):** Higher fuel costs raise freight rates and manufacturing input costs, eventually feeding into prices of food, industrial goods, and services as transport costs are passed along supply chains.

Real-world observation, however, reveals a systematic asymmetry — the **"Rockets and Feathers"** puzzle (Bacon, 1991). When global oil prices spike, domestic pump prices and CPI rise almost immediately ('Rockets'). Yet when global prices crash, domestic inflation rarely falls with the same speed or magnitude ('Feathers').

India historically used the Administered Pricing Mechanism (APM) to insulate consumers from oil volatility. The deregulation of petrol in **June 2010** and diesel in **October 2014** theoretically enabled full market pass-through. This study rigorously tests whether asymmetry has diminished post-deregulation, a question with direct policy implications.

### 1.3 Policy Relevance

- **Monetary Policy:** The RBI's flexible inflation targeting framework (4% ± 2% CPI) requires accurate supply-shock forecasting. Asymmetric pass-through implies that tightening cycles need to be faster after oil surges than easing cycles after oil crashes.
- **Fiscal Policy:** The government systematically raises excise duties on petroleum when global prices fall (2014–2016, 2020), effectively absorbing the 'feather' effect. Quantifying this mechanism informs excise duty reform.
- **Welfare:** Since fuel and transport constitute a significant CPI share, downward price stickiness directly erodes household purchasing power, particularly for lower-income groups.

---

## 2. Statement of the Problem

The core problem is the **inadequacy of symmetric, linear models** in explaining India's inflation dynamics. Most prior empirical studies employ OLS regression or standard VAR models, which assume that the relationship between oil prices and inflation is linear and constant. Under this assumption:

- A +10% shock in oil prices increases inflation by X%.
- A −10% shock decreases inflation by exactly X%.

This symmetry assumption is empirically dangerous. If oil price increases cause large CPI spikes but decreases yield minimal relief, a linear model will report only an average, moderate effect — systematically underestimating the inflationary threat of an oil price surge and overestimating the disinflationary benefit of an oil price crash.

A secondary problem is **domestic data quality.** India's national CPI series has undergone multiple base-year revisions (2001, 2010, 2012), creating structural breaks that complicate long-run analysis. This study resolves both issues by:

1. **Modeling asymmetry explicitly** using the NARDL framework.
2. **Using harmonized OECD/IMF CPI data** from FRED (base 2015 = 100) to ensure a clean, unbroken monthly series from 2004 to 2024, and constructing a chain-linked IIP series from official RBI DBIE data to avoid the stale FRED IIP series.

---

## 3. Review of Literature

### 3.1 Theoretical Foundations

The "Rockets and Feathers" metaphor for asymmetric price adjustment was formalized by Bacon (1991) for UK gasoline markets. The theoretical basis for asymmetric pass-through draws from: (i) *menu cost models* (firms adjust prices more readily upward than downward); (ii) *search cost theory* (consumers search less when prices fall, reducing competitive pressure); and (iii) *market power* of oil marketing companies (IOC, BPCL, HPCL in India's case), which prefer to restore margins after cost increases faster than they reduce retail prices after cost decreases.

Hamilton (2003) demonstrated that oil price increases are robustly associated with economic recessions, while equivalent decreases do not necessarily trigger booms — pointing to an inherently non-linear macroeconomic response. Kilian (2009) further showed that disaggregating oil shocks into supply-driven and demand-driven components substantially changes their inflationary implications.

### 3.2 Empirical Evidence: Global Studies

The NARDL framework of Shin, Yu, and Greenwood-Nimmo (2014) introduced a rigorous econometric method for testing asymmetric cointegration and estimating dynamic multipliers. It has since been widely applied to oil-inflation pass-through. Asymmetric pass-through has been confirmed in many economies: Apergis and Miller (2009) for G7 countries; Pal and Mitra (2019) for BRICS; and Ftiti et al. (2016) for GCC countries. The consensus finding is that upward oil price transmission to inflation is significantly larger and faster than downward transmission.

### 3.3 The Indian Context

Early Indian studies operated under the APM era. Khundrakpam (2007) found that the exchange rate pass-through to inflation increased post-liberalization. Bhanumurthy, Das, and Bose (2012) documented that Oil Bonds issued by the government effectively dampened direct pass-through before 2010.

The post-deregulation literature is limited. Abu-Bakar and Masih (2018) applied NARDL to India for 2003–2018, finding statistically significant asymmetry with upward pass-through approximately 1.5 times larger than downward. Pradeep (2022) specifically studied the impact of diesel deregulation, finding that post-2014, the pass-through became more symmetric but asymmetry was not fully eliminated, owing to continuing government excise duty manipulation.

### 3.4 Research Gap

No existing study extends the NARDL framework for India to the full **2004–2024 window**, including: (i) the post-COVID inflation episode (2021–2022); (ii) the Russia-Ukraine oil shock (2022); and (iii) the subsequent Brent crude moderation (2023–2024). This dissertation fills this gap using a clean, harmonized dataset with a chain-linked IIP series covering the complete study period.

---

## 4. Objectives of the Study

1. **Estimate Long-Run Elasticity:** Quantify how much a 1% increase in global Brent prices increases India's CPI in the long run, separately for positive shocks (β⁺) and negative shocks (β⁻).
2. **Test for Long-Run Asymmetry:** Test whether the long-run pass-through coefficient for oil price hikes (β⁺) is statistically different from that for price drops (β⁻) using a Wald test.
3. **Test for Short-Run Asymmetry:** Examine whether the short-run adjustment dynamics also differ across positive and negative oil shocks.
4. **Analyze Adjustment Speed via Dynamic Multipliers:** Visualize the cumulative time path of CPI response to oil price changes — specifically, does the response to a price hike converge faster than to a price drop?
5. **Evaluate Deregulation Impact:** Using sub-sample analysis (pre-2014 vs. post-2014) and step dummies, assess whether the 2010 and 2014 fuel price reforms have reduced pass-through asymmetry.

---

## 5. Hypotheses

### Hypothesis 1: The Asymmetry Hypothesis (Long-Run)

> **H₀:** β⁺ = β⁻ (Symmetric long-run pass-through. The CPI responds identically in magnitude to oil price hikes and drops.)
>
> **H₁:** β⁺ ≠ β⁻ (Asymmetric pass-through. Specifically, we expect |β⁺| > |β⁻| — oil price hikes transmit more strongly to CPI than price drops.)

### Hypothesis 2: The Cointegration Hypothesis

> **H₀:** ρ = 0 (No cointegration. Oil prices and CPI do not share a long-run equilibrium relationship.)
>
> **H₁:** ρ < 0 (Cointegration exists. Oil prices and Indian CPI are cointegrated — they move together in the long run.)

### Hypothesis 3: The Deregulation Hypothesis

> **H₀:** The degree of asymmetry |β⁺ − β⁻| is not statistically different in the post-2014 sub-sample compared to the pre-2014 sub-sample.
>
> **H₁:** Fuel price deregulation (2010 and 2014) reduced the degree of asymmetric pass-through, resulting in |β⁺ − β⁻| being smaller in the post-2014 period.

---

## 6. Data Sources and Variables

### 6.1 Sample Period and Rationale

**Sample: Monthly, April 2004 – December 2024 (N = 249 monthly observations)**

The sample begins in **April 2004** because this is the earliest month for which India's official IIP General Index exists in a continuous, publicly accessible series from RBI DBIE (Base 2004-05 commences April 2004). This is the binding constraint; all other variables (POILBREUSDM from January 2003, INDCPIALLMINMEI from January 2000, EXINUS from January 1973) have full coverage from April 2004 with no gaps.

The sample ends **December 2024**, providing a complete calendar year that includes the full post-Russia-Ukraine oil price moderation cycle (2023–2024) — the critical 'feathers' episode that this study's asymmetry hypothesis depends on capturing. The sample of N = 249 monthly observations is well above the minimum required for stable NARDL estimation and supports a post-2014 sub-sample of 123 observations (October 2014 – December 2024, N = 123) for robustness analysis.

### 6.2 Variable Definitions and Sources

| Variable | Full Series Name & Source | FRED ID / Source | Transformation | Role in NARDL |
|---|---|---|---|---|
| **CPI (Dependent)** | Consumer Price Index: Total for India. OECD Main Economic Indicators via FRED. Base 2015 = 100, Not Seasonally Adjusted. | **INDCPIALLMINMEI** (OECD/FRED) — Avail: Jan 2000 – Mar 2025 | ln(CPIₜ) | Dependent variable (yₜ). Long-run level in NARDL ECM. |
| **Brent Crude (Main Regressor)** | Global Price of Brent Crude. IMF Primary Commodity Prices via FRED. USD per barrel, Not Seasonally Adjusted. | **POILBREUSDM** (IMF/FRED) — Avail: Jan 2003 – Jan 2026 | ln(Brentₜ) decomposed into x⁺ and x⁻ partial sums | Main regressor (xₜ). Nonlinearly decomposed into positive (Δx⁺) and negative (Δx⁻) partial sums. |
| **Exchange Rate (Control 1)** | Indian Rupees to U.S. Dollar Spot Exchange Rate. Federal Reserve H.10 Release. Monthly average. Not Seasonally Adjusted. | **EXINUS** *(Note: DEXINUS is the daily series. Use EXINUS for monthly data.)* (Fed Reserve/FRED) — Avail: Jan 1973 – Feb 2026 | ln(EXRₜ) | Control variable (zₜ). Entered linearly; depreciation raises the INR cost of oil imports. |
| **IIP (Control 2 — Demand Proxy)** | Chain-linked series. File: IIP.xlsx from RBI DBIE. Sheet: 'IIP (Sector wise)' — contains TWO sections in the same sheet. **Section 1 (rows 6–9):** Base 2011-12. Dates row 6, General Index row 9. Apr 2012 – Jan 2026. **Section 2 (rows 14–18):** Base 2004-05. Dates row 14, General Index row 18. Apr 2004 – Jan 2017. **Splice:** 58-month overlap Apr 2012–Jan 2017. Factor ≈ 0.627. Base 2004-05 values (Apr 2004–Mar 2012) × factor; Base 2011-12 appended from Apr 2012. ⚠ Do NOT use FRED INDPROINDMISMEI — frozen at Jan 2023. | **RBI DBIE** — data.rbi.org.in → Indicators → Real Sector → IIP → Monthly. Avail: Apr 2004–Dec 2024 (both series in one file). | ln(IIPₜ) (applied after chain-linking) | Control variable (wₜ). Monthly proxy for aggregate demand. Controls for demand-pull inflation confounding oil supply shocks. |
| **Policy Dummies** | Step dummies for fuel price deregulation events | Researcher-constructed | Binary (0/1) | **D₁:** = 0 before June 2010, = 1 from June 2010 (petrol deregulation). **D₂:** = 0 before October 2014, = 1 from October 2014 (diesel deregulation). Step dummies, not impulse dummies. |

#### IIP Chain-Linking Procedure — Step by Step

| Step | Action |
|---|---|
| 1 | Download IIP.xlsx from RBI DBIE. In the Export dialog select 'IIP (Sector wise)' and 'IIP-Industry-Base:2011-12'. Export as Excel. |
| 2 | Open the sheet named 'IIP (Sector wise)'. It contains TWO sections stacked vertically: (a) Base 2011-12: header/dates in row 6, General Index values in row 9. (b) Base 2004-05: header/dates in row 14, General Index values in row 18. Dates run RIGHT TO LEFT in both sections. |
| 3 | Extract Base 2011-12 General Index: read row 6 for dates, row 9 for values. Reverse both so time runs left to right. Gives April 2012 – January 2026. |
| 4 | Extract Base 2004-05 General Index: read row 14 for dates, row 18 for values. Reverse both so time runs left to right. Gives April 2004 – January 2017. |
| 5 | Identify overlap period: April 2012 – January 2017 (58 months). Both series have observations for all 58 months. |
| 6 | Compute splice factor = mean(Base 2011-12 values during overlap) ÷ mean(Base 2004-05 values during overlap). Verified result: ≈ 0.627315. |
| 7 | Apply splice: Multiply ALL Base 2004-05 values (April 2004 – March 2012) by splice factor. These are now in Base 2011-12 equivalent units. |
| 8 | Concatenate: joined_iip = [spliced Base 2004-05 values: Apr 2004 – Mar 2012] + [original Base 2011-12 values: Apr 2012 – Dec 2024]. Final series: 249 monthly observations, no gaps. |
| 9 | Verify: Plot the full joined series. No visible jump at March/April 2012 boundary. |
| 10 | Apply log transformation: ln_iip = log(joined_iip). This is the variable wₜ entering the NARDL model. |

*Table 1a: IIP Chain-Linking Procedure — Step by Step.*

**Why this is correct:** The overlap-ratio (or 'linking coefficient') method is the standard approach used by national statistics offices worldwide (including the OECD and CSO India) when rebasing index series. It preserves the growth rate dynamics of both series while expressing the older series in units comparable to the newer base year. After log transformation, any residual level difference is absorbed by the NARDL intercept. The resulting series is econometrically equivalent to a single-base IIP series for all NARDL purposes.

**Pre-processing note:** This chain-linking operation is performed once, prior to any econometric analysis, using a Python script. The output is a clean two-column file (date, iip_chained) covering April 2004 – December 2024 with N = 249 rows. This pre-processed file is what gets loaded into all R scripts — no further manipulation of the raw IIP.xlsx is ever needed during estimation.

### 6.3 Note on Exchange Rate Series

The correct FRED series for **monthly** INR/USD exchange rates is **EXINUS** (Indian Rupees to U.S. Dollar Spot Exchange Rate, Monthly). The series **DEXINUS** is the *daily* version and is not directly usable for monthly NARDL estimation without first computing monthly averages. Researchers should download EXINUS directly from FRED for a ready-to-use monthly series.

---

## 7. Research Methodology

### 7.1 Theoretical Framework: The NARDL Model

Following Shin, Yu, and Greenwood-Nimmo (2014), we begin from the linear ARDL(p, q) model and introduce asymmetry via the **partial sum decomposition** of the oil price variable. Define:

```
xₜ = ln(Brentₜ)

x⁺ₜ = Σ max(Δxₜ, 0) = cumulative sum of positive changes in log Brent (oil price hikes)
x⁻ₜ = Σ min(Δxₜ, 0) = cumulative sum of negative changes in log Brent (oil price drops)
```

The NARDL unrestricted error correction model (UECM) is:

```
Δyₜ = α + ρyₜ₋₁ + θ⁺x⁺ₜ₋₁ + θ⁻x⁻ₜ₋₁ + φ₁zₜ₋₁ + φ₂wₜ₋₁
      + Σγⱼ Δyₜ₋ⱼ
      + Σ(π⁺ⱼ Δx⁺ₜ₋ⱼ + π⁻ⱼ Δx⁻ₜ₋ⱼ)
      + Σ(δ₁ₖ Δzₜ₋ₖ + δ₂ₖ Δwₜ₋ₖ)
      + η₁D₁ₜ + η₂D₂ₜ + εₜ
```

| Symbol | Definition |
|---|---|
| yₜ | ln(CPIₜ) — the dependent variable (log-level of India's consumer price index) |
| x⁺ₜ, x⁻ₜ | Positive and negative partial sums of ln(Brentₜ) |
| zₜ | ln(EXRₜ) — log of INR/USD exchange rate (entered linearly) |
| wₜ | ln(IIPₜ) — log of India's Index of Industrial Production (aggregate demand control) |
| θ⁺, θ⁻ | Long-run coefficients on x⁺ and x⁻ in the ECM; long-run elasticities = β⁺ = −θ⁺/ρ and β⁻ = −θ⁻/ρ |
| ρ | Error correction coefficient (must be ρ < 0 for cointegration/convergence) |
| π⁺ⱼ, π⁻ⱼ | Short-run coefficients capturing immediate response of ΔCPI to Δx⁺ and Δx⁻ |
| D₁, D₂ | Step dummies for petrol deregulation (June 2010) and diesel deregulation (October 2014) |
| εₜ | White noise error term |

*Table 2: NARDL Model Notation Guide.*

### 7.2 Step-by-Step Estimation Procedure

#### Step 1: Unit Root Tests

Test all variables for stationarity using:
- **Augmented Dickey-Fuller (ADF)** — tests for unit roots with drift/trend.
- **Phillips-Perron (PP)** — robust to heteroskedasticity in errors.
- **KPSS** — null of stationarity (complement to ADF/PP). Essential to confirm variables are I(0) or I(1), not I(2) — NARDL requires no I(2) variables.

*Expected outcome: All variables are I(1) in levels and I(0) in first differences.*

#### Step 2: Structural Break Detection

- **Zivot-Andrews Test** — endogenously identifies a single structural break in the series without imposing a break date a priori.
- If break dates differ from the policy dummies (June 2010, October 2014), assess whether additional dummies are warranted (e.g., COVID-19 shock: April 2020).

#### Step 3: Lag Selection

Optimal lag length p is selected using the **Akaike Information Criterion (AIC)** with a maximum lag of **12 months** (following Shin et al., 2014, and consistent with monthly data frequency). This step is critical because NARDL results are sensitive to lag length specification.

#### Step 4: NARDL Estimation via OLS

Estimate the UECM via OLS. The OLS estimator is consistent in the presence of I(1) regressors in ARDL/NARDL settings (Pesaran & Shin, 1999).

#### Step 5: Bounds Test for Cointegration

Apply the Pesaran, Shin, and Smith (2001) bounds test. Test the null H₀: ρ = θ⁺ = θ⁻ = φ₁ = φ₂ = 0 (no levels relationship). If the F-statistic exceeds the I(1) critical bound, cointegration is confirmed.

#### Step 6: Wald Tests for Asymmetry

- **Long-Run Asymmetry:** Wald test H₀: β⁺ = β⁻ (i.e., θ⁺/ρ = θ⁻/ρ).
- **Short-Run Asymmetry:** Wald test H₀: Σπ⁺ⱼ = Σπ⁻ⱼ.

#### Step 7: Dynamic Multipliers

Compute and plot cumulative dynamic multipliers to visualize the response path of CPI to a unit positive vs. unit negative shock in oil prices. The multiplier asymmetry plot will graphically confirm or reject the 'Rockets and Feathers' hypothesis.

#### Step 8: Diagnostic Tests

| Test | Null Hypothesis | Purpose |
|---|---|---|
| Breusch-Godfrey LM | No serial correlation in residuals | Model adequacy |
| Breusch-Pagan / White | Homoskedasticity of residuals | OLS efficiency |
| CUSUM / CUSUM² | Parameter stability over time | Structural stability |
| Ramsey RESET | No functional form misspecification | Nonlinearity check |
| Jarque-Bera | Normally distributed residuals | Inference validity |

*Table 3: Diagnostic Test Summary.*

#### Step 9: Robustness Checks

- **Sub-sample analysis:** Pre-2014 (Apr 2004 – Sep 2014, N = 126) vs. Post-2014 (Oct 2014 – Dec 2024, N = 123).
- **Alternative Brent measure:** MCOILBRENTEU (Brent - Europe, daily averaged to monthly) as a cross-check on POILBREUSDM.
- **Alternative lag specification:** BIC-selected lags vs. AIC-selected lags.
- **COVID-19 dummy:** Add impulse dummy for April 2020 (extreme demand collapse) as a sensitivity check.

### 7.3 Identification Strategy

Global Brent crude prices are **largely exogenous** to India: India is a price-taker in global oil markets (≈3.5% of global consumption, OPEC not a member). However, global demand shocks — particularly from China — can jointly affect both Brent prices and Indian industrial demand. To address this:

- **IIP is included** as a control to absorb demand-side variation common to global and Indian cycles.
- **Lagged regressors** in the NARDL specification mitigate simultaneity bias inherent in contemporaneous estimation.
- **Brent's exogeneity** relative to India CPI is supported by a small-open-economy argument standard in the Indian inflation literature (Bhanumurthy et al., 2012; Pradeep, 2022).

### 7.4 Justification for Linear Entry of Exchange Rate

The exchange rate (ln EXRₜ) enters the model linearly. Theoretically, one might consider decomposing it into rupee appreciation and depreciation episodes given RBI's asymmetric intervention (the RBI intervenes more aggressively during depreciation than appreciation). However, for parsimony — and because exchange rate asymmetry is not the primary research question — we enter it linearly. A decomposed exchange rate will be evaluated as a **robustness check** in the dissertation and reported in an appendix.

### 7.5 Software

- **Primary:** R via Google Colab (Runtime → Change runtime type → R). All econometric work is done in **one single R script** (`nardl_analysis.R`) that runs top-to-bottom in sequence. No separate scripts for different steps — everything from data loading to final output is in one file.
- **R packages required:**

```r
install.packages(c(
  "nardl", "urca", "tseries", "strucchange", "dynlm",
  "ggplot2", "dplyr", "readxl", "zoo", "lmtest",
  "sandwich", "forecast", "car", "stargazer", "gridExtra",
  "ggfortify", "scales", "patchwork"
))
```

### 7.6 R Script Specification — Console Logging and Output Requirements

The single R script must implement the following two requirements throughout every section:

---

#### Requirement 1: Console Logging

Every section of the script must print clear progress markers and full results to the console. The AI writing the script must follow this logging pattern at every step:

```
cat("\n============================================================\n")
cat("STEP 1: LOADING AND MERGING DATA\n")
cat("============================================================\n")
# ... code ...
cat(">> CPI loaded: rows =", nrow(cpi), "| date range:", ...)
cat(">> Brent loaded: rows =", nrow(brent), ...)
cat(">> Exchange Rate loaded:", ...)
cat(">> IIP chained loaded:", ...)
cat(">> Merged dataset: N =", nrow(df), "| Apr 2004 to Dec 2024\n")
cat(">> Partial sums computed. x_pos range:", range(df$x_pos), "\n")
cat(">> Step dummies created. D1 sum =", sum(df$D1), "| D2 sum =", sum(df$D2), "\n")
```

Logging requirements by section:
- **Data loading:** Print row count, date range, and first/last values of each loaded series.
- **Descriptive stats:** Print full summary() output for all variables to console.
- **Unit root tests:** Print complete test output (test statistic, critical values, p-value, conclusion) for every variable in every test (ADF, PP, KPSS).
- **Structural break:** Print Zivot-Andrews break date and statistic.
- **Lag selection:** Print AIC table for all lag combinations tested, print selected lag.
- **NARDL estimation:** Print full model summary (coefficients, standard errors, t-stats, p-values, R², adjusted R², F-statistic).
- **Bounds test:** Print F-statistic, critical bounds (I(0) and I(1) at 1%, 5%, 10%), and conclusion (cointegrated / not cointegrated).
- **Long-run coefficients:** Print β⁺, β⁻, their standard errors and p-values.
- **Wald tests:** Print W-statistic and p-value for long-run and short-run asymmetry.
- **Diagnostic tests:** Print test statistic and p-value for every diagnostic (BG, BP, RESET, JB).
- **Robustness:** Print sub-sample N counts, β⁺ and β⁻ for each sub-sample, comparison table.
- **All plots saved:** Print filename of every plot as it is saved.

---

#### Requirement 2: Plots, Diagrams, and Tables — Complete List

The script must automatically generate and save every output below. All plots saved as high-resolution PNG (300 dpi, minimum 1800×1200 px) to a folder called `dissertation_outputs/`. All tables saved as CSV and also printed to console via stargazer or knitr::kable equivalent.

**Section A — Data and Descriptive (Chapter 3 figures)**

| Output | Filename | Description |
|---|---|---|
| Plot 1 | `fig1_time_series_all_variables.png` | 4-panel time series: ln(CPI), ln(Brent), ln(EXR), ln(IIP) on same timeline, shaded bands marking pre/post deregulation periods (June 2010, October 2014) |
| Plot 2 | `fig2_brent_raw_with_events.png` | Brent crude price (USD/bbl) with labelled event markers: GFC peak (Jul 2008), GFC crash (Dec 2008), Arab Spring (2011), Shale glut (2014), COVID crash (Apr 2020), Russia-Ukraine spike (Mar 2022) |
| Plot 3 | `fig3_cpi_inflation_series.png` | Month-on-month CPI inflation (Δ ln CPI × 100) as bar chart with mean line |
| Plot 4 | `fig4_partial_sums.png` | 2-panel: x⁺ (cumulative positive Brent changes) and x⁻ (cumulative negative Brent changes) over time |
| Plot 5 | `fig5_correlation_matrix.png` | Correlation heatmap of all variables: ln(CPI), ln(Brent), ln(EXR), ln(IIP), x⁺, x⁻ |
| Table 1 | `table1_descriptive_stats.csv` | Summary statistics: mean, SD, min, max, skewness, kurtosis for all variables |

**Section B — Unit Root and Structural Break (Chapter 4.1–4.2 figures)**

| Output | Filename | Description |
|---|---|---|
| Table 2 | `table2_unit_root_results.csv` | Full ADF, PP, KPSS results for all variables — test stats, critical values, conclusion (I(0)/I(1)) |
| Plot 6 | `fig6_zivot_andrews.png` | Zivot-Andrews test plot for ln(CPI) and ln(Brent) showing test statistics across candidate break dates with critical value line |

**Section C — NARDL Estimation (Chapter 4.3–4.5 figures)**

| Output | Filename | Description |
|---|---|---|
| Table 3 | `table3_bounds_test.csv` | Bounds test F-statistic vs. Pesaran et al. (2001) critical bounds at 1%, 5%, 10% — cointegration conclusion |
| Table 4 | `table4_nardl_full_results.csv` | Full NARDL coefficient table: short-run and long-run coefficients, SE, t-stat, p-value |
| Table 5 | `table5_longrun_asymmetry.csv` | β⁺, β⁻, Wald test W-statistic and p-value, conclusion |
| Plot 7 | `fig7_dynamic_multipliers.png` | Cumulative dynamic multiplier plot: positive shock (solid) vs. negative shock (dashed) with 95% CI bands and asymmetry gap shaded. This is the signature "Rockets and Feathers" figure for the dissertation. |
| Plot 8 | `fig8_longrun_coeff_comparison.png` | Bar chart comparing β⁺ vs. β⁻ with error bars (confidence intervals) |

**Section D — Diagnostics (Chapter 4.6 figures)**

| Output | Filename | Description |
|---|---|---|
| Plot 9 | `fig9_residuals_plot.png` | 4-panel residual diagnostic: (a) residuals vs. fitted, (b) ACF of residuals, (c) PACF of residuals, (d) histogram of residuals with normal curve overlay |
| Plot 10 | `fig10_cusum.png` | CUSUM test plot with 5% significance bands |
| Plot 11 | `fig11_cusum_sq.png` | CUSUM-squared test plot with 5% significance bands |
| Table 6 | `table6_diagnostic_tests.csv` | All diagnostic test results: BG LM (serial correlation), BP (heteroskedasticity), RESET (functional form), JB (normality) — statistic and p-value |

**Section E — Robustness (Chapter 4.7 figures)**

| Output | Filename | Description |
|---|---|---|
| Plot 12 | `fig12_subsample_comparison.png` | Side-by-side dynamic multiplier plots: pre-2014 sub-sample (left) vs. post-2014 sub-sample (right) — shows whether asymmetry changed after deregulation |
| Table 7 | `table7_subsample_results.csv` | β⁺, β⁻, Wald statistic for full sample, pre-2014, and post-2014 sub-samples in one comparison table |
| Table 8 | `table8_robustness_summary.csv` | β⁺ and β⁻ across all robustness variants: baseline AIC, BIC lags, alternative Brent (MCOILBRENTEU), with/without COVID dummy |

**Total outputs: 12 plots + 8 tables = 20 files**, all saved automatically to `dissertation_outputs/` by the script.

---

## 8. Expected Contribution and Scope

### 8.1 Expected Contributions

1. **Temporal:** First study to apply NARDL to India's full 2004–2024 monthly CPI data, including the Russia-Ukraine (2022) and post-COVID oil moderation (2023–24) episodes.
2. **Methodological:** Rigorous treatment of asymmetry using both long-run (Wald) and dynamic multiplier evidence, with proper step dummies for policy breaks.
3. **Data Quality:** Uses internationally harmonized OECD/IMF data to overcome domestic CPI base-year revision breaks, with IIP sourced from the official RBI DBIE (avoiding the stale OECD FRED series).
4. **Policy:** Sub-sample analysis directly quantifies the deregulation dividend — whether Indian consumers have benefited from more symmetric oil pass-through post-2014.

### 8.2 Expected Findings

- Statistically significant long-run cointegration between Brent crude and India's CPI.
- Significant asymmetry: |β⁺| > |β⁻|, consistent with the 'Rockets and Feathers' hypothesis.
- Post-2014 sub-sample: Reduced asymmetry relative to pre-2014, but not full symmetry (government excise duty absorption of downward oil movements continues).
- Dynamic multipliers: Positive oil shock CPI response peaks within 3–6 months; negative shock response is slower and smaller.

### 8.3 Scope and Limitations

- The study uses headline CPI (all items). Disaggregated analysis by sub-index (food, transport, core) is beyond the scope of this dissertation but is noted for future research.
- The model does not control for global supply chain shocks independently of oil prices (post-COVID disruptions may introduce partial collinearity).
- NARDL as applied here assumes a single threshold (zero) for positive vs. negative oil changes. Regime-switching extensions (e.g., Markov-switching NARDL) are a natural extension.
- Coverage ends December 2024; ongoing post-2024 data is not incorporated.

---

## 9. Chapter Plan

| Chapter | Content |
|---|---|
| **Chapter 1** | Introduction — Background, Pass-Through Mechanism, Policy Relevance, Research Questions |
| **Chapter 2** | Review of Literature — Theoretical Foundations, Global Evidence, Indian Context, Research Gap |
| **Chapter 3** | Data and Methodology — 3.1 Data Sources, Variable Definitions, and Sample Period Justification; 3.2 Descriptive Statistics, Trend Analysis, and Correlation Matrix; 3.3 NARDL Model Derivation and Partial Sum Decomposition; 3.4 Full Estimation Procedure (Steps 1–9) |
| **Chapter 4** | Empirical Analysis and Results — 4.1 Unit Root Test Results (ADF, PP, KPSS table); 4.2 Structural Break Test Results (Zivot-Andrews); 4.3 Bounds Test for Cointegration; 4.4 Long-Run and Short-Run NARDL Estimates; 4.5 Dynamic Multiplier Graphs; 4.6 Diagnostic Tests; 4.7 Robustness Checks and Sub-Sample Analysis |
| **Chapter 5** | Discussion of Findings — 5.1 The 'Rockets and Feathers' Effect in India's Post-Deregulation Era; 5.2 Impact of 2010 and 2014 Deregulation Reforms on Asymmetry; 5.3 Exchange Rate vs. Oil Price Channels: Which Dominates?; 5.4 Comparison with Prior Literature (Abu-Bakar & Masih 2018; Pradeep 2022) |
| **Chapter 6** | Conclusion and Policy Recommendations — 6.1 Summary of Major Findings; 6.2 Implications for RBI Monetary Policy; 6.3 Implications for Government Fiscal Policy (excise duty reform); 6.4 Implications for Household Welfare; 6.5 Limitations and Scope for Future Research |

---

## 10. Research Timeline (5-Month Plan)

| Month | Tasks | Deliverable |
|---|---|---|
| **Month 1** | Literature review (30+ papers). Download and clean all data: (a) POILBREUSDM, INDCPIALLMINMEI, EXINUS from FRED as CSV (full series from Jan 2000, trimmed to Apr 2004 inside R); (b) iip_chained.xlsx already pre-processed via Python chain-linking script (splice factor ≈ 0.627, 58-month overlap). Place all 4 data files in one folder. Write opening sections of nardl_analysis.R: load all data, merge by date, trim to N=249, compute partial sums of ln(Brent), create step dummies D1 (June 2010) and D2 (October 2014). Run descriptive stats section — verify console prints all series, date ranges, N=249 confirmed. Generate Figures 1–5 and Table 1. | Chapters 1–2 draft; clean merged dataset (N=249); dissertation_outputs/ folder with first 5 figures and descriptive table |
| **Month 2** | Add unit root and structural break sections to nardl_analysis.R. Run ADF, PP, KPSS for all variables. Run Zivot-Andrews. Select AIC lag. Confirm all results print to console with test statistics and critical values. Generate Figure 6 and Table 2. Begin NARDL estimation section of script. | Chapter 3 draft; unit root and break results in console and CSV |
| **Month 3** | Complete NARDL estimation, bounds test, Wald tests, dynamic multipliers in nardl_analysis.R. Confirm console prints full coefficient table, F-statistic, β⁺, β⁻, Wald p-values. Generate Figures 7–11 and Tables 3–6. | Chapter 4 draft; all core results tables and multiplier figures |
| **Month 4** | Add sub-sample and robustness sections to nardl_analysis.R. Generate Figures 12 and Tables 7–8. Full script now runs end-to-end in one execution, saving all 20 outputs to dissertation_outputs/. Write Chapters 5 and 6. | Chapters 5–6 draft; complete outputs folder with all 20 files |
| **Month 5** | Final revisions, formatting, supervisor feedback incorporation, bibliography finalization, submission. | Complete dissertation |

---

## 11. Bibliography

*(APA 7th Edition format)*

Abu-Bakar, M., & Masih, M. (2018). Is the oil price pass-through to domestic inflation symmetric or asymmetric? New evidence from India based on NARDL. *MPRA Paper No. 87569*. University Library of Munich.

Apergis, N., & Miller, S. M. (2009). Do structural oil-market shocks affect stock prices? *Energy Economics, 31*(4), 569–575. https://doi.org/10.1016/j.eneco.2009.03.001

Bacon, R. W. (1991). Rockets and feathers: The asymmetric speed of adjustment of UK retail gasoline prices to cost changes. *Energy Economics, 13*(3), 211–218. https://doi.org/10.1016/0140-9883(91)90010-R

Bhanumurthy, N. R., Das, S., & Bose, S. (2012). Oil price shock, pass-through policy and its impact on India. *NIPFP Working Paper Series, No. 99*. National Institute of Public Finance and Policy.

Ftiti, Z., Guesmi, K., Teulon, F., & Chouachi, S. (2016). Relationship between crude oil prices and economic growth in selected OPEC countries. *Journal of Applied Business Research, 32*(1), 11–22.

Hamilton, J. D. (2003). What is an oil shock? *Journal of Econometrics, 113*(2), 363–398. https://doi.org/10.1016/S0304-4076(02)00207-5

Khundrakpam, J. K. (2007). Economic reforms and exchange rate pass-through to domestic prices in India. *BIS Working Papers, No. 225*. Bank for International Settlements.

Kilian, L. (2009). Not all oil price shocks are alike: Disentangling demand and supply shocks in the crude oil market. *American Economic Review, 99*(3), 1053–1069. https://doi.org/10.1257/aer.99.3.1053

Kilian, L., & Park, C. (2009). The impact of oil price shocks on the U.S. stock market. *International Economic Review, 50*(4), 1267–1287. https://doi.org/10.1111/j.1468-2354.2009.00568.x

Ministry of Petroleum and Natural Gas. (2025). *Annual report 2024–25*. Government of India.

Mishra, B. R., & Mishra, P. (2012). Oil prices and the Indian economy. *Journal of Academic Research in Economics, 4*(3), 301–320.

Pal, D., & Mitra, S. K. (2019). Asymmetric oil price transmission to the purchasing power of consumers in BRICS nations. *Energy Economics, 84*, 104506. https://doi.org/10.1016/j.eneco.2019.104506

Pesaran, M. H., & Shin, Y. (1999). An autoregressive distributed lag modelling approach to cointegration analysis. In S. Strøm (Ed.), *Econometrics and Economic Theory in the 20th Century: The Ragnar Frisch Centennial Symposium* (pp. 371–413). Cambridge University Press.

Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing approaches to the analysis of level relationships. *Journal of Applied Econometrics, 16*(3), 289–326. https://doi.org/10.1002/jae.616

Pradeep, S. (2022). Impact of diesel price reforms on asymmetricity of oil price pass-through to inflation: Indian perspective. *Journal of Economic Asymmetries, 26*, e00266. https://doi.org/10.1016/j.jeca.2022.e00266

Reserve Bank of India. (2025). *Database on Indian Economy (DBIE): Index of Industrial Production*. https://dbie.rbi.org.in

Shin, Y., Yu, B., & Greenwood-Nimmo, M. (2014). Modelling asymmetric cointegration and dynamic multipliers in a nonlinear ARDL framework. In R. Sickles & W. Horrace (Eds.), *Festschrift in Honor of Peter Schmidt* (pp. 281–314). Springer.

---

*Note: FRED series INDPROINDMISMEI (OECD via FRED) is NOT cited in this study. India's IIP data is sourced directly from the RBI DBIE repository to ensure complete temporal coverage through 2024.*
