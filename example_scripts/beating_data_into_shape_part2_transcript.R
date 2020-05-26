#let's start with a cleaned up version of what we did last time 
#reminder that we are looking at 30 min data from BOM AWS at Gunn Point 

#install.packages(lubridate) # run this line of code if you haven't already 

#load packages
library(openair)
library(dplyr) #this is part of the tidyverse suite of packages 
library(lubridate) #this package makes date manipulation easy

#in this script, I will try to always make explicit which package a function comes from by using the following syntax: 
#package::function

#define variable holding the path to the folder containing the data files we want to read in 
dir <- "C:/Users/gue02h/cloudstor/thinR/data/GPA/" #you need to change this to match the path on YOUR computer

#Commented out original code as we found a better way to use list.files: 
#read data files into a list using lapply()
#gpmet_lapply <- lapply(list.files(path = dir, pattern = "014023"), 
#                       function(x)  read.table(paste0(dir, x), sep = ",", header = TRUE, comment.char = "", na.strings = -999))

list.files(path = dir, pattern = "014023") #does not return full path 
list.files(path = dir, pattern = "014023", full.names = TRUE) #returns full path + file names 

#we can simplify our read.table function a little (we can drop the paste0(dir, x) and use x instead)

gpmet_lapply <- lapply(list.files(path = dir, pattern = "014023", full.names = TRUE), 
                       function(x)  read.table(x, sep = ",", header = TRUE, comment.char = "", na.strings = -999))


#combine dataframes into one using bind_rows()
gpmet_combined <- dplyr::bind_rows(gpmet_lapply, .id = "id")
#we added the column 'id' to help with quality checks on the data

#note that we can combine the two steps above to bypass creating the list in our environment:
#gpmet_combined <- bind_rows(lapply(list.files(path = dir, pattern = "014023"), 
#       function(x)  read.table(paste0(dir, x), sep = ",", header = T, comment.char = "", na.strings = -999)), .id = "id")

#let's look at our dataframe
str(gpmet_combined)

#then we create a date column in a format that R understands, using as.POSIXct()
gpmet_combined$date <- as.POSIXct(gpmet_combined$Day.Month.Year.Hour24.Minutes.in.DD.MM.YYYY.HH24.MI.format.in.Local.standard.time,
                                  format = "%d/%m/%Y %H:%M", tz = "Australia/Darwin")
#as.POSIXct is very versatile, and lets you turn almost anything string into a date - see last week for a fiendish example 

#then we can plot the data to see what it looks like: 
openair::timePlot(gpmet_combined, pollutant = "Wind.speed.in.km.h") #zero wind speeds in 2017?

#using scatterPlot(), we can make use of our "id" column:
openair::scatterPlot(gpmet_combined, x = "date", y =  "Wind.direction.in.degrees.true", group = "id")
#two issues - overlapping dates, zero wind directions in 2017? 

#to fix the overlapping data, we used a combination of duplicated() and which() 
#ids <- which(duplicated(gpmet_combined$date))
#ids contains the rows that are duplicated and that we should remove from our 'clean' dataset 
#gpmet <- gpmet_combined[-ids,] # the minus sign means "drop" - so we keep all columns, and all rows BUT the duplicated ones

#another option is to use distinct() from the dplyr package - thanks Chris! 
gpmet <- dplyr::distinct(gpmet_combined, date, .keep_all = TRUE) 
#distinct() keeps the first instance of each date present in gpmet_combined. .keep_all = TRUE means we keep all columns 

#check 
openair::scatterPlot(gpmet, x = "date", y =  "Wind.direction.in.degrees.true", group = "id")
#this is better!

# should we look at every variables? probably! 

openair::timePlot(gpmet, pollutant = "Wind.speed.in.km.h")
openair::timePlot(gpmet, pollutant = "Wind.direction.in.degrees.true")
#openair::timePlot(gpmet, pollutant = "Preci...")

#this is tedious because the variable names are long... 
#here is a quick and dirty way to make a plot for each variable
names(gpmet) #this returns a 'list' of variable names! 
#we can feed this to lapply, and ask it to make a plot for each variable in this list

lapply(names(gpmet), function(x) openair::timePlot(gpmet, pollutant = x, main = x, date.pad = TRUE))
#this saves a lot of typing 
#we can flick back through the plots using the blue arrows in the plot window  - not all of them work great, but that's OK for a quick look

#from these plots, it looks like wind speed, wind direction and windgust all have issues 

