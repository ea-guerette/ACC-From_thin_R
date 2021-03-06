#A script (.R file) lets you save your work 
#It also lets you write comments on your code, by using #
#to run a line of code, press ctrl+enter while the cursor is on it
#to run several lines of code, you can highlight them with the mouse, then press ctrl+enter. 
#You can also use the Run button
# Tab autofills variable names, it's a handy shortcut

#to install packages - they only need to be installed once, so this line can be commented out once it has been executed.
#install.packages("openair")

#Now, load the package(s) you want to use - this needs to be done *every* time you open a new session
library(openair)

#get some data in using {base} function
#in this case we want to import the gapminder.csv file, which is located in the "data" folder in this R project

gapminder <- read.csv("data/gapminder.csv") 

names(gapminder) #returns column names 
summary(gapminder) #returns a summary (stats if column is numeric) for each column in the dataframe

View(gapminder) #open the dataframe as a tab in the Editor

#very useful for timeseries 
head(gapminder) #shows first 6 rows by default
head(gapminder, 10) #shows first 10 rows
tail(gapminder) #shows last 6 rows by default


#how to subset a dataframe using {base} commands and functions

#using {base} functions 
#to select a specific column 
gapminder$country
gapminder[ ,1] #R uses [row,column] and indices start a at 1 (not 0 like in python)
#as row is not specified, R selects all rows 

#to select several columns 
gapminder[ ,c(1,4)]
gapminder[ ,1:4] #select columns 1 to 4, inclusively. Note gapminder[ ,c(1:4)] #also works
gapminder[,-c(1,4)] #drops columns 1 and 4
subset(gapminder, select = c("country", "lifeExp"))

#to select rows
gapminder[1:5,] #select first five rows, keeps all columns 
gapminder[1:5,1:4] #select a block of data containing first five rows of first four columns

#conditional subsetting of rows
subset(gapminder, country =="Australia") #keeps only rows containing data for Australia 
subset(gapminder, country !="Australia") #keeps all countries EXCEPT Australia


#conditional subsetting of rows + selection of variables 
subset(gapminder, country =="Australia", select = c(1:4)) 

#adding a new column 

gapminder$gdp <- gapminder$gdpPercap * gapminder$pop #a bit tedious to type

within(gapminder, gdp <- gdpPercap * pop)

#to save a subset of the main data, assign it to a new variable 
AusCan <- subset(gapminder, country %in% c("Australia", "Canada")) #note the use of %in% instead of == when using a list of conditions
gapminder_2007 <- subset(gapminder, year == 2007)


#it's often a good idea to have a quick look at the data
#{base} has some plotting functionality

plot(data = gapminder, lifeExp ~ year) #plot() uses a y ~ x formula 

#Q1: plot population versus year
#A1: plot(data = gapminder, pop ~ year)

#what if x is a categorical variable? 
plot(data = gapminder, lifeExp ~ continent) 
#we get a boxplot! 
#This is because whoever wrote the function thought this was the best way to display this kind of data.

#we can also make histograms
hist(gapminder_2007$gdpPercap)

#There are many packages out there that let you make really cool plots, it's often a matter of preference which you use. 
#because a lot of people are interested in using openair, we will use one of their plotting functions here 

##We will now start to use {openair} functions 

#plotting the data quickly using the scatterPlot function from {openair}
#Note that the function names are case sensitive!
scatterPlot(gapminder, x = "year", y = "lifeExp")

#Q1: plot population versus year 
#Q2: plot life expentancy vs gdp per capita

#some good features of scatterPlot (and all openair plots) are "type" and "group"
#lets try group:
scatterPlot(gapminder, x = "year", y = "lifeExp", group = "continent")
scatterPlot(gapminder, x = "year", y = "lifeExp", group = "pop")

#and now type: 
scatterPlot(gapminder, x = "year", y = "lifeExp", type = "continent")
scatterPlot(gapminder, x = "year", y = "lifeExp", type = "pop")

#we can plot a subset 
subset(gapminder, country == "Australia")
scatterPlot(subset(gapminder, country == "Australia"), x = "year", y = "lifeExp")

subset(gapminder, year == 1977)
scatterPlot(subset(gapminder, year == 1977), x = "gdpPercap", y = "lifeExp")

# scatterPlot lets you color the points by another variable 
scatterPlot(subset(gapminder, year == 1977), x = "gdpPercap", y = "lifeExp", z = "pop")

#you can change the axis scale from linear to logarithmic 
scatterPlot(subset(gapminder, year == 1977), x = "gdpPercap", y = "lifeExp", z = "pop", log.x = T)


#openair has been specifically written to handle air quality data. 
#It is quite powerful, but expects data in a certain format. 
#We will go over how to read in data into the openair format some other time. 
#for now, we will use 'mydata' which is an example dataset that comes with the openair package

head(mydata)
tail(mydata)

summary(mydata)
#date, ws, wd are expected, and should be in %Y-%m-%d, m/s and degrees, respectively. 
#the nice thing is that is your data is as openair wants it, making plot then feels like magic. 
#some examples: 

windRose(mydata)

timePlot(mydata, pollutant = c("nox", "no2"))

timeVariation(mydata, pollutant = "o3")
#to plot only the diurnal cycle, assign the plot as a variable

o3_timeVar_plot <- timeVariation(mydata, pollutant = "o3")
print(o3_timeVar_plot, subset = "hour")
#to plot the annual cycle
print(o3_timeVar_plot, subset = "month")
