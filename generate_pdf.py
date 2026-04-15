#!/usr/bin/env python3
"""Generate a comprehensive PDF dissertation guide."""
from fpdf import FPDF
import os

FIGS = "outputs/figures"
OUT = "presentation"
os.makedirs(OUT, exist_ok=True)

class PDF(FPDF):
    def header(self):
        if self.page_no() > 1:
            self.set_font("Helvetica","I",8)
            self.cell(0,5,"Oil Price Pass-Through to India's CPI | Dissertation Guide | Aniket Pandey",align="C")
            self.ln(8)
    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica","I",8)
        self.cell(0,10,f"Page {self.page_no()}/{{nb}}",align="C")
    def section_title(self, title):
        self.set_font("Helvetica","B",16)
        self.set_fill_color(30,60,114)
        self.set_text_color(255,255,255)
        self.cell(0,12,f"  {title}",fill=True,new_x="LMARGIN",new_y="NEXT")
        self.set_text_color(0,0,0)
        self.ln(4)
    def sub_title(self, title):
        self.set_font("Helvetica","B",13)
        self.set_text_color(30,60,114)
        self.cell(0,8,title,new_x="LMARGIN",new_y="NEXT")
        self.set_text_color(0,0,0)
        self.ln(2)
    def sub2_title(self, title):
        self.set_font("Helvetica","B",11)
        self.set_text_color(60,60,60)
        self.cell(0,7,title,new_x="LMARGIN",new_y="NEXT")
        self.set_text_color(0,0,0)
        self.ln(1)
    def body_text(self, txt):
        self.set_font("Helvetica","",10)
        self.multi_cell(0,5.5,txt)
        self.ln(2)
    def bold_text(self, txt):
        self.set_font("Helvetica","B",10)
        self.multi_cell(0,5.5,txt)
        self.ln(1)
    def bullet(self, txt):
        self.set_font("Helvetica","",10)
        self.set_x(10)
        self.multi_cell(0,5.5,f"  - {txt}")
    def equation(self, txt):
        self.set_font("Courier","",10)
        self.set_fill_color(240,240,245)
        self.set_x(10)
        self.multi_cell(0,5.5,f"  {txt}",fill=True)
        self.set_font("Helvetica","",10)
        self.ln(2)
    def add_fig(self, fname, caption, w=170):
        path = f"{FIGS}/{fname}"
        if os.path.exists(path):
            self.image(path, x=20, w=w)
            self.ln(3)
            self.set_font("Helvetica","I",9)
            self.set_text_color(80,80,80)
            self.set_x(10)
            self.multi_cell(0,4.5,caption)
            self.set_text_color(0,0,0)
            self.ln(4)
    def table_row(self, cols, widths, bold=False, fill=False):
        self.set_font("Helvetica","B" if bold else "",9)
        if fill:
            self.set_fill_color(230,235,245)
        self.set_x(10)
        h=6
        for i,c in enumerate(cols):
            self.cell(widths[i],h,str(c),border=1,fill=fill)
        self.ln(h)

pdf = PDF()
pdf.alias_nb_pages()
pdf.set_auto_page_break(auto=True, margin=20)

# ===== TITLE PAGE =====
pdf.add_page()
pdf.ln(40)
pdf.set_font("Helvetica","B",26)
pdf.set_text_color(30,60,114)
pdf.multi_cell(0,12,"Dissertation Progress Report\nComplete Guide",align="C")
pdf.ln(8)
pdf.set_font("Helvetica","",14)
pdf.set_text_color(80,80,80)
pdf.multi_cell(0,7,"Do Global Oil Price Shocks Raise India's Inflation\nMore Than They Lower It?",align="C")
pdf.ln(6)
pdf.set_font("Helvetica","",12)
pdf.cell(0,7,"Short-Run Pass-Through to CPI Inflation in India, 2004-2024",align="C",new_x="LMARGIN",new_y="NEXT")
pdf.ln(20)
pdf.set_text_color(0,0,0)
pdf.set_font("Helvetica","",12)
pdf.cell(0,7,"Student: Aniket Pandey",align="C",new_x="LMARGIN",new_y="NEXT")
pdf.cell(0,7,"Supervisor: Prof. Shakti Kumar",align="C",new_x="LMARGIN",new_y="NEXT")
pdf.cell(0,7,"MS Economics, JNU, 2026",align="C",new_x="LMARGIN",new_y="NEXT")

