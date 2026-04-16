---
name: Build improved-v2 pipeline
overview: Build a new `improved-v2/` Python pipeline implementing the publication-ready India oil-to-CPI pass-through model per `suggestions.md`, with automated FRED data fetching + caching, the full model hierarchy (M1 headline + mechanism chain), diagnostics, bootstrap, robustness, and publication-quality outputs.
todos:
  - id: setup
    content: Create improved-v2/ directory structure, config.py, helpers.py, requirements.txt
    status: pending
  - id: data-loader
    content: "Build data_loader.py: FRED auto-download with caching, PPAC Excel parsing, MoSPI Fuel & Light fetch with cache fallback"
    status: pending
  - id: variable-builder
    content: "Build variable_builder.py: merge, trim to study window, construct oil_inr, Mork decomposition, NOPI, lags, policy dummies"
    status: pending
  - id: unit-roots
    content: "Build unit_roots.py: ADF/PP/KPSS battery + Zivot-Andrews structural break test"
    status: pending
  - id: models
    content: "Build models.py: M0 symmetric baseline, M1 asymmetric INR headline, M2 Brent+EXR robustness, M2-AIC0, M3 interaction"
    status: pending
  - id: diagnostics
    content: "Build diagnostics.py: BG(12), BP, HAC-RESET, recursive/OLS CUSUM, comparative diagnostic table"
    status: pending
  - id: bootstrap
    content: "Build bootstrap.py: restricted-residual block bootstrap for Wald asymmetry test on M1"
    status: pending
  - id: mechanism
    content: "Build mechanism_chain.py: 3-stage dilution chain (PPAC -> Fuel & Light -> Headline CPI)"
    status: pending
  - id: robustness
    content: "Build robustness.py: NOPI, post-2011, pre/post 2014, COVID, winsorized, rolling window, lag grid"
    status: pending
  - id: descriptives-figures
    content: "Build descriptives.py + figures.py: summary stats tables, all publication-quality figures"
    status: pending
  - id: runner
    content: Build run_all.py master script that executes the full pipeline in order
    status: pending
isProject: false
---

# Build improved-v2 Publication Pipeline

## Context

The existing `improved/` directory is an R pipeline that produced results deemed non-publishable. The `suggestions.md` file provides a detailed handoff with specific model hierarchy, claim discipline, and paper structure for a UGC-journal-ready India time-series paper.

The new `improved-v2/` will be a **Python pipeline** that:

- Follows `suggestions.md` strictly: M1 (INR oil) as headline, PPAC + Fuel & Light as mechanism chain, M2 as robustness only
- Downloads and **caches** all FRED data on first fetch
- Reads existing PPAC Excel files from `data/raw/`
- Fetches CPI Fuel & Light from MoSPI API with caching
- Produces all tables (CSV) and figures (PNG) needed for the paper

## Data Strategy

**Auto-downloaded via FRED API (cached to `data/raw/` on first fetch):**

- `INDCPIALLMINMEI` (India CPI, monthly) -- already exists as CSV
- `POILBREUSDM` (Brent crude, monthly) -- already exists as CSV
- `EXINUS` (INR/USD exchange rate, monthly) -- already exists as CSV

Use the `fredapi` Python package with a FRED API key (free, instant registration). On first run, download and save to `data/raw/`. On subsequent runs, read from cache. **You will need a FRED API key** -- get one free at https://fred.stlouisfed.org/docs/api/api_key.html and set it as `FRED_API_KEY` environment variable.

**Already available locally (no download needed):**

- `data/raw/iip_chained.xlsx` -- chain-linked IIP from `chain_link_iip.py`
- `data/raw/ppac_rsp_pre2017.xls` -- PPAC pre-2017 retail fuel prices
- `data/raw/ppac_rsp_post2017.xlsx` -- PPAC post-2017 retail fuel prices

**Fetched via MoSPI API (cached to `data/processed/`):**

