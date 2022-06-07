library(rstanarm) #stan_glm
library(BayesTree) #bart() function
library(gtools) # for the "quantcut" function

bart_sim <- read.delim("C:/Users/livel/OneDrive/Documents/UTAustin/Causal Inference/Section 5/HW_5_2/bart_sim2.txt")
covariates = c("X1", "X2")
###Quesiton 3
##part A

X1 <- bart_sim$X1
X2 <- bart_sim$X2
Z <- bart_sim$Z

numerator <- abs(mean(X1[Z == 1]) - mean(X1[Z == 0])) # find the abs difference between the means of treated and controls

numerator / sd(X1[Z == 1]) #standardize

numerator <- abs(mean(X2[Z == 1]) - mean(X2[Z == 0])) # find the abs difference between the means of treated and controls

numerator / sd(X2[Z == 1])
##Part B

pscores <- predict(lalonde_fit, type="response")
matches <- matching(z=lalonde$treat, score=pscores, replace=FALSE)
matched <- matches$cnts

bart_fit <- stan_glm(Z ~ X1 + X2 + X1*X2, family = binomial(link = "logit"), data = bart_sim, algorithm = 'optimizing') 
pscores <- predict(bart_fit, type='response')

#' check overlap by looking at the propensity score histograms across the treatment groups

with(bart_sim, hist(pscores[Z==1], breaks=15, col = rgb(1,0,0, alpha=0.4)))
with(bart_sim, hist(pscores[Z==0], breaks=10, col = rgb(0,0,1, alpha=0.4), add = TRUE, 
                   main = "Histograms of PS", xlab = "ps"))

legend("topright", c("Control", "Treated"), 
       fill = c(rgb(0,0,1, alpha=0.4), rgb(1,0,0, alpha=0.4)))


#' Identify whether each unit has an estimated propensity score that 'overlaps' with
#' with the distribution in the other treatment group
minps_Z0 = min(pscores[Z==0]) 
maxps_Z0 = max(pscores[Z==0])
minps_Z1 = min(pscores[Z==1])
maxps_Z1 = max(pscores[Z==1])

overlap = rep(0, dim(bart_sim)[1])
overlap[Z==0 & pscores >= minps_Z1 & pscores <= maxps_Z1] = 1
overlap[Z==1 & pscores >= minps_Z0 & pscores <= maxps_Z0] = 1

# find the absolute SMD for X2 with overlapping values
numerator <- abs(mean(X2[overlap == 1 & Z==1]) - mean(X2[overlap == 1 & Z == 0]))
numerator/sd(X2[overlap == 1 & Z == 1])

##Part C
bart_sim_overlap = subset(bart_sim, overlap==1)
bart_xt <- as.matrix(bart_sim_overlap[,c("X1", "X2", "Z")])

#' Create test data that includes the covariates of all the treated units but sets the treatment variable = 0
#' This will be used for predicting the *other* potential outcome for the treated units only
#' i.e., for estimating the ATT

bart_xp <- as.matrix(bart_sim_overlap[bart_sim_overlap$Z==1, c(!(names(bart_sim_overlap) %in% c("X", "Y", "p","p_pred")))])
bart_xp[,3]=0

y=as.numeric(bart_sim_overlap[,5])

bart.tot <- bart(x.train=bart_xt,   y.train=y,  x.test=bart_xp) #fit the BART model

# check convergence
library(coda)
plot(as.mcmc(bart.tot$sigma))

#' Use MCMC samples to calculate individual and average treatment effects

#' First calculate MCMC simulations of individual treatment effects by subtracting
#' the observed outcome among treated units from the predicted values had they been
#' untreated (i.e., the "test predictions")
#' This averages across the rows to get the ATT for each MCMC sample, then averages those all together to get the overall ATT
diffs=bart.tot$yhat.train[,bart_sim_overlap$Z==1]-bart.tot$yhat.test 
head(diffs) # a matrix with 1000 MCMC samples (rows) for each of 218 treated units (columns)

