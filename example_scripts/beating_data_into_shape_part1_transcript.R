#Let's clean up some met data from Gunn Point. 
#the files are from BOM and are therefore mostly 'tidy' already
#but there are  a few steps required before we can effectively explore the data in  R 

#let's load some packages
library(openair)
library(tidyverse)

#the data is under 'data/GPA/" 
#the format is .txt - opening it in Notepad (or similar) let's us see a few peculiarities:
# the data are comma-separated (instead of tab or white space)
# the last column contains a "#" symbol - R recognises this as a 'comment' unless told not to
# missing data is indicated with -999
# we have headers 

#knowing this, we can read in one of the file, using read.table, and specifying:
# sep = "," #because the data are comma separated 
# header = TRUE
# na.strings = -999
# comment.char = "" #to tell R to treat # as a normal character instead of a special comment character

gpmet1 <- read.table(file = "data/GPA/HM01X_Data_014023_45795729457825.txt", sep = ",", header = TRUE, na.strings = -999, comment.char = "")
#this works but error prone (because the file names are tricky!)
#also, what if we had 10 files? or a hundred files? 
#do we really want  to repeat this line of code 100 times? 

#let's explore some options: 

#first, let's create a variable containing the full path to the data folder:
#on my computer, it looks like this (you need to change it to reflect the path on your own computer):
dir <- "C:/Users/gue02h/cloudstor/thinR/data/GPA/"
#this is a shortcut - typing 'dir' is much easier than typing all of the above everytime we want to use the path

#then, we can ask R to list all the files in that folder: 
list.files(path = dir)
#we can two file names printed to the console. 

#we can specify a specific pattern: e.g.
list.files(path = dir, pattern = ".txt")
#we still get 2 files because both file names contain ".txt" 

list.files(path = dir, pattern = "014023")
#we still get 2 files because both file names contain "014023" 

list.files(path =dir, pattern = "5.txt")
#this time the call only returns one file 

#we can save the output of list.files() to a variable 

files <- list.files(path = dir, pattern = ".txt")

#now we can use this list of file names to automate the reading in of the files

# one way would be to set up a loop 
#(not generally recommended for this purpose, but lets us revise loops, which we saw briefly last time)


gpmet_loop <- list() # we create an empty list to hold each file, otherwise each iteration of the loop will overwrite the previous one

for (i in 1:length(files)) { #we use length() instead of specifying the number of files directly - this makes it easier to scale up the code)

  gpmet_loop[[i]]  <- read.table(file = paste0(dir, files[i]), sep = ",", header = T, na.strings = -999, comment.char = "")
#gpmet_loop[[i]] this means that each file will become on element in our list 
#the rest of the call is the same as above - read.table(...), but the file path has changed a bit
#we use paste0(dir, files[i]) to build the file path automatically for each iteration

  } #this ends the loop

#This works - we now have a list containing two elements 
#BUT, loops are SLOW - and probably not the best solution to read in a 100 files 

#a more efficient solution uses the function lapply()
#lapply() is a function that lets you apply a function to each element of a list 

#let's play with lapply a bit: 
#let's create a small list, or three elements each containing 3 numbers:
mylist <- list(c(1,2,3), 
               c(2,4,6), 
               c(4,7,9))

#now we can apply a function to each element of that list: e.g.
lapply(mylist, mean) #returns the mean of each element
lapply(mylist, sum) #returns the sum of each element

#lapply also lets you use your own functions. 
#let's create our first R function: 
#we will call it 'myfunction': 
myfunction <- function(x) {
  x + 6
}
#this function takes x and adds 6 to it. 
#let's try it :
myfunction(7)
#returns 13 - it works! 

#what if we want to add 6 to each element in mylist?
myfunction(mylist)
#it does not work! our function cannot handle the list

#lapply saves the day - we can ask it to apply myfunction to each elements of mylist: 
lapply(mylist, myfunction)

#so now we can see how maybe we can use lapply to apply read.table to each element of our list of file names

lapply(files, read.table) #this does not let us pass the arguments (path, sep, comment.char, etc.) to read.table 
#so this won't work 'as is'. We need a few tweaks. 

#we can create a function that contains our "read.table" call from earlier
myreadfunction <- function(x) {
  read.table(paste0(dir, x), sep = ",", header = T, comment.char = "", na.strings = -999)
}

gpmet_lapply_fun <- lapply(files, myreadfunction)
#this works perfectly well - we get the same results as with the loop

#but lapply() lets us build a function within its own call:
gpmet_lapply <- lapply(files, 
                    function(x)  read.table(paste0(dir, x), sep = ",", header = T, comment.char = "", na.strings = -999))

