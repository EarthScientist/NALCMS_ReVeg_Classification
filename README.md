NALCMS_ReVeg_Classification
===========================

Writing a reclassification program using the {RASTER} package in R language

METADATA:

This land cover dataset represents a highly modified output originating from the North American Land Change Monitoring System (NALCMS) 2005 dataset.  This model input dataset was created solely for use in very large landscape scale modeling studies and is not representative of any ground based observations.

http://www.cec.org/Page.asp?PageID=924&SiteNodeID=565

Legend:
0 - NoVeg
1 - Black Spruce
2 - White Spruce
3 - Deciduous
4 - Shrub Tundra
5 - Graminoid  Tundra
6 - Wetland Tundra
7 - Barren lichen-moss
8 - Temperate Rainforest


Methods of production:

Reclassification of the input NALCMS Land cover layer involved creation of several input layers used to help decompose some of the broad classifications into more specific sub-classes.

These derived layers are:
north_south - this layer is derived from Aspect calculation (in degrees) of the PRISM 2km Digital Elevation Model (DEM). It constitutes a reclassification into 3 classes: North, South, Water.  The classification scheme used to reclassify the aspect map is as follows: south = greater than 90 degrees and less than 301 degrees (value=1). north is all else (value=2), water (value=999). It is important to note here that when calculating aspect there are situations that arise where there is no slope and therefore no aspect.  In these situations the flat areas were reclassified as NORTH (2) unless they are a body of water.  Water bodies were extracted from the NALCMS Landcover Data and those areas that were both flat and waterbodies were reclassed as water (999).  

growing_season_temperature - This layer  constitutes the average of the months of May, June, July, August, from the 1961-1990 PRISM climatology, resampled to 1km using a bilinear interpolation.

coastal_interior - this layer was derived through combining features of the Nowacki Ecoregions in Alaska (Nowacki, Gregory; Spencer, Page; Fleming, Michael; Brock, Terry; and Jorgenson, Torre. Ecoregions of Alaska: 2001.), and the Ecozones and Ecoregions of Canada (A National Ecological Framework for Canada: Attribute Data. Marshall, I.B., Schut, P.H., and Ballard, M. 1999. Agriculture and Agri-Food Canada, Research Branch, Centre for Land and Biological Resources Research, and Environment Canada, State of the Environment Directorate, Ecozone Analysis Branch, Ottawa/Hull.).

