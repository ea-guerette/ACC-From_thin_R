#let's start with a cleaned up version of what we did last time 

#load packages
library(openair)
library(dplyr)

#define variable holding the path to the folder containing the data files we want to read in 
dir <- "C:/Users/gue02h/cloudstor/thinR/data/GPA/"

#read data files into a list using lapply()
#gpmet_lapply <- lapply(list.files(path = dir, pattern = "014023"), 
#                       function(x)  read.table(paste0(dir, x), sep = ",", header = TRUE, comment.char = "", na.strings = -999))

gpmet_lapply <- lapply(list.files(path = dir, pattern = "014023", full.names = TRUE), 
                       function(x)  read.table(x, sep = ",", header = TRUE, comment.char = "", na.strings = -999))

#combine dataframes into one using bind_rows()
gpmet_combined <- dplyr::bind_rows(gpmet_lapply, .id = "id")
#we added the column 'id' to help with quality checks on the data

#note that we can combine the two steps above to bypass creating the list explicitely: 
#gpmet_combined <- bind_rows(lapply(list.files(path = dir, pattern = "014023"), 
#       function(x)  read.table(paste0(dir, x), sep = ",", header = T, comment.char = "", na.strings = -999)), .id = "id")

#then we create a date column in a format that R understands, using as.POSIXct()
gpmet_combined$date <- as.POSIXct(gpmet_combined$Day.Month.Year.Hour24.Minutes.in.DD.MM.YYYY.HH24.MI.format.in.Local.standard.time,
                                  format = "%d/%m/%Y %H:%M", tz = "Australia/Darwin")

#then we can plot the data to see what it looks like: 
openair::timePlot(gpmet_combined, pollutant = "Wind.speed.in.km.h") #zero wind speeds in 2017?

#using scatterPlot(), we can make use of our "id" column:
openair::scatterPlot(gpmet_combined, x = "date", y =  "Wind.direction.in.degrees.true", group = "id")
#two issues - overlapping dates, zero wind directions in 2017 

#to fix the overlapping data, we use a combination of duplicated() and which() 
#ids <- which(duplicated(gpmet_combined$date))
#ids contains the rows that are duplicated and that we should remove from our 'clean' dataset 
#gpmet <- gpmet_combined[-ids,] # the minus sign means "drop" - so we keep all columns, and all rows BUT the duplicated ones

#another option is to use distinct() from the dplyr package - thanks Chris! 
gpmet <- dplyr::distinct(gpmet_combined, date, .keep_all = TRUE)

#check 
openair::scatterPlot(gpmet, x = "date", y =  "Wind.direction.in.degrees.true", group = "id")






