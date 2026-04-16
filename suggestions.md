# Final Publication Handoff — India Oil Pass-Through Paper
## Project: Oil Price Pass-Through to India's Inflation
### Author context: Aniket Pandey | MS Economics, JNU
### Rewrite date: 16 April 2026

---

## 1. Professor Constraint

This paper must use:

- time-series analysis or panel analysis
- data spanning at least 20 years
- preferably 20-30 years if defensible

### Default Compliance Decision

The default path is:

- India-only time-series
- monthly sample from April 2004 to December 2024
- approximately 20.75 years of data
- 249 monthly observations before lag trimming

This satisfies the minimum duration requirement without changing the research question.

Panel analysis is not recommended by default because it changes the paper from an India pass-through paper into a cross-country inflation paper.

Decision: The final paper should remain an India time-series paper unless the supervisor explicitly asks for a panel redesign.

---

## 2. Final Recommendation

The paper should not be positioned as a strong proof that headline CPI asymmetry is established in India.

The final publishable version should be positioned as:

- a 20+ year India monthly time-series study
- focused on oil transmission through retail fuel and Fuel & Light
- showing attenuation into headline CPI
- treating headline CPI asymmetry as secondary and suggestive, not definitive

### Recommended Core Contribution

The paper should answer this question:

How do global oil shocks transmit through retail fuel prices and the Fuel & Light CPI sub-index into headline inflation in India over a 20+ year monthly sample, and where does the pass-through weaken?

### Why this is the best publication path

- It respects the professor's 20+ year requirement.
- It stays India-specific.
- It uses the strongest parts of the existing evidence.
- It aligns with what stronger published papers do: one core empirical story, disciplined scope, and restrained claims.

Decision: The final paper should be a transmission-and-dilution paper, not a pure headline-CPI asymmetry paper.

---

## 3. What Published Papers Do Right

### A. De and Mallik (2024, IIMB Management Review)

What they do well:

- keep the paper India-specific
- define the institutional setting clearly, especially fuel pricing and exchange-rate exposure
- use one coherent empirical framework rather than too many disconnected models
- justify extra modelling choices through diagnostics
- link results to actual policy institutions rather than abstract asymmetry alone

What to copy:

- institution-first framing
- tight India context
- clean statement of data and model purpose
- cautious interpretation when direct CPI effects are weak

What not to copy:

- adding extra method families unless they materially improve the core result

### B. Syzdykova et al. (2022, IJEEP)

What they do well:

- use one narrow method for one narrow claim
- keep the result structure simple
- do not force all countries into the same conclusion
- allow country-specific outcomes

What to copy:

- one method family in the main text
- one main claim
- country-specific restraint

What not to copy:

- broad cross-country framing, because this paper should remain India-only unless the topic is changed

### C. SDMIMD 2022 Conference Paper

What it does well:

- states the broad policy importance of oil clearly
- lists objectives directly

What it does poorly:

- too broad for the evidence
- too dependent on generic regression logic
- weak validation relative to its conclusions
- mixes GDP and inflation without a tight identification strategy

Lesson:

- keep its clarity of motivation
- reject its broad regression style and overclaiming

Decision: The final paper should imitate the discipline of the journal papers, not the breadth of the conference paper.

---

## 4. Recommended Paper Design

### Default Design

- country: India
- method class: time-series
- frequency: monthly
- main sample: April 2004 to December 2024
- core structure: asymmetric ADL plus transmission chain

### Main Empirical Narrative

Stage 1:

- oil shock -> PPAC retail petrol

Stage 2:

- PPAC retail petrol -> CPI Fuel & Light

Stage 3:

- fuel channel / oil shock -> headline CPI attenuation

### Main Model Hierarchy

Use the following hierarchy.

#### Main headline model

- M1: INR-denominated oil asymmetric ADL

Reason:

- diagnostic-safe relative to alternatives
- directly reflects domestic currency oil exposure
- suitable for the final headline CPI section

#### Main mechanism models

- PPAC retail petrol model
- CPI Fuel & Light model
- dilution chain summary

