#Create a map and table of median gross rents in the 5 boroughs by tract
#Include the city boundary of nyc
#Use mapshot to save mapview object as an html file

options(tigris_use_cache = TRUE)

# install.packages(c("tidycensus", "tidyverse"))
# install.packages(c("mapview", "survey", "srvyr", "ggplot2"))
# install.packages("webshot")
# install.packages("devtools") 
devtools::install_github("BlakeRMills/MoMAColors")
library(MoMAColors)
library(tidycensus)
library(ggplot2)
library(scales)
library(stringr)
library(mapview)
library(tigris) #this pulls in geometries
library(tidyverse)
library(sf)
library(webshot)
library(writexl)

#load and view census variables
vars <- load_variables(2022, "acs5")
#view(vars)
#define the boroughs to pull in census data by fips code
fiveboroughs <- c("Kings", "Queens", "Bronx", "Richmond", "New York")

#Downlaod borough boundaries from NYCDCP Rest API and convert to boundary line
url <- "https://services5.arcgis.com/GfwWNkhOj9bNBqoJ/arcgis/rest/services/NYC_Borough_Boundary/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
temp_file <- tempfile(fileext = ".geojson")
download.file(url, temp_file)
boundaries <- st_read(temp_file)
boundaryline <- st_cast(boundaries, "MULTILINESTRING") %>%
  st_cast("LINESTRING")

#Get ACS Data on median gross rent for the five boroughs
#Median gross rent is also available by number of bedrooms, something to consider for future analysis!

NYGROSSRENT <- get_acs(
  geography = "tract", 
  variables = c(MedianGrossRent = "B25031_001"), 
  state = "NY", 
  county = fiveboroughs,
  year = 2022,
  geometry = TRUE
)

NYGROSSRENT2 <- NYGROSSRENT %>%
  rename (Median_Gross_Rent = "estimate") %>%
  select(-geometry, -variable) %>%
  erase_water()

#Turn acs data into an excel spreadsheet for reference
NYGROSSRENTXLS <- NYGROSSRENT2
write_xlsx(
  NYGROSSRENTXLS,
  "NYGROSSRENT.xlsx",
  col_names = TRUE,
  format_headers = TRUE)

print(NYGROSSRENT2)

# Map median gross rent and borough boundary lines in the R viewer panel and the momacolors package color palette 
m1 <- mapview(NYGROSSRENT2, 
        zcol = "Median_Gross_Rent", 
        col.regions = moma.colors("Alkalay2"),
        alpha.regions=.8,
        lwd=.3, 
        layer.name = "Median Gross Rent",
        label= "Median_Gross_Rent")

m2 <- mapview(boundaryline, legend=FALSE, alpha.regions=0, lwd=2, label=FALSE, color="black")

RentMap <- m1+m2
RentMap

#Looks good? Save as an html file instead!
m= RentMap
mapshot(m, url = paste0(getwd(), "/map.html"))

