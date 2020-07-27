#an exploration of curve fitting with R 
#warning #1: we don't even scratch the surface 
#we will not cover timeseries modelling here 

library(tidyverse)
library(broom) #may need to install this, has useful functions for tidying curve fitting model outputs 
library(lattice)
library(lmodel2) #will need to install this if you want to use it 
library(deming) #will need to install this if you want to use it 
library(openair)

#Since R is a statistical software, there are many fitting tools built in. 
#warning #2: you need to do your stats homework before using any of this!

#e.g.

#stats package:
#lm(): linear model (least-square): i.e. cal curves:  ax + b, ax^2 + bx +c, log(x)  == Ordinary Least Suares (OLS)
#glm(): generalized linear models:  if error distribution is not gaussian/normal (i.e. poisson for counts)  
#nls(): non-linear least square

#lmodel2 package: 
#OLS, RMA, MA, SMA (reduced major axis): when error in x is not negligible 

#deming package (x and y have errors of similar magnitude)
# similar to lmodel2 but lets you weigh each data point by its sd

#nlme package: linear and non-linear mixed-effects models 

#mgcv package: general additive modelling


#Let's make up some data and fit a curve to it. 
#We will then use three different plotting packages to plot the results 

#This example is based on this: 
#https://www.r-graph-gallery.com/44-polynomial-curve-fitting.html

x <- runif(300,  min=-10, max=10) #runif stands for 'random uniform' distribution - we will get 300 numbers between -10 and 10
y <- 0.1*x^3 - 0.5 * x^2 - x + 10 + rnorm(length(x),0,8) #we create a y that is a function of x, plus some some randomness to it


#let's have a look at the data we created above: 
# plot of x and y using base graphics:
plot(x,y,col=rgb(0.4,0.4,0.8,0.6),pch=16 , cex=1.3) #col=rgb(0.4,0.4,0.8,0.6) gives the purple color
#pch=16 gives the filled points, cex = 1.3 makes the points 30% larger than the default


# Can we find a polynomial that fits this function ? (easy! we based our y on a polynomial...)
#we use lm to fit the curve. I() is used to inhibit the interpretation of the ^ operator as a formula operator so it is used as an arithmetical operator instead.
model <- lm(y ~ x + I(x^2) + I(x^3)) 

#model is a list containing 12 elements 

plot(model) # press enter in the console below to see diagnostic plots 

plot(model$residuals) #you can plot the residuals 

coef(model) #you can print the coefficients of the curve 

summary(model) #useful visual summary - not so great if you want to save the output and use it in something else 

#other options using the broom package: 
#library(broom)
df <- broom::tidy(model)
View(df)
broom:glance(model)


#plotting using base graphics 
plot(x,y,col=rgb(0.4,0.4,0.8,0.6),pch=16 , cex=1.3) #this is the same as above 
curve(coef(model)[1] + coef(model)[2]*x + coef(model)[3]*x^2 + coef(model)[4]*x^3, add = TRUE)



#plotting using ggplot

#first, we need to combine our x and y into a dataframe
df <- tibble(x = x, y = y)
View(df)
model <- lm(y ~ x + I(x^2) + I(x^3), data = df) #this time we need to tell lm where the data is 

#ggplot works better when the function is saved externally: 
f = function(x, a,b,c,d) {d + c*x + b*x^2 + a*x^3}

ggplot(df, aes(x = x, y=y )) + 
  geom_point(colour = rgb(0.4,0.4,0.8,0.6)) + 
  geom_smooth(method= lm, formula = y ~ x + I(x^2) + I(x^3), col = "red") + #this fits the data as part of the plotting
  stat_function(fun = f, args = list(d = coef(model)[1], c= coef(model)[2], b = coef(model)[3], a = coef(model)[4] ) )
#stat_function lets you use coefficients you obtained elsewhere, which is useful especially if you are fitting a model not covered by geom_smooth(method=). 
#Also geom_smooth does not return fit/model info so not so useful for evaluating how good the fit is (statistically). 

#another example using the gapminder data:  
gapminder <- read.csv("data/gapminder.csv")

ggplot(gapminder, aes(x = gdpPercap, y = lifeExp )) + 
  geom_point(mapping = aes(colour = continent), alpha = 0.5) + 
  scale_x_log10() +
  geom_smooth(mapping= aes(colour = continent), method = "lm", formula = y~x,  size = 1) +
  geom_smooth(method = "lm", formula = y~x, colour = "black", size  =2)

ggplot(gapminder, aes(x = gdpPercap, y = lifeExp )) + 
  geom_point(mapping = aes(colour = continent), alpha = 0.5) + 
  scale_x_log10() +
  geom_smooth(mapping= aes(colour = continent), method = "lm", size = 1) +
  facet_wrap(~continent)
#I could not get it to fit a lmodel2/deming curve 
#Cannot get the fit data out (coeffs, r squared, etc. )


