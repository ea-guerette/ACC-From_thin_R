#the goal today is to overlay a map with model data and observations at specific sites
#the 'easiest' way I have found to make this plot is using ggplot, a plotting package that is part of the tidiverse
#BUT there are many other packages out there and 
#if you deal with spatial data a lot, you'll probably want to investigate:
#raster (the package) and rasterVis 
#also have a look at this for more resources: 
#https://www.r-spatial.org/

#we will be using some new packages today: 
#install.packages("sf")
#install.packages("ggmap")
#install.packages("ncdf4")

library(tidyverse)
library(ncdf4) #we will need this to read in our model data 
library(sf) #to read in the shapefile 
library(ggmap) #has functions to pull maps from internet servers such as OpenStreetMap, Google (you will need an API key), Stamen and plot them
library(maps) #contains built in maps 
#library(mapdata) #contains more built in maps, but we won't use it today

#As we will be using the package ggplot2 for the first time, here is a VERY quick crash course
#There is a page or two on this in the RStudio Cheatsheets in the Files folder on Teams 
#The main thing to know is that ggplot works in layers

#First, let's load some data to plot: 
gapminder <- readr::read_csv("data/gapminder.csv")

#keep data from only one year to make this more manageable
gap_1977 <- dplyr::filter(gapminder, year ==1977)

#to make a plot, we use ggplot() from the ggplot2 package and pass it some data, 
#and then associate the columns in our dataframe to elements of the plot (i.e. x and y)
#this is done through mapping = aes()
ggplot(data = gap_1977, mapping = aes(x = gdpPercap, y = lifeExp)) ##nothing much happens when we run this. 

#because we need to tell ggplot what TYPE of plot (or geometry) we want:
ggplot(data = gap_1977, mapping = aes(x = gdpPercap, y = lifeExp)) + #the plus sign means we are adding a layer
  geom_point() # this plots the data as dots  

ggplot(data = gap_1977, mapping = aes(x = gdpPercap, y = lifeExp)) + #the plus sign means we are adding a layer
  geom_line() # this plots the data as a line

ggplot(data = gap_1977, mapping = aes(x = gdpPercap, y = lifeExp)) +
  geom_smooth() #fits a curve to the data - the default is 'loess'

#we can combine layers: 
ggplot(data = gap_1977, mapping = aes(x = gdpPercap, y = lifeExp)) +
  geom_point() +
  geom_smooth() 

#we can modify the apperance of each layer separately (here we change the colours only)  
  ggplot(data = gap_1977, mapping = aes(x = gdpPercap, y = lifeExp)) +
  geom_smooth(colour = "cyan") + 
  geom_point(colour = "magenta") 
#notice the points are now on top of the curve - this is because we swapped the order of the layers in the plot call

#some fancier stuff - map dot colour and size to variables - this has to be done INSIDE the aes() brackets
ggplot(data = gap_1977, 
       mapping = aes(x = gdpPercap, y = lifeExp, colour = continent, size = pop)) +
  geom_point()

#some more customisation: 
ggplot(data = gap_1977, 
       mapping = aes(x = gdpPercap, y = lifeExp, colour = continent, size = pop)) +
  geom_point()+
  scale_x_log10() + #this converts the x axis to a log10 scale
  theme_bw() #this modifies the default look of the plot (notice the grey background is gone)

#ggplot(<DATA>, <AESTHETIC MAPPINGS>) + <GEOMETRY LAYER> + ...+ <SCALE> + <THEME>
#or
#ggplot() + <GEOMETRY LAYER(<DATA1>, <AESTHETIC MAPPINGS>)> + <GEOMETRY LAYER(<DATA2>, <AESTHETIC MAPPINGS>)> + ...+ <SCALE> + <THEME>

#the data and aesthetics can be defined within the layer call instead of at the top ggplot() level.
#Useful in our case, since the various layers will come from different dataframes 
ggplot() +
  geom_point(data = gap_1977, 
             mapping = aes(x = gdpPercap, y = lifeExp, colour = continent, size = pop))

#another useful feature is facetting 
#make a plot as above, using the entire gapminder dataframe, making one plot per year: 
ggplot(data = gapminder, 
       mapping = aes(x = gdpPercap, y = lifeExp, colour = continent, size = pop)) +
  geom_point()+
  scale_x_log10() +
  facet_grid(~year) + #alternatively, try facet_wrap(~year)
  theme_bw()

