#This session is all about the package openair. 
#To install it, run this: (not needed if you installed it last time)
#install.packages("openair")

#load the openair package: (this is needed EVERYTIME)
library(openair)

#openair comes with example data, called 'mydata'
#we will use 'mydata' to explore some openair functions

#first, let's look at the structure of 'mydata': 
str(mydata)
#the printout in the console tells us there are 655533 obs and 10 variables 

#print names of columns - useful when trying to recall the name of the variables in the dataframe!
names(mydata)

#print first 6 rows of mydata
head(mydata)

#print last 6 rows of mydata
tail(mydata)
tail(mydata,15) #prints last 15 rows

#openair wants date called 'date', wind direction as "wd" and wind speed as "ws" 
#this is because its functions have built-in capabilities to handle time averaging and wind direction (vector) averaging
#the names of all other variables are up to you 

windRose(mydata) 
#notice how the function call does not need to specify which columns to use - openair automatically looks for wd and ws and makes the plot 
#a preview of the plot appears bottom left in the "Plots" tab 

windRose(mydata, type = "year") #makes one windRose for each year in the data 
windRose(mydata, type = "month") #makes one windRose for each month of the year - will average several years of data automatically
#neither 'year' or 'month' are columns in mydata - openair uses the information contained in 'date' to cut the data into the appropriate chunks

#you can save a plot to a variable: 
wr_plot <- windRose(mydata, type = "month")
#wr_plot is a list with three elements. The first element is a list containing the plotting information. 
#the second element is a dataframe that contains the data that went into the plot - this is a very useful feature 

#we can save this data into a variable of its own: 
summary_wr_data <- wr_plot$data
#we get a dataframe that we can use elsewhere - we are taling advantage of the built-in averaging of the plotting function 

#taking a step back: 
#openair has a few "exploratory" functions, including timePlot and scatterPlot
#openair also has many many aggregating functions

#let's start with the exploratory functions - it is alway best practice to look at the full dataset before starting to aggregating it 
#timePlot is for timeseries plotting: 
timePlot(mydata, pollutant = "o3" ) #this is the complete ozone timeseries
#there is no need to specify to use 'date' because timePlot assumes you want to plot a timeseries

#it is possible to plot multiple species at the same time, the default is to create one panel per species:  
timePlot(mydata, pollutant = c("wd", "o3") ) #notice c() to make a list of pollutants to plot
#notice how openair automatically labels 'wd' as wind dir., and formats 'o3'

#also notice how both species have the same y-axis - not necessarily the best option
#setting y.relation to "free" solves that issue: 
timePlot(mydata, pollutant = c("wd", "o3"), y.relation = "free" )

#looking at some of the species that had some missing data when we printed the 'head' and 'tail'
timePlot(mydata, pollutant = c("pm25", "so2"), y.relation = "free" ) 
#we can see that we are missing the last year or so of so2 data 


#scatterPlot lets you plot any variable against any other
#let's plot NO2 vs NOx as an example: 
scatterPlot(mydata, x = "nox", y = "no2")
#there are so much data that it is hard to see the details. 
#some ways to get around this:
scatterPlot(mydata, x = "nox", y = "no2", method = "density") 
scatterPlot(mydata, x = "nox", y = "no2", method = "hexbin")
#in both options, the colour give an indication of how much of data there is in each area of the plot

#it is also possible to colour the data points by another variable, using 'z':
scatterPlot(mydata, x = "nox", y = "no2", z = "ws")

#this works better for variables that are correlated: 
scatterPlot(mydata, x = "nox", y = "no2", z = "o3", alpha = 0.5) 
#alpha adds transparency to the dots - it can work well in some situation - here I'd say we have too much data 

#we can explore the relationship under low windspeed (i.e. <2 m/s)
#one option is to create a new dataframe that only contains the data of interest:
low_ws_data <- subset(mydata, ws <2)
#this is definitely worth doing if you are going to reuse this a lot. 
#the other option is to use subset within the plotting function:
scatterPlot(subset(mydata, ws <2), x = "nox", y = "no2")
#note that this is equivalent to scatterPlot(low_ws_data, x = "nox", y = "no2")

#a quick way to look at the relationship under various wind speed conditions is to use "type"
scatterPlot(mydata, x = "nox", y = "no2", type = "ws")
#this makes one panel for each quartile of wind speeds 
#notice the message in the console - telling us that 632 rows had missing ws data and were removed from the dataframe before plotting

#similarly, this creates a panel for each quartile of ozone values: 
scatterPlot(mydata, x = "nox", y = "no2", type = "o3")

#we can also use any of the 'keywords' that openair understands: "year", "month", "season", etc. see the manual for a list
scatterPlot(mydata, x = "nox", y = "no2", type = "season")

#we can use both z and type: 
scatterPlot(mydata, x = "nox", y = "no2", z = "o3", type = "season")


#Now lets look at some 'aggregating' functions 

#windRose is one that we covered earlier 