#' Row means correspond to the SATE for each MCMC iteration
mndiffs=apply(diffs,1,mean)
length(mndiffs) #A vector of 1000 simulations of the SATE
ATT_bart = mean(mndiffs) # Posterior mean SATE
ATT_bart

##PART D
sdATT_bart = sd(mndiffs) # Posterior standard deviation of the SATE
sdATT_bart

##PART E
#' Now look at the Individual Treatment Effects, (ITEs), noting that estimation may have
#' wide uncertainty with this sample size
#' 
#' The posterior ITEs are the columns of the 1000x218 matrix 'diffs'
#' Now we average down the columns to get each unit's ATT across all samples
ite_means<- apply(diffs, 2, mean)
ite_sds<- apply(diffs, 2, sd)
ite_ql = apply(diffs, 2, quantile, .025)
ite_qu = apply(diffs, 2, quantile, .975)
#' Now plot the ITEs (posterior means and 95% intervals) across the values of a covariate
#' Do this for every covariate just for illustration
for (cov in covariates){
  covplot = bart_sim_overlap[, cov]
  plot(covplot[bart_sim_overlap$Z==1], ite_means, pch=16, cex=0.75, col="red" , 
       main = paste("ATTs as a function of:", cov), xlab = cov, ylab = "ATT")
  arrows(covplot[bart_sim_overlap$Z==1], ite_ql, covplot[bart_sim_overlap$Z==1], ite_qu, col = rgb(0.5,0,0, alpha=0.5), angle=90, length=0.01, lwd=0.5)
}
length(covplot[Z==1])
length(mndiffs)


##PART F
X2_level <- factor(quantcut(bart_xt[,2], q = 3), labels = c("low", "med", "high"))[bart_xt[,3] == 1] #categorize the training data into low/med/high
X2_level

low_diffs <- diffs[ , X2_level == "low"] #separate the low diffs (from the diffs calc'd above)
low_mndiffs <- apply(low_diffs,1,mean) #average across the rows to get the ATT for each MCMC sample
low_ATT <- mean (low_mndiffs)

med_diffs <- diffs[, X2_level == 'med']
med_mndiffs <- apply(med_diffs,1,mean)
med_ATT <- mean(med_mndiffs)

high_diffs <- diffs[, X2_level == 'high']
high_mndiffs <- apply(high_diffs,1,mean)
high_ATT <- mean(high_mndiffs)

low_ATT-med_ATT #find the differences bt the levels
med_ATT-high_ATT

#create a df containing low/med/high diffs with their categories included as a factor
low <- rep('low', 1000)
med <- rep('med', 1000)
high <- rep('high', 1000)
level <- c(low, med, high)
level_diffs <- c(low_mndiffs, med_mndiffs, high_mndiffs)
violin_data <- data.frame(level_diffs, level)
violin_data$level <- as.factor(violin_data$level)

#create violin plot
ggplot(violin_data, aes(x= level, y=level_diffs)) +
  geom_violin(trim = FALSE) + 
  stat_summary(fun.data="mean_sdl", mult=2, geom="crossbar", width=0.2 ) + #include boxplots
  scale_x_discrete(limits=c("low", "med", "high")) #order the plots as needd rather than alphabetical (which is default)

##PART G

  

bart_sim_overlap$X1.5 <- (bart_sim_overlap$X1)*.5
bart_sim_overlap$X2.2 <- (bart_sim_overlap$X2)*2
bart_sim_overlap$X1X2 <- (bart_sim_overlap$X1)*(bart_sim_overlap$X2)
bart_sim_overlap$ZX1 <- (bart_sim_overlap$Z) * (bart_sim_overlap$X1)

bart_correct_fit <- stan_glm(Y ~ Z + X1.5 + X2.2 + X1*X2 + ZX1, data = bart_sim_overlap, refresh = 0)
bart_correct_fit
