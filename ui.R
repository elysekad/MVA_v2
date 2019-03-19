#UI code for MVA shiny app

library(shiny)
library(leaflet)

shinyUI(fluidPage(
  
  #application title:
  titlePanel("MVA App"),
  
  #enter inputs for app: 
  sidebarLayout(
    
    sidebarPanel(
      
      #select whether you would like to see results for completeness or timeliness: 
      radioButtons(
        inputId='DQ_measure', 
        label=h3('Select DQ measure'), 
        choices=list('Completeness'=1, 'Timeliness'=2), 
        selected=1),
      
        #input for if completeness is selected:
        conditionalPanel(
          condition="input.DQ_measure==1",
          uiOutput('complete_options')
        ),
      
        #input for if timeliness is selected:
        conditionalPanel(
          condition="input.DQ_measure==2",
          selectInput("time_var", label = "Select measure:", 
          choices = list(
            "% records received <24 hours" = "plessthan24", 
            "% records received <48 hours" = "plessthan48", 
            "Ave # days until 80% records received" = "days_at_80"
            )
          )
        ),
      
      #select EHR vendor:
      uiOutput('EHR_vendor'),
      
      #select yearly or monthly time intervals:
      radioButtons(
        inputId='year_month', 
        label=h3('Select unit of time:'), 
        choices=list('Year'=1, 'Month'=2), 
        selected=1
      ),
      
      #select year if year OR month is selected: 
      uiOutput("year"),
        
        #if month time interval is selected: 
        conditionalPanel(
          condition="input.year_month==2",
          uiOutput("month")
        )
      
    ),
    
    #leaflet map output in main panel:  
    mainPanel(
      
      leafletOutput(outputId = 'map')
      
    )
  )
))
