# this is a testing branch to come up with some new ways of classifying the NALCMS data
# lets bring in the library used to perform this task
require(raster)
require(rgeos)
require(sp)
require(maptools)

# set the working dir
setwd("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/Outputs/")

# set an output directory
output.dir <- "/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/Outputs/"

gs_values = c(6.5)

# the input NALCMS 2005 Land cover raster
lc05 <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/na_landcover_2005_1km_MASTER.tif")
lc05.mod <- getValues(lc05)
north_south <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/AKCanada_1km_NorthSouth_FlatWater_999_MASTER.tif"))
mask <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/mask_for_finalization_alfresco_VegMap.tif"))
gs_temp <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/AKCanada_gs_temp_mean_MJJAS_1961_1990_climatology_1km_bilinear_MASTER.tif"))
coast_spruce_bog <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/Coastal_vs_Woody_wetlands_MASTER.tif"))
treeline <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/CAVM_treeline_AKCanada_1km_commonExtent_MASTER.tif"))
NoPac <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/ALFRESCO_NorthPacMaritime_forVegMap.tif"))

# here we turn the input rasters into a stack that is then converted into a matrix of values
# inputs <- stack(lc05,gs_temp, coast_spruce_bog, north_south, treeline, NoPac, mask)
# inputs.vals <- getValues(inputs)



# And the resulting 16 AK NALCMS classes are:
# 0 =  
# 1 = Temperate or sub-polar needleleaf forest
# 2 = Sub-polar taiga needleleaf forest
# 5 = Temperate or sub-polar broadleaf deciduous
# 6 = Mixed Forest
# 8 = Temperate or sub-polar shrubland
# 10 = Temperate or sub-polar grassland
# 11 = Sub-polar or polar shrubland-lichen-moss
# 12 = Sub-polar or polar grassland-lichen-moss 
# 13 = Sub-polar or polar barren-lichen-moss
# 14 = Wetland
# 15 = Cropland
# 16 = Barren Lands
# 17 = Urban and Built-up
# 18 = Water
# 19 = Snow and Ice

# COLLAPSES TO:
# 0 0 : 0
# 1 2 : 2
# 5 6 : 4
# 8 8 : 5
# 10 12 : 1
# 13 : 13 ** temp class that will be reclassed at the end
# 14 14 : 6 
# 15 19 : 0


# FINAL OUTPUT CLASSIFICATION AFTER THIS RECLASSIFICATION IS AS FOLLOWS:
# NALCMS Vegetation Map Reclassification - ALFRESCO FIRE MODEL
# -------------------------------------------------------------

# 0 No Vegetation
# 1 Black Spruce
# 2 White Spruce
# 3 Deciduous
# 4 Shrub Tundra
# 5 Gramminoid Tundra
# 6 Wetland Tundra
# 7 Grassland
# 8 North Pacific Maritime Region - Temperate Rainforests
# 255 out of bounds

# this function will reclassify the data
# inputs: r.vec = a vector representing a RasterLayer object; rclVals = a list of values to reclasify or ""; 
# newVal = the new set value; complex = a complex subset fuction using available objects or ""
reclassify <- function(r.vec, rclVals, newVal, complex){
	r.v <- getValues(r)
	if(complex != ''){
		r.vec[which(eval(parse(text=complex)))] <- newVal
	}else{
		for(i in rclVals){
			r.vec[which(r.v == i)] <- newVal
		}
	}
	return(r)
}


# this little loop simply changes the "." to a "_"
if(grep(".",gs_value) == TRUE){
	gs <- sub(".", "_", gs_value, fixed=TRUE)
}else{
	gs <- gs_value
}



# STEP 1:
#  here the code will begin by getting rid of classes we are not interested in and
#  then will begin to aggregate classes that are too fine for this scale of analysis

#this next line just duplicates the input lc map and we will reclassify the values in this map then write it to a TIFF
# lc05.mod <- lc05
# # create a vector of values from the NALCMS 2005 Landcover Map
# v.lc05.mod <- getValues(lc05.mod)