Nowacki (2001) chosen features include 2 classes of the "LEVEL_2" ecoregions in that dataset where Intermontane Boreal (a.k.a. Alaska's Interior) was classed as 2 and all other ecoregions (all coastal) was classed as 1.  This gives a differentiation between the wetlands classes that fall into each of these two reclassified regions, allowing for the creation of an Spruce Bog class from the "wetland" class in the NALCMS 2005 Land Cover Classification.  

With the area of interest including sites in Western Canada, it was important to differentiate the coastal and inland boreal ecozones/regions in order to mimick what was done on the Alaska side.  To do this the Canada Ecozone/ecoregion data involved the following:

i. In the areas around south Sasketchewan there are large areas of prairie, which also coincides with the bread basket of Canada since their green revolution.  Since this area is not boreal forest and is a heavily human-will dictated environment (since it is mainly farms) it is not a good candidate to include in this classification.  **removed the Canada Ecozone "Prairie" and Canada Ecoregion "Interlake Plain" & "Boreal Transition"; both of which exist to the North of the excluded "Prairie" Canda Ecozone.  This was determined to be removed by examining the input NALCMS Land Cover map and inspecting visually that there were little to no trees in these areas.

ii. To extent the "coastal" region beyond the southern extent of southeast Alaska, it was determined that the Canada Ecozone "Pacific Maritime" should be classed as coast to differentiate between coastal and non-coastal wetlands. Therefore this was added to the non-"Intermontane Boreal" classes from the Nowacki AK ecoregions map.

iii. The southern-most extent of the new coastal vs spruce bog layer is the international border between Canada and the U.S.

iv. The areas classified as "Boreal" on the Canada side include Ecozones of: Montane Cordillera, Boreal Cordillera, Taiga Cordillera, Taiga Plain, Boreal Plain, Taiga Shield, Boreal Shield, Hudson Plain, Mixed Wood Plain, Atlantique Maritime, Hudson Plain, Arctic Cordillera.

v. Included Areas to the North of the new "boreal" class on the Canada side include the Canada Ecozones of: Southern Arctic AND the Canada Ecoregions of: Wager Bay Plateau, Boothia Peninsula Plateau, Meta Incognita Peninsula, Central Ungava Peninsula, Foxe Basin Plain, Melville Peninsula Plateau, Baffin Island Uplands. *** Areas North of these locations are not considered for this layer.  

treeline - This layer was created by rasterizing the Circumpolar Arctic Vegetation Map (CAVM, http://www.geobotany.uaf.edu/cavm/) and defining the treeline using the extent of this data.  The result is a boolean map where 0=no trees and 1=trees.

North Pacific Maritime -  This layer was created by rasterizing the Alaska biomes data (Nowacki) for the Northern Pacific Rainforest region and creating a layer which reclassifies this region as the North Pacific Maritime Region.


The steps of reclassification of the NALCMS Land Cover Map are:

1. Once the area of interest (AOI) is determined the input map was clipped to that extent.  The resulting classes in the  
AOI are:

0 = out of bounds
1 = Temperate or sub-polar needleleaf forest
2 = Sub-polar taiga needleleaf forest
5 = Temperate or sub-polar broadleaf deciduous
6 = Mixed Forest
8 = Temperate or sub-polar shrubland
10 = Temperate or sub-polar grassland
11 = Sub-polar or polar shrubland-lichen-moss
12 = Sub-polar or polar grassland-lichen-moss 
13 = Sub-polar or polar barren-lichen-moss
14 = Wetland
15 = Cropland
16 = Barren Lands
17 = Urban and Built-up
18 = Water
19 = Snow and Ice

These classes were collapsed to:

classes 15,16,17,18,19 were reclassed as no vegetation.

classes 1,2 were reclassed as a spruce class.

classes 5,6 were reclassed as deciduous

class 11 was reclassed as shrub tundra

The remainder of the classes were left as is for further classification in later steps

2. The wetland class was reclassified using the coastal_interior layer into coastal wetlands and interior spruce bogs (spruce class).

3. The newly derived coastal wetland layer was further reclassified into wetland tundra or no veg by using the growing_season_temperature layer.  Any coastal wetland pixel with a growing season temperature <6.5 C is classified as wetland tundra and the remainder of the data are classified as no veg.

4.  Next the class 8 (Temperate or sub-polar shrubland) is reclassified into deciduous or shrub tundra using the growing_season_temperature layer.  All pixels with a growing season temperature <6.5 C is classified as shrub tundra and the remainder are classified as deciduous.

5. The classes 12 "Sub-polar or polar grassland-lichen-moss" and 10 "Temperate or sub-polar grassland" are reclassified into graminoid tundra or grassland based on the growing_season_temperature layer.  Where pixels of class 10 or 12 with growing season temperature values of <6.5 are classified as graminoid tundra and the values >6.5 are classified as grassland.

6. Then we reclassify the spruce class we created in step 1 into black or white spruce using the north_south layer.  If a spruce pixel is north facing it is classified as black spruce, and if the pixel is south facing then it is classified as white spruce.

7. Due to some deficiencies in the NALCMS map there are spruce trees on the North Slope of Alaska, which is known to not be factual.  Instead of simply reclassifying these data into a single class, we found that it would be better to run a focal analysis on the data that would convert the suspect cells into most common class in its surrounding 16 neighbors.  This allowed for a more realistic reclassification of these suspect pixels with the land cover classes that are in the surrounding area.  

8. Using the north_pacific_maritime layer the pixels that are within that extent are reclassified as coastal rainforest in the output map.

9. Class 13 (Sub-polar or polar barren-lichen-moss) was reclassified into class 7 "Barren lichen-moss"

