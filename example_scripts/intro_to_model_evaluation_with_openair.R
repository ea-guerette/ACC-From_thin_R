#openair has built in functions to assist with model evaluation (model vs. observations)
#note: these functions can also be used to compare sensors, or models  

#we will also need to install the package dplyr to help with combining our datasets 
#install.packages("dplyr")

library(openair)
library(dplyr)

#we will mainly explore two functions: modStats and taylorDiagram,
#both of which expect a dataframe that contains observations and model data for each timestep 

# date        obs    mod 
# 2013-01-01  NA      30.1
# 2013-01-02  25.6    24.2

#load in observations from OEH - notice that the data is in the native RData format 
#I often use this to keep dataframes I have spent a lot of time cleaning up
#the main advantage is that it is super easy to read into R:
load("data/model_evaluation/OEH_obs_MUMBA.RData")

str(oeh_obs_MUMBA) #to have a look at the structure - we have several sites, and also a campaign column 

#we can have a quick look at the data, i.e. let's look at ozone using one of the functions we explored last time: 
timePlot(oeh_obs_MUMBA, pollutant = "O3") #does not work because we have several sites 
timePlot(oeh_obs_MUMBA, pollutant = "O3", type = "site") #makes one panel per site 

#then we need model data - we will use two models in this demo 
#but let's start with one! 

load("data/model_evaluation/CSIRO_model_output_MUMBA.RData")
str(csiroMUMBA)
#there would normally be a lot more variables, but I only kept a few for the purposes of this demonstration
#notice we have "site" and "campaign" (as in the obs) - we also have "data_source", which contains the model identification

#we can have a quick look at the ozone data: 
timePlot(csiroMUMBA, pollutant = "O3", type = "site") #remember we have several sites, so we need to specify type here


#Now we need to combine our two dataframes into 1 dataframe because openair functions only work on single dataframes 

#the modStats and TaylorDiagram functions expect 'side-by-side' data 
#both dataframes have ~17000 rows. If we put them side by side, we would expect roughly the same number of rows, but more columns

#there are several way to do this. {base} has a function called merge()
#the syntax is merge(dataframe1, dataframe2, by = "", suffixes) 
#by lets you specify which column(s) to do a match on - we often want to match by date.
#suffixes let's you specify what to append to the names of the columns so they are unique (i.e O3 is in both dataframes). 
#The default is to add .x to columns of dataframe1 and .y to columns of dataframe2 

#let's try: 
aq_test <- merge(oeh_obs_MUMBA, csiroMUMBA, by = c("date"), suffixes = c(".obs", ".mod")) 
#this has some many more rows then expected!!
#this is because we also need to match by site and by campaign (because these columns exist in both dataframes)
aq <- merge(oeh_obs_MUMBA, csiroMUMBA, by = c("date", "site", "campaign"), suffixes = c(".obs", ".mod")) #now we get something more reasonable
View(aq)

#We can now play with our functions.
#the syntax is similar for both modStats and TaylorDiagram. function_name(dataframe, obs = "column containing obs", mod = "column containing model data")
modStats(aq, obs = "O3.obs", mod = "O3.mod") #overall results 
modStats(aq, obs = "O3.obs", mod = "O3.mod", type = "site") #results for individual sites 


TaylorDiagram(aq, obs = "O3.obs", mod = "O3.mod")
TaylorDiagram(aq, obs = "O3.obs", mod = "O3.mod", group = "site")
TaylorDiagram(aq, obs = "O3.obs", mod = "O3.mod", group = "site", normalise = T ) 
#normalise divides each chunk of data (i.e. site) by the standard deviation of the observations at that site
?TaylorDiagram #to see the help file


#what if we add another model? 
load("data/model_evaluation/CMAQ_model_output_MUMBA.RData")

#how to we include this? 
#let's take a step back - we still want 1 column of model data, and 1 column of observations, 
#so we need to 'stack' our models together, then merge() with the obs
#both model dataframes have 11 columns, and we expect this to remain the ~same (it would increase if column names were not perfectly matched) 
#but the number of rows to be the sum of dataframe1 + dataframe2

#To combine the models, we will use a {dplyr} function called bind_rows(). 
#Note: ({base} has one too, it is called rbind(), but it is less flexible

models <- bind_rows(csiroMUMBA, cmaq_MUMBA)
#this 'stacks' the dataframes together (one below the other, instead of side-by-side) - as expected the result has 11 columns

#we can have a look at the combined data:
scatterPlot(models, x = "date", y = "O3",  
            group = "data_source",  #both model on one panel, in different colours
            plot.type = "l", alpha = 0.5) # plot.type = "l" changes the default dots to a line, alpha = 0.5 adds transparency 

#we can see that we have some tidying to do with the dates
#openair has a function for this - selectByDate() 

models <- selectByDate(models, start = "1/1/2013", end = "15/2/2013") #formatting is day/month/year!
#it's not my favorite for dealing with exact dates (it struggles with timezones), but it is great for selecting a subset of hours, months or years out of a long timeseries

scatterPlot(models, x = "date", y = "O3",  
            group = "data_source", type = "campaign", 
            x.relation = "free", plot.type = "l", alpha = 0.5)


#now we are ready to add the observations to the mix 

aq2 <- merge(oeh_obs_MUMBA, models, by = c("date", "site", "campaign"), suffixes = c(".obs", ".mod"))

modStats(aq2, obs = "O3.obs", mod = "O3.mod") #oops, all results together - surely we want results for each model separately
modStats(aq2, obs = "O3.obs", mod = "O3.mod", type = "data_source") #that's better 
stats <- modStats(aq2, obs = "O3.obs", mod = "O3.mod", type = c("site", "data_source")) #this gives us results for each model at each site

TaylorDiagram(aq2, obs = "O3.obs", mod = "O3.mod", group = "data_source") #two dots (one per model) - indicates overall performance (all sites)
TaylorDiagram(aq2, obs = "O3.obs", mod = "O3.mod", group = "data_source", type = 'site') #two dots (one per model), for each site

#we may get a better result by switching group and type in this case: 
TaylorDiagram(aq2, obs = "O3.obs", mod = "O3.mod", group = "site", type = "data_source")
#normalising puts all the sites on the same basis:
TaylorDiagram(aq2, obs = "O3.obs", mod = "O3.mod", group = "site", type = "data_source", normalise = T)
#normalise divides each chunk of data (i.e. site) by the standard deviation of the observations 


#now, we can create a loop to plot our Taylor diagrams for several species quickly 

#create a list of species we want to plot - the names have to match the columns names in the dataframe
list_of_species <- c("O3", "PM2.5", "CO") #a vector with three elements 

length(list_of_species) #this returns the number of elements 

#now we can set a 'for' loop. 
# i is the counter 
# we start from 1 and we want to go up to the end of the list_of_species - so up to length(list_of_species)
# {} everything between these will be part of the loop 

for(i in c(1:length(list_of_species))) { 
  TaylorDiagram(aq2, obs = paste0(list_of_species[i], ".obs"), mod = paste0(list_of_species[i],".mod"), 
                group = "site", type = "data_source", normalise = T,
                main = list_of_species[i]) #adds a title to the plot 
}

#we use paste0() - this is a function that let's you glue bits of strings (text) together 
paste0("a", " + b")
paste0("5 ", "is the square", " root of 25")

#in the example above, we use bits from list_of_species to create the variable name 
#first iteration, i = 1 
paste0(list_of_species[1], ".obs")
paste0(list_of_species[1],".mod")
#second iteration, i = 2 
paste0(list_of_species[2], ".obs")
paste0(list_of_species[2],".mod")

#etc. 