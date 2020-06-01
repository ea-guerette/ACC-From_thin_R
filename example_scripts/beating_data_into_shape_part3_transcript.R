#let's start with a cleaned up version of what we did last time - I removed all the 'non-essential' bits of code
#reminder that we are looking at 30 min data from BOM AWS at Gunn Point 


#load packages
library(openair)
library(dplyr) #this is part of the tidyverse suite of packages 
library(lubridate) #this package makes date manipulation easy
library(tidyr)
#in this script, I will try to explicitly state which package a function comes from by using the following syntax: 
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

#let's have a quick look at the data to make sure all went according to plan:
openair::timePlot(gpmet, pollutant = "Wind.speed.in.km.h")

# Next, we want to  recalculate precipitation to get 'Precipitation in the last 30 minutes'

#prcp2 <- c(NA, prcp[-length(prcp)])
#int_prcp <- prcp - prcp2 
#ids <- grep("09:30:00", date)
#int_prcp[ids] <- prcp[ids] 

#We need to fill in gaps in dates 
#need to get rid of times that aren't :00 or :30 

#let's try timeAverage using minimum as the statistic 

#gpmet_min <- openair::timeAverage(gpmet, avg.time = "30 min", statistic = "min")
#summary(gpmet_min$Precipitation.since.9am.local.time.in.mm)
#timeAverage is slow, we lose the Quality columns, and some Inf values appear 

#another approach is to create a sequence containing the dates we want to include: 
#remember this: 
#seq(1,12, by =2)
#it works for dates to: 
date_seq_df <- data.frame(date = seq(min(gpmet$date), max(gpmet$date), by = "30 min"))
#we now have a dataframe containing column called 'date', that starts at 
#the first date/time of our gpmet dataframe and ends at the last date/time of our gpmet dataframe

test <- merge(date_seq_df, gpmet, by = "date", all = TRUE) #full_join() - we have filled the gaps, but we get more rows than expected, due to the 12:25 etc. in the gpmet dataset
gpmet_complete <- merge(date_seq_df, test, by = "date", all = FALSE) #inner_join() - we now keep only the dates that are in date_seq
#we keep our Quality columns (although introducing NAs), fast, no Inf 

summary(gpmet$Station.Number)
summary(gpmet_complete$Station.Number)
#we how we have introduced NAs in our Station.Number column. Not ideal - see at the end for a tweaked solution

#Now that we have a dataframe containing all and only the date_seq dates, we can perform our precipitation calculation 
#prcp2 <- c(NA, prcp[-length(prcp)])
#int_prcp <- prcp - prcp2 
#ids <- grep("09:30:00", date)
#int_prcp[ids] <- prcp[ids] 
#we do this by replacing the place holders in the above with our real variables: 
prcp_i_minus_1 <- c(NA, gpmet_complete$Precipitation.since.9am.local.time.in.mm[-length(gpmet_complete$Precipitation.since.9am.local.time.in.mm)])
gpmet_complete$Precipitation.in.last.30.minutes.in.mm <- gpmet_complete$Precipitation.since.9am.local.time.in.mm - prcp_i_minus_1 
ids <- grep("09:30:00", gpmet_complete$date)
gpmet_complete$Precipitation.in.last.30.minutes.in.mm[ids] <- gpmet_complete$Precipitation.since.9am.local.time.in.mm[ids] 

summary(gpmet_complete$Precipitation.in.last.30.minutes.in.mm)

#to make a function, we go back to our generalised code 
#prcp2 <- c(NA, prcp[-length(prcp)])
#int_prcp <- prcp - prcp2 
#ids <- grep("09:30:00", date)
#int_prcp[ids] <- prcp[ids] 

#a function needs a name, some arguments, and a body 

recalculate_precip <- function(prcp, date) { #name is recalculate_precip, the arguments are prcp and date, the body is the code within the curly brackets
  prcp_i_minus_1 <- c(NA, prcp[-length(prcp)])
  int_prcp <- prcp - prcp_i_minus_1 
  ids <- grep("09:30:00", date)
  int_prcp[ids] <- prcp[ids] 
  return(int_prcp)
} 

#we can now test our function: 
test_fun <- recalculate_precip(prcp = gpmet_complete$Precipitation.since.9am.local.time.in.mm, date = gpmet_complete$date)
gpmet_complete$Precipitation.in.last.30.minutes.in.mm <- recalculate_precip(prcp = gpmet_complete$Precipitation.since.9am.local.time.in.mm, 
                                                                            date = gpmet_complete$date)
#our function does not have any vetting built in - 
test_incomplete <- recalculate_precip(prcp = gpmet$Precipitation.since.9am.local.time.in.mm, date = gpmet$date)
#this also works, but the result is gibberish because we have gaps and shorter intervals in gpmet 

#we could expand the function so that it:
 # gives a warning if the dataframe has gaps AND/OR
 # automatically fill in dates 
 # we could also add an extra argument for the time interval (to allow e.g. hourly data)
 # etc. 


#Ian mentioned tidyr:complete() as an alternative to
#date_seq_df <- data.frame(date = seq(min(gpmet$date), max(gpmet$date), by = "30 min"))
#test <- merge(date_seq_df, gpmet, by = "date", all = TRUE) #full_join() - we have filled the gaps, but we get more rows than expected, due to the 12:25 etc. in the gpmet dataset
#gpmet_complete <- merge(date_seq_df, test, by = "date", all = FALSE) #inner_join() - we now keep only the dates that are in date_seq

#tidyr:complete() lets you 'fill in' several variable, so we won't be introducing NAs in e.g. Station.Number
#let's try it:  

gpmet_tidyr_complete_test <- tidyr::complete(gpmet)
#nothing happens, we need to specify which column(s) to fill  

gpmet_tidyr_complete_test <- tidyr::complete(gp_tib, date = date_seq_df) #POSIXct error 
#the fill in feature requires a vector, not a dataframe 
#lets create a date_seq vector:  
date_seq <- seq(min(gpmet$date), max(gpmet$date), by = "30 min") #this is a vector containing the dates we want to include

gpmet_tidyr_complete_test <- tidyr::complete(gpmet, date = date_seq)
#this worked - we have all the dates including 12:25 etc. equivalent to test <- merge(date_seq_df, gpmet, by = "date", all = TRUE)
summary(gpmet_tidyr_complete_test$Station.Number) # this has introduced NAs

#now let's specify values for more columns (to replace the default NAs)
gpmet_tidyr_complete_test2 <- tidyr::complete(gpmet, date = date_seq , Station.Number = 14023, AWS.Flag = 1,
                                              Latitude.to.four.decimal.places.in.degrees = 	-12.249, 
                                              Longitude.to.four.decimal.places.in.degrees = 131.0449)

summary(gpmet_tidyr_complete_test2$Station.Number) #tada! no NAs 

#HOWEVER, we still have the 12:25, 12:26 time stamps in there, so we need to do something like:
#gpmet_complete <- merge(date_seq_df, test, by = "date", all = FALSE) #inner_join() - we now keep only the dates that are in date_seq

#using a dplyr function instead of merge()
gpmet_tidyr_test_cont <- dplyr::inner_join(date_seq, gpmet_tidyr_complete_test2)
#notice how inner_join accepts a vector as one of its arguments, whereas merge() would not.
#so, using the tidyverse, we still have to use two steps, 
#but it gives us an easy way to fill in other columns as well as the date column
#Thanks Ian!

#We will be exploring the tidyverse more in the next session 