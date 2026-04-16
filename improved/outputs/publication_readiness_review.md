# Publication Readiness Review

Date: 16 April 2026

Project: Oil price pass-through to India's CPI inflation, 2004-2024

## Short verdict

The improved pipeline is better than the earlier single-script analysis, but the paper should not be submitted with M2 as the sole primary model. M2 is useful as a Brent plus exchange-rate decomposition, yet it fails HAC-RESET and recursive CUSUM. The publishable version should be reframed as:

1. Conservative headline CPI evidence using M1, the INR-denominated oil model.
2. Mechanism evidence using PPAC retail petrol and CPI Fuel and Light.
3. A dilution/attenuation argument explaining why headline CPI effects are weaker than fuel-price effects.

This can be shown to the professor. It is not ready to claim a strong 5 percent asymmetry result for headline CPI.

## Why the earlier model passed but M2 failed

The earlier headline model used INR-denominated oil. That variable combines Brent and the exchange rate into the actual rupee cost exposure faced by India. It is less decomposed, but more stable in this sample. In the improved pipeline, M1 passes the key publication diagnostics:

- HAC-RESET p = 0.1827
- Recursive CUSUM p = 0.0910
- OLS-CUSUM p = 0.3876
- BG(12) p = 0.0728

M2 splits Brent and INR/USD. This is more interpretable, but it asks the data to separately identify oil and exchange-rate transmission over a structurally unstable period. M2 diagnostics fail:

- HAC-RESET p = 0.0128
- Recursive CUSUM p = 0.0337

The specification search confirms the issue. Brent+EXR with q=0 is diagnostic-safe, but it gives no positive oil pass-through. Brent+EXR with q=3 gives the more plausible positive pass-through, but that is exactly where RESET/CUSUM fail. Therefore, M2 should be robustness/decomposition evidence, not the core published claim.

## Model hierarchy to use

Use `table_24_publication_decision.csv` as the decision record.

- M1 INR oil ADL(p,3): main headline CPI model. It is diagnostic-safe, but the asymmetry is weak.
- M2 Brent+EXR ADL(p,3): robustness/decomposition. Report cautiously because diagnostics fail.
- M2-AIC0: transparency benchmark only. It passes better but gives no oil pass-through.
- M3 interaction: regime-change motivation only. The regime test is significant, but the equation fails diagnostics.
- PPAC petrol: strongest mechanism result. Direct retail fuel pass-through is large and diagnostic-safe.
- CPI Fuel and Light: mechanism result. Positive oil pass-through is significant and diagnostic-safe.
- NARDL: appendix only or remove from claims. ECT is positive, so the ECM interpretation is invalid.

## What aligns with the literature

Pradeep (2022) studies diesel reforms and finds that fuel-price policy changes altered asymmetric pass-through to retail diesel, wholesale prices, and aggregate consumer prices. That supports our focus on policy regimes and the finding that aggregate CPI is weaker than the direct fuel channel: https://ideas.repec.org/a/eee/joecas/v26y2022ics170349492200010x.html

NIPFP's report on oil price shocks in India explicitly models import, price, and fiscal channels and shows that higher domestic pass-through increases inflation pressure. That supports our channel-based framing rather than relying on one headline CPI coefficient: https://www.nipfp.org.in/publication-index-page/report-index-page/oil-price-shock-and-its-impact-on-india/

Choi et al. (2018) find that global oil price increases raise domestic inflation on average and that the effect is asymmetric, but also that transport weights and energy subsidies explain cross-country differences. This supports the dilution/channel interpretation: https://ideas.repec.org/a/eee/jimfin/v82y2018icp71-96.html

The 2026 SAGE/FIIB NARDL paper for India reports long-run oil-price asymmetry for WPI and no significant short-run asymmetry. This is close to our situation: short-run aggregate inflation asymmetry is hard to prove, especially with CPI rather than WPI: https://journals.sagepub.com/doi/10.1177/23197145261421703

RBI's summary of the revised CPI weighting diagram shows why headline CPI dilution is expected: Food and beverages has 45.86 percent combined weight, while Fuel and Light has only 6.84 percent. This supports our result that pass-through is large at PPAC petrol, smaller in Fuel and Light, and weakest in headline CPI: https://www.rbi.org.in/scripts/PublicationsView.aspx?id=16216

The UGC-CARE situation must be clarified with the professor. UGC's 584th meeting minutes state that no UGC-CARE listing of journals will be maintained or published by UGC going forward. The professor may mean a department-recognized journal list or an older CARE-listed journal: https://www.ugc.gov.in/pdfnews/5563038_MINUTES-584th-Meeting-of-the-Commission.pdf

## Roadblocks before submission

1. The abstract and conclusion must stop saying M2 is the primary result.
2. Do not claim "oil price increases raise CPI more than decreases lower it" as a proven 5 percent result.
3. NARDL dynamic multipliers must not be used because the ECT sign is invalid.
4. The paper should foreground mechanism and attenuation: Brent to PPAC petrol, PPAC petrol to Fuel and Light, then weak headline CPI.
5. Journal choice must be checked carefully. A five-day window is realistic for professor submission or journal submission, not for acceptance/publication.

## Five-day rescue plan

Day 1: Rewrite abstract, methods, and results around M1 plus the dilution mechanism.

Day 2: Replace all "primary M2" wording with the model hierarchy in `table_24_publication_decision.csv`.

Day 3: Add literature framing around diesel deregulation, fuel subsidies/taxes, CPI basket weights, and disaggregated pass-through.

Day 4: Clean tables and figures. Keep NARDL in appendix only if space permits; otherwise remove it from the main paper.

Day 5: Send to professor with a cover note saying the headline asymmetry is weak, but the fuel-channel and dilution findings are defensible.
