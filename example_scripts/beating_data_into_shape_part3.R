#let's start with a cleaned up version of what we did last time - I removed all the 'non-essential' bits of code
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

gpmet_lapply <- lapply(list.files(path = dir, pattern = "014023", full.names = TRUE), 
                       function(x)  read.table(x, sep = ",", header = TRUE, comment.char = "", na.strings = -999))


#combine dataframes into one using bind_rows()
gpmet_combined <- dplyr::bind_rows(gpmet_lapply, .id = "id")
#we added the column 'id' to help with quality checks on the data

#note that we can combine the two steps above to bypass creating the list in our environment:
#gpmet_combined <- bind_rows(lapply(list.files(path = dir, pattern = "014023"), 
#       function(x)  read.table(paste0(dir, x), sep = ",", header = T, comment.char = "", na.strings = -999)), .id = "id")

#let's look at our dataframe
#str(gpmet_combined)

#then we create a date column in a format that R understands, using as.POSIXct()
gpmet_combined$date <- as.POSIXct(gpmet_combined$Day.Month.Year.Hour24.Minutes.in.DD.MM.YYYY.HH24.MI.format.in.Local.standard.time,
                                  format = "%d/%m/%Y %H:%M", tz = "Australia/Darwin")
#as.POSIXct is very versatile, and lets you turn almost anything string into a date - see last week for a fiendish example 

#to fix the overlapping data, we use distinct() from the dplyr package - thanks Chris! 
gpmet <- dplyr::distinct(gpmet_combined, date, .keep_all = TRUE) 
#distinct() keeps the first instance of each date present in gpmet_combined. .keep_all = TRUE means we keep all columns 

#To 'fix' the wind data: 
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

bad_wind_data_rows <- which(lubridate::date(gpmet$date) %in% lubridate::date(daily_means$date[daily_ids]))
#this is very similar to what we had above, but we reformat our dates so the string matching can work 


#we can now assign a new value: 
gpmet$Wind.speed.in.km.h[bad_wind_data_rows] <- NA

#we do the same for wind direction: 
gpmet$Wind.direction.in.degrees.true[bad_wind_data_rows] <- NA
#we do the same for windgust:
gpmet$Speed.of.maximum.windgust.in.last.10.minutes.in..km.h[bad_wind_data_rows] <- NA


# Next time we will create a function to calculate precipitation in the last 30 minutes 


 