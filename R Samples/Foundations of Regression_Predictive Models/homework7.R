
library(ggplot2)

data <- read.csv("C:/Users/livel/OneDrive/Documents/UT Austin/Foundations_Regression_Pred_Model/HW7/HW7_data.csv")

x <- data$x
y <- data$y

#initialize theta at 1
t<-1

#iterate 20 times through the N-R algorithm
#u is the first derivative
#v is the second derivative
for(i in 1:20) {
  u <- -sum((y-exp(t*x))*x*exp(t*x))
  v <- sum(x^2*exp(t*x)*(2*exp(t*x)-y))
  t <- t-u/v
}

yh <- exp(t*x)
eh <- y-yh

eh^2

qplot(x,y)+stat_smooth(method="lm", formula="y~exp(x)", se=FALSE)


#PART 3
varhat <- sum(eh^2)/(99)
stdev <- sqrt(varhat)
ttt <- 0

#we want 1000 bootstrap samples
for(j in 1:1000)  {
  tt<-1                             #initialize theta_hat at 1 for each sample
  yy <- exp(t*x)+stdev*rnorm(100)   #generate 100 y's using estimators for mean and variance
  
                                    #use N-R algorithm with new y's to generate a new theta_hat*
  for(i in 2:20) {
    uu <- -sum((yy-exp(tt*x))*x*exp(tt*x))
    vv <- sum(x^2*exp(tt*x)*(2*exp(tt*x)-yy))
    tt <- tt-uu/vv
  }

#collect the current iteration's theta_hat*
ttt[j]<- tt
}

var(ttt)
t*xbar
sqrt(var(ttt))
#PART 5


xbar <- mean(x)

sd <- sqrt((xbar^2)*var(ttt))

t*xbar + (1.96*sd)
t*xbar - (1.96*sd)

j<-1
new_y<-0
new_t<-1
for(j in 1:1000)  {
                              
  ln_y <- t*xbar+stdev*rnorm(100)   #generate 100 y's using estimators for mean and variance
  
  #use N-R algorithm with new y's to generate a new theta_hat*
  for(i in 2:20) {
    uu <- -sum((ln_y-exp(new_t*x))*x*exp(new_t*x))
    vv <- sum(x^2*exp(new_t*x)*(2*exp(new_t*x)-ln_y))
    new_t <- new_t-uu/vv
  }
  
  #collect the current iteration's log(y) value
  new_y[j]<- new_t*xbar
}
# sd <- sqrt(var(new_y))
# t*xbar + (1.96*sd)
# t*xbar - (1.96*sd)