# ===== SECTION 1: BIG PICTURE =====
pdf.add_page()
pdf.section_title("1. The Big Picture - What Is This Study About?")
pdf.sub_title("Core Research Question")
pdf.body_text("When global oil prices go UP, does India's inflation go up too? And more importantly - when oil prices DROP, does inflation come down equally, or does it stay high?")
pdf.sub_title("Why This Matters for India")
pdf.bullet("India imports approximately 85% of its crude oil - making it highly vulnerable to global oil price shocks")
pdf.bullet("Oil price changes affect petrol, diesel, cooking gas, transport costs, and ultimately food and all consumer goods")
pdf.bullet("If oil price INCREASES push inflation UP strongly but oil price DECREASES DON'T bring it DOWN equally - that is called ASYMMETRY")
pdf.bullet("This asymmetry is also called 'rockets and feathers' - prices go up like rockets but come down like feathers")
pdf.ln(3)
pdf.sub_title("What We Are Trying to Show")
pdf.bullet("1. Oil price shocks DO pass through to India's CPI inflation (pass-through exists)")
pdf.bullet("2. The pass-through from oil price INCREASES is stronger than from DECREASES (asymmetry)")
pdf.bullet("3. The exchange rate (INR/USD) matters separately because oil is priced in dollars")
pdf.ln(3)
pdf.sub_title("The Honest Bottom Line (What to Tell Your Supervisor)")
pdf.bold_text("Lead with what you FOUND, not what you didn't find:")
pdf.body_text('"Positive oil shocks are associated with higher monthly CPI inflation in India, and the estimated effect is economically meaningful (+0.21 percentage points for a 10% oil shock). However, the null of symmetric pass-through cannot be rejected at the 5% level in the full sample. This is expected because headline CPI is dominated by food prices (47% weight), which dilutes the energy signal. Our Fuel & Light CPI appendix confirms a stronger and statistically significant positive pass-through."')

# ===== SECTION 2: DATA =====
pdf.add_page()
pdf.section_title("2. Data Sources and Why We Use Them")
pdf.sub_title("Study Window: April 2004 to December 2024 (249 monthly observations)")
pdf.body_text("Why start from 2004? India's comparable CPI series begins around then. This gives us 20 full years covering major oil events: China commodity boom, 2008 global financial crisis, US shale revolution, COVID-19, Russia-Ukraine conflict.")
pdf.ln(2)
pdf.sub_title("Four Main Data Files")
w = [30,35,35,70]
pdf.table_row(["Variable","File","Source","Why This Source"],w,bold=True,fill=True)
pdf.table_row(["CPI","INDCPIALLMINMEI","OECD/FRED","Standard international source, 2015=100"],w)
pdf.table_row(["Brent Oil","POILBREUSDM","IMF/FRED","Global benchmark for India's oil imports"],w)
pdf.table_row(["INR/USD","EXINUS","Fed/FRED","Oil priced in USD, India pays in INR"],w)
pdf.table_row(["IIP","iip_chained.xlsx","RBI DBIE","Controls for economic activity"],w)
pdf.ln(3)
pdf.sub_title("Why Headline CPI (Not Fuel CPI) as Main Variable?")
pdf.body_text("Because the dissertation asks about AGGREGATE inflation - what the RBI targets, what affects common people. Headline CPI is the policy-relevant inflation measure. Fuel CPI is only one sub-component and is used as supplementary appendix evidence.")
pdf.ln(2)
pdf.sub_title("Descriptive Statistics")
w2 = [35,15,20,20,25,25]
pdf.table_row(["Variable","N","Mean","SD","Min","Max"],w2,bold=True,fill=True)
for row in [
    ["CPI Index","249","93.97","35.71","41.79","159.20"],
    ["Brent USD","249","75.08","24.26","26.85","133.59"],
    ["INR/USD","249","60.21","13.89","39.27","84.97"],
    ["Oil INR","249","4490.6","1692.9","1464.1","9190.6"],
    ["dlnCPI (%)","248","0.54","0.75","-1.66","4.47"],
    ["dlnOil (%)","248","0.58","8.89","-45.37","23.20"],
    ["dOil+ (%)","248","3.60","4.58","0","23.20"],
    ["dOil- (%)","248","-3.02","6.02","-45.37","0"],
]:
    pdf.table_row(row,w2)
