#loading the required library 
library(tseries)   
library(forecast)

data <- read.csv(file.choose(),header=TRUE)

par(mfrow=c(1,1))
plot(data$Adj.Close,ylab="Nifty Price",xlab="Time (weeks)",type="l")
#an increasing trend can be seen, hence our data isn't stationary
#differencing is required to make it stationary

par(mfrow=c(2,1))
plot(diff(data$Adj.Close),type="l",main="d=1") #d=1
plot(diff(diff(data$Adj.Close)),type="l",main="d=2") #d=2
#no trend or seasonality can be seen in above graphs


#Augmented Dickey-Fuller Test to check stationarity 

#h0(null) : data is not stationarity 
#h1(alternative) : data is stationary 

adf.test(data$Adj.Close)
#p value = 0.7633, which is greater than 0.05
#non stationary
adf.test(diff(data$Adj.Close))
#p value = 0.01, which is smaller than 0.05
#d=1 is stationary
adf.test(diff(diff(data$Adj.Close)))
#p value = 0.01, which is smaller than 0.05
#d=2 is stationary


#Fitting the model

#ACF and PACF graphs for estimating p and q values for d=1 and d=2
par(mfrow=c(2,2))
diff1 <- diff(data$Adj.Close)
acf(diff1, main = "ACF (d=1)")
pacf(diff1, main = "PACF (d=1)")

diff2 <- diff(diff(data$Adj.Close))
acf(diff2, main = "ACF (d=2)")
pacf(diff2, main = "PACF (d=2)")
#for d=1, according to acf and pacf graph, p=0,q=0
#for d=2, according to graph pacf doesn't decay to 0 exponentially 
#arima model with parameters (0,1,0) is selected

#AIC and BIC for selecting the best model 
#model with least AIC and BIC value is better 
rname <- c("p=0","p=1","p=2","p=3","p=4","p=5")
cname <- c("q=0","q=1","q=2","q=3","q=4","q=5")
aic_d1 <- matrix(NA,6,6,dimnames =list(rname,cname))#AICmatrix for d=1 & p=q=0:5
bic_d1 <- matrix(NA,6,6,dimnames =list(rname,cname))#BICmatrix for d=1 & p=q=0:5
aic_d2 <- matrix(NA,6,6,dimnames =list(rname,cname))#AICmatrix for d=2 & p=q=0:5
bic_d2 <- matrix(NA,6,6,dimnames =list(rname,cname))#BICmatrix for d=2 & p=q=0:5

for (p in 0:5) {
  for (q in 0:5) {
    tryCatch({
    model <- Arima(data$Adj.Close,order=c(p,1,q))
    aic_d1[p+1,q+1] <- model$aic
    bic_d1[p+1,q+1] <- model$bic
    }, error = function(e) {
    })
  }
}
aic_d1;min(aic_d1)
bic_d1;min(bic_d1)

for (p in 0:5) {
  for (q in 0:5) {
    tryCatch({
    model <- Arima(data$Adj.Close,order=c(p,2,q))
    aic_d2[p+1,q+1] <- model$aic
    bic_d2[p+1,q+1] <- model$bic
    }, error = function(e) {
    })
  }
}
aic_d2;min(aic_d2)
bic_d2;min(bic_d2)
#arima model with parameters (0,2,1) have the least aic and bic values 

auto.arima(data$Adj.Close)
#arima model with parameters (2,1,0) and drift 

#we selected three different models from above 
#model 1 = ARIMA(0,1,0) using acf and pacf graphs
#model 2 = ARIMA(0,2,1) using AIC and BIC values
#model 3 = ARIMA(2,1,0) with drift using auto.arima

model1_010 <- Arima(data$Adj.Close,order=c(0,1,0))
model2_021 <- Arima(data$Adj.Close,order= c(0,2,1))
model3_210_drift <- Arima(data$Adj.Close,order=c(2,1,0),include.drift = TRUE)


