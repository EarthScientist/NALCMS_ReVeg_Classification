# This script will take as input the NALCMS 2005 Landcover map and 
# lets bring in the library used to perform this task
require(raster)
require(rgeos)
require(sp)
require(maptools)

# set an output directory
output.dir <- "/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/Outputs/"

# set the working dir
setwd(output.dir)

# these are the input layers that will be used to guide reclassification.  See metadata for descriptions
#    this is the NALCMS input map resampled to 1km resolution for ALFRESCO
lc05 <- raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/na_landcover_2005_1km_MASTER.tif")

lc05.mod <- getValues(lc05)
north_south <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/AKCanada_1km_NorthSouth_FlatWater_999_MASTER.tif"))
mask <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/mask_for_finalization_alfresco_VegMap.tif"))
gs_temp <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/AKCanada_gs_temp_mean_MJJAS_1961_1990_climatology_1km_bilinear_MASTER.tif"))
coast_spruce_bog <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/Coastal_vs_Woody_wetlands_MASTER.tif"))
treeline <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/CAVM_treeline_AKCanada_1km_commonExtent_MASTER.tif"))
NoPac <- getValues(raster("/workspace/UA/malindgren/projects/NALCMS_Veg_reClass/August2012_FINALversion/ALFRESCO_VegMap_Ancillary/ALFRESCO_NorthPacMaritime_forVegMap.tif"))

# this is the growing season temperature value threshold
gs_value = 6.5

# asks the gs_value if it contains a "." and changes it to a "_" for filenaming
if(grep(".",gs_value) == TRUE){
	gs <- sub(".", "_", gs_value, fixed=TRUE)
}else{
	gs <- gs_value
}


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
# 13 13 : 13
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


# this function will reclass the data
# inputs: r.vec = a vector representing a RasterLayer object; rclVals = a list of values, or value to reclasify, 
# OR a complex subset fuction using available objects (similar to that used in which()); 
# newVal = the new set value; complex = TRUE/FALSE to determine how to parse rclVals
reclass <- function(r.vec, rclVals, newVal, complex){
	if(complex == TRUE){
		r.vec[which(eval(parse(text=rclVals)))] <- newVal
	}else{
		for(i in rclVals){
			r.vec[which(r.vec == i)] <- newVal
		}
	}
	return(r.vec)
}

# STEP 1:
print("Step 1...")
# reclass the original NALCMS 2005 Landcover Map
# we do this via indexing the data we want using the builtin R {base} function which() and replace the values using the R {Raster}
# package function values() and assigning those values in the [index] the new value desired.
# begin by first collapsing down all classes from the original input that are not of interest to NOVEG
lc05.mod <- reclass(lc05.mod, c(15:19,128), 0, complex=FALSE)

# Reclass the needleleaf classes to SPRUCE
lc05.mod <- reclass(lc05.mod, c(1:2), 9, complex=FALSE)

# Reclass the deciduous and mixed as DECIDUOUS
lc05.mod <- reclass(lc05.mod, c(5:6), 3, complex=FALSE)