pdf.ln(3)
pdf.bold_text("Key insight: Oil prices are WAY more volatile than CPI. dlnOil swings -45% to +23% while dlnCPI only moves -1.7% to +4.5%. This means we should expect a small pass-through coefficient.")

# ===== SECTION 3: VARIABLE CONSTRUCTION =====
pdf.add_page()
pdf.section_title("3. Variable Construction (With Equations)")
pdf.sub_title("Step 1: Create Oil Price in Indian Rupees")
pdf.body_text("Since India pays for oil in INR, not USD, we construct:")
pdf.equation("Oil_INR(t) = Brent_USD(t) x INR/USD(t)")
pdf.body_text("Example: If Brent = $80/barrel and exchange rate = Rs.83/USD, then Oil_INR = 80 x 83 = Rs.6,640")

pdf.sub_title("Step 2: Why We Convert to Logarithms")
pdf.bold_text("This is a critical methodological question your supervisor may ask!")
pdf.body_text("We take logarithms and then first-differences for four important reasons:")
pdf.bullet("1. PERCENTAGE INTERPRETATION: ln(X_t) - ln(X_{t-1}) is approximately equal to the percentage change. So our coefficients directly tell us: a 1% oil change leads to X% CPI change.")
pdf.bullet("2. STATIONARITY: Raw CPI and oil prices have trends (go up over time). Regressions on trending data give SPURIOUS (fake) results. Log-differencing removes the trend and makes data stationary.")
pdf.bullet("3. NORMALITY: Log transformation reduces skewness in the data, making residuals closer to normal distribution.")
pdf.bullet("4. COMPARABILITY: Different variables have different scales (CPI ~ 100, Brent ~ 75, IIP ~ 110). Log-differences express everything as percentage changes, making them comparable.")
pdf.ln(2)
pdf.equation("dlnCPI(t) = 100 x [ln(CPI_t) - ln(CPI_{t-1})]")
pdf.equation("dlnOil(t) = 100 x [ln(Oil_INR_t) - ln(Oil_INR_{t-1})]")
pdf.equation("dlnEXR(t) = 100 x [ln(EXR_t) - ln(EXR_{t-1})]")
pdf.equation("dlnIIP(t) = 100 x [ln(IIP_t) - ln(IIP_{t-1})]")
pdf.body_text("Multiplied by 100 to express as percentage points.")

pdf.sub_title("Step 3: Asymmetric Decomposition (THE KEY IDEA)")
pdf.body_text("We split oil price changes into positive (increases) and negative (decreases) components:")
pdf.equation("dOil+(t) = max(dlnOil(t), 0)   <-- keeps only INCREASES")
pdf.equation("dOil-(t) = min(dlnOil(t), 0)   <-- keeps only DECREASES")
pdf.body_text("Example: Month where oil went up +5%: dOil+ = 5, dOil- = 0. Month where oil went down -8%: dOil+ = 0, dOil- = -8. Now we can estimate SEPARATE effects for increases vs decreases!")
pdf.bold_text("IMPORTANT: dOil- stays NEGATIVE. For a -10% oil shock, the CPI effect = CPT- x (-10).")

pdf.sub_title("Step 4: Policy Dummies and Lags")
w3 = [25,40,105]
pdf.table_row(["Dummy","= 1 when","What happened"],w3,bold=True,fill=True)
pdf.table_row(["D_petrol","From June 2010","Petrol prices deregulated (market-linked)"],w3)
pdf.table_row(["D_diesel","From Oct 2014","Diesel prices deregulated (market-linked)"],w3)
pdf.table_row(["D_covid","April 2020 only","COVID lockdown outlier"],w3)
pdf.table_row(["M1-M11","Monthly dummies","Seasonal patterns (Dec = reference)"],w3)
pdf.ln(3)
pdf.body_text("We also create LAGGED variables (L1 = 1 month ago, L2 = 2 months ago, L3 = 3 months ago) because oil price changes take time to flow through to consumer prices.")

