# Literature Benchmarking: CPI vs WPI Results and Dissertation-Safe Interpretation

## Purpose of this note

This note benchmarks the current project results against the available India-focused oil pass-through literature and rewrites the interpretation in a form that is safer for dissertation submission and later journal targeting.

It is **not** a formal systematic review. It is a working benchmark memo based on the project outputs and widely cited studies on India oil-price transmission.

---

## 1. What was run in this project

There are currently two main empirical tracks:

1. **CPI pipeline**: `improved-v2`
   - Sample: April 2004 to December 2024
   - Main framing: oil transmission into headline CPI through retail fuel and Fuel & Light
   - Main headline model: asymmetric ADL in differences using INR-denominated oil
   - Long-run test: ARDL bounds test only
   - Main advantage: satisfies the professor's 20+ year condition with a defensible India-only monthly sample
   - Main limitation: headline CPI response is weak and asymmetry is not supported

2. **WPI pipeline**: `wpi`
   - Headline sample: May 1983 to March 2026
   - Fuel & Power sample: May 1995 to March 2026
   - NARDL appendix sample: April 1997 to March 2025
   - Main framing: oil pass-through into wholesale inflation with long historical coverage
   - Main advantage: much stronger fit with the Indian oil–inflation literature and a much longer sample
   - Main limitation: some long-run claims require careful caveats; fuel ADL has a functional-form warning

---

## 2. Bottom-line comparison

### CPI pipeline (`improved-v2`)

The CPI pipeline is **usable**, but only with modest claims.

Main findings:

- headline CPI pass-through is small
- positive oil-shock pass-through is not significant at 5% in the preferred headline model
- short-run asymmetry is not supported
- bootstrap inference confirms the lack of short-run asymmetry
- Granger evidence is only marginal at the 10% level for oil leading headline CPI
- ARDL bounds evidence does **not** support a strong levels relationship at 5%

Interpretation:

> This is better framed as a **transmission-and-dilution paper** than as a paper proving strong asymmetric pass-through to headline CPI.

### WPI pipeline (`wpi`)

The WPI pipeline is **much stronger** and is the better basis for a dissertation or paper if your supervisor allows WPI as the main inflation measure.

Main findings:

- headline WPI pass-through is small but statistically significant
- fuel pass-through is much larger than headline pass-through
- short-run asymmetry is not supported in ADL
- bootstrap inference confirms the ADL symmetry result
- 4-lag Granger-predictive evidence suggests oil leads WPI, with no reverse feedback
- post-2010 pass-through is materially larger than pre-2010
- NARDL models suggest strong cointegration and long-run asymmetry
- the long-run adjustment speed in headline WPI is slow and must be discussed carefully

Interpretation:

> The WPI pipeline is broadly consistent with the India pass-through literature and is the strongest empirical component in the project.

---

## 3. Key numerical results from the current outputs

## 3.1 CPI headline results

Preferred headline CPI model (`improved-v2`, M1):

- CPT+ = 0.0213, p = 0.1220
- CPT− = 0.0006, p = 0.9375
- asymmetry Wald p = 0.2408
- bootstrap p = 0.4997

This means:

- the estimated headline CPI effect is economically small
- the positive-shock effect is only weakly suggestive, not conventionally significant
- the core asymmetry claim fails in short-run CPI data

Supporting mechanism results are much stronger:

- Brent -> retail petrol: CPT+ = 0.3459, p < 0.001
- retail petrol -> CPI Fuel & Light: CPT+ = 0.1777, p = 0.0021
- oil -> headline CPI: CPT+ = 0.0213, p = 0.1220

This supports a **dilution chain**:

> strong transmission into retail fuel, weaker transmission into Fuel & Light, and very weak transmission into headline CPI.

## 3.2 WPI headline and fuel results

Headline WPI ADL:

- CPT+ = 0.0301, p = 0.0240
- CPT− = 0.0374, p = 0.0012
- asymmetry Wald p = 0.6727
- bootstrap p = 0.7461

Fuel & Power WPI ADL:

- CPT+ = 0.2866, p < 0.001
- CPT− = 0.2677, p < 0.001
- asymmetry Wald p = 0.7832
- bootstrap p = 0.8196

Interpretation:

- headline WPI responds significantly to oil shocks
- the fuel sector responds much more strongly than headline WPI
- the evidence does **not** support short-run asymmetry in either ADL specification

