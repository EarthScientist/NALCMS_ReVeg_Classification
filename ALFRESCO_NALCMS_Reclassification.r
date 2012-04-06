# this is a testing branch to come up with some new ways of classifying the NALCMS data
# lets bring in the library used to perform this task
require(raster)

# set the working dir
setwd("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/working_folder/")

# set an output directory
output.dir <- "/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/outputs/run_5/"


# the input NALCMS 2005 Land cover raster
lc05 <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/NALCMS_VegReClass_Inputs/na_landcover_2005_1km_MASTER.tif")
north_south <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/NALCMS_VegReClass_Inputs/AKCanada_1km_NorthSouth_FlatWater_999_MASTER.tif")
mask <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/NALCMS_VegReClass_Inputs/AKCanada_PRISM_Mask_1km_gs_temp_version.tif")
gs_temp <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/NALCMS_VegReClass_Inputs/AKCanada_gs_temp_mean_MJJAS_1961_1990_climatology_1km_bilinear_MASTER.tif")
coast_spruce_bog <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/NALCMS_VegReClass_Inputs/Coastal_vs_Woody_wetlands_MASTER.tif")

#this next line just duplicates the input lc map and we will change the values in this map and write it to a TIFF
lc05.mod <- lc05
# remove the MASTER LC map
rm(lc05)
# create a vector of values from the NALCMS 2005 Landcover Map
v.lc05.mod <- getValues(lc05.mod)

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

# STEP 1

#reclassify the original NALCMS 2005 Landcover Map
# we do this via indexing the data we want using the builtin R {base} function which() and replace the values using the R {Raster}
# package function values() and assigning those values in the [index] the new value desired.
ind <- which(v.lc05.mod == 1 | v.lc05.mod == 2); values(lc05.mod)[ind] <- 2 # rcl 1 and 2 as 2
ind <- which(v.lc05.mod == 5 | v.lc05.mod == 6); values(lc05.mod)[ind] <- 4 # rcl 5 and 6 as 4
ind <- which(v.lc05.mod == 8); values(lc05.mod)[ind] <- 5 # rcl 8 as 5
ind <- which(v.lc05.mod == 10 | v.lc05.mod == 11 | v.lc05.mod == 12 | v.lc05.mod == 13); values(lc05.mod)[ind] <- 1 # rcl 10 thru 13 as 1
ind <- which(v.lc05.mod == 14); values(lc05.mod)[ind] <- 6 # rcl 14 as 6
ind <- which(v.lc05.mod == 15 | v.lc05.mod == 16 | v.lc05.mod == 17 | v.lc05.mod == 18 | v.lc05.mod == 19 | v.lc05.mod == 128); values(lc05.mod)[ind] <- 0 # rcl 15 thru 19 as 0

writeRaster(lc05.mod, filename=paste(output.dir,"NA_LandCover_2005_PRISM_extent_AKAlbers_1km_modal_simplifyClasses_step1.tif", sep=""), overwrite=TRUE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# STEP 2

v.lc05.mod <- getValues(lc05.mod)

# lets get the values of the Coastal_vs_Spruce_bog layer that differentiates the different wetland classes
v.CoastSpruceBog <- getValues(coast_spruce_bog)

# now we index the values we want to use for this step of the reclass
ind <- which(v.lc05.mod == 6 & v.CoastSpruceBog == 2); values(lc05.mod)[ind] <- 3
ind <- which(v.lc05.mod == 6 & v.CoastSpruceBog != 2); values(lc05.mod)[ind] <- 0


rm(v.CoastSpruceBog)
rm(coast_spruce_bog)

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step2.tif", sep=""), overwrite=TRUE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# STEP 3

v.lc05.mod <- getValues(lc05.mod)

# Now we need to get the values of the MJJA gs_temp layer that differentiates the temperate shrublands between 
#  tundra and deciduous
v.gs_temp <- getValues(gs_temp)

# now lets find the values we need for this reclassification step
ind <- which(v.lc05.mod == 5 & v.gs_temp < 6.5) ; values(lc05.mod)[ind] <- 1
ind <- which(v.lc05.mod == 5 & v.gs_temp > 6.5) ; values(lc05.mod)[ind] <- 4

rm(gs_temp)

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step3.tif", sep=""), overwrite=TRUE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# STEP 4

v.lc05.mod <- getValues(lc05.mod)

#Now we bring the north_south map into the mix to differentiate between the white and black spruce from the spruce bog
v.north_south <- getValues(north_south)

# now I get the values that correspond to some conditions and change their values to the proper ALFRESCO class
ind <- which(v.lc05.mod == 3 & (v.gs_temp > 6.5 | v.north_south == 2)); values(lc05.mod)[ind] <- 5

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step4.tif", sep=""), overwrite=TRUE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# STEP 5

v.lc05.mod <- getValues(lc05.mod)

# Here we will reclass the spruce class to black or white spruce

ind <- which(v.lc05.mod == 2 & (v.gs_temp < 6.5 | v.north_south == 1)); values(lc05.mod)[ind] <- 3

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step5.tif", sep=""), overwrite=TRUE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# STEP 6 -- FINAL

v.lc05.mod <- getValues(lc05.mod)

# this is the final reclass step to bring the NALCMS map back to the ALFRESCO classification

ind <- which(v.lc05.mod == 5); values(lc05.mod)[ind] <- 2


# now I will write out the raster file

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_FINAL.tif", sep=""), overwrite=TRUE)