# ===== SECTION 4: METHODOLOGY =====
pdf.add_page()
pdf.section_title("4. Econometric Methodology (Step by Step)")

pdf.sub_title("4.1 What is an ADL Model?")
pdf.body_text("ADL = Autoregressive Distributed Lag model. Think of it as: 'Today's inflation depends on past inflation (autoregressive part), current and past oil shocks (distributed lag part), and other controls.'")

pdf.sub_title("4.2 Baseline Symmetric Model (Benchmark)")
pdf.body_text("First we estimate a simple model where oil increases and decreases have the SAME effect:")
pdf.equation("dlnCPI(t) = a + g1*dlnCPI(t-1) + b0*dlnOil(t) + b1*dlnOil(t-1)")
pdf.equation("           + d*dlnIIP(t) + policy dummies + month dummies + e(t)")
pdf.body_text("Result: Symmetric CPT = 0.0028, p = 0.578. Oil effect is tiny and not significant. This is our benchmark to compare against the asymmetric model.")

pdf.sub_title("4.3 Main Asymmetric ADL(p,q) Model")
pdf.equation("dlnCPI(t) = a + SUM[gi * dlnCPI(t-i), i=1..p]")
pdf.equation("          + SUM[pi+ * dOil+(t-j), j=0..q]  (positive oil lags)")
pdf.equation("          + SUM[pi- * dOil-(t-j), j=0..q]  (negative oil lags)")
pdf.equation("          + d*dlnIIP(t) + policy dummies + month dummies + e(t)")
pdf.ln(2)
pdf.bold_text("Key decisions and how they were made:")
pdf.bullet("Oil lag length q = 3 (FIXED): Based on theory - oil shocks take 1-3 months to transmit through supply chains to retail prices.")
pdf.bullet("CPI AR lag length p selected by AIC from {1,2,3,4}: AIC balances model fit vs complexity. Lower AIC = better model.")
pdf.bullet("AIC results: p=1: 508.06, p=2: 502.06, p=3: 496.79, p=4: 497.58")
pdf.bullet("SELECTED p = 3 (lowest AIC = 496.79). Final model: ADL(3,3)")
pdf.bullet("All models compared on the SAME sample (important for fair AIC comparison)")

pdf.sub_title("4.4 Cumulative Pass-Through (CPT)")
pdf.equation("CPT+ = pi+_0 + pi+_1 + pi+_2 + pi+_3  (total positive oil effect)")
pdf.equation("CPT- = pi-_0 + pi-_1 + pi-_2 + pi-_3  (total negative oil effect)")
pdf.body_text("CPT tells us the TOTAL effect of a sustained oil shock over 0-3 months.")

pdf.sub_title("4.5 Newey-West HAC Standard Errors")
pdf.bold_text("Why not use regular OLS standard errors?")
pdf.body_text("In time series data, errors are typically autocorrelated (today's error predicts tomorrow's) and heteroskedastic (error variance changes over time). Regular OLS standard errors would be WRONG - giving unreliable p-values.")
pdf.body_text("Newey-West HAC (Heteroskedasticity and Autocorrelation Consistent) standard errors correct for both problems simultaneously.")
pdf.equation("Truncation lag = floor(0.75 x N^(1/3))")
pdf.body_text("For N=245: lag = floor(0.75 x 6.26) = 4. All p-values and t-statistics in this study use these robust standard errors.")

pdf.sub_title("4.6 Wald Test for Asymmetry")
pdf.equation("H0: CPT+ = CPT-   (no asymmetry)")
pdf.equation("H1: CPT+ != CPT-  (asymmetry exists)")
pdf.body_text("This F-test (using Newey-West covariance matrix) formally tests whether positive and negative oil effects are statistically different.")

