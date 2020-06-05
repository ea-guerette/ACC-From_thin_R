#today is all about the tidyverse 
library(tidyverse)
#the tidyverse is a collection of 8 packages. 
#It covers pretty much everything that we did using base R, but adds some neat funtionalities

gapminder <- readr::read_csv("data/gapminder.csv") #this reads in the data as a 'tibble' instead of a dataframe
#tibbles behave in the same way as dataframes, but they print in a neater way in the console
gapminder

#we will cover quite a few functions in this session, most of them from dplyr 
#filter() - similar to subset() from base - to select ROWS 
#select() - to choose COLUMNS
#mutate() - add new columns 
#rename() - to rename columns
#summarise() - to summarise columns (mean, min, max, median, sd, etc...)
#group_by() - very powerful, often used in combination with summarise

#PIPES %>% (ctrl-shift-m) - an alternative to nesting functions 

#to combine dataframes 
#bind_rows() - covered in previous sessions 
#inner_join()
#full_join()
#left_join()
#right_join()

#to reformat dataframes: 
#gather() - create long format 
#separate() - create two columns from one 
#spread() - create wide format 

#most of these have the same syntax:
#function(tibble, argument(s)) - this is similar to openair! 

#filter() - similar to subset() from base - to select ROWS 
filter(gapminder, country == "Australia") #only the data from Australia is retained 
filter(gapminder, country %in% c("Australia", "Botswana", "Benin")) #data from all 3 countries is kept 

filter(gapminder, year > 1957) #all years after 1957 are kept 
 
filter(gapminder, lifeExp > 80 & continent == "Europe") #we can filter using multiple conditions 

#select() - to choose COLUMNS
select(gapminder, country, year, lifeExp, pop, gdpPercap) #we keep all columns but continent 
select(gapminder, -continent) #this gives the same result as the above - we drop continent
select(gapminder, -continent, -lifeExp) #we can drop several columns 


#mutate() - add new column(s)
#mutate(tibble, new_column_name = ... ) 
mutate(gapminder, gdp = gdpPercap * pop,  #creates a new column called gdp that is the product of gdpPercap and population
                  pop_in_millions = pop / 1e6) #creates a new column that contains population in millions 
#running this, we can see that we now have 2 extra columns in our dataset 

#rename()
#rename(tibble, new_name = old_name)
rename(gapminder, life_expectancy = lifeExp, 
                  gpd_per_capita = gdpPercap)
names(gapminder) #this returns the old names because we did not assign the result of rename to a variable 

#summarise()
#summarise(tibble, new_column_name = ...)
summarise(gapminder, min_lifeExp = min(lifeExp), 
                     max_lifeExp = max(lifeExp))
#this returns the minimum and maximum life expectancies in the entire dataset 
#what is we want to break this down by continent? 

#group_by()
gapminder_by_continent <- group_by(gapminder, continent)
gapminder_by_continent 
# A tibble: 1,704 x 6
# Groups:   continent [5]
#looks like nothing has happened, but behind the scenes, the dataset is now broken into 5 chunks 

#if we summarise this new tibble: 
summarise(gapminder_by_continent, min_lifeExp = min(lifeExp), 
                                  max_lifeExp = max(lifeExp))
#we now get a min and max value for each continent. Nifty! 

#another useful function is n() - this counts the number of rows in a group: 
summarise(gapminder_by_continent, num_rows = n()) 

#we can also use more complex calculation within summarise(): 
summarise(gapminder_by_continent, num_rows = n(), 
                                  se_pop = sd(pop)/sqrt(n()))


#Notice how we had to have two steps to get our grouped results 
# One way to do it in one step - nested functions:  

summarise(group_by(gapminder, continent), min_lifeExp = min(lifeExp), 
          max_lifeExp = max(lifeExp))

#another way, from the tidyverse: 
#*PIPES*  %>% %>% %>% %>% %>% %>% (ctrl-shift-m)
gapminder %>% group_by(continent) %>%  #notice how we can 'pass' gapminder through the pipe to the group_by() function 
              summarise(min_lifeExp = min(lifeExp), #the result of group_by() is then passed on to the summarise function
                        max_lifeExp = max(lifeExp))