#Ljung Box test for testing the residuals 
#h0(null) : residuals are independently distributed
#h1(alternative) : residuals are not independently distributed

pvalue_model1 <- rep(0,12)
for (i in 1:12) {
test <- Box.test(model1_010$residuals,lag= i,type="Ljung-Box")
pvalue_model1[i] <- test$p.value
}

pvalue_model2 <- rep(0,12)
for (i in 1:12) {
  test <- Box.test(model2_021$residuals,lag= i,type="Ljung-Box")
  pvalue_model2[i] <- test$p.value
}

pvalue_model3 <- rep(0,12)
for (i in 1:12) {
  test <- Box.test(model3_210_drift$residuals,lag= i,type="Ljung-Box")
  pvalue_model3[i] <- test$p.value
}

pvalues <- cbind(pvalue_model1,pvalue_model2,pvalue_model3)
pvalues
# From the matrix above, all p-values for models 1-3 across lags 1:12
# are > 0.05. We fail to reject h0. 
# The residuals are independently distributed as pure white noise.


#Calculating percentage error for all the models
pct_error_model1 <- (model1_010$residuals/data$Adj.Close)*100
pct_error_model2 <- (model2_021$residuals/data$Adj.Close)*100
pct_error_model3 <- (model3_210_drift$residuals/data$Adj.Close)*100

#Plotting Absolute Percentage Error
par(mfrow = c(3, 1), mar = c(3, 4, 3, 2))

plot(abs(pct_error_model1), type = "h", col = "black",
     ylab = "Percentage Error (%)", xlab = "",
     main = "Model 1: ARIMA(0,1,0)")
abline(h = 2, col = "orange")
abline(h = 5, col = "red")
legend("topright",col = c("red","orange"),legend=c("5%","2%"),pch=15,bty="n",cex=0.8)

plot(abs(pct_error_model2), type = "h", col = "black",
     ylab = "Percentage Error (%)", xlab = "",
     main = "Model 2: ARIMA(0,2,1)")
abline(h = 2, col = "orange")
abline(h = 5, col = "red")
legend("topright",col = c("red","orange"),legend=c("5%","2%"),pch=15,bty="n",cex=0.8)

plot(abs(pct_error_model3), type = "h", col = "black",
     ylab = "Percentage Error (%)", xlab = "Time (Weeks)",
     main = "Model 3: ARIMA(2,1,0) with Drift")
abline(h = 2, col = "orange")
abline(h = 5, col = "red")
legend("topright",col = c("red","orange"),legend=c("5%","2%"),pch=15,bty="n",cex=0.8)

round(summary(abs(pct_error_model1)),5)
round(summary(abs(pct_error_model2)),5)
round(summary(abs(pct_error_model3)),5)
#There isn't a significant difference between the quantiles and mean of different models
#But model 2 has the least maximum value among them.


#One step forward forecasting and comparison with testdata 
testdata <- read.csv(file.choose(),header=TRUE)

#Forecasting for model 1 : Arima(0,1,0)
historicalvalues <- data$Adj.Close
actualvalues <- testdata$Adj.Close
predicted_model1 <- rep(0,72)
predicted_model1[1] <- tail(data$Adj.Close,1)
for (i in 1:71) {
  fit <- Arima(historicalvalues,order=c(0,1,0))
  predicted_model1[i+1] <- forecast(fit,h=1)$mean
  historicalvalues <- c(historicalvalues,actualvalues[i])
}

#Forecasting for model 2 : Arima(0,2,1)
historicalvalues <- data$Adj.Close
predicted_model2 <- rep(0,72)
predicted_model2[1] <- tail(data$Adj.Close,1)
for (i in 1:71) {
  fit <- Arima(historicalvalues,order=c(0,2,1))
  predicted_model2[i+1] <- forecast(fit,h=1)$mean
  historicalvalues <- c(historicalvalues,actualvalues[i])
}