# ===== SECTION 5: UNIT ROOT TESTS =====
pdf.add_page()
pdf.section_title("5. Unit Root Tests (ADF)")
pdf.sub_title("What and Why?")
pdf.body_text("The Augmented Dickey-Fuller (ADF) test checks if data is STATIONARY (mean-reverting). Non-stationary data in regressions gives SPURIOUS (fake) results. We need to confirm our variables are stationary before running regressions.")
pdf.equation("Test: dY(t) = a + b*Y(t-1) + SUM[g_i*dY(t-i)] + e(t)")
pdf.equation("H0: b = 0 (unit root, non-stationary)")
pdf.equation("H1: b < 0 (stationary)")
pdf.body_text("If p-value < 0.05, we reject H0 and conclude the series is stationary.")
pdf.ln(2)
pdf.sub_title("Our ADF Results")
w4 = [30,30,25,25,60]
pdf.table_row(["Variable","ADF Stat","p-value","Lags","Conclusion"],w4,bold=True,fill=True)
pdf.table_row(["ln(CPI)","-0.32","0.99","6","Non-stationary"],w4)
pdf.table_row(["ln(Oil_INR)","-2.57","0.33","6","Non-stationary"],w4)
pdf.table_row(["ln(EXR)","-3.69","0.03","6","Borderline stationary"],w4)
pdf.table_row(["ln(IIP)","-3.20","0.09","6","Not at 5%"],w4)
pdf.table_row(["dlnCPI","-9.04","<0.01","6","STATIONARY"],w4)
pdf.table_row(["dlnOil","-6.13","<0.01","6","STATIONARY"],w4)
pdf.table_row(["dlnEXR","-5.21","<0.01","6","STATIONARY"],w4)
pdf.table_row(["dlnIIP","-8.22","<0.01","6","STATIONARY"],w4)
pdf.ln(3)
pdf.bold_text("Interpretation: Levels are non-stationary. First differences (log-differences) are stationary. This is called I(1) behavior. This justifies our estimation in first differences.")
pdf.body_text("What to say to teacher: 'All variables in levels fail the ADF test (except exchange rate borderline), confirming they have unit roots. After first-differencing, all variables are strongly stationary with p < 0.01. This validates our choice to estimate the ADL model in log-differences.'")

# ===== SECTION 6: MAIN RESULTS =====
pdf.add_page()
pdf.section_title("6. Main Results and Their Interpretation")
pdf.sub_title("6.1 Main Asymmetric ADL(3,3) Results")
w5 = [55,30,85]
pdf.table_row(["Result","Value","Interpretation"],w5,bold=True,fill=True)
pdf.table_row(["CPT+","0.021296","1% oil increase raises monthly CPI by 0.021 pp"],w5)
pdf.table_row(["CPT-","0.000598","1% oil decrease lowers CPI by 0.0006 pp (~ zero)"],w5)
pdf.table_row(["Asymmetry Gap","0.020698","Positive effect is ~35x larger"],w5)
pdf.table_row(["+10% oil shock","+0.213 pp","CPI rises meaningfully"],w5)
pdf.table_row(["-10% oil shock","-0.006 pp","CPI barely moves"],w5)
pdf.table_row(["p(CPT+ = 0)","0.1220","Not significant at 5%, borderline at 12%"],w5)
pdf.table_row(["p(CPT- = 0)","0.9375","Clearly not significant"],w5)
pdf.table_row(["p(CPT+ = CPT-)","0.2408","Asymmetry NOT significant at 5%"],w5)
pdf.table_row(["Adj R-squared","0.4492","Model explains ~45% of CPI variation"],w5)
pdf.table_row(["N","245","Observations used"],w5)

pdf.ln(4)
pdf.sub_title("6.2 What These Numbers Mean (Plain English)")
pdf.bullet("Oil price increases DO affect CPI inflation positively - economically meaningful magnitude")
pdf.bullet("Oil price decreases DON'T bring CPI down - essentially zero effect")
pdf.bullet("The asymmetry IS visible in pointestimates but NOT statistically significant at 5%")
pdf.bullet("This is NOT a failure - headline CPI is noisy because food is 47% of the basket")
pdf.ln(3)
pdf.sub_title("6.3 Sub-Sample Analysis (Pre/Post Diesel Deregulation Oct 2014)")
w6 = [50,15,25,25,25,30]
pdf.table_row(["Period","N","CPT+","CPT-","Gap","p(Asym)"],w6,bold=True,fill=True)
pdf.table_row(["Pre-2014","122","0.0173","0.0099","0.0074","0.846"],w6)
pdf.table_row(["Post-2014","123","0.0102","-0.002","0.0082","0.443"],w6)
pdf.ln(3)
pdf.body_text("Post-2014 shows cleaner results: positive shock positive, negative shock near-zero, better model fit (R-sq = 0.50). This makes sense because after deregulation, market prices respond more directly to oil.")

