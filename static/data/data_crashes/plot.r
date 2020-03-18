#plot

library(shiny)
library(plotly)
library(shinydashboard)
library(tidyverse)
library(janitor)
library(plotly)
library(htmlwidgets)

howard <- c_dat %>%
    filter(county_desc == "Howard") %>% 
    mutate(year = as.factor(year))

Sys.setenv("MAPBOX_TOKEN" = "pk.eyJ1IjoiY2xhdWRpb3phbmV0dGluaSIsImEiOiJjazc1ZDI5NjAwMmk4M2txYTllcHB1MjJpIn0.3nW8EnMVDJJGFyTEfOoawg") # for Orca

fig <-
    howard  %>%
    plot_mapbox(
        lat = ~latitude,
        lon = ~longitude,
        mode = "markers",
        symbol = ~ciao,
        # color = ~report_type,
        type = 'scattermapbox',
        hovertext = howard[,"collision_type_desc"]
        ) %>%
  layout(
    mapbox = list(
      style = 'open-street-map',
      zoom = 5,
      center = list(lon = -76, lat = 39)))

    

fig