## 3.3 WPI subsample evidence

Headline WPI, pre-2010:

- CPT+ = 0.0117, p = 0.3812
- CPT− = 0.0253, p = 0.0430
- asymmetry p = 0.4836

Headline WPI, post-2010:

- CPT+ = 0.0741, p = 0.0043
- CPT− = 0.0813, p < 0.001
- asymmetry p = 0.7884

Fuel & Power WPI, pre-2010:

- CPT+ = 0.0922, p = 0.1679
- CPT− = 0.2379, p < 0.001
- asymmetry p = 0.1424

Fuel & Power WPI, post-2010:

- CPT+ = 0.5241, p < 0.001
- CPT− = 0.4376, p < 0.001
- asymmetry p = 0.2272

Interpretation:

> Post-2010 pass-through is materially larger than pre-2010, which is consistent with deregulation and more market-linked pricing.

Important caveat:

> These split-sample contrasts are strongly suggestive, but by themselves they are not a formal causal proof that deregulation caused the increase.

---

## 4. Comparison with published India-focused research

The literature below is the most relevant benchmark for this project.

### 4.1 Bhoi, Bhattacharyya, and Mandal (2012)

Main message:

- India is different from many economies because administered pricing historically muted or delayed pass-through
- pass-through rose once domestic prices adjusted more frequently to international oil prices
- inflation effects can be stronger in more market-linked periods

Project match:

- **Yes, broadly consistent**
- especially consistent with the WPI post-2010 strengthening
- also consistent with the idea that pass-through rises when pricing becomes more flexible

### 4.2 Abu-Bakar and Masih (2018, MPRA)

Main message:

- ARDL may miss nonlinear long-run effects
- NARDL can detect asymmetric long-run pass-through even when simpler ARDL results look weak
- positive oil shocks matter more than negative shocks in some specifications

Project match:

- **Broadly consistent in spirit**
- CPI pipeline ARDL bounds evidence is weak
- WPI NARDL appendix finds long-run asymmetry even though short-run ADL asymmetry is absent

Important caveat:

> This paper is a useful benchmark, but it is not the same sample, variable construction, or software implementation as this project. So it should be used as supportive comparison, not as a one-to-one replication claim.

### 4.3 Pradeep (2022, Journal of Economic Asymmetries)

Main message:

- diesel deregulation changed the pass-through process
- reform reduced asymmetry in some sectors
- reform increased transmission speed and changed sectoral behavior
- aggregate consumer inflation effects are weaker than direct fuel-channel effects

Project match:

- **Strongly consistent**
- your CPI mechanism chain fits this very well
- your WPI post-2010 increase in pass-through also fits this reform narrative
- your results similarly suggest that sectoral/fuel effects are stronger than broad headline effects

### 4.4 Other India evidence on external shocks and inflation

A recurring pattern in India-focused work is:

- WPI reacts more strongly than CPI to oil and external price shocks
- exchange-rate-adjusted oil measures often perform better than USD oil alone
- fuel or wholesale baskets show clearer transmission than all-items CPI
- deregulation and tax-policy changes matter for pass-through magnitude

Project match:

- **Very consistent**
- your CPI results are weak at headline level but stronger in the fuel channel
- your WPI results are much cleaner and more publishable as direct oil pass-through evidence

---

## 5. Where the project aligns with literature

The following claims are reasonably well supported.

### 5.1 WPI is more responsive than CPI

This is one of the clearest patterns in both this project and the broader India literature.

Project evidence:

- headline CPI preferred model: small and statistically weak
- headline WPI model: small but statistically significant
- fuel WPI model: large and highly significant

Safe statement:

> The project supports the standard view that oil-price transmission is easier to detect in WPI and fuel-sensitive price indices than in headline CPI.

### 5.2 Short-run asymmetry is weak or absent in the project data

Project evidence:

- CPI headline asymmetry p = 0.2408, bootstrap p = 0.4997
- WPI headline asymmetry p = 0.6727, bootstrap p = 0.7461
- WPI fuel asymmetry p = 0.7832, bootstrap p = 0.8196

Safe statement:

> In the short-run ADL framework used here, the data do not support asymmetry.

### 5.3 Post-reform pass-through is stronger

Project evidence:

- headline WPI pass-through rises sharply after 2010
- fuel WPI pass-through rises very strongly after 2010
- CPI mechanism chain shows strong transmission in retail fuel and weaker transmission into headline CPI