Reason:

- these are the strongest and most publishable results in the current pipeline
- they show where transmission is strong and where it weakens

#### Robustness only

- M2: Brent plus exchange-rate decomposition
- M2-AIC0
- M3 interaction

Reason:

- informative, but not strong enough to be the main claim-bearing specification

#### Appendix only or remove

- NARDL A and B
- dynamic multipliers from invalid ECMs
- excessive sensitivity checks that do not protect the final claim

Decision: Build the final paper around M1 plus the mechanism chain, with M2 only as secondary decomposition evidence.

---

## 5. Non-Negotiable Model Acceptance Rules

Any main model used in the paper must satisfy all of the following:

1. estimated on at least 20 years of data
2. economically interpretable
3. comparable on a common and explicitly stated sample
4. not contradicted by its own diagnostics

### Diagnostic rules for a main specification

For a model to remain in the main text as a claim-bearing model, it must pass or be defensible on:

- serial correlation diagnostics
- HAC-robust specification check
- stability diagnostics
- claim consistency with bootstrap or equivalent inference restraint

### Current decision under these rules

#### Accept for main text

- M1 headline model
- PPAC petrol mechanism model
- Fuel & Light mechanism model

#### Do not use as sole main model

- M2 Brent plus exchange-rate decomposition because HAC-RESET and recursive CUSUM fail

#### Do not use for substantive long-run claims

- NARDL because ECT is positive and the ECM interpretation is invalid

Decision: No model that fails the acceptance rules can be the paper's lead result, even if its coefficient is larger.

---

## 6. Duration Rule for Model Eligibility

Any main model must be estimated on a sample with at least 20 years of data.

If two candidate models are otherwise similar, prefer the one with:

1. longer defensible sample
2. cleaner data continuity
3. better diagnostics
4. simpler interpretation

### Critical warning

Do not extend the sample mechanically if doing so requires:

- mixing inconsistent inflation series
- weak or undocumented splicing
- unsupported retail fuel series
- controls that are not comparable through time

Decision: Duration matters, but defensibility matters more than mechanically chasing a longer sample.

---

## 7. Data and Measurement Rules

### Default data window

- April 2004 to December 2024

### Required series for the default design

- headline CPI inflation
- Brent oil price
- INR/USD exchange rate
- output/activity control
- PPAC retail petrol
- CPI Fuel & Light

### Source discipline

The next AI must explicitly state source precedence for each series and freeze the final sample before final estimation.

### Current known data issues

1. Fuel & Light CPI may rely on cached processed data when the MoSPI API is unavailable.
2. Headline CPI continuity before 2011 needs to be discussed carefully if OECD/FRED reconstruction is used.
3. PPAC history is strong enough for the current sample, but should not be stretched casually into older unsupported periods.
4. AIC comparisons must be made on the same sample, not across sample shifts.

### Rule on longer-history redesign

If a longer 25-30 year design is attempted, the next AI must first verify continuity of:

- headline inflation series
- oil price series
- exchange rate series
- activity/output control

If a 25-30 year monthly design is not defensible, prefer:

- a longer but lower-frequency India time-series

rather than:

- a panel redesign by default

Decision: The default sample is April 2004 to December 2024; only change it if continuity is demonstrably stronger.

---

## 8. Keep / Remove / Appendix

### Keep in main text

- the 20+ year India time-series framing
- M1 as the headline CPI model
- PPAC retail petrol pass-through evidence
- Fuel & Light pass-through evidence
- dilution chain interpretation
- bootstrap restraint on asymmetry claims
- institutional discussion of petrol deregulation, diesel deregulation, daily pricing, COVID, and fuel-tax episodes

### Keep as robustness only

- M2 Brent plus exchange-rate decomposition
- M2-AIC0 transparency benchmark
- selected stability or subsample discussion only if needed to defend the final narrative

### Move to appendix only

- M3 interaction
- post-2011 subsample
- pre/post-2014 subsamples
- winsorized and no-COVID checks
- lag grid table, unless it is needed for a specific methodology defense