#piped sequences can be a long as you want. The result can be saved to a variable: 
number_of_rows <- filter(gapminder, year > 1957) %>% 
               group_by(continent) %>% 
               summarise( num_rows = n())


#bind_rows() - we have used this function in the past, I will not go over is again

#to combine dataframes: 
#this are alternatives to merge() from base 
#inner_join(), full_join(), left_join(), right_join()

#inner_join() is like merge with all = F 
#full_join() is like merge with all = T 

#first, we create two small tibbles: 
df1 <- tibble(sample = c(1,2,3), measure_1 = c(4.2, 5.3, 6.1))
df2 <- tibble(sample = c(1,3,4), measure_2 = c(7.8, 6.4, 9.0))

new_df <- full_join(df1, df2)
# we can a printed "warning" : Joining, by = "sample" - the function did what we wanted, but our code was ambiguous 
new_df <- full_join(df1, df2, by ="sample")
#this new tibble contains all four samples, and NAs where data is missing 

inner_join(df1, df2, by ="sample") # only keeps samples for which we have both measurements 

left_join(df1, df2, by = "sample") #keeps samples 1,2,3 (from df1)
right_join(df1, df2, by = "sample") #keeps samples 1,3,4 (from df2)

#a really neat feature is that this works even if columns have different names: 
#let's reuse the tibbles from above but change "sample" for "ID" in df1: 
df1 <- tibble(ID = c(1,2,3), measure_1 = c(4.2, 5.3, 6.1))
df2 <- tibble(sample = c(1,3,4), measure_2 = c(7.8, 6.4, 9.0))

new_df <- full_join(df1, df2) #this fails as expected 
new_df <- full_join(df1, df2, by = "ID") #this also fails 

new_df <- full_join(df1, df2, by = c("ID" = "sample")) #this works! 
#this saves you renaming columns in dataset prior to merge them (e.g. Date vs date is a common one)

#to reshape data, there are three very useful functions: 
new_df 
#ID measure_1 measure_2
#<dbl>     <dbl>     <dbl>
#1     1       4.2       7.8
#2     2       5.3      NA  
#3     3       6.1       6.4
#4     4      NA         9  

#we may prefer to have something like this: 
#ID replicate value 
#1  1 4.2
#1  2 7.8
#...

#gather() - takes a tibble and makes as few columns as possible without losing information: 
gather(new_df) #this makes two columns (minimum possible without losing information)
#this is maybe a step two far - we would like to keep our "ID" column

#we can rename "key" and "value" to better names as part of the function call if we wish, using key = and value = : 
gather(new_df, key = "original_col_names", value = "value", measure_1, measure_2) # we tell gather to only 'gather' measure1 and measure2
new_df_long <- gather(new_df, key = "original_col_names", value = "value", -ID) #same result - gather everything BUT "ID"

#we can use spread to reverse what we have just done: 
spread(new_df_long, key = "original_col_names", value = "value")


#separate()
#separate(tibble, column to split, into = c(name of new column 1, name of new column 2), sep = where to cut)
separate(new_df_long, original_col_names, into = c("measure", "rep"), sep = "_")
#we have create two new columns, one called measure, the other called rep
#"measure" contains everything before the underscore, and the second contains everything after the underscore

#we can try this on a bigger dataset: 
gap_wide <- read_csv("data/gapminder_wide.csv")
#we have 142 rows (one per country), the rest of the info is in many many columns:
gap_wide 

#we can turn this mess into the same format as gapminder in three steps: 
#first we gather, then we separate, then we spread: 

gap_long <- gather(gap_wide, key = "orig_names", value = "value", -country, -continent)
gap_long
gap_long_separated <-   separate(gap_long, orig_names, into = c("measure", "year"), sep = "_") 
gap_long_separated
tidy_gapminder <-   spread(gap_long_separated, key = "measure", value = "value")
tidy_gapminder #this looks like the original gapminder! 

#we can save a couple of intermediate dfs by using pipes: 
gap_wide %>% gather(key = "orig_names", value = "value", -country, -continent) %>% 
             separate(orig_names, into = c("measure", "year"), sep = "_") %>% 
             spread(key = "measure", value = "value")