#Forecasting for model 3 : Arima(2,1,0) with drift
historicalvalues <- data$Adj.Close
predicted_model3 <- rep(0,72)
predicted_model3[1] <- tail(data$Adj.Close,1)
for (i in 1:71) {
  fit <- Arima(historicalvalues,order=c(2,1,0),include.drift = TRUE)
  predicted_model3[i+1] <- forecast(fit,h=1)$mean
  historicalvalues <- c(historicalvalues,actualvalues[i])
}

#Plotting forecasted values with actual values
par(mfrow = c(3, 1))
plot(c(tail(data$Adj.Close,1),actualvalues),type="l",
     main="Model 1 : ARIMA(0,1,0) vs Actual Values",
     ylab="",
     xlab="")
lines(1:72,predicted_model1,col="red")
legend("topleft", legend=c("Actual", "1-Step Forecast"),
       col=c("black", "red"),bty="n",cex=0.8,pch=15)

plot(c(tail(data$Adj.Close,1),actualvalues),type="l",
     main="Model 2 : ARIMA(0,2,1) vs Actual Values",
     ylab="",
     xlab="")
lines(1:72,predicted_model2,col="red")
legend("topleft", legend=c("Actual", "1-Step Forecast"),
       col=c("black", "red"), bty="n",cex=0.8,pch=15)

plot(c(tail(data$Adj.Close,1),actualvalues),type="l",
     main="Model 3 : ARIMA(2,1,0) vs Actual Values",
     ylab="",
     xlab="Time (Weeks)")
lines(1:72,predicted_model3,col="red")
legend("topleft", legend=c("Actual", "1-Step Forecast"), 
       col=c("black", "red"),bty="n",cex=0.8,pch=15)

#comparing predicted values with actual values 
accuracy(actualvalues,ts(predicted_model1[2:72]))
accuracy(actualvalues,ts(predicted_model2[2:72]))
accuracy(actualvalues,ts(predicted_model3[2:72]))

#Model 1: Lowest Root Mean Square Error (RMSE = 462.40)
#Model 2: Best Theil's U (0.9853), proving superior out of sample predictive skill
#Model 3: Lowest Mean Percentage Error (MPE = 0.026%)

#We move forward with model 2 : ARIMA(0,2,1)
#Model 1 is a simple random walk while model 3 relies on drift 
#Model 2 is more complex than model 1 and doesn't depend on drift 
#which means it'll capture economic shocks such as geopolitical tensions better than model 3


#Monte Carlo Simulation 

#Simulation using ARIMA(0,2,1)

sim_matrix <- matrix(NA,1000,71)
set.seed(1000)
#Generating simulations
for (i in 1:1000) {
  sim_matrix[i,] <- simulate(model2_021,nsim=71)
}

mean_path <- apply(sim_matrix, 2, mean)#mean path 
lower_90  <- apply(sim_matrix, 2, quantile, probs = 0.05)#lower bound of 90% confidence interval
upper_90  <- apply(sim_matrix, 2, quantile, probs = 0.95)#upper bound of 90% confidence interval
par(mfrow=c(1,1))
#Plotting simulations
plot(0:71,c(tail(data$Adj.Close,1),sim_matrix[1,]), type = "l",
     col = rgb(0.5, 0.5, 0.5, 0.15),
     xlim = c(1, 72), ylim = c(min(sim_matrix), max(sim_matrix)),
     main = "1,000 Monte Carlo Simulations(Time Series)",
     xlab = "Time (Weeks)",
     ylab = "Nifty 50 Price")
for (i in 2:1000) {
  lines(0:71,c(tail(data$Adj.Close,1),sim_matrix[i,]),col = rgb(0.5, 0.5, 0.5, 0.15))
}
#Plotting mean and 90% confidence interval path 
lines(0:71,c(tail(data$Adj.Close,1),mean_path),col="blue")
lines(0:71,c(tail(data$Adj.Close,1),lower_90),col="red")
lines(0:71,c(tail(data$Adj.Close,1),upper_90),col="red")
lines(0:71,c(tail(data$Adj.Close,1),actualvalues),col="darkgreen")
legend("topleft", legend = c("Mean Path", "90% Confidence Interval","Actual Value"), 
       col = c("blue", "red","darkgreen"),bty="n",cex=0.75,pch=15)


