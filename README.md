# Walkalytics
This R package is an interface to the [Walkalytics API](https://dev.walkalytics.com) that calculates the walking isochrone for a source location based on map data. To get an API key, you need to register at https://dev.walkalytics.com/signin. With the free starter account, you can make up to 100 calls a week to the API. More information (geographical availability of the service etc.) can be found [here](https://www.walkalytics.com). 

## Installation
Install the package with:
```
install.packages("devtools")
devtools::install_github("zumbov2/walkalytics")
```
## Example 1: Albert Einstein's life in Aarau
After failing the entrance examination for ETH Zurich, Albert Einstein attended the "Alte Kantonsschule Aarau" to complete his secondary schooling (read more [here](https://en.wikipedia.org/wiki/Albert_Einstein#Early_life_and_education)). Some say that Einstein was sent to Aarau only because there was much less distraction in the provincial nest than in the city of Zurich. Let's look for some evidence.

We define some points-of-interest and call the walkalytics API with respect to a source location (Einstein's former address). The function `pois_walktimes()` processes the API response object in such a way that the estimated walking times between the source location and the points-of-interest are returned.
```
# Define points-of-interest 
places <- data.frame(id = c("School", "Railway Station", "Affenkasten Bar", "River Island Zurlinden"),
                     x = c(895737, 896297, 895620, 895840),
                     y = c(6006558, 6006247, 6006171, 6007080))

# Call Walkalytics API and extract walking times to points-of-interest
isochrone_pois(x = 896552, y = 6006578, epsg = 3857, pois = pupils, key = key) %>% pois_walktimes()

# A tibble: 4 x 4
  id                     walktime      x       y
  <chr>                     <int>  <int>   <int>
1 Railway Station             184 896297 6006247
2 School                      348 895737 6006558
3 River Island Zurlinden      470 895840 6007080
4 Affenkasten Bar             500 895620 6006171
```
They had a point...and the rest is history. ;-)

## Example 2: More details please
We can go one step further and extract high-resolution walking times. For this we use the functions `isochrone_esri()`, which returns a response object that contains a base64-encoded gzipped Esri ASCII grid with walking times for every pixel. By using the function `esri_to_sgdf()`, we can convert the encoded Esri ASCII grid to an object of class SpatialPixelsDataFrame or we use `pixel_walktimes()` to directly extract walking times (in seconds) for every pixel with respect to the source location.
```
# Call Walkalytics API and convert response object to SpatialPixelsDataFrame
dt <- isochrone_esri(x = 896552, y = 6006578, epsg = 3857, key = key) %>% esri_to_sgdf()

# Call Walkalytics API and extract walking times for every pixel
dt2 <- isochrone_esri(x = 896552, y = 6006578, epsg = 3857, key = key) %>% pixel_walktimes()
```

## Example 3: Public transportation stops for Switzerland
Beside the isochrone API Walkalytics also offers the possibility of querying nearby public transport stops. The query works in the almost same way as the previous examples. 
```
# Call the Walkalytics pubtrans API and extract the walking times to the stations
pubtrans_ch_nearby(x = 8.0526331, y = 47.3933375, max_walktime = 10, key = key) %>% get_stops()  

# A tibble: 13 x 8
   name                  walktime station_category latitude longitude coordinates_type transport_category id     
   <chr>                    <dbl> <chr>            <chr>    <chr>     <chr>            <chr>              <chr>  
 1 Aarau, Bahnhof            1.90 2                8.051008 47.391860 WGS84            Bus                8502996
 2 Aarau, Gais               5.20 3                8.056074 47.391276 WGS84            Bus                8590142
 3 Aarau, Kasinopark         5.20 99               8.046865 47.392143 WGS84            Bus                8594929
 4 Aarau, Berufsschule       6.00 4                8.055041 47.397029 WGS84            Bus                8590134
 5 Aarau, Kunsthaus          6.30 3                8.046240 47.390788 WGS84            Bus                8578642
 6 Aarau, Holzmarkt          6.80 2                8.045527 47.392123 WGS84            Bus                8578643
 7 Aarau, Obere Vorstadt     6.90 4                8.047667 47.389324 WGS84            Bus                8590152
 8 Aarau, Friedhof           8.30 5                8.046799 47.388636 WGS84            Bus                8590141
 9 Aarau, Rathaus            9.00 2                8.043019 47.394025 WGS84            Bus                8578644
10 Aarau, Buchenhof          9.10 5                8.050706 47.387545 WGS84            Bus                8590136
11 Aarau, Herzogplatz        9.50 5                8.055592 47.387366 WGS84            Bus                8590146
12 Aarau, Tellizentrum       9.90 4                8.059063 47.397772 WGS84            Bus                8590156
13 Aarau, Kettenbrücke       9.90 99               8.042286 47.394847 WGS84            Bus                8594930
```

## More
Walkalytics also offers the possibility to save isochrones as PNG images (`isochrone_png() %>% save_png()`). Happy testing.
