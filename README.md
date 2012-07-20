# Overview

This readme file is to describe the creation of the input maps used in the reclassification of the NALCMS 2005 Land Cover data set into classes suitable for use in the ALFRESCO fire model.

The original code and logic was written by Anna Springsteen using the Python language and the ArcGIS 10 commercial GIS software.  The rewrite has been done in the R statistical language using the package::raster from CRAN using the same reclassification logic developed by Anna Springsteen.

The major difference between the old reclassification and the new one is that the Area of Interest (AOI) has been expanded to include the SNAP downscaled data extent.  This includes Alaska, Yukon, British Columbia, Alberta, Saskatchewan, and Manitoba.  This will allow for fire modeling using the ALFRESCO model into the regions of the Boreal Forest East of Alaska.  

This file was created by Michael Lindgren (malindgren@alaska.edu) Spatial Analyst at SNAP.

## Input Maps

### North American Land Cover 2005

Center for Environmental Cooperation (http://CEC.org): covers all of North American Continent with a seamless land cover classification scheme

### North South Map

Derived from Aspect calculation (in degrees) of the PRISM 2km Digital Elevation Model (DEM), reclassed to 3 classes: North, South, Water.

The classification scheme used to reclassify the aspect map is as follows: south = greater than 90 degrees and less than 301 degrees (value=1). north is all else (value=2), water (value=999)

It's important to note here that when calculating aspect there are situations that arise where there is no slope and therefore no aspect.  In these situations the flat areas were reclassified as NORTH (2) unless they are a body of water.  Water bodies were extracted from the NALCMS Landcover Data and those areas that were both flat and waterbodies were reclassed as water (999).  Therefore we are able to reclassify the large water bodies and give a class to the flat areas that are not waterbodies...

### Coastal Wetland vs Spruce Bog Map

This layer was derived through combining features of the Nowacki (Nowacki, Gregory; Spencer, Page; Fleming, Michael; Brock, Terry; and Jorgenson, Torre. Ecoregions of Alaska: 2001.), and the Ecozones and Ecoregions of Canada (A National Ecological Framework for Canada: Attribute Data. Marshall, I.B., Schut, P.H., and Ballard, M. 1999. Agriculture and Agri-Food Canada, Research Branch, Centre for Land and Biological Resources Research, and Environment Canada, State of the Environment Directorate, Ecozone Analysis Branch, Ottawa/Hull.).

Nowacki (2001) chosen features include 2 classes of the "LEVEL_2" ecoregions in that dataset where Intermontane Boreal (a.k.a. Alaska's Interior) was classed as 2 and all other ecoregions (Basically all coastal) was classed as 1.  This gives a differentiation between the wetlands classes that fall into each of these two reclassified regions, allowing for the creation of an Spruce Bog class from the "wetland" class in the NALCMS 2005 Land Cover Classification.  With the expansion in the AOI in this version of the reclassification to cover portions of West Canada it was important to differentiate the coastal and inland boreal ecozones/regions in order to mimick what was done on the Alaska side.  To do this to the Canada data:

1. In the areas around south Sasketchewan there are large areas of prairie, which also coincides with the bread basket of Canada since their green revolution.  Since this area is not boreal forest and is a heavily human-will dictated environment (since it is mainly farms) it is not a good candidate to include in this classification.  (Note: We removed the Canada Ecozone "Prairie" and Canada Ecoregion "Interlake Plain" & "Boreal Transition"; both of which exist to the North of the excluded "Prairie" Canda Ecozone.  This was determined to be removed by examining the input NALCMS Land Cover map and seeing that there were little to no trees in these areas.)
2. To extent the "coastal" region beyond the southern extent of southeast Alaska, it was determined that the Canada Ecozone "Pacific Maritime" should be classed as coast to differentiate between coastal and non-coastal wetlands. Therefore this was added to the non-"Intermontane Boreal" classes from the Nowacki AK ecoregions map.
3. The southern-most extent of the new coastal vs spruce bog layer is the international border between Canada and the U.S.
4. The areas classified as "Boreal" on the Canada side include Ecozones of: Montane Cordillera, Boreal Cordillera, Taiga Cordillera, Taiga Plain, Boreal Plain, Taiga Shield, Boreal Shield, Hudson Plain, Mixed Wood Plain, Atlantique Maritime, Hudson Plain, Arctic Cordillera.
5. Included Areas to the North of the new "boreal" class on the Canada side include the Canada Ecozones of: Southern Arctic AND the Canada Ecoregions of: Wager Bay Plateau, Boothia Peninsula Plateau, Meta Incognita Peninsula, Central Ungava Peninsula, Foxe Basin Plain, Melville Peninsula Plateau, Baffin Island Uplands. *** Areas North of these locations are not considered for this layer.  

### gs_temp

This layer was created by simply taking the tas 1961-1990 climatology from PRISM and averaging together the Months of May, June, July, August, September to create a reproduction of a dataset used in the previous iteration of this reclassification that people were unsure where it came from or what it represented.  Director of SNAP Scott Rupp informed me to use the average of these months from the 30-year climatology to recreate it for use in this new iteration of the reclassification.

### mask file

This layer was created by clipping the extent of the PRISM-based gs_temp to the Canada and Alaska Extents, removing the small amount of overlap in that data with the Lower-48.  This mask was then used to make sure there was perfect agreement between the other auxilary layers used to reclassify the NALCMS.  

