#today we explore how to handle netCDF files 
#the ncdf4 package can handle both netCDF3 and netCDF4 files 
#this type format is great for handling massive amounts of data - maybe more than your computer can handle  

#Note that we only look at reading in netCDF files, 
# not creating/editing them, although this is all possible with ncdf4

#install.packages("ncdf4")

library(ncdf4)
library(dplyr)

#functions from the ncdf4 package we will use today: 
#nc_open() open connection to the file 
#ncvar_get() to pull stuff out of the file 
#nc_close() close connection to the file 


#The example file for today is "ts20150202.nc"
#this is output from GEOS-Chem, massaged into a nice, very small, .nc file by Jenny Fisher from UOW
#it contains surface values for a few tracers over parts of NSW 

#the file is located in the data/netCDF folder 
fname <- "data/netCDF/ts20150202.nc"

gc <- nc_open(fname) #gc does not contain the data, but the 'connection' to the file 

print(gc) #lets us see how the file is structured 

summary(gc$var)
rownames(summary(gc$var)) #this is a list of all the variables included in the file - we will use this later

#pulling data out:

#dimensions (1D data): 
date <- ncvar_get(gc, "date") #this is read in as a character 
date <- as.POSIXct(ncvar_get(gc, "date")) #turns it into a date 

#date is in the variable list (handy), but we could create it from the 'time' dimension (yes, we can 'get' dimensions using ncvar_get() )
time <- ncvar_get(gc, "time")
date2 <- as.POSIXct(time*3600, origin = "1985-01-01 00:00:00", tz = "UTC") #*3600 to convert to seconds 
#the 'origin' is given in the meta data of the file: 
#time  Size:24   *** is unlimited ***
#  calendar: gregorian
#long_name: Time, instantaneous or at start of averaging period
#units: hours since 1985-1-1 00:00:0.0
#axis: T
#delta_t: 0000-00-00 01:00:00

lat <-  ncvar_get(gc, "lat") 
lon <-  ncvar_get(gc, "lon")

#variables (or 'measures' in the dplyr terminology - we will use this later)
#In this case, 3D data (lon, lat, time) but could be 4D (lon, lat, level(z), time) or more 
#we can pull in the entire variable: 
isoprene_array <- ncvar_get(gc, "IJ_AVG_S__ISOP")
monoterpene_array <- ncvar_get(gc, "IJ_AVG_S__MTPA")
dim(monoterpene_array) #print out the dimensions of the array 
#but this may be too much data, we will see how to pull in only a subset a bit later 

#Note that our arrays are not under 'Data' in our global environment - how can we handle them?
#what happens next really depends on what we want to do with the data 
#we can 'slice' the cube: 

#select one lat/lon, keep all hours 
isoprene_site1 <- isoprene_array[4,8,] #this is a vector 
lon[4] # longitude of the model grid square that contains the site of interest
lat[8] # latitude  of the model grid square that contains the site of interest
#note that if the array were very big, we would be better off subsetting at the 'get' stage: 
isoprene_site2 <- ncvar_get(gc, "IJ_AVG_S__ISOP")[10,7,]

#basic plotting will let you use vectors 
plot(isoprene_site1 ~date)

#but openair won't, so we need to build a dataframe 
isoprene_df <- data.frame(date = date, isoprene = isoprene_site1, site = 1)
#this gives a dataframe with 3 columns

#if you were interested in all variables: 
list_var <- rownames(summary(gc$var))[-1] #date is 1D so the subsetting will fail if we include it 
list_var

#we will subset as we pull in - reading in just the one site of interest
data_site1 <- lapply(list_var, function(t) ncvar_get(gc, t)[4,8,])
#yes, we are using lapply again :)

gc_site1 <- bind_cols(data_site1) #this is all bind_rows, but each element of the list becomes a column 
View(gc_site1) #we need some variable/column names!  
names(gc_site1) <- list_var #we assign the names contained in list_var
#add a date column 
gc_site1$date <- date 
#and maybe a site column 
gc_site1$site <- 1
#Note we could use 'mutate' from dplyr to do this in one step instead of what I did above 

#so this was extracting one site. 

#In some applications, we may want to keep all lats and lons, but only a specific hour of the day (this is a bit artificial, but hey)
#let's say we want to keep 08:00 
date[8]
isoprene_0800 <- isoprene_array[,,8]
#isoprene_0800 <- ncvar_get(gc, "IJ_AVG_S__ISOP")[,,8]

#we could also keep a smaller map 
isoprene_0800_zoom <- isoprene_array[1:4,1:4,8] #this keeps a corner of the map
lon[1:4]
lat[1:4]

#of course, it might be better to do this when we pull in the data 
isoprene_0800_zoom <- ncvar_get(gc, "IJ_AVG_S__ISOP")[1:4,1:4,] 
#keeps all hours, but keeps only the bit of the map we are interested in 

#Something I discovered recently: 
#can we keep the data in a more 'native' format - a netCDF-like structure within R
#tbl_cube(), from dplyr - this is an experimental class, not yet optimised, and limited in scope for now
#https://dplyr.tidyverse.org/reference/tbl_cube.html#implementation

#tbl_cube(dimensions, measures)
#the cube needs dimensions, and then data to fill it 

#for this example, we will use data we have pulled in from our 'gc' file
#we create a 'named list' containing our dimensions: 
dims <- list(lon = lon, lat = lat, date = date)

#alternatively, this works too: 
#dims <- list(lon, lat, date)
#names(dims) <- c("lon", "lat", "date")

#then we create a 'named list' of the data array we want to include: 
meas <- list(isoprene = isoprene_array, monoterpenes = monoterpene_array)

#we then create the data cube: 
gc_cube <- tbl_cube(dimensions = dims, measures = meas)
gc_cube
#Source: local array [3,168 x 3]
#D: lon [dbl, 12]
#D: lat [dbl, 11]
#D: date [dttm, 24]
#M: isoprene [dbl[,11,24]]
#M: monoterpenes [dbl[,11,24]]
class(gc_cube)
#notice how the cube is stored as a list in the Global Environment
#it can be turned into a 2D structure: 
head(as.data.frame(gc_cube))

#since tbl_cube is a dplyr class, the normal dplyr syntax applies 
#we can use select() (works on measures only)
select(gc_cube, isoprene)

#we can filter() (works on dimensions only)
filter(gc_cube, lon < 151)

#very nicely, we can use group_by:
by_loc <- group_by(gc_cube, lat, lon) %>% 
summarise( isoprene_max = max(isoprene), monoterpene_avg = mean(monoterpenes))
#and then turn the results into a dataframe
as.data.frame(by_loc)
#we have one row per lat/lon

#Mini Challenge: create a cube directly from ncvar_get commands

#Remember to close the file - not critical for this example, but would lead to issues with massive files. 
nc_close(gc)
