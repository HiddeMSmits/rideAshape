library(openrouteservice)
library(leaflet)
# library(sf)
# library(units)
library(plotKML)
# library(spdep)
library(shiny)
library(xml2)
source("/Users/Hidde/RideAshape/RideAshape/rideAshape/helpers.R")

apiKey <- #getAkey
t <- ors_api_key(apiKey)

gpxFile <- '/Users/Hidde/RideAshape/python/gpxFiles/shape.gpx'
f <- readGPX(gpxFile)
gpxCoord <- f$waypoints


# Define UI ----
ui <- fluidPage(
  titlePanel("Ride A shape"),
  
  sidebarLayout(
    sidebarPanel(
      textInput('geoCode',
                label = 'Input your starting adress',
                value =  "koningsweg 110, Utrecht"), 
      # helpText("input here the Lon en Lat coordinates from which you want to start the ride"),
      # 
      # textInput('lon',
      #           label = 'your longitudal coordiantes', 
      #           value =  5.148427),
      # textInput('lat',
      #           label = 'your latitude coordiantes',
      #           value = 52.084989),

      sliderInput("size", 
                  label = "Size of your dick:",
                  min = 0, max = 5, value = 1, step = 0.1),
      
      submitButton("Submit"),
      
      br(),
      
      #downloadLink("downloadData", "Download")
      
      
      ),
    mainPanel(
      leafletOutput("plot")
    )
    
  )
  )


# Define server logic ----
server <- function(input, output) {
  # gpxFile <- '/Users/Hidde/RideAshape/python/gpxFiles/shape.gpx'
  # f <- readGPX(gpxFile)
  # gpxCoord <- f$waypoints
  # userCoordinates = c('lon' = 7.148427,'lat' = 52.084989)
  
  output$plot <- renderLeaflet({
    message(input$geoCode)
    # userCoordinates <- geocodeAdddress(input$geocode)
    userCoordinates <- ors_geocode(query = input$geoCode)
    userCoordinates <- userCoordinates$features[[1L]]$geometry$coordinates
    coordinates <- createNewCoord(gpx = gpxCoord, userCoordinates = userCoordinates, sizeFactor = input$size)
    x <- ors_directions(coordinates, profile = 'cycling-regular', radiuses = rep(100000, nrow(coordinates)), format = c('geojson'))
    t <- leaflet() %>%
      addTiles() %>%
      addGeoJSON(x, fill=FALSE) %>%
      fitBBox(x$bbox)
    ####TODO:
    ####create a method that exports it as gpx
    
  })
  
  # output$downloadData <- downloadHandler(
  #   filename = function() {
  #     paste(input$geoCode, ".gpx", sep = "")
  #   },
  #   content = function(file) {
  #     # userCoordinates <- ors_geocode(query = input$geoCode)
  #     # userCoordinates <- userCoordinates$features[[1L]]$geometry$coordinates
  #     # coordinates <- createNewCoord(gpx = gpxCoord, userCoordinates = userCoordinates, sizeFactor = input$size)
  #     # x <- ors_directions(coordinates, profile = 'cycling-regular', radiuses = rep(100000, nrow(coordinates)), format = c('gpx'))
  #     write.csv(c('etest', 'test'), file)
  #   }
  # )
}


# Run the app ----
shinyApp(ui = ui, server = server)
