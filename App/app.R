#Biodiversity


library(shiny)
library(shinydashboard)
library(leaflet)
library(dplyr)
library(plotly)
library(sass)
library(rsconnect)

#Shinyapps.io
rsconnect::setAccountInfo(name='damaris24', 
                          token='88CA442371D1C6D8A3F032FDE2533210', 
                          secret='BoYE7EdkMH1y5g62ilVCc3/Bqsx9n0gAa13pnNuS')

#database
database <- read.csv("data_with_multimedia.csv")

ui <- dashboardPage(
  dashboardHeader(title = "Biodiversity"),
  dashboardSidebar(
    selectizeInput("vernacular_name",
                   label = tags$span("Vernacular Name", icon("leaf")),
                   choices = list(),
                   options = list(placeholder = "Enter a common name",
                                  server = TRUE)
    ),
    selectizeInput("scientific_name", 
                   label = tags$span("Scientific Name", icon("flask")), 
                   choices = list(),
                   options = list(placeholder = "Enter a scientific name",
                                  server = TRUE)
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ),
    fluidRow(
      column(6,
             box(leafletOutput("map", height = "300px" ), width = NULL, height = "400px", 
                 title = tags$span("Map", icon("map-marker-alt"))  
             )
      ),
      column(6,
             box(uiOutput("image", fill = TRUE ), width = NULL, height = "400px",
                 title = tags$span("Image", icon("image"))  
             )
      )
    ),
    
    fluidRow(
      column(12,
             box(plotlyOutput("timeline", height = "250px" ), width = NULL, height = "350px",
                 title = tags$span("Timeline", icon("chart-line"))  
             )
      )
    )
  )
)

server <- function(input, output, session) {
  
  updateSelectizeInput(session, "vernacular_name", 
                       choices = c("", database$vernacularName), 
                       server = TRUE)
  updateSelectizeInput(session, "scientific_name", 
                       choices = c("", database$scientificName), 
                       server = TRUE)
  
  observeEvent(input$vernacular_name, {
    if (input$vernacular_name != "") {
      match_Sci <- database %>% 
        filter(vernacularName == input$vernacular_name) %>%
        pull(scientificName)
      
      updateSelectizeInput(session, "scientific_name", selected = match_Sci)
    } 
  })
  
  observeEvent(input$scientific_name, {
    if (input$scientific_name != "") {
      match_Ver <- database %>% 
        filter(scientificName == input$scientific_name) %>%
        pull(vernacularName)
      
      updateSelectizeInput(session, "vernacular_name", selected = match_Ver)
    }
  })
  
  # Filtered data
  filtered_data <- reactive({
    if (input$vernacular_name != "") {
      database %>% filter(vernacularName == input$vernacular_name)
    } else if (input$scientific_name != "") {
      database %>% filter(scientificName == input$scientific_name)
    } else {
      return(NULL)
    }
  })
  
  # Map
  output$map <- renderLeaflet({
    map_data <- filtered_data()
    
    if (is.null(map_data) || nrow(map_data) == 0) {
      return(leaflet() %>% addTiles())
    }
    
    leaflet(map_data) %>%
      addTiles() %>%
      addCircleMarkers(~longitudeDecimal, ~latitudeDecimal,
                       popup = ~paste("<a href='", occurrenceID, 
                                      "' target='_blank'>Details</a>"),
                       color = "blue"
      )
  })
  
  # Timeline data
  output$timeline <- renderPlotly({
    timeline_data <- filtered_data()
    
    if (is.null(timeline_data) || nrow(timeline_data) == 0) {
      return(NULL)}
    
    # Observations
    timeline_summary <- timeline_data %>%
      group_by(eventDate) %>%
      summarise(observations = n())
    
    # Timeline chart
    plot_ly(timeline_summary, x = ~eventDate, y = ~observations, type = 'scatter', mode ='lines+markers',
            line = list(color = 'blue'), marker = list(size = 5)) %>%
      layout(title = "Sightings over time",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Individual Count"),
             showlegend = FALSE)
  })
  
  # Image
  output$image <- renderUI({
    imagen_data <- filtered_data()
    
    if (is.null(imagen_data) || nrow(imagen_data) == 0) {
      return(NULL)
    }
    
    accessURI <- imagen_data$accessURI[1]
    
    # Check if an image is available
    if (is.na(accessURI) || accessURI == "") {
      return(tags$p("Image not available"))
    } else {
      return(
        tags$div(
          class = "text-center",
          tags$img(src = accessURI, height = "300px", alt = "Image not available")
        )
      )
    }
  })
}

shinyApp(ui, server)