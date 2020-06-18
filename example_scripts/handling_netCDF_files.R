#today we explore how to handle netCDF files 
#the ncdf4 package can handle both netCDF3 and netCDF4 files 
#this type format is great for handling massive amounts of data - maybe more than your computer can handle  

#install.packages("ncdf4")

library(ncdf4)
library(dplyr)

#functions from the ncdf4 package we will use today: 
#nc_open() open connection to the file 
#ncvar_get()
#nc_close() close connection to the file 


#The example file for today is ".nc"
#this is output from GEOS-Chem, massaged into a nice, very small, .nc file by Jenny Fisher from UOW
#it contains surface values for a few tracers over parts of NSW 

#the file is located in the data/netCDF folder 
fname <- "data/netCDF/ts20150202.nc"

gc <- nc_open(fname) #gc does not contain the data, but the 'connection' to the file 

print(gc) #lets us see how the file is structured 

summary(gc$var)
rownames(summary(gc$var))

#pulling data out:

#dimensions (1D data): 
date <- ncvar_get(gc, "date")
date <- as.POSIXct(ncvar_get(gc, "date")) 

#date is in the variable list (handy), but we could create it from the 'time' dimension (yes, we can 'get' dimensions)
time <- ncvar_get(gc, "time")
date2 <- as.POSIXct(time*3600, origin = "1985-01-01 00:00:00", tz = "UTC") #*3600 to convert to seconds 

lat <-  ncvar_get(gc, "lat") 
lon <-  ncvar_get(gc, "lon")

#variables (or measures in the dplyr terminology)
#In this case, 3D data (lon, lat, time) but could be 4D (lon, lat, level, time) or more 
isoprene_array <- ncvar_get(gc, "IJ_AVG_S__ISOP")
monoterpene_array <- ncvar_get(gc, "IJ_AVG_S__MTPA")

#what happens next really depends on what we want to do with the data 

#we can 'slice' the cube: 

#select one lat/lon, keep all hours 
isoprene_site1 <- isoprene_array[4,8,] #this is a vector 

#note that is the array was very big, we would be better off subsetting at the 'get' stage: 
isoprene_site2 <- ncvar_get(gc, "IJ_AVG_S__ISOP")[10,7,]

#basic plotting will let you use vectors 
plot(isoprene_site1 ~date)

#but openair won't, so we need to build a dataframe 
isoprene_df <- data.frame(date = date, isoprene = isoprene_site1, site = 1)

#if you were interested in more than one variable 
list_var <- rownames(summary(gc$var))[-1] #date is 1D so the subsetting will fail if we include it 

#we can also subset as we pull in, very useful for massive datasets 
data_site1 <- lapply(list_var, function(t) ncvar_get(gc, t)[4,8,])

gc_site1 <- bind_cols(data_site1) #this is all bind_rows, but each element of the list becomes a column 
View(gc_site1) #we need some variable/column names! 
names(gc_site1) <- list_var
#add a date column 
gc_site1$date <- date 
gc_site1$site <- 1

#OR, we may want to keep all lats and lons, but only a specific hour of the day (this is a bit artificial, but hey)
#let's say 08:00 
date[8]
isoprene_0800 <- isoprene_array[,,8]

#we could keep a smaller map 
isoprene_0800_zoom <- isoprene_array[1:4,1:4,8] #this keeps a corner of the map
lon[1:4]
lat[1:4]

#of course, it might be better to do this when we 'get' the data 
isoprene_0800_zoom <- ncvar_get(gc, "IJ_AVG_S__ISOP")[1:4,1:4,] 
#keeps all hours, but keeps only the bit of the map we are interested in 



#can we keep the data in a more 'native' format - a netCDF-like structure within R
#tbl_cube(), from dplyr - this is an experimental class, not yet optimised, and limited in scope for now
#https://dplyr.tidyverse.org/reference/tbl_cube.html#implementation

#tbl_cube(dimensions, measures)

dims <- list(lon = lon, lat = lat, date = date)
meas <- list(isoprene = isoprene_array, monoterpenes = monoterpene_array)

gc_cube <- tbl_cube(dimensions = dims, measures = meas)
gc_cube
#can be turned into a 2D structure: 
head(as.data.frame(gc_cube))

#the normal dplyr syntax applies 

#we can use select() (works on measures only)
select(gc_cube, isoprene)

#we can filter() (works on dimensions only)
filter(gc_cube, lon < 151)

#very nicely, we can use group_by:

by_loc <- group_by(gc_cube, lat, lon) %>% 
summarise( isoprene_max = max(isoprene), monoterpene_avg = mean(monoterpenes))

as.data.frame(by_loc)
