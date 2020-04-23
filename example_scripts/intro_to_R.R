#A script (.R file) lets you save your work 

#get some data in using {base} function
#in this case we want to import the gapminder.csv file, which is located in the "data" folder in this R project

gapminder <- read.csv("data/gapminder.csv") 

names(gapminder) #returns column names 
summary(gapminder) 

View(gapminder)

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


#it's often a good idea to have a quick look at the data

plot(data = gapminder, lifeExp ~ year)

#Q1: plot population versus year 

#These are not great plots. There are many packages out there that let you make really cool plots 
#it's often a matter of preference which you use. 
#because a lot of people are interested in using openair, we will use one of the plotting functions here 

#to install packages - they only need to be installed once, so this line can be commented out once it has been executed.
install.packages("openair")

#Now, load the package(s) you want to use - this needs to be done *every* time you open a new session
library(openair)


#plotting the data quickly using the scatterPlot function from {openair}
scatterPlot(gapminder, x = "year", y = "lifeExp")

#Q1: plot population versus year 
#Q2: plot life expentancy vs gdp per capita

#some good features of scatterPlot (and all openair plots) are "type" and "group"
#lets try group:
scatterPlot(gapminder, x = "year", y = "lifeExp", group = "continent")
#and now type: 
scatterPlot(gapminder, x = "year", y = "lifeExp", type = "continent")


#we can plot a subset 
subset(gapminder, country =="Australia")
scatterPlot(gapminder, x = "year", y = "lifeExp")


subset(gapminder, year == 1977)
scatterPlot(subset(gapminder, year == 1977), x = "gdpPercap", y = "lifeExp")

# scatterPlot lets you color the points by another variable 
scatterPlot(subset(gapminder, year == 1977), x = "gdpPercap", y = "lifeExp", z = "pop")

#you can change the axis scale from linear to logarithmic 
scatterPlot(subset(gapminder, year == 1977), x = "gdpPercap", y = "lifeExp", z = "pop", log.x = T)
