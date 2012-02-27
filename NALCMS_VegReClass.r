# lets bring in the library used to perform this task
require(raster)

# set the working dir
setwd("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/working_folder/")

# set an output directory
output.dir <- "/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/outputs/run_1/"


# the input NALCMS 2005 Land cover raster
lc05 <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/FINAL/na_landcover_2005_ebm_1km_MASTER.tif")
north_south <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/FINAL/AKCanada_1km_NorthSouth_FlatWater_999.tif")
mask <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/FINAL/auxilary/AKCanada_Extent_PRISM_mask.tif")
gs_temp <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/FINAL/extract_by_mask_AKCanada_Extent/AKCanada_gs_temp_mean_MJJA_1961_1990_climatology_1km_bilinear_ebm.tif")
coast_spruce_bog <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/FINAL/extract_by_mask_AKCanada_Extent/Coastal_vs_Woody_wetlands_ebm.tif")

# create a vector of values from the NALCMS 2005 Landcover Map
v.lc05 <- getValues(lc05)

#this next line just duplicates the input lc map and we will change the values in this map and write it to a TIFF
lc05.mod <- lc05

#reclassify the original NALCMS 2005 Landcover Map
# we do this via indexing the data we want using the builtin R {base} function which() and replace the values using the R {Raster}
# package function values() and assigning those values in the [index] the new value desired.
ind <- which(v.lc05 == 1 | v.lc05 == 2); values(lc05.mod)[ind] <- 2 # rcl 1 and 2 as 2
ind <- which(v.lc05 == 5 | v.lc05 == 6); values(lc05.mod)[ind] <- 4 # rcl 5 and 6 as 4
ind <- which(v.lc05 == 8); values(lc05.mod)[ind] <- 5 # rcl 8 as 5
ind <- which(v.lc05 == 10 | v.lc05 == 11 | v.lc05 == 12 | v.lc05 == 13); values(lc05.mod)[ind] <- 1 # rcl 10 thru 13 as 1
ind <- which(v.lc05 == 14); values(lc05.mod)[ind] <- 6 # rcl 14 as 6
ind <- which(v.lc05 == 15 | v.lc05 == 16 | v.lc05 == 17 | v.lc05 == 18 | v.lc05 == 19); values(lc05.mod)[ind] <- 0 # rcl 15 thru 19 as 0

writeRaster(lc05.mod, filename=paste(output.dir,"NA_LandCover_2005_PRISM_extent_AKAlbers_1km_modal_simplifyClasses_step1.tif", sep=""), overwrite=TRUE)

# remove some no longer needed vars
rm(lc05)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# lets get the values of the Coastal_vs_Spruce_bog layer that differentiates the different wetland classes
v.CoastSpruceBog <- getValues(coast_spruce_bog)

# now we index the values we want to use for this step of the reclass
ind <- which(v.lc05.mod == 6 & v.CoastSpruceBog == 2); values(lc05.mod)[ind] <- 3
ind <- which(v.lc05.mod == 6 & v.CoastSpruceBog != 2); values(lc05.mod)[ind] <- 0

rm(v.CoastSpruceBog)
rm(coast_spruce_bog)

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step2.tif"))

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# Now we need to get the values of the MJJA gs_temp layer that differentiates the temperate shrublands between 
#  tundra and deciduous
v.gs_temp <- getValues(gs_temp)

# now lets find the values we need for this reclassification step
ind <- which(v.lc05.mod == 5 & v.gs_temp < 6.5) ; values(lc05.mod)[ind] <- 1
ind <- which(v.lc05.mod == 5 & v.gs_temp >= 6.5) ; values(lc05.mod)[ind] <- 4

rm(gs_temp)

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step3.tif"))

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
#Now we bring the north_south map into the mix to differentiate between the white and black spruce from the spruce bog
v.north_south <- getValues(north_south)

# now I get the values that correspond to some conditions and change their values to the proper ALFRESCO class
ind <- which(v.lc05.mod == 3 & v.gs_temp < 6.5 | v.north_south == 1); values(lc05.mod)[ind] <- 3
ind <- which(v.lc05.mod == 3 & v.gs_temp > 6.5 | v.north_south != 1); values(lc05.mod)[ind] <- 5

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step4.tif"))

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# Here we will reclass the spruce class to black or white spruce

ind <- which(v.lc05.mod == 2 & v.gs_temp < 6.5 | v.north_south == 2); values(lc05.mod)[ind] <- 3
ind <- which(v.lc05.mod == 2 & v.gs_temp > 6.5 | v.north_south != 2); values(lc05.mod)[ind] <- 2

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_Step5.tif"))

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# this is the final reclass step to bring the NALCMS map back to the ALFRESCO classification

ind <- which(v.lc05.mod == 5); values(lc05.mod)[ind] <- 2


# now I will write out the raster file

writeRaster(lc05.mod, filename=paste(output.dir, "NA_LandCover_2005_PRISM_extent_AKAlbers_1km_ALFRESCO_FINAL.tif"))

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --