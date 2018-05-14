[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/walkalytics)](https://cran.r-project.org/package=walkalytics)
[![Licence](https://img.shields.io/badge/licence-GPL--3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![cranlogs](https://cranlogs.r-pkg.org/badges/grand-total/walkalytics)](http://cran.rstudio.com/web/packages/walkalytics/index.html)

# Walkalytics
This R package is an interface to the [Walkalytics API](https://dev.walkalytics.com) that calculates the walking isochrone for a source location based on map data. To get an API key, you need to register at https://dev.walkalytics.com/signin. With the free starter account, you can make up to 100 calls a week to the API. More information (geographical availability of the service etc.) can be found [here](https://www.walkalytics.com). 

## Installation
The version 0.1.0 is on CRAN, and you can install it by:
```
install.packages("walkalytics")
```
For regularly updated version (latest: 0.1.0), install from GitHub:
```
install.packages("devtools")
devtools::install_github("zumbov2/walkalytics")
```
## Example 1: Albert's life in Aarau
Young Albert failed the entrance examination for ETH Zurich. The 16-year-old is now to move to Aarau to complete his secondary schooling. He doesn't know the town yet and is thinking about buying a bike for his everday life. Let's help Albert decide. He doesn't want to have to walk longer than 10 minutes. 

We define the blokes's most important points-of-interest and call the walkalytics API with the function `isochrome_pois()`. We take Albert's future address as the source location. The function `pois_walktimes()` processes the API response object in such a way that the estimated walking times (in seconds) between the source location and the points-of-interest are returned.
```
# Define Albert's points-of-interest 
places <- data.frame(id = c("School", "Railway Station", "Affenkasten (Pub)", "Zurlindeninsel (River Island)"),
                     x = c(895737, 896297, 895620, 895840),
                     y = c(6006558, 6006247, 6006171, 6007080))

# Call Walkalytics API and extract walking times to points-of-interest
isochrone_pois(x = 896552, y = 6006578, epsg = 3857, pois = places, key = key) %>% pois_walktimes()

# A tibble: 4 x 4
  id                            walktime      x       y
  <chr>                            <int>  <int>   <int>
1 Railway Station                    184 896297 6006247
2 School                             348 895737 6006558
3 Zurlindeninsel (River Island)      470 895840 6007080
4 Affenkasten (Pub)                  500 895620 6006171
```
Lucky Albert. He can save his money. Read more about Albert's life [here](https://en.wikipedia.org/wiki/Albert_Einstein#Early_life_and_education).

## Example 2: More details please
We can go one step further and extract high-resolution walking times. For this we use the function `isochrone_esri()`, which returns a response object that contains a base64-encoded gzipped Esri ASCII grid with walking times for every pixel. By using the function `esri_to_sgdf()`, we can convert the encoded Esri ASCII grid to an object of class `SpatialGridDataFrame` or we use `pixel_walktimes()` to directly extract walking times (in seconds) for every pixel with respect to the source location.
```
# Call Walkalytics API and convert response object to SpatialGridDataFrame
dt <- isochrone_esri(x = 896552, y = 6006578, epsg = 3857, key = key) %>% esri_to_sgdf()

# Call Walkalytics API and extract walking times for every pixel
dt2 <- isochrone_esri(x = 896552, y = 6006578, epsg = 3857, key = key) %>% pixel_walktimes()
```
`dt` can then be displayed graphically using `image()`
```
require(viridisLite)
image(dt, col = magma(10, direction = -1))
```
![example](https://github.com/zumbov2/walkalytics/blob/master/images/aarau1.png)

## Example 3: Public transportation stops for Switzerland
Beside the isochrone API Walkalytics also offers the possibility of querying [nearby public transportation stops](https://dev.walkalytics.com/docs/services/54213b7b352a401664d5c48a/operations/5551ed9350d8000f54f144a2?). The query works in the almost same way as the previous examples. 
```
# Call the Walkalytics pubtrans API and extract the walking times to the stations
pubtrans_ch_nearby(x = 8.528872, y = 47.382902, max_walktime = 10, key = key) %>% get_stops()  

# A tibble: 7 x 8
  name                          walktime station_category latitude longitude coordinates_type transport_category id     
  <chr>                            <dbl> <chr>            <chr>    <chr>     <chr>            <chr>              <chr>  
1 Zürich, Röntgenstrasse            1.30 3                8.529264 47.381932 WGS84            Bus                8591322
2 Zürich, Limmatplatz               3.40 2                8.531623 47.384600 WGS84            Bus_Tram           8591257
3 Zürich, Militär-/Langstrasse      4.40 2                8.527627 47.379600 WGS84            Bus                8591277
4 Zürich, Quellenstrasse            6.10 2                8.528753 47.386740 WGS84            Bus_Tram           8591306
5 Zürich, Kanonengasse              7.70 3                8.530306 47.378468 WGS84            Bus                8591219
6 Zürich, Museum für Gestaltung     8.50 2                8.534937 47.382121 WGS84            Bus_Tram           8591282
7 Zürich, Dammweg                   9.20 2                8.526392 47.388490 WGS84            Bus_Tram           8591110
```
## More
Walkalytics also offers the possibility to save isochrones with freely selectable break values as PNG images (`isochrone_png() %>% save_png()`). 

**Happy testing!**
