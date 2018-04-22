# Walkalytics
This R package is an interface to the [Walkalytics API](https://dev.walkalytics.com) that calculates the walking isochrone for a source location.
## Installation
Install the package with:
```
install.packages("devtools")
devtools::install_github("zumbov2/walkalytics")
```
## Example 1: Albert Einstein's life in Aarau
After failing the entrance examination for ETH Zurich, Albert Einstein attended the "Alte Kantonsschule Aarau" to complete
his secondary schooling (read more [here](https://en.wikipedia.org/wiki/Albert_Einstein#Early_life_and_education)). 

```
# Define points-of-interest 
places <- data.frame(id = c("School", "Railway Station", "Affenkasten Bar", "River Island Zurlinden"),
                     x = c(895737, 896297, 895620, 895840),
                     y = c(6006558, 6006247, 6006171, 6007080))

isochrone_pois(x = 896552, y = 6006578, pois = pupils, key = key) %>% pois_walktimes()

# A tibble: 4 x 4
  id                     walktime      x       y
  <chr>                     <int>  <int>   <int>
1 Railway Station             184 896297 6006247
2 School                      348 895737 6006558
3 River Island Zurlinden      470 895840 6007080
4 Affenkasten Bar             500 895620 6006171
```