#this ends the crash course. We have barely scratched the surface, but we know enough to make a start on our plot
#Our plot will have three layers: model data, a coastline outline, and some site data 

#Step 1: obtaining a map layer
#there are various ways to do this 
#as we are mostly after a coastline outline, we will start by using a shapefile 
#there is one in "data/AUS_states" 

#the package sf contains a function that can read this shapefile into R 
#we use sf::read_sf(), then 'pipe' (CTRL-SHIFT-M) this into another function that removes some of the detail in the coastline
#the map is too detailed otherwise and takes forever to draw
state_borders <- sf::read_sf("data/AUS_states") %>%
  sf::st_simplify(dTolerance = 0.01) 
#notice how this is not a dataframe containing lat/lon, but a list containing ??? (it's mostly gibberish to me)

#luckily, ggplot has a geometry that understands how to plot this kind of information: 
ggplot() +
  geom_sf(data = state_borders) 

#we can play with the settings: 
ggplot() +
  geom_sf(data = state_borders, fill= NA, colour = "blue")


#if we didn't have a shapefile, we could use some of the built in maps in R
#the 'maps' package contains a world map 
#ggplot2 has a function to save this in a dataframe format that can be plotted as a polygon geometry: 

world_map <- ggplot2::map_data("world") 

ggplot() + 
  geom_polygon(data = world_map, aes(x = long, y = lat, group = group)) #polygon needs this 'group' aesthetic

#we could select Australia only, using the region column:
aus_map <- subset(world_map, region %in% "Australia" )

ggplot() + 
  geom_polygon(data = aus_map, aes(x = long, y = lat, group = group), fill =NA, colour = "black") 

#this has lower resolution than our shapefile, but would do the job if we had nothing else 
#there are more options in the mapdata package 

#Step 2: reading in our model data 
#the file is located in the data/netCDF folder - it is the file we used during the netCDF session: 
fname <- "data/netCDF/ts20150202.nc"

#create connection to the file
gc <- nc_open(fname) #gc does not contain the data, but the 'connection' to the file 

print(gc) #lets us see how the file is structured - read through the output in the console
#if the file is nicely documented, you should get all the info you need to use the file in there 

summary(gc$var) #summary of all variables 
rownames(summary(gc$var)) #this is a vector containing all the names of the variables included in the file - useful to read in all data (see netCDF session)

#pulling data out:
#lat <-  ncvar_get(gc, "lat") 
#lon <-  ncvar_get(gc, "lon") 

#today, we will create a data cube because I think it is nifty, but you can do whatever works best for you 
#the cube needs dimensions, which we get from the netCDF file: 
dims <- list(lon = ncvar_get(gc, "lon") , lat = ncvar_get(gc, "lat") , date = ncvar_get(gc, "date"))
#and it needs variables:  
meas <- list(isoprene = ncvar_get(gc, "IJ_AVG_S__ISOP"), monoterpenes = ncvar_get(gc, "IJ_AVG_S__MTPA"))

gc_cube <- tbl_cube(dimensions = dims, measures = meas)

nc_close(gc) #we are done with the netCDF file, so we close the connection 


#let's summarise the data so we have something to plot 
#let's compute maximum isoprene and mean monoterpenes for each model grid square: 
#we achieve this by grouping the data by lat/lon, and then calculating our desired values for each lat/lon:
by_loc <- group_by(gc_cube, lat, lon) %>% 
  summarise( isoprene_max = max(isoprene), monoterpene_avg = mean(monoterpenes))
#notice we have lost the time dimension - we get one value per grid square

#then we turn the results into a dataframe so it can be handled by ggplot: 
gc_df <- as.data.frame(by_loc)
View(gc_df)

#let's try to plot lat vs lon, coloured by maximum isoprene:
ggplot(data = gc_df, aes(x = lon, y = lat, colour = isoprene_max)) +
  geom_point() #clearly this is not the ideal geometry for this type of data 

ggplot(data = gc_df, aes(x = lon, y = lat)) +
  geom_raster(aes(fill= monoterpene_avg)) #notice we use 'fill' and not 'colour' as the aesthetic here
#geom_tile() and geom_rect() also work, but raster is faster 

#can also do contour plots: 
ggplot(data = gc_df, aes(x = lon, y = lat )) +
  geom_contour_filled(aes(z = isoprene_max)) #the aesthetic is 'z' for contours 

