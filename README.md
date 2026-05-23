This project is an institutional-grade quantitative pipeline designed to extract the mathematical memory of the Nifty 50 Index, audit predictive algorithms, and simulate stochastic tail-risk. To ensure complete methodological integrity and zero data leakage, this codebase strictly separates historical signal extraction from future forecasting. The script and this documentation follow a linear, chronological 8-step pipeline.

Data Architecture & Splitting Strategy : To rigorously test the model's out-of-sample predictive power, the dataset was strictly partitioned to prevent any forward-looking bias (look-ahead leakage).

Training Dataset (nifty data.csv): January 1, 2008 — December 31, 2024. This 17-year dataset acts as the model's foundational memory, encompassing multiple macro-cycles, crashes, and bull runs. All algorithm fitting, parameter tuning, and residual diagnostics were locked in using only this data.

Testing Dataset (nifty test data.csv): January 7, 2025 — May 8, 2026. Data from December 31st onwards acts as the absolute blind test. The model was forced to predict these 71 weeks line-by-line without ever seeing them during the training phase.

1. Baseline Market Visualization : The pipeline initializes by ingesting historical Nifty 50 Adj.Close data. The raw time series is plotted to visually confirm inherent non-stationarity, identifying the presence of long-term trends and volatility clustering before any mathematical transformations are applied.
<img width="1624" height="850" alt="image" src="https://github.com/user-attachments/assets/b391616d-8cb9-4fd5-bdfe-a06d04ac1048" />

2. Variance Stabilization (Differencing: $d=1$ and $d=2$) : To prepare the data for autoregressive modeling, the trend component must be neutralized. The script computes and visually plots the first-order difference ($d=1$, representing velocity/returns) and the second-order difference ($d=2$, representing momentum/acceleration) to observe variance stabilization.
<img width="1603" height="795" alt="image" src="https://github.com/user-attachments/assets/4e433ec3-e9f2-4b88-b19d-caec52a7e0e9" />

3. Mathematical Stationarity (ADF Testing) : Visual confirmation is insufficient for algorithmic modeling. The Augmented Dickey-Fuller (ADF) test is deployed across the raw data ($d=0$), first difference ($d=1$), and second difference ($d=2$) to mathematically prove at which integration level the data achieves strict stationarity.
|  | d=0 | d=1 | d=2 |
| -------- | -------- | -------- | -------- |
| P-Value | 0.7633 | 0.01 | 0.01 |

4. Algorithmic Model Fitting : With the integration order confirmed on the pre-2025 training data, the pipeline identifies the optimal Autoregressive ($p$) and Moving Average ($q$) parameters:

   i) ACF & PACF Analysis: Autocorrelation and Partial Autocorrelation plots are generated for both $d=1$ and $d=2$ to manually identify potential parameter bounds. <img width="1624" height="850" alt="image" src="https://github.com/user-attachments/assets/dc54e189-b6f6-4320-8b8b-8df30d4ba0a5" />

   ii)  AIC & BIC Matrix: A grid search is executed, scoring multiple ARIMA configurations based on Akaike and Bayesian Information Criteria to find the mathematical optimum (penalizing for overfitting).

   iii) auto.arima Verification: The manual grid search results are audited against the algorithmic output of the forecast::auto.arima() function to confirm the optimal model structures.
   (Three candidate models are selected for further testing: Model 1 [0,1,0], Model 2 [0,2,1], and Model 3 [2,1,0]).

6. Residual Diagnostics (Ljung-Box Test) : A forecasting model is only valid if it extracts all available market signal. The Ljung-Box test is applied to the residuals of the candidate models across lags 1 through 12. This verifies that the remaining errors are purely white noise, confirming the models are mathematically sound.

7. In-Sample Percentage Error Analysis : Before out-of-sample testing, the baseline accuracy of the models is established. The absolute percentage error for each model is calculated, summarized, and plotted.<img width="1878" height="864" alt="image" src="https://github.com/user-attachments/assets/5763abd4-3317-46ed-bf1c-eb8d5d940054" /> Crucial Finding: Analyzing the Max error column reveals that Model 2 ($d=2$) adapts to historical market shocks significantly better than models relying on historical drift.

8. Out-of-Sample Walk-Forward Backtesting (2025 - 2026 Data) : To test pure predictive skill, a 71-week, 1-step-ahead expanding window backtest is executed across the blind testdata.csv. The models organically ingest new data line-by-line.
Metrics Tracked: RMSE, MAE, MAPE, ME, and Theil’s U.
The Verdict: While Model 1 and 3 perform adequately on average errors, Model 2 [ARIMA(0,2,1)] achieves the superior Theil's U (0.9853). Given anticipated macroeconomic shocks, Model 2 is explicitly chosen as the production engine because it relies on momentum acceleration rather than historical drift, aggressively mapping structural breaks.<img width="1857" height="808" alt="image" src="https://github.com/user-attachments/assets/204a9504-c635-4da4-91d6-da7087974ee2" />

9. Stochastic Risk Modeling (Monte Carlo Simulation) : With Model 2 validated as the premier engine, it is deployed to map future tail-risk. 1,000 parallel market universes are simulated for a 12-week horizon. To perform a visual Out-of-Sample VaR (Value at Risk) audit, the actual unseen market values from the test set are plotted directly over the simulation.<img width="1857" height="808" alt="image" src="https://github.com/user-attachments/assets/ba44bdf1-69e5-4255-afbf-bd74df39ec94" /> The "Fat Tail" Reality:The 90% confidence interval successfully bounds the Nifty 50's trajectory across the majority of the horizon. However, the momentary, violent breach of the lower boundary by the actual market data mathematically demonstrates the "fat-tailed" nature of equity markets. It visually proves that while ARIMA models effectively map standard variance, real-world structural market crashes exceed standard Gaussian probabilities.

Language : R

Libraries : forecast, tseries
