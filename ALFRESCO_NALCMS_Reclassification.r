# this is a testing branch to come up with some new ways of classifying the NALCMS data
# lets bring in the library used to perform this task
require(raster)

# set the working dir
setwd("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/rcl_new/")

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
	# writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step2.tif", sep=""), overwrite=TRUE)
	# -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	# Step 3 here the coastal wetland class is going to be reclassified into WETLAND TUNDRA or NO VEG
	v.lc05.mod <- getValues(lc05.mod)
	v.treeline <- getValues(treeline)

	# here we are taking the placeholder class of 20 and turning it into Wetland Tundra and NoVeg
	ind <- which(v.lc05.mod == 20 & v.gs_temp < gs_value & v.treeline == 1); values(lc05.mod)[ind] <- 6 # this is a FINAL CLASS WETLAND TUNDRA

	# here we turn the remainder of the placeholder class into noVeg
	ind <- which(v.lc05.mod == 20 & v.gs_temp >= gs_value); values(lc05.mod)[ind] <- 0 


	# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	# STEP 4
	# lets turn the placeholder class 13 (Temperate or sub-polar shrubland) into DECIDUOUS or SHRUB TUNDRA

	v.lc05.mod <- getValues(lc05.mod)

	# now lets find the values we need for this reclassification step
	ind <- which(v.lc05.mod == 8 & v.gs_temp < gs_value); values(lc05.mod)[ind] <- 4 # this is the final class of SHRUB TUNDRA
	ind <- which(v.lc05.mod == 8 & v.gs_temp > gs_value); values(lc05.mod)[ind] <- 3 # this is the final class of DECIDUOUS

	# writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step3.tif", sep=""), overwrite=TRUE)

	# now I am going to complete the reclassification of the NALCMS class 10 Temperate or sub-polar grassland to GRAMMINOID TUNDRA and GRASSSLAND (NoVeg)
	ind <- which(v.lc05.mod == 10 & v.gs_temp < gs_value); values(lc05.mod)[ind] <- 5 # GRAMMINOID TUNDRA
	ind <- which(v.lc05.mod == 10 & v.gs_temp > gs_value); values(lc05.mod)[ind] <- 7
	
	# I am doing this against my better judgement to get this damn thing running
	v.lc05.mod <- getValues(lc05.mod)
	ind <- which(v.lc05.mod == 10); values(lc05.mod)[ind] <- 7 # GRASSLAND Class

	# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

	# STEP 5

	v.lc05.mod <- getValues(lc05.mod)

	#Now we bring the north_south map into the mix to differentiate between the white and black spruce from the SPRUCE class
	v.north_south <- getValues(north_south)

	# we need to examine the 2 placeholder classes for SPRUCE class and parse them out in to WHITE / BLACK.  
	# if any pixels in the spruce classes are north facing and have gs_temps > gs_value then it is WHITE SPRUCE
	ind <- which(v.lc05.mod == 9 & (v.gs_temp > gs_value | v.north_south == 1)); values(lc05.mod)[ind] <- 2 # FINAL WHITE SPRUCE CLASS

	# if any pixels in the 2 spruce classes are north facing and have gs_temps < gs_value then it is BLACK SPRUCE
	ind <- which(v.lc05.mod == 9 & (v.gs_temp <= 6.5 & v.north_south == 1)); values(lc05.mod)[ind] <- 1

	# here we get the values of the lc05 map again.
	# v.lc05.mod <- getValues(lc05.mod)
	# ind <- which(v.lc05.mod == 9); values(lc05.mod)[ind] <- 1
	v.lc05.mod <- getValues(lc05.mod)
	NoPac <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/NALCMS_VegReClass_Inputs/NorthPacific_Temperate_Rainforest_MASTER.tif")
	# get the values for the North Pacific Maritime region map that we will use to reclassify that region in the new veg map
	v.NoPac <- getValues(NoPac)

	ind <- which(v.lc05.mod > 0 & v.NoPac == 1); values(lc05.mod)[ind] <- 8


	if(grep(".",gs_value) == TRUE){
		gs <- sub(".", "_", gs_value, fixed=TRUE)
	}else{
		gs <- gs_value
	}


	writeRaster(lc05.mod, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_v2_gs",gs,".tif", sep=""), overwrite=TRUE)
	rm(v.lc05.mod)
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	# # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	# here I am going to reclassify the MOSAICKED (not performed here) CAVM reclassified map and the NALCMS reclassified map
	#  we are creating a region that is classified Coastal Temperate Rainforest

	# read in the new map:

	# alf_veg <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/combine_CAVM_NALCMS05/ALFRESCO_VegMap_NALCMS_CAVM_hybrid.img")
	
	# alf_veg.v <- getValues(alf_veg)

	# ind <- which(NoPac.v == 1); values(alf_veg)[ind] <- 8

	# writeRaster(alf_veg, filename="/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/Version4_Final/ALF_Veg_NALCMS_CAVM_hyb_rainforest.tif")


}