#so now we can combine our map and our model data: 
ggplot() + 
  geom_raster(data = gc_df, aes(x = lon, y = lat, fill = isoprene_max)) +
  geom_sf(data = state_borders, fill = NA, colour = "black")  

#we can see we need to trim our map a bit! we can do this by setting limits on the coordinates of the map

ggplot() + 
  geom_raster(data = gc_df, aes(x = lon, y = lat, fill = isoprene_max)) +
  geom_sf(data = state_borders, fill = NA, colour = "black")  +
  coord_sf(xlim = c(148,152), ylim = c(-36,-33)) #these are not quite right. 
#A better way is to use the model data to set our limits 
ggplot() + 
  geom_raster(data = gc_df, aes(x = lon, y = lat, fill = isoprene_max)) +
  geom_sf(data = state_borders, fill = NA, colour = "black")  +
  coord_sf(xlim = c(min(gc_df$lon), max(gc_df$lon)), ylim = c(min(gc_df$lat), max(gc_df$lat))) 
#now our layers have the same size, it looks a lot better

#Step 3: add observations

#let's create fake site data:
sites <- data.frame(lat = c(-34, -33.5), lon = c(150, 150.5) , isoprene = c(8, 3), site = c(1,2))

ggplot() + 
  geom_raster(data = gc_df, aes(x = lon, y = lat, fill = isoprene_max)) +
  geom_sf(data = state_borders, fill = NA, colour = "black")  +
  coord_sf(xlim = c(min(gc_df$lon), max(gc_df$lon)), ylim = c(min(gc_df$lat), max(gc_df$lat))) +
  geom_point(data = sites, aes(x = lon, y = lat, colour = isoprene))
#our dots are there, but they are hard to see 

ggplot() + 
  geom_raster(data = gc_df, aes(x = lon, y = lat, fill = isoprene_max)) +
  geom_sf(data = state_borders, fill = NA, colour = "black")  +
  coord_sf(xlim = c(min(gc_df$lon), max(gc_df$lon)), ylim = c(min(gc_df$lat), max(gc_df$lat))) +
  geom_point(data = sites, aes(x = lon, y = lat, fill = isoprene), colour = "black", pch = 21, size = 2)
#pch=21 is a bit of a hack so that we can get the black outline  - symbol #21 is an open circle
#we can make it black, and 'fill' it with our isoprene values 

#And voila! 


#some other tidbits:
#to get a 'real map' i.e. a Google-type map, the ggmap package seems useful since it integrates well with ggplot

#I suggest looking at the help file on get_map() for some examples of its use: 
?ggmap::get_map()
#if you want to get a Google map into R (or anywhere), you will need a Google API key. 
#I will not cover this here. 

#in this example, we define boundaries based on our model data. The default for this type of call is to return a Stamen map:
map <- ggmap::get_map(c(left = min(gc_df$lon), bottom = min(gc_df$lat), right = max(gc_df$lon) , top =max(gc_df$lat) ) )
#notice that this is saved as a value! 
#to plot the map: 
ggmap::ggmap(map) 

#this can be used as a base layer, replacing the normal ggplot() call: 
ggmap(map) +  geom_point(data = sites, aes(x = lon, y = lat, fill = isoprene), pch =21, colour = "black", size = 2)

#now we have a map with our site data on top. 

#Note, ggmap does NOT currently support OpenStreetMaps 
#you can read about their cat fight here: 
#https://github.com/dkahle/ggmap/issues/117

#so it's Stamen or getting an API key for the Google server - which is not so hard if I recall correctly. 
#Also the options that are meant to work with Stamen maps seem broken
#ggmap is therefore not great - I think its developer has pretty much given up on it 
#I would not rely on it too much. 


#Some more ramblings about maps: 

#the package RgoogleMaps also as an OSM funtion (GetOsmMap()), but I had no luck when trying to run the examples in the help file. 
#it may be that OSM is rejecting automated calls to its servers. 

#getting satellite, etc. maps straight into R is getter harder and harder. 
#if anyone knows of a good solution, or even a workaround, please let me know. 

#Examples of a work around: 
#I know it is possible to add layers to a .tiff map in python - there is probably an equivalent in R. 
#It might be possible to read in an image (or a .tiff downloaded from the OSM website) as a raster and then manipulate that? 
#All thoughts welcome. 