# Reclass Sub-polar or polar shrubland-lichen-moss as SHRUB TUNDRA
lc05.mod <- reclass(lc05.mod, 11, 4, complex=FALSE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 2
print(" Step 2...")
# take the class WETLAND and break it down into classes of SPRUCE BOG (placeholder class) or WETLAND TUNDRA

# which values of wetland map are not near the coast? This will create interior spruce bog
lc05.mod <- reclass(lc05.mod, "lc05.mod == 14 & coast_spruce_bog == 2", 9, complex=TRUE)

# coastal wetlands are now reclassed to a placeholder class
lc05.mod <- reclass(lc05.mod, "lc05.mod == 14 & coast_spruce_bog != 2", 20, complex=TRUE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# Step 3 
print("  STEP 3...")
# coastal wetland class to WETLAND TUNDRA or NO VEG based on the gs_temp (Average Growing Season Temperature) values

# take the placeholder class of 20 and reclass to Wetland Tundra
lc05.mod <- reclass(lc05.mod, "lc05.mod == 20 & gs_temp < gs_value & treeline == 1", 6, complex=TRUE)

# turn the remainder of wetland becomes No Veg
lc05.mod <- reclass(lc05.mod, 20, 0, complex=FALSE) # (treeline == 1| treeline == 0)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 4
# lets turn the placeholder class 8 (Temperate or sub-polar shrubland) into DECIDUOUS or SHRUB TUNDRA
print("   STEP 4...")

# SHRUB TUNDRA = all shrub pixels with gs_temp values less than 6.5 C
lc05.mod <- reclass(lc05.mod, "lc05.mod == 8 & gs_temp < gs_value ", 4, complex=TRUE) # & treeline != 1

# DECIDUOUS = all shrub pixels with gs_temp values greater than 6.5 C
lc05.mod <- reclass(lc05.mod, "lc05.mod == 8 & gs_temp >= gs_value", 3, complex=TRUE) # & treeline != 1

# if any DECIDUOUS pixel are still located above treeline make it SHRUB TUNDRA
# lc05.mod <- reclass(lc05.mod, "lc05.mod == 3 & treeline == 1", 4, complex=TRUE) # & treeline != 1

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 5
# here we are reclassing the gramminoid tundra/grassland into simply gramminoid tundra
# *this is at the suggestion of Amy Breen (abreen@alaska.edu)*  
print("    STEP 5...")

# # Reclass Sub-polar or polar grassland-lichen-moss as GRAMMINOID TUNDRA
lc05.mod <- reclass(lc05.mod, c(10,12), 5, complex=FALSE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 6
print("     STEP 6...")
# reclass the SPRUCE category to WHITE and BLACK based on <>6.5 degrees and North/South Slopes 

# Take the SPRUCE placeholder class and parse it out in to WHITE / BLACK.
# White Spruce = SPRUCE class & on a South-ish Facing slope
lc05.mod <- reclass(lc05.mod, "lc05.mod == 9 & north_south == 1", 2, complex=TRUE)
# ind <- which(v.lc05.mod == 9 & v.north_south == 1); values(lc05.mod)[ind] <- 2

# Black Spruce = SPRUCE class & Very North-ish facing
lc05.mod <- reclass(lc05.mod, "lc05.mod == 9 & north_south == 2", 1, complex=TRUE)

# due to there being a couple hundred pixels living on flat areas (mainly along the Yukon River) 
# I am reclassing them here as BLACK SPRUCE since they are on low lying areas
lc05.mod <- reclass(lc05.mod, 9, 1, complex=FALSE)

values(lc05) <- lc05.mod
writeRaster(lc05, filename="STEP6.tif", overwrite=T)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 7
print("      STEP 7...")

# THIS STEP FINDS AND REPLACES sPRUCE PIXELS THAT ARE ERRONEOUSLY CLASSIFIED IN THE ORIGINAL NALCMS 05 MAP
#  WITH THE MOST COMMON VALUES OF THE ADJACENT CELLS THAT ARE NOT SPRUCE OR NOVEG 

# bring the data values back into a map for the adjacency call
values(lc05) <- lc05.mod

focalNeighbors = 8

# which cells are suspect?
focal <- which((lc05.mod == 1 | lc05.mod == 2) & treeline == 1)

while(length(focal) > 0){
	focalLen.in <- length(focal)
	# Which are adjacent to these suspect cells?
	adj <- adjacent(lc05, focal, directions=focalNeighbors, pairs=TRUE, target=NULL, sorted=TRUE, include=FALSE, id=FALSE)

	adjVals <- cbind(adj,values(lc05)[adj[,2]])
	colnames(adjVals) <- c("focal", "adjacent", "in.value")

	# lets remove the values that we are not interested in changing the vals to
	adjVals[,3][which(adjVals[,3] == 0 | adjVals[,3] == 1 | adjVals[,3] == 2)] <- NA

	rowNums <- seq(1,length(adj[,2]),focalNeighbors)

	# get the values from the raster
	lc05.mod <- getValues(lc05)

	# which of the adjacent cells values are most common?
	for(i in 1:length(rowNums)){
		cur <- adjVals[(rowNums[i]:(rowNums[i]+(focalNeighbors-1))),]
		cur.freq <- table(cur[,3], useNA='no')
		if(length(cur.freq) > 0){ 
			newVal <- as.integer(names(cur.freq[which(cur.freq == max(cur.freq))]))
			if(length(newVal) > 1){	newVal <- newVal[1]}
			lc05.mod[focal[i]] <- newVal
		}
	}

	# ask which cell values are still incorrectly classified and do it again
	focal <- which((lc05.mod == 1 | lc05.mod == 2) & treeline == 1)
	focalLen.out <- length(focal)

	# if there are pixels that just cant be solved with the algorithm make them noVeg and print the count
	if(focalLen.in == focalLen.out){ 
		lc05.mod[focal] <- 0
		print(paste("Number of unsolvable pixels: ", length(focal), sep="")) 
		print(focal)
	}

	print(paste("suspect cell count: ", length(focal), sep=""))
	# prep the lc05 for the next round
	values(lc05) <- lc05.mod
}

# # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 8
#  this is where we define the North Pacific Maritime Region as its own map region that is independent of the others
print("       STEP 8...")

# get the values for the North Pacific Maritime region map that we will use to reclass that region in the new veg map
lc05.mod <- reclass(lc05.mod, "lc05.mod > 0 & NoPac == 1", 8, complex=TRUE)

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 9 
print("        STEP 9...")

#  turn the barren lichen moss /heath class into value 7
lc05.mod <- reclass(lc05.mod, 13, 7, complex=FALSE)

# # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# STEP 10
print("...Writing output tiff file...") 

# here we need to set all of the not "no_veg" values to 255 and NoVeg to 0 using the mask file above.  It is a 3 category mask
#  with classes for Out-of-bounds, saskatoon agricultural area, all other areas
# turn all of the out-of-bounds areas to value=255
lc05.mod <- reclass(lc05.mod, "mask == 1", 255, complex=TRUE)

# now lets mask it to the final mask removing the Saskatoon, Canada area (agriculture)
values(lc05) <- lc05.mod # bring the values back into the raster
writeRaster(lc05, filename=paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,".tif", sep=""), overwrite=T, options="COMPRESS=LZW")

# now we need to rewrite the file out as a byte not 32-bit float which is what ALFRESCO wants as a datatype for inputs
system(paste("gdal_translate -of GTiff -ot Byte ",paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,".tif", sep="")," ",paste(output.dir, "ALFRESCO_LandCover_2005_1km_gs",gs,"_byte.tif", sep=""),sep=""))