### Remove from the final paper if space is tight

- NARDL tables and discussion
- dynamic multiplier discussion
- NOPI discussion
- rolling-window results
- long internal workflow descriptions
- output-file inventories
- old pipeline history

Decision: The main text should keep only what directly supports the final 20+ year India time-series claim.

---

## 9. Known Errors and Illogical Points to Fix

The next AI must explicitly fix or guard against the following:

### A. Logic errors

- calling M2 primary while its key diagnostics fail
- using larger coefficients as a substitute for model validity
- treating weak asymmetry evidence as proof
- letting robustness models dominate the main text
- using an invalid NARDL ECM for long-run interpretation

### B. Calculation and comparability issues

- AIC comparisons must be on the same estimation sample
- candidate main models must be compared after freezing one final sample window
- no cross-sample fit comparison should be used as decisive evidence

### C. Manuscript-source issue

- `dissertation.tex` exists, but the referenced `chapters/*.tex` files are not present in the workspace
- therefore, the next AI must not assume a full manuscript source tree is available
- the current empirical outputs, not the LaTeX structure, should be treated as the source of truth

### D. Claim discipline issue

- do not say "headline CPI asymmetry is established"
- do not say "NARDL proves long-run asymmetry"
- do not imply that one marginal 10% result is enough for a strong publication claim

Decision: Any final draft that does not explicitly eliminate these errors is not submission-ready.

---

## 10. Allowed Claims and Forbidden Claims

### Allowed claims

- positive oil pass-through to headline CPI is suggestive, not definitive
- direct transmission is strong at the retail fuel stage
- Fuel & Light shows clearer pass-through than headline CPI
- headline CPI dilutes fuel shocks because most of the basket is not direct energy
- the evidence supports an attenuation or dilution mechanism
- separating Brent and INR/USD is informative but diagnostically less stable

### Forbidden claims

- headline CPI asymmetry is proven at the 5% level
- M2 is the primary model
- NARDL validates a long-run asymmetry result
- every robustness check points in the same direction
- a longer sample is automatically better regardless of continuity

Decision: The final paper must use restrained claim language throughout.

---

## 11. Panel Is Not the Default

Panel analysis is acceptable in principle only if the research question is rewritten.

Panel should be used only if:

- the paper is changed from India-specific pass-through to cross-country comparative inflation transmission
- comparable 20-30 year inflation and oil datasets are assembled consistently across countries
- the contribution statement is rewritten for comparative macroeconomics

Otherwise:

- stay with India time-series

Decision: Do not switch to panel unless the supervisor explicitly asks for a comparative paper.

---

## 12. Only Use If Supervisor Rejects the 2004-2024 Monthly Design

If the supervisor insists on something closer to 25-30 years, follow this sequence:

1. test whether a longer India monthly headline inflation series can be defended without weak splicing
2. test whether output/activity and retail fuel controls can be kept consistent over the longer span
3. if not, consider a longer lower-frequency India time-series
4. do not switch to panel just to satisfy the duration preference

Decision: The 2004-2024 monthly sample is the default. A longer sample is a fallback, not the current baseline.

---

## 13. Workflow for the Next AI

The next AI should follow these steps in order:

1. freeze the final paper question as an India 20+ year time-series paper
2. freeze the final sample window and source precedence
3. compare candidate main models on one common sample
4. keep only models that satisfy the acceptance rules
5. write the paper around M1 plus the mechanism chain
6. demote M2 to decomposition robustness
7. remove NARDL from the main claim structure
8. rewrite abstract, results, discussion, and conclusion in restrained language
9. only after the final narrative is fixed, decide what appendix material survives

Decision: The next AI should not begin by polishing text. It should first lock the model hierarchy and claim hierarchy.

---

## 14. Final One-Sentence Instruction for the Next AI

Produce a journal-ready India time-series paper using at least 20 years of data, centered on oil transmission and CPI dilution, with M1 as the headline model, PPAC and Fuel & Light as the main mechanism evidence, M2 only as robustness, and no claim that headline CPI asymmetry is conclusively proven.