#plotting with lattice 
#library(lattice)
xyplot(y ~ x, data = df, col = rgb(0.4,0.4,0.8,0.6), pch = 16, 
       panel = function(...){
       panel.xyplot(...) 
       panel.abline(v = 0) #lets us add vertical (v) or horizontal (h) lines
       panel.curve(coef(model)[1] + coef(model)[2]*x + coef(model)[3]*x^2 + coef(model)[4]*x^3) #this is similar to basic
       }
)



#not for linear fits. 

#let's make new data: 
x <- runif(300,  min=0, max=20) 
y <- 8*x + 10 + rnorm(length(x),0,8) 

#this is what the data look like: 
plot(y~x)
abline(reg = mod) # only works for linear models (2 coefficients) - use curve() for polynomials 
 
mod <- lm(y ~ x) #this is OLS - assumes error in x << error in y 
summary(mod)

broom::glance(mod)

#make the plot with the fitted line on top 
plot(y~x)
abline(reg = mod) #only works when model has 2 coefficients only - use curve() for polynomials
 
#what is OLS assumptions are not met? 

#library(lmodel2)
mod_2 <- lmodel2::lmodel2(y~x) #, range.y = 'interval', range.x = 'interval', nperm = 5) #the extra args are needed for RMA
#please read the documentation that comes with the package
mod_2$rsquare
plot(mod_2, "SMA") #does not plot diagnosis, plots data + fitted curve 

#another option: 
#library(deming)
deming::deming(y~x) #gives same results as MA from lmodel2? Uses Maximum Likelihood Estimation 
#lets you fit only a subset, also let you use xstd and ystd as weights 


#It's worth covering what is in openair
#Please read the manual for more information
#library(openair)

#linear = TRUE in scatterPlot: uses lm #only marginally useful 
#mod.lines = TRUE in scatterPlot: 1:1, 1:2 and 2:1 lines 
#TheilSen - monotonic increase/decrease
#Given a set of n x,y pairs, the slopes between all pairs of points are calculated. 
#The Theil-Sen estimate of the slope is the median of all these slopes.
#tends to yield accurate confidence intervals even with non-normal data and heteroscedasticity (non-constant error variance). 
#It is also resistant to outliers
#smoothTrend - Generalized Additive Modelling using the mgcv package
#In this case, the model is a relationship between time and pollutant concentration i.e. a trend
library(openair)
scatterPlot(mydata, x= "co", y = "nox", smooth = T) #seems very sensitive to outliers 
scatterPlot(mydata, x= "co", y = "nox", linear = T) #this uses lm() so gives OLS - probably not appropriate in this case (because errors in NOx and CO are probably similar)
scatterPlot(mydata, x= "co", y = "nox", spline = T) #?
scatterPlot(mydata, x= "nox", y = "pm25", mod.line = T) #useful when comparing two instruments or AQ model vs observations (2:1, 1:1, 1:2 lines)

#to calculate monotonic trends over time 
TheilSen(mydata,pollutant= "o3", ylab= "ozone (ppb)", deseason= TRUE)
TheilSen(mydata,pollutant= "o3", type = "wd", ylab= "ozone (ppb)", deseason= TRUE) #can split the data using type, very cool, but check that this is appropriate for your dataset!
#can save the results and extract the stats: 
o3_trend_plot <- TheilSen(mydata,pollutant= "o3", type = "wd", ylab= "ozone (ppb)", deseason= TRUE)
o3_trend_data <- o3_trend_plot$data[[2]]

smoothTrend(mydata,pollutant= "o3", ylab= "ozone (ppb)", deseason = TRUE)
smoothTrend(mydata,pollutant= "o3", ylab= "ozone (ppb)", deseason = TRUE, simulate = TRUE) #uses bootstrap 

TheilSen(mydata,pollutant= "no2", ylab= "no2 (ppb)", deseason= TRUE) #not monotonic!!
test<- smoothTrend(mydata,pollutant= "no2", ylab= "no2 (ppb)", deseason = TRUE) #read the manual to know what this does behind the scenes
smoothTrend(mydata,pollutant= "no2", ylab= "no2 (ppb)", deseason = TRUE, simulate = TRUE)
test_fit <- test$data[[2]] #not stats, but the curve info is there-ish 

#Read the descriptions for these functions in the manual and if you really want to go deeper, have a look at Appendix B 



#So far, we have applied our fitting to the entire set only. 
#What if we want to fit subsets only (i.e. by 'type' as in openair)
#Here is one approach. I found this example here: 
#https://stackoverflow.com/questions/1169539/linear-regression-and-group-by-in-r

d <- data.frame(state=rep(c('NY', 'CA'), c(10, 10)),
                year=rep(1:10, 2),
                response=c(rnorm(10), rnorm(10)))
plot(response~year, data =d)

#use dplyr (part of tidyverse)

fitted_models = d %>% dplyr::group_by(state) %>% dplyr::do(model = lm(response ~ year, data = .))# %>% glance(model)

fitted_models %>% rowwise() %>% tidy(model) 
#we get fit info for each state separately 

