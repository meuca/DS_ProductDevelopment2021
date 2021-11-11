#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)


shinyUI(fluidPage(

    # Application title
    titlePanel("Cargado de archivos"),
    sidebarLayout(
      sidebarPanel(
        fileInput('cargar_archivo', 'Cargar Archivo',
                  buttonLabel = 'Buscar',
                  placeholder = 'No se hay archivo seleccionado'),
        dateRangeInput('rango_fechas', 'Seleccione fechas',
                       min = '1900-01-05',
                       max = '2007-09-30',
                       start = '1900-01-05',
                       end = '2007-09-30'),
        
        downloadButton('download_dataframe', 'Descargar_archivo')
        
      ),
      mainPanel(
        DT::dataTableOutput('contenido_archivo')
      )
    )
    ))
