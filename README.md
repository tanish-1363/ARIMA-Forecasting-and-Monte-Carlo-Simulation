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
| :--------: | :--------: | :--------: | :--------: |
| P-Value | 0.7633 | 0.01 | 0.01 |

4. Algorithmic Model Fitting : With the integration order confirmed on the pre-2025 training data, the pipeline identifies the optimal Autoregressive ($p$) and Moving Average ($q$) parameters:

   i) ACF & PACF Analysis: Autocorrelation and Partial Autocorrelation plots are generated for both $d=1$ and $d=2$ to manually identify potential parameter bounds. <img width="1624" height="850" alt="image" src="https://github.com/user-attachments/assets/dc54e189-b6f6-4320-8b8b-8df30d4ba0a5" />

   ii)  AIC & BIC Matrix: A grid search is executed, scoring multiple ARIMA configurations based on Akaike and Bayesian Information Criteria to find the mathematical optimum (penalizing for overfitting).

| **AIC Matrix for d=1** | | | | | | | | **BIC Matrix for d=1** | | | | | | |
| :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | 
|  | q=0 | q=1 | q=2 | q=3 | q=4 | q=5 | | | q=0 | q=1 | q=2 | q=3 | q=4 | q=5 | 
| p=0 | 12362.21 | 12364.11 | 12364.93 | 12366.41 | 12367.93 | 12369.87 | | p=0 | 12366.99 | 12373.69 | 12379.29 | 12385.57 | 12391.87 | 12398.60 |
| p=1 | 12364.11 | 12362.77 | 12366.31 | 12365.73 | 12367.49 | 12369.24 | | p=1 | 12373.68 | 12377.13 | 12385.47 | 12389.67 | 12396.21 | 12402.75 |
| p=2 | 12364.91 | 12366.36 | 12369.46 | 12371.27 | 12371.87 | 12373.86 | | p=2 | 12379.28 | 12385.51 | 12393.40 | 12400.00 | 12405.39 | 12412.16 |
| p=3 | 12366.42 | 12368.25 | 12367.51 | 12369.32 | 12367.40 | 12369.29 | | p=3 | 12385.57 | 12392.19 | 12396.24 | 12402.83 | 12405.70 | 12412.38 |
| p=4 | 12368.04 | 12370.00 | 12366.27 | 12373.35 | 12373.36 | 12369.77 | | p=4 | 12391.97 | 12398.72 | 12399.79 | 12411.65 | 12416.45 | 12417.65 |
| p=5 | 12369.95 | 12371.97 | 12359.72 | 12366.96 | 12370.24 | 12365.95 | | p=5 | 12398.68 | 12405.48 | 12398.03 | 12410.05 | 12418.12 | 12418.62 |

| **AIC Matrix for d=2** | | | | | | | | **BIC Matrix for d=2** | | | | | | |
| :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | 
|  | q=0 | q=1 | q=2 | q=3 | q=4 | q=5 | | | q=0 | q=1 | q=2 | q=3 | q=4 | q=5 | 
| p=0 | 12972.73 | 12351.73 | 12353.43 | 12354.68 | 12356.46 | 12358.26 | | p=0 | 12977.51 | 12361.30 | 12367.79 | 12373.83 | 12380.39 | 12386.98 |
| p=1 | 12688.26 | 12353.41 | 12355.19 | 12357.01 | 12357.22 | 12360.13 | | p=1 | 12697.84 | 12367.77 | 12374.33 | 12380.95 | 12385.94 | 12393.64 |
| p=2 | 12583.43 | 12354.69 | 12356.72 | 12358.73 | 12360.44 | 12362.18 | | p=2 | 12597.79 | 12373.84 | 12380.65 | 12387.45 | 12393.95 | 12400.47 |
| p=3 | 12529.13 | 12356.48 | 12355.54 | 12360.50 | 12361.99 | 12364.07 | | p=3 | 12548.28 | 12380.42 | 12384.26 | 12394.00 | 12400.28 | 12407.15 |
| p=4 | 12503.75 | 12358.34 | 12360.48 | 12361.73 | 12357.60 | 12359.07 | | p=4 | 12527.68 | 12387.06 | 12393.98 | 12400.03 | 12400.68 | 12406.94 |
| p=5 | 12485.77 | 12360.07 | 12362.29 | 12359.41 | 12363.67 | 12359.52 | | p=5 | 12514.49 | 12393.58 | 12400.59 | 12402.49 | 12411.54 | 12412.18 |

   iii) auto.arima Verification: The manual grid search results are audited against the algorithmic output of the forecast::auto.arima() function to confirm the optimal model structures.
   (Three candidate models are selected for further testing: Model 1 [0,1,0], Model 2 [0,2,1], and Model 3 [2,1,0] with drift).

