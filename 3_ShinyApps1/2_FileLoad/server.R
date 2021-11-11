#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(stringr)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

  archivos_cargado <- reactive({
    contenido_archivo <- input$cargar_archivo
    if(is.null((contenido_archivo))){ return (NULL)}
    else if(str_detect(contenido_archivo$name, '.csv')){
      out <- readr::read_csv(contenido_archivo$datapath)
      return(out)  
    }
    else
    {
      out <- data_frame(nombre_archivo = contenido_archivo$name,
                        error = 'Extension de archivo no soportada')
    }
    
  })
  
  out_dataset <- reactive({
    if(is.null(archivos_cargado())){return(NULL)}
    out <- archivos_cargado() %>%
      filter(Date >= input$rango_fechas[1],
             Date <= input$rango_fechas[2])
    return(out)
  })
  
  output$contenido_archivo <- DT::renderDataTable({
    out_dataset() %>% DT::datatable()
  })
  
  output$download_dataframe <- downloadHandler(
    filename = function(){
      paste('data-', Sys.Date(), '.csv', sep='')
    },
    content = function(file){
      readr::write_csv(out_dataset(), file)
    }
  )

})