Safe statement:

> The post-2010 estimates are materially larger and are consistent with the deregulation narrative in the Indian literature.

### 5.4 Fuel-channel effects are stronger than headline effects

Project evidence:

- CPI: Brent -> retail petrol and petrol -> Fuel & Light are much larger than oil -> headline CPI
- WPI: Fuel & Power pass-through is far larger than headline WPI pass-through

Safe statement:

> Oil transmission in India appears to operate most clearly through fuel-sensitive channels, with attenuation by the time the shock reaches aggregate headline inflation.

---

## 6. What should be treated cautiously

This is the most important part for dissertation safety.

## 6.1 Do not claim a “perfect” literature match

Even though the broad story is similar to the literature, the current project is **not** a formal replication of any one paper.

Safer wording:

- use “broadly consistent”
- use “in line with”
- use “similar to”
- avoid “perfect,” “textbook-perfect,” “universal,” or “exact replication”

## 6.2 Do not say Zivot-Andrews “confirmed” a structural break in `ln(WPI)`

The WPI outputs provide a break date candidate, but the test result is marked as a failure to reject.

So the safe interpretation is:

> Zivot-Andrews suggests a candidate break location, but does not by itself provide formal confirmation of a structural break in the WPI level series.

## 6.3 Do not overstate the KPSS issue

For WPI:

- `ln(WPI)` looks I(1) in the conventional sense
- `dln(WPI)` is strongly stationary by ADF and PP
- KPSS on `dln(WPI)` is still high

Safe interpretation:

> The unit-root evidence for `dln(WPI)` is mixed: ADF and PP strongly support stationarity, while KPSS rejects it. In a long sample with regime shifts, this may reflect KPSS size distortion or break sensitivity, but that explanation should be presented as plausible rather than proven.

## 6.4 Do not over-interpret the Bai-Perron break

The Bai-Perron result near 2013-09 is useful, but it is not definitive proof that deregulation caused the break.

Safe interpretation:

> The break timing is suggestive of regime change near the reform window and is consistent with the institutional narrative, but it should not be presented as direct causal proof.

## 6.5 Do not treat Granger results as structural causality

Safe interpretation:

> The Granger results indicate predictive precedence, not deep structural causation.

This is especially important in the write-up.

## 6.6 Be careful with NARDL headline error-correction speed

The WPI NARDL appendix gives:

- headline Brent ECT = -0.0189
- headline INR-oil ECT = -0.0170
- fuel ECT = -0.0811

These imply:

- slow monthly adjustment in headline WPI
- faster adjustment in Fuel & Power

Safe interpretation:

> The ECT signs are negative and statistically significant, supporting cointegration in the NARDL appendix. However, the implied headline adjustment speed is slow and is likely specification-sensitive. This should be discussed cautiously rather than compared mechanically with every published estimate.

## 6.7 Fuel ADL should carry a caveat

The fuel WPI result is economically strong, but the preferred fuel ADL fails a functional-form check.

Safe interpretation:

> The fuel-sector result is informative and economically large, but it should be reported with a functional-form caveat.

---

## 7. Dissertation-safe verdict on each pipeline

## 7.1 CPI pipeline verdict

### Strengths

- India-only monthly time-series
- satisfies the 20+ year requirement
- mechanism chain is interesting and policy-relevant
- diagnostics support the preferred headline CPI model
- bootstrap backs the conclusion of no short-run asymmetry

### Weaknesses

- weak direct headline CPI pass-through
- no convincing short-run asymmetry
- bounds test does not support strong long-run levels relationship at 5%
- Fuel & Light series is shorter than the headline sample
- this is not the best platform for a strong headline inflation asymmetry paper

### Best way to frame it

> Use CPI as a **transmission-and-dilution study**, not as a paper claiming strong asymmetric oil pass-through into headline CPI.

Suggested title direction:

> Oil Price Transmission into India’s Headline CPI: Evidence on Fuel-Channel Dilution, 2004–2024

## 7.2 WPI pipeline verdict

### Strengths

- 30+ years for fuel and 40+ years for headline WPI
- much stronger statistical results
- highly consistent with India pass-through literature
- good diagnostics in headline WPI models
- clear pre/post-2010 strengthening
- direct relevance for wholesale inflation transmission

### Weaknesses

- some long-run interpretations need caveats
- fuel ADL has a RESET warning
- WPI is less directly consumer-welfare oriented than CPI
- NARDL should remain supplementary, not the sole basis of the paper