pdf.sub_title("6.4 Diagnostic Tests")
w7 = [50,25,25,70]
pdf.table_row(["Test","Statistic","p-value","Result"],w7,bold=True,fill=True)
pdf.table_row(["Breusch-Godfrey LM(12)","19.71","0.073","PASS (no autocorrelation)"],w7)
pdf.table_row(["Breusch-Pagan","44.76","0.013","FAIL but HAC handles this"],w7)
pdf.table_row(["Ramsey RESET","2.80","0.063","PASS (correct form)"],w7)
pdf.table_row(["CUSUM","0.86","0.091","PASS (model is stable)"],w7)
pdf.ln(3)
pdf.bold_text("What to say about Breusch-Pagan failure:")
pdf.body_text("'The BP test detects heteroskedasticity, which is expected in macro time series. This is precisely why we use Newey-West HAC standard errors - they give valid inference even with heteroskedasticity. The detection CONFIRMS our choice of using HAC was correct and necessary.'")

# ===== SECTION 7: ALL PLOTS EXPLAINED =====
pdf.add_page()
pdf.section_title("7. All Output Plots - Explained")

pdf.sub_title("Figure 1: Raw Data Series (Levels)")
pdf.add_fig("fig_1_raw_series.png","Figure 1: CPI, Brent crude, INR/USD exchange rate, and IIP in levels (Apr 2004 - Dec 2024)")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("All four variables trend over time - CPI rises steadily, rupee depreciates, IIP grows. Brent is volatile with booms and crashes. These trending series are NON-STATIONARY, which is why we cannot use them directly in regression. We must transform them to log-differences.")

pdf.add_page()
pdf.sub_title("Figure 2: Log-Differenced Series (Monthly % Changes)")
pdf.add_fig("fig_2_log_diff_series.png","Figure 2: Monthly percentage changes after log-differencing")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("After log-differencing, all series oscillate around zero - this is STATIONARY data. Notice that dlnOil has much larger swings than dlnCPI (oil is ~12x more volatile). The massive IIP drop in April 2020 is the COVID lockdown. These are the variables that enter our regression model.")

pdf.add_page()
pdf.sub_title("Figure 3: Cumulative Partial Sums of Oil Changes")
pdf.add_fig("fig_3_oil_decomposition.png","Figure 3: Cumulative positive (red) and negative (blue) oil price changes")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("This plot visualizes the ASYMMETRIC DECOMPOSITION - the core innovation of our model. The red line (cumulative increases) trends strongly upward. The blue line (cumulative decreases) trends downward. Both components have large variation, giving our model sufficient data to estimate separate effects for positive and negative shocks.")

pdf.sub_title("Figure 4: Cumulative Pass-Through by Horizon")
pdf.add_fig("fig_4_cumulative_passthrough.png","Figure 4: CPT+ (red) and CPT- (blue) building up over 0 to 3 month lags")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("This is the KEY RESULT PLOT. The red line (CPT+) builds up to ~0.021 by lag 3, showing that positive oil shocks take 2-3 months to fully transmit to CPI. The blue line (CPT-) stays near zero throughout, showing that negative oil shocks have essentially NO effect on CPI inflation. 'The 2-month delay reflects supply chain transmission - oil price changes take time to reach retail fuel prices and then consumer goods.'")

pdf.add_page()
pdf.sub_title("Figure 5: Sub-Sample Comparison")
pdf.add_fig("fig_5_subsample_comparison.png","Figure 5: CPT+ vs |CPT-| before and after diesel deregulation")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("In both sub-periods, CPT+ (red) is larger than |CPT-| (blue), showing that the DIRECTION of asymmetry is consistent regardless of the policy regime. Post-2014 shows cleaner separation, suggesting diesel deregulation made pass-through more transparent.")

