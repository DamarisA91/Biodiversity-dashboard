# Biodiversity-dashboard

Link: https://damaris24.shinyapps.io/Biodiversity/

This is an interactive dashboard developed with Shiny that allows you to explore the biodiversity of plants and animals in Poland. Users can search for species by their common or scientific name, and the dashboard displays:

- Geographic distribution: An interactive map showing the location of species in Poland, with markers representing recorded observations.

- Sighting details: Clicking on the markers on the map takes you to a link containing all the information about each sighting.

- Temporal trends: An interactive graph showing the number of observations of the selected species over time, allowing you to analyze how observations vary.

- Images: If available, an image related to the selected species is displayed, directly from the database.

## Tools used:

- **R:** Main programming language.

- **Shiny:** Framework for building interactive web applications in R.

- **shinydashboard:** Library for creating interfaces with a dashboard layout.

- **leaflet:** Library for visualizing interactive maps.

- **plotly:** Library for creating interactive graphics, in this case a timeline.

- **sass:** CSS preprocessor to enhance the visual style of the dashboard.

- **rsconnect:** For deploying the application on platforms such as shinyapps.io.

## Databases
The database used is called "occurrence." It contains sighting records from around the world. Those from Poland were leaked. There is also a "multimedia" database, which contains photos of some of the sightings. From this last database, the "accessURI" column was taken, which contains the photo links. This resulted in the "data_with_multimedia.csv" database, from which duplicates were removed.

```
data_img<- Poland_data %>%
  left_join(multimedia %>% select(CoreId, accessURI), by =c("id"="CoreId"))
head(data_img)
write.csv(data_img,"data_with_multimedia.csv",row.names = FALSE)
```
## Dashboard structure:
- **UI** (User Interface): This is defined in the app.R file, in the ui object. The application's visual elements are configured here, such as the fields for entering information, the layout of graphics, and the general design.
- **Server:** This field corresponds to the operations performed with the information entered in the UI. It connects the UI to the data and is located in the server section of app.R. Filter updates, map displays, image loading, and the creation of interactive graphics are configured here.

## Vernacular name and scientific name
A list of options is displayed as the user types the species name, either the vernacular or scientific name. For this, the selectizaInput function was used, which also allows the "server = TRUE" option to be activated, allowing autocompletion and the list to be loaded from the server, optimizing the dashboard's performance. This tool was used in conjunction with updateSelectizeInput to update the options in the other available field. Once the user enters the species name, the record that matches the name entered is saved in "match_Sci" or "match_Ver" to obtain the corresponding other name.

- **ui:**
```
 selectizeInput("vernacular_name",
                   "Vernacular Name:",
                   choices = list(),
                   options = list(placeholder = "Enter a common name",
                                  server = TRUE)
```
- **server:**
```
updateSelectizeInput(session, "vernacular_name", 
                       choices = c("", database$vernacularName), 
                       server = TRUE)
 observeEvent(input$vernacular_name, {
    if (input$vernacular_name != "") {
      match_Sci <- database %>% 
        filter(vernacularName == input$vernacular_name) %>%
        pull(scientificName)
      
      updateSelectizeInput(session, "scientific_name", selected = match_Sci)
    } 
  })
```

## Display on the map
The renderLeaflet tool was used to generate the map. First, the species records entered by the user were filtered and the information was saved in the "map_data" vector. This dataset contains the coordinates needed to mark the points on the map (~longitudeDecimal and ~latitudeDecimal). 
Additionally, the "popup" option was used, which contains a link that opens a new page with details of the sighting when clicked.

![image](https://github.com/user-attachments/assets/f529d3f7-39e4-4d6c-af8d-2ea85de59c01)



## Timeline
The `ploty library was used to generate the timeline. Filtered data for the species entered was saved in "timeline_data." We used the "eventDate" column, which contains the sighting dates, to count the number of sightings by date and save the total as "observations." The graph was generated using this last piece of data and the sighting date.

```
 output$timeline <- renderPlotly({
    timeline_data <- filtered_data()
      
    # Observations
    timeline_summary <- timeline_data %>%
      group_by(eventDate) %>%
      summarise(observations = n())
    
    # Timeline chart
    plot_ly(timeline_summary, x = ~eventDate, y = ~observations, type = 'scatter', mode ='lines+markers',
            line = list(color = 'blue'), marker = list(size = 5)) %>%
      layout(title = "Observations over time",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Individual Count"),
             showlegend = FALSE)
```
## Images

Records from Poland with images were searched, and this column was added to the database. Images are available in some records, so a field was designed to display the image if it exists; otherwise, the message "Image not available" is displayed.

![image](https://github.com/user-attachments/assets/bdbb47f3-135f-465c-8ef1-110320e715f2)