#we can even generalise further: 
gpmet_lapply <- lapply(list.files(path = dir, pattern = "014023"), 
                       function(x)  read.table(paste0(dir, x), sep = ",", header = T, comment.char = "", na.strings = -999))
#this one line of code can read hundreds of files! (as long as we define 'dir' somewhere first)


#Now that the data is in, let's have a look at it                   
str(gpmet_lapply[[1]]) #prints the structure of the first element in the list 
#it contains 67761 obs of 29 variables
str(gpmet_lapply[[2]]) #this one has 31 variables

#recall that openair (for example) only works on dataframes, not on lists of dataframes
#we need to combine the dataframes in our list into one 

#let's use bind_rows() from the tidyverse 
#bind_rows lets us bind dataframes together, as we did with our model data last week: 
#bind_rows(df1, df2)
#it also works on lists of dataframes, which is perfect for us:
#bind_rows(list_containing_dfs)
gpmet_combined <- bind_rows(gpmet_lapply) #this works! we now have 1 dataframe containing all our data

#let's repeat this, using a nice feature of bind_rows: .id let's us name a column that will include an identifier for each dataframe: 
gpmet_combined <- bind_rows(gpmet_lapply, .id = "id")

str(gpmet_combined) #we now have 32 columns (31 original ones + the 'id' one)

#let's try to have a look at the data using openair
timePlot(gpmet_combined, pollutant = "Wind.speed.in.km.h")
#we do not have a 'date' column, so this fails

#we can try to get around the naming issue by using scatterPlot() instead:
scatterPlot(gpmet_combined[1:1000,], x = "Day.Month.Year.Hour24.Minutes.in.DD.MM.YYYY.HH24.MI.format.in.Local.standard.time", 
            y =  "Wind.speed.in.km.h")
#the x-axis is really odd - R does not know that this column is meant to be dates!

#to fix this, we will use the as.POSIXct() function 
#as.POSIXct() let's us convert almost anything into a data that R can understand:
#here is an example of how it works:
#imagine we have a date that looks messy like this: "D15M05Y2020H12M00"
#it contains date information, but also some extra characters that we don't need
#we can feed this to the as.POSIXct function, along with some format and timezone information 
as.POSIXct("D15M05Y2020H12M00", format = "D%dM%mY%YH%HM%M", tz = "Australia/Sydney")
#we tell as.POSIXct which bits of the string contain date information using %
#e.g. %d tells the function that the next bit of string contains the day
# %m is the month 
# %Y is the year (4-digit)
# %H is the hour 
# %M is minutes 
#the result is a date in a format that R can understand!

#let's use as.POSIXct() to create a new column called date, containing date info in a format that R understands 
gpmet_combined$date <- as.POSIXct(gpmet_combined$Day.Month.Year.Hour24.Minutes.in.DD.MM.YYYY.HH24.MI.format.in.Local.standard.time,
                                  format = "%d/%m/%Y %H:%M", tz = "Australia/Darwin")

str(gpmet_combined) #we now have a 33rd column - containing dates that we can use!

timePlot(gpmet_combined, pollutant = "Wind.speed.in.km.h")
#this now works, because our dataframe contains a 'date' column

#using scatterPlot(), we can make use of our "id" column:
scatterPlot(gpmet_combined, x = "date", y =  "Wind.speed.in.km.h", group = "id")
#this reveals that we have ovelapping dates/data

#to get rid of the duplicated rows, we will use a function called duplicated()

#lets see how duplicated works:
#let's create a vector of numbers, with one repeated value:
x <- c(1,2,2,3,4,5,6)
duplicated(x)
#this tells us that elements 1,2,4,5,6,7 are unique, but 3 is repeated

#we can combine duplicated() with which()
#which() returns the index (or row number) 
which(x ==6) #6 is the 7th element in our vector
which(x >1) #elements 2,3,4,5,6 and 7 contains values >1

#combining which() and duplicated returns the index of the repeated element:
which(duplicated(x))
#3!

#let's apply this to our date column: 
ids <- which(duplicated(gpmet_combined$date))
#there are >20000 repeated dates! 

#we can subset our dataframe, to drop these rows: 
gpmet <- gpmet_combined[-ids,] # the minus sign means "drop" - so we keep all columns, and all rows BUT the duplicated ones

#gpmet <- gpmet_combined[ids,] #note: this would KEEP the rows, dropping everything else

scatterPlot(gpmet, x = "date", y =  "Wind.speed.in.km.h", group = "id")
#we can see that we have remove the duplicates


#things we will cover next time 

#dodgy wind data in 2017? 
#calculate precipitation in last 30 minutes - let's write a function
#calculate wind components (u, v) - let's write another function

#clean up + save it - share it with others 