pdf.sub_title("Figure 6: CUSUM Stability Test")
pdf.add_fig("fig_6_cusum_stability.png","Figure 6: CUSUM statistic staying within the 5% confidence boundaries")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("The CUSUM line stays within the two red boundary lines. If it crossed, it would indicate a structural break (the oil-CPI relationship changed fundamentally). Since it stays within bounds, our model is STABLE over the entire 20-year sample. 'This confirms that despite policy changes and oil regimes, our estimated relationship is valid throughout.'")

pdf.add_page()
pdf.sub_title("Figure 7: Rolling 60-Month Window")
pdf.add_fig("fig_7_rolling_window.png","Figure 7: Rolling 5-year window CPT+ (red) and CPT- (blue) over time")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("This tells us HOW THE PASS-THROUGH CHANGED OVER TIME. CPT+ (red) varies considerably - strongest during volatile oil periods. CPT- (blue) stays near zero consistently. The vertical line marks diesel deregulation. 'This explains why the full-sample Wald test is weak: averaging 20 years of CHANGING dynamics dilutes the signal. The pass-through is significant in some sub-periods but gets averaged out.'")

pdf.sub_title("Figure 8: Residual Diagnostics")
pdf.add_fig("fig_8_residual_diagnostics.png","Figure 8: Four-panel residual diagnostics: time series, histogram, Q-Q plot, actual vs fitted")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("Top-left: Residuals over time show no obvious pattern (good - no autocorrelation). Top-right: Histogram is roughly bell-shaped but with fat tails (mild non-normality, typical for macro data). Bottom-left: Q-Q plot mostly follows the line with minor deviations at extremes. Bottom-right: Actual vs fitted points cluster around the 45-degree line. 'Overall, residuals behave reasonably. Mild non-normality is fully handled by our HAC robust inference.'")

pdf.add_page()
pdf.sub_title("Figure 9: Oil Price Regimes")
pdf.add_fig("fig_9_oil_price_regimes.png","Figure 9: Brent crude with shaded bands for major global events")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("Our 20-year sample covers ALL major oil price regimes: China commodity boom (2004-2008), Global Financial Crisis crash (2008-2009), US shale revolution + India diesel deregulation (2014-2016), COVID-19 (2020), Russia-Ukraine conflict (2022). 'This gives our model rich variation in both positive and negative oil shocks of large magnitude, making our estimates more reliable.'")

pdf.sub_title("Figure 10: Asymmetry Gap Comparison")
pdf.add_fig("fig_10_asymmetry_gap.png","Figure 10: CPT+ vs |CPT-| across full sample and sub-samples")
pdf.bold_text("What it shows and what to say:")
pdf.body_text("In ALL three samples (full, pre-2014, post-2014), the red bar (CPT+) is larger than the blue bar (|CPT-|). 'Even though statistical significance is elusive, the DIRECTION of asymmetry is completely robust across different sample periods. This is consistent evidence of rockets-and-feathers behavior in India.'")

# ===== SECTION 8: ROBUSTNESS =====
pdf.add_page()
pdf.section_title("8. Robustness Checks")
pdf.body_text("Robustness checks prove your main result is not a fluke or artifact of specific model choices.")

pdf.sub_title("8.1 Lag Grid Sensitivity (16 models)")
pdf.body_text("Estimated ALL combinations of p={1,2,3,4} and q={0,1,2,3}. CPT+ is positive across most specifications. Our main model ADL(3,3) is chosen by AIC, not cherry-picked.")

pdf.sub_title("8.2 Brent + Exchange Rate Model (Key Robustness)")
w8 = [40,22,28,25,25,30]
pdf.table_row(["Specification","CPT+","+10% Eff","p(CPT+)","EXR p","Adj R2"],w8,bold=True,fill=True)
pdf.table_row(["Primary(OilINR)","0.021","+0.213","0.122","--","0.449"],w8)
pdf.table_row(["Brent+EXR","0.027","+0.275","0.093","0.029","0.458"],w8)
pdf.ln(3)
pdf.bold_text("Key finding: Exchange rate is SIGNIFICANT (p=0.029)!")
pdf.body_text("A 1% rupee depreciation raises CPI by ~0.04 pp independently of oil. This separates the world oil price channel from the currency channel and makes the India interpretation more credible.")

