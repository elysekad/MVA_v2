library(shiny)
library(dplyr)
library(tigris)
library(leaflet)
library(rgeos)
library(readxl)
library(sp)

#importing data 
MVA_DATA <- read_excel("MVA_2017_2018.xlsx", sheet = "MVA_DATA")

#cleaning and organizing MVA data, creating month and year columns from timeval column, creating measure column with proper % and rounding
MVA_DATA <- MVA_DATA %>%
  mutate(month=substring(timeval, 5, 6),
    year=substring(timeval, 1, 4),
    measure=round(dqval*100, 1)) %>%
  select(-site_id, -usegrpno, -HL7_Segment, -pri, -dqvarno)

MVA_DATA[MVA_DATA$dqvar=='days_at_80', 'measure'] <- round(MVA_DATA[MVA_DATA$dqvar=='days_at_80', 'dqval'], 1)

#categorizing usegrp column
MVA_DATA[MVA_DATA$usegrp!='Timeliness', 'usegrp'] <- 'Completeness'

shinyServer(function(input, output){
  #rendering ui input objects 
  #creating options for % completeness variables dropdown
  output$complete_options <- renderUI({ 
    complete <- unique(MVA_DATA[MVA_DATA$usegrp!='Timeliness', 'dqvar'])
    complete <- complete[order(complete$dqvar), ]
    selectInput(inputId ='complete_var', label='Select data element', choices=complete$dqvar)
  })
  
  #creating options for vendor dropdown
  output$EHR_vendor <- renderUI({
    EHR <- MVA_DATA %>% 
      filter(!grepl('Unable', vendor_name)) %>% 
      distinct(vendor_name) %>% 
      arrange(vendor_name) %>% 
      select(vendor_name)
    
    selectInput(inputId ='vendor', label=h3('Select EHR vendor'), choices=EHR$vendor_name)
  })
  
  #creating options for year dropdown
  output$year <- renderUI({ 
    year <- MVA_DATA %>% 
      filter(timeagg=='year') %>%
      distinct(timeval) %>%
      arrange(timeval)
    
    selectInput(inputId='year', label="Year:", choices=year$timeval)
  })
  
  #using year input to create options for month dropdown   
  output$month <- renderUI({ 
    req(input$year)
  
    month <- MVA_DATA %>% 
      filter(timeagg=='month', year==input$year, month!='') %>%
      distinct(month) %>%
      arrange(month)
    
    selectInput(inputId='month', label="Month:", choices=month$month)
  })
  
  #using inputs to subset MVA data to merge with map shapefile
  map_data <- reactive({ 
    req(input$DQ_measure)
    req(input$vendor)
  
    map_data <- filter(MVA_DATA, vendor_name==input$vendor, year==input$year)
    
    #nested if else statements to accomodate month and year time interval inputs
    if (input$year_month==1) {
      if (input$DQ_measure==1) {
        filter(map_data, usegrp=='Completeness', dqvar==input$complete_var, year==input$year)
      } else if (input$DQ_measure==2 & input$time_var=='days_at_80') {
        filter(map_data, usegrp=='Timeliness', dqvar=='days_at_80', year==input$year)
      } else {
        filter(map_data, usegrp=='Timeliness', dqvar==input$time_var, year==input$year)
      } 
    } else {
      if (input$DQ_measure==1) {
        filter(map_data, usegrp=='Completeness', dqvar==input$complete_var, year==input$year, month==input$month)
      } else if (input$DQ_measure==2 & input$time_var=='days_at_80') {
        filter(map_data, usegrp=='Timeliness', dqvar=='days_at_80', year==input$year, month==input$month)
      } else {
        filter(map_data, usegrp=='Timeliness', dqvar==input$time_var, year==input$year, month==input$month)
      }
    }
  })

  #importing state shapefile and simplifying shape state file to optimize running app
  states <- states(cb = TRUE)
  simp_states <- gSimplify(states, tol = 0.05, topologyPreserve = FALSE)
  simp_states <- SpatialPolygonsDataFrame(simp_states, data = states@data)

  output$map <- renderLeaflet({
    #merging simplified shape file with subsetted MVA data
    states_shape_join <- geo_join(simp_states, map_data(), "STUSPS", "Site_State")
    
    #creating color_set, popups and legend titles based on inputs
    if (input$DQ_measure == 1) {
      color_set <- colorBin("Greens", NULL, bins = c(0, 25, 50, 75, 100))
      state_popup <- paste0("State:", states_shape_join$Site_State," <br>% Complete:", states_shape_join$measure)
      legend_title <- "% Completeness"
    } else if (input$DQ_measure==2 & input$time_var=='days_at_80') {
       color_set <- colorBin("Reds", NULL, bins = c(0, 1, 2, 5, 50))
       state_popup <- paste0("State:", states_shape_join$Site_State," <br>Ave # days:", states_shape_join$measure)
       legend_title <- "Ave # days"
    } else {
      color_set <- colorBin("Greens", NULL, bins = c(0, 25, 50, 75, 100))
      state_popup <- paste0("State:", states_shape_join$Site_State," <br>% Received:", states_shape_join$measure)
      legend_title <- "% Received"
    }
    
    #creating leaflet map
    leaflet() %>%
      #adding map styling
      addProviderTiles("CartoDB.Positron") %>% 
      addPolygons(data = states_shape_join,  
        fillColor = ~color_set(states_shape_join$measure), 
        fillOpacity = 1,
        weight = 1.5, 
        smoothFactor = 0.2, 
        color="white",
        popup = state_popup) %>%
      addLegend(pal = color_set,
        values = c(0:100), 
        position = "bottomright", 
        title = legend_title,
        opacity = 1) %>%
      #setting initial zoom
      setView(lng = -95.712891, lat = 37.09024, zoom = 3)
  })
})