### Best way to frame it

> Use WPI as the main empirical paper if your supervisor accepts wholesale inflation as the preferred inflation measure for a long-horizon India oil pass-through dissertation.

Suggested title direction:

> Oil Price Pass-Through to India’s Wholesale Inflation: Evidence from a 43-Year Monthly Time Series

---

## 8. Which one is better for your dissertation?

If your professor's primary requirement is:

- **time-series analysis**
- **at least 20–30 years**
- and a path toward a publishable paper

then the current evidence suggests:

### Best empirical choice: **WPI pipeline**

Why:

- it clearly exceeds the duration requirement
- it is much closer to the established India literature
- the results are stronger and more coherent
- it gives a cleaner publication story

### Best fallback if CPI must be retained: **CPI pipeline with dilution framing**

Why:

- it still satisfies the minimum time requirement
- it has a disciplined India-only design
- it supports a strong mechanism story even though headline CPI effects are weak

---

## 9. Recommendation on the 30-year requirement

You asked whether data can be made for a 30-year period covering the most important timeline.

### Practical answer

For this project, the best existing 30-year-plus design is already in the `wpi` pipeline:

- headline WPI: about 43 years
- Fuel & Power WPI: about 31 years
- NARDL appendix: about 28 years

This is already better than trying to mechanically force headline CPI into a 30-year monthly series using weaker or inconsistent reconstruction.

### Recommendation

- **Do not artificially stretch CPI** just to hit 30 years
- **Use WPI for the long historical paper**
- if needed, keep CPI as a secondary or complementary chapter showing why wholesale and fuel transmission is stronger than headline consumer inflation

---

## 10. Suggested publication strategy

## Option A: Strongest path

Main paper based on WPI.

Core claim:

> Oil shocks pass through significantly into India’s wholesale inflation, especially in fuel-sensitive sectors, with stronger transmission after deregulation and little evidence of short-run asymmetry.

Why this is publishable:

- long monthly sample
- clear institutional story
- literature alignment
- disciplined claims

## Option B: Safer CPI path

Main paper based on CPI transmission-and-dilution.

Core claim:

> Oil shocks transmit strongly into retail fuel and fuel-sensitive components but attenuate sharply before reaching headline CPI in India.

Why this is publishable:

- does not overclaim weak CPI headline results
- still uses 20+ years
- links directly to tax, deregulation, and retail pricing channels

---

## 11. Final verdict

### Main empirical conclusion

The project is **not doing something fundamentally wrong**.

The main results are economically sensible and broadly consistent with Indian oil pass-through research:

- WPI responds more clearly than CPI
- fuel channels are much stronger than headline inflation
- post-reform transmission is stronger
- short-run asymmetry is weak in your ADL setups
- long-run asymmetry may exist in supplementary nonlinear levels models

### Best dissertation conclusion

> The WPI pipeline is the stronger and more literature-aligned foundation for a dissertation or paper targeting a 20–30+ year Indian time-series requirement. The CPI pipeline remains useful, but only when framed as a transmission-and-dilution study rather than as strong evidence of headline CPI asymmetry.

### Safest submission language

Use language like:

- “broadly consistent with prior India-focused studies”
- “suggestive of stronger post-reform transmission”
- “predictive Granger evidence”
- “supplementary NARDL evidence”
- “reported with diagnostic caveats where applicable”

Avoid language like:

- “perfect match”
- “textbook-perfect”
- “universal finding”
- “confirmed causality”
- “proved reform caused the break”

---

## 12. One-paragraph summary you can reuse in the dissertation

A comparison of the project outputs with the India-focused oil pass-through literature suggests that the results are broadly credible and institutionally plausible. The CPI-based pipeline over 2004–2024 supports a transmission-and-dilution interpretation, with strong pass-through into retail fuel and weaker propagation into Fuel & Light and headline CPI. By contrast, the WPI-based pipeline over 1983–2026 provides stronger direct evidence of oil-price pass-through, especially in Fuel & Power, and shows materially larger pass-through in the post-2010 period consistent with the deregulation narrative. Short-run asymmetry is not supported in the ADL specifications, while the nonlinear levels models provide supplementary evidence of long-run asymmetry that should be interpreted cautiously. Overall, the WPI framework is the stronger basis for a long-horizon dissertation and a more credible candidate for eventual journal submission.