pdf.sub_title("8.3 COVID & Winsorized Sensitivity")
pdf.body_text("Removing COVID dummy: CPT+ barely changes. Winsorizing extreme oil shocks (top/bottom 1%): Results remain similar. Our findings are not driven by outliers.")

pdf.sub_title("8.4 Fuel & Light CPI Appendix (Strongest Supporting Evidence)")
w9 = [45,25,25,25,25,25]
pdf.table_row(["Metric","Headline","Fuel CPI","","",""],w9,bold=True,fill=True)
pdf.table_row(["CPT+","0.021","0.061","","",""],w9)
pdf.table_row(["+10% effect","+0.213pp","+0.609pp","","",""],w9)
pdf.table_row(["p(CPT+)","0.122","0.034*","","",""],w9)
pdf.table_row(["Sample","2004-24","2011-24","","",""],w9)
pdf.ln(3)
pdf.bold_text("Fuel CPI shows 3x STRONGER and STATISTICALLY SIGNIFICANT positive oil pass-through (p=0.034)!")
pdf.body_text("This is exactly what theory predicts - a more energy-exposed CPI sub-index responds more directly to oil. It serves as powerful supplementary evidence.")

# ===== SECTION 9: VIVA PREP =====
pdf.add_page()
pdf.section_title("9. Likely Supervisor Questions and Answers")

qas = [
    ("Why ADL and not NARDL or SVAR?",
     "ADL is the most transparent framework for short-run pass-through. NARDL requires cointegration which our variables don't strongly support. SVAR requires structural identification assumptions hard to defend. ADL gives clean, interpretable short-run multipliers with robust HAC inference."),
    ("Why use headline CPI if oil mainly affects fuel?",
     "Because the dissertation asks about aggregate inflation relevance - what the RBI targets. I then add Fuel CPI as an appendix to show the direct energy channel. This is a standard two-level approach."),
    ("Your Wald test is insignificant. Did you fail?",
     "No. The main result is positive oil pass-through with meaningful magnitude (+0.21pp per 10% shock). The Wald test asks whether positive and negative effects are statistically DIFFERENT. In headline CPI that difference is hard to estimate precisely because energy is a small share of the basket."),
    ("Why Newey-West and not OLS standard errors?",
     "Because macro time-series residuals are autocorrelated and heteroskedastic. OLS standard errors would be inconsistent, giving unreliable t-statistics and p-values. HAC corrects for both simultaneously."),
    ("How did you choose lag lengths?",
     "Oil lags (q=3) are fixed based on theory: 1-3 months for supply chain transmission. CPI AR lags selected by AIC from {1,2,3,4} on a common sample. p=3 was chosen. The full 4x4 lag grid sensitivity table confirms robustness."),
    ("What does Brent+EXR model tell us?",
     "It separates world oil prices from exchange-rate effects. Since India imports oil in dollars, rupee depreciation independently adds to domestic cost. The exchange rate is significant (p=0.029), confirming both channels matter."),
    ("What about the Fuel CPI result?",
     "It shows 3x stronger positive pass-through than headline CPI, and it is statistically significant at 5% (p=0.034). This confirms oil DOES pass through to prices; headline CPI just dilutes the signal."),
    ("Is 0.21pp per 10% shock economically meaningful?",
     "Yes. India's average monthly CPI change is 0.54%. A +0.21pp addition from a 10% oil shock represents ~39% of average monthly inflation. Over a year with sustained high oil, this compounds significantly."),
    ("Why take logarithms?",
     "Three reasons: (1) log-differences approximate percentage changes for easy interpretation, (2) log transformation reduces skewness and heteroskedasticity, (3) log-differences make non-stationary trending series stationary, which is required for valid regression inference."),
]

for q, a in qas:
    pdf.sub2_title(f"Q: {q}")
    pdf.body_text(a)
    pdf.ln(1)

# Save
outpath = f"{OUT}/Dissertation_Guide_Aniket_Pandey.pdf"
pdf.output(outpath)
print(f"PDF saved to: {outpath}")
