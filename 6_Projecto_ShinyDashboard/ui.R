#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)

library(DT)
library(dplyr)
library(mapview)
library(leaflet)

variableNames <- c('', 'Anios de Construccion', 'Total de Habitaciones', 'Total Dormitorios', 'Poblacion', 'Cantidad de Hogares', 'Ingresos Promedio')

dashboardPage(
  dashboardHeader(title = "Precios de Casas", titleWidth = 400),
  dashboardSidebar(width = 400,
                   h2("Filtros de datos"),
                   fileInput("cargar_archivo","Carga de archivo", buttonLabel = 'Buscar', placeholder = "archivo", width = 390),
                   sliderInput('precio', 'Precio de la vivienda:', min=0, max=1, value = c(0,1), width = 390),
                   sliderInput('longitud', 'Longitud:',            min=0, max=1, value = c(0,1), width = 390),
                   sliderInput('latitud', 'Latitud:',              min=0, max=1, value = c(0,1), width = 390),
                   sliderInput('contruccion', 'Antiguedad:',       min=0, max=1, value = c(0,1), width = 390),
                   sliderInput('habitaciones', 'Habitaciones:',    min=0, max=1, value = c(0,1), width = 390),
                   sliderInput('dormitorios', 'Dormitorios:',      min=0, max=1, value = c(0,1), width = 390),
                   sliderInput('poblacion', 'Poblacion:',          min=0, max=1, value = c(0,1), width = 390),
                   sliderInput('horages', 'Hogares-Familias:',     min=0, max=1, value = c(0,1), width = 390),
                   sliderInput('ingresos', 'Ingresos familiares:', min=0, max=1, value = c(0,1), width = 390),
                   actionButton('reset','Reiniciar', icon = icon("battle-net"), style="color: #001219; background-color: #ee9b00; border-color: #e9d8a6; font-weight: bold")
  ),
  dashboardBody(
    h2(textOutput("userName")),
    p("parametros url disponibles: user, tab"),
    p("ejemplo, /?user=Admin&tab=2"),
    tabsetPanel(id = "contentPanel",
                #-------------------------------------------DATOS GENERALES----------------------------------------        
                tabPanel("Datos generales", style = "font-size:12px", icon = icon("fas fa-database"),
                         h3("Informacion de archivo", style = "font-size:12px"),
                         DT::dataTableOutput ("inf_archivo"),
                         hr(),
                         h3("Resumen general valores:", style = "font-size:12px"),
                         hr(),
                         verbatimTextOutput("resumen") 
                ),
                tabPanel("Tabla", icon = icon("fas fa-table"),
                         h3("Valor de vivienda segun parametros:", style = "font-size:12px"),
                         hr(),
                         DT::dataTableOutput ("contenido_archivo"),
                         div(style = "align:right", downloadButton('downloadData', 'Download data', style="background-color:#06d6a0; color:#073b4c; font-weight: bold")),
                ),
                #-------------------------------------------GRAFICAS-----------------------------------------------        
                tabPanel("Graficas",  icon = icon("fas fa-chart-bar"),
                         navbarPage("",
                                    tabPanel("Mapas",
                                             tags$div(style = "padding-left:60px", selectInput('mapVariables', width = "400px", 'Seleccione Variable a representar en el tamano del circulo', choices = variableNames)),
                                             leafletOutput("mapplot", height = "74vh")
                                    ),
                                    navbarMenu("Analisis estadistico",
                                               tabPanel("Graficas de Densidad",
                                                        h2("Graficas de Densidad"),
                                                        selectInput('densityVariables', width = "400px", 'Seleccione Variable', choices = variableNames),
                                                        plotOutput('densityPlot')
                                               ),
                                               tabPanel("Dispersion y tendencia",
                                                        h2("Dispersion y tendencia"),
                                                        selectInput('scatterVariablesX', width = "400px", 'Seleccione Variable Independiente', selected = 'Precio', choices = c('Precio', variableNames)),
                                                        selectInput('scatterVariablesY', width = "400px", 'Seleccione Variable Dependiente', selected = 'Precio', choices = c('Precio', variableNames)),
                                                        p("Zoom: (Brush y doble click)"),
                                                        plotOutput('scatterPlot', height = "60vh",
                                                                   dblclick = 'scatterdclk',
                                                                   brush = brushOpts( id = "scatterbrh", resetOnNew = TRUE)
                                                        ),
                                                        DT::dataTableOutput ("brushedDots")
                                               ))
                         )
                )
    )
  )
)
