
#this script runs the Metadata Visualization App
#enter file path to folder containing app
file_path <- ""

#using pacman package to check for required packages and install if not done already
if (!require("pacman")) install.packages("pacman")
pacman::p_load(shiny, leaflet, dplyr, tigris, rgeos, readxl, sp)

# Run app
library(shiny)
runApp(file_path)
