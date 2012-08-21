# this is a testing branch to come up with some new ways of classifying the NALCMS data
# lets bring in the library used to perform this task
require(raster)

# set the working dir
setwd("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/Outputs/")

# set an output directory
output.dir <- "/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/Outputs/"


gs_values = c(6.5)

# the input NALCMS 2005 Land cover raster
lc05 <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/na_landcover_2005_1km_MASTER.tif")
north_south <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/AKCanada_1km_NorthSouth_FlatWater_999_MASTER.tif")
mask <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/AKCanada_PRISM_Mask_1km_gs_temp_version.tif")
gs_temp <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/AKCanada_gs_temp_mean_MJJAS_1961_1990_climatology_1km_bilinear_MASTER.tif")
coast_spruce_bog <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/Coastal_vs_Woody_wetlands_MASTER.tif")
treeline <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/CAVM_treeline_AKCanada_1km_commonExtent_MASTER.tif")
NoPac <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/ALFRESCO_NorthPacMaritime_forVegMap.tif")

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
# 10 13 : 1
# 14 14 : 6 
# 15 19 : 0


# this outer loop is used for testing the differences between different thresholds of gs_temp values
for(gs_value in gs_values){
	# print out the gs value being currently used to create an output map
	print(paste("current gs_value = ", gs_value, sep=""))

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
	lc05.mod <- lc05
	
	# create a vector of values from the NALCMS 2005 Landcover Map
	v.lc05.mod <- getValues(lc05.mod)

	#reclassify the original NALCMS 2005 Landcover Map
	# we do this via indexing the data we want using the builtin R {base} function which() and replace the values using the R {Raster}
	# package function values() and assigning those values in the [index] the new value desired.

	# begin by first collapsing down all classes from the original input that are not of interest to NOVEG
	ind <- which(v.lc05.mod == 13 | v.lc05.mod == 15 | v.lc05.mod == 16 | v.lc05.mod == 17 | v.lc05.mod == 18 | v.lc05.mod == 19 | v.lc05.mod == 128); values(lc05.mod)[ind] <- 0 # rcl 13 & 15 thru 19 as 0

	# Reclass the needleleaf classes to SPRUCE
	ind <- which(v.lc05.mod == 1 | v.lc05.mod == 2); values(lc05.mod)[ind] <- 9 # SPRUCE PLACEHOLDER CLASS

	# Reclass the deciduous and mixed as DECIDUOUS
	ind <- which(v.lc05.mod == 5 | v.lc05.mod == 6); values(lc05.mod)[ind] <- 3 # Final Class

	# Reclass Sub-polar or polar shrubland-lichen-moss as SHRUB TUNDRA
	ind <- which(v.lc05.mod == 11); values(lc05.mod)[ind] <- 4 

	# Reclass Sub-polar or polar grassland-lichen-moss as GRAMMINOID TUNDRA
	ind <- which(v.lc05.mod == 12); values(lc05.mod)[ind] <- 5

	writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,"_Step1.tif", sep=""), overwrite=TRUE)

	# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

	# STEP 2
	#  here we are going to take the class SPRUCE or WET TUNDRA and break it down into classes of SPRUCE BOG or WETLAND TUNDRA or WETLAND
	# get the values from the reclasification of Step 1 (this is performed at each step so that the newly updated values from the previous step are added to the values list)
	v.lc05.mod <- getValues(lc05.mod)

	# get gs_temp layers values this is the one that will be used to determine the +/- growing season temperatures (6.0/gs_value/7.0)
	v.gs_temp <- getValues(gs_temp)

	# lets get the values of the Coastal_vs_Spruce_bog layer that differentiates the different wetland classes
	v.coast_spruce_bog <- getValues(coast_spruce_bog)

	# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	# touch base with Amy about whether this is an ok differentiation to create.  Where only the Wetland Tundra occurs at the coast and not in the interior?
	# this command asks which of the values of the reclassed map are wetland and also not near the coast? This will create spruce bog or SPRUCE
	ind <- which(v.lc05.mod == 14 & v.coast_spruce_bog == 2); values(lc05.mod)[ind] <- 9 # reclassed into SPRUCE placeholder class
	# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	# coastal wetlands are now reclassed to a placeholder class
	ind <- which(v.lc05.mod == 14 & v.coast_spruce_bog != 2); values(lc05.mod)[ind] <- 20 # reclassed to a PlaceHolder class of 20 (coastal wetland)

	# rm(v.coast_spruce_bog)
	# rm(coast_spruce_bog)

	# write out and intermediate raster for review
	writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,"_Step2.tif", sep=""), overwrite=TRUE)

	# -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	# Step 3 here the coastal wetland class is going to be reclassified into WETLAND TUNDRA or NO VEG
	v.lc05.mod <- getValues(lc05.mod)
	v.treeline <- getValues(treeline)

	# here we are taking the placeholder class of 20 and turning it into Wetland Tundra and NoVeg
	ind <- which(v.lc05.mod == 20 & v.gs_temp < gs_value & v.treeline == 1); values(lc05.mod)[ind] <- 6 # this is a FINAL CLASS WETLAND TUNDRA
	ind <- which(v.lc05.mod == 20 & v.gs_temp >= gs_value & v.treeline == 1); values(lc05.mod)[ind] <- 0
	# this next line is saying that if a pixel in lc05 has gs_temp < 6.5 and is in the coastal region but not above treeline make it a black spruce
	#ind <- which(v.lc05.mod == 20 & v.gs_temp < gs_value & v.treeline == 0); values(lc05.mod)[ind] <- 1
	ind <- which(v.lc05.mod == 20 & v.gs_temp >= gs_value & v.treeline == 0); values(lc05.mod)[ind] <- 0
	
	# here we turn the remainder of the placeholder class into noVeg
	# get the values again.  cant find another way to do this
	v.lc05.mod <- getValues(lc05.mod)
	#remove the last of the 20's
	ind <- which(v.lc05.mod == 20); values(lc05.mod)[ind] <- 0 

	writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,"_Step3.tif", sep=""), overwrite=TRUE)

	# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	# STEP 4
	# lets turn the placeholder class 13 (Temperate or sub-polar shrubland) into DECIDUOUS or SHRUB TUNDRA

	v.lc05.mod <- getValues(lc05.mod)

	# now lets find the values we need for this reclassification step
	ind <- which(v.lc05.mod == 8 & v.gs_temp < gs_value); values(lc05.mod)[ind] <- 4 # this is the final class of SHRUB TUNDRA
	ind <- which(v.lc05.mod == 8 & v.gs_temp > gs_value); values(lc05.mod)[ind] <- 3 # this is the final class of DECIDUOUS

	# now I am going to complete the reclassification of the NALCMS class 10 Temperate or sub-polar grassland to GRAMMINOID TUNDRA and GRASSSLAND (NoVeg)
	ind <- which(v.lc05.mod == 10 & v.gs_temp < gs_value); values(lc05.mod)[ind] <- 5 # GRAMMINOID TUNDRA
	ind <- which(v.lc05.mod == 10 & v.gs_temp > gs_value); values(lc05.mod)[ind] <- 7
	
	# I am doing this against my better judgement to get this damn thing running
	v.lc05.mod <- getValues(lc05.mod)
	ind <- which(v.lc05.mod == 10); values(lc05.mod)[ind] <- 7 # GRASSLAND Class

	writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,"_Step4.tif", sep=""), overwrite=TRUE)

	# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

	# STEP 5
	#  this is where we reclassify the SPRUCE category to WHITE and BLACK based on <>6.5 degrees and North/South Slopes 
	v.lc05.mod <- getValues(lc05.mod)

	#Now we bring the north_south map into the mix to differentiate between the white and black spruce from the SPRUCE class
	v.north_south <- getValues(north_south)

	# we need to examine the 2 placeholder classes for SPRUCE class and parse them out in to WHITE / BLACK.  
	# if any pixels in the spruce classes are north facing and have gs_temps > gs_value then it is WHITE SPRUCE


	#*** ok this line states that, where the SPRUCE class exists & is on a North Facing slope 
	ind <- which(v.lc05.mod == 9 & v.north_south == 1); values(lc05.mod)[ind] <- 2

	#v.lc05.mod <- getValues(lc05.mod)
	# if any pixels in the 2 spruce classes are north facing and have gs_temps < gs_value then it is BLACK SPRUCE
	ind <- which(v.lc05.mod == 9 & v.north_south == 2); values(lc05.mod)[ind] <- 1 # this is a culprit of the spruce issue.

	#------------------------------------------------------------------------------------------------------------------------
	#   I DO NOT FEEL CONFIDENT ABOUT THIS FIX!!!!  CHECK IN ON THIS LATER TO ASSESS PROPERLY!
	# this little 2 liner is put in to solve the issue with leftover class 9 in the ALFRESCO Veg Map reclassification\
	#  i think that there are issues with the 999 {flat areas} with some overlap with spruce...  
	v.lc05.mod <- getValues(lc05.mod)
	ind <- which(v.lc05.mod == 9 & v.north_south == 999); values(lc05.mod)[ind] <- 0
	# here we turn all of the remainders into WHITE SPRUCE
	v.lc05.mod <- getValues(lc05.mod)
	ind <- which(v.lc05.mod == 9); values(lc05.mod)[ind] <- 2
	#------------------------------------------------------------------------------------------------------------------------

	writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,"_Step5.tif", sep=""), overwrite=TRUE)

	# STEP 6
	# this is where it is necessary to make up for some of the deficiencies in the NALCMS map.  In particular the spruce contingent on the north slope
	# here i will use some focal stats to give values to the pixels based on the majority of non-spruce and non-water pixels in the window
	v.lc05.mod <- getValues(lc05.mod)
	v.treeline <- getValues(treeline)

	
	if(length(which((v.lc05.mod == 1 | v.lc05.mod == 2) & v.treeline == 1) > 0)){
		ind <- which((v.lc05.mod == 1 | v.lc05.mod == 2) & v.treeline == 1)
		for(i in ind){
			# here we aer looking for cell numbers that are adjacent to the list of cell numbers I am going to give the function
			ad <- adjacent(lc05.mod, i, directions=8, pairs=FALSE, target=NULL, sorted=TRUE, include=TRUE, id=FALSE)
			# here is where we ask which neighbors the focal cell has
			adjCellVals <- values(lc05.mod)[ad]
			# which ones of these cells are not 0,1,2 (oob, black spruce, white spruce)
			newInd <- which(adjCellVals > 2)
			# what is the most common value in the set?
			count(adjCellVals[newInd])
			newValue <- max(count(adjCellVals[newInd])[,2])
			values(lc05.mod)[newInd] <- newValue
		}
		v.lc05.mod <- getValues(lc05.mod)
	}

	# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	# STEP 7
	#  this is where we define the North Pacific Maritime Region as its own map region that is independent of the others

	# here we get the values of the lc05 map again.
	# v.lc05.mod <- getValues(lc05.mod)
	# ind <- which(v.lc05.mod == 9); values(lc05.mod)[ind] <- 1
	v.lc05.mod <- getValues(lc05.mod)
	
	# get the values for the North Pacific Maritime region map that we will use to reclassify that region in the new veg map
	v.NoPac <- getValues(NoPac)

	ind <- which(v.lc05.mod > 0 & v.NoPac == 1); values(lc05.mod)[ind] <- 8

	writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,".tif", sep=""), overwrite=TRUE)
	
	rm(v.lc05.mod)
}