#timeVariation is useful, if not necessarily for the resulting plot, at least for its 'aggregating powers'

timeVariation(mydata, pollutant = "o3")

#as for the windRose earlier, we can save this plot as a variable: 
o3_varPlot <- timeVariation(mydata, pollutant = "o3")
#this time the result is a list containing 5 elements

#to print just one of the four plots:
print(o3_varPlot, subset = "hour") #diurnal cycle
print(o3_varPlot, subset = "month") #annual cycle 

#to access the diurnal cycle data 
o3_diurnal_data <- o3_varPlot$data$hour

#All aggregating functions will treat wind direction averaging properly, as long as 'wd' and 'ws' are there
#to test this, lets make a new variable containing wd data, but called "wind_direction": 
mydata$wind_direction <- mydata$wd

timeVariation(mydata, pollutant = c("wd", "wind_direction"))
#the teal-coloured line is for "wind_direction"
#openair did not recognise it as wd, and applied scalar averaging instead of the correct vector averaging

#the default is to plot the mean and a confidence interval, but other stats are available, i.e. median
timeVariation(mydata, pollutant = "nox", statistic = "median")
#this plots the median, the 25/75th and 5/95th quantiles

#to remove the confidence interval, set ci = FALSE
timeVariation(mydata, pollutant = "nox", statistic = "median", ci = FALSE)


#timeAverage is not a plotting function, but is a very powerful averaging function
#it lets us convert i.e. minute data into hourly averages using one line of code. 
#in our case, we already have hourly data, but we can still play around, for example, by making monthly averages: 

monthly_data <- timeAverage(mydata, avg.time = "month")
View(monthly_data)
#we can see we now have one row for each month of data. 
#wd has been vector averaged (correct) whereas wind_direction has not 

#the function is very flexible, e.g. we can specify a certain number of hours to average over:
timeAverage(mydata, avg.time = "3 hour")

#IMPORTANT: the function will return a value as long as 1 data point is available in the period being averaged. 
#the function lets us change the default and set a threshold: e.g. we only want averages for periods for which 75% of the data is available
timeAverage(mydata, avg.time = "3 hour", data.thresh = 75)

#we can also "fill' in data using this function 
timeAverage(mydata, avg.time = "15 min", fill= TRUE)

#it is worth looking at the help for this function
?timeAverage #this opens the help page in the 'Help' tab in the bottom left corner of RStudio

#we can add columns with labels, which can be useful if planning to use the dataframe outside of openair 
#(where 'keywords' such as 'season', 'year', etc may not be understood)
seasonal_data <- cutData(mydata, type = "season") #this add a column listing which season each row belongs to

cutData(mydata, type = "month")


#there are many ways to read in data into R, and we will eventually cover more of them (so far we have used read.csv from {base})
#openair has a built in function to read in data: import() 
#it accepts two file formats: comma separated or tab delimited  

#in the /data/ folder in this project, I have a file containing OEH AQ data for 3 Sydney stations during SPS2. 

AQ_sps2 <- import(file = "data/AQ_SPS2.csv", file.type = "csv", header.at = 1, date = "date", ws = "ws", 
                  wd = "wd", date.format = "%Y-%m-%d %H:%M:%S")
#we have to specify the path and file name in file = "" 
#then we specify the file.type (csv or txt)
#we can tell openair where the column names are using header.at = (they don't have to be on the first line of the file)
#we can tell openair on which line the data start with data.at = (they don't have to be on the second line of the file)
#we have to tell openair which column contains date info with date = "" 
##NOTE IMPORT() WILL ALWAYS REQUIRE A DATE column - not good for data that comes with a column for year, a column for month, a column for day (like some model data do)
#we can specify what the date format is in the file we are reading in using date.format: % indicates that the next character is a date element
#if we have wind data, we should tell openair which column they are in using ws = "" and wd = "" 
#the function will work even if the dataset does not contain wind data 

#once the data is in, we can have a look at it: 

str(AQ_sps2)

#we can plot the data :
timePlot(AQ_sps2, pollutant = "O3") #this throws an error message because openair has detected more than one site
#and it does not automatically average several sites together

#this works and makes one panel per site: 
timePlot(AQ_sps2, pollutant = "O3", type = "site")

#we can change the layout: 
timePlot(AQ_sps2, pollutant = "O3", type = "site", layout = c(3,1)) #three plots on one row
timePlot(AQ_sps2, pollutant = "O3", type = "site", layout = c(1,3)) #three plots in one column 

#for certain functions, we have the option to make one panel per site: 
timeVariation(AQ_sps2, pollutant = "PM2.5", type = "site", layout = c(1,3))
#or put all three sites in one panel: 
timeVariation(AQ_sps2, pollutant = "PM2.5", group = "site")

#IMPORTANT: the aggregating functions work even if there is a lot of missing data. 
#let's look more closely at our PM2.5 data :
timePlot(AQ_sps2, pollutant = "PM2.5", type = "site")
#Most of the Liverpool data is missing, but timeVariation did not give us a warning!