#Simulation using Geometric Brownian Motion 

#Calculating parameters
log_returns <- diff(log(data$Adj.Close))
mu <- mean(log_returns, na.rm = TRUE)
sigma <- sd(log_returns, na.rm = TRUE)

#Setting up simulation matrix 
gbm_matrix <- matrix(NA,1000,72)
gbm_matrix[,1] <- tail(data$Adj.Close,1)

#Generating Simulations 
set.seed(1000)
for (i in 1:1000) {
 for (j in 1:71) {
   z <- rnorm(1)
   gbm_matrix[i,j+1] <- gbm_matrix[i,j]*exp((mu-(sigma^2)/2)+sigma*z)
 } 
}

gbm_mean_path <- apply(gbm_matrix, 2, mean) #mean path
gbm_upper_90 <- apply(gbm_matrix, 2, quantile, probs = 0.95) #upper bound of 90% confidence interval
gbm_lower_90 <- apply(gbm_matrix, 2, quantile, probs = 0.05) #lower bound of 90% confidence interval

#Plotting Simulations
plot(0:71,gbm_matrix[1,],type="l",
     col = rgb(0.5, 0.5, 0.5, 0.15),
     xlim = c(1, 72), ylim = c(min(gbm_matrix), max(gbm_matrix)),
     main = "1,000 Monte Carlo Simulations(Geometric Brownian Motion)",
     xlab = "Time (Weeks)",
     ylab = "Nifty 50 Price")
for (i in 2:1000) {
  lines(0:71,gbm_matrix[i,],col = rgb(0.5, 0.5, 0.5, 0.15))
}

#Plotting mean and 90% confidence interval path
lines(0:71,gbm_mean_path,col="purple")
lines(0:71,gbm_lower_90,col="darkorange")
lines(0:71,gbm_upper_90,col="darkorange")
lines(0:71,c(tail(data$Adj.Close,1),actualvalues),col="darkgreen")
legend("topleft", legend = c("Mean Path", "90% Confidence Interval","Actual Value"), 
       col = c("purple", "darkorange","darkgreen"),bty="n",cex=0.75,pch=15)


#Comparing the mean paths and confidence intervals 
plot(0:71,c(tail(data$Adj.Close,1),actualvalues),type="l",lwd=1.5,
     col="darkgreen",
     xlim = c(1, 72), ylim = c(min(gbm_lower_90), max(gbm_upper_90)),
     xlab = "Time (Weeks)",
     ylab = "Nifty 50 Price" )
lines(0:71,gbm_lower_90,col="darkorange")
lines(0:71,gbm_upper_90,col="darkorange") 
lines(0:71,c(tail(data$Adj.Close,1),lower_90),col="red")
lines(0:71,c(tail(data$Adj.Close,1),upper_90),col="red")
lines(0:71,gbm_mean_path,col="purple")
lines(0:71,c(tail(data$Adj.Close,1),mean_path),col="blue")
legend("topleft", legend = c("90% Confidence Interval (Geometric Brownian Motion)","90% Confidence Interval (Time Series)","Mean Path (Geometric Brownian Motion)","Mean Path (Time Series)","Actual Value"), 
       col = c("darkorange","red","purple","blue","darkgreen"),bty="n",cex=0.75,pch=15)
#The lower bound of time series confidence interval is breached multiple times in the starting 15 weeks time frame
#but later on as interval widens, no breach was observed
#GBM created extremely wide confidence interval 

#Comparing mean paths of gbm and time series 
accuracy(actualvalues,mean_path)
accuracy(actualvalues,gbm_mean_path[2:72])

#Time series mean path out performs gbm in every parameter