- CPI Fuel & Light sub-index (group code 5) -- cached file already exists at `data/processed/cpi_fuel_light.csv`

## Directory Structure

```
improved-v2/
  run_all.py            # Master runner
  config.py             # All paths, constants, study window
  data_loader.py        # FRED download + cache, PPAC loading, MoSPI fetch
  variable_builder.py   # Mork decomposition, lags, dummies, NOPI
  descriptives.py       # Tables 1-2, Figures 1-3
  unit_roots.py         # ADF, PP, KPSS, Zivot-Andrews
  models.py             # M0, M1 (headline), M2 (robustness), M3 (interaction)
  diagnostics.py        # BG, BP, HAC-RESET, CUSUM
  bootstrap.py          # Block bootstrap for Wald asymmetry test
  mechanism_chain.py    # PPAC + Fuel & Light + dilution chain (Stages 1-3)
  robustness.py         # NOPI, subsamples, COVID, winsorized, rolling, lag grid
  figures.py            # All publication figures
  helpers.py            # NW-HAC, Wald tests, CPT computation, formatting
  requirements.txt      # Pinned dependencies
  outputs/
    tables/
    figures/
```

## Model Hierarchy (per `suggestions.md` Section 4)

**Main headline model (M1):**

- `dlnCPI ~ AR(p, AIC-selected) + dlnOil_pos_L0..L3 + dlnOil_neg_L0..L3 + dlnIIP + dummies`
- Oil = Brent x EXR (INR-denominated), Mork decomposition
- Newey-West HAC inference throughout
- Must pass: BG serial correlation, HAC-RESET, CUSUM stability

**Mechanism chain (main evidence):**

- Stage 1: Brent USD -> PPAC Retail Petrol (Delhi) -- strongest pass-through
- Stage 2: PPAC Petrol -> CPI Fuel & Light -- retail-to-CPI channel
- Stage 3: Oil -> Headline CPI -- attenuation/dilution

**Robustness only (M2):**

- Brent + EXR decomposition (separate oil and exchange rate channels)
- M2-AIC0 transparency benchmark

**Appendix/remove:**

- M3 interaction, NARDL, dynamic multipliers -- not in main text

## Key Python Packages

```
pandas, numpy, matplotlib, seaborn
statsmodels          # OLS, HAC, ADF/PP/KPSS, diagnostic tests
arch                 # Zivot-Andrews, additional unit root tests
fredapi              # FRED data download
openpyxl, xlrd       # Excel reading (PPAC, IIP)
scipy                # Bootstrap, statistical tests
```

## Diagnostic / Acceptance Rules (per `suggestions.md` Section 5)

Every main model must satisfy:

- Estimated on 20+ years of data (Apr 2004 - Dec 2024, ~249 obs)
- Serial correlation: Breusch-Godfrey LM(12) p > 0.05
- Functional form: HAC-RESET p > 0.05 (not OLS-RESET)
- Stability: Recursive CUSUM within 5% bounds
- Asymmetry claims backed by bootstrap (not just point Wald)

## Data Caching Logic

```python
def load_or_fetch_fred(series_id, filepath):
    if os.path.exists(filepath):
        return pd.read_csv(filepath, parse_dates=['date'])
    # Download from FRED API
    data = fred.get_series(series_id)
    data.to_csv(filepath)
    return data
```

Same pattern for MoSPI Fuel & Light: check `data/processed/cpi_fuel_light.csv` first, only hit API if missing or stale.

## What You Need to Do Manually

1. **FRED API key**: Register free at https://fred.stlouisfed.org/docs/api/api_key.html, then `export FRED_API_KEY=your_key_here`
2. **PPAC data**: Already present at `data/raw/ppac_rsp_pre2017.xls` and `data/raw/ppac_rsp_post2017.xlsx` -- no action needed
3. **IIP data**: Already present at `data/raw/iip_chained.xlsx` -- no action needed
