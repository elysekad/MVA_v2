#running MVA app
#please enter file path for folder where app lives

file_path <- ''

#using pacman package to check for required packages and install if not done already
if (!require("pacman")) install.packages("pacman")
pacman::p_load(shiny, leaflet, dplyr, rgdal, rgeos, readxl, sp)

#run app
library(shiny)
runApp(file_path)

