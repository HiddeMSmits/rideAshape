library(openrouteservice)
library(leaflet)
library(sf)
library(googlePolylines)
library(ggplot2)
library(ggforce)
library(units)
library(plotKML)
library(spdep)
library(xml2)
apiKey <- #getAkey
t <- ors_api_key(apiKey)

gpxFile <- '/Users/Hidde/RideADick/python/gpxFiles/penis.gpx'
f <- readGPX(gpxFile)
gpxCoord <- f$waypoints
# gpxCoord <- rbind(gpxCoord, gpxCoord[1,])
userCoordinates = c('lon' = 7.148427,'lat' = 52.084989)
#52.076450, 5.136051
#
createNewCoord <- function(gpx, userCoordinates, sizeFactor = 1){
  newCoord <- matrix(ncol = 2, nrow = nrow(gpx))
  for(i in 1:nrow(gpx)){
    if(i == 1){
      lon0 <- gpx[i,'lon']
      lat0 <- gpx[i,'lat']
    }
    lonI <- gpx[i,'lon']
    latI <- gpx[i,'lat']
  
    deltaLonCoord <- lonI - lon0
    deltaLatCoord <- latI - lat0
    
    newCoord[i,1] <- deltaLonCoord*sizeFactor + userCoordinates[1]
    newCoord[i,2] <- deltaLatCoord*sizeFactor + userCoordinates[2]
  }
  return(newCoord)
}

createNewCoord(gpx = gpxCoord, userCoordinates = userCoordinates, sizeFactor = 1)


createMultipleDicks <- function(gpx, userCoordinates, sizeFactor = 1){
  dickList <- list(rbind(createNewCoord(gpx, userCoordinates, sizeFactor = sizeFactor), userCoordinates[c(2,1)]))
  numberOfIterations <- 10
  divider <- 3
  
  # for(i in 1:(nrow(gpx)/2)){
  #   if(numberOfIterations%%i == 0){
  #     divider <- numberOfIterations/i
  #     numberOfIterations <- i
  #   }
  # }
  for(i in 1:numberOfIterations){ #make it a number difible by the GPX
    newOrder <- c((i*divider+1):nrow(gpx),c(1:(i*divider)))

    newGpx <- gpx[newOrder,]
    newGpx <- rbind(newGpx, userCoordinates[c(2,1)])
    print(newGpx)
    dickList[[i+1]] <- createNewCoord(newGpx, userCoordinates, sizeFactor = sizeFactor)
  }
  return(dickList)
}

createHeightProfile <- function(coord){
  x <- ors_directions(coord, profile = "cycling-regular", elevation = TRUE,
                      extra_info = "steepness", output = "sf", radiuses =  rep(2000, nrow(coord)))
  
  
  height <- st_geometry(x)[[1]][, 3]
  points <- st_cast(st_geometry(x), "POINT")
  n <- length(points)
  segments <- cumsum(st_distance(points[-n], points[-1], by_element = TRUE))
  
  steepness <- x$extras$steepness$values
  steepness <- rep(steepness[,3], steepness[,2]-steepness[,1])
  steepness <- factor(steepness, -5:5)
  
  palette = setNames(rev(RColorBrewer::brewer.pal(11, "RdYlBu")), levels(steepness))
  
  units(height) <- as_units("m")
  
  df <- data.frame(x1 = c(set_units(0, "m"), segments[-(n-1)]),
                   x2 = segments,
                   y1 = height[-n],
                   y2 = height[-1],
                   steepness)
  
  y_ran = range(height) * c(0.9, 1.1)
  
  n = n-1
  
  df2 = data.frame(x = c(df$x1, df$x2, df$x2, df$x1),
                   y = c(rep(y_ran[1], 2*n), df$y2, df$y1),
                   steepness,
                   id = 1:n)
  
  ggplot() + theme_bw() +
    geom_segment(data = df, aes(x1, y1, xend = x2, yend = y2), size = 1) +
    geom_polygon(data = df2, aes(x, y, group = id), fill = "white") +
    geom_polygon(data = df2, aes(x, y , group = id, fill = steepness)) +
    scale_fill_manual(values = alpha(palette, 0.8), drop = FALSE) +
    scale_x_unit(unit = "km", expand = c(0,0)) +
    scale_y_unit(expand = c(0,0), limits = y_ran) +
    labs(x = "Distance", y = "Height")
}

fitDickModel <- function(){}

rotateDick <- function(coords, degrees, userCoordinates){
  rad=-degrees*pi/180
  
  lonRot = userCoordinates[['lon']]
  latRot = userCoordinates[['lat']]
  lonCoord = coords[,'lon']
  latCoord= coords[,'lat']
  
  xRot = lonRot + cos(rad) * (lonCoord - lonRot) - sin(rad) * (latCoord - latRot)
  yRot = latRot + sin(rad) * (lonCoord - lonRot) + cos(rad) * (latCoord - latRot)
  rot=cbind('lon' = xRot, 'lat' = yRot)
  return(rot)
}

filterPoints <- function(){} #reduce number of points with a lower size factor 


createNewCoord(gpx = gpxCoord, userCoordinates = userCoordinates, sizeFactor = 1)



coordinates <-createNewCoord(gpx = gpxCoord, userCoordinates = userCoordinates, sizeFactor = 1)

#coordinates <- rotateDick(coordinates, 90, userCoordinates)


x <- ors_directions(coordinates, profile = 'cycling-regular', radiuses = rep(100000, nrow(coordinates)), format = 'gpx')
write_xml(x, '/Users/Hidde/Downloads/test.gpx')

t <- leaflet() %>%
  addTiles() %>%
  addGeoJSON(x, fill=FALSE) %>%
  fitBBox(x$bbox)

######trash zone
coordList <- createMultipleDicks(gpxCoord, userCoordinates, sizeFactor = 1)

createHeightProfile(coordinates)


x <- ors_directions(coordinatesRot, profile = 'cycling-regular', radiuses = rep(2000, nrow(coordinates)))
leaflet() %>%
  addTiles() %>%
  addGeoJSON(x, fill=FALSE) %>%
  fitBBox(x$bbox)



geocodeAdddress <- function(address, googleApi = "AIzaSyDjpblzWNNkJ5nEkNGaQ72JqTDDF4lmRBY") {
  require(RJSONIO)
  url <- "https://maps.google.com/maps/api/geocode/json?address="
  url <- URLencode(paste(url, address, "&sensor=false", "&key=", googleApi, sep = ""))
  x <- fromJSON(url, simplify = FALSE)
  if (x$status == "OK") {
    out <- c(x$results[[1]]$geometry$location$lng,
             x$results[[1]]$geometry$location$lat)
  } else {
    out <- NA
  }
  Sys.sleep(0.2)  # API only allows 5 requests per second
  out
}

location <- ors_geocode(query = "koningsweg 110, Utrecht", boundary.country = "NL")
userCoordinates <- location$features[[1L]]$geometry$coordinates
userCoordinates
