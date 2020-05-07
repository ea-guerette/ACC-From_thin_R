#openair has built in functions to assist with model evaluation 
#note: these functions can also be used to compare sensors  

#we will also need to install the package dplyr to help with combining our datasets 
#install.packages("dplyr")

library(openair)
library(dplyr)

#we will mainly explore two functions: modStats and taylorDiagram,
#both of which expect a dataframe that contains observations and model data for each timestep 

# date        o3.obs    o3.mod 
# 2013-01-01  NA          30.1
# 2013-01-02  25.6        24.2

#load in observations from OEH 

load("data/model_evaluation/OEH_obs_MUMBA.RData")
str(oeh_obs_MUMBA)

timePlot(oeh_obs_MUMBA, pollutant = "O3", type = "site")

#then we need model data - we will use two models here (instead of 6 as in the paper)
#but we will start with one! 

load("data/model_evaluation/CSIRO_model_output_MUMBA.RData")
str(csiroMUMBA)
#there would normally be a lot more variables, but I only kept a few for the purposes of this demonstration

#we can have a quick look at the ozone data (which we will use here): 
timePlot(csiroMUMBA, pollutant = "O3", type = "site")


#we need to combine this into 1 dataframe because openair functions only work on single dataframes 
names(oeh_obs_MUMBA)
names(csiroMUMBA)

#the functions expect 'side-by-side' data 
#there are several way to do this. {base} has a function called merge()

aq_test <- merge(oeh_obs_MUMBA, csiroMUMBA, by = c("date"), suffixes = c(".obs", ".mod"))
aq <- merge(oeh_obs_MUMBA, csiroMUMBA, by = c("date", "site", "campaign"), suffixes = c(".obs", ".mod"))


modStats(aq, obs = "O3.obs", mod = "O3.mod")
modStats(aq, obs = "O3.obs", mod = "O3.mod", type = "site")


TaylorDiagram(aq, obs = "O3.obs", mod = "O3.mod")
TaylorDiagram(aq, obs = "O3.obs", mod = "O3.mod", group = "site")
TaylorDiagram(aq, obs = "O3.obs", mod = "O3.mod", group = "site", normalise = T ) 
#normalise divides each chunk of data (i.e. site) by the standard deviation of the observations 
?TaylorDiagram


#what if we add another model? 
load("data/model_evaluation/CMAQ_model_output_MUMBA.RData")

#how to we include this? 
#let's take a step back 


#first we can combine the models using a {dplyr} version 

models <- bind_rows(csiroMUMBA, cmaq_MUMBA)
#this 'stacks' the dataframes together (one below the other, instead of side-by-side )

#we can have a look at this new data
scatterPlot(models, x = "date", y = "O3",  
            group = "data_source",  
            x.relation = "free", plot.type = "l", alpha = 0.5)

#we can see that we have some tidying to do with the dates
#openair has a function for this 

models <- selectByDate(models, start = "1/1/2013", end = "15/2/2013") #formatting is day/month/year!
#it's not my favorite for dealing with exact dates, but it is great for selecting a subset of hours, months or years 

scatterPlot(models, x = "date", y = "O3",  
            group = "data_source", type = "campaign", 
            x.relation = "free", plot.type = "l", alpha = 0.5)


#now we add the observations to the mix 

aq2 <- merge(oeh_obs_MUMBA, models, by = c("date", "site", "campaign"), suffixes = c(".obs", ".mod"))

modStats(aq2, obs = "O3.obs", mod = "O3.mod")
modStats(aq2, obs = "O3.obs", mod = "O3.mod", type = "data_source")
stats <- modStats(aq2, obs = "O3.obs", mod = "O3.mod", type = c("site", "data_source"))


TaylorDiagram(aq2, obs = "O3.obs", mod = "O3.mod", group = "data_source") 
TaylorDiagram(aq2, obs = "O3.obs", mod = "O3.mod", group = "data_source", type = 'site')

#we may get a better result by switching group and type in this case: 
TaylorDiagram(aq2, obs = "O3.obs", mod = "O3.mod", group = "site", type = "data_source")
#normalising puts all the sites on the same basis:
TaylorDiagram(aq2, obs = "O3.obs", mod = "O3.mod", group = "site", type = "data_source", normalise = T)
#normalise divides each chunk of data (i.e. site) by the standard deviation of the observations 

species <- c("O3", "PM2.5")

for(i in c(1:length(species))) {
  TaylorDiagram(aq2, obs = paste0(species[i], ".obs"), mod = paste0(species[i],".mod"), 
                group = "site", type = "data_source", normalise = T,
                main = species[i]) 
}

  