6. Residual Diagnostics (Ljung-Box Test) : A forecasting model is only valid if it extracts all available market signal. The Ljung-Box test is applied to the residuals of the candidate models across lags 1 through 12. This verifies that the remaining errors are purely white noise, confirming the models are mathematically sound.

| | Pvalue Model 1 | Pvalue Model 2 | Pvalue Model 3 |
| :--------: | :--------: | :--------: | :--------: |
| lag=1 | 0.6214884 | 0.5014497 | 0.9854807 |
| lag=2 | 0.5813448 | 0.5968052 | 0.9995973 |
| lag=3 | 0.7256440 | 0.7696152 | 0.9629399 |
| lag=4 | 0.8242606 | 0.8727575 | 0.9763112 |
| lag=5 | 0.8876187 | 0.9002415 | 0.9851889 |
| lag=6 | 0.9365100 | 0.9330611 | 0.9928795 |
| lag=7 | 0.9012372 | 0.8666764 | 0.9677287 |
| lag=8 | 0.9349256 | 0.9007932 | 0.9816127 |
| lag=9 | 0.9082417 | 0.8821703 | 0.9644252 |
| lag=10 | 0.7916540 | 0.7308207 | 0.8812571 |
| lag=11 | 0.8154456 | 0.7730395 | 0.9022298 |
| lag=12 | 0.8674843 | 0.8352408 | 0.9323718 |

8. In-Sample Percentage Error Analysis : Before out-of-sample testing, the baseline accuracy of the models is established. The absolute percentage error for each model is calculated, summarized, and plotted.<img width="1878" height="864" alt="image" src="https://github.com/user-attachments/assets/5763abd4-3317-46ed-bf1c-eb8d5d940054" /> Crucial Finding: Analyzing the Max error column reveals that Model 2 ($d=2$) adapts to historical market shocks significantly better than models relying on historical drift.

| | Min | 1st Quartile | Median | Mean | 3rd Quartile | Max | 
| :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: |
| Model 1 | 0.0005 | 0.7415 | 1.5103 | 2.0837 | 2.6897 | 23.7144 |
| Model 2 | 0.00023 | 0.72515 | 1.51163 | 2.09959 | 2.71627 | 20.87352 |
| Model 3 | 0.00317 | 0.69064 | 1.47889 | 2.06593 | 2.64602 | 24.57292 |

9. Out-of-Sample Walk-Forward Backtesting (2025 - 2026 Data) : To test pure predictive skill, a 71-week, 1-step-ahead expanding window backtest is executed across the blind niftytestdata.csv. The models organically ingest new data line-by-line.
Metrics Tracked: RMSE, MAE, MAPE, ME, and Theil’s U.
| | Mean Error | Root Mean Square Error | Mean Absolute Error | Mean Percentage Error | Mean Absolute Percentage Error | ACF 1 | Theil's U |
| :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: | :--------: |
| Model 1 | -7.888732 | 462.4058 | 347.8746 | -0.05189504 | 1.442589 | 0.1372903 | 0.9896478 |
| Model 2 | 25.17813 | 463.9208 | 346.29 | 0.08223255 | 1.433376 | 0.1362873 | 0.9853665 |
| Model 3 | 11.37134 | 466.3588 | 347.9964 | 0.02618351 | 1.441482 | 0.1525857 | 1.004965 | 

The Verdict: While Model 1 and 3 perform adequately on average errors, Model 2 [ARIMA(0,2,1)] achieves the superior Theil's U (0.9853) and lower MAPE (1.4333). Given anticipated macroeconomic shocks, Model 2 is explicitly chosen as the production engine because it relies on momentum acceleration rather than historical drift, aggressively mapping structural breaks.<img width="1857" height="808" alt="image" src="https://github.com/user-attachments/assets/204a9504-c635-4da4-91d6-da7087974ee2" />

11. Stochastic Risk Modeling (Monte Carlo Simulation) : With Model 2 validated as the premier engine, it is deployed to map future tail-risk. 1,000 parallel market universes are simulated for a 12-week horizon. To perform a visual Out-of-Sample VaR (Value at Risk) audit, the actual unseen market values from the test set are plotted directly over the simulation.<img width="1857" height="808" alt="image" src="https://github.com/user-attachments/assets/ba44bdf1-69e5-4255-afbf-bd74df39ec94" /> The "Fat Tail" Reality:The 90% confidence interval successfully bounds the Nifty 50's trajectory across the majority of the horizon. However, the momentary, violent breach of the lower boundary by the actual market data mathematically demonstrates the "fat-tailed" nature of equity markets. It visually proves that while ARIMA models effectively map standard variance, real-world structural market crashes exceed standard Gaussian probabilities.

Language : R

Libraries : forecast, tseries