# we can explore how to clean up the wind data 
#if we had field notes, we could use these, but we have no external information in this case, so we will devise our own QA method, based on daily averages  
#first, let's plot the data in more detail. 
#this plot shows all "August" data (one panel per year):
openair::scatterPlot(openair::selectByDate(gpmet, month = 8), x = "date", y = "Wind.speed.in.km.h", type = "year", #essential elements
                     x.relation = "free", pch =16, cex = 0.5, plot.type = "b", #elements to make plot prettier
                     main = paste("month", m)) #to add a title 
#openair::selectByDate() is a neat function that lets use extract only certain times/dates out of the timeseries. Here we use month = 
#type = "year" means we get one plot panel per year 
#x.relation = "free" means that the x axis is not the same for all panels - we tried making the plot without this and it looked ugly!
#pch is the type of dots - I think the options go from 1 - >20, have a play! 
#cex = 0.5 makes the dots half the size of the default
#plot.type = "b" means we are plotting BOTH points and a line. plot.type = "p" is the default (points); plot.type = "l" plots a line only (this is the default for openair::timePlot)
  

#here again, we can make use of lapply to quickly make a plot for each month of the year
#this time, we feed it a list of numbers (1 to 12)
lapply(seq(1,12), function (m)  openair::scatterPlot(openair::selectByDate(gpmet, month = m), x = "date", y = "Wind.speed.in.km.h", type = "year", date.pad = T,
                            x.relation = "free", pch =16, cex = 0.5, plot.type = "b",
                            main = paste("month", m))
       )
#note that we could write c(1,2,3,4,5,6,7,8,9,10,11,12) instead of seq(1,12)

#Again, we can flick through the plots using the back/forward arrows in the plot window 

#We can see that 'good' data has a diurnal cycle in wind speed. Let's use this to identify our bad data.  

#first, we make daily averages of the data using the timeAverage function from openair: 
daily_means <- openair::timeAverage(gpmet, avg.time = "1 day", statistic = "mean")

#then, we can look for days with a mean wind speed of zero:
daily_ids <- which(daily_means$Wind.speed.in.km.h == 0  )
#daily_ids contains the row numbers associated with bad wind data in our daily_means dataframe 
#daily_means only has 2141 rows, vs. >98k for our original dataframe... so daily_ids does not get us very far. 
#we want to get the row numbers associated with bad wind data in our original dataframe! 

daily_means$date[daily_ids] #this prints out all the dates associated with bad wind data

#this is a good start
#now we want to find these dates in our original dataframe 

#running this returns nothing - why?
test <- which(gpmet$date %in% daily_means$date[daily_ids])
#we are comparing strings - and none of daily_means$date[daily_ids] exactly match: 
#"2017-06-23 ACST" is not the same as "2017-06-23 00:00:00 ACST" is you treat them like strings 
#also, we want to find "2017-06-23 01:00:00 ACST", "2017-06-23 02:00:00 ACST", "2017-06-23 03:00:00 ACST", etc... 

#this is where lubridate becomes useful: 
#lubridate::date() extracts the "date" element of a "date time timezone" string
lubridate::date(daily_means$date[daily_ids])
#now our daily dates look like "2017-06-23"
#we can do the same to our original dates: 
lubridate::date(gpmet$date)

#and now we can find the rows of bad wind data in our original dataframe 
bad_wind_data_rows <- which(lubridate::date(gpmet$date) %in% lubridate::date(daily_means$date[daily_ids]))
#this is very similar to what we had above, but we reformat our dates so the string matching can work 

#pulling out the bad wind data:
gpmet$Wind.speed.in.km.h[bad_wind_data_rows]
#we can see they are zero, as expected 

#we can now assign a new value: 
gpmet$Wind.speed.in.km.h[bad_wind_data_rows] <- NA

#now if we pull out the data again, we see we have NAs everywhere
gpmet$Wind.speed.in.km.h[bad_wind_data_rows]

#we do the same for wind direction: 
gpmet$Wind.direction.in.degrees.true[bad_wind_data_rows] <- NA
#we do the same for windgust:
gpmet$Speed.of.maximum.windgust.in.last.10.minutes.in..km.h[bad_wind_data_rows] <- NA

#now we can replot our data: 
openair::timePlot(gpmet, pollutant = "Wind.speed.in.km.h")



# Next time we will create a function to calculate precipitation in the last 30 minutes 


 