# reclassify the original NALCMS 2005 Landcover Map
# we do this via indexing the data we want using the builtin R {base} function which() and replace the values using the R {Raster}
# package function values() and assigning those values in the [index] the new value desired.
# begin by first collapsing down all classes from the original input that are not of interest to NOVEG
lc05.mod <- reclassify(lc05.mod, c(15:19,128), 0,"")

#values(lc05.mod)[which(values(lc05.mod) == 15 | values(lc05.mod) == 16 | values(lc05.mod) == 17 | values(lc05.mod) == 18 | values(lc05.mod) == 19 | values(lc05.mod) == 128)] <- 0 # rcl 13 & 15 thru 19 as 0

# Reclass the needleleaf classes to SPRUCE
lc05.mod <- reclassify(lc05.mod, c(1:2), 9,"")

#values(lc05.mod)[which(values(lc05.mod) == 1 | values(lc05.mod) == 2)] <- 9 # SPRUCE PLACEHOLDER CLASS
# Reclass the deciduous and mixed as DECIDUOUS
lc05.mod <- reclassify(lc05.mod, c(5:6), 3,"")

# ind <- which(values(lc05.mod) == 5 | values(lc05.mod) == 6); values(lc05.mod)[ind] <- 3 # Final Class

# Reclass Sub-polar or polar shrubland-lichen-moss as SHRUB TUNDRA
lc05.mod <- reclassify(lc05.mod, 11, 9,"")
# ind <- which(values(lc05.mod) == 11); values(lc05.mod)[ind] <- 4 



# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 2
#  here we are going to take the class SPRUCE or WET TUNDRA and break it down into classes of SPRUCE BOG or WETLAND TUNDRA or WETLAND
print(" STEP 2...")

# get the values from the reclasification of Step 1 (this is performed at each step so that the newly updated values from the previous step are added to the values list)
# v.lc05.mod <- getValues(lc05.mod)
# get gs_temp layers values this is the one that will be used to determine the +/- growing season temperatures (6.0/gs_value/7.0)
# v.gs_temp <- getValues(gs_temp)
# # lets get the values of the Coastal_vs_Spruce_bog layer that differentiates the different wetland classes
# v.coast_spruce_bog <- getValues(coast_spruce_bog)
# this command asks which of the values of the reclassed map are wetland and also not near the coast? This will create spruce bog or SPRUCE
reclassify(lc05.mod, "", 9, "lc05.mod == 14 & coast_spruce_bog == 2")

# ind <- which(v.lc05.mod == 14 & v.coast_spruce_bog == 2); values(lc05.mod)[ind] <- 9 # reclassed into SPRUCE placeholder class

# coastal wetlands are now reclassed to a placeholder class
reclassify(lc05.mod, "", 20, "lc05.mod == 14 & coast_spruce_bog != 2")

# ind <- which(v.lc05.mod == 14 & v.coast_spruce_bog != 2); values(lc05.mod)[ind] <- 20 # reclassed to a PlaceHolder class of 20 (coastal wetland)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# Step 3 here the coastal wetland class is going to be reclassified into WETLAND TUNDRA or NO VEG
print("  STEP 3...")

# v.lc05.mod <- getValues(lc05.mod)
# v.treeline <- getValues(treeline)

# here we are taking the placeholder class of 20 and turning it into Wetland Tundra and NoVeg
reclassify(lc05.mod, "", 6, "lc05.mod == 20 & gs_temp < gs_value & treeline == 1")
# ind <- which(v.lc05.mod == 20 & v.gs_temp < gs_value & v.treeline == 1); values(lc05.mod)[ind] <- 6 # this is a FINAL CLASS WETLAND TUNDRA

reclassify(lc05.mod, "", 0, "lc05.mod == 20 & gs_temp >= gs_value & treeline == 1")
# ind <- which(v.lc05.mod == 20 & v.gs_temp >= gs_value & v.treeline == 1); values(lc05.mod)[ind] <- 0
# this next line is saying that if a pixel in lc05 has gs_temp < 6.5 and is in the coastal region but not above treeline make it a black spruce
reclassify(lc05.mod, "", 0, "lc05.mod == 20 & gs_temp >= gs_value & treeline == 0")
# ind <- which(v.lc05.mod == 20 & v.gs_temp >= gs_value & v.treeline == 0); values(lc05.mod)[ind] <- 0

# here we turn the remainder of the placeholder class into noVeg
# v.lc05.mod <- getValues(lc05.mod)
# remove the remainder of the class 20 which were over some NA cells incorrectly during the original query
reclassify(lc05.mod, 20, 0, "")
# ind <- which(v.lc05.mod == 20); values(lc05.mod)[ind] <- 0 

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 4
# lets turn the placeholder class 8 (Temperate or sub-polar shrubland) into DECIDUOUS or SHRUB TUNDRA
print("   STEP 4...")

# v.lc05.mod <- getValues(lc05.mod)

# now lets find the values we need for this reclassification step
ind <- which(v.lc05.mod == 8 & v.gs_temp < gs_value); values(lc05.mod)[ind] <- 4 # this is the final class of SHRUB TUNDRA
ind <- which(v.lc05.mod == 8 & v.gs_temp >= gs_value); values(lc05.mod)[ind] <- 3 # this is the final class of DECIDUOUS

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 5
# here we are reclassifying the gramminoid tundra/grassland into simply gramminoid tundra
# *this is at the suggestion of Amy Breen (abreen@alaska.edu)*  
print("    STEP 5...")

# # Reclass Sub-polar or polar grassland-lichen-moss as GRAMMINOID TUNDRA
ind <- which(v.lc05.mod == 12 | v.lc05.mod == 10); values(lc05.mod)[ind] <- 5 # GRAMMINOID TUNDRA
writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,"_Step4.tif", sep=""), overwrite=TRUE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 6
print("     STEP 6...")
# reclassify the SPRUCE category to WHITE and BLACK based on <>6.5 degrees and North/South Slopes 

v.lc05.mod <- getValues(lc05.mod)
#Now we bring the north_south map into the mix to differentiate between the white and black spruce from the SPRUCE class
v.north_south <- getValues(north_south)

# we need to examine the 2 placeholder classes for SPRUCE class and parse them out in to WHITE / BLACK.  
#this line states that, where the SPRUCE class exists & is on a North Facing slope 
ind <- which(v.lc05.mod == 9 & v.north_south == 1); values(lc05.mod)[ind] <- 2
# if any pixels in the 2 spruce classes are north facing and have gs_temps < gs_value then it is BLACK SPRUCE
ind <- which(v.lc05.mod == 9 & v.north_south == 2); values(lc05.mod)[ind] <- 1 # this is a culprit of the spruce issue.

#------------------------------------------------------------------------------------------------------------------------
# this little 2 liner is put in to solve the issue with leftover class 9 in the ALFRESCO Veg Map reclassification\
# there are issues with the 999 {flat areas} with some overlap with spruce.
v.lc05.mod <- getValues(lc05.mod)
ind <- which(v.lc05.mod == 9 & v.north_south == 999); values(lc05.mod)[ind] <- 0
# here we turn all of the remainders into WHITE SPRUCE
v.lc05.mod <- getValues(lc05.mod)
ind <- which(v.lc05.mod == 9); values(lc05.mod)[ind] <- 2

#-----------------------------------------------------------
# STEP 7
print("      STEP 7...")

# this is where it is necessary to make up for some of the deficiencies in the NALCMS map.  In particular the spruce contingent on the north slope
# here i will use some focal stats to give values to the pixels based on the majority of non-spruce and non-water pixels in the window
v.lc05.mod <- getValues(lc05.mod)
v.treeline <- getValues(treeline)

focalNeighbors <- 16 # this is a value of 4(rook),8(queen),16,OR bishop

# which values north of treeline are spruce?
ind <- which((v.lc05.mod == 1 | v.lc05.mod == 2) & v.treeline == 1)

while(length(ind) > 0){
	# here we create a matrix that will be used to hold focal and 16 neighbors and reclass value
	new.m <- matrix(NA,nrow=length(ind),ncol=focalNeighbors+2)

	print(paste("number of bad pixels: ", length(ind)))

	# fill column 1 with the cell indexes grabbed above
	new.m[,1] <- ind
	
	for(n in 1:nrow(new.m)){
		# here we ask which cell numbers are adjacent to the focal cell of interest
		adj <- adjacent(lc05.mod, new.m[n,1], directions=focalNeighbors, pairs=FALSE, target=NULL, sorted=FALSE, include=FALSE, id=FALSE)	
		# then we add those cell vals to the matrix
		new.m[n,2:as.integer(focalNeighbors+1)] <- adj
		# this line grabs those values from the indexes 
		adjCellVals <- v.lc05.mod[adj]
		# which ones of these cells are not 0,1,2 (oob, black spruce, white spruce)
		desiredInd <- which(adjCellVals > 2| adjCellVals == 0) 
		# what is the most common value in the set?
		adjCellVals.count <- table(adjCellVals[desiredInd])
		# what do we do if there are no values that meet criteria?
		if(length(adjCellVals.count) == 0){
			#print("SKIP!!!")
			new.m[n,focalNeighbors+2] <- NA
		}else{	
			maxCount <- which(as.vector(adjCellVals.count) == max(as.vector(adjCellVals.count)))
			
			# # here if there is a tie, we are going to take the first one in the list.  Gotta choose one.
			if(length(maxCount)>1){ maxCount <- maxCount[1] } else{ maxCount <- maxCount }
			cellVals <- as.numeric(names(adjCellVals.count))		
			new.m[n,focalNeighbors+2] <- cellVals[maxCount]
		}
	}
	# which are the non-NA's?
	NA.ind <- which(is.na(new.m[,focalNeighbors+2])==FALSE)
	# change those values in the raster
	values(lc05.mod)[new.m[,1][NA.ind]] <- new.m[,focalNeighbors+2][NA.ind]
	# get the values the reclassified map again
	v.lc05.mod <- getValues(lc05.mod)
	# which values north of treeline are spruce?
	ind <- which((v.lc05.mod == 1 | v.lc05.mod == 2) & v.treeline == 1)
	print(paste("   new length of bad pixels: ", length(ind)))
}

# # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 8
#  this is where we define the North Pacific Maritime Region as its own map region that is independent of the others
print("       STEP 8...")

# here we get the values of the lc05 map again.
v.lc05.mod <- getValues(lc05.mod)
# get the values for the North Pacific Maritime region map that we will use to reclassify that region in the new veg map
v.NoPac <- getValues(NoPac)
ind <- which(v.lc05.mod > 0 & v.NoPac == 1); values(lc05.mod)[ind] <- 8

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 9 
#  turn the barren lichen moss /heath class into value 7
v.lc05.mod <- getValues(lc05.mod)
ind <- which(v.lc05.mod == 13); values(lc05.mod)[ind] <- 7

# # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 9 
# here we need to set all of the not "no_veg" values to 255 and NoVeg to 0 using the mask file above.  It is a 3 category mask
#  with classes for Out-of-bounds, saskatoon agricultural area, all other areas
v.lc05.mod <- getValues(lc05.mod)
mask.v <- getValues(mask) # this is going to set all of the NoData values to 1 and the vals I want to 0
# turn all of the out-of-bounds areas to value=255
values(lc05.mod)[which(mask.v == 1)] <- 255
# now lets mask it to the final mask removing the Saskatoon, Canada area (agriculture)
ind <- which(mask.v == 3); values(lc05.mod)[ind] <- 0 
writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,".tif", sep=""), overwrite=T, options="COMPRESS=LZW")

